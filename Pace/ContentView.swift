//
//  ContentView.swift
//  Pace.
//
//  根 View。当前直接展示 IdleHome (Phone 01)。
//  v0.2 接入 NavigationView + 路由后会改为容器。
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        IdleHome()
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
#endif
