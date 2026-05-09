//
//  TimelineDots.swift
//  Pace.
//
//  Phone 01 底部 14 天活力点：13 个历史点（按强度发光）+ 1 个空心冷绿环（今日）。
//

import SwiftUI

struct TimelineDots: View {
    /// 历史 13 天的强度值 0-1。
    let intensities: [Double]

    var body: some View {
        HStack {
            ForEach(intensities.indices, id: \.self) { i in
                let intensity = intensities[i]
                let age = Double(intensities.count - i) / Double(intensities.count) // 1 → 0
                let opacity = min(0.18 + (1 - age) * 0.8 * intensity, 0.9)
                let size = 4 + intensity * 4 // 4-8 px

                Circle()
                    .fill(Theme.accent.opacity(opacity))
                    .frame(width: size, height: size)
                    .shadow(
                        color: intensity > 0.7 ? Theme.accent.opacity(0.5) : .clear,
                        radius: 4
                    )
                if i < intensities.count - 1 {
                    Spacer(minLength: 0)
                }
            }
            Spacer(minLength: 0)

            // 今日空心环
            Circle()
                .stroke(Theme.accent, lineWidth: 1.5)
                .frame(width: 11, height: 11)
                .shadow(color: Theme.accent.opacity(0.6), radius: 5)
        }
        .padding(.vertical, 8)
    }
}

#if DEBUG
struct TimelineDots_Previews: PreviewProvider {
    static var previews: some View {
        TimelineDots(intensities: MockData.timeline)
            .padding()
            .background(Theme.bgApp)
            .previewLayout(.sizeThatFits)
    }
}
#endif
