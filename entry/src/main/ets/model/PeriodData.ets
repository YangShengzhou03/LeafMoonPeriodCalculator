// entry/src/main/ets/model/PeriodData.ets 
/** 
 * 经期数据模型 
 * 修复：移除工具类型、替换对象展开、声明显式接口、修复方法调用 
 */ 
import { PeriodCalculator, CycleData, CalculationResult, TrendData, AverageResult } from '../utils/PeriodCalculator'; 
import { StorageService } from '../services/StorageService'; 

// 1. 声明接口替代工具类型 
export interface Symptom {
  id: string;           // 症状ID
  name: string;         // 症状名称
  value: number;        // 症状程度（0-10）
  date: Date;           // 记录日期
}

// 定义不包含id的症状类型，替代Omit工具类型
export interface SymptomWithoutId {
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

// 定义不包含id的周期记录类型，替代Omit工具类型
export interface PeriodRecordWithoutId {
  startDate: Date;      // 开始日期
  endDate: Date;        // 结束日期
  cycleLength: number;  // 周期长度（天）
  periodLength: number; // 经期长度（天）
  notes?: string;       // 备注信息
  symptoms: Symptom[];  // 关联的症状记录
} 

// 定义时间范围类型
export interface DateRange {
  start: Date;        // 开始日期
  end: Date;          // 结束日期
}

export interface PredictionResult { 
  nextPeriod: Date;      // 下次月经日期 
  ovulationDay: Date;    // 排卵日 
  fertileWindow: DateRange;  // 易孕期 
  safePeriod: DateRange;    // 安全期 
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
  private calculator: PeriodCalculator; 
  
  constructor() { 
    this.storageService = new StorageService(); 
    this.calculator = new PeriodCalculator(); 
    
    // 默认设置 
    this.settings = { 
      averageCycleLength: 28, 
      averagePeriodLength: 5, 
      reminderEnabled: false, 
      themeColor: '#FF6B6B', 
      darkMode: false, 
      onboardingCompleted: false 
    }; 
    
    // 初始化数据（修复未初始化问题） 
    this.records = []; 
    
    // 初始化时加载数据 
    this.loadData(); 
  } 

  // 改为公共方法，修复private访问错误 
  public async loadData(): Promise<void> { 
    try { 
      const loadedRecords = await this.storageService.loadPeriodRecords(); 
      if (loadedRecords.length > 0) { 
        this.records = loadedRecords; 
        
        // 转换为计算器需要的格式 
        const cycleData: CycleData[] = loadedRecords.map(record => {
          const data: CycleData = {
            startDate: record.startDate, 
            cycleDays: record.cycleLength, 
            periodDays: record.periodLength 
          };
          return data;
        }); 
        
        // 更新计算器数据 
        cycleData.forEach(data => this.calculator.addCycleData(data)); 
      } 
      
      const loadedSettings = await this.storageService.loadSettings(); 
      if (loadedSettings) { 
        // 使用对象属性赋值替代展开运算符 
        this.settings.averageCycleLength = loadedSettings.averageCycleLength; 
        this.settings.averagePeriodLength = loadedSettings.averagePeriodLength; 
        this.settings.reminderEnabled = loadedSettings.reminderEnabled; 
        this.settings.themeColor = loadedSettings.themeColor; 
        this.settings.darkMode = loadedSettings.darkMode; 
        this.settings.onboardingCompleted = loadedSettings.onboardingCompleted; 
      } 
    } catch (error) { 
      console.error('加载数据失败:', error); 
    } 
  } 

  // 添加周期记录
  async addRecord(record: PeriodRecordWithoutId): Promise<string> { 
    // 替换对象展开语法 
    const newRecord: PeriodRecord = { 
      id: Date.now().toString(), 
      startDate: record.startDate, 
      endDate: record.endDate, 
      cycleLength: record.cycleLength, 
      periodLength: record.periodLength, 
      notes: record.notes, 
      symptoms: record.symptoms || [] 
    }; 
    this.records.push(newRecord); 
    this.records.sort((a, b) => b.startDate.getTime() - a.startDate.getTime()); 
    
    // 更新计算器数据 
    this.calculator.addCycleData({
      startDate: record.startDate, 
      cycleDays: record.cycleLength, 
      periodDays: record.periodLength 
    }); 
    
    // 保存到存储 
    await this.storageService.savePeriodRecords(this.records); 
    
    return newRecord.id; 
  } 

