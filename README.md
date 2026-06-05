# TemperatureCLI

Prueba minima para leer sensores reales de temperatura en Apple Silicon desde una herramienta CLI escrita en Swift, con un puente C para acceder a HID/IOKit.

## Requisitos

- Mac Apple Silicon.
- macOS con Command Line Tools o Xcode instalado.
- Swift 6.

## Compilar

```sh
swift build
```

Si SwiftPM intenta escribir caches fuera del proyecto y falla, usa:

```sh
env CLANG_MODULE_CACHE_PATH=.build/ModuleCache SWIFTPM_HOME=.build/swiftpm swift build --scratch-path .build
```

## Ejecutar

Listar todos los sensores de temperatura encontrados:

```sh
.build/debug/temperature-cli --list
```

Ver diagnostico de descubrimiento:

```sh
.build/debug/temperature-cli --debug
```

Imprimir una lectura seleccionada por heuristica:

```sh
.build/debug/temperature-cli
```

Actualizar cada 2 segundos:

```sh
.build/debug/temperature-cli --watch
```

## Interpretacion

La salida de `--list` es la importante en la primera fase. Apple no publica un mapa estable de sensores para Apple Silicon, asi que primero hay que ver que nombres expone tu MacBook Air.

Ejemplos de nombres que podrian ser relevantes para CPU:

- `CPU`
- `tdie`
- `Tp0`
- `Tp1`
- sensores del cluster de performance o efficiency

Si `--debug` muestra `Sensor services matched: 0`, la app no esta viendo sensores HID desde ese contexto de ejecucion. Pruebalo desde Terminal normal, no desde un sandbox ni desde un entorno remoto.

## Nota tecnica

Esta prueba usa APIs/rutas no documentadas de HID/IOKit. Eso es aceptable para validar viabilidad y para distribucion directa, pero puede ser fragil entre versiones de macOS y generaciones M1/M2/M3/M4/M5.
