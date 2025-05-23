[global_config]
  window_state = maximise
  borderless = False
  title_transmit_bg_color = "{{ theme_secondary_color }}"
  title_receive_bg_color = "{{ theme_secondary_color }}"
  title_inactive_bg_color = "{{ theme_primary_color }}"
  enabled_plugins = Logger, LaunchpadBugURLHandler, LaunchpadCodeURLHandler, APTURLHandler
  suppress_multiple_term_dialog = True
[keybindings]
[profiles]
  [[default]]
    icon_bell = False
    cursor_color = "#aaaaaa"
    font = Ubuntu Mono 14
    scrollback_infinite = True
    use_system_font = False
[layouts]
  [[default]]
    [[[window0]]]
      type = Window
      parent = ""
    [[[child1]]]
      type = Terminal
      parent = window0
[plugins]
