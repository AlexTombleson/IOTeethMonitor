// SensorData.swift
// IO Teeth Monitor

import Foundation

// MARK: - Bioimpedance

struct ImpedancePoint: Identifiable, Codable, Hashable {
    let id: UUID
    let frequency: Double      // Hz
    let resistance: Double     // Ohms (real part)
    let reactance: Double      // Ohms (imaginary part)

    var conductivity: Double {
        let magSq = resistance * resistance + reactance * reactance
        return magSq > 0 ? resistance / magSq : 0
    }

    var permittivity: Double {
        let magSq = resistance * resistance + reactance * reactance
        return magSq > 0 ? abs(reactance) / magSq : 0
    }

    init(id: UUID = UUID(), frequency: Double, resistance: Double, reactance: Double) {
        self.id = id
        self.frequency = frequency
        self.resistance = resistance
        self.reactance = reactance
    }
}

struct BioimpedanceSweep: Identifiable, Codable, Hashable {
    let id: UUID
    let timestamp: Date
    let points: [ImpedancePoint]

    init(id: UUID = UUID(), timestamp: Date = Date(), points: [ImpedancePoint]) {
        self.id = id
        self.timestamp = timestamp
        self.points = points
    }
}

// MARK: - Pressure & Temperature

struct ArchReading: Identifiable, Codable, Hashable {
    let id: UUID
    let timestamp: Date
    let leftPressure: Double    // Pascals
    let rightPressure: Double   // Pascals
    let leftTemp: Double        // Celsius
    let rightTemp: Double       // Celsius

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        leftPressure: Double,
        rightPressure: Double,
        leftTemp: Double,
        rightTemp: Double
    ) {
        self.id = id
        self.timestamp = timestamp
        self.leftPressure = leftPressure
        self.rightPressure = rightPressure
        self.leftTemp = leftTemp
        self.rightTemp = rightTemp
    }
}

// MARK: - Day Session

struct DaySession: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let sweeps: [BioimpedanceSweep]
    let archReadings: [ArchReading]

    var label: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }

    init(id: UUID = UUID(), date: Date, sweeps: [BioimpedanceSweep], archReadings: [ArchReading]) {
        self.id = id
        self.date = date
        self.sweeps = sweeps
        self.archReadings = archReadings
    }
}
