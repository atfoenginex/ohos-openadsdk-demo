# ATFOHAdSDK 鸿蒙接入示例

`@atf/openadsdk`（鸿蒙广告 SDK）的**可运行接入示例**。本仓库依赖的是 **ohpm 私仓上已发布的版本**，不是 SDK 源码，所以它同时是一份「接入方视角」的参考实现，可以直接对照着改到你自己的 App 里。

| 包 | 本示例使用的版本 |
|---|---|
| `@atf/openadsdk` | 0.0.2 |
| `@atf/gromore` | 0.0.1 |

## 环境准备

1. **DevEco Studio**（含 hvigor 与 ohpm）。下面的命令假定它装在 `/Applications/DevEco-Studio.app`。
2. **配置 `@atf` 私仓**。本仓库根目录的 `.ohpmrc` 已写好，正常 clone 后即可用：

   ```ini
   @atf:registry=https://ohpm.cxwlad.com/repos/ohpm/
   registry=https://ohpm.openharmony.cn/ohpm/,https://artifact.bytedance.com/repository/byted-ohpm/
   ```

   - 第一行：SDK 本体与已发布适配器所在的私仓。**需要凭据**，账号由 SDK 负责人分配；
     凭据写在你自己的 `~/.ohpm/.ohpmrc`（不要提交到仓库）。
   - 第二行：`@atf/gromore` 依赖 `@csj/openadsdk`，它只在**字节 ohpm 仓库**有坐标，
     所以必须带上 `https://artifact.bytedance.com/repository/byted-ohpm/`（注意是 `byted-ohpm`）。

## 运行

在仓库根目录：

```bash
export DEVECO_SDK_HOME="/Applications/DevEco-Studio.app/Contents/sdk"
export NODE_HOME="/Applications/DevEco-Studio.app/Contents/tools/node"
export PATH="$NODE_HOME/bin:/Applications/DevEco-Studio.app/Contents/tools/ohpm/bin:$PATH"
OHPM="/Applications/DevEco-Studio.app/Contents/tools/ohpm/bin/ohpm"
HV="/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw"

"$OHPM" install --all
"$HV" assembleHap --mode module -p module=entry@default -p product=default --no-daemon
```

装到设备：用 DevEco Studio 打开本工程，**Project Structure → Signing Configs** 勾选自动签名
（本仓库不含任何签名材料，`build-profile.json5` 里也没有 `signingConfigs`），然后直接 Run。

## 目录结构

```
ohos-openadsdk-demo/
├── .ohpmrc                      # @atf 私仓 + 字节 ohpm 仓库
├── build-profile.json5          # 工程配置（不含签名，用你自己的）
├── oh-package.json5             # 根清单
├── AppScope/                    # 应用级配置与图标
└── entry/                       # 示例宿主 HAP
    ├── build-profile.json5      # 演示参数（appID / mediaID / 广告位 ID）
    ├── oh-package.json5         # SDK 依赖在这里
    └── src/main/ets/
        ├── entryability/EntryAbility.ets   # 生命周期入口
        ├── demo/DemoSdkInit.ets            # SDK 初始化 + 适配器注册 + 权限申请
        ├── demo/DemoSupport.ets            # 演示用的通用工具
        └── pages/                          # 开屏 / 激励视频 / 插屏 / 信息流 / 原生 五种广告示例
```

演示参数集中在 `entry/build-profile.json5` 的 `buildProfileFields`（`DEMO_APP_ID`、
`DEMO_MEDIA_ID`、各广告位 ID）。**换成你自己的参数**即可。

## 接入到你自己的 App

### 1. 声明权限

`module.json5` 里需要（SDK 联网、网络状态与设备标识）：

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

> **设备标识**：鸿蒙没有 IDFA / IDFV，广告场景只有 **OAID**。`APP_TRACKING_CONSENT` 是
> `user_grant` 权限，除了声明还要在用户同意隐私政策后调用
> `abilityAccessCtrl.requestPermissionsFromUser` 动态申请（见 `demo/DemoSdkInit.ets`）。
> 未声明或用户拒绝时，系统返回全 0 占位值，SDK 原样上报表示「未授权」，不会崩溃也不阻塞启动。

### 2. 加依赖

```json5
// 你的 entry/oh-package.json5
{
  "dependencies": {
    "@atf/openadsdk": "0.0.2",
    "@atf/gromore": "0.0.1"
  }
}
```

### 3. 初始化

