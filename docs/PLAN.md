# Plan: Admin-Controlled Ad Provider Switching

## Goal

Enable absolute control from the Admin Panel to switch between **Google AdMob** and **Meta Audience Network** dynamically.
The mobile app must respect the "Enabled" flag of each provider and initialize the correct SDK.

## Trade-off Analysis

- **Previous Approach**: AdMob Mediation (AdMob is master, Meta is bidder).
- **New Approach**: Custom Switching (Mobile app decides which SDK to load based on Admin Config).
  - **Pros**: Absolute control. Can turn off AdMob and run only Meta.
  - **Cons**: No Bidding (unless separate mediation is set up). Meta Bidding requires a mediator. If "Meta Only" is selected, we must use **Meta Audience Network SDK directly**.

## Proposed Changes

### 1. Mobile App (`AdService.dart`)

We need to support two modes:

1.  **AdMob Mode** (Default): Uses `google_mobile_ads` package. Can mediate Meta if configured.
2.  **Meta Mode** (Direct): Uses `facebook_audience_network` package directly.

**Refactoring `AdService`**:

- Fetch Config first.
- If `admob.enabled` -> Initialize `MobileAds.instance`. Load AdMob units.
- If `meta.enabled` (and AdMob disabled) -> Initialize `FacebookAudienceNetwork.init()`. Load Facebook Widget/Interstitial.
- **Wait**: `google_mobile_ads` handles AdMob logic. We need a way to abstract "Load Interstitial" and "Show Banner" to support both SDKs.
- **Abstraction**: Create `IAdProvider` interface (implicitly) or switch inside `AdService` methods.

### 2. Dependencies

- We already have `facebook_audience_network` (Direct SDK) in `pubspec.yaml`.
- We previously added `com.google.ads.mediation:facebook` (Mediation Adapter) to `build.gradle.kts`.
- **Conflict**: Having both _might_ cause duplicate class issues or version conflicts, but usually Mediation Adapter depends on the Audience Network SDK. We need to check if we can use the _same_ underlying SDK for both Mediation and Direct usage.
  - _AdMob Mediation Adapter_ usually bundles or depends on specific version of FB SDK.
  - `facebook_audience_network` flutter package also interacts with FB SDK.
  - **Strategy**: Keep `facebook_audience_network` package. It is required for Direct rendering.

### 3. Implementation Steps

1.  **Modify `AdService`**:
    - Add `AdProvider` enum (`admob`, `facebook`).
    - Parse `_remoteConfig` to determine active provider.
    - Update `loadInterstitialAd`, `showInterstitialAd` to dispatch to correct SDK.
    - Expose `currentProvider` to UI.
2.  **Modify UI (Banner Widgets)**:
    - Create a `UniversalBannerAd` widget that checks `AdService.currentProvider`.
    - If AdMob -> return `AdWidget`.
    - If Facebook -> return `FacebookBannerAd`.

## Verification Plan

1.  **Admin Panel**:
    - Enable AdMob, Disable Meta -> App loads AdMob.
    - Disable AdMob, Enable Meta -> App loads Facebook SDK.
2.  **Mobile App**:
    - Verify Banner loads in both modes.
    - Verify Interstitial loads in both modes.

> [!WARNING]
> Meta Audience Network is moving towards **Bidding Only**. "Direct" integration (Waterfall) is deprecated/legacy in many regions. Ensure your Meta Property supports Waterfall if you want to use it directly without a Mediator.
