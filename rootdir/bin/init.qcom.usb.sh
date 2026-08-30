#!/vendor/bin/sh
# Copyright (c) 2012-2018, 2020-2021 The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#     * Neither the name of The Linux Foundation nor the names of its
#       contributors may be used to endorse or promote products derived
#      from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#

if [ "$(getprop persist.vendor.usb.config)" == "" -a "$(getprop ro.build.type)" != "user" -a \
	"$(getprop init.svc.vendor.usb-gadget-hal-1-0)" != "running" ]; then
	setprop persist.vendor.usb.config diag,adb
fi

# (FFBM)
if [ "$(getprop ro.bootmode)" == "ffbm-01" -o "$(getprop ro.bootmode)" == "ffbm-00" ]; then
	setprop persist.vendor.usb.config diag,adb
fi

# ConfigFS
if [ -d /config/usb_gadget ]; then
	# Якщо iSerialNumber відсутній, задаємо дефолтний для коректної роботи ADB
	serialnumber=`cat /config/usb_gadget/g1/strings/0x409/serialnumber 2> /dev/null`
	if [ "$serialnumber" == "" ]; then
		echo 1234567 > /config/usb_gadget/g1/strings/0x409/serialnumber
	fi

	product_string=`getprop ro.zuk.product.market`
	if [ "$product_string" == "" ]; then
		product_string="XiaoXin Pad 2022"
	fi
	setprop vendor.usb.product_string "$product_string"
	setprop vendor.usb.configfs 1
fi

# RNDIS Diag
diag_extra=`getprop persist.vendor.usb.config.extra`
if [ "$diag_extra" == "" ]; then
	setprop persist.vendor.usb.config.extra none
fi
