# LeafMoonPeriodCalculator

LeafMoonPeriodCalculator 是一个基于 HarmonyOS 开发的智能生理期计算器应用，帮助女性轻松追踪和预测月经周期，关爱女性健康。

## ✨ 功能特点

### 核心功能
- 📅 **周期记录**: 便捷记录每次月经开始和结束日期
- 📊 **智能预测**: 基于历史数据预测下次月经、排卵日和易孕期
- 🎨 **视觉化日历**: 直观展示周期各阶段（月经期、排卵期、易孕期、安全期）
- 📈 **数据分析**: 计算平均周期长度和经期长度
- 💾 **数据持久化**: 本地存储用户数据，确保数据安全

### 用户体验
- � 简洁直观的用户界面
- 📱 适配多种 HarmonyOS 设备
- ⚡ 流畅的操作体验
- 🎨 温馨的配色方案

## 🛠️ 技术架构

### 开发框架与语言
- **开发框架**: HarmonyOS
- **编程语言**: ArkTS
- **UI框架**: ArkUI
- **构建工具**: Hvigor

### 项目结构
```
LeafMoonPeriodCalculator/
├── AppScope/                    # 应用全局配置
│   ├── app.json5               # 应用配置文件
│   └── resources/              # 应用资源文件
├── entry/                       # 主入口模块
│   ├── src/main/ets/           # 核心代码目录
│   │   ├── entryability/       # 应用启动入口
│   │   ├── model/              # 数据模型
│   │   ├── pages/              # 页面组件
│   │   ├── services/           # 服务层
│   │   └── utils/              # 工具类
│   └── resources/              # 模块资源
├── hvigor/                      # Hvigor 构建配置
├── LICENSE                      # MIT 许可证
└── README.md                    # 项目说明文档
```

### 核心模块
1. **数据模型** (`model/PeriodData.ets`)
   - 定义周期记录、预测结果和用户设置的数据结构
   - 提供数据管理方法

2. **计算工具** (`utils/PeriodCalculator.ets`)
   - 实现周期计算算法
   - 预测下次月经和排卵期
   - 计算易孕期和安全期

3. **存储服务** (`services/StorageService.ets`)
   - 使用 Preferences API 实现数据持久化
   - 保存和加载用户数据

4. **页面组件**
   - `Index.ets`: 主页面，显示当前状态和快捷操作
   - `CalendarPage.ets`: 日历视图，可视化展示周期信息

## 📱 安装和运行

### 环境要求
- DevEco Studio
- HarmonyOS SDK
- Node.js
- HarmonyOS 模拟器或真机设备

### 安装步骤

1. **克隆项目**
   ```bash
   git clone <repository-url>
   cd LeafMoonPeriodCalculator
   ```

2. **安装依赖**
   ```bash
   npm install
   ```

3. **构建项目**
   ```bash
   npm run build
   ```

4. **运行应用**
   - 在 DevEco Studio 中打开项目
   - 连接模拟器或真机设备
   - 点击 "Run" 按钮运行应用

## 🚀 使用指南

### 基本操作

1. **记录月经**
   - 点击 "记录月经" 按钮
   - 在日期选择器中选择开始日期
   - 系统会根据默认设置自动计算结束日期

2. **查看预测**
   - 主页面会显示当前周期阶段
   - 预测下次月经、排卵日、易孕期和安全期

3. **日历视图**
   - 点击 "查看日历" 按钮进入日历页面
   - 可视化查看每月周期各阶段
   - 不同颜色标记不同周期阶段

### 周期阶段说明

| 阶段 | 颜色 | 说明 |
|------|------|------|
| 月经期 | 红色 | 月经期间 |
| 排卵日 | 黄色 | 最易受孕的日期 |
| 易孕期 | 橙色 | 容易受孕的时间段 |
| 安全期 | 绿色 | 不容易受孕的时间段 |
| 即将经期 | 浅红色 | 即将来月经的时间段 |

## 📝 开发说明

### 代码风格
- 遵循 HarmonyOS ArkTS 开发规范
- 使用 TypeScript 类型系统确保代码安全
- 采用组件化和模块化设计

### 数据存储
- 使用 Preferences API 进行本地数据存储
- 数据格式：JSON
- 加密方式：依赖系统安全机制

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来帮助改进项目！

### 贡献指南
1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 📧 联系方式

如有问题或建议，欢迎通过以下方式联系：

- 项目地址: [GitHub Repository](<repository-url>)
- Issue 跟踪: [GitHub Issues](<repository-url>/issues)

## 🎉 致谢

感谢所有为项目做出贡献的开发者和用户！

---

**LeafMoonPeriodCalculator** - 关爱女性健康，从周期管理开始。