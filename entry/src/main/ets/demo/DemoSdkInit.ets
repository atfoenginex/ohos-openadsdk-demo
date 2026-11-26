import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ATFAdSDK, EnvironmentType, SDKConfig } from '@atf/openadsdk';
import { ATFGroMoreAdapter } from '@atf/gromore';
// 接入其它厂商时按 README「接入更多厂商」一节添加依赖后再放开对应 import：
// import { ATFGDTAdapter } from '@atf/gdt';
// import { ATFKuaiShouAdapter } from '@atf/kuaishou';
// import { ATFMeiShuAdapter } from '@atf/meishu';
import BuildProfile from 'BuildProfile';

const DOMAIN: number = 0x0000;
const TAG: string = 'ATFOHAdSDKDemo';

/** 启动中的 Promise：EntryAbility.onCreate 发起，页面只等待同一个结果，不重复初始化 */
let startPromise: Promise<boolean> | null = null;

/**
 * 申请 OAID 所需的跟踪权限（ohos.permission.APP_TRACKING_CONSENT）。
 * 鸿蒙没有 IDFA/IDFV，广告标识只有 OAID；未授权时系统返回全 0 占位值。
 */
async function requestTrackingPermission(context: common.UIAbilityContext): Promise<void> {
  const permissions: Permissions[] = ['ohos.permission.APP_TRACKING_CONSENT'];
  try {
    const atManager = abilityAccessCtrl.createAtManager();
    const result = await atManager.requestPermissionsFromUser(context, permissions);
    hilog.info(DOMAIN, TAG, '跟踪权限申请结果: %{public}s', JSON.stringify(result.authResults));
  } catch (e) {
    hilog.warn(DOMAIN, TAG, '跟踪权限申请失败: %{public}s', (e as Error).message);
  }
}

async function doStart(context: common.UIAbilityContext): Promise<boolean> {
  const config = SDKConfig.builder()
    .appID(BuildProfile.DEMO_APP_ID)
    .mediaID(BuildProfile.DEMO_MEDIA_ID)
    .secretKey(BuildProfile.DEMO_SECRET_KEY)
    // 不注入伪造 OAID：优量汇等厂商按设备号匹配库存与测试设备白名单，假值会直接导致无填充
    .environmentType(EnvironmentType.development)
    .build();
  // 先拿跟踪权限，再启动 SDK；Demo 通过 SDKConfig 注入伪造 OAID，未授权也能带上该值
  await requestTrackingPermission(context);
  const success: boolean = await ATFAdSDK.start(context, config);
  hilog.info(DOMAIN, TAG, 'SDK 初始化%{public}s', success ? '成功' : '失败');
  return success;
}

/**
 * 启动 Demo 的 SDK：EntryAbility.onCreate 触发，页面用同一个 Promise 拿结果。
 * 失败时清空缓存，页面上的「SDK 初始化」按钮可以重试。
 */
export function startDemoSDK(context: common.UIAbilityContext): Promise<boolean> {
  // 厂商适配器必须在 SDK 初始化前注册（幂等）；放在这里保证 onCreate 里也不会漏。
  // 未在本仓默认开启的厂商见 README「接入更多厂商」。
  ATFGroMoreAdapter.register();
  if (startPromise !== null) {
    return startPromise;
  }
  startPromise = doStart(context).then((success: boolean): boolean => {
    if (!success) {
      startPromise = null;
    }
    return success;
  });
  return startPromise;
}
