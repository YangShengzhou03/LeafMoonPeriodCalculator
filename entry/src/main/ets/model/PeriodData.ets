// 生理期数据模型
import { StorageService } from '../services/StorageService';

export interface PeriodRecord {
  id: string;           // 记录ID
  startDate: Date;      // 开始日期
  endDate: Date;        // 结束日期
  cycleLength: number;  // 周期长度（天）
  periodLength: number; // 经期长度（天）
  notes?: string;       // 备注信息
}

export interface PredictionResult {
  nextPeriod: Date;      // 下次月经日期
  ovulationDay: Date;    // 排卵日
  fertileWindow: {
    start: Date;        // 易孕期开始
    end: Date;          // 易孕期结束
  };
  safePeriod: {
    start: Date;        // 安全期开始
    end: Date;          // 安全期结束
  };
}

export interface UserSettings {
  averageCycleLength: number;  // 平均周期长度
  averagePeriodLength: number; // 平均经期长度
  reminderEnabled: boolean;    // 是否启用提醒
  themeColor: string;          // 主题颜色
}

export class PeriodData {
  private records: PeriodRecord[] = [];
  private settings: UserSettings;
  private storageService: StorageService;

  constructor() {
    this.storageService = new StorageService();
    
    // 默认设置
    this.settings = {
      averageCycleLength: 28,
      averagePeriodLength: 5,
      reminderEnabled: false,
      themeColor: '#FF6B6B'
    };
    
    // 初始化时加载数据
    this.loadData();
  }

  // 加载数据
  private async loadData() {
    try {
      const loadedRecords = await this.storageService.loadPeriodRecords();
      if (loadedRecords.length > 0) {
        this.records = loadedRecords;
      }
      
      const loadedSettings = await this.storageService.loadSettings();
      if (loadedSettings) {
        this.settings = loadedSettings;
      }
    } catch (error) {
      console.error('加载数据失败:', error);
    }
  }

  // 添加周期记录
  async addRecord(record: Omit<PeriodRecord, 'id'>): Promise<string> {
    const newRecord: PeriodRecord = {
      ...record,
      id: Date.now().toString()
    };
    this.records.push(newRecord);
    this.records.sort((a, b) => b.startDate.getTime() - a.startDate.getTime());
    
    // 保存到存储
    await this.storageService.savePeriodRecords(this.records);
    
    return newRecord.id;
  }

  // 获取所有记录
  getAllRecords(): PeriodRecord[] {
    return [...this.records];
  }

  // 获取最近的记录
  getLatestRecord(): PeriodRecord | null {
    return this.records.length > 0 ? this.records[0] : null;
  }

  // 更新设置
  async updateSettings(newSettings: Partial<UserSettings>): Promise<void> {
    this.settings = { ...this.settings, ...newSettings };
    
    // 保存到存储
    await this.storageService.saveSettings(this.settings);
  }

  // 获取设置
  getSettings(): UserSettings {
    return { ...this.settings };
  }

  // 删除记录
  async deleteRecord(id: string): Promise<boolean> {
    const initialLength = this.records.length;
    this.records = this.records.filter(record => record.id !== id);
    
    if (this.records.length < initialLength) {
      // 保存到存储
      await this.storageService.savePeriodRecords(this.records);
      return true;
    }
    
    return false;
  }
}
