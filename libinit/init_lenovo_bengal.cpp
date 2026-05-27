/*
 * Copyright (C) 2021 The LineageOS Project
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <libinit_dalvik_heap.h>
#include <libinit_utils.h>

#include "vendor_init.h"

void vendor_load_properties() {
    set_dalvik_heap();

    // Android 16 QPR2 spoofing - bypass VINTF checks
    // Raise system version to Android 16
    property_override("ro.build.version.sdk", "36");
    property_override("ro.build.version.release", "16");
    property_override("ro.build.version.security_patch", "2025-06-01");
    property_override("ro.system.build.version.sdk", "36");
    property_override("ro.system.build.version.release", "16");

    // Keep vendor at lower level for compatibility (Android 14)
    property_override("ro.vendor.build.version.sdk", "34");
    property_override("ro.vendor.build.version.release", "14");
    property_override("ro.board.api_level", "34"); // Must match vendor SDK 34

    // Keep original factory launch API level (Android 11 for Xiaoxin Pad 2022)
    property_override("ro.product.first_api_level", "30");
}
