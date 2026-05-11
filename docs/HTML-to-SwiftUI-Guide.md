# HTML → SwiftUI 翻译指南

> 适用：当你有 HTML/CSS 高保真 demo，需要在 iOS 原生 SwiftUI 里复刻视觉时。
>
> 来源：Pace v0.1.0 → v0.2.7 实战 17 个版本踩坑总结。下次同类工作直接照表施工。

---

## 0. 架构决策树（先选路线再写一行代码）

```
你的 demo 是什么？
├─ 仅 HTML demo (无 Figma)
│   ├─ 屏幕需要传感器 / 后台 / 触觉 / Live Activity?
│   │   ├─ 是 → 必须原生 SwiftUI（本指南剩下章节）
│   │   └─ 否 → 看下一题
│   ├─ 你的开发工作流？
│   │   ├─ 全程在 Mac 上 (能 live-reload)
│   │   │   → 可以试 WKWebView 嵌 HTML，"所见即所得"红利成立
│   │   └─ 跨设备 (PC 编辑 / Mac 仅 build)
│   │       → 必须原生 SwiftUI。WebView 红利不成立，改 .html 和改 .swift 一样慢
│   └─ App 长期会扩展原生功能?
│       ├─ 是 → 原生为底，WebView 仅当装饰层
│       └─ 否 → WebView 包装即可
└─ 有 Figma → 用 Locofy / DhiWise 一次性生成 SwiftUI（不在本指南范围）
```

**Pace 项目结论**：跨设备工作流 + 跑步屏需后台 → **原生 SwiftUI**，HTML demo 仅作设计冻结档参考。

---

## 1. Swift 5.4 / iOS 14 雷区（Xcode 12.5 用户必读）

老 Mac (Big Sur 11.7.x) 锁死 Xcode 12.5 → 锁死 Swift 5.4 / iOS 14 SDK。
新 SDK 的便利 API 全用不了，下面这些是踩过的炸弹：

### 1.1 ViewBuilder 10-child 限制 ⚠️ 高频踩坑
**犯错频率**: Pace v0.1.9, v0.4.0, ... 每次写新屏都可能再踩。
**症状**: `Extra argument in call` (假错, 编译器误报真实原因)
**触发**: VStack/HStack/ZStack 直接子元素 > 10
**陷阱**: `Spacer().frame(height: X)` 也算一个子, 不是 brand 那种 view 才算

```swift
// ❌ 11 个子 → 炸
VStack {
    a; Spacer().frame(height: 12); b; Spacer().frame(height: 10); c
    Spacer().frame(height: 10); d; Spacer().frame(height: 14); e; Spacer(); f
}

// ✅ Group { } 合并前 N 个为 1 个子
VStack {
    Group {
        a; Spacer().frame(height: 12); b; Spacer().frame(height: 10); c
        Spacer().frame(height: 10); d; Spacer().frame(height: 14); e
    }
    Spacer()
    f
}
// 实际子元素: Group + Spacer + f = 3 ≤ 10 ✓
```

**写新屏的预防**: 直接子超过 7 就主动 wrap Group。**含 Spacer().frame() 也要数**。

### 1.2 严格 CGFloat / Double 类型 ⚠️ 高频踩坑
**犯错频率**: Pace v0.1.x, v0.4.0, v0.4.0.3 等多次.
**症状**:
- `Binary operator '*' cannot be applied to operands of type 'Double' and 'CGFloat'`
- `Cannot convert value of type 'Double' to expected argument type 'CGFloat'`
- `Cannot convert value of type 'CGFloat' to expected argument type 'Double'`

**根因**: Swift 5.4 / iOS 14 SDK 不自动 Double↔CGFloat 转换 (Swift 5.5+ 引入了 CGFloat ↔ Double 隐式转换, 但 Xcode 12.5 的 5.4 不行)

**铁律**: 在涉及视觉坐标 / 绘图 / 几何计算的代码里, **全程 CGFloat**, 不要混 Double。
- `CGPoint`, `CGRect`, `.frame()`, `.padding()`, `.offset()`, Path 几何 → **必 CGFloat**
- 业务数据 (公里数 / 时长 / 心率) → 用 Double (在 MockData / 业务逻辑层)
- **两边交界处加 `CGFloat(...)` 转换**

