# Project Context: dotfiles-nix

This repository is transitioning from a GNU Stow-based dotfiles management system to a modern **Nix Flake** architecture using `nix-darwin` and `Home Manager`.

## Core Mandates

### Guardrails
- **ARCHITECTURE**: Always follow the modular structure (`hosts/`, `modules/`, `lib/`, `pkgs/`).
- **QUALITY**: No Nix code shall be committed without passing `statix`, `deadnix`, and `nixpkgs-fmt`. These are enforced via `git-hooks.nix`.
- **SECRETS**: Never commit unencrypted secrets. Use `agenix` for any sensitive configuration files.
- **NIX COMMANDS**: Always use `--extra-experimental-features 'nix-command flakes'` when running Nix commands if not already enabled in the environment.

## Knowledge Management
- **Vault Location**: `/Users/myers/Documents/second_brain/`
- **Base Path**: `working/dotfiles-nix/`
- **Implementation Plans**: `working/dotfiles-nix/plans/`
- **Knowledge Artifacts**: `working/dotfiles-nix/knowledge/`

## Project Architecture

### Directory Structure
- `hosts/`: Machine-specific entry points.
- `modules/darwin/`: macOS system-level modules.
- `modules/home/`: Host-agnostic Home Manager modules.
- `lib/`: Shared helper functions.
- `secrets/`: Encrypted secrets managed by `agenix`.

### Development Workflow
1.  **Analyze**: Create a plan in Obsidian before implementing.
2.  **Implement**: Follow the plan, keeping atomic commits per phase.
3.  **Verify**: Run `nix flake check` frequently.
4.  **Compound**: Conduct a retrospective and update knowledge artifacts after significant milestones.

## Known Traps
- **Hook Naming**: Use `github:cachix/git-hooks.nix` for pre-commit hooks. Avoid the old `nix-community` or `serokell` URLs.
- **Empty Patterns**: `statix` requires `_:` instead of `{ ... }:` for empty or unused lambda patterns.
- **Output Destructuring**: Ensure all inputs used in `outputs` are explicitly destructured (e.g., `{ self, nixpkgs, home-manager, ... }@inputs`).

## Conventions
- **Nix Style**: Use `nixpkgs-fmt` for all Nix files.
- **Theme**: Consistently use **Catppuccin Mocha** across all tool configurations.
- **CLI Organization**: Consolidate core CLI tool enablements in `modules/home/cli.nix`.
- **Hybrid Config**: Use HM `programs` options by default, supplementing with `home.file` for custom assets (themes, sidecar configs).
- **Safety First**: Always perform dry-run builds (`nix build .#homeConfigurations.<user>.activationPackage`) before considering a task ready for integration.
