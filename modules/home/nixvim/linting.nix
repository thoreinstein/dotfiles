{ pkgs, ... }:
{
  programs.nixvim = {
    plugins.lint = {
      enable = true;
      lintersByFt = {
        javascript = [ "eslint_d" ];
        svelte = [ "eslint_d" ];
        typescript = [ "eslint_d" ];
        javascriptreact = [ "eslint_d" ];
        typescriptreact = [ "eslint_d" ];
        python = [ "flake8" ];
        go = [ "golangcilint" ];
        sh = [ "shellcheck" ];
        bash = [ "shellcheck" ];
        markdown = [ "markdownlint" ];
        yaml = [ "yamllint" ];
      };
      autoCmd = {
        event = [ "BufEnter" "BufWritePost" "InsertLeave" ];
        callback.__raw = ''
          function()
            require("lint").try_lint()
          end
        '';
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>cl";
        action.__raw = ''
          function()
            require("lint").try_lint()
          end
        '';
        options.desc = "Lint buffer";
      }
      {
        mode = "n";
        key = "<leader>l";
        action.__raw = ''
          function()
            require("lint").try_lint()
          end
        '';
        options.desc = "Trigger linting for current file";
      }
    ];

    extraPackages = with pkgs; [
      golangci-lint
      eslint_d
      shellcheck
      markdownlint-cli
      yamllint
      python3Packages.flake8
    ];
  };
}
