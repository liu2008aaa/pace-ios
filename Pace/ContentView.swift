//
//  ContentView.swift
//  Pace.
//
//  根 View。当前直接展示 IdleHome (Phone 01)。
//  v0.2 接入 NavigationView + 路由后会改为容器。
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var engine: RunSessionEngine
    @EnvironmentObject var store: RunSessionStore
    @State private var isLaunchOverlayVisible = true

    private let launchOverlaySeconds: Double = 3.0

    private var isRunFlowActive: Binding<Bool> {
        Binding(
            get: { self.engine.phase != .idle },
            set: { _ in }
        )
    }

    var body: some View {
        ZStack {
            Group {
                if store.hasStoredRecords || !store.records.isEmpty {
                    IdleHome()
                } else {
                    FirstRunHomeView()
                }
            }

            if isLaunchOverlayVisible {
                LaunchOverlay()
                    .transition(.opacity)
            }
        }
        .onAppear {
            LaunchTiming.mark("ContentView appear")
            DispatchQueue.main.asyncAfter(deadline: .now() + launchOverlaySeconds) {
                withAnimation(.easeOut(duration: 0.22)) {
                    isLaunchOverlayVisible = false
                }
            }
        }
        .fullScreenCover(isPresented: isRunFlowActive) {
            RunFlowView()
                .environmentObject(engine)
                .environmentObject(store)
        }
    }
}

private struct LaunchOverlay: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            Theme.bgApp.ignoresSafeArea()

            VStack(spacing: 12) {
                logo

                caption
            }
            .offset(y: -12)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.82).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private var logo: some View {
        Text("Pace.")
            .font(.system(size: 56, weight: .black))
            .foregroundColor(Theme.accent.opacity(pulse ? 1.0 : 0.78))
    }

    private var caption: some View {
        Text("RUN READY")
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(Theme.text3.opacity(pulse ? 0.95 : 0.58))
            .kerning(3.4)
    }
}

#if DEBUG
enum LaunchTiming {
    static let appInit = Date()

    static func mark(_ label: String) {
        let ms = Int(Date().timeIntervalSince(appInit) * 1000)
        print("PaceLaunch \(label): \(ms)ms")
    }
}
#else
enum LaunchTiming {
    static func mark(_ label: String) {}
}
#endif

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
            .environmentObject(RunSessionEngine())
            .environmentObject(RunSessionStore.shared)
    }
}
#endif
