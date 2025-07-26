# Machine-Specific Configurations

This directory contains machine-specific overrides and configurations.

## Usage

To add machine-specific settings, create a file named `<hostname>.nix` in this directory.
The hostname should match the output of `hostname -s` on the target machine.

## Setting Up a New Machine

1. **Add to flake.nix**: Define the machine in the `machines` attribute set:
```nix
machines = {
  "work-laptop" = {
    system = "aarch64-darwin";  # or "x86_64-darwin" for Intel
    hostname = "work-laptop";
    username = "john.doe";      # Your username on this machine
  };
};
```

2. **Create machine-specific config** (optional): Create `work-laptop.nix`:
```nix
{ config, pkgs, ... }:
{
  # Machine-specific settings here
  homebrew.casks = [
    "slack"
    "microsoft-teams"
  ];
}
```

3. **Deploy**: Run `make darwin` on the target machine.

This file will be automatically imported if it exists for the current hostname.