```swift
// ❌ 1. 简单情形: Double 计算结果塞 CGFloat 参数
let height = 4.0 + intensity * 4.0   // Double
.frame(height: height)               // 期望 CGFloat → 炸

// ✅
.frame(height: CGFloat(4.0 + intensity * 4.0))


// ❌ 2. 复杂情形: cubicBezier 数学全 Double, 最后塞 CGPoint(x:y:)
private func cubicBezier(t: Double, p0: CGPoint, ...) -> CGPoint {
    let x = mt3 * Double(p0.x) + 3 * mt2 * t * Double(p1.x) + ...   // Double
    return CGPoint(x: x, y: y)   // 期望 CGFloat → 炸
}

// ✅ 全程 CGFloat, 多项式拆子表达式避免类型检查器超时
private func cubicBezier(t: CGFloat, p0: CGPoint, ...) -> CGPoint {
    let mt: CGFloat = 1 - t
    let mt2 = mt * mt
    let three: CGFloat = 3
    // ★ 关键: 拆成 4 个子表达式各自 CGFloat 流, 不混 Double
    let x0 = mt3 * p0.x
    let x1 = three * mt2 * t * p1.x
    let x2 = three * mt * t2 * p2.x
    let x3 = t3 * p3.x
    return CGPoint(x: x0 + x1 + x2 + x3, y: ...)
}
```

**预防 checklist (写绘图代码前)**:
1. 函数签名输入 — 视觉坐标参数声明 `CGFloat`, 业务数据声明 `Double`
2. 中间变量 — 显式 `let mt: CGFloat = ...` 起头, 后续推断也是 CGFloat
3. 字面量常量 — 写 `let three: CGFloat = 3`, 别让编译器猜
4. 多项式 — 超过 3 个加法项就拆子表达式 (类型检查器会超时)
5. 返回 CGPoint/CGRect/CGSize — 确认所有参数都是 CGFloat
6. Animatable Shape — `animatableData: Double` 是 SwiftUI 协议要求, 在 `path()` 内部转成 CGFloat 用

### 1.3 iOS 15+/16+ API 不可用
| 不能用 (iOS 15+/16+) | 替代 (iOS 14) |
|---|---|
| `.buttonStyle(.plain)` | `PlainButtonStyle()` |
| `.tracking()` on Text | `.kerning()` |
| `.foregroundStyle()` | `.foregroundColor()` |
| `LinearGradient(colors:)` | `LinearGradient(gradient: Gradient(colors: [...]))` |
| `.statusBarHidden(_:)` | `.statusBar(hidden:)` |
| `Layout` 协议 | 手写 `Path` / `GeometryReader` |
| `Grid` / `GridRow` | `LazyVGrid` / 自己 HStack 拼 |
| `ViewThatFits` | 手动 size class 分支 |
| `.scrollContentBackground(_:)` | `UITableView.appearance().backgroundColor = ...` |

### 1.4 多参 `.frame()` 假错
```swift
// ❌ 在某些组合下报 "Extra argument in call"
.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

// ✅ 拆成两个 .frame()
.frame(maxWidth: .infinity)
.frame(maxHeight: .infinity, alignment: .center)
```

### 1.5 GeometryReader + 嵌套 frame 慎用
GeometryReader 内部用多参 `.frame(width:height:alignment:)` 容易触发类型推断超时。
能用 ZStack alignment 自然对齐就别用 GeometryReader。

### 1.9 自定义 Shape 不配 .stroke() / .fill() 默认渲染成黑块 ⚠️ 视觉错位

**症状**: 自定义 Shape 在视图里"看不见"或显示为黑块, 编译没报错但视觉缺失.

**根因**: SwiftUI Shape 是 protocol, 直接 `MyShape()` 当 View 用时, 默认会
调用 `.fill(.foreground)`. 在深色背景下 fill 封闭路径区域是黑的, 看起来像
没渲染.

```swift
// ❌ Shape 当 View 用没加 stroke/fill
MyCurveShape()
    .frame(height: 28)
    // 默认 fill → 路径封闭区是黑色 → 曲线看不见

// ✅ 显式 stroke 才画线条
MyCurveShape()
    .stroke(Theme.accent, lineWidth: 1.2)
    .frame(height: 28)
```

**SVG path 翻译时的预防**: `<path stroke="..." stroke-width="..."/>` 必带
对应 `.stroke()` 调用. 翻完后 grep `MyShape\(\)` 确认每处都有 stroke/fill.

