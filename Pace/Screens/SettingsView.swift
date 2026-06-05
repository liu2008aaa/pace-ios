//
//  SettingsView.swift
//  Pace.
//
//  Phone 10 · 设置 (Settings)
//
//  对照 pace-demo/index.html#L3927-L4084
//
//  布局: §4.4 表单/列表 — 自然紧凑顶对齐, 不要 Spacer, 套 ScrollView 兜底
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var store: RunSessionStore

    private var profileMeta: String {
        guard !store.records.isEmpty else { return MockData.Settings.profileMeta }
        let totalKm = store.records.reduce(0) { $0 + $1.distanceKm }
        return String(format: "已跑 %.1f km · 连续 %d 天",
                      totalKm,
                      store.currentStreakDays())
    }

    var body: some View {
        ZStack {
            Theme.bgApp.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    brandStrip
                    Spacer().frame(height: 16)
                    profileCard
                    ForEach(0..<MockData.Settings.sections.count, id: \.self) { i in
                        Spacer().frame(height: 16)
                        sectionView(MockData.Settings.sections[i])
                    }
                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
            }
        }
    }

    // MARK: - 顶部条 (设置 + 关闭 ✕)
    private var brandStrip: some View {
        HStack {
            Text("设置")
                .font(PaceFont.cn(size: 13, weight: .semibold))
                .foregroundColor(Theme.text1)
                .kerning(2.8)
            Spacer()
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack(spacing: 4) {
                    Text("关闭")
                        .font(PaceFont.cn(size: 11, weight: .medium))
                        .foregroundColor(Theme.text2)
                        .kerning(2.2)
                    Text("✕")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.text2)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.top, 10)
    }

    // MARK: - Profile card
    private var profileCard: some View {
        HStack(spacing: 12) {
            // Monogram avatar 44×44
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: 0x06281E),
                                Color(hex: 0x003B2C),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.accent.opacity(0.42), lineWidth: 1)

                // 点阵背景
                MonogramDots()
                    .frame(width: 44, height: 44)

                // L. 字母组
                HStack(spacing: 0) {
                    Text("L")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(Theme.accent)
                    Text(".")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(Theme.accentBright)
                }
            }
            .frame(width: 48, height: 48)
            .shadow(color: Theme.accent.opacity(0.15), radius: 12)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(MockData.Settings.userName)
                        .font(PaceFont.cn(size: 15, weight: .bold))
                        .foregroundColor(Theme.text1)
                        .kerning(0.4)
                    Text(MockData.Settings.userHandle)
                        .font(PaceFont.mono(size: 10, weight: .medium))
                        .foregroundColor(Theme.text4)
                        .kerning(0.4)
                }
                Text(profileMeta)
                    .font(PaceFont.cn(size: 11, weight: .medium))
                    .foregroundColor(Theme.text2)
                    .kerning(0.8)
            }

            Spacer()

            Text("›")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(Theme.text4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Theme.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.hairlineBright, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - section
    private func sectionView(_ section: MockData.Settings.Section) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.title)
                .font(PaceFont.mono(size: 9.5, weight: .semibold))
                .foregroundColor(Theme.text3)
                .kerning(2.8)

            VStack(spacing: 0) {
                ForEach(0..<section.rows.count, id: \.self) { i in
                    let row = section.rows[i]
                    settingRow(row)
                    if i < section.rows.count - 1 {
                        Rectangle()
                            .fill(Theme.hairline)
                            .frame(height: 0.5)
                            .padding(.horizontal, 14)
                    }
                }
            }
            .background(Theme.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.hairlineBright, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - 单设置行
    @ViewBuilder
    private func settingRow(_ row: MockData.Settings.Row) -> some View {
        HStack {
            HStack(spacing: 6) {
                Text(row.label)
                    .font(PaceFont.cn(size: 13, weight: .medium))
                    .foregroundColor(Theme.text1)
                    .kerning(0.4)
                if row.recommended {
                    Text("推荐")
                        .font(PaceFont.cn(size: 9, weight: .semibold))
                        .foregroundColor(Theme.accent)
                        .kerning(1.6)
                }
            }
            Spacer()
            settingRowValue(row.kind)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    @ViewBuilder
    private func settingRowValue(_ kind: MockData.Settings.RowKind) -> some View {
        switch kind {
        case .toggle(let on):
            ToggleSwitch(isOn: on)
        case .nav(let value, let valueAccent):
            HStack(spacing: 5) {
                Text(value)
                    .font(PaceFont.cn(size: 12, weight: .medium))
                    .foregroundColor(valueAccent ? Theme.accent : Theme.text2)
                    .kerning(0.4)
                Text("›")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(Theme.text4)
            }
        case .staticText(let value):
            Text(value)
                .font(PaceFont.mono(size: 11, weight: .medium))
                .foregroundColor(Theme.text3)
                .kerning(1.0)
        case .action:
            Text("›")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Theme.text4)
        }
    }
}

// MARK: - 自定义开关 (静态, 接真功能时改 @Binding)
private struct ToggleSwitch: View {
    let isOn: Bool

    var body: some View {
        ZStack {
            Capsule()
                .fill(isOn ? Theme.accent.opacity(0.30) : Theme.bgElev2)
            Capsule()
                .stroke(isOn ? Theme.accent.opacity(0.50) : Theme.hairlineBright, lineWidth: 1)

            HStack {
                if isOn { Spacer() }
                Circle()
                    .fill(isOn ? Theme.accent : Theme.text3)
                    .frame(width: 16, height: 16)
                    .shadow(color: isOn ? Theme.accent.opacity(0.6) : .clear, radius: 4)
                    .padding(2)
                if !isOn { Spacer() }
            }
        }
        .frame(width: 38, height: 22)
    }
}

// MARK: - Avatar 点阵装饰
private struct MonogramDots: View {
    var body: some View {
        GeometryReader { geo in
            let scaleX: CGFloat = geo.size.width / 44
            let scaleY: CGFloat = geo.size.height / 44
            let step: CGFloat = 5
            ZStack {
                ForEach(0..<9, id: \.self) { row in
                    ForEach(0..<9, id: \.self) { col in
                        Circle()
                            .fill(Theme.accent.opacity(0.32))
                            .frame(width: 0.9, height: 0.9)
                            .position(
                                x: (CGFloat(col) * step + 2.5) * scaleX,
                                y: (CGFloat(row) * step + 2.5) * scaleY
                            )
                    }
                }
            }
        }
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .preferredColorScheme(.dark)
            .environmentObject(RunSessionStore.shared)
    }
}
#endif
