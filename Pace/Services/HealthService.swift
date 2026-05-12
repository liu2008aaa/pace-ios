//
//  HealthService.swift
//  Pace.
//
//  v0.5.0: HealthKit 集成 — HKWorkoutBuilder 周期 + HR 实时读取.
//
//  iPhone-only 路径 (不是 watchOS):
//  - HKWorkoutBuilder + HKLiveWorkoutDataSource 是 watchOS 专属
//  - iPhone 用 HKWorkoutBuilder 直接构建 + HKAnchoredObjectQuery 监听 HR
//  - iPhone 没 HR 传感器, 真心率来自配对 Apple Watch (或第三方蓝牙带)
//
//  模拟器 fallback:
//  - HKHealthStore.isHealthDataAvailable() 在 sim 返回 true 但拿不到真数据
//  - #if targetEnvironment(simulator) 启用 sine 波 mock HR 60-180 bpm
//    让 UI 看到"有心率"在变 — 便于本地预览
//
//  Info.plist Mac 端必须加 (Xcode 12.5):
//    NSHealthShareUsageDescription = "用于读取你的心率, 在跑步中实时显示"
//    NSHealthUpdateUsageDescription = "用于把这次跑步保存到 Health 应用"
//

import Foundation
import HealthKit

final class HealthService: NSObject, ObservableObject {

    // MARK: - 输出

    @Published private(set) var isAuthorized: Bool = false
    @Published private(set) var currentHR: Int? = nil
    /// 累计所有 HR 读数 (workout 结束计算平均时用)
    @Published private(set) var hrSamples: [Int] = []

    // MARK: - 单例

    static let shared = HealthService()

    private let store = HKHealthStore()
    private var hrQuery: HKAnchoredObjectQuery?
    private var workoutBuilder: HKWorkoutBuilder?
    private var workoutStart: Date?

    #if targetEnvironment(simulator)
    private var mockTimer: Timer?
    private var mockTickIdx: Int = 0
    #endif

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // MARK: - 授权

    /// 请求读 HR + 写 Workout. completion 回主线程.
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard isAvailable else {
            completion(false)
            return
        }
        let read: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
        ]
        let share: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        ]
        store.requestAuthorization(toShare: share, read: read) { [weak self] ok, _ in
            DispatchQueue.main.async {
                self?.isAuthorized = ok
                completion(ok)
            }
        }
    }

    // MARK: - Workout lifecycle

    /// 开始一个 workout. 启动 HR observer + (sim) mock HR 定时器.
    func startWorkout(activityType: HKWorkoutActivityType = .running, start: Date) {
        workoutStart = start
        hrSamples = []
        currentHR = nil

        let config = HKWorkoutConfiguration()
        config.activityType = activityType
        config.locationType = .outdoor

        do {
            let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: nil)
            try? builder.beginCollection(withStart: start) { _, _ in /* ignore */ }
            workoutBuilder = builder
        }

        startHeartRateObserver(after: start)

        #if targetEnvironment(simulator)
        startMockHeartRate()
        #endif
    }

    /// 结束 — 保存 Workout 到 Health, 返回平均 HR (若有). completion 回主线程.
    func endWorkout(end: Date,
                    distance: Double,
                    completion: @escaping (_ avgHR: Int?, _ savedOK: Bool) -> Void) {
        stopHeartRateObserver()

        #if targetEnvironment(simulator)
        stopMockHeartRate()
        #endif

        let avgHR: Int? = hrSamples.isEmpty
            ? nil
            : Int(round(Double(hrSamples.reduce(0, +)) / Double(hrSamples.count)))

        guard let builder = workoutBuilder, isAuthorized else {
            workoutBuilder = nil
            DispatchQueue.main.async { completion(avgHR, false) }
            return
        }

        // 加上距离 sample
        if distance > 0,
           let distType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning),
           let start = workoutStart {
            let q = HKQuantity(unit: .meter(), doubleValue: distance)
            let s = HKQuantitySample(type: distType, quantity: q, start: start, end: end)
            builder.add([s]) { _, _ in /* ignore */ }
        }

        builder.endCollection(withEnd: end) { [weak self] _, _ in
            builder.finishWorkout { _, _ in
                self?.workoutBuilder = nil
                DispatchQueue.main.async { completion(avgHR, true) }
            }
        }
    }

    func reset() {
        currentHR = nil
        hrSamples = []
        workoutStart = nil
        workoutBuilder = nil
    }

    // MARK: - HR observer

    private func startHeartRateObserver(after start: Date) {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate),
              isAuthorized else { return }

        let predicate = HKQuery.predicateForSamples(withStart: start,
                                                    end: nil,
                                                    options: .strictStartDate)
        let q = HKAnchoredObjectQuery(type: hrType,
                                      predicate: predicate,
                                      anchor: nil,
                                      limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, _, _ in
            self?.processHR(samples: samples)
        }
        q.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.processHR(samples: samples)
        }
        store.execute(q)
        hrQuery = q
    }

    private func stopHeartRateObserver() {
        if let q = hrQuery {
            store.stop(q)
            hrQuery = nil
        }
    }

    private func processHR(samples: [HKSample]?) {
        guard let qSamples = samples as? [HKQuantitySample], !qSamples.isEmpty else { return }
        let unit = HKUnit.count().unitDivided(by: .minute())
        let bpms: [Int] = qSamples.map { Int(round($0.quantity.doubleValue(for: unit))) }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let latest = bpms.last { self.currentHR = latest }
            self.hrSamples.append(contentsOf: bpms)
        }
    }

    // MARK: - 模拟器 mock HR (sine 60-180 bpm, 周期 ~3 分钟)

    #if targetEnvironment(simulator)
    private func startMockHeartRate() {
        mockTickIdx = 0
        mockTimer?.invalidate()
        let t = Timer(timeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.mockTickIdx += 1
            // sine 周期 90 ticks (= 3 min). amplitude 60 → 180 bpm
            let phase = Double(self.mockTickIdx) * 2.0 * .pi / 90.0
            let bpm = 120 + 60 * sin(phase)   // 60..180
            let hr = max(50, min(190, Int(round(bpm))))
            DispatchQueue.main.async {
                self.currentHR = hr
                self.hrSamples.append(hr)
            }
        }
        RunLoop.main.add(t, forMode: .common)
        mockTimer = t
    }

    private func stopMockHeartRate() {
        mockTimer?.invalidate()
        mockTimer = nil
    }
    #endif
}
