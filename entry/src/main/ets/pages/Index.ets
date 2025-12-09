import { PeriodData } from '../model/PeriodData';
import { PeriodCalculator } from '../utils/PeriodCalculator';
import { Color, FontWeight, FlexAlign, FlexDirection, ItemAlign } from '@kit.ArkUI';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  @State periodData: PeriodData = new PeriodData();
  @State currentDate: Date = new Date();
  @State showDatePicker: boolean = false;
  @State selectedDate: Date = new Date();

  // 获取当前周期阶段
  getCurrentPhase(): string {
    const latestRecord = this.periodData.getLatestRecord();
    const settings = this.periodData.getSettings();
    const phase = PeriodCalculator.getCurrentCyclePhase(
      this.currentDate,
      latestRecord,
      settings
    );

    switch (phase) {
      case 'period':
        return '月经期';
      case 'ovulation':
        return '排卵日';
      case 'fertile':
        return '易孕期';
      case 'safe':
        return '安全期';
      case 'approaching':
        return '即将来月经';
      default:
        return '正常时期';
    }
  }

  // 获取阶段颜色
  getPhaseColor(): string {
    const latestRecord = this.periodData.getLatestRecord();
    const settings = this.periodData.getSettings();
    const phase = PeriodCalculator.getCurrentCyclePhase(
      this.currentDate,
      latestRecord,
      settings
    );

    switch (phase) {
      case 'period':
        return '#FF6B6B'; // 红色
      case 'ovulation':
        return '#FFD93D'; // 黄色
      case 'fertile':
        return '#FF9F43'; // 橙色
      case 'safe':
        return '#6BCB77'; // 绿色
      case 'approaching':
        return '#FF8787'; // 浅红色
      default:
        return '#4D96FF'; // 蓝色
    }
  }

  // 获取距离下次月经的天数
  getDaysUntilNextPeriod(): number {
    const latestRecord = this.periodData.getLatestRecord();
    const settings = this.periodData.getSettings();
    return PeriodCalculator.daysUntilNextPeriod(latestRecord, settings);
  }

  // 打开日期选择器
  openDatePicker() {
    this.showDatePicker = true;
  }

  // 添加周期记录
  async addPeriodRecord() {
    const settings = this.periodData.getSettings();
    await this.periodData.addRecord({
      startDate: this.selectedDate,
      endDate: PeriodCalculator.addDays(this.selectedDate, settings.averagePeriodLength - 1),
      cycleLength: settings.averageCycleLength,
      periodLength: settings.averagePeriodLength
    });
  }

  build() {
    Column() {
      // 顶部信息栏
      Stack() {
        Column() {
          Text('LeafMoon')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .color(Color.White)
          Text('生理期计算器')
            .fontSize(14)
            .color(Color.White)
        }
        .padding(20)
      }
      .width('100%')
      .height(120)
      .backgroundColor('#FF6B6B')
      .borderRadius(0, 0, 20, 20)

      // 当前状态卡片
      Column() {
        Text(this.getCurrentPhase())
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .color(this.getPhaseColor())
        Text(`距离下次月经还有 ${this.getDaysUntilNextPeriod()} 天`)
          .fontSize(14)
          .color('#666666')
          .margin({ top: 8 })
      }
      .width('90%')
      .padding(20)
      .margin({ top: -30 })
      .backgroundColor(Color.White)
      .borderRadius(15)
      .shadow({
        radius: 10,
        color: 'rgba(0, 0, 0, 0.1)',
        offsetX: 0,
        offsetY: 5
      })

      // 快捷操作按钮
      Row() {
        Button('记录月经')
          .width('45%')
          .height(50)
          .backgroundColor('#FF6B6B')
          .fontColor(Color.White)
          .borderRadius(10)
          .onClick(() => this.openDatePicker())

        Button('查看日历')
          .width('45%')
          .height(50)
          .backgroundColor('#4D96FF')
          .fontColor(Color.White)
          .borderRadius(10)
          .onClick(() => {
            router.pushUrl({
              url: 'pages/CalendarPage'
            });
          })
      }
      .width('90%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 20 })

      // 预测信息卡片
      Column() {
        Text('周期预测')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .color('#333333')
          .alignSelf(ItemAlign.Start)

        const latestRecord = this.periodData.getLatestRecord();
        const settings = this.periodData.getSettings();
        const prediction = PeriodCalculator.predictNextPeriod(latestRecord, settings);

        Flex({ direction: FlexDirection.Column, gap: 15 }) {
          Row() {
            Text('下次月经:')
              .width(100)
              .fontSize(14)
              .color('#666666')
            Text(PeriodCalculator.formatDate(prediction.nextPeriod))
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .color('#333333')
          }

          Row() {
            Text('排卵日:')
              .width(100)
              .fontSize(14)
              .color('#666666')
            Text(PeriodCalculator.formatDate(prediction.ovulationDay))
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .color('#FFD93D')
          }

          Row() {
            Text('易孕期:')
              .width(100)
              .fontSize(14)
              .color('#666666')
            Text(
              `${PeriodCalculator.formatDate(prediction.fertileWindow.start)} - ` +
              `${PeriodCalculator.formatDate(prediction.fertileWindow.end)}`
            )
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .color('#FF9F43')
          }

          Row() {
            Text('安全期:')
              .width(100)
              .fontSize(14)
              .color('#666666')
            Text(
              `${PeriodCalculator.formatDate(prediction.safePeriod.start)} - ` +
              `${PeriodCalculator.formatDate(prediction.safePeriod.end)}`
            )
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .color('#6BCB77')
          }
        }
        .margin({ top: 15 })
      }
      .width('90%')
      .padding(20)
      .margin({ top: 20 })
      .backgroundColor(Color.White)
      .borderRadius(15)
      .shadow({
        radius: 10,
        color: 'rgba(0, 0, 0, 0.1)',
        offsetX: 0,
        offsetY: 5
      })

      // 统计信息卡片
      Column() {
        Text('统计信息')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .color('#333333')
          .alignSelf(ItemAlign.Start)

        const records = this.periodData.getAllRecords();
        const settings = this.periodData.getSettings();

        Flex({ direction: FlexDirection.Column, gap: 15 }) {
          Row() {
            Text('平均周期:')
              .width(100)
              .fontSize(14)
              .color('#666666')
            Text(`${PeriodCalculator.calculateAverageCycleLength(records)} 天`)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .color('#333333')
          }

          Row() {
            Text('平均经期:')
              .width(100)
              .fontSize(14)
              .color('#666666')
            Text(`${PeriodCalculator.calculateAveragePeriodLength(records)} 天`)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .color('#333333')
          }

          Row() {
            Text('记录次数:')
              .width(100)
              .fontSize(14)
              .color('#666666')
            Text(`${records.length} 次`)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .color('#333333')
          }
        }
        .margin({ top: 15 })
      }
      .width('90%')
      .padding(20)
      .margin({ top: 20, bottom: 20 })
      .backgroundColor(Color.White)
      .borderRadius(15)
      .shadow({
        radius: 10,
        color: 'rgba(0, 0, 0, 0.1)',
        offsetX: 0,
        offsetY: 5
      })

      // 日期选择器对话框
      if (this.showDatePicker) {
        DatePickerDialog({
          start: new Date(2020, 0, 1),
          end: new Date(2030, 11, 31),
          selected: this.selectedDate
        })
          .onChange((value) => {
            this.selectedDate = new Date(value.year, value.month, value.day);
          })
          .onAccept(() => {
            this.addPeriodRecord();
            this.showDatePicker = false;
          })
          .onCancel(() => {
            this.showDatePicker = false;
          })
          .show();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}