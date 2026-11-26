import { NodeController, router } from '@kit.ArkUI';
import {
  AdSlotBuilder,
  AdType,
  ATFAdSDK,
  NativeAd,
  NativeAdData,
  NativeAdViewArgs
} from '@atf/openadsdk';
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
  DemoAdListener,
  demoUseMockParam
} from '../demo/DemoSupport';

/**
 * 原生自渲染广告 Demo。
 * 广告位用 AdType.native：SDK 内部按 feed 请求，Api 源返回原生 loader；
 * 宿主用 NativeAdData 自绘，节点挂载后 registerView 完成曝光/点击绑定。
 */
@Entry
@Component
struct NativeAdPage {
  @State status: string = '🎨 原生自渲染广告状态：未加载';
  @State statusColor: string = DEMO_COLOR_DEFAULT;
  @State slotID: string = BuildProfile.DEMO_FEED_SLOT_ID;
  @State logText: string = '🎯 欢迎使用原生自渲染广告 Demo！\n点击「加载原生广告」开始体验...\n';
  @State dataReady: boolean = false;
  @State useMock: boolean = true;
  @State registered: boolean = false;

  private nativeAd: NativeAd | null = null;
  private adData: NativeAdData | null = null;
  private loading: boolean = false;
  private logScroller: Scroller = new Scroller();

  private readonly rootViewID: string = 'atf_native_root';
  private readonly clickViewID: string = 'atf_native_cta';
  private readonly creativeViewID: string = 'atf_native_media';

  aboutToAppear(): void {
    this.useMock = demoUseMockParam(router.getParams() as Record<string, Object> | undefined);
  }

  aboutToDisappear(): void {
    this.destroyAd();
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
        Text('原生自渲染广告 Demo')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Blank()
        Text(`广告源: ${this.useMock ? '本地 Mock' : '在线'}`)
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

          Text(`registerView: ${this.registered ? '成功' : '待注册'}`)
            .width('100%')
            .fontSize(12)
            .fontColor(this.registered ? DEMO_COLOR_SHOWING : '#999999')

          TextInput({ placeholder: '请输入原生广告位 ID', text: this.slotID })
            .height(40)
            .onChange((value: string) => {
              this.slotID = value;
            })

          Button('🚀 加载原生广告')
            .width('100%')
            .height(44)
            .backgroundColor(DEMO_COLOR_LOAD_BUTTON)
            .onClick(() => {
              this.loadAd();
            })

          Button('🔍 检查广告有效性')
            .width('100%')
            .height(44)
            .backgroundColor(DEMO_COLOR_CHECK_BUTTON)
            .onClick(() => {
              this.checkValid();
            })

          if (this.dataReady && this.adData !== null) {
            this.buildAdCard(this.adData)
          } else {
            Stack() {
              Text('🎨 原生广告渲染区域')
                .fontSize(13)
                .fontColor('#999999')
            }
            .width('100%')
            .height(120)
            .backgroundColor(Color.White)
            .borderRadius(8)
          }

          if (this.dataReady) {
            Button('关闭广告')
              .width('100%')
              .height(40)
              .backgroundColor('#E8EAF0')
              .fontColor('#333333')
              .onClick(() => {
                this.closeAd();
              })
          }

          Text('📋 功能说明：\n• AdType.native 只是客户端标记，内部按 feed 请求\n• 宿主用 NativeAdData 自绘，onAppear 后 registerView\n• 可见比例达 50% 上报曝光，点击/关闭由宿主转发\n• Api 源点击后由 SDK 打开落地页')
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

  @Builder
  buildAdCard(data: NativeAdData) {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        if (data.iconURL.length > 0) {
          Image(data.iconURL)
            .width(36)
            .height(36)
            .borderRadius(6)
            .objectFit(ImageFit.Cover)
        }
        Column({ space: 2 }) {
          Text(data.title.length > 0 ? data.title : '广告标题')
            .width('100%')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(data.desc.length > 0 ? data.desc : '广告描述')
            .width('100%')
            .fontSize(12)
            .fontColor('#666666')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text('广告')
          .fontSize(10)
          .fontColor('#999999')
          .border({ width: 1, color: '#DDDDDD', radius: 4 })
          .padding({ left: 4, right: 4, top: 1, bottom: 1 })
      }
      .width('100%')

      Stack() {
        if (data.mediaController !== null) {
          NodeContainer(data.mediaController as NodeController)
            .width('100%')
            .height('100%')
        } else if (data.imageURL.length > 0) {
          Image(data.imageURL)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
        } else if (data.videoCoverURL.length > 0) {
          Image(data.videoCoverURL)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
        } else {
          Text('媒体区域')
            .fontSize(13)
            .fontColor('#999999')
        }
      }
      .id(this.creativeViewID)
      .width('100%')
      .height(140)
      .backgroundColor('#F0F0F0')
      .borderRadius(8)
      .clip(true)

      Row({ space: 8 }) {
        Text(data.adSource.length > 0 ? data.adSource : '广告来源')
          .fontSize(11)
          .fontColor('#999999')
        Blank()
        if (data.adLogoURL.length > 0) {
          Image(data.adLogoURL)
            .width(40)
            .height(15)
            .objectFit(ImageFit.Contain)
        } else if (data.adLogoController !== null) {
          NodeContainer(data.adLogoController as NodeController)
            .width(40)
            .height(15)
        }
        Row() {
          Text(data.buttonText.length > 0 ? data.buttonText : '查看详情')
            .fontSize(13)
            .fontColor(Color.White)
        }
        .id(this.clickViewID)
        .padding({ left: 12, right: 12, top: 5, bottom: 5 })
        .backgroundColor('#FF6A00')
        .borderRadius(4)
      }
      .width('100%')
    }
    .id(this.rootViewID)
    .width('100%')
    .padding(10)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .onAppear(() => {
      this.registerView();
    })
    .onClick((event: ClickEvent) => {
      this.nativeAd?.handleClick(event);
    })
    .onVisibleAreaChange(this.ratioList(data), (_isExpanding: boolean, ratio: number) => {
      // 第一个参数是“是否在扩大”，不是实际可见性；按可见比例换算
      this.nativeAd?.onVisibleAreaChange(ratio > 0, ratio);
    })
  }

