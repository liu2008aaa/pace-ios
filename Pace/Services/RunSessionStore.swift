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
    @Published private(set) var hasStoredRecords: Bool = false
    @Published private(set) var hasLoadedRecords: Bool = false

    private let storageKey = "pace.runs.v1"
    private let hasStoredRecordsKey = "pace.runs.hasStoredRecords.v1"

    private init() {
        let defaults = UserDefaults.standard
        hasStoredRecords = defaults.bool(forKey: hasStoredRecordsKey)
        loadAsync()
    }

    // MARK: - 持久化

    func save(_ record: RunRecord) {
        records.insert(record, at: 0)   // 新的在最前 (历史按时间倒序)
        hasStoredRecords = true
        persist()
    }

    /// 删除某条 (本期未在 UI 触发, 但 v0.5+ Settings 会用)
    func delete(id: UUID) {
        records.removeAll { $0.id == id }
        hasStoredRecords = !records.isEmpty
        persist()
    }

    private func loadAsync() {
        let storageKey = self.storageKey
        let hasStoredRecordsKey = self.hasStoredRecordsKey
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let data = UserDefaults.standard.data(forKey: storageKey)
            let decoded = data.flatMap { try? JSONDecoder().decode([RunRecord].self, from: $0) } ?? []

            DispatchQueue.main.async {
                guard let self = self else { return }
                self.records = decoded
                self.hasStoredRecords = !decoded.isEmpty
                self.hasLoadedRecords = true
                UserDefaults.standard.set(self.hasStoredRecords, forKey: hasStoredRecordsKey)
            }
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        UserDefaults.standard.set(!records.isEmpty, forKey: hasStoredRecordsKey)
    }

    /// 测试用 — 清空所有
    func clearAll() {
        records.removeAll()
        hasStoredRecords = false
        hasLoadedRecords = true
        UserDefaults.standard.removeObject(forKey: storageKey)
        UserDefaults.standard.set(false, forKey: hasStoredRecordsKey)
    }

    // MARK: - 派生聚合 (供 WeekHistoryView 等读)

    /// 本周已跑公里 (按周一为周首)
    var thisWeekDistanceKm: Double {
        recordsThisWeek.reduce(0) { $0 + $1.distanceKm }
    }

    /// 本周跑步次数
    var thisWeekRuns: Int {
        recordsThisWeek.count
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

    var recordsThisWeek: [RunRecord] {
        let start = startOfWeek(Date())
        return records.filter { $0.startDate >= start }
    }

    var thisWeekAveragePaceDisplay: String {
        averagePaceDisplay(for: recordsThisWeek)
    }

    var thisWeekDurationDisplay: String {
        durationDisplay(seconds: recordsThisWeek.reduce(0) { $0 + $1.elapsedSeconds })
    }

    var thisWeekDeltaDisplay: String {
        distanceDeltaDisplay(current: thisWeekDistanceKm,
                             previous: previousWeekDistanceKm)
    }

    var thisYearRunDays: Int {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year], from: Date())
        guard let yearStart = cal.date(from: comps) else { return 0 }
        let days = Set(records
            .filter { $0.startDate >= yearStart }
            .map { cal.startOfDay(for: $0.startDate) })
        return days.count
    }

    var thisYearAveragePaceDisplay: String {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year], from: Date())
        guard let yearStart = cal.date(from: comps) else { return "--'--\"" }
        return averagePaceDisplay(for: records.filter { $0.startDate >= yearStart })
    }

    var thisMonthDeltaDisplay: String {
        distanceDeltaDisplay(current: thisMonthDistanceKm,
                             previous: previousMonthDistanceKm)
    }

    var thisYearDeltaDisplay: String {
        distanceDeltaDisplay(current: thisYearDistanceKm,
                             previous: previousYearDistanceKm)
    }

    func dailyDistancesThisWeek() -> [Double] {
        let cal = Calendar(identifier: .gregorian)
        let start = startOfWeek(Date())
        var result = Array(repeating: 0.0, count: 7)
        for record in records where record.startDate >= start {
            let days = cal.dateComponents([.day], from: start, to: record.startDate).day ?? 0
            if days >= 0 && days < 7 {
                result[days] += record.distanceKm
            }
        }
        return result
    }

    func recentDayIntensities(days: Int) -> [Double] {
        guard days > 0 else { return [] }
        let cal = Calendar(identifier: .gregorian)
        let today = cal.startOfDay(for: Date())
        var values = Array(repeating: 0.0, count: days)
        for record in records {
            let recordDay = cal.startOfDay(for: record.startDate)
            let offset = cal.dateComponents([.day], from: recordDay, to: today).day ?? days
            if offset >= 0 && offset < days {
                values[days - 1 - offset] += record.distanceKm
            }
        }
        let maxKm = max(values.max() ?? 0, 1)
        return values.map { km in
            guard km > 0 else { return 0 }
            return max(0.22, min(1.0, km / maxKm))
        }
    }

    func currentStreakDays() -> Int {
        let cal = Calendar(identifier: .gregorian)
        let runDays = Set(records.map { cal.startOfDay(for: $0.startDate) })
        guard var cursor = runDays.max() else { return 0 }
        var streak = 0

        while runDays.contains(cursor) {
            streak += 1
            guard let previous = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }

        return streak
    }

    func lastFourWeekBars() -> [(label: String, km: Double, current: Bool)] {
        let cal = Calendar(identifier: .gregorian)
        let thisWeek = startOfWeek(Date())
        return (0..<4).reversed().map { offset in
            let start = cal.date(byAdding: .weekOfYear, value: -offset, to: thisWeek) ?? thisWeek
            let end = cal.date(byAdding: .weekOfYear, value: 1, to: start) ?? Date()
            let km = records
                .filter { $0.startDate >= start && $0.startDate < end }
                .reduce(0) { $0 + $1.distanceKm }
            return (label: weekLabel(for: start), km: km, current: offset == 0)
        }
    }

    func daysInCurrentMonth() -> Int {
        let cal = Calendar(identifier: .gregorian)
        return cal.range(of: .day, in: .month, for: Date())?.count ?? 30
    }

    func currentMonthStartColumnMondayFirst() -> Int {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year, .month], from: Date())
        guard let start = cal.date(from: comps) else { return 0 }
        let weekday = cal.component(.weekday, from: start)
        return (weekday + 5) % 7
    }

    func currentMonthToday() -> Int {
        Calendar(identifier: .gregorian).component(.day, from: Date())
    }

    func dailyIntensityThisMonth() -> [Int: Double] {
        let distances = dailyDistancesThisMonth()
        let maxKm = max(distances.values.max() ?? 0, 1)
        var result: [Int: Double] = [:]
        for (day, km) in distances where km > 0 {
            result[day] = max(0.22, min(1.0, km / maxKm))
        }
        return result
    }

    func currentMonthTitleCN() -> String {
        let cal = Calendar(identifier: .gregorian)
        let year = cal.component(.year, from: Date())
        let month = cal.component(.month, from: Date())
        return "\(year) · \(month)月"
    }

    func currentMonthTitleEN() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMM · yyyy"
        return f.string(from: Date()).uppercased()
    }

    func currentYearTitleCN() -> String {
        "\(Calendar(identifier: .gregorian).component(.year, from: Date()))"
    }

    func currentYearTitleEN() -> String {
        "YEAR · \(Calendar(identifier: .gregorian).component(.year, from: Date()))"
    }

    func bestPaceDisplay(minDistanceKm: Double) -> String {
        let candidates = records.filter { $0.distanceKm >= minDistanceKm && $0.avgPaceSecondsPerKm > 0 }
        guard let best = candidates.min(by: { $0.avgPaceSecondsPerKm < $1.avgPaceSecondsPerKm }) else {
            return "--"
        }
        return best.paceDisplay
    }

    func averagePaceDisplay(for selected: [RunRecord]) -> String {
        let distance = selected.reduce(0) { $0 + $1.distanceMeters }
        let seconds = selected.reduce(0) { $0 + $1.elapsedSeconds }
        guard distance > 10, seconds > 0 else { return "--'--\"" }
        let pace = Int((Double(seconds) / distance) * 1000)
        let m = pace / 60
        let s = pace % 60
        return "\(m)'\(String(format: "%02d", s))\""
    }

    // MARK: - Helpers

    private func startOfWeek(_ date: Date) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2   // 周一为首
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: comps) ?? date
    }

    private func weekLabel(for date: Date) -> String {
        let cal = Calendar(identifier: .gregorian)
        let week = cal.component(.weekOfYear, from: date)
        return "W\(week)"
    }

    private var previousWeekDistanceKm: Double {
        let cal = Calendar(identifier: .gregorian)
        let thisWeek = startOfWeek(Date())
        guard let previousStart = cal.date(byAdding: .weekOfYear, value: -1, to: thisWeek) else { return 0 }
        return distance(from: previousStart, to: thisWeek)
    }

    private var previousMonthDistanceKm: Double {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year, .month], from: Date())
        guard let thisMonth = cal.date(from: comps),
              let previousMonth = cal.date(byAdding: .month, value: -1, to: thisMonth) else { return 0 }
        return distance(from: previousMonth, to: thisMonth)
    }

    private var previousYearDistanceKm: Double {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year], from: Date())
        guard let thisYear = cal.date(from: comps),
              let previousYear = cal.date(byAdding: .year, value: -1, to: thisYear) else { return 0 }
        return distance(from: previousYear, to: thisYear)
    }

    private func distance(from start: Date, to end: Date) -> Double {
        records
            .filter { $0.startDate >= start && $0.startDate < end }
            .reduce(0) { $0 + $1.distanceKm }
    }

    private func distanceDeltaDisplay(current: Double, previous: Double) -> String {
        guard previous > 0 else {
            return current > 0 ? "NEW" : "—"
        }
        let pct = Int(round(((current - previous) / previous) * 100))
        if pct > 0 { return "↑\(pct)%" }
        if pct < 0 { return "↓\(abs(pct))%" }
        return "0%"
    }

    private func durationDisplay(seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        if h > 0 {
            return "\(h)h \(m)m"
        }
        return "\(m)m"
    }
}
