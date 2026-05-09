//
//  Colors.swift
//  Pace.
//
//  色板 token —— 严格对照 HTML demo (`pace-demo/index.html`) 的 :root CSS 变量。
//  策略：单一冷绿主色 + 严格的状态色语义（gold = 中间态、warn = 警示、heart = 心形专属）。
//

import SwiftUI

extension Color {
    /// 十六进制初始化。例：`Color(hex: 0x00E5A8)`
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xff) / 255
        let g = Double((hex >> 8) & 0xff) / 255
        let b = Double(hex & 0xff) / 255
        self.init(red: r, green: g, blue: b, opacity: opacity)
    }
}

/// 全局色板。所有屏直接 `Theme.bgApp` 这样访问。
enum Theme {
    // MARK: - 背景层 (5 阶)
    static let bgCanvas       = Color(hex: 0x04050a)
    static let bgApp          = Color(hex: 0x000000)   // 主背景：纯黑
    static let bgCard         = Color(hex: 0x0B0C0F)
    static let bgElev         = Color(hex: 0x14161B)
    static let bgElev2        = Color(hex: 0x1B1E24)

    // MARK: - 主色（单点）
    static let accent         = Color(hex: 0x00E5A8)   // 冷绿主色
    static let accentBright   = Color(hex: 0x29F0BD)
    static let accentDeep     = Color(hex: 0x003B2C)
    static let accentDeeper   = Color(hex: 0x06281E)

    // MARK: - 状态色（语义专用）
    static let warn           = Color(hex: 0xFF6B3D)   // 警示橙 / 结束
    static let gold           = Color(hex: 0xE5C07B)   // 中间态金 / 负荷偏高
    static let live           = Color(hex: 0xFF3B30)   // 录制红
    static let heart          = Color(hex: 0xFF3B5C)   // 心形专属粉红

    // MARK: - 文字（4 阶）
    static let text1          = Color.white
    static let text2          = Color(hex: 0x9CA0AB)
    static let text3          = Color(hex: 0x5A5E68)
    static let text4          = Color(hex: 0x3A3D44)

    // MARK: - 描边
    static let hairline       = Color(hex: 0x1F2126)
    static let hairlineBright = Color(hex: 0x2A2D33)

    // MARK: - 心率区间（5 段）
    static let zone1 = Color.white.opacity(0.10)
    static let zone2 = Color(hex: 0x00E5A8).opacity(0.22)
    static let zone3 = Color(hex: 0x00E5A8).opacity(0.55)
    static let zone4 = Color(hex: 0xFFC864).opacity(0.55)
    static let zone5 = Color(hex: 0xFF6B3D).opacity(0.7)

    // MARK: - 配速色谱（5 段，slow → fast）
    static let pace1 = Color(hex: 0x006B4E)
    static let pace2 = Color(hex: 0x00875F)
    static let pace3 = Color(hex: 0x00B488)
    static let pace4 = Color(hex: 0x00D49A)
    static let pace5 = Color(hex: 0x29F0BD)
}
