// 数据持久化服务
import { PeriodRecord, UserSettings } from '../model/PeriodData';
import { Preferences } from '@kit.StorageKit';

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
          endDate: record.endDate.toISOString()
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
          endDate: new Date(record.endDate)
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
}