**犯错记录**: v0.4.1 ShareView MiniClassicCurve — HTML SVG 有 stroke 但
SwiftUI 翻译时漏写 .stroke(), 用户截图发现"经典 mini 缺曲线"才发现 (v0.4.1.3 修)

### 1.8 .kerning() 是 Text-only 在 iOS 14 ⚠️ 高频踩坑
**犯错频率**: Pace v0.4.1 ShareView MiniData 底部 HR.

**症状**:
- `Value of type 'some View' has no member 'kerning'`
- 后续 modifier 跟着炸 "Cannot infer contextual base..."

**根因**: iOS 14 的 `.kerning(_:)` 是 Text method, 返回 Text. iOS 16+ 才提升为 View modifier.

```swift
// ❌ HStack 是 some View, 不是 Text
HStack { Text("A"); Text("B") }
    .font(...)
    .foregroundColor(...)
    .kerning(1.0)         // 炸: HStack 不是 Text

// ✅ kerning 必须紧贴每个 Text
HStack {
    Text("A").kerning(1.0)
    Text("B").kerning(1.0)
}
.font(...)                // .font 是 View modifier 可以挂 HStack
.foregroundColor(...)
```

**为什么 .font / .foregroundColor 可以但 .kerning 不行**:
- `.font(_:)` / `.foregroundColor(_:)` 是 View modifier, 自动传播给 descendant Text
- `.kerning(_:)` 是 Text method, 返回 Text 不返回 View

### 1.7 数据文件不能用 CGPoint / CGFloat ⚠️ 高频踩坑
**犯错频率**: Pace v0.4.0 写 MockData 路径坐标时踩。
**症状**:
```
Cannot find type 'CGPoint' in scope
Cannot find type 'CGFloat' in scope; did you mean to use 'CGFloat'?
```
**根因**: `import Foundation` **不带** CGPoint / CGFloat —— 它们在 CoreGraphics。

**铁律**:
- MockData / Constants / Model 等**纯数据文件**: 只 `import Foundation`,
  **只用** `Double` / `Int` / `String` / 元组
- 视觉常量（CGFloat 高度、CGPoint 路径坐标）: 放在 **`import SwiftUI` 的 View 文件**里
  作为 private enum / struct 常量

```swift
// ❌ MockData.swift 只 import Foundation
enum PostRun {
    static let routePoints: [CGPoint] = [...]    // 编译失败
    static let chartHeights: [CGFloat] = [...]   // 编译失败
}

// ✅ MockData 纯 Foundation, 视觉数据移到 View 文件
// MockData.swift
enum PostRun {
    static let distanceKm: Double = 5.42  // 业务数据
}

// PostRunView.swift (import SwiftUI)
private enum PaceChartConstants {
    static let splitsY: [CGFloat] = [24, 34, 28, 38, 12]
}
```

**例外**: 如果非要在 MockData 里用 CG 类型, 加 `import CoreGraphics` 即可。
但更推荐保持 MockData 框架无关。

### 1.6 WKPreferences API 选老的
```swift
// iOS 14 仍用：
prefs.javaScriptEnabled = true

// 不要用 (iOS 14+ 新 API, 但 Xcode 12.5 编译器告警)
WKWebpagePreferences().allowsContentJavaScript = true
```

---

## 2. CSS → SwiftUI 速查表

### 2.1 布局
| CSS | SwiftUI |
|---|---|
| `display: flex; flex-direction: row` | `HStack { }` |
| `display: flex; flex-direction: column` | `VStack { }` |
| `gap: 12px` | `HStack(spacing: 12) { }` |
| `flex: 1` | `Spacer()` 或 `.frame(maxWidth: .infinity)` |
| `flex: 1 1 0; min-height: 0` (3 等分多余空间) | `Spacer()` ×3 |
| `justify-content: space-between` | `HStack { A; Spacer(); B }` |
| `justify-content: center` | `HStack { Spacer(); content; Spacer() }` |
| `align-items: center` | `HStack(alignment: .center)` (默认) |
| `position: absolute; top:Y; left:X` | `.position(x: X, y: Y)` 或 `.offset(x: X, y: Y)` |
| `padding: 12px 16px` | `.padding(.vertical, 12).padding(.horizontal, 16)` |
| `margin-top: 16px` | `.padding(.top, 16)` |
| `width: 100%; height: 200px` | `.frame(maxWidth: .infinity, height: 200)` 或拆两次 |

