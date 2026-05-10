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

### 1.1 ViewBuilder 10-child 限制
```swift
// ❌ 报"Extra argument in call" 假错
VStack {
    A; B; C; D; E; F; G; H; I; J; K  // 11 个直接子 → 炸
}

// ✅ 用 Group { } 合并
VStack {
    Group {
        A; B; C; D; E; F; G  // 这 7 个算 1 个
    }
    H; I; J; K  // 加上这 4 个 = 5 ≤ 10
}
```

### 1.2 严格 CGFloat / Double 类型
```swift
// ❌
let height = 4.0 + intensity * 4.0   // intensity: Double → height: Double
.frame(height: height)               // 类型不匹配 (期望 CGFloat)

// ✅
.frame(height: CGFloat(4.0 + intensity * 4.0))
```

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
| `border: 0.5px solid X` | `.overlay(RoundedRectangle().stroke(X, lineWidth: 0.5))` |
| `border-radius: 14px` | `.clipShape(RoundedRectangle(cornerRadius: 14))` 或 `RoundedRectangle(cornerRadius: 14).fill(...)` |

⚠️ **0.5pt border 在 iPhone retina 上几乎隐形**——CSS 0.5px 看得见因为屏幕 DPR 渲染策略不同。
SwiftUI 里 border 至少 **1pt** 才看得清。

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
