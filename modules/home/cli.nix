{ pkgs, ... }:
{
  home.packages = with pkgs; [
    codefresh
    codespell
    dolt
    gitleaks
    # `gcloud components install` can't write to the nix store; declare components here.
    (google-cloud-sdk.withExtraComponents (with google-cloud-sdk.components; [
      gcloud-crc32c
      gke-gcloud-auth-plugin
    ]))
    k9s
    nodejs
    pkg-config
    poppler-utils
    presenterm
    terminal-notifier
    uv
    yq-go
  ];

  programs = {
    asciinema = {
      enable = true;
    };
    fzf = {
      enable = true;
      enableZshIntegration = true;
      historyWidget.command = ""; # atuin owns Ctrl-R
      tmux.enableShellIntegration = true;
    };
    jq.enable = true;
  };
}
