// 设置页面
import { Column, Row, Text, Button, ScrollView, NavigationTitle, Divider, AlertDialog, Toast, Toggle } from '@kit.ArkUI';
import { useRouter } from '@kit.ArkUI';
import { PeriodData } from '../model/PeriodData';
import { StorageService } from '../services/StorageService';
import { fs } from '@kit.FileKit';
import { path } from '@kit.FileKit';

@Entry
@Component
struct SettingsPage {
  private router = useRouter();
  private periodData = PeriodData.getInstance();
  private storageService = new StorageService();
  private isExporting = false;
  private isImporting = false;
  private settings = this.periodData.getSettings();
  private darkMode = this.settings.darkMode;

  // 导出数据
  async exportData() {
    this.isExporting = true;
    const filePath = await this.storageService.exportData();
    this.isExporting = false;

    if (filePath) {
      AlertDialog.show({
        title: '导出成功',
        message: `数据已导出到: ${filePath}`,
        primaryButton: {
          value: '确定',
          action: () => {}
        }
      });
    } else {
      AlertDialog.show({
        title: '导出失败',
        message: '数据导出失败，请重试',
        primaryButton: {
          value: '确定',
          action: () => {}
        }
      });
    }
  }

  // 导入数据
  async importData() {
    try {
      this.isImporting = true;
      const files = await this.storageService.getExportFiles();
      
      if (files.length === 0) {
        AlertDialog.show({
          title: '没有找到导入文件',
          message: '没有找到可导入的备份文件',
          primaryButton: {
            value: '确定',
            action: () => {}
          }
        });
        this.isImporting = false;
        return;
      }

      // 显示文件选择对话框
      const fileOptions = files.map(file => path.basename(file));
      let selectedFile = '';

      AlertDialog.show({
        title: '选择导入文件',
        message: '',
        primaryButton: {
          value: '取消',
          action: () => {
            this.isImporting = false;
          }
        },
        secondaryButton: {
          value: '导入',
          action: async () => {
            if (selectedFile) {
              const success = await this.storageService.importData(selectedFile);
              if (success) {
                // 重新加载数据
                await this.periodData.loadData();
                AlertDialog.show({
                  title: '导入成功',
                  message: '数据导入成功',
                  primaryButton: {
                    value: '确定',
                    action: () => {
                      this.router.pushUrl({ url: 'pages/Index' });
                    }
                  }
                });
              } else {
                AlertDialog.show({
                  title: '导入失败',
                  message: '数据导入失败，请检查文件格式',
                  primaryButton: {
                    value: '确定',
                    action: () => {}
                  }
                });
              }
            }
            this.isImporting = false;
          }
        },
        builder: () => {
          Column() {
            files.forEach(file => {
              Button(path.basename(file))
                .fontSize(14)
                .fontColor(selectedFile === file ? '#FF6B6B' : '#333333')
                .backgroundColor(selectedFile === file ? '#FEECEC' : '#F5F5F5')
                .borderRadius(8)
                .width('100%')
                .margin({ bottom: 8 })
                .onClick(() => {
                  selectedFile = file;
                });
            });
          }
          .padding(10)
        }
      });
    } catch (error) {
      console.error('导入数据失败:', error);
      this.isImporting = false;
      AlertDialog.show({
        title: '导入失败',
        message: '数据导入失败，请重试',
        primaryButton: {
          value: '确定',
          action: () => {}
        }
      });
    }
  }

