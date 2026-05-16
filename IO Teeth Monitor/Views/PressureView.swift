//
//  PressureView.swift
//  IO Teeth Monitor
//
//  Created by Alexandra Tombleson on 5/16/26.


import SwiftUI
import Charts

struct PressureView: View {
    @ObservedObject var data: MockDataManager
    @State private var selectedSession: DaySession?

    var session: DaySession? { selectedSession ?? data.sessions.last }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Text("Pressure")
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

                // Live gauges
                if let reading = data.latestReading {
                    HStack(spacing: 16) {
                        PressureGauge(title: "Left Arch",  value: reading.leftPressure,  color: .blue)
                        PressureGauge(title: "Right Arch", value: reading.rightPressure, color: .indigo)
                    }
                    .padding(.horizontal)
                }

                // Chart
                if let s = session, !s.archReadings.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pressure Over Day · \(s.label)")
                            .font(.headline).padding(.horizontal)

                        Chart {
                            ForEach(s.archReadings) { r in
                                LineMark(x: .value("Time", r.timestamp),
                                         y: .value("Pressure", r.leftPressure))
                                .foregroundStyle(.blue)
                                .interpolationMethod(.catmullRom)
                                LineMark(x: .value("Time", r.timestamp),
                                         y: .value("Pressure", r.rightPressure))
                                .foregroundStyle(.indigo)
                                .interpolationMethod(.catmullRom)
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 6)) { _ in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.hour())
                                    .font(.system(size: 9))
                            }
                        }
                        .chartYAxisLabel("Pressure (Pa)", position: .leading)
                        .frame(height: 220)
                        .padding(.horizontal)

                        HStack(spacing: 16) {
                            Label("Left Arch", systemImage: "circle.fill").foregroundStyle(.blue)
                            Label("Right Arch", systemImage: "circle.fill").foregroundStyle(.indigo)
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

struct PressureGauge: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Text(title).font(.headline)
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 16)
                Circle()
                    .trim(from: 0, to: min(value / 300, 1))
                    .stroke(color, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.4), value: value)
                VStack(spacing: 2) {
                    Text(String(format: "%.0f", value))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.3), value: value)
                    Text("Pa").font(.caption).foregroundStyle(.secondary)
                }
            }
            .frame(width: 140, height: 140)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
