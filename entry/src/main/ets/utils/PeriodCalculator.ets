// entry/src/main/ets/utils/PeriodCalculator.ets 
// 经期计算器工具类
// 导入类型定义
import { PeriodRecord, UserSettings, PredictionResult, DateRange, Symptom } from '../model/PeriodData'; 

// 1. 声明所有需要的接口（替代无类型对象字面量） 
export interface CycleData { 
  startDate: Date; 
  cycleDays: number; 
  periodDays: number; 
  ovulationDay?: number; 
} 

export interface CyclePhaseResult { 
  phase: string; // 经期/排卵期/安全期 
  daysRemaining: number; 
} 

export interface CalculationResult { 
  nextPeriodDate: Date; 
  ovulationDate: Date; 
  cyclePhase: CyclePhaseResult; 
  daysUntilNextPeriod: number; 
} 

export interface TrendData { 
  month: string; 
  cycleLength: number; 
  periodLength: number; 
} 

export interface AverageResult { 
  avgCycleLength: number; 
  avgPeriodLength: number; 
  cycleVariability: number; 
} 

// 2. 封装为类，所有方法使用类属性而非独立函数的this 
export class PeriodCalculator { 
  private cycleData: CycleData[]; 
  
  constructor(initialData: CycleData[] = []) { 
    this.cycleData = initialData; 
  } 

  // 显式声明返回类型，修复 arkts-no-implicit-return-types 
  public predictNextPeriod(): CalculationResult { 
    if (this.cycleData.length === 0) { 
      throw new Error("No cycle data available"); 
    } 

    // 获取最后一条记录 
    const lastCycle = this.cycleData[this.cycleData.length - 1]; 
    // 计算下次经期日期 
    const nextPeriodDate = new Date(lastCycle.startDate); 
    nextPeriodDate.setDate(nextPeriodDate.getDate() + lastCycle.cycleDays); 
    
    // 计算排卵期（经期前14天） 
    const ovulationDate = new Date(nextPeriodDate); 
    ovulationDate.setDate(ovulationDate.getDate() - 14); 
    
    // 计算当前周期阶段 
    const cyclePhase = this.getCurrentCyclePhase(); 
    // 计算距离下次经期的天数 
    const today = new Date(); 
    const daysUntilNextPeriod = Math.ceil( 
      (nextPeriodDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24) 
    ); 

    return { 
      nextPeriodDate, 
      ovulationDate, 
      cyclePhase, 
      daysUntilNextPeriod 
    }; 
  } 

  // 改为静态方法并添加参数，以匹配Index.ets中的调用方式
  public static getCurrentCyclePhase(currentDate: Date, latestRecord: PeriodRecord | null, settings: UserSettings): string {
    if (!latestRecord) {
      return 'safe';
    }

    const today = currentDate;
    const nextPeriod = new Date(latestRecord.startDate);
    nextPeriod.setDate(nextPeriod.getDate() + settings.averageCycleLength);
    const ovulationDate = new Date(nextPeriod);
    ovulationDate.setDate(ovulationDate.getDate() - 14);

    // 检查是否在经期
    const periodEnd = new Date(latestRecord.startDate);
    periodEnd.setDate(periodEnd.getDate() + settings.averagePeriodLength);
    
    if (today >= latestRecord.startDate && today <= periodEnd) {
      return 'period';
    }
    // 检查是否在排卵期
    else if (
      today >= new Date(ovulationDate.getTime() - 2 * 24 * 60 * 60 * 1000) &&
      today <= new Date(ovulationDate.getTime() + 1 * 24 * 60 * 60 * 1000)
    ) {
      return 'ovulation';
    }
    // 检查是否在易孕期
    else if (
      today >= new Date(ovulationDate.getTime() - 5 * 24 * 60 * 60 * 1000) &&
      today <= new Date(ovulationDate.getTime() + 2 * 24 * 60 * 60 * 1000)
    ) {
      return 'fertile';
    }
    // 其他情况为安全期
    else {
      return 'safe';
    }
  } 

  // 改为静态方法并修改参数，以匹配Index.ets中的调用方式
  public static calculateAverageCycleLength(records: PeriodRecord[]): number {
    if (records.length === 0) return 28;
    
    const total = records.reduce((sum: number, record: PeriodRecord) => sum + record.cycleLength, 0);
    return Math.round(total / records.length);
  }

  // 改为静态方法并修改参数，以匹配Index.ets中的调用方式
  public static calculateAveragePeriodLength(records: PeriodRecord[]): number {
    if (records.length === 0) return 5;
    
    const total = records.reduce((sum: number, record: PeriodRecord) => sum + record.periodLength, 0);
    return Math.round(total / records.length);
  }

  // 改为静态方法并修改参数，以匹配Index.ets中的调用方式
  public static calculateCycleVariability(records: PeriodRecord[]): number {
    if (records.length < 2) return 0;
    
    const avg = PeriodCalculator.calculateAverageCycleLength(records);
    const variance = records.reduce(
      (sum: number, record: PeriodRecord) => sum + Math.pow(record.cycleLength - avg, 2),
      0
    );
    return Math.round(Math.sqrt(variance / records.length));
  } 