  // 清除所有数据
  showClearDataDialog() {
    AlertDialog.show({
      title: '警告',
      message: '确定要清除所有数据吗？此操作不可恢复。',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '确定清除',
        action: async () => {
          await this.periodData.clearAllData();
          AlertDialog.show({
            title: '清除成功',
            message: '所有数据已清除',
            primaryButton: {
              value: '确定',
              action: () => {
                this.router.pushUrl({ url: 'pages/Index' });
              }
            }
          });
        }
      }
    });
  }

  // 切换深色模式
  toggleDarkMode(isDarkMode: boolean) {
    this.darkMode = isDarkMode;
    this.settings.darkMode = isDarkMode;
    this.periodData.updateSettings(this.settings);
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
        .backgroundColor(this.darkMode ? '#333333' : '#F5F5F5')
        .onClick(() => {
          this.router.back();
        })

        NavigationTitle() {
          Text('设置')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
        }
        .margin({ left: 10 })

        Blank()
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      ScrollView() {
        Column() {
          // 外观设置
          Column() {
            Text('外观设置')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 16 })

            Row() {
              Text('深色模式')
                .fontSize(16)
                .fontWeight(FontWeight.Regular)
                .color(this.darkMode ? '#FFFFFF' : '#333333')
              Blank()
              Toggle({
                type: ToggleType.Switch,
                checked: this.darkMode
              })
              .onChange((isChecked) => {
                this.toggleDarkMode(isChecked);
              })
            }
            .width('100%')
            .height(50)
            .padding({ left: 20, right: 20 })
            .backgroundColor(this.darkMode ? '#444444' : '#F5F5F5')
            .borderRadius(10)
            .margin({ bottom: 12 })
            .alignItems(VerticalAlign.Center)
          }
          .width('90%')
          .margin({ top: 20 })

          Divider()
            .width('90%')
            .margin({ top: 20, bottom: 20 })

          // 数据管理
          Column() {
            Text('数据管理')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 16 })

            Button() {
              Row() {
                Text('导出数据')
                  .fontSize(16)
                  .fontWeight(FontWeight.Regular)
                  .color(this.darkMode ? '#FFFFFF' : '#333333')
                Blank()
                if (this.isExporting) {
                  Text('导出中...')
                    .fontSize(14)
                    .color(this.darkMode ? '#AAAAAA' : '#999999')
                } else {
                  Text('导出为JSON文件')
                    .fontSize(14)
                    .color(this.darkMode ? '#AAAAAA' : '#999999')
                }
              }
              .width('100%')
            }
            .width('100%')
            .height(50)
            .backgroundColor(this.darkMode ? '#444444' : '#F5F5F5')
            .borderRadius(10)
            .margin({ bottom: 12 })
            .onClick(() => this.exportData())

            Button() {
              Row() {
                Text('导入数据')
                  .fontSize(16)
                  .fontWeight(FontWeight.Regular)
                  .color(this.darkMode ? '#FFFFFF' : '#333333')
                Blank()
                if (this.isImporting) {
                  Text('导入中...')
                    .fontSize(14)
                    .color(this.darkMode ? '#AAAAAA' : '#999999')
                } else {
                  Text('从JSON文件导入')
                    .fontSize(14)
                    .color(this.darkMode ? '#AAAAAA' : '#999999')
                }
              }
              .width('100%')
            }
            .width('100%')
            .height(50)
            .backgroundColor(this.darkMode ? '#444444' : '#F5F5F5')
            .borderRadius(10)
            .margin({ bottom: 12 })
            .onClick(() => this.importData())

            Button() {
              Row() {
                Text('清除所有数据')
                  .fontSize(16)
                  .fontWeight(FontWeight.Regular)
                  .color('#FF6B6B')
                Blank()
                Text('谨慎操作')
                  .fontSize(14)
                  .color('#FF6B6B')
              }
              .width('100%')
            }
            .width('100%')
            .height(50)
            .backgroundColor(this.darkMode ? '#4A1F1F' : '#FEECEC')
            .borderRadius(10)
            .onClick(() => this.showClearDataDialog())
          }
          .width('90%')
          .margin({ top: 20 })

          Divider()
            .width('90%')
            .margin({ top: 20, bottom: 20 })

          // 关于
          Column() {
            Text('关于')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 16 })
              .color(this.darkMode ? '#FFFFFF' : '#333333')

            Text('LeafMoon 生理期计算器')
              .fontSize(14)
              .color(this.darkMode ? '#AAAAAA' : '#666666')
              .margin({ bottom: 8 })
            Text('版本 1.0.0')
              .fontSize(14)
              .color(this.darkMode ? '#AAAAAA' : '#666666')
            Text('提供专业的生理期跟踪与预测服务')
              .fontSize(14)
              .color(this.darkMode ? '#AAAAAA' : '#666666')
              .margin({ top: 8 })
          }
          .width('90%')
          .margin({ bottom: 40 })
        }
        .width('100%')
      }
      .flexGrow(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.darkMode ? '#222222' : '#FFFFFF')
  }
}
