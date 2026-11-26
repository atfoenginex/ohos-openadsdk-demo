import { router } from '@kit.ArkUI';
import { AdSize, AdSlot, AdSource, AdType, ATFAdSDK, FeedAd, FeedAdNodeController } from '@atf/openadsdk';
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
  DemoFeedListener,
  demoUseMockParam
} from '../demo/DemoSupport';

/**
 * 信息流广告 Demo 二级页（对齐 ios_demo/FeedViewController）：
 * 广告位 ID 可输入，加载 → 渲染到容器 → 校验有效性，事件写入日志。
 */
@Entry
@Component
struct FeedAdPage {
  @State status: string = '📰 信息流广告状态：未加载';
  @State statusColor: string = DEMO_COLOR_DEFAULT;
  @State slotID: string = BuildProfile.DEMO_FEED_SLOT_ID;
  @State logText: string = '🎯 欢迎使用信息流广告 Demo！\n点击「加载信息流广告」开始体验...\n';
  @State useMock: boolean = true;
  @State adComponent: FeedAdNodeController | null = null;

  private feedAd: FeedAd | null = null;
  private loading: boolean = false;
  /** 日志区域滚动控制器（新日志自动滚到底部） */
  private logScroller: Scroller = new Scroller();

  aboutToAppear(): void {
    this.useMock = demoUseMockParam(router.getParams() as Record<string, Object> | undefined);
  }

  aboutToDisappear(): void {
    this.adComponent = null;
    this.feedAd?.destroy();
    this.feedAd = null;
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
        Text('信息流广告 Demo')
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

          Button('🚀 加载信息流广告')
            .width('100%')
            .height(44)
            .backgroundColor(DEMO_COLOR_LOAD_BUTTON)
            .onClick(() => {
              this.loadAd();
            })

          Button('🎨 渲染信息流广告')
            .width('100%')
            .height(44)
            .backgroundColor(DEMO_COLOR_SHOW_BUTTON)
            .onClick(() => {
              this.renderAd();
            })

          Button('🔍 检查广告有效性')
            .width('100%')
            .height(44)
            .backgroundColor(DEMO_COLOR_CHECK_BUTTON)
            .onClick(() => {
              this.checkValid();
            })

          // 广告渲染容器：SDK 渲染出的模版节点挂在这里
          Stack() {
            if (this.adComponent !== null) {
              NodeContainer(this.adComponent)
                .width('100%')
                .height('100%')
            } else {
              Text('📰 信息流广告渲染区域')
                .fontSize(13)
                .fontColor('#999999')
            }
          }
          .width('100%')
          .height(this.adComponent !== null ? 160 : 120)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .clip(true)

          Text('📋 功能说明：\n• 自渲染模版：1005 单图 / 9006 左图右文 / 9007 上文下媒体 / 9008·9009 下载条 / 9010 上媒体下文案 / 9011 通知卡片\n• 严格按 style_id 渲染\n• 可见比例达 50% 上报曝光\n• 关闭即「不感兴趣」，由宿主移除')
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
    this.status = `📰 信息流广告状态：${suffix}`;
    this.statusColor = color;
  }

  private async loadAd(): Promise<void> {
    if (this.loading) {
      return;
    }
    this.loading = true;
    const slotID = this.slotID.length > 0 ? this.slotID : `demo_${AdType.feed}`;
    this.slotID = slotID;
    this.log(`🚀 开始加载信息流广告，广告位: ${slotID}`);
    this.setStatus('加载中...', DEMO_COLOR_LOADING);
    applyDemoMock(this.getUIContext().getHostContext(), AdType.feed, this.useMock);
    const adSize: AdSize = { width: 360, height: 160 };
    try {
      const ad: FeedAd = await ATFAdSDK.generateCreator<FeedAd>().load(new AdSlot(slotID, AdType.feed, adSize));
      ad.setListener(new DemoFeedListener((text: string, color: string): void => {
        this.setStatus(text, color);
      }, (text: string): void => {
        this.log(text);
      }, (): void => {
        this.closeAd();
      }));
      this.feedAd?.destroy();
      this.feedAd = ad;
      this.adComponent = null;
      this.setStatus('已加载', DEMO_COLOR_SHOWING);
      this.log('✅ 信息流广告加载成功');
    } catch (e) {
      this.setStatus('加载失败', DEMO_COLOR_ERROR);
      this.log(`❌ 加载失败: ${(e as Error).message}`);
    } finally {
      this.loading = false;
    }
  }

  private async renderAd(): Promise<void> {
    if (this.feedAd === null) {
      this.log('❌ 请先加载广告再进行渲染');
      return;
    }
    this.log('🎨 开始渲染信息流广告');
    try {
      this.adComponent = await this.feedAd.render(this.getUIContext());
      this.setStatus('已渲染', DEMO_COLOR_SHOWING);
      this.log('✅ 信息流广告渲染成功');
    } catch (e) {
      this.adComponent = null;
      this.setStatus('渲染失败', DEMO_COLOR_ERROR);
      this.log(`❌ 信息流广告渲染失败: ${(e as Error).message}`);
    }
  }

  private closeAd(): void {
    this.adComponent = null;
    this.feedAd?.destroy();
    this.feedAd = null;
    this.setStatus('已关闭（不感兴趣）', DEMO_COLOR_DEFAULT);
    this.log('🚪 广告关闭');
  }

  private checkValid(): void {
    if (this.feedAd === null) {
      this.log('🔍 尚未加载广告');
      return;
    }
    this.log(`🔍 广告有效性: ${this.feedAd.isValid()}`);
  }
}
