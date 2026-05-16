//
//  MainSidebarView.swift
//  IO Teeth Monitor
//
//  Created by Alexandra Tombleson on 5/16/26.
//

import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case dashboard     = "Dashboard"
    case pressure      = "Pressure"
    case temperature   = "Temperature"
    case bioimpedance  = "Bioimpedance"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard:    return "square.grid.2x2.fill"
        case .pressure:     return "gauge.medium"
        case .temperature:  return "thermometer.medium"
        case .bioimpedance: return "waveform.path.ecg"
        }
    }
}

struct MainSidebarView: View {
    @StateObject private var data = MockDataManager()
    @State private var selection: AppSection? = .dashboard

    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $selection) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .tag(section)
            }
            .navigationTitle("IOTeeth Monitor")
            .safeAreaInset(edge: .bottom) {
                connectionFooter
            }
        } detail: {
            switch selection ?? .dashboard {
            case .dashboard:
                DashboardView(data: data)
            case .pressure:
                PressureView(data: data)
            case .temperature:
                TemperatureView(data: data)
            case .bioimpedance:
                BioimpedanceView(data: data)
            }
        }
        .onAppear { data.connect() }
        .onDisappear { data.disconnect() }
    }

    private var connectionFooter: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(data.isConnected ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
                .shadow(color: data.isConnected ? .green.opacity(0.7) : .orange.opacity(0.7), radius: 4)
            Text(data.statusMessage)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(12)
    }
}