  // 显式声明返回类型 
  public generateCycleTrendData(): TrendData[] { 
    const trendData: TrendData[] = []; 
    
    this.cycleData.forEach((data, index) => { 
      const month = new Date(data.startDate).toLocaleString('default', { month: 'short' }); 
      trendData.push({ 
        month, 
        cycleLength: data.cycleDays, 
        periodLength: data.periodDays 
      }); 
    }); 
    
    return trendData; 
  } 

  // 工具方法：添加天数（改为静态方法）
  public static addDays(date: Date, days: number): Date {
    const newDate = new Date(date);
    newDate.setDate(newDate.getDate() + days);
    return newDate;
  }

  // 工具方法：格式化日期
  public static formatDate(date: Date): string {
    return `${date.getMonth() + 1}/${date.getDate()}`;
  }

  // 计算距离下次经期的天数
  public static daysUntilNextPeriod(latestRecord: PeriodRecord | null, settings: UserSettings): number {
    if (!latestRecord) {
      return 0;
    }

    const today = new Date();
    const nextPeriod = new Date(latestRecord.startDate);
    nextPeriod.setDate(nextPeriod.getDate() + settings.averageCycleLength);
    
    return Math.ceil((nextPeriod.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
  }

  // 预测下次经期、排卵期等
  public static predictNextPeriod(latestRecord: PeriodRecord | null, settings: UserSettings): PredictionResult {
    if (!latestRecord) {
      const today = new Date();
      return {
        nextPeriod: PeriodCalculator.addDays(today, settings.averageCycleLength),
        ovulationDay: PeriodCalculator.addDays(today, settings.averageCycleLength - 14),
        fertileWindow: {
          start: PeriodCalculator.addDays(today, settings.averageCycleLength - 19),
          end: PeriodCalculator.addDays(today, settings.averageCycleLength - 12)
        },
        safePeriod: {
          start: today,
          end: PeriodCalculator.addDays(today, settings.averageCycleLength - 19)
        }
      };
    }

    const nextPeriod = new Date(latestRecord.startDate);
    nextPeriod.setDate(nextPeriod.getDate() + settings.averageCycleLength);
    
    const ovulationDay = new Date(nextPeriod);
    ovulationDay.setDate(ovulationDay.getDate() - 14);
    
    const fertileWindow: DateRange = {
        start: PeriodCalculator.addDays(ovulationDay, -5),
        end: PeriodCalculator.addDays(ovulationDay, 2)
      };
      
      const safePeriod: DateRange = {
        start: PeriodCalculator.addDays(latestRecord.startDate, settings.averagePeriodLength),
        end: PeriodCalculator.addDays(ovulationDay, -6)
      };
    
    return {
      nextPeriod,
      ovulationDay,
      fertileWindow,
      safePeriod
    };
  } 

  // 添加数据 
  public addCycleData(data: CycleData): void { 
    this.cycleData.push(data); 
  } 

  // 获取所有数据 
  public getAllCycleData(): CycleData[] { 
    return [...this.cycleData]; // 返回副本，避免外部修改 
  }

  // 实例方法：获取当前周期阶段
  public getCurrentCyclePhase(): CyclePhaseResult {
    if (this.cycleData.length === 0) {
      return { phase: 'safe', daysRemaining: 0 };
    }

    const today = new Date();
    const lastCycle = this.cycleData[this.cycleData.length - 1];
    const nextPeriodDate = new Date(lastCycle.startDate);
    nextPeriodDate.setDate(nextPeriodDate.getDate() + lastCycle.cycleDays);
    const ovulationDate = new Date(nextPeriodDate);
    ovulationDate.setDate(ovulationDate.getDate() - 14);
    const periodEnd = new Date(lastCycle.startDate);
    periodEnd.setDate(periodEnd.getDate() + lastCycle.periodDays);

    // 计算距离下次经期的天数
    const daysUntilNextPeriod = Math.ceil((nextPeriodDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));

    // 确定当前周期阶段
    let phase: string;
    if (today >= lastCycle.startDate && today <= periodEnd) {
      phase = 'period';
    } else if (
      today >= new Date(ovulationDate.getTime() - 2 * 24 * 60 * 60 * 1000) &&
      today <= new Date(ovulationDate.getTime() + 1 * 24 * 60 * 60 * 1000)
    ) {
      phase = 'ovulation';
    } else if (
      today >= new Date(ovulationDate.getTime() - 5 * 24 * 60 * 60 * 1000) &&
      today <= new Date(ovulationDate.getTime() + 2 * 24 * 60 * 60 * 1000)
    ) {
      phase = 'fertile';
    } else {
      phase = 'safe';
    }

    return { phase, daysRemaining: daysUntilNextPeriod };
  } 
}