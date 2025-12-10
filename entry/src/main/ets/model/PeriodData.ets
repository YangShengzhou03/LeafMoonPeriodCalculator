// 生理期数据模型
import { StorageService } from '../services/StorageService';
import * as PeriodCalculator from '../utils/PeriodCalculator';

export interface Symptom {
  id: string;           // 症状ID
  name: string;         // 症状名称
  value: number;        // 症状程度（0-10）
  date: Date;           // 记录日期
}

export interface PeriodRecord {
  id: string;           // 记录ID
  startDate: Date;      // 开始日期
  endDate: Date;        // 结束日期
  cycleLength: number;  // 周期长度（天）
  periodLength: number; // 经期长度（天）
  notes?: string;       // 备注信息
  symptoms: Symptom[];  // 关联的症状记录
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
  darkMode: boolean;           // 是否启用深色模式
  onboardingCompleted: boolean; // 是否完成新手引导
}

// 周期统计信息接口
export interface CycleStats {
  averageCycleLength: number;
  averagePeriodLength: number;
  recordCount: number;
  cycleVariability: number;
}

// 周期趋势数据接口
export interface CycleTrendData {
  dates: string[];
  cycleLengths: number[];
  periodLengths: number[];
}

export class PeriodData {
  private records: PeriodRecord[] = [];
  private settings: UserSettings;
  private storageService: StorageService;
  private commonSymptoms: string[] = ['腹痛', '乳房胀痛', '疲劳', '情绪波动', '头痛', '恶心', '腰痛', '痤疮'];

  constructor() {
    this.storageService = new StorageService();
    
    // 默认设置
    this.settings = {
      averageCycleLength: 28,
      averagePeriodLength: 5,
      reminderEnabled: false,
      themeColor: '#FF6B6B',
      darkMode: false,
      onboardingCompleted: false
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
      id: Date.now().toString(),
      symptoms: record.symptoms || []
    };
    this.records.push(newRecord);
    this.records.sort((a, b) => b.startDate.getTime() - a.startDate.getTime());
    
    // 保存到存储
    await this.storageService.savePeriodRecords(this.records);
    
    return newRecord.id;
  }

  // 添加症状记录
  async addSymptom(periodId: string, symptom: Omit<Symptom, 'id'>): Promise<string> {
    const record = this.records.find(r => r.id === periodId);
    if (record) {
      const newSymptom: Symptom = {
        ...symptom,
        id: Date.now().toString()
      };
      record.symptoms.push(newSymptom);
      
      // 保存到存储
      await this.storageService.savePeriodRecords(this.records);
      
      return newSymptom.id;
    }
    return '';
  }

  // 删除症状记录
  async deleteSymptom(periodId: string, symptomId: string): Promise<boolean> {
    const record = this.records.find(r => r.id === periodId);
    if (record) {
      const initialLength = record.symptoms.length;
      record.symptoms = record.symptoms.filter(s => s.id !== symptomId);
      
      if (record.symptoms.length < initialLength) {
        // 保存到存储
        await this.storageService.savePeriodRecords(this.records);
        return true;
      }
    }
    return false;
  }

  // 获取常用症状列表
  getCommonSymptoms(): string[] {
    return [...this.commonSymptoms];
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

  // 获取预测结果
  getPrediction(): PredictionResult {
    return PeriodCalculator.predictNextPeriod(this.getLatestRecord(), this.settings, this.records);
  }

  // 获取当前周期阶段
  getCurrentPhase(): string {
    return PeriodCalculator.getCurrentCyclePhase(new Date(), this.getLatestRecord(), this.settings, this.records);
  }

  // 获取距离下次月经的天数
  getDaysUntilNextPeriod(): number {
    return PeriodCalculator.daysUntilNextPeriod(this.getLatestRecord(), this.settings, this.records);
  }

  // 获取周期统计信息
  getCycleStats(): CycleStats {
    return {
      averageCycleLength: PeriodCalculator.calculateAverageCycleLength(this.records),
      averagePeriodLength: PeriodCalculator.calculateAveragePeriodLength(this.records),
      recordCount: this.records.length,
      cycleVariability: PeriodCalculator.calculateCycleVariability(this.records)
    };
  }

  // 获取周期趋势数据（用于图表展示）
  getCycleTrendData(): CycleTrendData {
    return PeriodCalculator.generateCycleTrendData(this.records);
  }

  // 清除所有数据
  async clearAllData(): Promise<void> {
    // 清空本地记录
    this.records = [];
    
    // 重置设置为默认值
    this.settings = {
      averageCycleLength: 28,
      averagePeriodLength: 5,
      reminderEnabled: false,
      themeColor: '#FF6B6B',
      darkMode: false,
      onboardingCompleted: false
    };
    
    // 保存到存储
    await this.storageService.clearAllData();
  }
}