### 2.2 颜色与边框
| CSS | SwiftUI |
|---|---|
| `var(--accent)` | `Theme.accent` (项目自定 token) |
| `rgba(0, 229, 168, 0.4)` | `Theme.accent.opacity(0.4)` |
| `border: 0.5px solid X` | `.overlay(RoundedRectangle().stroke(X, lineWidth: 1))` ⚠️ |
| `border-radius: 14px` | `.clipShape(RoundedRectangle(cornerRadius: 14))` 或 `RoundedRectangle(cornerRadius: 14).fill(...)` |

⚠️ **边框两个坑（必看）**：

1. **lineWidth 0.5 在 retina 上几乎隐形** — CSS 0.5px 看得见因为屏幕 DPR 不同。
   SwiftUI 至少 **1pt** 才看得清。
2. **opacity 1:1 对齐 HTML 时视觉偏淡** — SwiftUI 1pt 边框 anti-aliasing 比 CSS 0.5px 软 30-50%。
   **经验值：HTML border opacity × 1.6 = SwiftUI 视觉对齐起点**。
   - HTML `rgba(0, 229, 168, 0.25)` → SwiftUI `Theme.accent.opacity(0.42)`
   - HTML `rgba(229, 192, 123, 0.32)` → SwiftUI `Theme.gold.opacity(0.50)`

   背景 tint 同理但程度轻：HTML × 1.5 起步。
   - HTML `rgba(..., 0.04)` → SwiftUI `.opacity(0.07)`

### 2.3 阴影 / 光晕
| CSS | SwiftUI |
|---|---|
| `box-shadow: 0 0 20px rgba(...)` | `.shadow(color: ..., radius: 10)` (radius 半径，约 CSS 模糊半径的一半) |
| `box-shadow: A, B` (双层) | 链式 `.shadow(...).shadow(...)` |
| `text-shadow: 0 0 18px X, 0 0 36px Y` | 同上，给 Text 链 `.shadow(...).shadow(...)` |
| `filter: drop-shadow(...)` | `.shadow(color:radius:)` |
| `box-shadow: inset 0 1.5px 0 rgba(...)` (内顶高光) | 没有原生等价。用 overlay 顶部一条 LinearGradient 模拟 |

### 2.4 渐变
| CSS | SwiftUI |
|---|---|
| `linear-gradient(180deg, A, B)` | `LinearGradient(gradient: Gradient(colors:[A,B]), startPoint: .top, endPoint: .bottom)` |
| `radial-gradient(at 50% 22%, A, B)` | `RadialGradient(gradient:..., center: UnitPoint(x:0.5, y:0.22), startRadius: 0, endRadius: ...)` |
| `conic-gradient(from 0deg, A, B, C)` | `AngularGradient(gradient:..., center: .center, angle: .degrees(0))` |

### 2.5 动画
| CSS | SwiftUI |
|---|---|
| `transition: transform 200ms ease-out` | `.animation(.easeOut(duration: 0.2), value: someState)` |
| `@keyframes spin { ... } animation: spin 7s linear infinite` | `withAnimation(.linear(duration: 7).repeatForever(autoreverses: false)) { angle = 360 }` |
| `:hover { transform: scale(1.015) }` | `.scaleEffect(isPressed ? 1.015 : 1.0)` + `DragGesture` 检测 press |
| `mix-blend-mode: plus-lighter` | `.blendMode(.plusLighter)` (iOS 14+) — 慎用，offscreen pass 重 |

### 2.6 字体
| CSS | SwiftUI |
|---|---|
| `font-family: 'Noto Sans SC'` | `.font(.system(...))` 自动用苹方 PingFang SC |
| `font-family: 'JetBrains Mono'` | `.font(.system(..., design: .monospaced))` 用 SF Mono |
| `font-size: 14px` | `.font(.system(size: 14))` ⚠️ **注意 px ≠ pt 视觉**（见第 3 章） |
| `font-weight: 500` (medium) | `.font(.system(size:..., weight: .medium))` |
| `font-weight: 700` (bold) | `weight: .bold` |
| `font-weight: 900` (black) | `weight: .heavy` 或 `.black` |
| `letter-spacing: 0.16em` | `.kerning(font_size * 0.16)` ⚠️ **kerning 要 pt 不是 em** |
| `line-height: 1.55` | `.lineSpacing(font_size * 0.55)` (lineSpacing = 行间距，不是行高) |

