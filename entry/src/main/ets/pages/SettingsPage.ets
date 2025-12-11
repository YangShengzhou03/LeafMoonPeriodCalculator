// 设置页面
import { PeriodData } from '../model/PeriodData';
import { StorageService } from '../services/StorageService';
import { AlertDialog } from '@ohos.arkui.dialog';
import router from '@ohos.router';

@Entry
@Component
struct SettingsPage {
  private periodData: PeriodData = new PeriodData();
  private storageService = new StorageService();
  private isExporting = false;
  private isImporting = false;
  private settings = this.periodData.getSettings();
  private darkMode = this.settings.darkMode;

  // 导出数据
  async exportData(): Promise<void> {
    this.isExporting = true;
    const filePath = await this.storageService.exportData();
    this.isExporting = false;

    if (filePath) {
      AlertDialog.builder()
        .title('导出成功')
        .message(`数据已导出到: ${filePath}`)
        .primaryButton('确定', () => {})
        .show();
    } else {
      AlertDialog.builder()
        .title('导出失败')
        .message('数据导出失败，请重试')
        .primaryButton('确定', () => {})
        .show();
    }
  }

  // 导入数据
  async importData(): Promise<void> {
    try {
      this.isImporting = true;
      const files = await this.storageService.getExportFiles();
      
      if (files && files.length > 0) {
        // 显示文件选择对话框
        const selectedFile = await this.showFileSelectDialog(files);
        if (selectedFile) {
          const success = await this.storageService.importData(selectedFile);
          this.isImporting = false;

          if (success) {
            AlertDialog.builder()
              .title('导入成功')
              .message('数据导入成功')
              .primaryButton('确定', () => {
                router.replaceUrl({ url: 'pages/Index' });
              })
              .show();
          } else {
            AlertDialog.show({
          title: '导入失败',
          message: '数据导入失败，请重试',
          buttons: [
            {
              text: '确定',
              action: () => {}
            }
          ]
        });
          }
        } else {
          this.isImporting = false;
        }
      } else {
        this.isImporting = false;
        AlertDialog.show({
          title: '无可用文件',
          message: '没有找到可导入的数据文件',
          buttons: [
            {
              text: '确定',
              action: () => {}
            }
          ]
        });
      }
    } catch (error) {
      console.error('导入数据失败:', error);
      this.isImporting = false;
      AlertDialog.builder()
        .title('导入失败')
        .message('数据导入失败，请重试')
        .primaryButton('确定', () => {})
        .show();
    }
  }

  // 文件选择对话框
  async showFileSelectDialog(files: string[]): Promise<string | null> {
    return new Promise((resolve) => {
      let selectedFile: string | null = null;
      
      // 定义对话框按钮类型
      interface DialogButton {
        value: string;
        action: () => void;
      }
      
      // 定义对话框内容类型
      interface DialogContent {
        title: string;
        message: string;
        buttons: DialogButton[];
      }
      
      const dialogContent: DialogContent = {
        title: '选择数据文件',
        message: '请选择要导入的数据文件:',
        buttons: [
          {
            value: '取消',
            action: () => {
              resolve(null);
            }
          }
        ]
      };

      // 添加文件选择按钮
      files.forEach((file) => {
        dialogContent.buttons.push({
          value: file.substring(file.lastIndexOf('/') + 1),
          action: () => {
            selectedFile = file;
            resolve(file);
          }
        });
      });

      AlertDialog.show(dialogContent);
    });
  }

  // 清除所有数据
  showClearDataDialog() {
    AlertDialog.show({
      title: '警告',
      message: '确定要清除所有数据吗？此操作不可恢复。',
      buttons: [
        {
          text: '取消',
          action: () => {}
        },
        {
          text: '确定清除',
          action: async () => {
            await this.periodData.clearAllData();
            AlertDialog.show({
              title: '清除成功',
              message: '所有数据已清除',
              buttons: [
                {
                  text: '确定',
                    action: () => {
                    router.push({ url: 'pages/Index' });
                  }
                }
              ]
            });
          }
        }
      ]
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
      // 页面标题栏
      Row() {
        Button() {
          Text('←')
            .fontSize(20)
        }
        .backgroundColor(0)
        .width(40)
        .height(40)
        .onClick(() => {
          router.push({ url: 'pages/Index' });
        })

        Text('设置')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 10 })
      }
      .width('100%')
      .height(60)
      .padding({ left: 20, right: 20 })
      .alignItems(VerticalAlign.Center)

      // 内容区域
      Column() {
        // 外观设置
        Column() {
          Text('外观设置')
            .fontSize(16)
            .fontWeight(500)
            .margin({ bottom: 16 })

          Row() {
            Text('深色模式')
              .fontSize(16)
              .fontWeight(400)
              .margin({ right: 'auto' })
            Button() {
              Text(this.darkMode ? '开启' : '关闭')
                .fontSize(14)
                .fontColor(this.darkMode ? '#FFFFFF' : '#333333')
            }
            .width(80)
            .height(32)
            .backgroundColor(this.darkMode ? '#4D96FF' : '#F5F5F5')
            .borderRadius(16)
            .onClick(() => {
              this.toggleDarkMode(!this.darkMode);
            })
          }
          .width('100%')
          .height(50)
          .padding({ left: 20, right: 20 })
          .backgroundColor(this.darkMode ? '#444444' : '#F5F5F5')
          .borderRadius(10)
        }
        .width('90%')
        .margin({ top: 20 })

        // 数据管理
        Column() {
          Text('数据管理')
            .fontSize(16)
            .fontWeight(500)
            .margin({ bottom: 16, top: 30 })

          Button() {
            Row() {
              Text('导出数据')
                .fontSize(16)
                .fontWeight(400)
                .margin({ right: 'auto' })
              Text(this.isExporting ? '导出中...' : '导出为JSON文件')
                .fontSize(14)
                .fontColor('#999999')
            }
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
                .fontWeight(400)
                .margin({ right: 'auto' })
              Text(this.isImporting ? '导入中...' : '从JSON文件导入')
                .fontSize(14)
                .fontColor('#999999')
            }
          }
          .width('100%')
          .height(50)
          .backgroundColor(this.darkMode ? '#444444' : '#F5F5F5')
          .borderRadius(10)
          .margin({ bottom: 12 })
          .onClick(() => this.importData())

          Button() {
            Text('清除所有数据')
              .fontSize(16)
              .fontWeight(400)
              .fontColor('#FF6B6B')
          }
          .width('100%')
          .height(50)
          .backgroundColor(this.darkMode ? '#4A1F1F' : '#FEECEC')
          .borderRadius(10)
          .onClick(() => this.showClearDataDialog())
        }
        .width('90%')

        // 关于
        Column() {
          Text('关于')
            .fontSize(16)
            .fontWeight(500)
            .margin({ bottom: 16, top: 40 })

          Text('LeafMoon 生理期计算器')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ bottom: 8 })
          Text('版本 1.0.0')
            .fontSize(14)
            .fontColor('#666666')
          Text('提供专业的生理期跟踪与预测服务')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 8 })
        }
        .width('90%')
        .margin({ bottom: 40 })
      }
      .flexGrow(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.darkMode ? '#222222' : '#FFFFFF')
  }
}
