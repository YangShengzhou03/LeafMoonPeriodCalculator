import { TrendChart } from '../components/TrendChart';
import { PeriodData, CycleTrendData, CycleStats } from '../model/PeriodData';
import router from '@ohos.router';
import { FontWeight } from '@ohos.arkui.advanced.Text';

@Entry
@Component
struct AnalysisPage {
  private periodData: PeriodData = new PeriodData();

  // 获取趋势数据
  private getTrendData(): CycleTrendData {
    return this.periodData.getCycleTrendData();
  }

  // 获取统计数据
  private getStats(): CycleStats {
    return this.periodData.getCycleStats();
  }

  build() {
    Column() {
      // 页面标题栏
      Row() {
        Button() {
          Text('←')
            .fontSize(20)
        }
        .type(ButtonType.Circle)
        .backgroundColor('#F5F5F5')
        .onClick(() => {
          router.back().catch((err: Error) => {
            console.error('返回失败:', err);
          });
        })

        NavigationTitle() {
          Text('数据分析')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
        }
        .margin({ left: 10 })

        Blank()
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems('Center')

      ScrollView() {
        Column() {
          // 趋势图表
          Column() {
            Text('周期趋势')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 16 })

            // 趋势图组件
            TrendChart(
              data: this.getTrendData(),
              width: 320,
              height: 240
            )
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ bottom: 12 })

          // 统计信息卡片
          Column() {
            Text('周期统计')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 16 })

            Row() {
              // 平均周期长度
              Column() {
                Text('平均周期')
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ bottom: 4 })

                Text(this.getStats().averageCycleLength + ' 天')
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FF6B6B')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)

              Divider()
                .vertical(true)
                .width(1)
                .backgroundColor('#E0E0E0')

              // 平均经期长度
              Column() {
                Text('平均经期')
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ bottom: 4 })

                Text(this.getStats().averagePeriodLength + ' 天')
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#4ECDC4')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)
            }

            Divider()
              .margin({ top: 16, bottom: 16 })

            Row() {
              // 记录次数
              Column() {
                Text('记录次数')
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ bottom: 4 })

                Text(this.getStats().recordCount.toString())
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#95E1D3')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)

              Divider()
                .vertical(true)
                .width(1)
                .backgroundColor('#E0E0E0')

              // 周期波动
              Column() {
                Text('周期波动')
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ bottom: 4 })

                Text(this.getStats().cycleVariability + ' 天')
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#F38181')
              }
              .flexGrow(1)
              .alignItems(HorizontalAlign.Center)
            }

            // 统计说明
            Column() {
              Text('周期波动说明：')
                .fontSize(12)
                .fontColor('#666666')
                .margin({ top: 16, bottom: 4 })
                .textAlign(TextAlign.Start)

              if (this.getStats().cycleVariability < 2) {
                Text('您的周期非常规律，预测准确率较高')
                  .fontSize(12)
                  .fontColor('#4CAF50')
                  .textAlign(TextAlign.Start)
              } else if (this.getStats().cycleVariability < 5) {
                Text('您的周期比较规律，预测结果基本准确')
                  .fontSize(12)
                  .fontColor('#FFC107')
                  .textAlign(TextAlign.Start)
              } else {
                Text('您的周期波动较大，建议记录更多数据以提高预测准确率')
                  .fontSize(12)
                  .fontColor('#FF5722')
                  .textAlign(TextAlign.Start)
              }
            }
            .padding({ top: 12 })
            .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ bottom: 12 })

          // 图表说明
          Column() {
            Text('图表说明')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 12 })

            Text('• 趋势图展示了您最近几个周期的变化规律')
              .fontSize(12)
              .fontColor('#666666')
              .margin({ bottom: 4 })
              .textAlign(TextAlign.Start)

            Text('• 记录的数据越多，图表分析越准确')
              .fontSize(12)
              .fontColor('#666666')
              .margin({ bottom: 4 })
              .textAlign(TextAlign.Start)

            Text('• 建议连续记录3个周期以上的数据')
              .fontSize(12)
              .fontColor('#666666')
              .textAlign(TextAlign.Start)
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
        }
        .padding(16)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
