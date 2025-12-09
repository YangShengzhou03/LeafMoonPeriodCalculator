import { PeriodData } from '../model/PeriodData';
import { PeriodCalculator } from '../utils/PeriodCalculator';
import { Color, FontWeight, FlexAlign, ItemAlign, FlexDirection } from '@kit.ArkUI';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct CalendarPage {
  @State periodData: PeriodData = new PeriodData();
  @State currentYear: number = new Date().getFullYear();
  @State currentMonth: number = new Date().getMonth();
  @State calendarDays: CalendarDay[] = [];

  // 日历天数据结构
  class CalendarDay {
    date: Date;
    day: number;
    isCurrentMonth: boolean;
    isToday: boolean;
    phase: string;

    constructor(date: Date, isCurrentMonth: boolean) {
      this.date = date;
      this.day = date.getDate();
      this.isCurrentMonth = isCurrentMonth;
      this.isToday = PeriodCalculator.isSameDay(date, new Date());
      this.phase = this.getPhaseForDate(date);
    }

    private getPhaseForDate(date: Date): string {
      const latestRecord = this.periodData.getLatestRecord();
      const settings = this.periodData.getSettings();
      return PeriodCalculator.getCurrentCyclePhase(date, latestRecord, settings);
    }
  }

  // 生成日历数据
  generateCalendarDays() {
    const firstDayOfMonth = new Date(this.currentYear, this.currentMonth, 1);
    const lastDayOfMonth = new Date(this.currentYear, this.currentMonth + 1, 0);
    const startDate = new Date(firstDayOfMonth);
    startDate.setDate(startDate.getDate() - firstDayOfMonth.getDay());

    const days: CalendarDay[] = [];
    for (let i = 0; i < 42; i++) {
      const date = new Date(startDate);
      date.setDate(startDate.getDate() + i);
      const isCurrentMonth = date.getMonth() === this.currentMonth;
      days.push(new CalendarDay(date, isCurrentMonth));
    }

    this.calendarDays = days;
  }

  // 获取阶段颜色
  getPhaseColor(phase: string): string {
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
        return 'transparent'; // 透明
    }
  }

  // 获取阶段文本
  getPhaseText(phase: string): string {
    switch (phase) {
      case 'period':
        return '经期';
      case 'ovulation':
        return '排卵日';
      case 'fertile':
        return '易孕期';
      case 'safe':
        return '安全期';
      case 'approaching':
        return '即将经期';
      default:
        return '';
    }
  }

  // 上一个月
  prevMonth() {
    if (this.currentMonth === 0) {
      this.currentMonth = 11;
      this.currentYear--;
    } else {
      this.currentMonth--;
    }
    this.generateCalendarDays();
  }

  // 下一个月
  nextMonth() {
    if (this.currentMonth === 11) {
      this.currentMonth = 0;
      this.currentYear++;
    } else {
      this.currentMonth++;
    }
    this.generateCalendarDays();
  }

  // 返回首页
  goBack() {
    router.back();
  }

  aboutToAppear() {
    this.generateCalendarDays();
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button('返回')
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor('#FF6B6B')
          .borderRadius(10)
          .onClick(() => this.goBack())

        Text(`${this.currentYear}年${this.currentMonth + 1}月`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .color('#333333')

        Button('切换月份')
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor('#4D96FF')
          .borderRadius(10)
          .onClick(() => {
            // 这里可以添加月份选择器
          })
      }
      .width('90%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .margin({ top: 20, bottom: 20 })

      // 星期标题
      Row() {
        const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
        weekdays.forEach(weekday => {
          Text(weekday)
            .width('14.28%')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .color('#333333')
            .textAlign(TextAlign.Center)
        });
      }
      .width('90%')
      .padding({ bottom: 10 })

      // 日历网格
      Grid() {
        ForEach(this.calendarDays, (day: CalendarDay) => {
          GridItem() {
            Column() {
              Stack() {
                // 日期数字
                Text(`${day.day}`)
                  .fontSize(16)
                  .color(day.isCurrentMonth ? '#333333' : '#CCCCCC')
                  .fontWeight(day.isToday ? FontWeight.Bold : FontWeight.Normal)
                  .textAlign(TextAlign.Center)

                // 阶段标记点
                if (day.phase !== 'normal' && day.isCurrentMonth) {
                  Stack() {
                    Circle()
                      .width(8)
                      .height(8)
                      .fill(this.getPhaseColor(day.phase))
                  }
                  .position({ x: '80%', y: '20%' })
                }
              }
              .width('100%')
              .height(40)

              // 阶段文本
              if (day.phase !== 'normal' && day.isCurrentMonth) {
                Text(this.getPhaseText(day.phase))
                  .fontSize(10)
                  .color(this.getPhaseColor(day.phase))
                  .textAlign(TextAlign.Center)
              }
            }
            .width('100%')
            .height(60)
            .justifyContent(FlexAlign.Center)
            .alignItems(ItemAlign.Center)
            .backgroundColor(day.isToday ? '#FFF0F0' : 'transparent')
            .borderRadius(8)
            .onClick(() => {
              // 点击日期可以添加记录
              console.log(`点击了日期: ${PeriodCalculator.formatDate(day.date)}`);
            })
          }
        })
      }
      .width('90%')
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
      .columnsGap(5)
      .rowsGap(5)

      // 月份导航按钮
      Row() {
        Button('上一月')
          .width('45%')
          .height(40)
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor('#FF6B6B')
          .borderRadius(10)
          .onClick(() => this.prevMonth())

        Button('下一月')
          .width('45%')
          .height(40)
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor('#4D96FF')
          .borderRadius(10)
          .onClick(() => this.nextMonth())
      }
      .width('90%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 20, bottom: 20 })

      // 图例说明
      Column() {
        Text('图例说明')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .color('#333333')
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 15 })

        Flex({ direction: FlexDirection.Column, gap: 10 }) {
          this.renderLegendItem('月经期', '#FF6B6B')
          this.renderLegendItem('排卵日', '#FFD93D')
          this.renderLegendItem('易孕期', '#FF9F43')
          this.renderLegendItem('安全期', '#6BCB77')
          this.renderLegendItem('即将经期', '#FF8787')
        }
      }
      .width('90%')
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(15)
      .shadow({
        radius: 10,
        color: 'rgba(0, 0, 0, 0.1)',
        offsetX: 0,
        offsetY: 5
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  // 渲染图例项
  renderLegendItem(text: string, color: string) {
    Row() {
      Stack() {
        Circle()
          .width(12)
          .height(12)
          .fill(color)
      }
      .margin({ right: 10 })

      Text(text)
        .fontSize(14)
        .color('#666666')
    }
    .alignItems(VerticalAlign.Center)
  }
}
