import { PeriodData } from '../model/PeriodData';

// 定义引导步骤接口
export interface OnboardingStep {
  title: string;
  description: string;
  image?: string;
}

@Component
export struct Onboarding {
  private periodData: PeriodData;
  private currentStep: number = 0;
  private steps: Array<OnboardingStep> = [
    {
      title: '欢迎使用 Leaf Moon',
      description: '您的月经周期智能助手，帮助您轻松追踪和预测月经周期。'
    },
    {
      title: '记录月经',
      description: '点击「记录月经开始」按钮，快速记录您的月经开始日期。'
    },
    {
      title: '查看预测',
      description: '系统会根据您的记录智能预测下次月经日期和排卵期。'
    },
    {
      title: '记录症状',
      description: '可以记录月经期间的症状，帮助您更好地了解身体状况。'
    },
    {
      title: '个性化设置',
      description: '在设置页面可以调整周期长度、启用提醒等个性化选项。'
    }
  ];

  constructor(periodData: PeriodData) {
    this.periodData = periodData;
  }

  @Builder
  private renderStep(step: OnboardingStep) {
    Column() {
      Text(step.title)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })
        .textAlign(TextAlign.Center)
        .width('80%');

      Text(step.description)
        .fontSize(16)
        .textAlign(TextAlign.Center)
        .width('80%')
        .margin({ bottom: 24 });

      if (step.image) {
        Image(step.image)
          .width(200)
          .height(200)
          .margin({ bottom: 24 });
      }
    }
  }

  @Builder
  private renderIndicator() {
    Row() {
      ForEach(this.steps, (_, index) => {
        Ellipse()
          .width(index === this.currentStep ? 24 : 12)
          .height(12)
          .fill(index === this.currentStep ? '#FF6B6B' : '#CCCCCC')
          .margin({ horizontal: 8 });
      });
    }
  }

  private nextStep() {
    if (this.currentStep < this.steps.length - 1) {
      this.currentStep++;
    } else {
      this.completeOnboarding();
    }
  }

  private skipOnboarding() {
    this.completeOnboarding();
  }

  private completeOnboarding() {
    const settings = this.periodData.getSettings();
    settings.onboardingCompleted = true;
    this.periodData.updateSettings(settings);
  }

  build() {
    Column() {
      // 背景遮罩
      Column() {
        // 引导内容容器
        Column() {
          // 步骤内容
          this.renderStep(this.steps[this.currentStep]);

          // 指示器
          this.renderIndicator();

          // 操作按钮
          Column() {
            Button(this.currentStep < this.steps.length - 1 ? '下一步' : '完成')
              .width('80%')
              .height(48)
              .backgroundColor('#FF6B6B')
              .fontColor('#FFFFFF')
              .borderRadius(24)
              .margin({ bottom: 12 })
              .onClick(() => this.nextStep());

            if (this.currentStep < this.steps.length - 1) {
              Button('跳过')
                .width('80%')
                .height(48)
                .backgroundColor('transparent')
                .fontColor('#666666')
                .borderRadius(24)
                .onClick(() => this.skipOnboarding());
            }
          }
        }
        .width(320)
        .height(480)
        .backgroundColor('#FFFFFF')
        .borderRadius(20)
        .padding(24)
        .shadow({
          radius: 10,
          color: '#00000020',
          offsetX: 0,
          offsetY: 5
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('rgba(0, 0, 0, 0.5)')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .zIndex(9999)
  }
}