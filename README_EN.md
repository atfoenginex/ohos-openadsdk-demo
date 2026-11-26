[简体中文](README.md) ｜ **English**

# ATFOpenAdSDK HarmonyOS Demo

HarmonyOS sample project and integration guide for ATFOpenAdSDK. This repository contains both a runnable demo app and the full integration guide.

---

## Table of Contents

- [1. Introduction](#1-introduction)
- [2. Requirements](#2-requirements)
- [3. Quick Start](#3-quick-start)
- [4. Integrating Into Your App](#4-integrating-into-your-app)
- [5. SDK Initialization](#5-sdk-initialization)
- [6. Loading Ads](#6-loading-ads)
- [7. Adapters](#7-adapters)
- [8. Permissions](#8-permissions)
- [9. FAQ](#9-faq)

---

## 1. Introduction

ATFOpenAdSDK is ATF's HarmonyOS advertising SDK. It supports splash, interstitial, rewarded video, feed and native self-rendered ads, and can aggregate multiple third-party ad sources through adapters.

This repository provides:

- A runnable demo project: `entry/`
- Sample code for every ad format under `entry/src/main/ets/pages/`
- A single configuration file for demo parameters: `entry/build-profile.json5`

The demo covers the following ad formats:

| Ad format | Entry point | Notes |
| --- | --- | --- |
| Splash | `SplashAdPage.ets` | Full-screen splash with optional host bottom view and skip |
| Interstitial | `InterstitialAdPage.ets` | Full-screen interstitial with portrait and landscape templates |
| Rewarded video | `RewardVideoAdPage.ets` | Playback and reward callbacks |
| Feed (template) | `FeedAdPage.ets` | Rendered by the SDK template |
| Feed (self-rendered) | `NativeAdPage.ets` | Media renders its own views |

> The demo also provides a mock data switch, an ad validity check and a log panel.

## 2. Requirements

| Item | Requirement |
| --- | --- |
| DevEco Studio | 5.0 or later |
| HarmonyOS | 5.0.1(13) or later |
| Language | ArkTS |

## 3. Quick Start

```bash
# 1. Clone the repository
git clone git@github.com:atfoenginex/ohos-openadsdk-demo.git
cd ohos-openadsdk-demo

# 2. Replace the demo parameters (see below)
#    Edit entry/build-profile.json5 and replace every YOUR_* placeholder with real values

# 3. Install dependencies
ohpm install --all

# 4. Build
hvigorw assembleHap --mode module -p module=entry@default -p product=default --no-daemon
```

**Step 2 is mandatory.** `entry/build-profile.json5` only contains placeholder constants. Until they are replaced, the SDK cannot initialize and ad requests will not return.

Constants to replace in `entry/build-profile.json5`:

| Constant | Description |
| --- | --- |
| `DEMO_APP_ID` | SDK App ID |
| `DEMO_MEDIA_ID` | SDK Media ID |
| `DEMO_SECRET_KEY` | SDK Secret Key |
| `DEMO_SPLASH_SLOT_ID` | Splash slot ID |
| `DEMO_INTERSTITIAL_SLOT_ID` | Interstitial slot ID |
| `DEMO_REWARD_SLOT_ID` | Rewarded video slot ID |
| `DEMO_FEED_SLOT_ID` | Feed slot ID |

To run on a device: open the project in DevEco Studio, enable automatic signing under **Project Structure → Signing Configs** (this repository contains no signing material and `build-profile.json5` declares no `signingConfigs`), then Run.

## 4. Integrating Into Your App

### 4.1 Configure the ohpm registry

The SDK and adapters are published to the private `@atf` registry. Ask the SDK owner for an account. Create `.ohpmrc` in your project root:

```ini
# Private @atf registry (SDK core and adapters)
@atf:registry=https://ohpm.cxwlad.com/repos/ohpm/

# GroMore depends on @csj/openadsdk, which is only available on ByteDance's ohpm registry
registry=https://ohpm.openharmony.cn/ohpm/,https://artifact.bytedance.com/repository/byted-ohpm/
```

Put your private registry credentials in `~/.ohpm/.ohpmrc` and never commit them.

### 4.2 Add the dependency

```json5
// entry/oh-package.json5
{
  "dependencies": {
    "@atf/openadsdk": "1.0.2",
    "@atf/gromore": "1.0.2"
  }
}
```

Then run:

```bash
ohpm install --all
```

## 5. SDK Initialization

Initialize in `UIAbility.onCreate`. **Adapters must be registered before the SDK starts.**

```ts
import { ATFAdSDK, EnvironmentType, SDKConfig } from '@atf/openadsdk';
import { ATFGroMoreAdapter } from '@atf/gromore';
import BuildProfile from 'BuildProfile';

// Register adapters (idempotent, safe to call repeatedly)
ATFGroMoreAdapter.register();

const config = SDKConfig.builder()
  .appID(BuildProfile.DEMO_APP_ID)
  .mediaID(BuildProfile.DEMO_MEDIA_ID)
  .secretKey(BuildProfile.DEMO_SECRET_KEY)
  // Development prints more integration logs; switch to EnvironmentType.production for release
  .environmentType(EnvironmentType.development)
  .build();

// Context is injected by the host: use this.context inside a UIAbility;
// in a page use this.getUIContext().getHostContext() (getContext() is deprecated)
const success: boolean = await ATFAdSDK.start(this.context, config);
```

Common `ATFAdSDK` APIs:

| API | Description |
| --- | --- |
| `ATFAdSDK.start(context, config)` | Initializes the SDK; ads can only be requested afterwards |
| `ATFAdSDK.generateCreator<T>()` | Returns the builder for the given ad type |
| `ATFAdSDK.isInitialized` | Whether the SDK is initialized |
| `ATFAdSDK.getAvailableAdapterNames()` | Names of the currently registered adapters |

See the full implementation in `entry/src/main/ets/demo/DemoSdkInit.ets`.

## 6. Loading Ads

Every ad type is described by an `AdSlot`:

```ts
import { AdSlot, AdType } from '@atf/openadsdk';

const adSlot = new AdSlot('YOUR_SLOT_ID', AdType.splash, { width: screenW, height: screenH });
```

`load()` returns a Promise: resolving means the ad is loaded, rejecting carries the error. Interaction callbacks are registered with `setListener()`.

### 6.1 Splash

```ts
const ad: SplashAd = await ATFAdSDK.generateCreator<SplashAd>()
  .load(new AdSlot(slotID, AdType.splash, adSize));

ad.setListener(listener);
ad.show(windowStage, splashBottomView);   // second argument is the optional host bottom view
ad.isValid();
```

`adSize` is the ad area size in vp; the vendor splash `acceptSize` receives it unchanged. Use the screen width and the screen height minus the bottom logo height (88 in the demo).

### 6.2 Interstitial

```ts
const ad: InterstitialAd = await ATFAdSDK.generateCreator<InterstitialAd>()
  .load(new AdSlot(slotID, AdType.interstitial, adSize));

ad.setListener(listener);
ad.show(windowStage);
```

### 6.3 Rewarded video

```ts
const ad: RewardVideoAd = await ATFAdSDK.generateCreator<RewardVideoAd>()
  .load(new AdSlot(slotID, AdType.rewardVideo, adSize));

ad.setListener(listener);
ad.show(windowStage);
```

Reward callbacks come from `RewardVideoAdInteractionListener`:

```ts
class MyRewardListener implements RewardVideoAdInteractionListener {
  onPlayFinished(): void {}
  onRewardEffective(verify: boolean): void {}
}
```

### 6.4 Feed

Template rendering:

```ts
const ad: FeedAd = await ATFAdSDK.generateCreator<FeedAd>()
  .load(new AdSlot(slotID, AdType.feed, adSize));

const component = await ad.render(this.getUIContext());
```

Self-rendering:

```ts
const ad: NativeAd = await ATFAdSDK.generateCreator<NativeAd>().load(slot);
ad.bindAd(new NativeAdViewArgs(rootViewID, [clickViewID], [creativeViewID]));
```

### 6.5 Interaction callbacks

`AdInteractionListener` provides the common callbacks. See the implementation in `entry/src/main/ets/demo/DemoSupport.ets`:

| Callback | Description |
| --- | --- |
| `onShow()` | Ad shown successfully |
| `onShowFailed(error)` | Ad failed to show |
| `onClick()` | Ad clicked |
| `onClose()` | Ad closed |

## 7. Adapters

| Adapter | Package | Vendor SDK | How to integrate |
| --- | --- | --- | --- |
| GroMore (CSJ) | `@atf/gromore` | Remote dependency `@csj/openadsdk` 7.7.0 | Enabled by default; configure the ByteDance registry |
| GDT (Tencent) | `@atf/gdt` | GDT has no ohpm coordinate | Provide the vendor HAR yourself, see 7.1 |
| Kuaishou | `@atf/kuaishou` | Vendor SDK bundled inside the adapter HAR | Not released yet |
| MeiShu | `@atf/meishu` | Remote `@admate/ms_sdk` | Not released yet |

### 7.1 Integrating GDT

GDT's SDK has no public ohpm coordinate, so the adapter uses the peer model: `@atf/gdt` does not declare it, and the host app must provide it. Without it the build fails with `Failed to get a resolved OhmUrl for "@gdt/gdt-union-sdk"`.

1. Download the HarmonyOS SDK from the GDT console to get `GDTUnionSDK-default-release.har`;
2. Place it at `entry/libs/GDTUnionSDK-default-release.har` (excluded by `.gitignore`; do not commit vendor artifacts);
3. Add the dependency:

```json5
// entry/oh-package.json5
{
  "dependencies": {
    "@atf/openadsdk": "1.0.2",
    "@atf/gromore": "1.0.2",
    "@atf/gdt": "1.0.2",
    "@gdt/gdt-union-sdk": "file:./libs/GDTUnionSDK-default-release.har"
  }
}
```

4. Uncomment the matching `import` and `ATFGDTAdapter.register();` in `DemoSdkInit.ets`.

### 7.2 Registering adapters

Adapters are registered through a static method and **must be called before `ATFAdSDK.start()`**, otherwise the ad source will not take part in bidding:

```ts
import { ATFGDTAdapter } from '@atf/gdt';
import { ATFGroMoreAdapter } from '@atf/gromore';

ATFGDTAdapter.register();
ATFGroMoreAdapter.register();
```

## 8. Permissions

The demo's `module.json5` already declares the following permissions; mirror them in your app.

```json5
{
  "module": {
    "requestPermissions": [
      { "name": "ohos.permission.INTERNET" },
      { "name": "ohos.permission.GET_NETWORK_INFO" },
      {
        "name": "ohos.permission.APP_TRACKING_CONSENT",
        "reason": "$string:oaid_permission_reason",
        "usedScene": { "abilities": ["EntryAbility"], "when": "inuse" }
      }
    ]
  }
}
```

### 8.1 OAID device identifier

HarmonyOS has no IDFA / IDFV; OAID is the only device identifier used for advertising. `ohos.permission.APP_TRACKING_CONSENT` is a `user_grant` permission, so besides declaring it you must request it at runtime after the user accepts the privacy policy:

```ts
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';

const permissions: Permissions[] = ['ohos.permission.APP_TRACKING_CONSENT'];
const atManager = abilityAccessCtrl.createAtManager();
await atManager.requestPermissionsFromUser(context, permissions);
```

If the permission is missing or denied, the system returns an all-zero placeholder. The SDK reports it as-is to indicate "not authorized"; it neither crashes nor blocks startup.

## 9. FAQ

**Q: `ohpm install` fails with `package '@atf/openadsdk@1.0.2' not found`.**
A: Make sure `.ohpmrc` contains `@atf:registry=https://ohpm.cxwlad.com/repos/ohpm/` and that `~/.ohpm/.ohpmrc` holds credentials for that registry.

**Q: `ohpm install` fails with `package '@csj/openadsdk@7.7.0' not found`.**
A: When using `@atf/gromore`, add `https://artifact.bytedance.com/repository/byted-ohpm/` to `registry` (note `byted-ohpm`, not `ohpm`).

**Q: The build fails with `Failed to get a resolved OhmUrl for "@gdt/gdt-union-sdk"`.**
A: `@atf/gdt` is used without the GDT vendor HAR. See "7.1 Integrating GDT".

**Q: An adapter is installed but that ad source never bids.**
A: Make sure the matching `ATFxAdapter.register()` is called before `ATFAdSDK.start()`.

**Q: The reported `oaid` is all zeros.**
A: Make sure `ohos.permission.APP_TRACKING_CONSENT` is declared and requested at runtime after the user accepts the privacy policy. See "8.1 OAID device identifier".

**Q: No ads are returned on the emulator.**
A: Some vendors do not deliver inventory to emulators; verify on a physical device.

---

## License

[LICENSE](LICENSE)
