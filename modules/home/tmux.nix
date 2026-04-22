{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;

    baseIndex = 1;
    clock24 = true;
    keyMode = "vi";
    mouse = true;
    prefix = "C-Space";
    sensibleOnTop = true;
    terminal = "tmux-256color";

    plugins = with pkgs; [
      tmuxPlugins.better-mouse-mode
      tmuxPlugins.extrakto
      tmuxPlugins.pain-control
      tmuxPlugins.prefix-highlight
      tmuxPlugins.tmux-which-key
      tmuxPlugins.vim-tmux-navigator
      tmuxPlugins.yank
      {
        plugin = tmuxPlugins.rose-pine;
        extraConfig = ''
          set -g @rose_pine_variant 'main'
          set -g @rose_pine_date_time '''
          set -g @rose_pine_directory 'on'
          set -g @rose_pine_bar_bg_disable 'on'
          set -g @rose_pine_bar_bg_disabled_color_option 'default'
          set -g @rose_pine_show_current_program 'off'
          set -g @rose_pine_show_pane_directory 'off'
          set -g @rose_pine_default_window_behavior 'on'
        '';
      }
    ];

    extraConfig = ''
      # True color support
      set -ag terminal-overrides ",xterm-256color:RGB"

      # Let Claude Code notification/progress escape sequences reach Ghostty/iTerm/etc.
      set -g allow-passthrough on

      # Session switcher
      bind -r f run-shell "ts"

      # Turn on extended keys support
      set -g extended-keys on
      set -g extended-keys-format csi-u

      # Window behavior
      set-window-option -g aggressive-resize
      set -g automatic-rename off
      set -g allow-rename off
      set -g set-titles off
      set -g renumber-windows on

      # Alt+Number window switching (no prefix)
      bind-key -n M-1 select-window -t 1
      bind-key -n M-2 select-window -t 2
      bind-key -n M-3 select-window -t 3
      bind-key -n M-4 select-window -t 4
      bind-key -n M-5 select-window -t 5
      bind-key -n M-6 select-window -t 6
      bind-key -n M-7 select-window -t 7
      bind-key -n M-8 select-window -t 8
      bind-key -n M-9 select-window -t 9
    '';
  };
}
