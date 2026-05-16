//
//  DashboardView.swift
//  IO Teeth Monitor
//
//  Created by Alexandra Tombleson on 5/16/26.

import SwiftUI
import Charts

struct DashboardView: View {
    @ObservedObject var data: MockDataManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Live Overview")
                    .font(.largeTitle.bold())
                    .padding(.horizontal)

                // Live vitals row
                if let reading = data.latestReading {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()),
                                        GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(title: "Left Pressure",  value: String(format: "%.0f", reading.leftPressure),  unit: "Pa",  color: .blue,   icon: "gauge.medium")
                        StatCard(title: "Right Pressure", value: String(format: "%.0f", reading.rightPressure), unit: "Pa",  color: .indigo, icon: "gauge.medium")
                        StatCard(title: "Left Temp",      value: String(format: "%.1f", reading.leftTemp),      unit: "°C",  color: .orange, icon: "thermometer.medium")
                        StatCard(title: "Right Temp",     value: String(format: "%.1f", reading.rightTemp),     unit: "°C",  color: .red,    icon: "thermometer.medium")
                    }
                    .padding(.horizontal)
                } else {
                    ProgressView("Waiting for data…")
                        .frame(maxWidth: .infinity)
                        .padding()
                }

                // Latest bioimpedance sweep preview
                if let lastSession = data.sessions.last,
                   let lastSweep = lastSession.sweeps.last {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Latest Bioimpedance Sweep")
                            .font(.headline)
                            .padding(.horizontal)
                        Text("Conductivity vs Frequency · \(lastSession.label)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        Chart(lastSweep.points) { point in
                            LineMark(
                                x: .value("Frequency", log10(point.frequency)),
                                y: .value("Conductivity", point.conductivity * 1000)
                            )
                            .foregroundStyle(.cyan)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Frequency", log10(point.frequency)),
                                yStart: .value("Base", 0),
                                yEnd: .value("Conductivity", point.conductivity * 1000)
                            )
                            .foregroundStyle(.cyan.opacity(0.15))
                            .interpolationMethod(.catmullRom)
                        }
                        .chartXAxis {
                            AxisMarks(values: [3, 4, 5, 6]) { val in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let v = val.as(Double.self) {
                                        Text(freqLabel(v)).font(.system(size: 9))
                                    }
                                }
                            }
                        }
                        .chartYAxisLabel("Conductivity (mS)", position: .leading)
                        .frame(height: 180)
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 12)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }

                // Sessions summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Data Sessions")
                        .font(.headline)
                        .padding(.horizontal)
                    ForEach(data.sessions.reversed()) { session in
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(.secondary)
                            Text(session.label)
                                .font(.subheadline)
                            Spacer()
                            Text("\(session.sweeps.count) sweeps · \(session.archReadings.count) readings")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                        Divider().padding(.horizontal)
                    }
                }
                .padding(.vertical, 12)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    private func freqLabel(_ log: Double) -> String {
        switch log {
        case 3: return "1kHz"
        case 4: return "10kHz"
        case 5: return "100kHz"
        case 6: return "1MHz"
        default: return ""
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).foregroundStyle(color)
                Spacer()
                Text("LIVE")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.green.opacity(0.15))
                    .foregroundStyle(.green)
                    .clipShape(Capsule())
            }
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: value)
                Text(unit).font(.caption).foregroundStyle(.secondary)
            }
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
