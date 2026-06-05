# TemperatureIcon

Minimal native macOS menu bar app that shows the current Apple Silicon CPU/SoC temperature.

![App icon](TemperatureIcon/DesignAssets/AppIcon-Source.png)

The Xcode project is named `TemperatureIcon`; the installed app appears as `CPU Temperature`.

Current menu bar format:

```text
CPU 45°C
```

## Screenshot

![TemperatureIcon in the menu bar](TemperatureIcon/DesignAssets/menu-bar-screenshot.png)

The screenshot is a cropped strip of the macOS menu bar. The app does not open a main window.

## Compatibility

- macOS 14 or later.
- Apple Silicon Mac.
- Tested locally on a MacBook Air Apple Silicon where macOS exposed `PMU tdie*` and `PMU2 tdie*` sensors.
- Not intentionally limited to M4. The HID/IOKit method may work on other Apple Silicon M-series chips, but it is not guaranteed on every model.
- Intel Macs are not supported in the current implementation.

## Limitations

Apple does not provide a public stable API for reading Apple Silicon CPU/SoC temperature in Celsius. TemperatureIcon uses undocumented HID/IOKit sensor paths.

That means:

- Sensor names can change between M1, M2, M3, M4, and future generations.
- The app displays a representative die/SoC reading, not an official per-core temperature.
- It may stop working if Apple changes sensor access or permissions in a future macOS release.
- App Sandbox is disabled because HID/IOKit sensor reading may fail inside the sandbox.

## Project Structure

```text
TemperatureIcon/TemperatureIcon/
  App/
    TemperatureIconApp.swift
  Monitoring/
    TemperatureMonitor.swift
  Sensors/
    TemperatureReader.swift
    SensorBridge.c
    SensorBridge.h
    TemperatureIcon-Bridging-Header.h
  Views/
    ContentView.swift
  Assets.xcassets/
Sources/
  SensorBridge/
  temperature-cli/
```

## Main Components

- `TemperatureIcon/TemperatureIcon/App/TemperatureIconApp.swift`: app entry point and `MenuBarExtra`.
- `TemperatureIcon/TemperatureIcon/Monitoring/TemperatureMonitor.swift`: current reading, 5-second timer, and menu bar formatting.
- `TemperatureIcon/TemperatureIcon/Sensors/TemperatureReader.swift`: chooses the CPU/SoC sensor reading.
- `TemperatureIcon/TemperatureIcon/Sensors/SensorBridge.c`: low-level HID/IOKit sensor access.
- `Sources/temperature-cli`: minimal CLI prototype used to validate sensor access before building the SwiftUI app.

## Run the App

Open:

```text
TemperatureIcon/TemperatureIcon.xcodeproj
```

Select the `TemperatureIcon` scheme and press Run.

The app uses `LSUIElement`, so it appears only in the menu bar and not in the Dock.

## CLI Prototype

Build:

```sh
swift build
```

List detected temperature sensors:

```sh
.build/debug/temperature-cli --list
```

Print the selected CPU/SoC reading:

```sh
.build/debug/temperature-cli
```

## Privacy and Security

Local review before sharing:

- No network requests.
- No `URLSession`, sockets, or HTTP APIs.
- No external command execution.
- No access to user documents.
- No Keychain usage.
- No tokens, secrets, or credentials.
- Only reads temperature sensors via HID/IOKit and updates menu bar text.

## References

- [Stats](https://github.com/exelban/stats) documents that Apple Silicon CPU/GPU sensors are thermal zones and that Apple changes sensor keys between SoCs.
- [mactop](https://github.com/metaspartan/mactop) uses `IOKit` / `IOHIDEventSystemClient` for Apple Silicon monitoring.
- [apple_sensors write-up](https://blog.paul-goldschmidt.de/read-cpu-gpu-chip-temperature-on-m1-m2-m3-macs-apple-silicon-under-macos-sonoma/) explains the HID approach for reading temperatures on M-series Macs.

## License

MIT
