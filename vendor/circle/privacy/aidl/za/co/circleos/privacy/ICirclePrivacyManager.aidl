/*
 * Copyright (C) 2026 The Other Bhengu (PTY) Ltd t/a The Geek Network.
 *
 * AIDL surface for the Circle Privacy Framework.
 *
 * Callers — both system components and Circle-owned apps — use this to ask
 * the OS about per-package network and data privacy state. The framework
 * itself enforces the answers; this interface is the only blessed way to
 * read or change them.
 */

package za.co.circleos.privacy;

/** Binder published under SERVICE_NAME = "circle_privacy". */
interface ICirclePrivacyManager {

    /**
     * Returns true if {@code packageName} (for the given userId) is
     * currently allowed to make outbound network connections. The default
     * for any new package is FALSE — Circle is deny-by-default for the
     * INTERNET permission.
     */
    boolean isNetworkAllowed(in String packageName, int userId);

    /**
     * Grant or revoke network access for {@code packageName}. Persisted
     * across reboots. Only callable by holders of the
     * za.co.circleos.permission.MANAGE_PRIVACY signature|privileged
     * permission, or by the package itself if the user has been shown the
     * runtime-permission prompt.
     */
    void setNetworkAllowed(in String packageName, int userId, boolean allowed);

    /**
     * Returns true if denied reads of contacts / storage / location for
     * {@code packageName} should be answered with a *synthetic* response
     * (an empty list, a fixed home address, a black-screen camera frame…)
     * instead of an explicit SecurityException. This is the core of the
     * privacy guarantee: apps that misbehave when denied permissions get a
     * believable lie, not a crash.
     */
    boolean isFakeResponseEnabled(in String packageName, int userId);

    /**
     * Enable / disable the fake-response provider for one package. Default
     * is TRUE for all third-party apps; FALSE for system / Circle-signed
     * packages.
     */
    void setFakeResponseEnabled(in String packageName, int userId, boolean enabled);

    /**
     * Schema version of the binder surface. Bumped whenever any method's
     * shape changes so older callers can detect a mismatch.
     */
    int getApiVersion();
}
