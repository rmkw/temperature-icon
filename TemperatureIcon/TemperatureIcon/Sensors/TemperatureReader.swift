import Foundation

struct TemperatureReading {
    let name: String
    let value: Double
}

enum TemperatureReader {
    static func currentCPUReading() -> TemperatureReading? {
        let readings = allReadings()

        let dieReadings = readings.filter { reading in
            let name = reading.name.lowercased()
            return name.hasPrefix("pmu tdie") || name.hasPrefix("pmu2 tdie")
        }

        return (dieReadings.isEmpty ? readings : dieReadings).max { $0.value < $1.value }
    }

    private static func allReadings() -> [TemperatureReading] {
        let capacity = 256
        let buffer = UnsafeMutablePointer<TemperatureSensorReading>.allocate(capacity: capacity)
        defer { buffer.deallocate() }

        let count = temperature_sensor_read_all(buffer, Int32(capacity))
        guard count > 0 else {
            return []
        }

        return (0..<Int(count)).compactMap { index in
            let item = buffer[index]
            let name = withUnsafePointer(to: item.name) { pointer in
                pointer.withMemoryRebound(to: CChar.self, capacity: MemoryLayout.size(ofValue: item.name)) { cString in
                    String(cString: cString)
                }
            }

            guard item.value.isFinite, item.value > 0, item.value < 130 else {
                return nil
            }

            return TemperatureReading(name: name, value: item.value)
        }
    }
}
