# Pace. — 原生 SwiftUI 版本

> 静默奔跑 · 智慧恢复  
> 同款设计，纯原生 SwiftUI 实现，告别 RN 损耗。

[![Swift](https://img.shields.io/badge/Swift-5.5+-FA7343.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-14.0+-black.svg)](https://apple.com/ios)
[![Xcode](https://img.shields.io/badge/Xcode-13.2.1-1575F9.svg)](https://developer.apple.com/xcode/)

---

## 你的 Mac 配置（已确认）

- **MacBook Pro Retina 13" Late 2013**
- **macOS Big Sur 11.7.10**
- **Intel CPU**

这套配置最高可装 **Xcode 13.2.1**，能写 iOS 14-15 SDK 的应用。**完全够用** — 我把所有 SwiftUI 代码控制在 iOS 14 deployment target，对应 SwiftUI 2.x 的稳定能力。

---

## 一次性环境搭建（约 30-60 分钟，主要是下载时间）

### 1. 装 Xcode 13.2.1

打开 **App Store** → 搜 `Xcode` → 看到的是最新版（不兼容你的 Big Sur）。**不能装 App Store 的版本**。

去 https://developer.apple.com/download/all/ → **Apple ID 登录**（用你的 iCloud 账号即可，免费）→ 搜索栏输入 `Xcode 13.2.1` → 下载 `Xcode_13.2.1.xip`（约 11 GB）

下载完双击 `.xip` 解压（5-15 分钟，老 Mac 慢点正常）→ 把 `Xcode.app` 拖进 `/Applications/`

第一次打开 Xcode 会让你装"额外组件"（点 Install）+ 接受协议。**给它 5-10 分钟初始化**。

### 2. 注册免费 Apple Developer 账号

不用付那 ¥688/年的开发者会员（那是上架 App Store 才需要的）。**真机调试只需要免费 Apple ID**：

Xcode 菜单 → `Settings...` → `Accounts` → 左下 `+` → `Apple ID` → 用你的 iCloud 账号登录。

### 3. iPhone 准备

- 用**数据线**连接 iPhone 到 Mac
- iPhone 弹"信任此电脑" → 点信任
- iPhone 设置 → 隐私与安全 → 滚到底 → **开发者模式**（开关打开）→ 重启 iPhone
- 重启后再次开关一次确认

---

## 跑起这个项目（每次 1 分钟）

### 第一次：创建 Xcode 项目（仅一次）

由于 `.xcodeproj` 文件由 Xcode 管理（不能手写），第一次需要你在 Xcode 里**创建一个空项目**，然后把我提供的源文件拖进去。

**Step 1**：Xcode → `File` → `New` → `Project...`

**Step 2**：左侧选 `iOS`，模板选 `App`，点 `Next`

**Step 3**：项目配置（重要！）
- **Product Name**: `Pace`
- **Team**: 选你刚才登录的 Apple ID
- **Organization Identifier**: `com.liuyu`（或任何你喜欢的反向域名）
- **Interface**: `SwiftUI`
- **Language**: `Swift`
- **Use Core Data**: ❌ **不勾**
- **Include Tests**: ❌ **不勾**

点 `Next` → 选保存位置 → **保存到 `D:\web3\pace-ios\`**（即你当前 git clone 的根目录）→ 点 `Create`

**Step 4**：Xcode 会生成一些默认文件：
- `Pace/PaceApp.swift`（默认入口）
- `Pace/ContentView.swift`（默认空 View）
- `Pace/Assets.xcassets/`
- `Pace/Preview Content/`

**用我提供的同名文件覆盖**这些默认文件（Finder 里直接复制覆盖即可）。

**Step 5**：在 Xcode 项目导航器里，右键 `Pace` 文件夹 → `Add Files to "Pace"...` → 选我提供的整个 `Pace/Theme/`、`Pace/Components/`、`Pace/Screens/` 文件夹 → 勾选 `Copy items if needed`、`Create groups`、target 选 `Pace` → 点 Add

**Step 6**：设置 Deployment Target

点项目文件（最上面的 `Pace`）→ TARGETS 选 `Pace` → `General` → `Minimum Deployments` → `iOS` 设为 `14.0`

### 编译运行（每次只用做这步）

**模拟器版**：
Xcode 顶部 device 选择器 → 选 `iPhone 13` 或类似 → 按 `⌘R` → 等编译（首次 1-3 分钟，之后秒级）→ 模拟器会弹出来自动跑应用

**真机版（推荐）**：
Xcode 顶部 device 选择器 → 选你的 iPhone 名字（数据线已插好）→ 按 `⌘R`

**第一次连真机的提示**：
- iPhone 上会弹"开发者无法信任"→ iPhone 设置 → 通用 → VPN 与设备管理 → 你的 Apple ID → 信任
- Xcode 可能提示 "签名错误"→ 点 `Try Again` 通常自动修复

---

## 项目结构

```
pace-ios/
├── Pace/                       Xcode 项目源代码目录
│   ├── PaceApp.swift           @main App 入口
│   ├── ContentView.swift       根 View → IdleHome
│   ├── Theme/
│   │   ├── Colors.swift        色板 (与 HTML demo 完全一致)
│   │   ├── Typography.swift    字体系统
│   │   ├── Spacing.swift       间距 token
│   │   └── MockData.swift      Mock 数据
│   ├── Components/
│   │   ├── Hairline.swift      0.5px 渐变分隔线
│   │   ├── TimelineDots.swift  14 天活力点
│   │   ├── DialCard.swift      WHOOP 风环形 dial
│   │   └── StartButton.swift   出发按钮（含光晕呼吸）
│   ├── Screens/
│   │   └── IdleHome.swift      Phone 01 待机首页
│   └── Resources/
│       └── Fonts/              字体文件（v0.2 加入）
├── Pace.xcodeproj/             Xcode 自动管理（你创建项目时生成，不要手动改）
├── README.md                   本文档
└── .gitignore                  Xcode / Swift 标准
```

---

## 当前 v0.1 实现进度

| 屏 | 状态 | 备注 |
|---|---|---|
| **01 待机首页** | ✅ 完整实现 | 三联表盘 + 出发按钮 + 14 天时间线 |
| 02-16 | ⏳ 后续 iteration | 我会在你确认 v0.1 跑通后逐个加 |

---

## 技术决策记录

### 为什么用 SwiftUI（不用 UIKit）
- 声明式语法 → 代码量少 60%
- 跟 HTML demo 的 React 模式更接近
- 可读性高，方便你将来自己改

### 为什么 deployment target = iOS 14（不是 15/16/17）
- 兼容你的 Xcode 13.2.1（最高支持 iOS 15.2 SDK）
- iOS 14 是 SwiftUI 2.x，**95% 的 SwiftUI 能力都已稳定**
- 你的 iPhone 是 iOS 17/18，向后兼容 → 完美运行

### 跳过哪些 iOS 17+ 炫技 API
| 不用的 | 用什么替代 |
|---|---|
| `@Observable` 宏 (iOS 17+) | `@StateObject` + `ObservableObject`（iOS 14） |
| `Charts` framework (iOS 16+) | 手写 `Path` + `GeometryReader` |
| `NavigationStack` (iOS 16+) | `NavigationView`（iOS 14） |
| `presentationDetents` (iOS 16+) | `.fullScreenCover` 或 `.sheet` |
| `.symbolEffect` (iOS 17+) | 手动 `withAnimation` + `.scaleEffect` |
| `SwiftData` (iOS 17+) | `Codable` + `UserDefaults` |
| `ActivityKit` (iOS 16+ + EAS) | iOS 真灵动岛由系统接管（暂跳过） |

**结论**：所有 Pace. 核心功能 100% 覆盖。少几个语法糖，无视觉损失。

---

## 反馈

跑起来后告诉我：
1. **能不能编译**（如果报错截 Xcode 错误信息发我）
2. **能不能装到 iPhone**（数据线连上、信任后）
3. **首次安装到 iPhone 上的视觉效果**（截图）

我会基于反馈调整设计 token 和组件，然后开始写后续 15 个屏。
