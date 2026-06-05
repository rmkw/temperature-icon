import SwiftUI
import AppKit

@main
struct TemperatureIconApp: App {
    @StateObject private var monitor = TemperatureMonitor()

    var body: some Scene {
        MenuBarExtra {
            Text(monitor.detailTitle)
            Text("Sensor: \(monitor.sensorName)")

            Divider()

            Button("Refresh") {
                monitor.refresh()
            }

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            Text(monitor.menuBarTitle)
                .monospacedDigit()
        }
        .menuBarExtraStyle(.menu)
    }
}
