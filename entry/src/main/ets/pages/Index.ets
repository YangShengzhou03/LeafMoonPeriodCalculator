import { PeriodData, Symptom, DateRange } from '../model/PeriodData';
import { PeriodCalculator } from '../utils/PeriodCalculator';
import { Stack, Column, Row, Text, Button, TextInput, Progress, Slider, ItemAlign, FontWeight, Overflow, TextOverflow } from '@ohos/arkui';
import { AlertDialog } from '@ohos/arkui/dialog';
import router from '@ohos.router';
import { Onboarding } from '../components/Onboarding';

@Entry
@Component
struct Index {
  @State periodData: PeriodData = new PeriodData();
  @State currentDate: Date = new Date();
  @State showDatePicker: boolean = false;
  @State selectedDate: Date = new Date();
  @State showSymptomDialog: boolean = false;
  @State selectedSymptom: string = '';
  @State symptomValue: number = 5;
  @State currentPeriodId: string = '';
  @State showSymptomList: boolean = false;
  @State darkMode: boolean = false;
  @State showOnboarding: boolean = false;

  // 初始化组件
  aboutToAppear() {
    // 从存储加载数据
    this.periodData.loadData();
    // 获取当前深色模式设置
    this.darkMode = this.periodData.getSettings().darkMode;
    // 检查是否需要显示新手引导
    this.showOnboarding = !this.periodData.getSettings().onboardingCompleted;
  }

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
  openDatePicker(): void {
    this.showDatePicker = true;
  }

  // 添加周期记录
  async addPeriodRecord(): Promise<void> {
    const settings = this.periodData.getSettings();
    const periodId = await this.periodData.addRecord({
      startDate: this.selectedDate,
      endDate: PeriodCalculator.addDays(this.selectedDate, settings.averagePeriodLength - 1),
      cycleLength: settings.averageCycleLength,
      periodLength: settings.averagePeriodLength,
      symptoms: []
    });
    
    // 保存当前周期ID，用于后续添加症状
    this.currentPeriodId = periodId;
    // 自动打开症状记录对话框
    this.showSymptomDialog = true;
  }

  // 添加症状记录
  async addSymptom(): Promise<void> {
    if (this.selectedSymptom && this.currentPeriodId) {
      await this.periodData.addSymptom(this.currentPeriodId, {
        name: this.selectedSymptom,
        value: this.symptomValue,
        date: this.selectedDate
      });
      this.showSymptomDialog = false;
      // 重置表单
      this.selectedSymptom = '';
      this.symptomValue = 5;
    }
  }

  // 获取当前周期的症状记录
  getCurrentPeriodSymptoms(): Symptom[] {
    if (this.currentPeriodId) {
      const record = this.periodData.getAllRecords().find(r => r.id === this.currentPeriodId);
      return record ? record.symptoms : [];
    }
    const latestRecord = this.periodData.getLatestRecord();
    return latestRecord ? latestRecord.symptoms : [];
  }

