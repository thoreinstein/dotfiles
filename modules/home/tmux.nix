_:
{
  programs.tmux = {
    enable = true;
    mouse = true;
    keyMode = "vi";
    terminal = "tmux-256color";
    prefix = "C-Space";
    baseIndex = 1;

    extraConfig = ''
      # True color support
      set -ag terminal-overrides ",xterm-256color:RGB"

      # Session switcher
      bind -r f run-shell "~/.bin/ts"

      # Window behavior
      set-window-option -g aggressive-resize
      set -g automatic-rename off
      set -g allow-rename off
      set -g set-titles off
      setw -g pane-base-index 1
      set -g renumber-windows on

      # Now-playing plugin settings
      set -g @now-playing-status-format "{icon} {scrollable}"
      set -g @now-playing-playing-icon "♪"
      set -g @now-playing-paused-icon "⏸"
      set -g @now-playing-scrollable-format "{artist} - {title}"
      set -g @now-playing-scrollable-threshold 25

      # TPM plugins
      set -g @plugin 'rose-pine/tmux'
      set -g @plugin 'tmux-plugins/tmux-sensible'
      set -g @plugin 'tmux-plugins/tmux-yank'
      set -g @plugin 'tmux-plugins/tmux-prefix-highlight'
      set -g @plugin 'tmux-plugins/tmux-pain-control'
      set -g @plugin 'christoomey/vim-tmux-navigator'
      set -g @plugin 'spywhere/tmux-now-playing'
      set -g @plugin 'b0o/tmux-autoreload'
      set -g @plugin 'laktak/extrakto'
      set -g @plugin 'nhdaly/tmux-better-mouse-mode'
      set -g @plugin 'tmux-plugins/tpm'

      # Rose Pine theme
      set -g @rose_pine_variant 'main'
      set -g @rose_pine_date_time '''
      set -g @rose_pine_directory 'on'
      set -g @rose_pine_bar_bg_disable 'on'
      set -g @rose_pine_bar_bg_disabled_color_option 'default'
      set -g @rose_pine_show_current_program 'off'
      set -g @rose_pine_show_pane_directory 'off'
      set -g @rose_pine_default_window_behavior 'on'
      set -g @rose_pine_status_right_prepend_section '#{now_playing} '

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

      # Initialize TPM (must be last)
      run '~/.tmux/plugins/tpm/tpm'
    '';
  };
}
