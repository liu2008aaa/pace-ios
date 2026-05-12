//
//  RunSessionStore.swift
//  Pace.
//
//  v0.5.0: RunRecord 数组的 UserDefaults 持久化 + 派生聚合.
//
//  目前实现选择 UserDefaults 而非 CoreData/SQLite, 因为 v0.5 还在"几条记录"的
//  规模 (<100 条). UserDefaults JSON 数组够用. 真用户量大后再迁 CoreData.
//

import Foundation
import CoreLocation

final class RunSessionStore: ObservableObject {

    static let shared = RunSessionStore()

    @Published private(set) var records: [RunRecord] = []

    private let storageKey = "pace.runs.v1"

    private init() {
        load()
    }

    // MARK: - 持久化

    func save(_ record: RunRecord) {
        records.insert(record, at: 0)   // 新的在最前 (历史按时间倒序)
        persist()
    }

    /// 删除某条 (本期未在 UI 触发, 但 v0.5+ Settings 会用)
    func delete(id: UUID) {
        records.removeAll { $0.id == id }
        persist()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        if let decoded = try? JSONDecoder().decode([RunRecord].self, from: data) {
            records = decoded
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    /// 测试用 — 清空所有
    func clearAll() {
        records.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    // MARK: - 派生聚合 (供 WeekHistoryView 等读)

    /// 本周已跑公里 (按周一为周首)
    var thisWeekDistanceKm: Double {
        let start = startOfWeek(Date())
        return records
            .filter { $0.startDate >= start }
            .reduce(0) { $0 + $1.distanceKm }
    }

    /// 本周跑步次数
    var thisWeekRuns: Int {
        let start = startOfWeek(Date())
        return records.filter { $0.startDate >= start }.count
    }

    /// 本月已跑公里
    var thisMonthDistanceKm: Double {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year, .month], from: Date())
        guard let start = cal.date(from: comps) else { return 0 }
        return records
            .filter { $0.startDate >= start }
            .reduce(0) { $0 + $1.distanceKm }
    }

    /// 本年已跑公里
    var thisYearDistanceKm: Double {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year], from: Date())
        guard let start = cal.date(from: comps) else { return 0 }
        return records
            .filter { $0.startDate >= start }
            .reduce(0) { $0 + $1.distanceKm }
    }

    /// 本月每天的距离 (1..31 月内, 没跑的 = 0)
    func dailyDistancesThisMonth() -> [Int: Double] {
        let cal = Calendar(identifier: .gregorian)
        let now = Date()
        let comps = cal.dateComponents([.year, .month], from: now)
        guard let monthStart = cal.date(from: comps) else { return [:] }
        var result: [Int: Double] = [:]
        for r in records where r.startDate >= monthStart {
            let day = cal.component(.day, from: r.startDate)
            result[day, default: 0] += r.distanceKm
        }
        return result
    }

    /// 本年每月的距离 (1..12)
    func monthlyDistancesThisYear() -> [Double] {
        let cal = Calendar(identifier: .gregorian)
        let now = Date()
        let comps = cal.dateComponents([.year], from: now)
        guard let yearStart = cal.date(from: comps) else { return Array(repeating: 0, count: 12) }
        var result: [Double] = Array(repeating: 0, count: 12)
        for r in records where r.startDate >= yearStart {
            let m = cal.component(.month, from: r.startDate) - 1   // 0-indexed
            if m >= 0 && m < 12 {
                result[m] += r.distanceKm
            }
        }
        return result
    }

    // MARK: - Helpers

    private func startOfWeek(_ date: Date) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2   // 周一为首
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: comps) ?? date
    }
}
