#! /vendor/bin/sh

# Copyright (c) 2012-2013, 2016-2020, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

function configure_memory_parameters() {
    # If ZRAM was not initialized in early boot, initialize it:
    if ! grep -q '^/dev/block/zram0 ' /proc/swaps; then
        read -r _ mem_kb _ < /proc/meminfo
        if [ "$mem_kb" -lt 4800000 ]; then
            zRamSizeMB=3072
        else
            zRamSizeMB=4096
        fi
        [ -f /sys/block/zram0/comp_algorithm ] && echo lz4kd > /sys/block/zram0/comp_algorithm
        [ -f /sys/block/zram0/disksize ] && echo "${zRamSizeMB}M" > /sys/block/zram0/disksize
        mkswap /dev/block/zram0
        swapon /dev/block/zram0 -p 32758
    fi

    if [ -f /sys/module/vmpressure/parameters/allocstall_threshold ]; then
        echo 0 > /sys/module/vmpressure/parameters/allocstall_threshold
    fi

    echo 1 > /proc/sys/vm/page-cluster
    echo 100 > /proc/sys/vm/watermark_scale_factor

    read -r _ mem_kb _ < /proc/meminfo
    if [ "$mem_kb" -lt 4800000 ]; then
        # 4GB
        echo 80 > /proc/sys/vm/swappiness
    else
        # 6GB
        echo 60 > /proc/sys/vm/swappiness
    fi
    echo 100 > /proc/sys/vm/vfs_cache_pressure

    if [ -f /sys/kernel/mm/lru_gen/min_ttl_ms ]; then
        echo 1000 > /sys/kernel/mm/lru_gen/min_ttl_ms
    fi
    if [ -d /sys/block/mmcblk0 ]; then
        echo mq-deadline > /sys/block/mmcblk0/queue/scheduler 2>/dev/null
        echo 512 > /sys/block/mmcblk0/bdi/read_ahead_kb 2>/dev/null
        echo 512 > /sys/block/mmcblk0/queue/read_ahead_kb 2>/dev/null
    fi
    if [ -d /sys/block/mmcblk0rpmb ]; then
        echo 512 > /sys/block/mmcblk0rpmb/bdi/read_ahead_kb 2>/dev/null
    fi
    for dm in /sys/block/dm-*/queue/read_ahead_kb; do
        [ -f "$dm" ] && echo 512 > "$dm"
    done
}

# Core control parameters on big cluster
echo 0 > /sys/devices/system/cpu/cpu0/core_ctl/enable
echo 2 > /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
echo 40 > /sys/devices/system/cpu/cpu4/core_ctl/busy_down_thres
echo 60 > /sys/devices/system/cpu/cpu4/core_ctl/busy_up_thres
echo 100 > /sys/devices/system/cpu/cpu4/core_ctl/offline_delay_ms
echo 4 > /sys/devices/system/cpu/cpu4/core_ctl/task_thres

# Setting b.L scheduler parameters
echo 65 > /proc/sys/kernel/sched_downmigrate
echo 71 > /proc/sys/kernel/sched_upmigrate
echo 85 > /proc/sys/kernel/sched_group_downmigrate
echo 100 > /proc/sys/kernel/sched_group_upmigrate

# cpuset settings
echo 0-3 > /dev/cpuset/background/cpus
echo 0-3 > /dev/cpuset/system-background/cpus

# configure governor settings for little cluster
echo "schedutil" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 1000 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/up_rate_limit_us
echo 20000 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/down_rate_limit_us
echo 1190400 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/hispeed_freq
echo 691200 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
echo 0 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/rtg_boost_freq

# configure governor settings for big cluster
echo "schedutil" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor
echo 10000 > /sys/devices/system/cpu/cpu4/cpufreq/schedutil/up_rate_limit_us
echo 20000 > /sys/devices/system/cpu/cpu4/cpufreq/schedutil/down_rate_limit_us
echo 1766400 > /sys/devices/system/cpu/cpu4/cpufreq/schedutil/hispeed_freq
echo 300000 > /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq
echo 0 > /sys/devices/system/cpu/cpu4/cpufreq/schedutil/rtg_boost_freq

