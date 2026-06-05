//
//  RunSessionEngine.swift
//  Pace.
//
//  v0.5.0: 跑步会话的状态机 + 数据聚合. 编排 LocationService / HealthService /
//          Timer + 在 .end 时落盘到 RunSessionStore.
//
//  状态机
//    .idle
//      ↓ user 点出发 (IdleHome / FirstRunHomeView)
//    .preflight   ← 请求权限 + 启动 GPS 探测 (探到 fix 即 ready)
//      ↓ GPS ≥ 4 fix
//    .ready
//      ↓ engine.startCountdown()
//    .countdown   ← 3..2..1 (1 Hz)
//      ↓ countdown 归零
//    .running     ← Timer 1 Hz tick; elapsed / distance / pace 实时更新
//      ↘ pause()              ↘ end()
//    .paused                    .ended
//      ↘ resume() / end()       ↘ acknowledge() → .idle (PostRun dismiss 后)
//
//  Swift 5.4 / iOS 14 注意:
//  - 不能用 @MainActor (Swift 5.5+)
//  - Timer.scheduledTimer 在 main RunLoop, 已经在主线程, @Published 安全
//

import Foundation
import Combine
import CoreLocation
import HealthKit

final class RunSessionEngine: ObservableObject {

    // MARK: - 阶段

    enum Phase {
        case idle           // 待机
        case preflight      // 请求权限 + GPS 探测中
        case ready          // GPS OK, 等用户点出发
        case countdown      // 3..2..1
        case running        // 跑步中
        case paused         // 暂停
        case ended          // 结束总结 (PostRunView)
    }

    @Published private(set) var phase: Phase = .idle

    /// countdown 剩余秒. 倒数到 0 自动切 .running.
    @Published private(set) var countdown: Int = 0

    /// 跑步累计秒 (不含暂停). 显示 25:43 之类.
    @Published private(set) var elapsedSeconds: Int = 0

    /// 跑步累计公里数 (实时, 由 LocationService 推).
    @Published private(set) var distanceKm: Double = 0

    /// 当前滚动配速 (秒/公里). 由 LocationService 推, 引擎转发.
    @Published private(set) var rollingPaceSecondsPerKm: Int = 0

    /// 当前心率 (BPM), 由 HealthService 推. nil = 无数据.
    @Published private(set) var currentHR: Int? = nil

    /// GPS fix 计数 (0..6). LocationService 转发 — UI 直接订阅 engine 即可,
    /// 不用再 @ObservedObject 接 LocationService.
    @Published private(set) var gpsFixCount: Int = 0

    /// CL 授权状态 (转发, 用于检测拒绝)
    @Published private(set) var locationAuthorized: Bool = false
    @Published private(set) var locationDenied: Bool = false

    /// .end 时生成, .acknowledge 后清空. PostRunView 显示这条.
    @Published private(set) var lastRecord: RunRecord? = nil

    // MARK: - 依赖

    let location: LocationService
    let health: HealthService
    let store: RunSessionStore

    private var locationCancellables = Set<AnyCancellable>()
    private var healthCancellables = Set<AnyCancellable>()

    private var tickTimer: Timer?
    private var countdownTimer: Timer?
    private var preflightTimer: Timer?
    private var startDate: Date?
    private var pausedAccumulated: TimeInterval = 0
    private var pauseStartDate: Date?

    /// preflight 阶段已搜索秒 (UI 显示用)
    @Published private(set) var preflightSeconds: Int = 0

    // MARK: - 初始化

    init(location: LocationService = .shared,
         health: HealthService = .shared,
         store: RunSessionStore = .shared) {
        self.location = location
        self.health = health
        self.store = store
        bindToServices()
    }

