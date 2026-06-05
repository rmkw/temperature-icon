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
int temperature_sensor_last_error(void);
int temperature_sensor_last_service_count(void);

#ifdef __cplusplus
}
#endif

#endif
