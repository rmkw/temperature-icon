import Foundation
import Combine

@MainActor
final class TemperatureMonitor: ObservableObject {
    @Published private(set) var reading: TemperatureReading?

    private var timer: Timer?

    var menuBarTitle: String {
        guard let reading else {
            return "CPU --°C"
        }

        let rounded = Int(reading.value.rounded())
        return String(format: "CPU %02d°C", rounded)
    }

    var detailTitle: String {
        guard let reading else {
            return "CPU Temperature: unavailable"
        }

        return String(format: "CPU Temperature: %.1f°C", reading.value)
    }

    var sensorName: String {
        reading?.name ?? "No sensor selected"
    }

    init() {
        start()
    }

    func start() {
        guard timer == nil else {
            return
        }

        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func refresh() {
        reading = TemperatureReader.currentCPUReading()
    }
}
