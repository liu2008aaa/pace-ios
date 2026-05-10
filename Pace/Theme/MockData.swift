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
        static let aiSuggestion = "恢复良好但负荷偏高，建议轻松跑。"
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

    /// 本周节奏 (Weekly Rhythm) — 7 天小柱图数据
    enum WeekRhythm {
        /// 一二三四五六日 7 天的公里数。最后一项 = 今天。
        static let dayKm: [Double] = [5.0, 6.2, 0, 4.0, 5.0, 0, 6.0]
        static let dayLabels: [String] = ["一", "二", "三", "四", "五", "六", "日"]
        static let todayIndex: Int = 6
        static let totalKm: String = "26.0"
        static let runs: Int = 5
        static let avgPace: String = "5'18\""
        static let streakDays: Int = 12
    }

    /// 14 天活力点强度，0-1（越大越亮 / 越大尺寸）
    static let timeline: [Double] = [
        0.4, 0.5, 0.6, 0.4, 0.5, 0.7, 0.6,
        0.5, 0.8, 0.6, 0.7, 0.5, 0.6,
    ]

    /// Phone 03 跑步进行中数据
    /// v0.3 静态 mock；v0.5 真实 GPS / HKWorkoutSession 后会变成 Store 驱动的实时值
    enum Running {
        static let activityType = "户外跑"
        static let gpsStatus = "GPS 锁定"
        static let temperature = "11°C"

        // 实时配速 (huge hero number)
        static let pace = "5'24\""

        // 距离 / 时长
        static let distanceKm = 3.42
        static let durationStr = "18:32"
        static let splitNumber = 4

        // 心率
        static let heartRate = 152
        static let hrZonePercent: Double = 0.52   // 0..1 marker 在 5 段 bar 上的位置
        static let hrZoneLabel = "Z3 · TEMPO"
    }
}
