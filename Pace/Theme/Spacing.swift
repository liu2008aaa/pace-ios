//
//  Spacing.swift
//  Pace.
//
//  间距 token。基础单位 4px，4 的倍数堆叠。
//

import SwiftUI

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

enum Radius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 10
    static let lg: CGFloat = 12
    static let xl: CGFloat = 14
    static let pill: CGFloat = 999
}

enum AppAnimation {
    /// 设计系统主缓动：cubic-bezier(.2, .8, .2, 1)，类 iOS 默认
    static let easeOut: Animation = .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.2)
    static let easeOutSlow: Animation = .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.5)

    // 周期性
    static let glowBreathe: Animation = .easeInOut(duration: 2.1).repeatForever(autoreverses: true)
    static let pulseLive: Animation = .easeInOut(duration: 0.75).repeatForever(autoreverses: true)
    static let pulseSoft: Animation = .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
}