  build() {
    Stack() {
      // 背景颜色
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.darkMode ? '#1A1A1A' : '#F5F5F5')

      // 顶部信息栏
      Stack() {
        Column() {
          Text('LeafMoon')
            .fontSize(28)
            .fontWeight(700)
            .fontColor('#FFFFFF')
            .margin({ bottom: 4 })
          
          Text('生理期计算器')
            .fontSize(16)
            .fontColor('rgba(255, 255, 255, 0.9)')
        }
        .padding(20)
        .alignItems(HorizontalAlign.Center)

        // 设置按钮
        Button() {
          Text('⚙️')
            .fontSize(22)
        }
        .type(ButtonType.Circle)
        .backgroundColor('rgba(255, 255, 255, 0.2)')
        .width(44)
        .height(44)
        .position({ x: '90%', y: 20 })
        .onClick(async () => {
              try {
                router.pushUrl({ url: 'pages/SettingsPage' });
              } catch (err) {
                console.error('跳转到设置页面失败:', err);
              }
            })
        .animation({
            duration: 200,
            curve: Curve.EaseInOut
          })
      }
      .width('100%')
      .height(140)
      .backgroundGradient({
        direction: 0, // 0表示TopToBottom方向
        colors: ['#FF6B6B', '#FF8787']
      })
      .borderRadius(0, 0, 24, 24)
      .shadow({
        radius: 10,
        color: 'rgba(255, 107, 107, 0.2)',
        offsetX: 0,
        offsetY: 5
      })

      // 主内容区域
      Column() {
        // 当前状态卡片
        Column() {
          Text(this.getCurrentPhase())
            .fontSize(24)
            .fontWeight(700)
            .color(this.getPhaseColor())
            .margin({ bottom: 10 })
          Text(`距离下次月经还有 ${this.getDaysUntilNextPeriod()} 天`)
            .fontSize(16)
            .color(this.darkMode ? '#AAAAAA' : '#666666')
        }
        .width('90%')
        .padding(28)
        .margin({ top: -40 })
        .backgroundColor(this.darkMode ? '#333333' : '#FFFFFF')
        .borderRadius(20)
        .shadow({
          radius: 16,
          color: 'rgba(0, 0, 0, 0.12)',
          offsetX: 0,
          offsetY: 8
        })
        .animation({
          duration: 300,
          curve: Curve.EaseOut
        })

        // 快捷操作按钮
        Row() {
          Button('记录月经')
            .width('22%')
            .height(56)
            .backgroundColor('#FF6B6B')
            .fontColor('#FFFFFF')
            .fontSize(16)
            .borderRadius(16)
            .shadow({
              radius: 8,
              color: 'rgba(255, 107, 107, 0.2)',
              offsetX: 0,
              offsetY: 4
            })
            .onClick(() => this.openDatePicker())
            .animation({
              duration: 200,
              curve: Curve.EaseInOut
            })

          Button('记录症状')
            .width('22%')
            .height(56)
            .backgroundColor('#FF9F43')
            .fontColor('#FFFFFF')
            .fontSize(16)
            .borderRadius(16)
            .shadow({
              radius: 8,
              color: 'rgba(255, 159, 67, 0.2)',
              offsetX: 0,
              offsetY: 4
            })
            .onClick(() => {
              const latestRecord = this.periodData.getLatestRecord();
              if (latestRecord) {
                this.currentPeriodId = latestRecord.id;
                this.selectedDate = new Date();
                this.showSymptomDialog = true;
              } else {
                // 如果没有周期记录，先引导用户记录月经
                this.openDatePicker();
              }
            })
            .animation({
              duration: 200,
              curve: Curve.EaseInOut
            })

          Button('查看日历')
            .width('22%')
            .height(56)
            .backgroundColor('#4D96FF')
            .fontColor('#FFFFFF')
            .fontSize(16)
            .borderRadius(16)
            .shadow({
              radius: 8,
              color: 'rgba(77, 150, 255, 0.2)',
              offsetX: 0,
              offsetY: 4
            })
            .onClick(() => {
              router.pushUrl({ url: 'pages/CalendarPage' });
            })
            .animation({
              duration: 200,
              curve: Curve.EaseInOut
            })

          Button('查看分析')
            .width('22%')
            .height(56)
            .backgroundColor('#9C27B0')
            .fontColor('#FFFFFF')
            .fontSize(16)
            .borderRadius(16)
            .shadow({
              radius: 8,
              color: 'rgba(156, 39, 176, 0.2)',
              offsetX: 0,
              offsetY: 4
            })
            .onClick(() => {
              router.pushUrl({ url: 'pages/AnalysisPage' });
            })
            .animation({
              duration: 200,
              curve: Curve.EaseInOut
            })
        }
        .width('90%')
        .justifyContent('SpaceBetween')
        .margin({ top: 24 })

        // 预测信息卡片
        Column() {
          Text('周期预测')
            .fontSize(20)
            .fontWeight(700)
            .fontColor(this.darkMode ? '#FFFFFF' : '#333333')
            .alignSelf('Start')
            .margin({ bottom: 16 })

          Column() {
            // 预测信息已在组件内计算
            Row() {
              Text('下次月经:')
                .width(100)
                .fontSize(16)
                .fontColor(this.darkMode ? '#AAAAAA' : '#666666')
              Text(PeriodCalculator.formatDate(PeriodCalculator.predictNextPeriod(this.periodData.getLatestRecord(), this.periodData.getSettings()).nextPeriod))
                .fontSize(16)
                .fontWeight(700)
                .fontColor('#FF6B6B')
            }
            .margin({ bottom: 18 })

            Row() {
              Text('排卵日:')
                .width(100)
                .fontSize(16)
                .fontColor(this.darkMode ? '#AAAAAA' : '#666666')
              Text(PeriodCalculator.formatDate(PeriodCalculator.predictNextPeriod(this.periodData.getLatestRecord(), this.periodData.getSettings()).ovulationDay))
                .fontSize(16)
                .fontWeight(700)
                .fontColor('#FFD93D')
            }
            .margin({ bottom: 18 })

            Row() {
              Text('易孕期:')
                .width(100)
                .fontSize(16)
                .fontColor(this.darkMode ? '#AAAAAA' : '#666666')
              Text(
                `${PeriodCalculator.formatDate(PeriodCalculator.predictNextPeriod(this.periodData.getLatestRecord(), this.periodData.getSettings()).fertileWindow.start)} - ${PeriodCalculator.formatDate(PeriodCalculator.predictNextPeriod(this.periodData.getLatestRecord(), this.periodData.getSettings()).fertileWindow.end)}`
              )
                .fontSize(16)
                .fontWeight(700)
                .fontColor('#FF9F43')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .margin({ bottom: 18 })

            Row() {
              Text('安全期:')
                .width(100)
                .fontSize(16)
                .fontColor(this.darkMode ? '#AAAAAA' : '#666666')
              Text(
                `${PeriodCalculator.formatDate(PeriodCalculator.predictNextPeriod(this.periodData.getLatestRecord(), this.periodData.getSettings()).safePeriod.start)} - ${PeriodCalculator.formatDate(PeriodCalculator.predictNextPeriod(this.periodData.getLatestRecord(), this.periodData.getSettings()).safePeriod.end)}`
              )
                .fontSize(16)
                .fontWeight(700)
                .fontColor('#6BCB77')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
          }
          .margin({ top: 5 })
        }
        .width('90%')
        .padding(24)
        .margin({ top: 24 })
        .backgroundColor(this.darkMode ? '#333333' : '#FFFFFF')
        .borderRadius(20)
        .shadow({
          radius: 16,
          color: 'rgba(0, 0, 0, 0.12)',
          offsetX: 0,
          offsetY: 8
        })

        // 症状记录卡片
        Column() {
          Row() {
            Text('症状记录')
              .fontSize(20)
              .fontWeight(700)
              .color(this.darkMode ? '#FFFFFF' : '#333333')
              .alignSelf('Start')

            Button(this.showSymptomList ? '收起' : '展开')
              .fontSize(14)
              .fontColor('#4D96FF')
              .backgroundColor(this.darkMode ? 'rgba(77, 150, 255, 0.2)' : 'rgba(77, 150, 255, 0.1)')
              .borderRadius(20)
              .padding({ horizontal: 16, vertical: 6 })
              .onClick(() => this.showSymptomList = !this.showSymptomList)
              .animation({
                duration: 200,
                curve: Curve.EaseInOut
              })
          }
          .justifyContent('SpaceBetween')
          .width('100%')
          .alignItems('Center')
          .margin({ bottom: 16 })

          if (this.showSymptomList || this.getCurrentPeriodSymptoms().length > 0) {
            if (this.getCurrentPeriodSymptoms().length > 0) {
              Column() {
                ForEach(this.getCurrentPeriodSymptoms(), (symptom: Symptom) => {
                  Row() {
                    Text(symptom.name)
                      .width(100)
                      .fontSize(16)
                      .fontWeight(500)
                      .color(this.darkMode ? '#DDDDDD' : '#555555')
                    
                    // 症状程度进度条
                    Progress({
                      value: symptom.value,
                      total: 10,
                      type: 'Linear'
                    })
                    .width('55%')
                    .height(10)
                    .color('#FF9F43')
                    .backgroundColor(this.darkMode ? '#4A3A2A' : '#FFF0E0')
                    .borderRadius(5)
                    
                    Text(`${symptom.value}`)
                      .width(30)
                      .fontSize(16)
                      .fontWeight(500)
                      .color('#FF9F43')
                      .textAlign(TextAlign.End)
                  }
                  .alignItems('Center')
                  .padding({ vertical: 12, horizontal: 8 })
                  .backgroundColor(this.darkMode ? '#444444' : '#FFFFFF')
                  .borderRadius(12)
                  .margin({ bottom: 8 })
                }, (item: Symptom) => item.id.toString())
              }
            } else {
              Text('暂无症状记录，点击"记录症状"添加')
                .fontSize(16)
                .color(this.darkMode ? '#AAAAAA' : '#999999')
                .margin({ top: 8 })
                .padding(12)
                .backgroundColor(this.darkMode ? '#444444' : '#F8F9FA')
                .borderRadius(12)
            }
          }
        }
        .width('90%')
        .padding(24)
        .margin({ top: 24 })
        .backgroundColor(this.darkMode ? '#333333' : '#FFFFFF')
        .borderRadius(20)
        .shadow({
          radius: 16,
          color: 'rgba(0, 0, 0, 0.12)',
          offsetX: 0,
          offsetY: 8
        })

        // 统计信息卡片
        Column() {
          Text('统计信息')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .color(this.darkMode ? '#FFFFFF' : '#333333')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 20 })

          Grid() {
            GridItem() {
              Column() {
                Text('平均周期')
                  .fontSize(14)
                  .color('#888888')
                  .margin({ bottom: 8 })
                Text(`${PeriodCalculator.calculateAverageCycleLength(this.periodData.getAllRecords())} 天`)
                  .fontSize(22)
                  .fontWeight(700)
                  .color('#FF6B6B')
              }
              .padding(20)
              .backgroundColor('#FFF5F5')
              .borderRadius(16)
              .width('100%')
              .height('100%')
              .shadow({
                radius: 8,
                color: 'rgba(255, 107, 107, 0.1)',
                offsetX: 0,
                offsetY: 4
              });
            }
            
            GridItem() {
              Column() {
                Text('平均经期')
                  .fontSize(14)
                  .color('#888888')
                  .margin({ bottom: 8 })
                Text(`${PeriodCalculator.calculateAveragePeriodLength(this.periodData.getAllRecords())} 天`)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .color('#FF9F43')
              }
              .padding(20)
              .backgroundColor('#FFF8F0')
              .borderRadius(16)
              .width('100%')
              .height('100%')
              .shadow({
                radius: 8,
                color: 'rgba(255, 159, 67, 0.1)',
                offsetX: 0,
                offsetY: 4
              });
            }
            
            GridItem() {
              Column() {
                Text('记录次数')
                  .fontSize(14)
                  .color('#888888')
                  .margin({ bottom: 8 })
                Text(`${this.periodData.getAllRecords().length} 次`)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .color('#4D96FF')
              }
              .padding(20)
              .backgroundColor('#F0F7FF')
              .borderRadius(16)
              .width('100%')
              .height('100%')
              .shadow({
                radius: 8,
                color: 'rgba(77, 150, 255, 0.1)',
                offsetX: 0,
                offsetY: 4
              });
            }
            
            GridItem() {
              Column() {
                Text('周期波动')
                  .fontSize(14)
                  .color('#888888')
                  .margin({ bottom: 8 })
                Text(`${PeriodCalculator.calculateCycleVariability(this.periodData.getAllRecords())} 天`)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .color('#9C27B0')
              }
              .padding(20)
              .backgroundColor('#F5F0FF')
              .borderRadius(16)
              .width('100%')
              .height('100%')
              .shadow({
                radius: 8,
                color: 'rgba(156, 39, 176, 0.1)',
                offsetX: 0,
                offsetY: 4
              });
            }
          }
          .columnsTemplate('1fr 1fr')
          .rowsTemplate('1fr 1fr')
          .columnsGap(16)
          .rowsGap(16)
          .width('100%')
          .height(300)
        }
        .width('90%')
        .padding(24)
        .margin({ top: 24, bottom: 32 })
        .backgroundColor(this.darkMode ? '#333333' : '#FFFFFF')
        .borderRadius(20)
        .shadow({
          radius: 16,
          color: 'rgba(0, 0, 0, 0.12)',
          offsetX: 0,
          offsetY: 8
        })
      }

      // 日期选择器对话框
      if (this.showDatePicker) {
        Stack() {
          // 半透明背景遮罩
          Row()
            .width('100%')
            .height('100%')
            .backgroundColor('rgba(0, 0, 0, 0.5)')
            .onClick(() => {
              this.showDatePicker = false;
            })
          
          // 对话框内容
          Column({ space: 20 })
            .width(300)
            .backgroundColor(this.darkMode ? '#333333' : '#FFFFFF')
            .borderRadius(12)
            .padding(24)
            .shadow({ radius: 16, color: 'rgba(0, 0, 0, 0.3)', offsetX: 0, offsetY: 8 }) {
            // 标题
            Text('选择日期')
              .fontSize(20)
              .fontWeight(700)
              .color(this.darkMode ? '#FFFFFF' : '#000000')
              .margin({ bottom: 12 })
            
            // 使用文本输入框让用户输入日期
            TextInput({
              placeholder: 'YYYY-MM-DD',
              text: `${this.selectedDate.getFullYear()}-${String(this.selectedDate.getMonth() + 1).padStart(2, '0')}-${String(this.selectedDate.getDate()).padStart(2, '0')}`
            })
            .width('100%')
            .height(44)
            .backgroundColor(this.darkMode ? '#444444' : '#F0F0F0')
            .borderRadius(8)
            .padding(12)
            .onChange((value: string): void => {
              // 简单的日期格式验证
              const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
              if (dateRegex.test(value)) {
                const parts: string[] = value.split('-');
                const year: number = parseInt(parts[0]);
                const month: number = parseInt(parts[1]) - 1;
                const day: number = parseInt(parts[2]);
                this.selectedDate = new Date(year, month, day);
              }
            });
            
            // 按钮行
            Row({ space: 12 }) {
              // 取消按钮
              Button('取消')
                .width(80)
                .height(36)
                .backgroundColor(this.darkMode ? '#555555' : '#F0F0F0')
                .fontColor(this.darkMode ? '#FFFFFF' : '#000000')
                .borderRadius(8)
                .onClick(() => {
                  this.showDatePicker = false;
                })
              
              // 确定按钮
              Button('确定')
                .width(80)
                .height(36)
                .backgroundColor('#67C23A')
                .fontColor('#FFFFFF')
                .borderRadius(8)
                .onClick(() => {
                  this.addPeriodRecord();
                  this.showDatePicker = false;
                })
            }
            .width('100%')
            .justifyContent('FlexEnd')
          }
        }
        .width('100%')
        .height('100%')
        .position({ x: 0, y: 0 })
      }

      // 症状记录界面
      if (this.showSymptomDialog) {
        // 使用半透明遮罩层
        Stack() {
          // 背景遮罩
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('rgba(0, 0, 0, 0.5)')
            .onClick(() => {
              this.showSymptomDialog = false;
              this.selectedSymptom = '';
              this.symptomValue = 5;
            })

          // 对话框内容
          Column() {
            Text('记录症状')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 20 })

            // 症状选择
            Text('选择症状:')
              .fontSize(14)
              .color('#666666')
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 10 })

