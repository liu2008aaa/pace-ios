# Pace iOS · v0.5 架构

> v0.4 是 16 屏静态 mock。v0.5 引入 Service 层 + 状态机, 把 mock 数据替换成 GPS + HealthKit 真数据。这份文档解释**为什么**这么拆,以及每个文件**应该**做什么。

## 1. 层

```
┌──────────────────────────────────────────────────────────┐
│  View 层 (Pace/Screens/*)                                │
│  - IdleHome / PreRunView / RunningView / PausedView /     │
│    PostRunView / WeekHistoryView ...                      │
│  - 只读, 通过 @EnvironmentObject 订阅 engine               │
│  - 触发 engine.startPreflight() / pause() / end() 等       │
└────────────────────────┬─────────────────────────────────┘
                         │
                         ▼ @Published
┌──────────────────────────────────────────────────────────┐
│  RunSessionEngine (Pace/Services/RunSessionEngine.swift) │
│  - 状态机: idle → preflight → ready → countdown →          │
│            running ↔ paused → ended                       │
│  - Timer 1Hz 驱动 elapsedSeconds                          │
│  - 转发 LocationService / HealthService 的 @Published      │
│  - .end() 时聚合, 落盘到 Store                            │
└──────┬─────────┬──────────────┬──────────────────────────┘
       │         │              │
       ▼         ▼              ▼
┌──────────┐ ┌──────────┐ ┌────────────────┐
│ Location │ │ Health   │ │ RunSession     │
│ Service  │ │ Service  │ │ Store          │
│          │ │          │ │                │
│ CLLoc    │ │ HK Wkout │ │ UserDefaults   │
│ Manager  │ │ Builder  │ │ JSON 数组       │
│ Delegate │ │ HKAnchor │ │ 聚合 helpers   │
│ wrapper  │ │ Query HR │ │ (周/月/年)     │
└──────────┘ └──────────┘ └────────────────┘
```

**单 source of truth = `RunSessionEngine.phase`**. 所有 UI 状态都从它派生。

## 2. 状态机

```
        ┌─────────────┐
        │   .idle     │ ← IdleHome 显示
        └──────┬──────┘
               │ user 点 出发
               ▼
        ┌─────────────┐
        │ .preflight  │ ← PreRunView 显示 GPS 搜索 UI
        └──────┬──────┘    engine 1Hz preflightTimer:
               │            - 累 preflightSeconds
               │ GPS ≥4    - 看 fixCount ≥4 即转 .ready
               ▼
        ┌─────────────┐
        │   .ready    │ ← 短暂 0.2s 让 UI 显示 "GPS OK"
        └──────┬──────┘
               │ 0.2s 后自动 startCountdown(3)
               ▼
        ┌─────────────┐
        │ .countdown  │ ← PreRunView 显示倒计时 hero
        └──────┬──────┘    engine 1Hz countdownTimer 递减
               │ countdown==0
               ▼
        ┌─────────────┐
        │  .running   │ ← RunningView 显示
        └─┬───────────┘    engine 1Hz tickTimer:
          │                 - elapsedSeconds 累加
          │                 - LocationService 推 distance/pace
          │                 - HealthService 推 HR (#if sim mock)
          │ pause()                 ┌────────┐
          ├────────────────────────►│ .paused│ ← PausedView 显示
          │                         └───┬────┘
          │   resume()                  │
          │ ◄───────────────────────────┤ end()
          │                             │
          │ end()                       │
          ▼                             ▼
        ┌─────────────┐
        │   .ended    │ ← PostRunView 显示 lastRecord
        └──────┬──────┘
               │ user 点 完成 (acknowledge)
               ▼
        ┌─────────────┐
        │   .idle     │ ← 回到 IdleHome
        └─────────────┘
```

**取消路径** (任意 preflight/ready/countdown 期间 cancelPreflight) 直接回 .idle, 不存档。

## 3. Service 单例 vs Engine

```
RunSessionEngine (StateObject, 每次 App 启动 1 个)
  ↓ 拥有
LocationService.shared (单例)
HealthService.shared   (单例)
RunSessionStore.shared (单例)
```

为什么 services 是 singleton, engine 是 @StateObject?
- Services 是底层 iOS API 包装, 全局只能有一份 (CLLocationManager / HKHealthStore 都是底层资源)
- Engine 是会话级状态, 跟着 App 生命周期。理论上一个 App 内只跑一次, @StateObject 在 PaceApp 持有, 跨整个 ContentView 树注入

