# Ad Configuration & Mediation Verification Plan

## Analysis

The Admin Panel provides separate switches for "Google AdMob" and "Meta Audience Network".
However, the Mobile App implementation (and the requested Bidding feature) relies on **AdMob Mediation**.

### Current Behavior

1.  **AdMob Enabled (Admin)**: Mobile App initializes AdMob. If configured in AdMob Console, it **WILL** serve Facebook Ads (Bidding). -> **WORKS**
2.  **AdMob Disabled / Meta Enabled (Admin)**: Mobile App receives "Ads Enabled" signal but **Missing AdMob Config**. It does NOT initialize Facebook SDK directly. -> **NO ADS**

## Recommendation

To support Facebook Bidding "along with" AdMob (as requested), you must use **AdMob Mediation**.

- **Admin Panel**: You must keep **Google AdMob ENABLED**.
- **AdMob Console**: You must configure **Facebook Audience Network** as a Bidding Source.
- **Meta Settings (Admin)**: These settings are effectively **unused** by the mobile app in Mediation mode (as AdMob fetches config from Google servers). You can leave them for reference or disable them to avoid confusion.

## Proposed Changes

To ensure the app behaves predictably and aids debugging:

### 1. Mobile App (`AdService.dart`)

- Add logic to gracefully handle the "AdMob Disabled" state. (Currently it might try to read null config).
- Add a debug warning if `ads_enabled` is true but `admob` config is missing (reminding developer that Direct Meta is not supported).

### 2. Backend (Admin API) - _Optional_

- (No changes required, logic is safe).

## Verification Plan

1.  **Configuration Check**: Ensure "Google AdMob" is Enabled in Admin.
2.  **Mobile Logs**: Run app and check `flutter logs` for "Ad config fetched".
3.  **Mediation**: Verify Facebook Adapter is initialized (via internal logs or Test Suite).

> [!NOTE]
> We will NOT implement a separate "Direct Facebook SDK" mode, as it conflicts with the "Bidding via Mediation" goal and complicates the codebase. AdMob Mediation is the industry standard for Bidding.
