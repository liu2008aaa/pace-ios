//
//  Typography.swift
//  Pace.
//
//  字体系统。
//
//  v0.1 用 iOS 系统字 fallback：
//  - 数据数字 → SF Mono（iOS 内置等宽字，效果接近 JetBrains Mono）
//  - 中文 → 苹方（PingFang SC，iOS 内置中文字，等价 Noto Sans SC）
//  - 拉丁正文 → SF Pro Text（系统默认，等价 Inter）
//
//  v0.2 计划接入真实字体文件：
//  - JetBrains-Mono-Regular.ttf / Bold.ttf
//  - 加 Info.plist 的 UIAppFonts 数组
//  - 用 Font.custom("JetBrainsMono-Regular", size: ...)
//

import SwiftUI

enum PaceFont {
    /// 数据 / 数字 / 技术标签 → 等宽
    static func mono(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        // SF Mono 是 iOS 内置等宽字，特征值 'monospaced' 强制激活
        .system(size: size, weight: weight, design: .monospaced)
    }

    /// 中文正文（iOS 自动用苹方 PingFang SC）
    static func cn(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// 拉丁正文（SF Pro）
    static func sans(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// 品牌大字（"Pace." / 巨型数字标题）
    static func display(size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .default)
    }
}