## 4. 跨线程

```
CLLocationManagerDelegate            HKAnchoredObjectQuery
  (main thread by default)             (HK background queue)
        │                                     │
        ▼                                     ▼
LocationService.ingestFix()           HealthService.processHR()
        │                                     │
        ▼  DispatchQueue.main.async ▼ (强制回主线程)
        ◄────────────────────────────────────►
        │
        ▼
@Published distanceMeters / currentHR
        │
        ▼ Combine assign
RunSessionEngine.distanceKm / currentHR
        │
        ▼ SwiftUI 自动刷新
RunningView 显示
```

**注意**: Swift 5.4 没有 `@MainActor` (5.5+ 才有), 所以**任何**回调里改 `@Published` 都要手动 `DispatchQueue.main.async`. 是不是已经在主线程都得加 — 安全冗余比死锁好。

## 5. RunRecord 数据流

```
.end() 时:
  endDate = Date()
  collected = location.stopAndCollect()       ← [CLLocation] 路径
  dist     = location.distanceMeters
  secs     = engine.elapsedSeconds
  pace     = (dist > 10) ? (secs/dist)*1000 : 0
  health.endWorkout(end:, distance:) { avgHR, savedOK in
    let record = RunRecord(
      id: UUID(),
      startDate, endDate,
      distanceMeters: dist,
      elapsedSeconds: secs,
      avgPaceSecondsPerKm: pace,
      avgHR: avgHR,
      routePoints: collected.map(RoutePoint.init)
    )
    store.save(record)         ← UserDefaults JSON 数组
    engine.lastRecord = record ← PostRunView 显示这条
    engine.phase = .ended
  }
```

`HealthService` 同时把 workout 写进 Health.app (`HKWorkoutBuilder.finishWorkout`)。

## 6. 模拟器 vs 真机

| Service | Sim 行为 | 真机行为 |
|---|---|---|
| LocationService | Debug → Location → City Run 走慢路径 | 真 GPS, 室外 |
| HealthService (HR) | `#if targetEnvironment(simulator)` sine 60-180 bpm | 配对 Watch 后真 HR (iPhone 无传感器) |
| HKWorkoutBuilder save | save 到 Health.app sandbox (可看) | save 到 Health.app 真实 |
| UserDefaults | 单 Mac, App 卸载就丢 | 真 iCloud sync (如开)|

## 7. v0.5.0 没做的 (deferred)

- **WeekHistoryView 真聚合** — 还是 MockData. v0.5.1 swap.
- **IdleHome 三表盘** — 还是 MockData. v0.5.1 wire to store.thisWeekDistanceKm 等
- **TTS 公里报数** — v0.5.2
- **Local Notifications** — v0.5.3
- **Live Activity (iOS 16.1+ 锁屏卡)** — Xcode 12.5 不支持, 需 Mac 升级
- **后台跑步** — 已开 Capabilities, 但没在 LocationService 里调 `allowsBackgroundLocationUpdates = true` (避免 Mac 上一开 App 就持续偷电)。真机需要这一行才能后台。
- **HRZone 真实计算** — 现在是简单线性 60→Z1, 190→Z5. 应该按用户最大心率 (静息 + 运动恢复) 自适应。
- **失败路径** — 用户拒绝 GPS 权限怎么显示? 现在引擎卡在 preflight 永远到不了 ready。需要 LocationService 探测 .denied 状态时通知 engine 切某个 fallback 状态。

## 8. Pre-commit 雷区 + Service 层补充

Service 层 (非 View) 有额外注意:
- **Service 全用 class** (ObservableObject 要求引用类型)
- **@Published 修改必须主线程** — 委托回调 + 异步 query 全部 `DispatchQueue.main.async`
- **不能用 async/await** — Swift 5.4 没有, 全 callback closure
- **不能用 @MainActor** — Swift 5.4 没有
- **Foundation only for Model** — RunRecord 只 import Foundation + CoreLocation (CL 是因为 routePoints 编码 CLLocation)
- **Codable 默认参数** — Swift 5.4 Codable 不支持 default value 自动 sync, 写 init 显式给 nil
- **iOS 14 SDK 限制**: 没 `.task`, 没 `LocationManager.requestAlwaysAuthorization` 自动 → fallback 到 When-In-Use
