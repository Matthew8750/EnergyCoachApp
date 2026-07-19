//
//  WatchContentView.swift
//  EnergyCoachWatchApp
//
//  Created by Codex on 14/07/2026.
//

import SwiftUI

struct WatchContentView: View {
    @EnvironmentObject private var model: WatchEnergyModel

    private var tint: Color {
        if model.score < 40 {
            return .red
        }

        if model.score < 70 {
            return .orange
        }

        return .green
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(model.score)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(tint)
                    Text("/100")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Text(model.recoveryRisk)
                    .font(.headline)
                    .foregroundStyle(tint)

                Text(model.connectionStatus)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(model.lastUpdatedText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(model.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: model.requestLatestScore) {
                    Label(model.isRefreshing ? "Refreshing" : "Refresh", systemImage: "arrow.clockwise")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .disabled(model.isRefreshing)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 8)
        }
        .containerBackground(.black, for: .navigation)
    }
}


#Preview {
    WatchContentView()
        .environmentObject(WatchEnergyModel.preview)
}
