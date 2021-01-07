{ pkgs ? import <nixpkgs> { } }:
''
  set -g default-terminal "screen-256color"

  # change prefix command to C-z
  set -g prefix C-s
  unbind C-b
  bind C-s last-window
  bind z send-prefix

  # Turn on mouse support
  setw -g mouse on

  # Allow xterm titles in terminal window, terminal scrolling with scrollbar, and setting overrides of C-Up, C-Down, C-Left, C-Right
  set -g terminal-overrides "xterm*:XT:smcup@:rmcup@:kUP5=\eOA:kDN5=\eOB:kLFT5=\eOD:kRIT5=\eOC"

  # Scroll History
  set -g history-limit 30000

  # Set ability to capture on start and restore on exit window data when running an application
  setw -g alternate-screen on

  # Lower escape timing from 500ms to 50ms for quicker response to scroll-buffer access.
  set -s escape-time 50

  # setup | and - for window splitting
  unbind %
  bind | split-window -h -c "#{pane_current_path}"
  bind - split-window -v -c "#{pane_current_path}"

  bind c new-window -c "#{pane_current_path}"

  # Use emacs / readline key-bindings at the tmux command prompt `<prefix>:`
  set -g status-keys emacs

  # Use vim keybindings in copy mode
  setw -g mode-keys vi
  bind-key -T copy-mode-vi v send -X begin-selection
  bind-key -T copy-mode-vi y send -X copy-pipe-and-cancel "pbcopy"
  unbind -T copy-mode-vi Enter
  bind-key -T copy-mode-vi Enter send -X copy-pipe-and-cancel "pbcopy"
  unbind -T copy-mode-vi Space
  bind -T copy-mode-vi Space send -X jump-again
  bind-key -T copy-mode-vi 0 send -X back-to-indentation
  bind y run 'tmux save-buffer - | pbcopy '
  bind C-y run 'tmux save-buffer - | pbcopy '

  # Smart pane switching with awareness of Vim splits.
  # See: https://github.com/christoomey/vim-tmux-navigator
  is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
      | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
      bind-key -n C-h if-shell "$is_vim" "send-keys C-h"  "select-pane -L"
      bind-key -n C-j if-shell "$is_vim" "send-keys C-j"  "select-pane -D"
      bind-key -n C-k if-shell "$is_vim" "send-keys C-k"  "select-pane -U"
      bind-key -n C-l if-shell "$is_vim" "send-keys C-l"  "select-pane -R"
      bind-key -n 'C-\' if-shell "$is_vim" "send-keys C-\\" "select-pane -l"
      bind-key -T copy-mode-vi C-h select-pane -L
      bind-key -T copy-mode-vi C-j select-pane -D
      bind-key -T copy-mode-vi C-k select-pane -U
      bind-key -T copy-mode-vi C-l select-pane -R
      bind-key -T copy-mode-vi 'C-\' select-pane -l

  # colors
  set -g default-terminal "screen-256color"

  # start window numbering at 1 for easier switching
  set -g base-index 1
  setw -g pane-base-index 1

  # start numbering at 1
  set -g base-index 1

  set -g @plugin 'tmux-plugins/tpm'
  set -g @plugin 'janders223/nord-tmux'

  run '~/.tmux/plugins/tpm/tpm'
''
