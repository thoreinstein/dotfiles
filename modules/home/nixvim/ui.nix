{ pkgs, ... }:
{
  programs.nixvim = {
    colorschemes.rose-pine = {
      enable = true;
      settings = {
        styles = {
          transparency = true;
        };
      };
    };

    plugins = {
      lualine = {
        enable = true;
        settings = {
          options = {
            icons_enabled = true;
            theme = "auto";
            component_separators = { left = ""; right = ""; };
            section_separators = { left = ""; right = ""; };
            disabled_filetypes = {
              statusline = [ ];
              winbar = [ ];
            };
            ignore_focus = [ ];
            always_divide_middle = true;
            always_show_tabline = true;
            globalstatus = false;
            refresh = {
              statusline = 100;
              tabline = 100;
              winbar = 100;
            };
          };
          sections = {
            lualine_a = [ "mode" ];
            lualine_b = [ "branch" "diff" "diagnostics" ];
            lualine_c = [ "filename" ];
            lualine_x = [ "encoding" "fileformat" "filetype" ];
            lualine_y = [ "progress" ];
            lualine_z = [ "location" ];
          };
          inactive_sections = {
            lualine_a = [ ];
            lualine_b = [ ];
            lualine_c = [ "filename" ];
            lualine_x = [ "location" ];
            lualine_y = [ ];
            lualine_z = [ ];
          };
          tabline = { };
          winbar = { };
          inactive_winbar = { };
          extensions = [ ];
        };
      };

      which-key = {
        enable = true;
        settings = {
          plugins = {
            spelling = true;
          };
          defaults = {
            mode = [ "n" "v" ];
          };
        };
        registrations = {
          "<leader>b" = "buffer";
          "<leader>c" = "code";
          "<leader>d" = "debug";
          "<leader>e" = "explorer";
          "<leader>f" = "find";
          "<leader>g" = "git";
          "<leader>h" = "hunk";
          "<leader>o" = "octo";
          "<leader>r" = "refactor";
          "<leader>s" = "search/replace";
          "<leader>w" = "window";
          "<leader>x" = "diagnostics";
          "[" = "prev";
          "]" = "next";
          "g" = "goto";
        };
      };

      trouble = {
        enable = true;
        settings = {
          modes = {
            symbols = {
              win = {
                position = "right";
                size = { width = 50; };
              };
            };
          };
        };
      };

      fidget = {
        enable = true;
        settings = {
          notification = {
            window = {
              winblend = 0;
              border = "none";
              zindex = 45;
              max_width = 0;
              max_height = 0;
              x_padding = 1;
              y_padding = 0;
              align = "bottom";
              relative = "editor";
            };
          };
        };
      };

      indent-blankline.enable = true;

      web-devicons.enable = true;

      todo-comments = {
        enable = true;
        settings = {
          signs = true;
          keywords = {
            FIX = { icon = " "; color = "error"; alt = [ "FIXME" "BUG" "FIXIT" "ISSUE" ]; };
            TODO = { icon = " "; color = "info"; };
            HACK = { icon = " "; color = "warning"; };
            WARN = { icon = " "; color = "warning"; alt = [ "WARNING" "XXX" ]; };
            PERF = { icon = " "; alt = [ "OPTIM" "PERFORMANCE" "OPTIMIZE" ]; };
            NOTE = { icon = " "; color = "hint"; alt = [ "INFO" ]; };
            TEST = { icon = "⏲ "; color = "test"; alt = [ "TESTING" "PASSED" "FAILED" ]; };
          };
        };
      };

      lspsaga = {
        enable = true;
        settings = {
          symbol_in_winbar = {
            folder_level = 3;
          };
        };
      };

      lsp-signature = {
        enable = true;
      };
    };

    keymaps = [
      # Trouble
      { mode = "n"; key = "<leader>xx"; action = "<cmd>Trouble diagnostics toggle<cr>"; options.desc = "Diagnostics (Trouble)"; }
      { mode = "n"; key = "<leader>xX"; action = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>"; options.desc = "Buffer Diagnostics (Trouble)"; }
      { mode = "n"; key = "<leader>cs"; action = "<cmd>Trouble symbols toggle focus=false<cr>"; options.desc = "Symbols (Trouble)"; }
      { mode = "n"; key = "<leader>xL"; action = "<cmd>Trouble loclist toggle<cr>"; options.desc = "Location List (Trouble)"; }
      { mode = "n"; key = "<leader>xQ"; action = "<cmd>Trouble qflist toggle<cr>"; options.desc = "Quickfix List (Trouble)"; }
      {
        mode = "n"; key = "[q";
        action.__raw = ''
          function()
            if require("trouble").is_open() then
              require("trouble").prev({ skip_groups = true, jump = true })
            else
              local ok, err = pcall(vim.cmd.cprev)
              if not ok then vim.notify(err, vim.log.levels.ERROR) end
            end
          end
        '';
        options.desc = "Previous Trouble/Quickfix Item";
      }
      {
        mode = "n"; key = "]q";
        action.__raw = ''
          function()
            if require("trouble").is_open() then
              require("trouble").next({ skip_groups = true, jump = true })
            else
              local ok, err = pcall(vim.cmd.cnext)
              if not ok then vim.notify(err, vim.log.levels.ERROR) end
            end
          end
        '';
        options.desc = "Next Trouble/Quickfix Item";
      }

      # Todo-comments
      { mode = "n"; key = "]t"; action.__raw = ''function() require("todo-comments").jump_next() end''; options.desc = "Next TODO"; }
      { mode = "n"; key = "[t"; action.__raw = ''function() require("todo-comments").jump_prev() end''; options.desc = "Previous TODO"; }
      { mode = "n"; key = "<leader>xt"; action = "<cmd>Trouble todo<cr>"; options.desc = "TODOs (Trouble)"; }
      { mode = "n"; key = "<leader>st"; action = "<cmd>TodoTelescope<cr>"; options.desc = "Search TODOs"; }

      # Lspsaga
      { mode = "n"; key = "<leader>cf"; action = "<cmd>Lspsaga finder<cr>"; options.desc = "LSP finder"; }
      { mode = "n"; key = "<leader>cp"; action = "<cmd>Lspsaga peek_definition<cr>"; options.desc = "Peek definition"; }
      { mode = "n"; key = "<leader>cP"; action = "<cmd>Lspsaga peek_type_definition<cr>"; options.desc = "Peek type definition"; }
      { mode = "n"; key = "<leader>co"; action = "<cmd>Lspsaga outline<cr>"; options.desc = "Toggle outline"; }
      { mode = "n"; key = "<leader>ci"; action = "<cmd>Lspsaga incoming_calls<cr>"; options.desc = "Incoming calls"; }
      { mode = "n"; key = "<leader>cO"; action = "<cmd>Lspsaga outgoing_calls<cr>"; options.desc = "Outgoing calls"; }
      { mode = "n"; key = "<leader>ch"; action = "<cmd>Lspsaga hover_doc<cr>"; options.desc = "Hover doc"; }
      { mode = [ "n" "v" ]; key = "<leader>ca"; action = "<cmd>Lspsaga code_action<cr>"; options.desc = "Code action"; }
    ];
  };
}
