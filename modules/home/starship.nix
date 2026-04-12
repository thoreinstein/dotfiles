_:
{
  programs.starship = {
    enable = true;
    settings = {
      format = "$directory$git_branch$git_status$custom$fill$cmd_duration$line_break$character";
      right_format = "$hostname";

      character = {
        success_symbol = " (bold green)";
        error_symbol = " (bold red)";
      };

      directory = {
        truncate_to_repo = false;
        truncation_symbol = "…/";
        truncation_length = 4;
        style = "bold cyan";
      };

      git_branch = {
        symbol = " ";
        style = "bold purple";
        format = " [$symbol$branch(:$remote_branch)]($style) ";
      };

      git_status = {
        style = "bold yellow";
        format = "([$all_status$ahead_behind]($style) )";
        conflicted = "=";
        ahead = " \${count} ";
        behind = " \${count} ";
        diverged = "󰹹  \${ahead_count}  \${behind_count} ";
        untracked = " \${count} ";
        stashed = "󰆓 ";
        modified = " \${count} ";
        staged = "󰐕 \${count} ";
        renamed = "󰹳 ";
        deleted = "󰆴 ";
      };

      cmd_duration = {
        min_time = 2000;
        style = "bold yellow";
        format = " [$duration]($style)";
      };

      hostname = {
        ssh_only = true;
        style = "bold dimmed white";
        format = "[$hostname]($style)";
      };

      username = {
        show_always = false;
        style_user = "bold dimmed white";
        format = "[$user]($style_user)@";
      };

      gcloud.disabled = true;
      ruby.disabled = true;
      golang.disabled = true;
      terraform.disabled = true;
      nodejs.disabled = true;
      python.disabled = true;
      package.disabled = true;

      custom.gcloud = {
        command = "echo $PROJECT_NAME";
        when = ''[ -n "$PROJECT_NAME" ]'';
        symbol = "󱇶 ";
        style = "bold blue";
        format = "[$symbol($output)]($style) ";
      };
    };
  };
}