  private ratioList(data: NativeAdData): number[] {
    return data.visibleAreaRatios.length > 0 ? data.visibleAreaRatios : [0.0, 0.5];
  }

  private log(text: string): void {
    this.logText = appendLog(this.logText, text);
    setTimeout(() => {
      this.logScroller.scrollEdge(Edge.Bottom);
    }, 0);
  }

  private setStatus(suffix: string, color: string): void {
    this.status = `🎨 原生自渲染广告状态：${suffix}`;
    this.statusColor = color;
  }

  private async loadAd(): Promise<void> {
    if (this.loading) {
      return;
    }
    this.loading = true;
    this.destroyAd();
    this.setStatus('加载中...', DEMO_COLOR_LOADING);
    this.log(`🚀 开始加载原生广告，广告位: ${this.slotID}`);
    applyDemoMock(this.getUIContext().getHostContext(), AdType.native, this.useMock);
    try {
      const slot = new AdSlotBuilder()
        .slotID(this.slotID)
        .adType(AdType.native)
        .adSize({ width: 360, height: 160 })
        .build();
      const ad = await ATFAdSDK.generateCreator<NativeAd>().load(slot);
      ad.setListener(new DemoAdListener(
        (text: string, color: string): void => {
          this.setStatus(text, color);
        },
        (text: string): void => {
          this.log(text);
        }
      ));
      this.nativeAd = ad;
      const data = ad.data(this.getUIContext());
      if (data === null) {
        throw new Error('nativeData is null');
      }
      this.adData = data;
      // 先落到「已加载」再触发 dataReady：onAppear 里的 registerView 会把状态推进到「已渲染」，
      // 反过来写会把「已渲染」覆盖回「已加载」
      this.setStatus('已加载', DEMO_COLOR_SHOWING);
      this.log(`✅ 加载成功: source=${data.adSource}, materialType=${data.materialType}, isValid=${ad.isValid()}`);
      this.dataReady = true;
    } catch (e) {
      this.setStatus('加载失败', DEMO_COLOR_ERROR);
      this.log(`❌ 加载失败: ${(e as Error).message}`);
    } finally {
      this.loading = false;
    }
  }

  private registerView(): void {
    const ad = this.nativeAd;
    if (ad === null || this.registered) {
      return;
    }
    try {
      ad.registerView(this.getUIContext(),
        new NativeAdViewArgs(this.rootViewID, [this.clickViewID], [this.creativeViewID]));
      this.registered = true;
      this.setStatus('已渲染', DEMO_COLOR_SHOWING);
      this.log('✅ registerView 成功');
    } catch (e) {
      this.log(`❌ registerView 失败: ${(e as Error).message}`);
    }
  }

  private closeAd(): void {
    const ad = this.nativeAd;
    if (ad !== null) {
      ad.close();
    }
    this.destroyAd();
    this.setStatus('已关闭', DEMO_COLOR_DEFAULT);
    this.log('🚪 关闭广告');
  }

  private destroyAd(): void {
    const ad = this.nativeAd;
    this.nativeAd = null;
    this.adData = null;
    this.dataReady = false;
    this.registered = false;
    ad?.destroy();
  }

  private checkValid(): void {
    const ad = this.nativeAd;
    if (ad === null) {
      this.log('🔍 尚未加载广告');
      return;
    }
    this.log(`🔍 广告有效性: ${ad.isValid()}`);
  }
}
