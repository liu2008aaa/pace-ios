# WebContent · 嵌入 WKWebView 的静态 HTML 资源

## 背景

Pace 采用混合架构：

| 屏幕 | 实现 |
|---|---|
| Phone 01 待机首页 | **WKWebView 嵌 `idle-home.html`** |
| Phone 02 跑步进行中 | 原生 SwiftUI（HKWorkoutSession + GPS） |
| Phone 04 PostRun 总结 | WKWebView (待加) |
| Phone 05 分享卡 | WKWebView (待加) |

理由：HTML demo 早就所见即所得，纯展示屏（无传感器/后台/触觉）走 WebView 像素级一致零移植；只在真正需要原生能力的屏才付出 SwiftUI 的迭代税。

## 一次性 Xcode 配置

**仅在第一次拉取 v0.2.0 后做一次**。后续 `git pull` 自动生效，不用再操作。

1. 在 Xcode 项目导航器中，右键 `Pace` 文件夹 → **Add Files to "Pace"…**
2. 浏览到 `Pace/WebContent/` 文件夹（不是单个 .html，是整个 WebContent 文件夹）
3. **取消勾选** `Copy items if needed`（文件已经在仓库里，不要复制）
4. **选择** `Create folder references`（蓝色文件夹图标，保留路径结构）—— 不要选 `Create groups`（黄色），group 会丢路径
5. **勾选** Targets 里的 `Pace`
6. 点 **Add**

完成后导航器里 `WebContent` 应该是**蓝色文件夹**。

## 验证

Build & run。如果首页显示 HTML 内容 → ✅。如果显示橙色 "WebShell · 资源未找到" 错误页 → 重新做上面 6 步。

## 修改 HTML 内容

直接在编辑器/IDE 里改 `idle-home.html`，build & run 自动生效（资源会被打包进 bundle）。无须重新 Add Files。

## 添加新的 HTML 屏

1. 把新 .html 放进本文件夹（如 `post-run.html`）
2. 因为 WebContent 是蓝色文件夹引用，新增的文件**自动**出现在 bundle 里——无需再次 Add Files
3. Swift 侧用 `WebShell(file: "post-run", ext: "html")` 加载
