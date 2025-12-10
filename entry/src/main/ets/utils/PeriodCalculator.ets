// 周期计算工具类
import { PeriodRecord, PredictionResult, UserSettings } from '../model/PeriodData';

// 定义周期统计结果接口
interface CycleStats {
  average: number;
  stdDev: number;
}

export class PeriodCalculator {
  // 添加天数到日期
  private static addDays(date: Date, days: number): Date {
    const result = new Date(date);
    result.setDate(result.getDate() + days);
    return result;
  }

  // 格式化日期为YYYY-MM-DD
  static formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  // 解析YYYY-MM-DD格式的日期
  static parseDate(dateString: string): Date {
    return new Date(dateString);
  }

  // 比较两个日期是否为同一天
  static isSameDay(date1: Date, date2: Date): boolean {
    return (
      date1.getFullYear() === date2.getFullYear() &&
      date1.getMonth() === date2.getMonth() &&
      date1.getDate() === date2.getDate()
    );
  }

  // 计算周期的统计数据
  private static calculateCycleStats(records: PeriodRecord[]): CycleStats {
    if (records.length < 2) {
      return { average: 28, stdDev: 2 }; // 默认值
    }

    // 计算相邻周期的长度
    const sortedRecords = [...records].sort((a, b) => a.startDate.getTime() - b.startDate.getTime());
    const cycleLengths: number[] = [];

    for (let i = 1; i < sortedRecords.length; i++) {
      const prevStart = sortedRecords[i - 1].startDate;
      const currentStart = sortedRecords[i].startDate;
      const diffDays = Math.ceil((currentStart.getTime() - prevStart.getTime()) / (1000 * 60 * 60 * 24));
      cycleLengths.push(diffDays);
    }

    // 计算平均值
    const average = cycleLengths.reduce((sum, length) => sum + length, 0) / cycleLengths.length;

    // 计算标准差
    const squaredDiffs = cycleLengths.map(length => Math.pow(length - average, 2));
    const variance = squaredDiffs.reduce((sum, diff) => sum + diff, 0) / squaredDiffs.length;
    const stdDev = Math.sqrt(variance);

    return { average, stdDev };
  }

  // 根据最近记录预测下次月经和排卵期
  static predictNextPeriod(record: PeriodRecord | null, settings: UserSettings, allRecords: PeriodRecord[] = []): PredictionResult {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    let lastPeriodStart: Date;
    let cycleLength: number;
    let periodLength: number;

    if (record) {
      lastPeriodStart = record.startDate;
      
      // 如果有足够的历史记录，使用统计数据
      if (allRecords.length >= 3) {
        const stats = this.calculateCycleStats(allRecords);
        cycleLength = stats.average;
        periodLength = this.calculateAveragePeriodLength(allRecords);
      } else {
        cycleLength = record.cycleLength;
        periodLength = record.periodLength;
      }
    } else {
      // 如果没有记录，使用默认设置从今天开始计算
      lastPeriodStart = today;
      cycleLength = settings.averageCycleLength;
      periodLength = settings.averagePeriodLength;
    }

    // 计算下次月经日期
    const nextPeriod = this.addDays(lastPeriodStart, cycleLength);

    // 计算排卵日（通常在下次月经前14天）
    const ovulationDay = this.addDays(nextPeriod, -14);

    // 计算易孕期（排卵日前5天到后2天）
    const fertileWindow = {
      start: this.addDays(ovulationDay, -5),
      end: this.addDays(ovulationDay, 2)
    };

    // 计算安全期
    // 安全期1：月经结束后到易孕期开始前
    const periodEnd = this.addDays(lastPeriodStart, periodLength);
    const safePeriod1End = this.addDays(fertileWindow.start, -1);

    // 安全期2：易孕期结束后到下次月经开始前
    const safePeriod2Start = this.addDays(fertileWindow.end, 1);
    const safePeriod2End = this.addDays(nextPeriod, -1);

    // 合并安全期（如果有重叠）
    let safePeriod = {
      start: periodEnd,
      end: safePeriod2End
    };

    // 确保日期在合理范围内
    if (safePeriod.start > today) {
      safePeriod.start = today;
    }

    return {
      nextPeriod,
      ovulationDay,
      fertileWindow,
      safePeriod
    };
  }

