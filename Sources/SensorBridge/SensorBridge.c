#include "SensorBridge.h"

#include <CoreFoundation/CoreFoundation.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

typedef struct __IOHIDEvent *IOHIDEventRef;
typedef struct __IOHIDEventSystemClient *IOHIDEventSystemClientRef;
typedef struct __IOHIDServiceClient *IOHIDServiceClientRef;

#if __LP64__
typedef double IOHIDFloat;
#else
typedef float IOHIDFloat;
#endif

extern IOHIDEventSystemClientRef IOHIDEventSystemClientCreate(CFAllocatorRef allocator);
extern int IOHIDEventSystemClientSetMatching(IOHIDEventSystemClientRef client, CFDictionaryRef match);
extern CFArrayRef IOHIDEventSystemClientCopyServices(IOHIDEventSystemClientRef client);
extern IOHIDEventRef IOHIDServiceClientCopyEvent(IOHIDServiceClientRef service, int64_t type, int32_t options, int64_t timestamp);
extern CFTypeRef IOHIDServiceClientCopyProperty(IOHIDServiceClientRef service, CFStringRef property);
extern IOHIDFloat IOHIDEventGetFloatValue(IOHIDEventRef event, int32_t field);

#define IOHID_EVENT_FIELD_BASE(type) ((type) << 16)
#define IOHID_EVENT_TYPE_TEMPERATURE 15

static int last_error = 0;
static int last_service_count = 0;

static CFDictionaryRef create_matching_dictionary(int page, int usage) {
    CFStringRef keys[2];
    CFNumberRef values[2];

    keys[0] = CFSTR("PrimaryUsagePage");
    keys[1] = CFSTR("PrimaryUsage");
    values[0] = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &page);
    values[1] = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &usage);

    CFDictionaryRef dictionary = CFDictionaryCreate(
        kCFAllocatorDefault,
        (const void **)keys,
        (const void **)values,
        2,
        &kCFTypeDictionaryKeyCallBacks,
        &kCFTypeDictionaryValueCallBacks
    );

    CFRelease(values[0]);
    CFRelease(values[1]);

    return dictionary;
}

static void copy_sensor_name(IOHIDServiceClientRef service, char *destination, size_t destination_size) {
    if (destination_size == 0) {
        return;
    }

    destination[0] = '\0';

    CFTypeRef product = IOHIDServiceClientCopyProperty(service, CFSTR("Product"));
    if (product != NULL && CFGetTypeID(product) == CFStringGetTypeID()) {
        Boolean ok = CFStringGetCString((CFStringRef)product, destination, destination_size, kCFStringEncodingUTF8);
        if (!ok) {
            snprintf(destination, destination_size, "unknown");
        }
    } else {
        snprintf(destination, destination_size, "unknown");
    }

    if (product != NULL) {
        CFRelease(product);
    }
}

static int read_matching_page(int page, int usage, TemperatureSensorReading *buffer, int capacity) {
    if (buffer == NULL || capacity <= 0) {
        return 0;
    }

    CFDictionaryRef matching = create_matching_dictionary(page, usage);
    if (matching == NULL) {
        last_error = -1;
        return -1;
    }

    IOHIDEventSystemClientRef client = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
    if (client == NULL) {
        CFRelease(matching);
        last_error = -2;
        return -2;
    }

    IOHIDEventSystemClientSetMatching(client, matching);
    CFArrayRef services = IOHIDEventSystemClientCopyServices(client);
    CFRelease(matching);

    if (services == NULL) {
        CFRelease(client);
        last_error = -3;
        return -3;
    }

    CFIndex service_count = CFArrayGetCount(services);
    last_service_count += (int)service_count;
    int written = 0;

    for (CFIndex i = 0; i < service_count && written < capacity; i++) {
        IOHIDServiceClientRef service = (IOHIDServiceClientRef)CFArrayGetValueAtIndex(services, i);
        if (service == NULL) {
            continue;
        }

        IOHIDEventRef event = IOHIDServiceClientCopyEvent(service, IOHID_EVENT_TYPE_TEMPERATURE, 0, 0);
        if (event == NULL) {
            continue;
        }

        copy_sensor_name(service, buffer[written].name, sizeof(buffer[written].name));
        buffer[written].value = IOHIDEventGetFloatValue(event, IOHID_EVENT_FIELD_BASE(IOHID_EVENT_TYPE_TEMPERATURE));
        written += 1;

        CFRelease(event);
    }

    CFRelease(services);
    CFRelease(client);

    return written;
}

int temperature_sensor_read_all(TemperatureSensorReading *buffer, int capacity) {
    last_error = 0;
    last_service_count = 0;

    if (buffer == NULL || capacity <= 0) {
        return 0;
    }

    int written = read_matching_page(0xff00, 0x0005, buffer, capacity);
    if (written < 0) {
        return written;
    }

    if (written < capacity) {
        int additional = read_matching_page(0xff05, 0x0005, buffer + written, capacity - written);
        if (additional < 0 && written == 0) {
            return additional;
        }
        if (additional > 0) {
            written += additional;
        }
    }

    if (written > 0) {
        last_error = 0;
    }

    return written;
}

int temperature_sensor_last_error(void) {
    return last_error;
}

int temperature_sensor_last_service_count(void) {
    return last_service_count;
}
