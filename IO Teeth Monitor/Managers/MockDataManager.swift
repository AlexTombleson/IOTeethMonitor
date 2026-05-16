// MockDataManager.swift
// IO Teeth Monitor
//  Created by Alexandra Tombleson 5/16/26.
import Foundation
import Combine

final class MockDataManager: ObservableObject {

    @Published var sessions: [DaySession] = []
    @Published var latestReading: ArchReading?
    @Published var isConnected: Bool = false
    @Published var statusMessage: String = "Disconnected"

    private var liveTimer: AnyCancellable?
    private let frequencies: [Double] = {
        // 48 log-spaced points from 1kHz to 1MHz
        (0..<48).map { i in
            let logMin = log10(1_000.0)
            let logMax = log10(1_000_000.0)
            return pow(10, logMin + (logMax - logMin) * Double(i) / 47)
        }
    }()

    func connect() {
        statusMessage = "Connecting to IO-Tooth…"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            self.isConnected = true
            self.statusMessage = "Connected · IO-Tooth v1.0 (mock)"
            self.sessions = self.generateWeekOfData()
            self.startLiveReadings()
        }
    }

    func disconnect() {
        liveTimer?.cancel()
        isConnected = false
        statusMessage = "Disconnected"
    }

    // MARK: - Live pressure/temp stream

    private func startLiveReadings() {
        liveTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.latestReading = ArchReading(
                    leftPressure:  Double.random(in: 180...220),
                    rightPressure: Double.random(in: 175...215),
                    leftTemp:      Double.random(in: 36.3...36.9),
                    rightTemp:     Double.random(in: 36.2...36.8)
                )
            }
    }

    // MARK: - Mock data generation

    private func generateWeekOfData() -> [DaySession] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            return DaySession(
                date: date,
                sweeps: generateDailySweeps(for: date, dayOffset: daysAgo),
                archReadings: generateDayReadings(for: date)
            )
        }
    }

    private func generateDailySweeps(for date: Date, dayOffset: Int) -> [BioimpedanceSweep] {
        let calendar = Calendar.current
        let times = [8, 13, 20]  // morning, afternoon, evening
        let dayDrift = Double(dayOffset) * 0.02  // subtle tissue change over days

        return times.map { hour in
            let timestamp = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date)!
            let points = frequencies.map { freq -> ImpedancePoint in
                let logF = log10(freq)
                // Realistic oral tissue Cole-Cole inspired model
                let baseR = 600 - 300 * (1 - exp(-logF / 3)) + dayDrift * 50
                let baseX = -120 * exp(-pow(logF - 4.5, 2) / 1.5) + dayDrift * 20
                let noise = Double.random(in: -5...5)
                return ImpedancePoint(
                    frequency: freq,
                    resistance: max(10, baseR + noise),
                    reactance: min(-1, baseX + noise)
                )
            }
            return BioimpedanceSweep(timestamp: timestamp, points: points)
        }
    }

    private func generateDayReadings(for date: Date) -> [ArchReading] {
        let calendar = Calendar.current
        return (0..<24).map { hour in
            let timestamp = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date)!
            return ArchReading(
                timestamp: timestamp,
                leftPressure:  Double.random(in: 160...240),
                rightPressure: Double.random(in: 155...235),
                leftTemp:      Double.random(in: 36.0...37.2),
                rightTemp:     Double.random(in: 35.9...37.1)
            )
        }
    }
}