---

## 3. 字体差异：苹方 vs Noto Sans SC

**最坑的一条**：HTML 用 Google Noto Sans SC，SwiftUI 系统字用苹方 PingFang SC。
**同字号下苹方比 Noto Sans SC 字形细约 10-15%**。

### 调整规则
1. **字号直接对齐 px=pt 几乎总是偏小**——SwiftUI 视觉看上去小一档
2. **解决方案：字号 +1~2pt 或 weight +1 档**
   - HTML `font-size: 17px; weight: 500` → SwiftUI 至少 `size: 19, weight: .medium`，更对齐是 `size: 21, weight: .semibold`
3. **谁是真理**：用户的眼睛对比 simulator vs HTML 截图。**不要相信 px 算术对齐**，对齐 px 永远偏小。
4. **特例**：等宽数字 (JetBrains Mono → SF Mono) 视觉差异较小，1:1 对齐即可。

### 实测案例 (Pace)
| 元素 | HTML px | 直接对齐 | 实际生效 |
|---|---|---|---|
| 问候语 上午好,刘宇 | 17px / 500 | 17pt / .medium | **21pt / .semibold** |
| Dial 大数字 82 | SVG 16px (实效 14.5px) | 14-16pt / .semibold | **22pt / .semibold** |
| Dial 标签 状态/负荷 | ~9px / 400 | 9pt / .regular | **12pt / .medium** |
| 今日体感 section header | 9.5px / 400 | 10pt / .regular | **11pt / .medium** |

**经验法则**：HTML px 值乘以 **1.15-1.30** 是 SwiftUI pt 值的好起点。

---

## 4. 视口尺寸适配（212pt 多余高度往哪放）

HTML demo 通常按某个固定预览盒画的（如 308×632 或 393×852）。
真机/模拟器可能更高（iPhone 12 Pro 390×844、Pro Max 430×932）。
**多余的 100-300pt 高度必须放在某处**——这不是 bug，是设计源不响应式。

### 三种放置策略
| 策略 | CSS / SwiftUI 写法 | 视觉结果 |
|---|---|---|
| **底部塞** | 所有内容贴顶 + 底部空白 | 上紧下松，按钮飘在中间 |
| **顶部塞** | `Spacer()` 在 brand 之前 | 标题下移，居中感 |
| **CTA 上方塞** | `Spacer()` 在 CTA 之前 | 顶半屏内容 + 大空白 + CTA 在底 |
| **均匀分布** ⭐ | 多个小 `Spacer()` 各占 `flex: 1` | 各 section 之间均有呼吸感，最自然 |

**Pace 经验**：均匀分布最不显眼。**3 个 Spacer (greeting↔hairline / AI↔card / card↔CTA) 各 `flex: 1`** 比单个大 Spacer 视觉好。

### 但更好的方案：让 demo 设计本身考虑响应式
不要用固定预览盒画 demo。用 `min-height: 100vh` + flex column + 适当的 `flex: 1` 分布。
这样 HTML 在任何屏幕尺寸都自适应，SwiftUI 翻译时也只需要 1:1 对应。

### Safe-area
- HTML: `padding: env(safe-area-inset-top) X env(safe-area-inset-bottom) X`
- SwiftUI: 默认就避开 safe area。要全屏背景用 `.ignoresSafeArea()`，但 content VStack 不要 ignore。

### 4.3 经验值: 「三段呼吸」模式 ⭐ 推荐

经过 IdleHome / PreRun / RunningView 三屏实战验证后总结的**屏级布局首选**：

```swift
VStack(spacing: 0) {
    topAnchor      // 顶部锚点 (brand strip / header)

    Spacer()       // 段 1: top ↔ hero

    heroSection    // 中段主视觉 (大数字 / countdown 圆 / 主卡)

    Spacer()       // 段 2: hero ↔ list

    listSection    // 列表 / checklist / metrics

    Spacer()       // 段 3: list ↔ bottom

    bottomAnchor   // 底部锚点 (hint / CTA / button)
}
```

**3 个无封顶 Spacer**, SwiftUI 自动均分多余高度。212pt 多余 → 每段 ~70pt, 都不算大空洞。

**为什么 work**：
- iPhone SE (667pt): 3 个 Spacer 各 ~10pt, 几乎不可见, 内容紧贴
- iPhone 12 Pro (844pt): 3 个 Spacer 各 ~70pt, 视觉舒展但不空
- iPhone 14 Pro Max (932pt): 各 ~100pt, 仍可接受