  // 计算当前处于周期的哪个阶段
  static getCurrentCyclePhase(date: Date, record: PeriodRecord | null, settings: UserSettings, allRecords: PeriodRecord[] = []): string {
    const prediction = this.predictNextPeriod(record, settings, allRecords);
    
    // 检查是否处于月经期
    if (record) {
      const periodEnd = this.addDays(record.startDate, record.periodLength);
      if (date >= record.startDate && date <= periodEnd) {
        return 'period'; // 月经期
      }
    }

    // 检查是否处于易孕期
    if (date >= prediction.fertileWindow.start && date <= prediction.fertileWindow.end) {
      // 检查是否是排卵日
      if (this.isSameDay(date, prediction.ovulationDay)) {
        return 'ovulation'; // 排卵日
      }
      return 'fertile'; // 易孕期
    }

    // 检查是否处于安全期
    if ((date >= prediction.safePeriod.start && date <= prediction.safePeriod.end) ||
        (record && date <= this.addDays(record.startDate, record.periodLength))) {
      return 'safe'; // 安全期
    }

    // 检查是否接近下次月经
    const daysUntilNextPeriod = Math.ceil((prediction.nextPeriod.getTime() - date.getTime()) / (1000 * 60 * 60 * 24));
    if (daysUntilNextPeriod <= 3) {
      return 'approaching'; // 即将来月经
    }

    return 'normal'; // 正常时期
  }

  // 计算距离下次月经的天数
  static daysUntilNextPeriod(record: PeriodRecord | null, settings: UserSettings, allRecords: PeriodRecord[] = []): number {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const prediction = this.predictNextPeriod(record, settings, allRecords);
    const timeDiff = prediction.nextPeriod.getTime() - today.getTime();
    return Math.ceil(timeDiff / (1000 * 60 * 60 * 24));
  }

  // 计算平均周期长度
  static calculateAverageCycleLength(records: PeriodRecord[]): number {
    if (records.length < 2) {
      return 28; // 默认值
    }

    let totalDays = 0;
    let count = 0;

    // 按日期排序
    const sortedRecords = [...records].sort((a, b) => a.startDate.getTime() - b.startDate.getTime());

    for (let i = 1; i < sortedRecords.length; i++) {
      const prevStart = sortedRecords[i - 1].startDate;
      const currentStart = sortedRecords[i].startDate;
      const diffDays = Math.ceil((currentStart.getTime() - prevStart.getTime()) / (1000 * 60 * 60 * 24));
      totalDays += diffDays;
      count++;
    }

    return count > 0 ? Math.round(totalDays / count) : 28;
  }

  // 计算周期波动（标准差）
  static calculateCycleVariability(records: PeriodRecord[]): number {
    if (records.length < 3) {
      return 2; // 默认值
    }

    const cycleLengths: number[] = [];
    const sortedRecords = [...records].sort((a, b) => a.startDate.getTime() - b.startDate.getTime());

    for (let i = 1; i < sortedRecords.length; i++) {
      const prevStart = sortedRecords[i - 1].startDate;
      const currentStart = sortedRecords[i].startDate;
      const diffDays = Math.ceil((currentStart.getTime() - prevStart.getTime()) / (1000 * 60 * 60 * 24));
      cycleLengths.push(diffDays);
    }

    const average = cycleLengths.reduce((sum, length) => sum + length, 0) / cycleLengths.length;
    const squaredDiffs = cycleLengths.map(length => Math.pow(length - average, 2));
    const variance = squaredDiffs.reduce((sum, diff) => sum + diff, 0) / squaredDiffs.length;
    const stdDev = Math.sqrt(variance);

    return Math.round(stdDev * 10) / 10; // 保留一位小数
  }

  // 计算平均经期长度
  static calculateAveragePeriodLength(records: PeriodRecord[]): number {
    if (records.length === 0) {
      return 5; // 默认值
    }

    const totalDays = records.reduce((sum, record) => sum + record.periodLength, 0);
    return Math.round(totalDays / records.length);
  }

  // 生成周期趋势数据（用于图表展示）
  static generateCycleTrendData(records: PeriodRecord[]): { dates: string[]; cycleLengths: number[]; periodLengths: number[] } {
    if (records.length === 0) {
      return { dates: [], cycleLengths: [], periodLengths: [] };
    }

    // 按日期排序
    const sortedRecords = [...records].sort((a, b) => a.startDate.getTime() - b.startDate.getTime());

    const dates: string[] = [];
    const cycleLengths: number[] = [];
    const periodLengths: number[] = [];

    // 处理第一个记录
    dates.push(this.formatDate(sortedRecords[0].startDate));
    periodLengths.push(sortedRecords[0].periodLength);
    cycleLengths.push(sortedRecords[0].cycleLength); // 使用记录的周期长度

    // 处理后续记录
    for (let i = 1; i < sortedRecords.length; i++) {
      dates.push(this.formatDate(sortedRecords[i].startDate));
      periodLengths.push(sortedRecords[i].periodLength);
      
      // 计算实际周期长度
      const prevStart = sortedRecords[i - 1].startDate;
      const currentStart = sortedRecords[i].startDate;
      const cycleLength = Math.ceil((currentStart.getTime() - prevStart.getTime()) / (1000 * 60 * 60 * 24));
      cycleLengths.push(cycleLength);
    }

    return { dates, cycleLengths, periodLengths };
  }
}