```ts
import { ATFAdSDK, SDKConfig, EnvironmentType, AdSlot, AdSlotBuilder, AdType } from '@atf/openadsdk';
import { ATFGroMoreAdapter } from '@atf/gromore';

// 厂商适配器必须在 SDK 初始化之前注册（幂等，重复调用无副作用）
ATFGroMoreAdapter.register();

const config = SDKConfig.builder()
  .appID('你的 appID')
  .mediaID('你的 mediaID')
  .secretKey('你的 secretKey')
  .environmentType(EnvironmentType.production)
  .build();

// Context 由宿主注入：页面里用 getUIContext().getHostContext()，
// UIAbility 里可直接用 this.context（getContext() 已弃用，不要再用）
const context = this.getUIContext().getHostContext();
if (context === undefined) {
  return;
}

// 必须在用户同意隐私政策之后调用
const success: boolean = await ATFAdSDK.start(context, config);

const slot = new AdSlotBuilder()
  .slotID('你的广告位ID')
  .adType(AdType.draw)
  .build();
```

完整可运行版本见 `entry/src/main/ets/demo/DemoSdkInit.ets`。

## 接入更多厂商

本示例默认只带 `@atf/gromore`（依赖全部来自可公开访问的仓库）。其余适配器按下表处理：

| 适配器 | 厂商 SDK 形态 | 接入方式 |
|---|---|---|
| `@atf/gromore` 穿山甲 | 远程 `@csj/openadsdk` 7.7.0 | **已默认开启**，只需 `.ohpmrc` 配好字节仓库 |
| `@atf/gdt` 优量汇 | 优量汇在 ohpm **没有坐标** | 需自备厂商 HAR，见下 |
| `@atf/kuaishou` 快手 | 厂商 SDK 内嵌在适配器 HAR 内 | 待发布，发布后按版本号加依赖即可 |
| `@atf/meishu` 美数 | 远程 `@admate/ms_sdk`（ohpm 公开仓） | 待发布，发布后按版本号加依赖即可 |

### 接入优量汇 `@atf/gdt`

优量汇 SDK 在 ohpm 上没有公开坐标，适配器采用 **peer 模式**：`@atf/gdt` 自己不声明它，
必须由接入方提供，否则编译期会报
`Failed to get a resolved OhmUrl for "@gdt/gdt-union-sdk"`。

1. 从优量汇后台下载 HarmonyOS SDK，得到 `GDTUnionSDK-default-release.har`；
2. 放到 `entry/libs/GDTUnionSDK-default-release.har`（本仓库 `.gitignore` 已排除 `entry/libs/*.har`，
   厂商产物不要提交入库）；
3. 在 `entry/oh-package.json5` 补两条依赖：

   ```json5
   {
     "dependencies": {
       "@atf/openadsdk": "0.0.2",
       "@atf/gromore": "0.0.1",
       "@atf/gdt": "0.0.1",
       "@gdt/gdt-union-sdk": "file:./libs/GDTUnionSDK-default-release.har"
     }
   }
   ```

4. 放开 `demo/DemoSdkInit.ets` 里对应的 import 与 `ATFGDTAdapter.register();`。

## 常见问题

| 现象 | 原因 | 处理 |
|---|---|---|
| `package '@atf/openadsdk@0.0.2' not found` | `.ohpmrc` 没配 `@atf:registry`，或私仓凭据缺失 | 确认 `.ohpmrc` 有 `@atf:registry`，并在 `~/.ohpm/.ohpmrc` 配好凭据 |
| `package '@csj/openadsdk@7.7.0' not found` | 用的 `@atf/gromore`，但 `.ohpmrc` 没有字节仓库 | `registry` 里加上 `https://artifact.bytedance.com/repository/byted-ohpm/` |
| `Failed to get a resolved OhmUrl for "@gdt/gdt-union-sdk"` | 用了 `@atf/gdt` 但没声明优量汇厂商 HAR | 见上文「接入优量汇」 |
| 广告源已安装但没参与竞价 | 适配器没有在 SDK 初始化前注册 | 调用 `ATFxAdapter.register()`，放在 `ATFAdSDK.start` 之前 |
| 上报的 `oaid` 是全 0 | 未声明或用户拒绝了 `APP_TRACKING_CONSENT` | 见「1. 声明权限」，并做动态申请 |
| 模拟器上拉不到广告 | 部分厂商不向模拟器下发库存 | 用真机验证 |

## 相关仓库

- SDK 本体与适配器源码：`atfoenginex/ohos_openadsdk`
