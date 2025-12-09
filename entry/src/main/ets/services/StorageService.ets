// 数据持久化服务
import { PeriodRecord, UserSettings } from '../model/PeriodData';
import { Preferences } from '@kit.StorageKit';
import { fs } from '@kit.FileKit';
import { path } from '@kit.FileKit';
import { BusinessError } from '@kit.BasicServicesKit';

const STORAGE_KEY = 'leaf_moon_period_data';
const SETTINGS_KEY = 'leaf_moon_settings';

export class StorageService {
  private preferences: Preferences | null = null;

  // 初始化存储
  async init(): Promise<void> {
    try {
      this.preferences = await Preferences.getPreferences(globalThis.applicationContext, 'period_calculator');
    } catch (error) {
      console.error('初始化存储失败:', error);
    }
  }

  // 保存周期记录
  async savePeriodRecords(records: PeriodRecord[]): Promise<void> {
    if (!this.preferences) {
      await this.init();
    }

    if (this.preferences) {
      try {
        // 将Date对象转换为ISO字符串以便存储
        const serializableRecords = records.map(record => ({
          ...record,
          startDate: record.startDate.toISOString(),
          endDate: record.endDate.toISOString(),
          symptoms: record.symptoms.map(symptom => ({
            ...symptom,
            date: symptom.date.toISOString()
          }))
        }));

        await this.preferences.put(STORAGE_KEY, JSON.stringify(serializableRecords));
        await this.preferences.flush();
      } catch (error) {
        console.error('保存周期记录失败:', error);
      }
    }
  }

  // 读取周期记录
  async loadPeriodRecords(): Promise<PeriodRecord[]> {
    if (!this.preferences) {
      await this.init();
    }

    if (this.preferences) {
      try {
        const recordsJson = await this.preferences.get(STORAGE_KEY, '[]');
        const serializableRecords = JSON.parse(recordsJson as string);

        // 将ISO字符串转换回Date对象
        return serializableRecords.map((record: any) => ({
          ...record,
          startDate: new Date(record.startDate),
          endDate: new Date(record.endDate),
          symptoms: record.symptoms ? record.symptoms.map((symptom: any) => ({
            ...symptom,
            date: new Date(symptom.date)
          })) : []
        }));
      } catch (error) {
        console.error('读取周期记录失败:', error);
      }
    }

    return [];
  }

  // 保存用户设置
  async saveSettings(settings: UserSettings): Promise<void> {
    if (!this.preferences) {
      await this.init();
    }

    if (this.preferences) {
      try {
        await this.preferences.put(SETTINGS_KEY, JSON.stringify(settings));
        await this.preferences.flush();
      } catch (error) {
        console.error('保存设置失败:', error);
      }
    }
  }

  // 读取用户设置
  async loadSettings(): Promise<UserSettings | null> {
    if (!this.preferences) {
      await this.init();
    }

    if (this.preferences) {
      try {
        const settingsJson = await this.preferences.get(SETTINGS_KEY, 'null');
        return settingsJson ? JSON.parse(settingsJson as string) : null;
      } catch (error) {
        console.error('读取设置失败:', error);
      }
    }

    return null;
  }

  // 清除所有数据
  async clearAllData(): Promise<void> {
    if (!this.preferences) {
      await this.init();
    }

    if (this.preferences) {
      try {
        await this.preferences.delete(STORAGE_KEY);
        await this.preferences.delete(SETTINGS_KEY);
        await this.preferences.flush();
      } catch (error) {
        console.error('清除数据失败:', error);
      }
    }
  }

  // 导出数据到JSON文件
  async exportData(): Promise<string | null> {
    try {
      // 获取应用文档目录
      const documentsDir = await fs.getPublicDirectory(fs.DirectoryType.DIRECTORY_DOCUMENT);
      
      // 生成唯一的文件名
      const now = new Date();
      const fileName = `period_data_${now.getFullYear()}_${now.getMonth() + 1}_${now.getDate()}_${now.getHours()}_${now.getMinutes()}.json`;
      const filePath = path.join(documentsDir, fileName);

      // 获取当前数据
      const records = await this.loadPeriodRecords();
      const settings = await this.loadSettings();

      // 准备导出数据
      const exportData = {
        version: '1.0',
        exportDate: now.toISOString(),
        records: records.map(record => ({
          ...record,
          startDate: record.startDate.toISOString(),
          endDate: record.endDate.toISOString(),
          symptoms: record.symptoms.map(symptom => ({
            ...symptom,
            date: symptom.date.toISOString()
          }))
        })),
        settings
      };

      // 写入文件
      await fs.writeTextFile(filePath, JSON.stringify(exportData, null, 2));

      return filePath;
    } catch (error) {
      console.error('导出数据失败:', error);
      return null;
    }
  }

  // 导入数据从JSON文件
  async importData(filePath: string): Promise<boolean> {
    try {
      // 读取文件内容
      const fileContent = await fs.readTextFile(filePath);
      const importData = JSON.parse(fileContent);

      // 验证数据格式
      if (!importData.version || !importData.records) {
        throw new Error('无效的数据格式');
      }

      // 转换日期格式
      const records: PeriodRecord[] = importData.records.map((record: any) => ({
        ...record,
        startDate: new Date(record.startDate),
        endDate: new Date(record.endDate),
        symptoms: record.symptoms ? record.symptoms.map((symptom: any) => ({
          ...symptom,
          date: new Date(symptom.date)
        })) : []
      }));

      // 保存数据
      await this.savePeriodRecords(records);
      if (importData.settings) {
        await this.saveSettings(importData.settings);
      }

      return true;
    } catch (error) {
      console.error('导入数据失败:', error);
      return false;
    }
  }

  // 获取导出文件列表
  async getExportFiles(): Promise<string[]> {
    try {
      const documentsDir = await fs.getPublicDirectory(fs.DirectoryType.DIRECTORY_DOCUMENT);
      const files = await fs.listFile(documentsDir);
      
      // 过滤出period_data开头的JSON文件
      return files
        .filter(file => file.name.startsWith('period_data_') && file.name.endsWith('.json'))
        .sort((a, b) => b.lastModifiedTime - a.lastModifiedTime) // 按修改时间降序排列
        .map(file => path.join(documentsDir, file.name));
    } catch (error) {
      console.error('获取导出文件列表失败:', error);
      return [];
    }
  }
}
