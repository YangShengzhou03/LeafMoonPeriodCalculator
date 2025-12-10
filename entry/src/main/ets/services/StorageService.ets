// 数据持久化服务
import { PeriodRecord, UserSettings } from '../model/PeriodData';
import Preferences from '@ohos.data.preferences';
import fs from '@ohos.file.fs';
import path from '@ohos.file.path';
import { fileIo } from '@kit.CoreFileKit';
import { BusinessError } from '@ohos.base';
import common from '@ohos.app.ability.common';

// 定义Symptom类型
interface Symptom {
  id: string;
  name: string;
  value: number;
  date: Date;
}

// 定义可序列化的Symptom类型
interface SerializableSymptom {
  id: string;
  name: string;
  value: number;
  date: string;
}

// 定义可序列化的PeriodRecord类型
interface SerializablePeriodRecord {
  id: string;
  startDate: string;
  endDate: string;
  cycleLength: number;
  periodLength: number;
  notes?: string;
  symptoms: SerializableSymptom[];
}

// 定义导出数据类型
interface ExportData {
  version: string;
  exportDate: string;
  records: SerializablePeriodRecord[];
  settings?: UserSettings;
}

// 定义导入数据类型
interface ImportData {
  version: string;
  records: SerializablePeriodRecord[];
  settings?: UserSettings;
}

// 定义文件信息接口
interface FileInfo {
  name: string;
  lastModifiedTime: number;
}

const STORAGE_KEY = 'leaf_moon_period_data';
const SETTINGS_KEY = 'leaf_moon_settings';

export class StorageService {
  private preferences: Preferences | null = null;

  // 初始化存储
  async init(): Promise<void> {
    try {
      // 使用 getApplicationContext() 获取应用上下文
      this.preferences = await Preferences.getPreferences(common.getApplicationContext(), 'period_calculator');
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
        const serializableRecords: SerializablePeriodRecord[] = records.map(record => {
          const serializableSymptoms: SerializableSymptom[] = record.symptoms.map(symptom => {
            const serializableSymptom: SerializableSymptom = {
              id: symptom.id,
              name: symptom.name,
              value: symptom.value,
              date: symptom.date.toISOString()
            };
            return serializableSymptom;
          });

          const serializableRecord: SerializablePeriodRecord = {
            id: record.id,
            startDate: record.startDate.toISOString(),
            endDate: record.endDate.toISOString(),
            cycleLength: record.cycleLength,
            periodLength: record.periodLength,
            notes: record.notes,
            symptoms: serializableSymptoms
          };
          return serializableRecord;
        });

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
        const recordsJson: string = await this.preferences.get(STORAGE_KEY, '[]');
        const serializableRecords: SerializablePeriodRecord[] = JSON.parse(recordsJson) as SerializablePeriodRecord[];

        // 将ISO字符串转换回Date对象
        return serializableRecords.map(record => {
          const symptoms: Symptom[] = record.symptoms.map(symptom => {
            const symptomObj: Symptom = {
              id: symptom.id,
              name: symptom.name,
              value: symptom.value,
              date: new Date(symptom.date)
            };
            return symptomObj;
          });

          const periodRecord: PeriodRecord = {
            id: record.id,
            startDate: new Date(record.startDate),
            endDate: new Date(record.endDate),
            cycleLength: record.cycleLength,
            periodLength: record.periodLength,
            notes: record.notes,
            symptoms: symptoms
          };
          return periodRecord;
        });
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
        const settingsJson: string = await this.preferences.get(SETTINGS_KEY, 'null');
        return settingsJson ? JSON.parse(settingsJson) as UserSettings : null;
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
      const context: common.Context = common.getApplicationContext();
      const documentsDir: string = context.filesDir;
      
      // 生成唯一的文件名
      const now = new Date();
      const fileName: string = `period_data_${now.getFullYear()}_${now.getMonth() + 1}_${now.getDate()}_${now.getHours()}_${now.getMinutes()}.json`;
      const filePath: string = path.join(documentsDir, fileName);

      // 获取当前数据
      const records: PeriodRecord[] = await this.loadPeriodRecords();
      const settings: UserSettings | null = await this.loadSettings();

      // 准备导出数据
      const serializableRecords: SerializablePeriodRecord[] = records.map(record => {
        const serializableSymptoms: SerializableSymptom[] = record.symptoms.map(symptom => {
          const serializableSymptom: SerializableSymptom = {
            id: symptom.id,
            name: symptom.name,
            value: symptom.value,
            date: symptom.date.toISOString()
          };
          return serializableSymptom;
        });

        const serializableRecord: SerializablePeriodRecord = {
          id: record.id,
          startDate: record.startDate.toISOString(),
          endDate: record.endDate.toISOString(),
          cycleLength: record.cycleLength,
          periodLength: record.periodLength,
          notes: record.notes,
          symptoms: serializableSymptoms
        };
        return serializableRecord;
      });

      const exportData: ExportData = {
        version: '1.0',
        exportDate: now.toISOString(),
        records: serializableRecords,
        settings: settings ?? undefined
      };

      // 写入文件
      const file: fileIo.File = await fileIo.open(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE);
      await fileIo.write(file.fd, JSON.stringify(exportData, null, 2));
      await fileIo.close(file.fd);

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
      const file: fileIo.File = await fileIo.open(filePath, fileIo.OpenMode.READ_ONLY);
      const fileContent: string = await fileIo.readText(file.fd);
      await fileIo.close(file.fd);
      
      const importData: ImportData = JSON.parse(fileContent);

      // 验证数据格式
      if (!importData.version || !importData.records) {
        throw new Error('无效的数据格式');
      }

      // 转换日期格式
      const records: PeriodRecord[] = importData.records.map(record => {
        const symptoms: Symptom[] = record.symptoms.map(symptom => {
          const symptomObj: Symptom = {
            id: symptom.id,
            name: symptom.name,
            value: symptom.value,
            date: new Date(symptom.date)
          };
          return symptomObj;
        });

        const periodRecord: PeriodRecord = {
          id: record.id,
          startDate: new Date(record.startDate),
          endDate: new Date(record.endDate),
          cycleLength: record.cycleLength,
          periodLength: record.periodLength,
          notes: record.notes,
          symptoms: symptoms
        };
        return periodRecord;
      });

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
      const context: common.Context = common.getApplicationContext();
      const documentsDir: string = context.filesDir;
      
      // 使用fileIo.listFile获取文件列表
      const files: string[] = await fileIo.listFile(documentsDir);
      
      // 过滤出period_data开头的JSON文件
      const result: string[] = files
        .filter(file => file.startsWith('period_data_') && file.endsWith('.json'))
        .map(file => path.join(documentsDir, file));
      return result;
    } catch (error) {
      console.error('获取导出文件列表失败:', error);
      return [];
    }
  }
}
