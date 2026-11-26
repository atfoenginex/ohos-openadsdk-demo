import { display, router, window } from '@kit.ArkUI';
import { AdSize, AdSlot, AdSource, AdType, ATFAdSDK, SplashAd } from '@atf/openadsdk';
import BuildProfile from 'BuildProfile';
import {
  appendLog,
  applyDemoMock,
  DEMO_COLOR_CHECK_BUTTON,
  DEMO_COLOR_DEFAULT,
  DEMO_COLOR_ERROR,
  DEMO_COLOR_LOAD_BUTTON,
  DEMO_COLOR_LOADING,
  DEMO_COLOR_SHOWING,
  DEMO_COLOR_SHOW_BUTTON,
  DemoAdListener,
  demoUseMockParam
} from '../demo/DemoSupport';

/** 宿主自定义开屏底部视图 */
@Builder
function splashBottomBar() {
  Row({ space: 8 }) {
    Text('ATF')
      .fontSize(15)
      .fontWeight(FontWeight.Bold)
      .fontColor(Color.White)
    Text('宿主底部视图')
      .fontSize(12)
      .fontColor('#CCFFFFFF')
    Blank()
    Text('了解更多')
      .fontSize(12)
      .fontColor('#CCFFFFFF')
  }
  .width('100%')
  .height(88)
  .padding({ left: 16, right: 16, bottom: 24 })
  .backgroundColor('#B3000000')
}

const splashBottomView: WrappedBuilder<[]> = wrapBuilder(splashBottomBar);

/** 开屏广告 Demo 二级页：广告位 ID 可输入，加载 / 展示 / 校验分步操作 */
@Entry
@Component
struct SplashAdPage {
  @State status: string = '📱 开屏广告状态：未加载';
  @State statusColor: string = DEMO_COLOR_DEFAULT;
  @State slotID: string = BuildProfile.DEMO_SPLASH_SLOT_ID;
  @State logText: string = '🎯 欢迎使用开屏广告 Demo！\n点击「加载开屏广告」开始体验...\n';
  @State useMock: boolean = true;

  private splashAd: SplashAd | null = null;
  private loading: boolean = false;
  /** 日志区域滚动控制器（新日志自动滚到底部） */
  private logScroller: Scroller = new Scroller();

  aboutToAppear(): void {
    this.useMock = demoUseMockParam(router.getParams() as Record<string, Object> | undefined);
  }

  aboutToDisappear(): void {
    this.splashAd?.destroy();
    this.splashAd = null;
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        Button('返回')
          .height(32)
          .fontSize(14)
          .backgroundColor('#E8EAF0')
          .fontColor('#333333')
          .onClick(() => {
            router.back();
          })
        Text('开屏广告 Demo')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Blank()
        Text(`广告源: ${AdSource.api}`)
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)

      Scroll() {
        Column({ space: 12 }) {
          Text(this.status)
            .width('100%')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
            .padding(10)
            .backgroundColor(this.statusColor)
            .borderRadius(8)

          TextInput({ placeholder: '请输入广告位 ID', text: this.slotID })
            .height(40)
            .onChange((value: string) => {
              this.slotID = value;
            })

          Button('🚀 加载开屏广告')
            .width('100%')
            .height(44)
            .backgroundColor(DEMO_COLOR_LOAD_BUTTON)
            .onClick(() => {
              this.loadAd();
            })

          Button('📺 展示开屏广告')
            .width('100%')
            .height(44)
            .backgroundColor(DEMO_COLOR_SHOW_BUTTON)
            .onClick(() => {
              this.showAd();
            })

          Button('🔍 检查广告有效性')
            .width('100%')
            .height(44)
            .backgroundColor(DEMO_COLOR_CHECK_BUTTON)
            .onClick(() => {
              this.checkValid();
            })

          Text('📋 功能说明：\n• 支持视频和图片开屏广告\n• 摇一摇/上滑互动\n• 智能跳转（WebView/DeepLink/应用市场）\n• 倒计时跳过按钮')
            .width('100%')
            .fontSize(13)
            .fontColor('#666666')
            .padding(10)
            .backgroundColor(Color.White)
            .borderRadius(8)

          Text('📝 事件日志：')
            .width('100%')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)

          Scroll(this.logScroller) {
            Column() {
              Text(this.logText)
                .width('100%')
                .fontSize(12)
                .fontColor('#333333')
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .height(220)
          .align(Alignment.Top)
          .scrollBar(BarState.Auto)
          .padding(10)
          .backgroundColor(Color.White)
          .borderRadius(8)
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F8')
  }

  private log(text: string): void {
    this.logText = appendLog(this.logText, text);
    setTimeout(() => {
      this.logScroller.scrollEdge(Edge.Bottom);
    }, 0);
  }

  private setStatus(suffix: string, color: string): void {
    this.status = `📱 开屏广告状态：${suffix}`;
    this.statusColor = color;
  }

  private async loadAd(): Promise<void> {
    if (this.loading) {
      return;
    }
    this.loading = true;
    const slotID = this.slotID.length > 0 ? this.slotID : `demo_${AdType.splash}`;
    this.slotID = slotID;
    this.log(`🚀 开始加载开屏广告，广告位: ${slotID}`);
    this.setStatus('加载中...', DEMO_COLOR_LOADING);
    // 先丢弃旧广告：加载中或加载失败时点「展示」不应再出现上一支已展示过的广告
    this.splashAd?.destroy();
    this.splashAd = null;
    applyDemoMock(this.getUIContext().getHostContext(), AdType.splash, this.useMock);
    // adSize 即广告区尺寸（vp）：厂商开屏 acceptSize 直接透传该值。
    // 对齐 GroMore 官方要求：宽=屏宽，高=屏高 − 底部 Logo 高度
    const screen = display.getDefaultDisplaySync();
    const screenWidth: number = screen.width / screen.densityPixels;
    const screenHeight: number = screen.height / screen.densityPixels;
    const adSize: AdSize = { width: screenWidth, height: screenHeight - 88 };
    try {
      const ad: SplashAd = await ATFAdSDK.generateCreator<SplashAd>().load(new AdSlot(slotID, AdType.splash, adSize));
      ad.setListener(new DemoAdListener((text: string, color: string): void => {
        this.setStatus(text, color);
      }, (text: string): void => {
        this.log(text);
      }));
      this.splashAd = ad;
      this.setStatus('已加载', DEMO_COLOR_SHOWING);
      this.log('✅ 开屏广告加载成功');
    } catch (e) {
      this.setStatus('加载失败', DEMO_COLOR_ERROR);
      this.log(`❌ 加载失败: ${(e as Error).message}`);
    } finally {
      this.loading = false;
    }
  }

  private showAd(): void {
    const stage = AppStorage.get<window.WindowStage>('windowStage');
    if (this.splashAd === null) {
      this.log('❌ 请先加载广告');
      return;
    }
    if (stage === undefined) {
      this.log('❌ windowStage 未就绪');
      return;
    }
    this.setStatus('展示中', DEMO_COLOR_SHOWING);
    this.log('📺 展示开屏广告');
    this.splashAd.show(stage, splashBottomView);
  }

  private checkValid(): void {
    if (this.splashAd === null) {
      this.log('🔍 尚未加载广告');
      return;
    }
    this.log(`🔍 广告有效性: ${this.splashAd.isValid()}`);
  }
}
