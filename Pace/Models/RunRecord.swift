//
//  RunRecord.swift
//  Pace.
//
//  v0.5.0: 一条完整的跑步记录. 由 RunSessionEngine 在 .end() 时生成,
//          RunSessionStore 持久化到 UserDefaults.
//
//  Codable + Identifiable, 便于 JSON 编码 + SwiftUI List 用 id 区分行.
//

import Foundation
import CoreLocation

struct RunRecord: Codable, Identifiable {
    let id: UUID
    let startDate: Date
    let endDate: Date

    /// 总距离 (米). 由 LocationService 累计.
    let distanceMeters: Double

    /// 实际跑步时长 (秒, 不含暂停).
    let elapsedSeconds: Int

    /// 平均配速 (秒 / 公里). 0 表示无效 (距离 < 0.01 km).
    let avgPaceSecondsPerKm: Int

    /// 平均心率 (BPM). nil = 没拿到 (sim 无设备 / 用户拒绝授权).
    let avgHR: Int?

    /// 路径点 (lat/lng/alt/timestamp 序列化). 压缩存储, 解码时重建 CLLocation.
    let routePoints: [RoutePoint]

    // MARK: - 派生

    var distanceKm: Double { distanceMeters / 1000.0 }

    /// 6'12" 格式
    var paceDisplay: String {
        guard avgPaceSecondsPerKm > 0 else { return "--'--\"" }
        let m = avgPaceSecondsPerKm / 60
        let s = avgPaceSecondsPerKm % 60
        return "\(m)'\(String(format: "%02d", s))\""
    }

    /// 25:43 或 1:25:43 (有时)
    var durationDisplay: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        if h > 0 {
            return "\(h):\(String(format: "%02d", m)):\(String(format: "%02d", s))"
        }
        return "\(m):\(String(format: "%02d", s))"
    }
}

/// 一个 GPS 采样点. 不直接存 CLLocation (它不是 Codable).
struct RoutePoint: Codable {
    let lat: Double
    let lng: Double
    let alt: Double
    let timestamp: TimeInterval   // since 1970

    init(_ location: CLLocation) {
        self.lat = location.coordinate.latitude
        self.lng = location.coordinate.longitude
        self.alt = location.altitude
        self.timestamp = location.timestamp.timeIntervalSince1970
    }
}