            // 使用Column和Button实现自定义选择列表
            Column() {
              Button(this.selectedSymptom || '请选择症状')
                .width('100%')
                .height(44)
                .backgroundColor('#FFFFFF')
                .borderRadius(8)
                .borderWidth(1)
                .borderColor('#E0E0E0')
                .margin({ bottom: 10 })
                .onClick(() => {
                  this.showSymptomList = !this.showSymptomList;
                })

              if (this.showSymptomList) {
                Column() {
                  ForEach(this.periodData.getCommonSymptoms(), (symptom: string): void => {
                    Button(symptom)
                      .width('100%')
                      .height(40)
                      .backgroundColor(symptom === this.selectedSymptom ? '#F5F5F5' : '#FFFFFF')
                      .borderRadius(4)
                      .margin({ bottom: 4 })
                      .onClick((): void => {
                        this.selectedSymptom = symptom;
                        this.showSymptomList = false;
                      })
                  }, (symptom: string): string => symptom)
                }
                .width('100%')
                .backgroundColor('#FFFFFF')
                .borderRadius(8)
                .borderWidth(1)
                .borderColor('#E0E0E0')
                .padding(8)
                .maxHeight(200)
                .overflow(Overflow.Scroll)
              }
            }
            .width('100%')
            .margin({ bottom: 20 })

            // 症状程度
            Text('症状程度 (0-10):')
              .fontSize(14)
              .color('#666666')
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 10 })

            Slider({
              value: this.symptomValue,
              min: 0,
              max: 10,
              step: 1
            })
            .width('100%')
            .onChange((value: number): void => {
              this.symptomValue = value;
            });

            Text(`${this.symptomValue}`)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .color('#333333')
              .margin({ top: 10, bottom: 20 })

            // 按钮栏
            Row() {
              Button('取消')
                .width('45%')
                .height(44)
                .backgroundColor('#E0E0E0')
                .borderRadius(8)
                .margin({ right: 10 })
                .onClick(() => {
                  this.showSymptomDialog = false;
                  this.selectedSymptom = '';
                  this.symptomValue = 5;
                })

              Button('确定')
                .width('45%')
                .height(44)
                .backgroundColor('#FF69B4')
                .borderRadius(8)
                .onClick(() => this.addSymptom())
            }
          }
          .width('80%')
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .padding(20)
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
        }
        .position({ x: 0, y: 0 })
        .zIndex(100)
      }
      
      // 新手引导
      if (this.showOnboarding) {
        Onboarding({ periodData: this.periodData });
      }
    }
  }
}