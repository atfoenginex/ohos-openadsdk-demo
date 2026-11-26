import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { ATFAdSDK } from '@atf/openadsdk';
import { startDemoSDK } from '../demo/DemoSdkInit';

/**
 * Demo 主页面（对齐 ios_demo/ViewController）：
 * SDK 在 EntryAbility.onCreate 里初始化，本页只展示结果；开关本地 Mock，各广告类型进入独立二级页面。
 */
@Entry
@Component
struct Index {
  @State status: string = '未初始化';
  @State adapterNames: string = '-';
  @State initialized: boolean = false;
  /** 是否用 rawfile 里的 mock_ads.json 替换 /getads 响应 */
  @State useMock: boolean = false;
  /** 启动时的自动初始化是否已触发（避免返回主页重复初始化） */
  private autoInitStarted: boolean = false;

  /** 读取已注册的适配器列表（EntryAbility 初始化时已完成注册） */
  aboutToAppear(): void {
    this.adapterNames = ATFAdSDK.getAvailableAdapterNames().join(', ');
  }

  /** 启动时同步初始化结果：EntryAbility.onCreate 已发起初始化，这里只等待同一个 Promise */
  onPageShow(): void {
    if (this.autoInitStarted) {
      return;
    }
    this.autoInitStarted = true;
    this.syncInitStatus();
  }

  /** 等待启动结果（失败时按钮可重试），并刷新页面状态 */
  private async syncInitStatus(): Promise<void> {
    this.status = '初始化中...';
    const hostContext = this.getUIContext().getHostContext();
    if (hostContext === undefined) {
      this.status = '获取 Context 失败';
      return;
    }
    // 厂商适配器要求 UIAbilityContext，这里按 Ability 上下文取
    const success: boolean = await startDemoSDK(hostContext as common.UIAbilityContext);
    this.initialized = success;
    this.status = success ? 'SDK 初始化成功' : 'SDK 初始化失败';
  }

  /** 进入广告类型二级页 */
  private openDemo(url: string): void {
    if (!this.initialized) {
      this.status = '请先初始化 SDK';
      return;
    }
    router.pushUrl({
      url: url,
      params: { useMock: this.useMock }
    }).catch((e: Error) => {
      this.status = `打开页面失败: ${e.message}`;
    });
  }

  onBackPress(): boolean {
    return ATFAdSDK.handleBackPress();
  }

  build() {
    Stack() {
      Row() {
        Column({ space: 16 }) {
          Text('ATFOHAdSDK')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1E2226')

          Row({ space: 8 }) {
            Text('使用本地 Mock')
              .fontSize(13)
              .fontColor('#666666')
            Toggle({ type: ToggleType.Switch, isOn: this.useMock })
              .onChange((isOn: boolean) => {
                this.useMock = isOn;
                if (!isOn) {
                  ATFAdSDK.clearApiMock();
                }
              })
          }

          Text(`可用适配器: ${this.adapterNames}`)
            .fontSize(13)
            .fontColor('#666666')

          Text(this.status)
            .fontSize(14)
            .fontColor(this.initialized ? '#0A8F3C' : '#B23B3B')
            .textAlign(TextAlign.Center)
            .padding(12)

          Button('1. SDK 初始化')
            .width('80%')
            .height(44)
            .backgroundColor('#0A59F7')
            .fontColor(Color.White)
            .onClick(() => {
              this.syncInitStatus();
            })

          Button('2. 开屏广告 Demo')
            .width('80%')
            .height(44)
            .backgroundColor('#1E2226')
            .fontColor(Color.White)
            .onClick(() => {
              this.openDemo('pages/SplashAdPage');
            })

          Button('3. 插屏广告 Demo')
            .width('80%')
            .height(44)
            .backgroundColor('#1E2226')
            .fontColor(Color.White)
            .onClick(() => {
              this.openDemo('pages/InterstitialAdPage');
            })

          Button('4. 激励视频广告 Demo')
            .width('80%')
            .height(44)
            .backgroundColor('#1E2226')
            .fontColor(Color.White)
            .onClick(() => {
              this.openDemo('pages/RewardVideoAdPage');
            })

          Button('5. 信息流广告 Demo')
            .width('80%')
            .height(44)
            .backgroundColor('#1E2226')
            .fontColor(Color.White)
            .onClick(() => {
              this.openDemo('pages/FeedAdPage');
            })

          Button('6. 原生自渲染广告 Demo')
            .width('80%')
            .height(44)
            .backgroundColor('#1E2226')
            .fontColor(Color.White)
            .onClick(() => {
              this.openDemo('pages/NativeAdPage');
            })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F8')
  }
}
