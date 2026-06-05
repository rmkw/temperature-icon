import Foundation
import SensorBridge

struct Reading {
    let name: String
    let value: Double
}

enum ExitCode: Int32 {
    case success = 0
    case failure = 1
}

let arguments = Set(CommandLine.arguments.dropFirst())

if arguments.contains("--help") || arguments.contains("-h") {
    print("""
    Usage:
      swift run temperature-cli
      swift run temperature-cli --list
      swift run temperature-cli --watch
      swift run temperature-cli --debug

    Options:
      --list    Print every temperature sensor exposed by Apple Silicon HID.
      --watch   Print the selected reading every 2 seconds.
      --debug   Print sensor discovery diagnostics.
      --help    Show this help.
    """)
    exit(ExitCode.success.rawValue)
}

func readSensors() -> [Reading] {
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

        guard item.value.isFinite, item.value > -50, item.value < 150 else {
            return nil
        }

        return Reading(name: name, value: item.value)
    }
}

func printDebug(_ readings: [Reading]) {
    print("Sensor services matched: \(temperature_sensor_last_service_count())")
    print("Last bridge error: \(temperature_sensor_last_error())")
    print("Temperature readings: \(readings.count)")
    printList(readings)
}

func selectedReading(from readings: [Reading]) -> Reading? {
    let cpuNameMarkers = [
        "cpu",
        "p-core",
        "ecore",
        "pcore",
        "tdie",
        "tp0",
        "tp1"
    ]

    let candidates = readings.filter { reading in
        let lowercased = reading.name.lowercased()
        return cpuNameMarkers.contains { lowercased.contains($0) }
    }

    return (candidates.isEmpty ? readings : candidates).max { $0.value < $1.value }
}

func printList(_ readings: [Reading]) {
    if readings.isEmpty {
        print("No temperature sensors found.")
        return
    }

    for reading in readings.sorted(by: { $0.name.localizedStandardCompare($1.name) == .orderedAscending }) {
        let paddedName = reading.name.padding(toLength: 32, withPad: " ", startingAt: 0)
        print(String(format: "%@ %6.1f°C", paddedName, reading.value))
    }
}

func printSelected(_ readings: [Reading]) {
    guard let reading = selectedReading(from: readings) else {
        print("CPU Temperature: unavailable")
        return
    }

    print(String(format: "CPU Temperature: %.1f°C (%@)", reading.value, reading.name))
}

if arguments.contains("--watch") {
    while true {
        printSelected(readSensors())
        fflush(stdout)
        Thread.sleep(forTimeInterval: 2)
    }
} else {
    let readings = readSensors()
    if arguments.contains("--debug") {
        printDebug(readings)
    } else if arguments.contains("--list") {
        printList(readings)
    } else {
        printSelected(readings)
    }
}
