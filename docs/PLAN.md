# Plan: Gender Selection & Facebook/AdMob Bidding Implementation

## Goal

1.  **Gender Selection**: Add gender selection to the Sign-Up flow and save it to the user profile.
2.  **Ads**: Implement Facebook Ads (Audience Network) alongside AdMob, enabling Bidding via AdMob Mediation.

## User Review Required

> [!IMPORTANT]
> **AdMob Mediation & Bidding**: To enable "Bidding" for Facebook Audience Network via AdMob, you must:
>
> 1.  Set up a **Meta Audience Network Property** and **Ad Units**.
> 2.  Configure **AdMob Mediation** in the AdMob Console, adding Facebook as a Bidding source and mapping the ID.
> 3.  This plan adds the necessary **SDKs and Adapters** to the mobile app code. You must perform the Console setup yourself.

## Proposed Changes

### 1. Backend Integration (Auth Provider)

- **File**: `lib/core/providers/auth_provider.dart`
  - Update `signUpWithEmail` method to accept a `required String gender` argument.
  - Include `gender` in the API request body.

### 2. Frontend (Sign Up UI)

- **File**: `lib/features/auth/screens/register_screen.dart`
  - Add `_selectedGender` state variable (Default: 'Male' or null).
  - Add a Gender Dropdown/Selector in `_buildBasicInfoStep` (e.g., below Phone Number).
  - Update `_handleRegister` to pass the selected gender to `authProvider`.

### 3. Ads Implementation (AdMob Mediation + Facebook)

- **Dependencies**:
  - Add `com.google.ads.mediation:facebook` adapter to Android.
  - Add `GoogleMobileAdsMediationFacebook` to iOS Podfile.
- **File**: `android/app/build.gradle.kts`
  - Add implementation for Facebook Mediation Adapter.
- **File**: `ios/Podfile`
  - Ensure Facebook Mediation pod is included.
- **File**: `lib/core/services/ad_service.dart`
  - Ensure `MobileAds.instance.initialize()` is called (checks for all adapters).
  - (Optional) If you want to use Facebook Native Ads directly via Flutter widgets, we keep `facebook_audience_network`. If we only want Bidding via AdMob, we strictly need the Adapter. I will assume we keep the package to allow potential future hybrid usage, but focus on Mediation for Bidding.

## Verification Plan

### Automated Tests

- **Unit Test**: Update `auth_provider_test.dart` (if exists) to verify `sign_up` passes gender.
- **Build Test**: Run `flutter build apk` to verify Gradle dependencies resolve correctly (especially Mediation adapters).

### Manual Verification

1.  **Sign Up**:
    - Go to Sign Up screen.
    - Verify "Gender" dropdown appears.
    - Select a gender (e.g., "Female").
    - Complete Sign Up.
    - Check Firestore/Backend (or Profile page) to see if Gender is saved.
2.  **Ads**:
    - Run app on a real device (Ads often fail on emulators).
    - Verify Banner/Interstitial ads load.
    - (Note: Bidding is hard to verify visually without Console tools, but we can check logs for "Facebook Adapter initialized").
