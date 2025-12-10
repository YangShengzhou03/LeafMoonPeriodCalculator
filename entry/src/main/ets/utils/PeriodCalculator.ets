// entry/src/main/ets/utils/PeriodCalculator.ets 
/** 
 * 经期计算器工具类 
 * 修复：独立函数改为类方法、声明显式接口、移除this在独立函数中的使用 
 */ 

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

  // 显式声明返回类型 
  public getCurrentCyclePhase(): CyclePhaseResult { 
    const today = new Date(); 
    let phase = "安全期"; 
    let daysRemaining = 0; 

    if (this.cycleData.length > 0) { 
      const lastCycle = this.cycleData[this.cycleData.length - 1]; 
      const nextPeriod = new Date(lastCycle.startDate); 
      nextPeriod.setDate(nextPeriod.getDate() + lastCycle.cycleDays); 
      const ovulationDate = new Date(nextPeriod); 
      ovulationDate.setDate(ovulationDate.getDate() - 14); 

      // 检查是否在经期 
      const periodEnd = new Date(lastCycle.startDate); 
      periodEnd.setDate(periodEnd.getDate() + lastCycle.periodDays); 
      
      if (today >= lastCycle.startDate && today <= periodEnd) { 
        phase = "经期"; 
        daysRemaining = Math.ceil((periodEnd.getTime() - today.getTime()) / (1000 * 60 * 60 * 24)); 
      } 
      // 检查是否在排卵期 
      else if ( 
        today >= new Date(ovulationDate.getTime() - 2 * 24 * 60 * 60 * 1000) && 
        today <= new Date(ovulationDate.getTime() + 1 * 24 * 60 * 60 * 1000) 
      ) { 
        phase = "排卵期"; 
        daysRemaining = Math.ceil((ovulationDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24)); 
      } 
    } 

    return { phase, daysRemaining }; 
  } 

  // 显式声明返回类型 
  public calculateAverageCycleLength(): number { 
    if (this.cycleData.length === 0) return 28; 
    
    const total = this.cycleData.reduce((sum, data) => sum + data.cycleDays, 0); 
    return Math.round(total / this.cycleData.length); 
  } 

  // 显式声明返回类型 
  public calculateAveragePeriodLength(): number { 
    if (this.cycleData.length === 0) return 5; 
    
    const total = this.cycleData.reduce((sum, data) => sum + data.periodDays, 0); 
    return Math.round(total / this.cycleData.length); 
  } 

  // 显式声明返回类型 
  public calculateCycleVariability(): number { 
    if (this.cycleData.length < 2) return 0; 
    
    const avg = this.calculateAverageCycleLength(); 
    const variance = this.cycleData.reduce( 
      (sum, data) => sum + Math.pow(data.cycleDays - avg, 2), 
      0 
    ); 
    return Math.round(Math.sqrt(variance / this.cycleData.length)); 
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

  // 工具方法：添加天数（改为公共方法，修复private访问错误） 
  public addDays(date: Date, days: number): Date { 
    const newDate = new Date(date); 
    newDate.setDate(newDate.getDate() + days); 
    return newDate; 
  } 

  // 添加数据 
  public addCycleData(data: CycleData): void { 
    this.cycleData.push(data); 
  } 

  // 获取所有数据 
  public getAllCycleData(): CycleData[] { 
    return [...this.cycleData]; // 返回副本，避免外部修改 
  } 
}