**反例（踩过的坑）**：

| 模式 | 问题 |
|---|---|
| 单 Spacer 在底 | 底部一处大空洞 200pt |
| 单 Spacer 在中 | 中部一处大空洞 200pt |
| 多 Spacer + maxHeight 上限 | 限了上限后剩余还是要找地方放, 反而更乱 |
| 用 `.frame(height: X)` 固定 gap | 死板, 真机/模拟器看上去都怪 |

**例外情况**：
- 两屏锚点（如 IdleHome 的 brand+greeting / 出发按钮+timeline）→ 用 4 个 Spacer 对称分布
- 单屏满内容（无富余空间）→ 不需要 Spacer
- hero 必须在视觉中心 → 改用 `Spacer + hero + Spacer + (其他全推到底部)`

### 4.4 ⚠️ 三段呼吸**不是万能解**: 连贯数据流不能切

**犯错频率**: Pace v0.4.0.3 PostRunView 强行套三段呼吸, 用户反馈"通过空挡撑出来不合适"

**反例**: PostRunView 的 map → stats → chart 是同一个数据故事
(路线 → 总结数字 → 趋势分析), 中间塞 Spacer 把它切三块, 视觉断裂

```swift
// ❌ 错: 数据流硬切
VStack {
    Group { brand; ai }
    Spacer()                  // ← 红框 1 出现
    Group { map; stats }
    Spacer()                  // ← 红框 2 出现 (map 跟 stats 跟 chart 应该在一起!)
    chart
    Spacer()
    actions
}

// ✅ 对: 数据流紧凑堆叠 + 单一底部 Spacer
VStack {
    Group {
        brand; smallGap; ai
        smallGap; map; smallGap; stats
        smallGap; chart        // ← 数据故事一气呵成
    }
    Spacer()                  // ← 单一弹性吃 void
    actions
}
```

**判断准则**:
| section 关系 | 用法 |
|---|---|
| **语义独立** (PreRun: countdown ↔ checklist 是两个独立模块) | 三段呼吸 ✓ |
| **连贯数据流** (PostRun: map→stats→chart 同一故事) | 紧凑 + 单一底部 Spacer |
| **页面是表单/列表** | 自然紧凑, 顶部对齐, 不要 Spacer |
| **hero 主导** (IdleHome triad) | hero 居中 + 上下 Spacer 对称 |

**配合策略**: 如果"紧凑 + 单一底部 Spacer"留出大块底部 void → **放大内容** (卡高 / 字号 / 按钮高), 别再加 Spacer.

### 4.5 List/选择型屏幕填满经验值

**犯错频率**: Pace v0.4.1 ShareView 一版 mini 卡 174pt (HTML 真值), 12 Pro 屏底部留 200pt 空洞.

**经验值**: HTML demo 是 308×632 viewport 画的, 真机 12 Pro 390×844 高 1.33×.
**列表卡片元素**需要按比例放大才能填满. **宁可第一版偏大 1.4-1.5×, 别 1.33× 后又反复加大**.
- 主卡片高度 × **1.4-1.5** (HTML 174 → Swift 245-260)
  - v0.4.1 我用 174 → 232 (×1.33), 用户 v0.4.1.2 仍报 void
  - v0.4.1.4 改 232 → 258 (×1.48) 才完全铺满
- 卡片内大数字 × 1.3-1.4 (HTML 28 → Swift 38-40)
- 按钮高度 × 1.3-1.45 (HTML 38 → Swift 50-55)
- 圆角半径同步

**判断 list 型屏没填满**: 直接看 simulator 截图底部是否有大块未利用空间. 有 → 放大. 这是**视觉判断, 不要靠数学算总高度估算**(我每次估算都偏离实际 30+ pt).

**整体增长目标**: 列表卡是页面主体, 应占总屏 60-70% 高度. 单卡占 ~25% 屏高是合理目标 (12 Pro 800pt × 0.25 ≈ 200pt → 实际 232pt).

加入 pre-commit checklist 第 12 条:
12 ✅ list/选择型屏 — 主卡尺寸 HTML × 1.3 起步, 看 simulator 截图直接确认填满, 不要靠 demo 真值原样照抄

---

## 5. 迭代纪律（避免 v0.1.13-17 那种 5 版地狱）

