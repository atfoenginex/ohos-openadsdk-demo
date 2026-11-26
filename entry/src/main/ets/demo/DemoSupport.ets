import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import {
  AdInteractionListener,
  AdType,
  ATFAdSDK,
  ATFError,
  RewardVideoAdInteractionListener
} from '@atf/openadsdk';

/** Demo 状态色板（对齐 iOS DemoConfig 的 DEMO_COLOR_*） */
export const DEMO_COLOR_DEFAULT: string = '#E8EAF0';
export const DEMO_COLOR_LOADING: string = '#B45A00';
export const DEMO_COLOR_SHOWING: string = '#0A8F3C';
export const DEMO_COLOR_ERROR: string = '#C0392B';
export const DEMO_COLOR_LOAD_BUTTON: string = '#0A6CF6';
export const DEMO_COLOR_SHOW_BUTTON: string = '#0A8F3C';
export const DEMO_COLOR_CHECK_BUTTON: string = '#6A3FB5';

/** 追加一行带时间戳的事件日志（等价 iOS addLog:） */
export function appendLog(current: string, text: string): string {
  const now = new Date();
  const pad = (value: number): string => value < 10 ? `0${value}` : `${value}`;
  const line = `[${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}] ${text}\n`;
  return `${current}${line}`;
}

/** 展示期回调：把事件写进状态栏与日志 */
export class DemoAdListener implements AdInteractionListener {
  protected readonly status: (text: string, color: string) => void;
  protected readonly log: (text: string) => void;

  constructor(status: (text: string, color: string) => void, log: (text: string) => void) {
    this.status = status;
    this.log = log;
  }

  onShow(): void {
    this.status('展示中', DEMO_COLOR_SHOWING);
    this.log('👀 广告展示成功');
  }

  onShowFailed(error: ATFError | null): void {
    this.status('展示失败', DEMO_COLOR_ERROR);
    this.log(`❌ 广告展示失败: ${error === null ? '' : error.message}`);
  }

  onClick(): void {
    this.log('👆 广告被点击');
  }

  onClose(): void {
    this.status('已关闭', DEMO_COLOR_DEFAULT);
    this.log('🚪 广告关闭');
  }
}

/** 激励视频回调：在通用事件之外补充播放完成与奖励发放 */
export class DemoRewardVideoListener extends DemoAdListener implements RewardVideoAdInteractionListener {
  onPlayFinished(): void {
    this.status('播放完成', DEMO_COLOR_SHOWING);
    this.log('🎉 激励视频播放完成');
  }

  onRewardEffective(isEffective: boolean, verify: boolean): void {
    this.status('奖励已发放', DEMO_COLOR_SHOWING);
    this.log(`🎁 奖励发放: ${isEffective}, 服务端验证: ${verify}`);
  }
}

/** 信息流回调：在通用事件之外补充关闭处理（渲染结果由 render() 的 Promise 表达） */
export class DemoFeedListener extends DemoAdListener {
  private readonly closeHandler: () => void;

  constructor(status: (text: string, color: string) => void, log: (text: string) => void,
    closeHandler: () => void) {
    super(status, log);
    this.closeHandler = closeHandler;
  }

  onClose(): void {
    super.onClose();
    this.closeHandler();
  }
}

/** 把 rawfile 里的 mock 广告改写成指定广告类型（仅供 Demo 本地联调） */
export function demoMockResponse(context: common.Context | undefined, adType: AdType): string | null {
  if (context === undefined) {
    return null;
  }
  try {
    const bytes = context.resourceManager.getRawFileContentSync('mock_ads.json');
    const json = JSON.parse(util.TextDecoder.create('utf-8').decodeToString(bytes)) as Record<string, Object>;
    const ads = json['ads'];
    if (Array.isArray(ads) && ads.length > 0) {
      const ad = ads[0] as Record<string, Object>;
      // native 只是客户端标记：服务端仍按 feed 请求，并要求自渲染
      ad['ad_type'] = adType === AdType.native ? AdType.feed : adType;
      if (adType === AdType.native) {
        ad['render_type'] = 1;
      }
    }
    return JSON.stringify(json);
  } catch (e) {
    return null;
  }
}

/** 按开关应用 mock：true 走本地 mock，false 走真实请求 */
export function applyDemoMock(context: common.Context | undefined, adType: AdType, useMock: boolean): void {
  if (!useMock) {
    ATFAdSDK.clearApiMock();
    return;
  }
  const mock = demoMockResponse(context, adType);
  if (mock !== null) {
    ATFAdSDK.setApiMock('getads', mock);
  }
}

/** 读取二级页面入参里的 mock 开关 */
export function demoUseMockParam(params: Record<string, Object> | undefined): boolean {
  if (params === undefined || params['useMock'] === undefined) {
    return true;
  }
  return params['useMock'] as boolean;
}
