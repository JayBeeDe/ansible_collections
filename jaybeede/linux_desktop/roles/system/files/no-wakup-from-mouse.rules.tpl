ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="usb", ATTRS{idVendor}=="{{ mouse_vendor }}", ATTR{power/wakeup}="disabled"
