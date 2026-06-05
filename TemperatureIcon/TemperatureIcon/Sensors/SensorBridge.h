#ifndef SENSOR_BRIDGE_H
#define SENSOR_BRIDGE_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    char name[128];
    double value;
} TemperatureSensorReading;

int temperature_sensor_read_all(TemperatureSensorReading *buffer, int capacity);

#ifdef __cplusplus
}
#endif

#endif
