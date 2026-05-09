//
//  Hairline.swift
//  Pace.
//
//  0.5px 渐变分隔线。中间最浓，左右淡出。
//

import SwiftUI

struct Hairline: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [.clear, Theme.hairlineBright, Theme.hairlineBright, .clear]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 0.5)
    }
}

#if DEBUG
struct Hairline_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            Hairline()
            Hairline()
        }
        .padding()
        .background(Theme.bgApp)
        .previewLayout(.sizeThatFits)
    }
}
#endif
