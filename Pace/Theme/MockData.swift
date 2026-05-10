//
//  MockData.swift
//  Pace.
//
//  v0.1 屏幕展示用的写死数据。
//  v0.5 真实传感器接入后，所有这些字段从 Store 读取。
//

import Foundation

enum MockData {

    enum User {
        static let displayName = "刘宇"
        static let handle = "@liuyu"
    }

    enum Today {
        static let readiness = 82
        static let readinessDelta = 6        // ↑6 vs 昨
        static let strain = 14.2
        static let strainStatus = "7 日 · 偏高"
        static let sleepPercent = 87
        static let sleepHours = "7h 24m"
        static let sleepDelta = 4
        static let aiSuggestion = "恢复良好但负荷偏高，建议做轻松跑而非节奏跑。"
        static let aiHighlight = "负荷偏高"
    }

    enum Weather {
        static let city = "上海"
        static let condition = "晴"
        static let tempC = 18
        static let wind = "微风"
        static let suitability = "适合跑步"
    }

    enum LastRun {
        static let date = "5月3日"
        static let distance = 6.20  // km
        static let pace = "5'34\""
    }

    enum WeekProgress {
        static let kmThisWeek = 12.4
        static let kmGoal = 30.0
        static let runs = 4
        static let avgPace = "5'18\""
        static let deltaPercent = 12  // ↑12% vs 上周

        /// 0.0 - 1.0 进度
        static var ratio: Double {
            min(1.0, kmThisWeek / kmGoal)
        }
    }

    /// 14 天活力点强度，0-1（越大越亮 / 越大尺寸）
    static let timeline: [Double] = [
        0.4, 0.5, 0.6, 0.4, 0.5, 0.7, 0.6,
        0.5, 0.8, 0.6, 0.7, 0.5, 0.6,
    ]
}