我们这次走过的弯路：
- v0.1.13 → v0.1.17 五版改 padding/字号，用户每版都要发截图
- v0.2.0 → v0.2.0.4 转 WebView，五版改 spacer 分布
- v0.2.3 字号下调（错方向）→ v0.2.4 反向上调

总结成铁律：

### 5.1 不信 px 算术，信用户的眼睛
HTML px 和 SwiftUI pt 视觉不是 1:1。任何"我算出来该是这个值"都先用用户的视觉判断校验。

### 5.2 一次提问 = 一次改动
用户说"X 看着不对"，只改 X 不附带"我顺便也调了 Y"。否则每次都引入新争议。

### 5.3 改动方向先确认再动手
"是该大还是小？是该亮还是暗？"——先把方向问清楚。**反方向调比不调更糟**。

### 5.4 不靠加内容补布局
如果 HTML 在合适尺寸下不需要"填空"也好看，SwiftUI 也应该不需要。
"加 tip 行" / "塞推荐配速" 这种**用产品复杂度抵消视觉问题**的做法是 lazy 解。

### 5.5 架构选了就别频繁切
WebView vs 原生先想清楚再选。**不要走到 v0.2.0 才发现工作流不支持 WebView 红利再 revert**。

### 5.6 提取 HTML 真值前先 grep 源码
改动之前先在 HTML demo 里找到对应 CSS 类的精确属性值（颜色、padding、shadow），不要凭印象。

### 5.7 性能优化不要等真机才考虑
旧 Mac 模拟器卡的效果 (角度梯度 + blendMode + 多层 shadow)，真机虽然不卡但耗电。能优化掉就优化。

---

## 6. 工作流程模板（Phone X 翻译时照做）

```
1. 在 pace-demo/index.html 找到目标屏的 markup 范围 (grep "Phone XX" 或 "<!-- 屏名 -->")
2. 列出该屏依赖的所有 CSS class 名
3. 对每个 class：
   - grep 源码找到 CSS 定义
   - 列出关键属性 (颜色 / 字号 / padding / border / shadow / animation)
4. 按本指南第 2 章速查表逐条翻译
5. 字体应用第 3 章规则 (px 乘 1.15-1.30, weight +1 档)
6. 布局应用第 4 章 (尺寸适配 → 用 Spacer 分布而非内容填充)
7. 编译跑模拟器 → 用户截图对比 HTML demo
8. 用户指出差异 → grep HTML 真值 → 单点修复 → 不附带其他改动
9. 性能：链式 shadow 别超 2 层、blendMode 慎用、动画周期适当放慢
10. commit 信息记录每个改动的 HTML 真值参照（"对照 index.html#L4910"）
```

---

## 附录 A：Pace 项目实测踩坑详单

| 版本 | 触发问题 | 根因 | 修法 |
|---|---|---|---|
| v0.1.4 | "Extra argument in call" 假错 | 多参 `.frame()` 类型推断超时 | 拆成多个 `.frame()` |
| v0.1.5-6 | Spacer 报错 | iOS 14 ViewBuilder 限制 | 用 ZStack 替代多 Spacer |
| v0.1.9 | 顽固 "Extra argument" | ViewBuilder 10 child 上限 | Group 包裹合并 |
| v0.1.12 | "Cannot find in scope" | Xcode 没自动 Add Files | 内联 private struct |
| v0.2.0-0.2.0.4 | WebView 视觉差距 | HTML 设计为 308×632 | revert，原生路线 |
| v0.2.3 | 字号反向（下调） | 信了 px 算术 | v0.2.4 上调并加 weight |
| v0.2.5 | 边框看不见 | 0.5pt 在 retina 上太细 | 改 1pt + hairlineBright |
| v0.2.6 | 老 Mac 模拟器卡 | blendMode + AngularGradient 双重开销 | 7s→12s + 去 blendMode |

## 附录 B：项目硬约束（Pace 当前）

- macOS Big Sur 11.7.10（不升级）→ Xcode 12.5.1（不能更高）→ Swift 5.4 / iOS 14 SDK
- 真机 iOS 17，Xcode 12.5 不支持 → **无法 deploy 到真机**，模拟器是唯一测试环境
- 模拟器主用机型：iPhone 12 Pro（390×844）— Xcode 12.5 模拟器列表的最高型号
- 工作流：Windows 编辑代码 → Git push → Mac pull → Xcode build → 模拟器看
