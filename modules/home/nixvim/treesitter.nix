{ pkgs, ... }:
{
  programs.nixvim.plugins.treesitter = {
    enable = true;
    settings = {
      highlight.enable = true;
      indent.enable = true;
    };
    grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
      lua
      luadoc
      printf
      vim
      vimdoc
      go
      gomod
      gosum
      gowork
      typescript
      tsx
      javascript
      svelte
      json
      yaml
      bash
      fish
      toml
      dockerfile
      terraform
      hcl
      sql
      git_config
      git_rebase
      gitcommit
      gitignore
      diff
      markdown
      markdown_inline
      html
      css
      gotmpl
      comment
      nix
    ];
  };
}
