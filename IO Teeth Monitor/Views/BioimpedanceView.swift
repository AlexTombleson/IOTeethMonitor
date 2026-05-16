// BioimpedanceView.swift
// IO Teeth Monitor

import SwiftUI
import Charts

struct BioimpedanceView: View {
    @ObservedObject var data: MockDataManager
    @State private var selectedSession: DaySession?
    @State private var plotType: PlotType = .conductivity
    @State private var overlayAll: Bool = true

    enum PlotType: String, CaseIterable {
        case conductivity = "Conductivity"
        case permittivity = "Permittivity"
    }

    var session: DaySession? { selectedSession ?? data.sessions.last }

    private let sweepColors: [Color] = [.cyan, .mint, .teal]
    private let sweepLabels = ["Morning", "Afternoon", "Evening"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Header controls
                VStack(alignment: .leading, spacing: 12) {
                    Text("Bioimpedance Spectroscopy")
                        .font(.largeTitle.bold())

                    HStack(spacing: 12) {
                        // Day picker
                        if !data.sessions.isEmpty {
                            Picker("Day", selection: $selectedSession) {
                                Text("Latest").tag(Optional<DaySession>.none)
                                ForEach(data.sessions.reversed()) { s in
                                    Text(s.label).tag(Optional(s))
                                }
                            }
                            .frame(width: 180)
                        }

                        // Plot type
                        Picker("Plot", selection: $plotType) {
                            ForEach(PlotType.allCases, id: \.self) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 260)

                        // Overlay toggle
                        Toggle("Overlay all sweeps", isOn: $overlayAll)
                            .toggleStyle(.switch)
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal)

                // Main spectroscopy chart
                if let s = session {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(plotType.rawValue) vs Frequency · \(s.label)")
                            .font(.headline).padding(.horizontal)
                        Text("Frequency range: 1 kHz – 1 MHz · 48 points per sweep")
                            .font(.caption).foregroundStyle(.secondary).padding(.horizontal)

                        let sweeps = overlayAll ? s.sweeps : [s.sweeps.last].compactMap { $0 }

                        Chart {
                            ForEach(Array(sweeps.enumerated()), id: \.offset) { idx, sweep in
                                let color = sweepColors[idx % sweepColors.count]
                                ForEach(sweep.points) { point in
                                    let yVal = plotType == .conductivity
                                        ? point.conductivity * 1000
                                        : point.permittivity * 1000
                                    LineMark(
                                        x: .value("log(Hz)", log10(point.frequency)),
                                        y: .value(plotType.rawValue, yVal)
                                    )
                                    .foregroundStyle(color)
                                    .interpolationMethod(.catmullRom)

                                    AreaMark(
                                        x: .value("log(Hz)", log10(point.frequency)),
                                        yStart: .value("Base", 0),
                                        yEnd: .value(plotType.rawValue, yVal)
                                    )
                                    .foregroundStyle(color.opacity(0.08))
                                    .interpolationMethod(.catmullRom)
                                }
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: [3, 3.5, 4, 4.5, 5, 5.5, 6]) { val in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let v = val.as(Double.self) {
                                        Text(freqLabel(v)).font(.system(size: 9))
                                    }
                                }
                            }
                        }
                        .chartYAxisLabel(plotType == .conductivity ? "Conductivity (mS)" : "Permittivity (mF/m)", position: .leading)
                        .frame(height: 280)
                        .padding(.horizontal)
                        .animation(.easeInOut(duration: 0.3), value: plotType)
                        .animation(.easeInOut(duration: 0.3), value: overlayAll)

                        // Legend
                        HStack(spacing: 16) {
                            ForEach(Array(sweeps.enumerated()), id: \.offset) { idx, _ in
                                Label(sweepLabels[idx % sweepLabels.count],
                                      systemImage: "circle.fill")
                                    .foregroundStyle(sweepColors[idx % sweepColors.count])
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 12)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Sweep stats table
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sweep Summary")
                            .font(.headline).padding(.horizontal)

                        ForEach(Array(s.sweeps.enumerated()), id: \.offset) { idx, sweep in
                            HStack {
                                Circle().fill(sweepColors[idx % sweepColors.count])
                                    .frame(width: 8, height: 8)
                                Text(sweepLabels[idx % sweepLabels.count])
                                    .font(.subheadline)
                                Spacer()
                                Text(sweep.timestamp, style: .time)
                                    .font(.caption).foregroundStyle(.secondary)
                                Text("· \(sweep.points.count) pts")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                            if idx < s.sweeps.count - 1 {
                                Divider().padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    private func freqLabel(_ log: Double) -> String {
        switch log {
        case 3:   return "1kHz"
        case 3.5: return "3kHz"
        case 4:   return "10kHz"
        case 4.5: return "30kHz"
        case 5:   return "100kHz"
        case 5.5: return "300kHz"
        case 6:   return "1MHz"
        default:  return ""
        }
    }
}
