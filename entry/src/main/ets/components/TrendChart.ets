import { Stack, Row, Canvas, Text } from '@ohos.arkui';
import { CanvasRenderingContext2D } from '@ohos.canvas.canvas';
import { FlexAlign } from '@ohos.arkui';

export interface ChartData {
  dates: string[];
  cycleLengths: number[];
  periodLengths: number[];
}

@Component
export struct TrendChart {
  @Prop data: ChartData;
  @Prop chartWidth: number;
  @Prop chartHeight: number;

  // 图表配置
  private readonly chartPadding: number = 40;
  private readonly lineWidth: number = 2;
  private readonly dotRadius: number = 4;
  private readonly gridColor: string = '#E0E0E0';
  private readonly cycleLineColor: string = '#FF6B6B'; // 周期长度线条颜色
  private readonly periodLineColor: string = '#4ECDC4'; // 经期长度线条颜色
  private readonly textColor: string = '#333333';

  build() {
    Stack() {
      // 图表画布
      Canvas(this.onDrawChart)
        .width(this.chartWidth)
        .height(this.chartHeight)
        .backgroundColor('#FFFFFF')

      // 图例
      Row() {
        // 周期长度图例
        Row() {
          Canvas((context: CanvasRenderingContext2D) => {
            context.strokeStyle = this.cycleLineColor;
            context.lineWidth = this.lineWidth;
            context.beginPath();
            context.moveTo(0, 5);
            context.lineTo(20, 5);
            context.stroke();
            
            // 绘制点
            context.fillStyle = this.cycleLineColor;
            context.beginPath();
            context.arc(10, 5, this.dotRadius, 0, Math.PI * 2);
            context.fill();
          })
          .width(24)
          .height(10)
          
          Text('周期长度 (天)')
            .fontSize(12)
            .fontColor(this.textColor)
            .margin({ left: 4 })
        }
        
        // 经期长度图例
        Row()
          .margin({ left: 20 })
        {
          Canvas((context: CanvasRenderingContext2D) => {
            context.strokeStyle = this.periodLineColor;
            context.lineWidth = this.lineWidth;
            context.beginPath();
            context.moveTo(0, 5);
            context.lineTo(20, 5);
            context.stroke();
            
            // 绘制点
            context.fillStyle = this.periodLineColor;
            context.beginPath();
            context.arc(10, 5, this.dotRadius, 0, Math.PI * 2);
            context.fill();
          })
          .width(24)
          .height(10)
          
          Text('经期长度 (天)')
            .fontSize(12)
            .fontColor(this.textColor)
            .margin({ left: 4 })
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ top: 10 })
    }
  }

  // 绘制图表
  private onDrawChart(context: CanvasRenderingContext2D): void {
    // 检查是否有数据
    if (this.data.dates.length === 0) {
      this.drawNoData(context);
      return;
    }

    // 计算图表区域尺寸
    const chartWidth = this.chartWidth - 2 * this.chartPadding;
    const chartHeight = this.chartHeight - 2 * this.chartPadding;

    // 绘制网格
    this.drawGrid(context, chartWidth, chartHeight);

    // 计算数据范围
    const allValues = [...this.data.cycleLengths, ...this.data.periodLengths];
    const maxValue = Math.max(...allValues) + 2;
    const minValue = Math.max(1, Math.min(...allValues) - 2); // 确保最小不小于1
    const valueRange = maxValue - minValue;

    // 绘制周期长度线条
    this.drawLineChart(
      context, 
      this.data.cycleLengths, 
      chartWidth, 
      chartHeight, 
      minValue, 
      valueRange, 
      this.cycleLineColor
    );

    // 绘制经期长度线条
    this.drawLineChart(
      context, 
      this.data.periodLengths, 
      chartWidth, 
      chartHeight, 
      minValue, 
      valueRange, 
      this.periodLineColor
    );

    // 绘制坐标轴标签
    this.drawAxisLabels(context, chartWidth, chartHeight, minValue, maxValue, valueRange);
  }

  // 绘制无数据提示
  private drawNoData(context: CanvasRenderingContext2D): void {
    context.fillStyle = this.textColor;
    context.font = '14px sans-serif';
    context.textAlign = 'center';
    context.textBaseline = 'middle';
    context.fillText('暂无数据', this.chartWidth / 2, this.chartHeight / 2);
  }

  // 绘制网格
  private drawGrid(context: CanvasRenderingContext2D, width: number, height: number): void {
    context.strokeStyle = this.gridColor;
    context.lineWidth = 0.5;

    // 绘制垂直线
    const verticalLines = Math.min(6, this.data.dates.length - 1);
    for (let i = 0; i <= verticalLines; i++) {
      const x = this.chartPadding + (width / verticalLines) * i;
      context.beginPath();
      context.moveTo(x, this.chartPadding);
      context.lineTo(x, this.chartPadding + height);
      context.stroke();
    }

    // 绘制水平线
    const horizontalLines = 5;
    for (let i = 0; i <= horizontalLines; i++) {
      const y = this.chartPadding + (height / horizontalLines) * i;
      context.beginPath();
      context.moveTo(this.chartPadding, y);
      context.lineTo(this.chartPadding + width, y);
      context.stroke();
    }
  }

  // 绘制线条图表
  private drawLineChart(
    context: CanvasRenderingContext2D,
    values: number[],
    width: number,
    height: number,
    minValue: number,
    valueRange: number,
    color: string
  ): void {
    if (values.length === 0) return;

    context.strokeStyle = color;
    context.lineWidth = this.lineWidth;
    context.lineCap = 'round';
    context.lineJoin = 'round';

    // 开始绘制线条
    context.beginPath();
    
    for (let i = 0; i < values.length; i++) {
      const x = this.chartPadding + (i / (values.length - 1)) * width;
      const y = this.chartPadding + height - ((values[i] - minValue) / valueRange) * height;

      if (i === 0) {
        context.moveTo(x, y);
      } else {
        context.lineTo(x, y);
      }
    }
    
    context.stroke();

    // 绘制数据点
    context.fillStyle = color;
    for (let i = 0; i < values.length; i++) {
      const x = this.chartPadding + (i / (values.length - 1)) * width;
      const y = this.chartPadding + height - ((values[i] - minValue) / valueRange) * height;
      
      context.beginPath();
      context.arc(x, y, this.dotRadius, 0, Math.PI * 2);
      context.fill();
    }
  }

  // 绘制坐标轴标签
  private drawAxisLabels(
    context: CanvasRenderingContext2D,
    width: number,
    height: number,
    minValue: number,
    maxValue: number,
    valueRange: number
  ): void {
    context.fillStyle = this.textColor;
    context.font = '12px sans-serif';
    context.textAlign = 'center';
    context.textBaseline = 'top';

    // 绘制X轴日期标签（只显示部分日期避免重叠）
    const labelCount = Math.min(6, this.data.dates.length);
    const step = Math.max(1, Math.floor(this.data.dates.length / labelCount));
    
    for (let i = 0; i < this.data.dates.length; i += step) {
      const x = this.chartPadding + (i / (this.data.dates.length - 1)) * width;
      const dateText = this.data.dates[i];
      context.fillText(dateText, x, this.chartPadding + height + 5);
    }

    // 绘制Y轴数值标签
    context.textAlign = 'right';
    context.textBaseline = 'middle';
    
    const yLabels = 5;
    for (let i = 0; i <= yLabels; i++) {
      const y = this.chartPadding + (i / yLabels) * height;
      const value = Math.round(maxValue - (i / yLabels) * valueRange);
      context.fillText(value.toString(), this.chartPadding - 5, y);
    }
  }
}
