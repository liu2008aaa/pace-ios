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

    private var isRunFlowActive: Binding<Bool> {
        Binding(
            get: { self.engine.phase != .idle },
            set: { _ in }
        )
    }

    var body: some View {
        Group {
            if store.records.isEmpty {
                FirstRunHomeView()
            } else {
                IdleHome()
            }
        }
        .fullScreenCover(isPresented: isRunFlowActive) {
            RunFlowView()
                .environmentObject(engine)
                .environmentObject(store)
        }
    }
}

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
