//
//  TemperatureView.swift
//  IO Teeth Monitor
//
//  Created by Alexandra Tombleson on 5/16/26.


import SwiftUI
import Charts

struct TemperatureView: View {
    @ObservedObject var data: MockDataManager
    @State private var selectedSession: DaySession?

    var session: DaySession? { selectedSession ?? data.sessions.last }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("Temperature")
                        .font(.largeTitle.bold())
                    Spacer()
                    if !data.sessions.isEmpty {
                        Picker("Day", selection: $selectedSession) {
                            Text("Latest").tag(Optional<DaySession>.none)
                            ForEach(data.sessions.reversed()) { s in
                                Text(s.label).tag(Optional(s))
                            }
                        }
                        .frame(width: 180)
                    }
                }
                .padding(.horizontal)

                // Live readings
                if let reading = data.latestReading {
                    HStack(spacing: 16) {
                        TempCard(title: "Left Arch",  value: reading.leftTemp,  color: .orange)
                        TempCard(title: "Right Arch", value: reading.rightTemp, color: .red)
                    }
                    .padding(.horizontal)
                }

                // Chart
                if let s = session, !s.archReadings.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Temperature Over Day · \(s.label)")
                            .font(.headline).padding(.horizontal)

                        Chart {
                            ForEach(s.archReadings) { r in
                                LineMark(x: .value("Time", r.timestamp),
                                         y: .value("Temp", r.leftTemp))
                                .foregroundStyle(.orange)
                                .interpolationMethod(.catmullRom)
                                LineMark(x: .value("Time", r.timestamp),
                                         y: .value("Temp", r.rightTemp))
                                .foregroundStyle(.red)
                                .interpolationMethod(.catmullRom)
                            }
                            RuleMark(y: .value("Normal High", 37.5))
                                .foregroundStyle(.red.opacity(0.4))
                                .lineStyle(StrokeStyle(dash: [4]))
                            RuleMark(y: .value("Normal Low", 36.0))
                                .foregroundStyle(.blue.opacity(0.4))
                                .lineStyle(StrokeStyle(dash: [4]))
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 6)) { _ in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.hour())
                                    .font(.system(size: 9))
                            }
                        }
                        .chartYScale(domain: 35.0...38.5)
                        .chartYAxisLabel("Temperature (°C)", position: .leading)
                        .frame(height: 220)
                        .padding(.horizontal)

                        HStack(spacing: 16) {
                            Label("Left Arch", systemImage: "circle.fill").foregroundStyle(.orange)
                            Label("Right Arch", systemImage: "circle.fill").foregroundStyle(.red)
                            Label("Normal Range", systemImage: "line.diagonal").foregroundStyle(.secondary)
                        }
                        .font(.caption)
                        .padding(.horizontal)
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
}

struct TempCard: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "thermometer.medium").foregroundStyle(color)
                Text(title).font(.subheadline).foregroundStyle(.secondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(String(format: "%.1f", value))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: value)
                Text("°C").font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
