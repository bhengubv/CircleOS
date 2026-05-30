/*
 * Copyright (C) 2026 The Other Bhengu (PTY) Ltd t/a The Geek Network.
 *
 * The canonical representation of one Personality mode.
 *
 * Immutable, Parcelable, equality-by-id. The mode catalogue is bundled
 * with the OS as JSON resources under vendor/circle/personality/data/
 * and loaded at boot by CirclePersonalityService.
 */

package com.circleos.personality;

import android.os.Parcel;
import android.os.Parcelable;

import java.util.Arrays;
import java.util.Objects;

public final class PersonalityMode implements Parcelable {

    /** Machine id, e.g. "daily", "work", "secure". Lowercase, ASCII. */
    public final String id;

    /** Localised display name, e.g. "Daily" or "iSiKhathi". */
    public final String displayName;

    /** Short user-facing description shown in the picker. */
    public final String description;

    /** Accent colour in 0xAARRGGBB, e.g. 0xFF2196F3 for Daily. */
    public final int accentColor;

    /** Tier mask: 1=STANDARD, 2=KID, 4=ELDER. Bitwise OR for "in many". */
    public final int tierMask;

    /**
     * System-prompt template fed to the Inference Service in this mode.
     * Empty means the default neutral prompt is used. May contain the
     * placeholders {user_name}, {locale}, {device_model}.
     */
    public final String personalityPrompt;

    /**
     * Package names this mode pins to the launcher's first row, in order.
     * Apps not installed are silently ignored.
     */
    public final String[] recommendedPackages;

    /**
     * Names of permissions auto-granted to *all* installed apps while this
     * mode is active (in addition to whatever the user has granted
     * individually). Used by e.g. "Sport" to grant location to fitness apps
     * without nag.
     */
    public final String[] autoGrantedPermissions;

    /**
     * Names of permissions force-revoked while this mode is active. Used
     * by e.g. "Secure" to deny camera/microphone to everything except a
     * whitelist.
     */
    public final String[] forceRevokedPermissions;

    public PersonalityMode(String id,
                           String displayName,
                           String description,
                           int accentColor,
                           int tierMask,
                           String personalityPrompt,
                           String[] recommendedPackages,
                           String[] autoGrantedPermissions,
                           String[] forceRevokedPermissions) {
        this.id = Objects.requireNonNull(id);
        this.displayName = displayName == null ? id : displayName;
        this.description = description == null ? "" : description;
        this.accentColor = accentColor;
        this.tierMask = tierMask;
        this.personalityPrompt = personalityPrompt == null ? "" : personalityPrompt;
        this.recommendedPackages = recommendedPackages == null ? new String[0] : recommendedPackages;
        this.autoGrantedPermissions = autoGrantedPermissions == null ? new String[0] : autoGrantedPermissions;
        this.forceRevokedPermissions = forceRevokedPermissions == null ? new String[0] : forceRevokedPermissions;
    }

    public boolean isAvailableInTier(int tier) {
        return (tierMask & (1 << tier)) != 0;
    }

    // ----- Parcelable --------------------------------------------------

    private PersonalityMode(Parcel in) {
        this.id = in.readString();
        this.displayName = in.readString();
        this.description = in.readString();
        this.accentColor = in.readInt();
        this.tierMask = in.readInt();
        this.personalityPrompt = in.readString();
        this.recommendedPackages = in.createStringArray();
        this.autoGrantedPermissions = in.createStringArray();
        this.forceRevokedPermissions = in.createStringArray();
    }

    @Override
    public void writeToParcel(Parcel out, int flags) {
        out.writeString(id);
        out.writeString(displayName);
        out.writeString(description);
        out.writeInt(accentColor);
        out.writeInt(tierMask);
        out.writeString(personalityPrompt);
        out.writeStringArray(recommendedPackages);
        out.writeStringArray(autoGrantedPermissions);
        out.writeStringArray(forceRevokedPermissions);
    }

    @Override
    public int describeContents() { return 0; }

    public static final Parcelable.Creator<PersonalityMode> CREATOR =
            new Parcelable.Creator<PersonalityMode>() {
        @Override public PersonalityMode createFromParcel(Parcel in) { return new PersonalityMode(in); }
        @Override public PersonalityMode[] newArray(int n) { return new PersonalityMode[n]; }
    };

    // ----- equality / debug --------------------------------------------

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof PersonalityMode)) return false;
        PersonalityMode that = (PersonalityMode) o;
        return id.equals(that.id);
    }

    @Override
    public int hashCode() { return id.hashCode(); }

    @Override
    public String toString() {
        return "PersonalityMode{id=" + id
                + ", display=" + displayName
                + ", tierMask=" + tierMask
                + ", recPkgs=" + Arrays.toString(recommendedPackages)
                + "}";
    }
}