echo 1 > /proc/sys/kernel/sched_walt_rotate_big_tasks

# sched_load_boost as -6 is equivalent to target load as 85. It is per cpu tunable.
echo -6 > /sys/devices/system/cpu/cpu0/sched_load_boost
echo -6 > /sys/devices/system/cpu/cpu1/sched_load_boost
echo -6 > /sys/devices/system/cpu/cpu2/sched_load_boost
echo -6 > /sys/devices/system/cpu/cpu3/sched_load_boost
echo -6 > /sys/devices/system/cpu/cpu4/sched_load_boost
echo -6 > /sys/devices/system/cpu/cpu5/sched_load_boost
echo -6 > /sys/devices/system/cpu/cpu6/sched_load_boost
echo -6 > /sys/devices/system/cpu/cpu7/sched_load_boost
echo 90 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/hispeed_load
echo 90 > /sys/devices/system/cpu/cpu4/cpufreq/schedutil/hispeed_load

# Set Memory parameters
configure_memory_parameters

# Enable bus-dcvs
for device in /sys/devices/platform/soc
do
    for cpubw in $device/*cpu-cpu-ddr-bw/devfreq/*cpu-cpu-ddr-bw
    do
        echo "bw_hwmon" > $cpubw/governor
        echo 50 > $cpubw/polling_interval
        echo 762 > $cpubw/min_freq
        echo "2288 3440 4173 5195 5859 7759 10322 11863 13763 15960" > $cpubw/bw_hwmon/mbps_zones
        echo 85 > $cpubw/bw_hwmon/io_percent
        echo 4 > $cpubw/bw_hwmon/sample_ms
        echo 90 > $cpubw/bw_hwmon/decay_rate
        echo 190 > $cpubw/bw_hwmon/bw_step
        echo 20 > $cpubw/bw_hwmon/hist_memory
        echo 0 > $cpubw/bw_hwmon/hyst_length
        echo 80 > $cpubw/bw_hwmon/down_thres
        echo 0 > $cpubw/bw_hwmon/guard_band_mbps
        echo 250 > $cpubw/bw_hwmon/up_scale
        echo 1600 > $cpubw/bw_hwmon/idle_mbps
    done
done

for d in /sys/class/devfreq/soc:qcom,cpu*-cpu-ddr-lat*; do
    [ -f $d/governor ] && echo "mem_latency" > $d/governor
done

# colocation v3 disabled
echo 0 > /proc/sys/kernel/sched_min_task_util_for_boost
echo 0 > /proc/sys/kernel/sched_min_task_util_for_colocation

# Turn off scheduler boost at the end
echo 0 > /proc/sys/kernel/sched_boost

echo N > /sys/module/lpm_levels/system/pwr/pwr-l2-gdhs/idle_enabled
echo N > /sys/module/lpm_levels/system/perf/perf-l2-gdhs/idle_enabled
echo N > /sys/module/lpm_levels/system/pwr/pwr-l2-gdhs/suspend_enabled
echo N > /sys/module/lpm_levels/system/perf/perf-l2-gdhs/suspend_enabled

# Turn on sleep modes
echo 0 > /sys/module/lpm_levels/parameters/sleep_disabled

# Touch Boost - optimized for battery and responsiveness
echo "0:1190400 1:1190400 2:1190400 3:1190400 4:0 5:0 6:0 7:0" > /sys/devices/system/cpu/cpu_boost/input_boost_freq
echo 20 > /sys/devices/system/cpu/cpu_boost/input_boost_ms
echo 0 > /sys/devices/system/cpu/cpu_boost/sched_boost_on_input

setprop vendor.post_boot.parsed 1
