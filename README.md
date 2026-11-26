**简体中文** ｜ [English](README_EN.md)

# ATFOpenAdSDK HarmonyOS Demo

ATFOpenAdSDK 的 HarmonyOS 示例工程与接入文档。本仓库同时包含可直接运行的 Demo App 与 SDK 接入说明。

---

## 目录

- [1. 简介](#1-简介)
- [2. 环境要求](#2-环境要求)
- [3. 快速开始：运行 Demo](#3-快速开始运行-demo)
- [4. 集成到你的 App](#4-集成到你的-app)
- [5. SDK 初始化](#5-sdk-初始化)
- [6. 广告接入](#6-广告接入)
- [7. 厂商适配器](#7-厂商适配器)
- [8. 权限](#8-权限)
- [9. 常见问题](#9-常见问题)

---

## 1. 简介

ATFOpenAdSDK 是 ATF 提供的 HarmonyOS 广告 SDK，支持开屏、插屏、激励视频、信息流与原生自渲染广告，并可通过适配器接入多家三方广告源参与竞价。

本仓库提供：

- 可直接运行的 Demo 工程 `entry/`
- 覆盖全部广告类型的示例代码 `entry/src/main/ets/pages/`
- 集中管理演示参数的配置文件 `entry/build-profile.json5`

Demo 内置以下广告能力示例：

| 广告类型 | 入口 | 说明 |
| --- | --- | --- |
| 开屏广告 | `SplashAdPage.ets` | 全屏开屏，支持宿主自定义底部视图与跳过 |
| 插屏广告 | `InterstitialAdPage.ets` | 全屏插屏，支持横竖屏模板 |
| 激励视频 | `RewardVideoAdPage.ets` | 支持播放完成与奖励回调 |
| 信息流（模板） | `FeedAdPage.ets` | SDK 模板渲染 |
| 信息流（自渲染） | `NativeAdPage.ets` | 媒体自定义渲染视图 |

> Demo 还提供 Mock 数据开关、广告有效性检查与日志面板等辅助能力。

## 2. 环境要求

| 项 | 要求 |
| --- | --- |
| DevEco Studio | 5.0 及以上 |
| HarmonyOS | 5.0.1(13) 及以上 |
| 语言 | ArkTS |

## 3. 快速开始：运行 Demo

```bash
# 1. 克隆仓库
git clone git@github.com:atfoenginex/ohos-openadsdk-demo.git
cd ohos-openadsdk-demo

# 2. 替换演示参数（见下）
#    编辑 entry/build-profile.json5，把所有 YOUR_* 占位符替换为真实值

# 3. 安装依赖
ohpm install --all

# 4. 构建
hvigorw assembleHap --mode module -p module=entry@default -p product=default --no-daemon
```

**必须先完成第 2 步。** 仓库内的 `entry/build-profile.json5` 只包含占位常量，未替换前 SDK 无法初始化，广告请求也不会返回。

`entry/build-profile.json5` 需要替换的常量：

| 常量 | 说明 |
| --- | --- |
| `DEMO_APP_ID` | SDK App ID |
| `DEMO_MEDIA_ID` | SDK Media ID |
| `DEMO_SECRET_KEY` | SDK Secret Key |
| `DEMO_SPLASH_SLOT_ID` | 开屏广告位 ID |
| `DEMO_INTERSTITIAL_SLOT_ID` | 插屏广告位 ID |
| `DEMO_REWARD_SLOT_ID` | 激励视频广告位 ID |
| `DEMO_FEED_SLOT_ID` | 信息流广告位 ID |

装到设备：用 DevEco Studio 打开本工程，**Project Structure → Signing Configs** 勾选自动签名
（本仓库不含任何签名材料，`build-profile.json5` 中也没有 `signingConfigs`），然后直接 Run。

## 4. 集成到你的 App

### 4.1 配置 ohpm 仓库

SDK 与适配器发布在 `@atf` 私仓，账号由 SDK 负责人分配。在工程根目录新建 `.ohpmrc`：

```ini
# @atf 私仓（SDK 本体与适配器）
@atf:registry=https://ohpm.cxwlad.com/repos/ohpm/

# 穿山甲 GroMore 依赖 @csj/openadsdk，只在字节 ohpm 仓库有坐标
registry=https://ohpm.openharmony.cn/ohpm/,https://artifact.bytedance.com/repository/byted-ohpm/
```

私仓凭据写在你自己的 `~/.ohpm/.ohpmrc`，不要提交到仓库。

### 4.2 添加依赖

```json5
// entry/oh-package.json5
{
  "dependencies": {
    "@atf/openadsdk": "0.0.2",
    "@atf/gromore": "0.0.1"
  }
}
```

执行：

```bash
ohpm install --all
```

## 5. SDK 初始化

在 `UIAbility.onCreate` 中完成初始化，**厂商适配器必须在 SDK 初始化之前注册**。

```ts
import { ATFAdSDK, EnvironmentType, SDKConfig } from '@atf/openadsdk';
import { ATFGroMoreAdapter } from '@atf/gromore';
import BuildProfile from 'BuildProfile';

// 注册适配器（幂等，重复调用无副作用）
ATFGroMoreAdapter.register();

const config = SDKConfig.builder()
  .appID(BuildProfile.DEMO_APP_ID)
  .mediaID(BuildProfile.DEMO_MEDIA_ID)
  .secretKey(BuildProfile.DEMO_SECRET_KEY)
  // 开发环境会输出更完整的联调日志，上线请改为 EnvironmentType.production
  .environmentType(EnvironmentType.development)
  .build();

// Context 由宿主注入：UIAbility 中直接用 this.context；
// 页面中请用 this.getUIContext().getHostContext()（getContext() 已弃用）
const success: boolean = await ATFAdSDK.start(this.context, config);
```

`ATFAdSDK` 常用接口：

| 接口 | 说明 |
| --- | --- |
| `ATFAdSDK.start(context, config)` | 初始化 SDK，成功后才能请求广告 |
| `ATFAdSDK.generateCreator<T>()` | 获取对应广告类型的构建器 |
| `ATFAdSDK.isInitialized` | 是否已初始化 |
| `ATFAdSDK.getAvailableAdapterNames()` | 当前已注册的适配器名称 |

完整实现见 `entry/src/main/ets/demo/DemoSdkInit.ets`。

## 6. 广告接入

所有广告类型都通过 `AdSlot` 描述广告位：

```ts
import { AdSlot, AdType } from '@atf/openadsdk';

const adSlot = new AdSlot('YOUR_SLOT_ID', AdType.splash, { width: screenW, height: screenH });
```

`load()` 返回 Promise：成功即加载完成，失败通过 `catch` 拿到错误。交互回调通过 `setListener()` 注册。

### 6.1 开屏广告

```ts
const ad: SplashAd = await ATFAdSDK.generateCreator<SplashAd>()
  .load(new AdSlot(slotID, AdType.splash, adSize));

ad.setListener(listener);
ad.show(windowStage, splashBottomView);   // 第二个参数为可选的宿主底部视图
ad.isValid();
```

`adSize` 即广告区尺寸（vp），厂商开屏的 `acceptSize` 直接透传该值。宽取屏宽，高取屏高减去底部 Logo 高度（Demo 中为 88）。

### 6.2 插屏广告

```ts
const ad: InterstitialAd = await ATFAdSDK.generateCreator<InterstitialAd>()
  .load(new AdSlot(slotID, AdType.interstitial, adSize));

ad.setListener(listener);
ad.show(windowStage);
```

### 6.3 激励视频

```ts
const ad: RewardVideoAd = await ATFAdSDK.generateCreator<RewardVideoAd>()
  .load(new AdSlot(slotID, AdType.rewardVideo, adSize));

ad.setListener(listener);
ad.show(windowStage);
```

奖励回调通过 `RewardVideoAdInteractionListener` 获取：

```ts
class MyRewardListener implements RewardVideoAdInteractionListener {
  onPlayFinished(): void {}
  onRewardEffective(isEffective: boolean, verify: boolean): void {}
}
```

### 6.4 信息流

模板渲染：

```ts
const ad: FeedAd = await ATFAdSDK.generateCreator<FeedAd>()
  .load(new AdSlot(slotID, AdType.feed, adSize));

const component = await ad.render(this.getUIContext());
```

自渲染：

```ts
const ad: NativeAd = await ATFAdSDK.generateCreator<NativeAd>().load(slot);
ad.bindAd(new NativeAdViewArgs(rootViewID, [clickViewID], [creativeViewID]));
```

### 6.5 交互回调

`AdInteractionListener` 提供通用回调，Demo 中的实现见 `entry/src/main/ets/demo/DemoSupport.ets`：

| 回调 | 说明 |
| --- | --- |
| `onShow()` | 广告展示成功 |
| `onShowFailed(error)` | 广告展示失败 |
| `onClick()` | 广告被点击 |
| `onClose()` | 广告关闭 |

## 7. 厂商适配器

| 适配器 | 包名 | 厂商 SDK 形态 | 接入方式 |
| --- | --- | --- | --- |
| 穿山甲 GroMore | `@atf/gromore` | 远程依赖 `@csj/openadsdk` 7.7.0 | 已默认开启，配好字节仓库即可 |
| 优量汇 GDT | `@atf/gdt` | 优量汇在 ohpm 无坐标 | 需自备厂商 HAR，见 7.1 |
| 快手联盟 | `@atf/kuaishou` | 内嵌在适配器 HAR 内 | 待发布，发布后按版本号引入 |
| 美数 | `@atf/meishu` | 远程 `@admate/ms_sdk` | 待发布，发布后按版本号引入 |

### 7.1 接入优量汇 GDT

优量汇 SDK 在 ohpm 上没有公开坐标，适配器采用 peer 模式：`@atf/gdt` 自己不声明它，必须由接入方提供。缺少时编译报 `Failed to get a resolved OhmUrl for "@gdt/gdt-union-sdk"`。

1. 从优量汇后台下载 HarmonyOS SDK，得到 `GDTUnionSDK-default-release.har`；
2. 放到 `entry/libs/GDTUnionSDK-default-release.har`（本仓库已用 `.gitignore` 排除，厂商产物不要提交）；
3. 补依赖：

```json5
// entry/oh-package.json5
{
  "dependencies": {
    "@atf/openadsdk": "0.0.2",
    "@atf/gromore": "0.0.1",
    "@atf/gdt": "0.0.1",
    "@gdt/gdt-union-sdk": "file:./libs/GDTUnionSDK-default-release.har"
  }
}
```

4. 在 `DemoSdkInit.ets` 中放开对应的 `import` 与 `ATFGDTAdapter.register();`。

### 7.2 适配器注册

适配器通过静态方法注册，**必须在 `ATFAdSDK.start()` 之前调用**，否则该广告源不参与竞价：

```ts
import { ATFGDTAdapter } from '@atf/gdt';
import { ATFGroMoreAdapter } from '@atf/gromore';

ATFGDTAdapter.register();
ATFGroMoreAdapter.register();
```

## 8. 权限

Demo 的 `module.json5` 已包含以下权限，接入时请同步到你的工程。

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

### 8.1 设备标识 OAID

HarmonyOS 没有 IDFA / IDFV，广告场景的设备标识只有 OAID。`ohos.permission.APP_TRACKING_CONSENT` 是 `user_grant` 权限，除声明外还需在用户同意隐私政策后动态申请：

```ts
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';

const permissions: Permissions[] = ['ohos.permission.APP_TRACKING_CONSENT'];
const atManager = abilityAccessCtrl.createAtManager();
await atManager.requestPermissionsFromUser(context, permissions);
```

未声明或用户拒绝时，系统返回全 0 占位值，SDK 会原样上报表示「未授权」，不会崩溃也不阻塞启动。

## 9. 常见问题

**Q：`ohpm install` 报 `package '@atf/openadsdk@0.0.2' not found`？**
A：确认 `.ohpmrc` 里已配置 `@atf:registry=https://ohpm.cxwlad.com/repos/ohpm/`，且 `~/.ohpm/.ohpmrc` 里有该私仓的凭据。

**Q：`ohpm install` 报 `package '@csj/openadsdk@7.7.0' not found`？**
A：使用 `@atf/gromore` 时必须在 `registry` 中加入 `https://artifact.bytedance.com/repository/byted-ohpm/`（注意是 `byted-ohpm`，不是 `ohpm`）。

**Q：编译报 `Failed to get a resolved OhmUrl for "@gdt/gdt-union-sdk"`？**
A：使用了 `@atf/gdt` 但没有提供优量汇厂商 HAR，见「7.1 接入优量汇 GDT」。

**Q：广告源已安装，但该广告源不参与竞价？**
A：确认对应的 `ATFxAdapter.register()` 已在 `ATFAdSDK.start()` 之前调用。

**Q：上报的 `oaid` 是全 0？**
A：确认已声明 `ohos.permission.APP_TRACKING_CONSENT` 并在隐私政策同意后完成动态申请，见「8.1 设备标识 OAID」。

**Q：模拟器上请求不到广告？**
A：部分厂商不向模拟器下发库存，请用真机验证。

---

## License

[LICENSE](LICENSE)
