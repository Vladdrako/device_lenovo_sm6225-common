#! /vendor/bin/sh

# Copyright (c) 2012-2013,2016,2018-2021 The Linux Foundation. All rights reserved.
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

export PATH=/vendor/bin

# 1. Display size from DRM or Framebuffer
if [ -f /sys/class/drm/card0-DSI-1/modes ]; then
	echo "detect" > /sys/class/drm/card0-DSI-1/status
	read -r line < /sys/class/drm/card0-DSI-1/modes
	fb_width=${line%%x*}
elif [ -f /sys/class/graphics/fb0/virtual_size ]; then
	res=`cat /sys/class/graphics/fb0/virtual_size` 2> /dev/null
	fb_width=${res%,*}
fi

log -t BOOT -p i "Early boot initialization for Bengal platform"

# 2. DRM vblankoffdelay
vbfile=/sys/module/drm/parameters/vblankoffdelay
if [ -w $vbfile ]; then
	echo -1 > $vbfile
fi

# 3. LCD density
if [ -z "$(getprop vendor.display.lcd_density)" ]; then
	if [ -z "$fb_width" ]; then
		setprop vendor.display.lcd_density 320
	elif [ $fb_width -ge 1600 ]; then
		setprop vendor.display.lcd_density 640
	elif [ $fb_width -ge 1440 ]; then
		setprop vendor.display.lcd_density 560
	elif [ $fb_width -ge 1080 ]; then
		setprop vendor.display.lcd_density 480
	else
		setprop vendor.display.lcd_density 320
	fi
fi

# 4. DRM Netflix
setprop vendor.netflix.bsp_rev "Q6115-31409-1"

# 5. Disable ATFWD
setprop persist.vendor.radio.atfwd.start false

# 6. Display perms
if [ -e /sys/class/lcd_bias/secure_mode ]; then
	chown -h system.graphics /sys/class/lcd_bias/secure_mode
	chmod 0660 /sys/class/lcd_bias/secure_mode
fi

if [ -e /sys/class/leds/wled/secure_mode ]; then
	chown -h system.graphics /sys/class/leds/wled/secure_mode
	chmod 0660 /sys/class/leds/wled/secure_mode
fi

# 7. Alarm Boot
boot_reason=`cat /proc/sys/kernel/boot_reason 2>/dev/null`
reboot_reason=`getprop ro.boot.alarmboot`
if [ "$boot_reason" = "3" ] || [ "$reboot_reason" = "true" ]; then
	setprop ro.vendor.alarm_boot true
else
	setprop ro.vendor.alarm_boot false
fi

# 8. GPU
if [ -f /sys/class/kgsl/kgsl-3d0/gpu_available_frequencies ]; then
	gpu_freq=`cat /sys/class/kgsl/kgsl-3d0/gpu_available_frequencies` 2> /dev/null
	setprop vendor.gpu.available_frequencies "$gpu_freq"
fi