    private func bindToServices() {
        location.$distanceMeters
            .map { $0 / 1000.0 }
            .receive(on: DispatchQueue.main)
            .assign(to: \.distanceKm, on: self)
            .store(in: &locationCancellables)

        location.$rollingPaceSecondsPerKm
            .receive(on: DispatchQueue.main)
            .assign(to: \.rollingPaceSecondsPerKm, on: self)
            .store(in: &locationCancellables)

        location.$fixCount
            .receive(on: DispatchQueue.main)
            .assign(to: \.gpsFixCount, on: self)
            .store(in: &locationCancellables)

        location.$authorization
            .map { $0 == .authorizedWhenInUse || $0 == .authorizedAlways }
            .receive(on: DispatchQueue.main)
            .assign(to: \.locationAuthorized, on: self)
            .store(in: &locationCancellables)

        location.$authorization
            .map { $0 == .denied || $0 == .restricted }
            .receive(on: DispatchQueue.main)
            .assign(to: \.locationDenied, on: self)
            .store(in: &locationCancellables)

        health.$currentHR
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentHR, on: self)
            .store(in: &healthCancellables)
    }

    // MARK: - 触发方法 (UI 调用)

    /// IdleHome 点"出发" — 进入 preflight, 启动 1Hz 自动 tick (等 GPS / 超时)
    func startPreflight() {
        guard phase == .idle else { return }
        phase = .preflight
        preflightSeconds = 0
        location.requestAuthorization()
        location.startProbing()
        health.requestAuthorization { _ in /* 拒绝也 OK, HR 不强求 */ }
        schedulePreflightTick()
    }

    /// 用户在 GPS 弱时强行继续 — 把 .preflight 跳到 .ready, 立刻倒计时
    func skipGpsAndProceed() {
        guard phase == .preflight else { return }
        preflightTimer?.invalidate()
        preflightTimer = nil
        phase = .ready
        // 短暂 0.2s 让 UI 切到 ready 态再启 countdown
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.startCountdown(seconds: 3)
        }
    }

    /// preflight / ready 阶段用户取消 — 回 idle
    func cancelPreflight() {
        guard phase == .preflight || phase == .ready || phase == .countdown else { return }
        preflightTimer?.invalidate()
        preflightTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        location.reset()
        health.reset()
        phase = .idle
    }

    private func schedulePreflightTick() {
        preflightTimer?.invalidate()
        let t = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.preflightTick()
        }
        preflightTimer = t
    }

    private func preflightTick() {
        guard phase == .preflight else {
            preflightTimer?.invalidate()
            preflightTimer = nil
            return
        }
        preflightSeconds += 1
        // GPS 锁定 (fixCount ≥ 4) 且授权了 → 自动切 ready, 0.2s 后启 countdown
        if gpsFixCount >= 4 && locationAuthorized {
            preflightTimer?.invalidate()
            preflightTimer = nil
            phase = .ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.startCountdown(seconds: 3)
            }
        }
    }

    /// ready 状态点"出发倒计时"
    func startCountdown(seconds: Int = 3) {
        guard phase == .ready else { return }
        countdown = seconds
        phase = .countdown
        let t = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            self.countdown -= 1
            if self.countdown <= 0 {
                timer.invalidate()
                self.countdownTimer = nil
                self.startRunning()
            }
        }
        countdownTimer = t
    }

    /// 真开跑 (countdown 归零 / 紧急出发)
    private func startRunning() {
        startDate = Date()
        pausedAccumulated = 0
        pauseStartDate = nil
        elapsedSeconds = 0

        location.startAccumulating()
        health.startWorkout(activityType: .running, start: startDate!)

        phase = .running
        scheduleTick()
    }

    /// 暂停
    func pause() {
        guard phase == .running else { return }
        tickTimer?.invalidate()
        tickTimer = nil
        location.pauseTracking()
        pauseStartDate = Date()
        phase = .paused
    }

    /// 继续
    func resume() {
        guard phase == .paused else { return }
        if let p = pauseStartDate {
            pausedAccumulated += Date().timeIntervalSince(p)
        }
        pauseStartDate = nil
        location.resumeTracking()
        phase = .running
        scheduleTick()
    }

    /// 结束 — 落盘 + 切 ended
    func end() {
        guard phase == .running || phase == .paused else { return }
        tickTimer?.invalidate()
        tickTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil

        let endDate = Date()
        // 若在 paused, 把暂停期间也算进 pausedAccumulated
        if let p = pauseStartDate {
            pausedAccumulated += endDate.timeIntervalSince(p)
            pauseStartDate = nil
        }

        let collected = location.stopAndCollect()
        let dist = location.distanceMeters
        let secs = elapsedSeconds

        let pace = (dist > 10)
            ? Int((Double(secs) / dist) * 1000)
            : 0

        health.endWorkout(end: endDate, distance: dist) { [weak self] avgHR, _ in
            guard let self = self else { return }
            let record = RunRecord(
                id: UUID(),
                startDate: self.startDate ?? endDate,
                endDate: endDate,
                distanceMeters: dist,
                elapsedSeconds: secs,
                avgPaceSecondsPerKm: pace,
                avgHR: avgHR,
                routePoints: collected.map(RoutePoint.init)
            )
            self.store.save(record)
            self.lastRecord = record
            self.phase = .ended
        }
    }

    /// PostRunView dismiss / 用户点回到 IdleHome
    func acknowledge() {
        guard phase == .ended else { return }
        lastRecord = nil
        elapsedSeconds = 0
        distanceKm = 0
        rollingPaceSecondsPerKm = 0
        currentHR = nil
        pausedAccumulated = 0
        startDate = nil
        location.reset()
        health.reset()
        phase = .idle
    }

    // MARK: - Tick (1 Hz)

    private func scheduleTick() {
        tickTimer?.invalidate()
        let t = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        tickTimer = t
    }

    private func tick() {
        guard phase == .running, let start = startDate else { return }
        let raw = Date().timeIntervalSince(start) - pausedAccumulated
        elapsedSeconds = max(0, Int(raw))
    }

    // MARK: - 派生 (UI 直接读)

    /// 25:43 或 1:25:43
    var elapsedDisplay: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        if h > 0 {
            return "\(h):\(String(format: "%02d", m)):\(String(format: "%02d", s))"
        }
        return "\(String(format: "%d", m)):\(String(format: "%02d", s))"
    }

    /// 6'12" 或 --'--"
    var paceDisplay: String {
        guard rollingPaceSecondsPerKm > 0 else { return "--'--\"" }
        let m = rollingPaceSecondsPerKm / 60
        let s = rollingPaceSecondsPerKm % 60
        return "\(m)'\(String(format: "%02d", s))\""
    }

    /// 5.42 (公里 String, 2 位小数)
    var distanceDisplay: String {
        String(format: "%.2f", distanceKm)
    }
}
