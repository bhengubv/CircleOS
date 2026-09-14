#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Add the mesh RECEIVE path: a GATT server + BLE advertiser so peers can find us
# and write to us, and the link-decrypt -> unframe -> MESSAGE_RECEIVED broadcast.
# Fully-qualified android.bluetooth.* names so no imports need editing.
import sys
F = "frameworks/base/services/core/java/com/circleos/server/mesh/CircleMeshService.java"
s = open(F, encoding="utf-8").read()
if "startGattServer" in s:
    print("receive path already present"); sys.exit(0)

# 1) wire into startBle right after the scan starts
anchor = '            Slog.i(TAG, "BLE scan started for service UUID " + CIRCLE_MESH_BLE_SVC_UUID);'
if anchor not in s:
    print("FAIL: scan-start anchor not found"); sys.exit(1)
s = s.replace(anchor, anchor + "\n            startGattServer();\n            startAdvertising();", 1)

# 2) insert the receive-path methods before currentServiceUuid()
ins_anchor = "    /** Current rotating BLE service UUID (daily;"
if ins_anchor not in s:
    print("FAIL: currentServiceUuid anchor not found"); sys.exit(1)
block = r'''    private android.bluetooth.BluetoothGattServer mGattServer;
    private android.bluetooth.le.BluetoothLeAdvertiser mAdvertiser;

    /** Host the writable Circle characteristic so peers can deliver frames to us. */
    private void startGattServer() {
        try {
            final android.bluetooth.BluetoothManager bm =
                    mContext.getSystemService(android.bluetooth.BluetoothManager.class);
            if (bm == null) return;
            mGattServer = bm.openGattServer(mContext, mGattServerCb);
            if (mGattServer == null) { Slog.w(TAG, "openGattServer failed"); return; }
            final UUID svcUuid = currentServiceUuid();
            android.bluetooth.BluetoothGattService svc = new android.bluetooth.BluetoothGattService(
                    svcUuid, android.bluetooth.BluetoothGattService.SERVICE_TYPE_PRIMARY);
            android.bluetooth.BluetoothGattCharacteristic ch =
                    new android.bluetooth.BluetoothGattCharacteristic(
                            CIRCLE_MESH_BLE_CHAR_UUID,
                            android.bluetooth.BluetoothGattCharacteristic.PROPERTY_WRITE,
                            android.bluetooth.BluetoothGattCharacteristic.PERMISSION_WRITE);
            svc.addCharacteristic(ch);
            mGattServer.addService(svc);
            Slog.i(TAG, "GATT server up");
        } catch (SecurityException se) {
            Slog.w(TAG, "GATT server denied (BLUETOOTH_CONNECT)", se);
        } catch (Throwable t) {
            Slog.w(TAG, "GATT server bring-up failed", t);
        }
    }

    private final android.bluetooth.BluetoothGattServerCallback mGattServerCb =
            new android.bluetooth.BluetoothGattServerCallback() {
        @Override
        public void onCharacteristicWriteRequest(android.bluetooth.BluetoothDevice device,
                int requestId, android.bluetooth.BluetoothGattCharacteristic characteristic,
                boolean preparedWrite, boolean responseNeeded, int offset, byte[] value) {
            try {
                if (responseNeeded && mGattServer != null) {
                    try {
                        mGattServer.sendResponse(device, requestId,
                                android.bluetooth.BluetoothGatt.GATT_SUCCESS, offset, null);
                    } catch (SecurityException ignored) {}
                }
                if (characteristic == null
                        || !CIRCLE_MESH_BLE_CHAR_UUID.equals(characteristic.getUuid())) return;
                deliverReceived(device, value);
            } catch (Throwable t) {
                Slog.w(TAG, "onCharacteristicWriteRequest failed", t);
            }
        }
    };

    /** Advertise the (rotating) Circle service UUID so peers can discover + connect. */
    private void startAdvertising() {
        try {
            if (mBtAdapter == null) return;
            mAdvertiser = mBtAdapter.getBluetoothLeAdvertiser();
            if (mAdvertiser == null) { Slog.w(TAG, "no BLE advertiser"); return; }
            android.bluetooth.le.AdvertiseSettings settings =
                    new android.bluetooth.le.AdvertiseSettings.Builder()
                            .setAdvertiseMode(android.bluetooth.le.AdvertiseSettings.ADVERTISE_MODE_LOW_POWER)
                            .setConnectable(true)
                            .setTxPowerLevel(android.bluetooth.le.AdvertiseSettings.ADVERTISE_TX_POWER_LOW)
                            .build();
            android.bluetooth.le.AdvertiseData data =
                    new android.bluetooth.le.AdvertiseData.Builder()
                            .addServiceUuid(new ParcelUuid(currentServiceUuid()))
                            .setIncludeDeviceName(false)
                            .build();
            mAdvertiser.startAdvertising(settings, data, mAdvertiseCb);
            Slog.i(TAG, "BLE advertising started");
        } catch (SecurityException se) {
            Slog.w(TAG, "advertising denied (BLUETOOTH_ADVERTISE)", se);
        } catch (Throwable t) {
            Slog.w(TAG, "advertising failed", t);
        }
    }

    private final android.bluetooth.le.AdvertiseCallback mAdvertiseCb =
            new android.bluetooth.le.AdvertiseCallback() {
        @Override public void onStartFailure(int errorCode) {
            Slog.i(TAG, "BLE advertise failed errorCode=" + errorCode);
        }
    };

    /** Link-decrypt -> unframe -> broadcast an incoming frame to mesh apps. */
    private void deliverReceived(android.bluetooth.BluetoothDevice device, byte[] wire) {
        if (wire == null) return;
        byte[] frame = MeshLinkPrivacy.linkDecrypt(
                MeshLinkPrivacy.currentEpoch(System.currentTimeMillis()), wire);
        if (frame == null) { Slog.i(TAG, "drop: not a Circle link frame"); return; }
        byte[] payload = unframe(frame);
        if (payload == null) return;
        final String sender = shortIdFromMac(device == null ? "" : device.getAddress());
        final String text = new String(payload, java.nio.charset.StandardCharsets.UTF_8);
        android.content.Intent i =
                new android.content.Intent("za.co.circleos.mesh.action.MESSAGE_RECEIVED");
        i.putExtra("sender_id", sender);
        i.putExtra("msg_text", text);
        i.setFlags(android.content.Intent.FLAG_INCLUDE_STOPPED_PACKAGES);
        try {
            mContext.sendBroadcastAsUser(i, android.os.UserHandle.ALL);
        } catch (Throwable t) {
            mContext.sendBroadcast(i);
        }
        Slog.i(TAG, "delivered mesh message from " + sender + " (" + payload.length + "b)");
    }

    /** Reverse frameMessage v2: [ver][trueLen:4 BE][payload][padding] -> payload. */
    private static byte[] unframe(byte[] frame) {
        if (frame == null || frame.length < 5 || (frame[0] & 0xff) != FRAME_VERSION) return null;
        int len = ((frame[1] & 0xff) << 24) | ((frame[2] & 0xff) << 16)
                | ((frame[3] & 0xff) << 8) | (frame[4] & 0xff);
        if (len < 0 || 5 + len > frame.length) return null;
        return java.util.Arrays.copyOfRange(frame, 5, 5 + len);
    }

'''
s = s.replace(ins_anchor, block + ins_anchor, 1)
open(F, "w", encoding="utf-8").write(s)
print("mesh receive path added (GATT server + advertiser + broadcast)")
