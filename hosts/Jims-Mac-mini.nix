_:
{
  programs.pi-coding-agent = {
    settings = {
      defaultProvider = "anthropic";
      defaultModel = "claude-opus-5";
    };

    # Explicitly empty so nix owns models.json and the stale `chicago` ollama
    # provider at 192.168.4.56 is cleared. No local models are run on this host.
    models.providers = { };
  };
}
