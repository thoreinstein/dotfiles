{ pkgs, ... }:
let
  # The nix nvim wrapper execs nvim with unquoted `--cmd set rtp^=/nix/store/…` args,
  # which resurrect can't replay. Save plain `nvim <file>` instead. Resurrect skips
  # unchanged saves by comparing its raw save to `last`, which this rewrite already
  # changed, so drop the new save here when it matches the previous one.
  resurrectPostSave = pkgs.writeShellScript "resurrect-post-save" ''
    dir=~/.local/share/tmux/resurrect
    new=$(readlink -f "$dir/last")
    ${pkgs.gnused}/bin/sed -i -E "s#[^:\t]*/bin/nvim( --cmd set [^ \t]+)*#nvim#" "$new"
    prev=$(ls -t "$dir"/tmux_resurrect_*.txt | sed -n 2p)
    if [ -n "$prev" ] && cmp -s "$new" "$prev"; then
      rm "$new"
      ln -sf "$(basename "$prev")" "$dir/last"
    fi
  '';

  # Fuzzy-pick an open session, most recently used first, previewing its active pane.
  # ctrl-x kills the highlighted session and reloads the list.
  sessionPicker = pkgs.writeShellScript "tmux-session-picker" ''
    current=$(tmux display-message -p '#S')
    list="tmux list-sessions -F '#{session_last_attached} #S' | sort -rn | cut -d' ' -f2- | grep -vxF '$current'"
    session=$(eval "$list" \
      | ${pkgs.fzf}/bin/fzf --tmux 80%,70% --layout=reverse --prompt='Session > ' \
          --header 'ctrl-x: kill session' \
          --bind "ctrl-x:execute-silent(tmux kill-session -t \"=\"{})+reload($list)" \
          --preview 'tmux capture-pane -ep -t "="{}:' --preview-window=right,60%) || exit 0
    tmux switch-client -t "=$session"
  '';
in
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
      {
        plugin = tmuxPlugins.resurrect;
        extraConfig = ''
          set -g @resurrect-dir '~/.local/share/tmux/resurrect'
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-hook-post-save-all '${resurrectPostSave}'
        '';
      }
      # Must stay last: continuum's autosave rides on status-right, which rose-pine resets.
      {
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '5'
        '';
      }
    ];

    extraConfig = ''
      # True color support
      set -ag terminal-overrides ",xterm-256color:RGB"

      # Let Claude Code and pi notification/progress escape sequences reach Ghostty/iTerm/etc.
      # "all" rather than "on": "on" drops them from panes that aren't visible, which is
      # exactly when a "done" notification matters.
      set -g allow-passthrough all

      # Session switcher
      bind -r f run-shell "ts"
      bind s run-shell "${sessionPicker}"
      bind S choose-tree -Zs

      # Turn on extended keys support
      set -g extended-keys on
      set -g extended-keys-format csi-u

      set -g history-limit 10000

      set -g focus-events on

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
