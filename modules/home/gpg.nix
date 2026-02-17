{ pkgs, ... }:
{
  programs.gpg = {
    enable = true;

    settings = {
      # HM already defaults the drduh cipher/digest/compress/keyid prefs.
      # These are the settings that go beyond those defaults.
      no-greeting = true;
      require-secmem = true;
      armor = true;
      use-agent = true;
      throw-keyids = true;
    };

    scdaemonSettings = {
      disable-ccid = true;
    };

    dirmngrSettings = {
      keyserver = "hkps://keys.openpgp.org";
    };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    enableZshIntegration = true;
    defaultCacheTtl = 60;
    maxCacheTtl = 120;
    pinentry.package = pkgs.pinentry_mac;
  };

  home.packages = with pkgs; [
    yubikey-manager
    yubikey-personalization
  ];
}
