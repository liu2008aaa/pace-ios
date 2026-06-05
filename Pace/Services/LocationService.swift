//
//  LocationService.swift
//  Pace.
//
//  v0.5.0: CLLocationManager 的薄封装. 跟踪期间累计距离, 记录路径.
//
//  关键决策:
//  - 全程 .requestWhenInUseAuthorization (背景跑步需要 Background Modes 后再升级)
//  - 距离累计采用"两点间 GPS 投影" — 抛弃 horizontalAccuracy > 30m 或位移 < 0.5m
//    的脏数据, 减少静止漂移误累计
//  - fixCount 用作"卫星数"的近似 — 不能直接拿到真实卫星数, 但前几个高精度
//    fix 拿到后才认为 GPS ready (≥ 4 表示 ready 出发)
//
//  iOS 14 注意:
//  - locationManagerDidChangeAuthorization(_:) 是 iOS 14+ 替代旧 didChange
//  - 所有 @Published 修改必须回主线程 (CL 默认在 manager 创建线程)
//

import Foundation
import CoreLocation
import Combine

final class LocationService: NSObject, ObservableObject {

    // MARK: - 输出 @Published (供 UI 订阅)

    @Published private(set) var authorization: CLAuthorizationStatus = .notDetermined

    /// 最新一次 fix (已过滤精度差的). nil = 还没拿到首个 fix.
    @Published private(set) var currentLocation: CLLocation?

    /// 累计距离 (米). reset() 清零.
    @Published private(set) var distanceMeters: Double = 0

    /// 最近一次 fix 的精度 (米). -1 = 还没 fix.
    @Published private(set) var horizontalAccuracy: Double = -1

    /// 跟踪是否在跑 (start ↔ stop).
    @Published private(set) var isTracking: Bool = false

    /// 有效 fix 计数. 0..6, 用作 "卫星数 / 6" 的近似. ≥4 即认为 ready.
    @Published private(set) var fixCount: Int = 0

    /// 当前 (滚动) 配速 (秒/公里). 用最近 8 个 fix 估算; 0 表示尚未有效.
    @Published private(set) var rollingPaceSecondsPerKm: Int = 0

    // MARK: - 内部

    static let shared = LocationService()

    private let manager = CLLocationManager()
    private var lastValidLocation: CLLocation?
    private var route: [CLLocation] = []
    private var wantsProbing: Bool = false
    /// 近期 fix 缓冲, 计算 rolling pace 用
    private var recentFixes: [(loc: CLLocation, accumulated: Double)] = []

    // MARK: - 初始化

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
        manager.distanceFilter = 5
        manager.pausesLocationUpdatesAutomatically = false
        authorization = manager.authorizationStatus
    }

    // MARK: - 授权

    /// 请求 When-In-Use. 调用后, 系统通过 delegate 异步推回结果.
    func requestAuthorization() {
        guard authorization == .notDetermined else { return }
        manager.requestWhenInUseAuthorization()
    }

    var isAuthorized: Bool {
        authorization == .authorizedWhenInUse || authorization == .authorizedAlways
    }

    // MARK: - 跟踪

    /// 开始接收 fix. 此时 fixCount 从 0 累计, distanceMeters 不变 (等 startAccumulating)
    /// 二段式: 先获取 fix (PreRun phase), 跑起来后才 startAccumulating.
    func startProbing() {
        wantsProbing = true
        guard isAuthorized else { return }
        fixCount = 0
        horizontalAccuracy = -1
        currentLocation = nil
        manager.startUpdatingLocation()
        isTracking = true
    }

    /// 跑起来 — 重置距离累加器, 开始累计 distance.
    func startAccumulating() {
        distanceMeters = 0
        lastValidLocation = currentLocation
        route.removeAll()
        recentFixes.removeAll()
        if let loc = currentLocation {
            route.append(loc)
        }
    }

    /// 暂停时停 fix (Pause). 重新 resume 时再 startUpdating.
    func pauseTracking() {
        manager.stopUpdatingLocation()
        // lastValidLocation 保留, 重新 resume 时 NOT 累加 pause 间距 (会有跳变)
        lastValidLocation = nil
    }

    func resumeTracking() {
        guard isAuthorized else { return }
        manager.startUpdatingLocation()
    }

    /// 完整结束, 返回完整路径. 调用方负责清零状态.
    func stopAndCollect() -> [CLLocation] {
        wantsProbing = false
        manager.stopUpdatingLocation()
        isTracking = false
        let collected = route
        route.removeAll()
        return collected
    }

    /// 完全 reset (PostRun → IdleHome 后)
    func reset() {
        wantsProbing = false
        manager.stopUpdatingLocation()
        fixCount = 0
        horizontalAccuracy = -1
        currentLocation = nil
        distanceMeters = 0
        rollingPaceSecondsPerKm = 0
        lastValidLocation = nil
        route.removeAll()
        recentFixes.removeAll()
        isTracking = false
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.authorization = manager.authorizationStatus
            if self.wantsProbing, self.isAuthorized, !self.isTracking {
                self.startProbing()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        // 取最新, 过滤掉时间戳过老 (>5s) 的 cached fix
        guard let loc = locations.last else { return }
        let age = Date().timeIntervalSince(loc.timestamp)
        guard age < 5 else { return }
        // 抛弃 horizontalAccuracy <= 0 (无效) 或 > 30m (太差)
        guard loc.horizontalAccuracy > 0, loc.horizontalAccuracy <= 30 else { return }

        DispatchQueue.main.async { [weak self] in
            self?.ingestFix(loc)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 静默吞 — UI 端通过 fixCount/horizontalAccuracy 自然反映
        #if DEBUG
        print("LocationService didFailWithError: \(error.localizedDescription)")
        #endif
    }

    private func ingestFix(_ loc: CLLocation) {
        currentLocation = loc
        horizontalAccuracy = loc.horizontalAccuracy
        fixCount = min(6, fixCount + 1)

        // 距离累加 (仅 startAccumulating 之后, 即 lastValidLocation 非 nil)
        if let last = lastValidLocation {
            let seg = loc.distance(from: last)
            // 跳变保护: 单次位移 > 80m 在跑步场景不合理 (1Hz 下 = 288 km/h)
            if seg > 0.5 && seg < 80 {
                distanceMeters += seg
                route.append(loc)
                updateRollingPace(loc: loc, accumulated: distanceMeters)
            }
        }
        lastValidLocation = loc
    }

    /// 滚动配速 = 最近 80m 用了多少秒. 没有 80m 时取最近所有缓冲.
    private func updateRollingPace(loc: CLLocation, accumulated: Double) {
        recentFixes.append((loc, accumulated))
        // 仅保留最近 16 个或 ≥ 80m 跨度
        while recentFixes.count > 16 {
            recentFixes.removeFirst()
        }
        guard let first = recentFixes.first, recentFixes.count >= 4 else { return }
        let dist = accumulated - first.accumulated
        guard dist >= 30 else { return }   // 数据太少
        let dt = loc.timestamp.timeIntervalSince(first.loc.timestamp)
        guard dt > 0 else { return }
        // 秒/公里 = (dt / dist) * 1000
        rollingPaceSecondsPerKm = Int((dt / dist) * 1000)
    }
}
