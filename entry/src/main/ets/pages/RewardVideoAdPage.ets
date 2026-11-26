import { router, window } from '@kit.ArkUI';
import { AdSize, AdSlot, AdSource, AdType, ATFAdSDK, RewardVideoAd } from '@atf/openadsdk';
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
  DemoRewardVideoListener,
  demoUseMockParam
} from '../demo/DemoSupport';

/** 激励视频 Demo 二级页：广告位 ID 可输入，加载 / 展示 / 校验分步操作 */
@Entry
@Component
struct RewardVideoAdPage {
  @State status: string = '🎬 激励视频状态：未加载';
  @State statusColor: string = DEMO_COLOR_DEFAULT;
  @State slotID: string = BuildProfile.DEMO_REWARD_SLOT_ID;
  @State logText: string = '🎯 欢迎使用激励视频 Demo！\n点击「加载激励视频」开始体验...\n';
  @State useMock: boolean = true;

  private rewardAd: RewardVideoAd | null = null;
  private loading: boolean = false;
  /** 日志区域滚动控制器（新日志自动滚到底部） */
  private logScroller: Scroller = new Scroller();

  aboutToAppear(): void {
    this.useMock = demoUseMockParam(router.getParams() as Record<string, Object> | undefined);
  }

  aboutToDisappear(): void {
    this.rewardAd?.destroy();
    this.rewardAd = null;
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
        Text('激励视频 Demo')
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

          Button('🚀 加载激励视频')
            .width('100%')
            .height(44)
            .backgroundColor(DEMO_COLOR_LOAD_BUTTON)
            .onClick(() => {
              this.loadAd();
            })

          Button('📺 展示激励视频')
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

          Text('📋 功能说明：\n• 按服务端 rwd_cfg.rate 进度发奖，默认 100%\n• 未发奖关闭二次确认（继续观看/放弃奖励）\n• 播放完成展示结束页\n• 静音开关、落地页期间暂停')
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
    this.status = `🎬 激励视频状态：${suffix}`;
    this.statusColor = color;
  }

  private async loadAd(): Promise<void> {
    if (this.loading) {
      return;
    }
    this.loading = true;
    const slotID = this.slotID.length > 0 ? this.slotID : `demo_${AdType.rewardVideo}`;
    this.slotID = slotID;
    this.log(`🚀 开始加载激励视频广告，广告位: ${slotID}`);
    this.setStatus('加载中...', DEMO_COLOR_LOADING);
    applyDemoMock(this.getUIContext().getHostContext(), AdType.rewardVideo, this.useMock);
    const adSize: AdSize = { width: 360, height: 640 };
    try {
      const ad: RewardVideoAd =
        await ATFAdSDK.generateCreator<RewardVideoAd>().load(new AdSlot(slotID, AdType.rewardVideo, adSize));
      ad.setListener(new DemoRewardVideoListener((text: string, color: string): void => {
        this.setStatus(text, color);
      }, (text: string): void => {
        this.log(text);
      }));
      this.rewardAd?.destroy();
      this.rewardAd = ad;
      this.setStatus('已加载', DEMO_COLOR_SHOWING);
      this.log('✅ 激励视频加载成功');
    } catch (e) {
      this.setStatus('加载失败', DEMO_COLOR_ERROR);
      this.log(`❌ 加载失败: ${(e as Error).message}`);
    } finally {
      this.loading = false;
    }
  }

  private showAd(): void {
    const stage = AppStorage.get<window.WindowStage>('windowStage');
    if (this.rewardAd === null) {
      this.log('❌ 请先加载广告');
      return;
    }
    if (stage === undefined) {
      this.log('❌ windowStage 未就绪');
      return;
    }
    this.setStatus('展示中', DEMO_COLOR_SHOWING);
    this.log('📺 展示激励视频');
    this.rewardAd.show(stage);
  }

  private checkValid(): void {
    if (this.rewardAd === null) {
      this.log('🔍 尚未加载广告');
      return;
    }
    this.log(`🔍 广告有效性: ${this.rewardAd.isValid()}`);
  }
}
