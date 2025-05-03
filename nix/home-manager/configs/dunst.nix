{lib, ...}: {
  services.dunst = {
    enable = true;
    settings = {
      global = {
        monitor = 0;
        follow = "mouse";
        indicate_hidden = true;
        shrink = false;
        separator_height = 2;
        padding = 20;
        horizontal_padding = 20;
        frame_width = 2;
        sort = true;
        idle_threshold = 120;
        line_height = 4;
        format = "<b>%s</b>\\n%b";
        markup = "full";
        alignment = "left";
        show_age_threshold = 60;
        word_wrap = true;
        ignore_newline = false;
        stack_duplicates = false;
        hide_duplicate_count = true;
        show_indicators = false;
        icon_position = "left";
        max_icon_size = 48;
        sticky_history = true;
        history_length = 20;
        browser = "firefox -new-tab";
        always_run_script = true;
        title = "Dunst";
        class = "Dunst";
        mouse_left_click = "do_action";
        font = lib.mkForce "SFMono Nerd Font 10";
      };

      shortcuts = {
        close = "ctrl+shift+space";
        close_all = "mod4+backslash";
        context = "ctrl+shift+period";
      };

      urgency_low = {
        timeout = 5;
      };

      urgency_normal = {
        timeout = 10;
      };

      urgency_critical = {
        timeout = 15;
      };
    };
  };
}