  // 添加症状记录 
  async addSymptom(periodId: string, symptom: SymptomWithoutId): Promise<string> { 
    const record = this.records.find(r => r.id === periodId); 
    if (record) { 
      // 替换对象展开语法 
      const newSymptom: Symptom = { 
        id: Date.now().toString(), 
        name: symptom.name, 
        value: symptom.value, 
        date: symptom.date 
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
    // 使用对象属性赋值替代展开运算符 
    if (newSettings.averageCycleLength !== undefined) { 
      this.settings.averageCycleLength = newSettings.averageCycleLength; 
    } 
    if (newSettings.averagePeriodLength !== undefined) { 
      this.settings.averagePeriodLength = newSettings.averagePeriodLength; 
    } 
    if (newSettings.reminderEnabled !== undefined) { 
      this.settings.reminderEnabled = newSettings.reminderEnabled; 
    } 
    if (newSettings.themeColor !== undefined) { 
      this.settings.themeColor = newSettings.themeColor; 
    } 
    if (newSettings.darkMode !== undefined) { 
      this.settings.darkMode = newSettings.darkMode; 
    } 
    if (newSettings.onboardingCompleted !== undefined) { 
      this.settings.onboardingCompleted = newSettings.onboardingCompleted; 
    } 
    
    // 保存到存储 
    await this.storageService.saveSettings(this.settings); 
  } 

  // 获取设置 
  getSettings(): UserSettings { 
    // 深拷贝返回设置对象 
    return { 
      averageCycleLength: this.settings.averageCycleLength, 
      averagePeriodLength: this.settings.averagePeriodLength, 
      reminderEnabled: this.settings.reminderEnabled, 
      themeColor: this.settings.themeColor, 
      darkMode: this.settings.darkMode, 
      onboardingCompleted: this.settings.onboardingCompleted 
    }; 
  } 

  // 删除记录 
  async deleteRecord(id: string): Promise<boolean> { 
    const initialLength = this.records.length; 
    this.records = this.records.filter(record => record.id !== id); 
    
    if (this.records.length < initialLength) { 
      // 重新初始化计算器数据
      const cycleData: CycleData[] = this.records.map(record => ({
        startDate: record.startDate,
        cycleDays: record.cycleLength,
        periodDays: record.periodLength
      })); 
      this.calculator = new PeriodCalculator(cycleData); 
      
      // 保存到存储 
      await this.storageService.savePeriodRecords(this.records); 
      return true; 
    } 
    
    return false; 
  } 

  // 获取预测结果 
  getPrediction(): PredictionResult { 
    const result = this.calculator.predictNextPeriod(); 
    
    // 计算易孕期（排卵日前5天到后2天）
    const fertileWindow: DateRange = {
      start: this.calculator.addDays(result.ovulationDate, -5),
      end: this.calculator.addDays(result.ovulationDate, 2)
    }; 
    
    // 计算安全期 
    const lastRecord = this.getLatestRecord(); 
    const periodEnd = lastRecord ? this.calculator.addDays(lastRecord.startDate, lastRecord.periodLength) : new Date(); 
    
    return {
      nextPeriod: result.nextPeriodDate,
      ovulationDay: result.ovulationDate,
      fertileWindow,
      safePeriod: {
        start: periodEnd,
        end: this.calculator.addDays(result.nextPeriodDate, -1)
      }
    }; 
  } 

  // 获取当前周期阶段 
  getCurrentPhase(): string { 
    const result = this.calculator.getCurrentCyclePhase(); 
    return result.phase; 
  } 

  // 获取距离下次月经的天数 
  getDaysUntilNextPeriod(): number { 
    try { 
      const result = this.calculator.predictNextPeriod(); 
      return result.daysUntilNextPeriod; 
    } catch (e) { 
      // 如果没有数据，使用默认设置计算 
      return this.settings.averageCycleLength; 
    } 
  } 

  // 获取周期统计信息 
  getCycleStats(): CycleStats { 
    return { 
      averageCycleLength: this.calculator.calculateAverageCycleLength(), 
      averagePeriodLength: this.calculator.calculateAveragePeriodLength(), 
      recordCount: this.records.length, 
      cycleVariability: this.calculator.calculateCycleVariability() 
    }; 
  } 

  // 获取周期趋势数据（用于图表展示） 
  getCycleTrendData(): CycleTrendData { 
    const trendData = this.calculator.generateCycleTrendData(); 
    
    // 转换为兼容原有图表的格式 
    return { 
      dates: trendData.map(data => data.month), 
      cycleLengths: trendData.map(data => data.cycleLength), 
      periodLengths: trendData.map(data => data.periodLength) 
    }; 
  } 

  // 清除所有数据 
  async clearAllData(): Promise<void> { 
    // 清空本地记录 
    this.records = []; 
    
    // 重置计算器 
    this.calculator = new PeriodCalculator(); 
    
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