[global]
    monitor = 0
    follow = none
    width = (0, 1920)
    height = 32
    notification_limit = 1
    origin = top-center
    offset = 0x0
    progress_bar = false
    padding = 0
    horizontal_padding = 10
    text_icon_padding = 30
    frame_width = 1
    sort = urgency_descending
    font = Ubuntu 16
    format = "%p%n <big>%s</big>     |     %b"
    ignore_newline = true
    show_indicators = true
    icon_path = /usr/share/icons/gnome/48x48/status/:/usr/share/icons/gnome/48x48/devices/
    icon_theme = "{{ theme_secondary_name }}, {{ theme_primary_name }}"
    enable_recursive_icon_lookup = true
    dmenu = "/usr/bin/dmenu -p dunst -m 0 -fn 'Ubuntu-20' -nf '#ffffff' -sb '{{ theme_primary_color }}'"
    mouse_left_click = close_current
    mouse_middle_click= do_action
    mouse_right_click = close_all
    icon_position = left
    min_icon_size = 32
    max_icon_size = 32
    ellipsize = end
    markup = full

[urgency_low]
    background = "#2E3440"
    foreground = "#ffffff"
    frame_color = "{{ theme_primary_color }}"
    timeout = 3

[urgency_normal]
    background = "#2E3440"
    foreground = "#ffffff"
    frame_color = "{{ theme_primary_color }}"
    timeout = 5

[urgency_critical]
    background = "#2E3440"
    foreground = "#ffffff"
    frame_color = "#900000"
    timeout = 10