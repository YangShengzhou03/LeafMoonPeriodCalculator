import { PeriodData } from '../model/PeriodData';
import { PeriodCalculator } from '../utils/PeriodCalculator';
import router from '@ohos.router';
import { Text, Row, Stack, Circle, Column, Button } from '@ohos.arkui';
import { TextAlign, FlexAlign, VerticalAlign } from '@ohos.arkui';

// 日历天类型定义
interface CalendarDay {
  date: Date;
  day: number;
  phase: string;
  isCurrentMonth: boolean;
  isToday: boolean;
}

@Entry
@Component
struct CalendarPage {
  @State periodData: PeriodData = new PeriodData();
  @State currentYear: number = new Date().getFullYear();
  @State currentMonth: number = new Date().getMonth();
  @State calendarDays: CalendarDay[] = [];

  // 初始化组件
  aboutToAppear() {
    this.generateCalendarDays();
  }

  // 生成日历天数
  generateCalendarDays(): void {
    this.calendarDays = [];
    const firstDay = new Date(this.currentYear, this.currentMonth, 1);
    const lastDay = new Date(this.currentYear, this.currentMonth + 1, 0);
    const startDate = new Date(firstDay);
    startDate.setDate(startDate.getDate() - firstDay.getDay());

    // 生成42天的日历（6周）
    for (let i = 0; i < 42; i++) {
      const currentDate = new Date(startDate);
      currentDate.setDate(startDate.getDate() + i);
      const phase = this.periodData.getCyclePhase(currentDate);
      const isToday = this.isToday(currentDate);
      
      this.calendarDays.push({
        date: currentDate,
        day: currentDate.getDate(),
        phase: phase,
        isCurrentMonth: currentDate.getMonth() === this.currentMonth,
        isToday: isToday
      });
    }
  }

  // 判断是否为今天
  isToday(date: Date): boolean {
    const today = new Date();
    return date.getFullYear() === today.getFullYear() &&
           date.getMonth() === today.getMonth() &&
           date.getDate() === today.getDate();
  }

  // 上一个月
  prevMonth() {
    this.currentMonth--;
    if (this.currentMonth < 0) {
      this.currentMonth = 11;
      this.currentYear--;
    }
    this.generateCalendarDays();
  }

  // 下一个月
  nextMonth() {
    this.currentMonth++;
    if (this.currentMonth > 11) {
      this.currentMonth = 0;
      this.currentYear++;
    }
    this.generateCalendarDays();
  }

  // 返回首页
  goBack() {
    // 使用 router.pushUrl 跳转到首页
    router.pushUrl({
      url: 'pages/Index'
    }).catch((err: Error) => {
      console.error('导航失败:', err);
    });
  }

  // 获取阶段颜色
  getPhaseColor(phase: string): string {
    switch (phase) {
      case 'period':
        return '#FF6B6B';
      case 'ovulation':
        return '#FFD93D';
      case 'fertile':
        return '#FF9F43';
      case 'safe':
        return '#6BCB77';
      case 'upcoming':
        return '#FF8787';
      default:
        return '#CCCCCC';
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
      case 'upcoming':
        return '即将经期';
      default:
        return '';
    }
  }

  // 组件构建
  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Button('返回')
          .width(60)
          .height(36)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#FF6B6B')
          .borderRadius(18)
          .onClick(() => this.goBack())

        Text(`${this.currentYear}年${this.currentMonth + 1}月`)
          .fontSize(18)
          .fontWeight(500)
          .color('#333333')

        Button('切换月份')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#4D96FF')
          .borderRadius(10)
          .onClick(() => {
            // 这里可以添加月份选择器
          })
      }
      .width('90%')
      .justifyContent('space-between')
      .alignItems('center')
      .margin({ top: 20, bottom: 20 })

      // 星期标题
      Row() {
        const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
        ForEach(weekdays, (weekday: string) => {
          Text(weekday)
            .width('14.28%')
            .fontSize(14)
            .fontWeight(500)
            .fontColor('#333333')
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
                  .fontColor(day.isCurrentMonth ? '#333333' : '#CCCCCC')
                  .fontWeight(day.isToday ? 500 : 400)
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
                  .fontColor(this.getPhaseColor(day.phase))
                  .textAlign(TextAlign.Center)
              }
            }
            .width('100%')
            .height(60)
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
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
          .fontColor('#FFFFFF')
          .backgroundColor('#FF6B6B')
          .borderRadius(10)
          .onClick(() => this.prevMonth())

        Button('下一月')
          .width('45%')
          .height(40)
          .fontSize(14)
          .fontColor('#FFFFFF')
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
          .fontWeight(500)
          .fontColor('#333333')
          .margin({ bottom: 15 })

        Column({
          space: 10
        }) {
          // 直接在UI中渲染图例项，而不是调用方法
          Row() {
            Stack() {
              Circle()
                .width(12)
                .height(12)
                .fill('#FF6B6B')
            }
            .margin({ right: 10 })

            Text('月经期')
              .fontSize(14)
              .fontColor('#666666')
          }
          .alignItems(VerticalAlign.Center)

          Row() {
            Stack() {
              Circle()
                .width(12)
                .height(12)
                .fill('#FFD93D')
            }
            .margin({ right: 10 })

            Text('排卵日')
              .fontSize(14)
              .fontColor('#666666')
          }
          .alignItems(VerticalAlign.Center)

          Row() {
            Stack() {
              Circle()
                .width(12)
                .height(12)
                .fill('#FF9F43')
            }
            .margin({ right: 10 })

            Text('易孕期')
              .fontSize(14)
              .fontColor('#666666')
          }
          .alignItems(VerticalAlign.Center)

          Row() {
            Stack() {
              Circle()
                .width(12)
                .height(12)
                .fill('#6BCB77')
            }
            .margin({ right: 10 })

            Text('安全期')
              .fontSize(14)
              .fontColor('#666666')
          }
          .alignItems(VerticalAlign.Center)

          Row() {
            Stack() {
              Circle()
                .width(12)
                .height(12)
                .fill('#FF8787')
            }
            .margin({ right: 10 })

            Text('即将经期')
              .fontSize(14)
              .fontColor('#666666')
          }
          .alignItems(VerticalAlign.Center)
        }
      }
      .width('90%')
      .padding(20)
      .backgroundColor('#FFFFFF')
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

  // 渲染图例项方法已移除，改为直接在UI中渲染
}
