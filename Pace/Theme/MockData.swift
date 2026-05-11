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

    /// Phone 02 跑前预热数据
    enum PreRun {
        /// v0.3.3: 3s 太快 (用户截图都来不及), 改 6s 让仪式感够
        static let countdownStart: Int = 6
        static let gpsSatellites: Int = 12
        static let restingHR: Int = 76
        static let musicSource = "网易云 · 礼让模式"
        static let voiceSetting = "每 1 km · 中文女声"
    }

    /// Phone 04 结束总结数据
    /// MockData 严格只用 Foundation 类型 (Double / Int / String / 元组),
    /// 不导入 CoreGraphics / UIKit / SwiftUI。视觉常量 (路径坐标 / chart 几何)
    /// 放在使用它们的 View 文件里 (PostRunView 等), 不进 MockData。
    enum PostRun {
        static let date = "5月7日"
        static let timeOfDay = "夜跑"

        // AI insight 文案 (3 段拼接, 中段是 highlight)
        static let aiBefore = "今晚状态稳定。最后 1 公里 "
        static let aiHighlight = "5'02\""
        static let aiAfter = " —— 30 天内最强尾段。"
        static let aiCounter = "AI · 1 / 3"

        // 主统计 (3 列卡)
        static let distanceKm: Double = 5.42
        static let durationStr = "28:14"
        static let avgPace = "5'12\""

        // 路线图 GPS 坐标
        static let coords = "31.2°N · 121.4°E"

        // 末公里相对全程平均的提升说明
        static let lastKmDelta = "↓ 末公里 -22s"
    }

    /// Phone 06 周历史数据
    enum WeekHistory {
        // 本周 hero
        static let weekDistanceKm: Double = 38.4
        static let weekTrendStr = "↑12%"
        static let weekRuns: Int = 4
        static let weekTimeStr = "3:21'42\""
        static let weekAvgPace = "5'18\""

        // 本周恢复 (7 天: 周五~周四, 周四是 today)
        enum RecoveryState { case good, ok, bad }
        static let recoveryAvg: Int = 74
        static let recoveryDays: [(label: String, value: Int, state: RecoveryState, today: Bool)] = [
            ("五", 76, .good, false),
            ("六", 80, .good, false),
            ("日", 72, .good, false),
            ("一", 56, .ok,   false),
            ("二", 74, .good, false),
            ("三", 79, .good, false),
            ("四", 82, .good, true),
        ]

        // 活动 84 天 dotmap (12 行 × 7 列, 0-1 intensity)
        // 静态 mock — 真实版会从 HKWorkoutSession 历史读
        static let dotmapDays: [Double] = {
            // 简化的 84 个 intensity (越近越亮的趋势, 部分零值)
            var arr: [Double] = []
            let pattern: [Double] = [
                // row 0 (最早)
                0.18, 0.35, 0.0, 0.55, 0.0, 0.0, 0.40,
                0.0, 0.42, 0.55, 0.0, 0.0, 0.35, 0.50,
                0.50, 0.0, 0.42, 0.60, 0.0, 0.0, 0.55,
                0.0, 0.45, 0.0, 0.60, 0.40, 0.0, 0.55,
                0.55, 0.0, 0.50, 0.0, 0.65, 0.0, 0.45,
                0.60, 0.50, 0.0, 0.55, 0.65, 0.0, 0.42,
                0.0, 0.60, 0.55, 0.65, 0.0, 0.55, 0.60,
                0.55, 0.0, 0.65, 0.55, 0.0, 0.55, 0.70,
                0.60, 0.65, 0.55, 0.0, 0.65, 0.55, 0.70,
                0.0, 0.65, 0.70, 0.0, 0.75, 0.60, 0.65,
                0.70, 0.55, 0.0, 0.80, 0.70, 0.65, 0.85,
                // row 11 (最近一周, 末位为今日)
                0.85, 0.65, 0.75, 0.55, 0.60, 0.0, 1.0,
            ]
            arr = pattern
            return arr
        }()

        // 每周公里 4 周柱图 (label, km, isCurrent)
        static let weekBars: [(label: String, km: Double, current: Bool)] = [
            ("W14", 26.1, false),
            ("W15", 31.0, false),
            ("W16", 34.2, false),
            ("W17", 38.4, true),
        ]

        static let streakDays: Int = 12
    }

    /// Phone 05 分享卡数据
    enum Share {
        // 画布元数据
        static let canvasRatio = "9 : 16"
        static let canvasSize = "1080×1920"

        // 4 种样式选项
        enum Style: Int, CaseIterable {
            case classic = 0
            case minimal = 1
            case poster = 2
            case data = 3

            var cn: String {
                switch self {
                case .classic: return "经典"
                case .minimal: return "极简"
                case .poster: return "海报"
                case .data: return "数据"
                }
            }
            var en: String {
                switch self {
                case .classic: return "CLASSIC"
                case .minimal: return "MINIMAL"
                case .poster: return "POSTER"
                case .data: return "DATA"
                }
            }
        }

        // 经典样式的 4 列数据
        static let classicStats: [String] = ["28:14", "5'12", "152", "420"]
        // 数据样式的 5 km splits (km, pace)
        static let dataSplits: [(Int, String)] = [
            (1, "5'34\""),
            (2, "5'18\""),
            (3, "5'12\""),
            (4, "5'08\""),
            (5, "5'02\""),
        ]
        static let dataFooter = ("HR Z3·42%", "152 AVG")

        // 海报副标
        static let posterTitle = "5.42 KM"
        static let posterSub = "28:14 · NIGHT RUN"

        // 金句 / 高亮
        static let classicQuote = "✦ 30 天最强尾段"
    }

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
