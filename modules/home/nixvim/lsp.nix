_:
{
  programs.nixvim = {
    plugins.lsp = {
      enable = true;

      servers = {
        lua_ls = {
          enable = true;
          settings = {
            Lua = {
              workspace = {
                library = [
                  "\${vim.fn.expand(\"$VIMRUNTIME/lua\")}"
                  "\${3rd}/luv/library"
                ];
              };
            };
          };
        };

        gopls = {
          enable = true;
          settings = {
            gopls = {
              completeUnimported = true;
              usePlaceholders = true;
              buildFlags = [ ];
              analyses = {
                unusedparams = true;
                unreachable = true;
                fillstruct = true;
                nonewvars = true;
                undeclaredname = true;
                unusedwrite = true;
                unusedvariable = true;
                ST1000 = false;
              };
              staticcheck = true;
              gofumpt = true;
              codelenses = {
                gc_details = false;
                generate = true;
                regenerate_cgo = true;
                run_govulncheck = true;
                test = true;
                tidy = true;
                upgrade_dependency = true;
                vendor = true;
              };
              hints = {
                assignVariableTypes = true;
                compositeLiteralFields = true;
                compositeLiteralTypes = true;
                constantValues = true;
                functionTypeParameters = true;
                parameterNames = true;
                rangeVariableTypes = true;
              };
            };
          };
        };

        ts_ls = {
          enable = true;
          extraOptions.init_options = {
            hostInfo = "neovim";
          };
        };

        svelte = {
          enable = true;
        };

        pyright = {
          enable = true;
        };

        rust_analyzer = {
          enable = true;
          installCargo = false;
          installRustc = false;
        };

        taplo = {
          enable = true;
        };

        nil_ls = {
          enable = true;
        };
      };

      onAttach = ''
        local map = vim.keymap.set
        local function opts(desc)
          return { buffer = bufnr, desc = desc }
        end

        -- goto (g prefix, standard vim convention)
        map("n", "gd", vim.lsp.buf.definition, opts "Go to definition")
        map("n", "gD", vim.lsp.buf.declaration, opts "Go to declaration")
        map("n", "gi", vim.lsp.buf.implementation, opts "Go to implementation")
        map("n", "gr", vim.lsp.buf.references, opts "References")

        -- hover (standard K)
        map("n", "K", vim.lsp.buf.hover, opts "Hover")

        -- diagnostics ([ ] navigation)
        map("n", "[d", vim.diagnostic.goto_prev, opts "Prev diagnostic")
        map("n", "]d", vim.diagnostic.goto_next, opts "Next diagnostic")

        -- code actions (<leader>c group)
        map("n", "<leader>ck", vim.lsp.buf.signature_help, opts "Signature help")
        map("n", "<leader>cr", vim.lsp.buf.rename, opts "Rename")

        -- diagnostics (<leader>x group)
        map("n", "<leader>xe", vim.diagnostic.open_float, opts "Show diagnostic float")
        map("n", "<leader>xl", vim.diagnostic.setloclist, opts "Diagnostic loclist")

        if client.supports_method("textDocument/semanticTokens") then
          client.server_capabilities.semanticTokensProvider = nil
        end
      '';
    };

    diagnostics = {
      virtual_text = false;
      signs = true;
      underline = true;
      update_in_insert = false;
      severity_sort = true;
    };

    extraConfigLua = ''
      local signs = { Error = "󰅚 ", Warn = "󰀪 ", Hint = "󰌶 ", Info = " " }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
      end

      -- Helm filetype detection
      vim.api.nvim_create_autocmd("BufRead", {
        pattern = "*/templates/*.yaml",
        callback = function()
          vim.bo.filetype = "helm"
        end,
      })

      -- Svelte TS/JS change notification
      local svelte_group = vim.api.nvim_create_augroup("svelte-lsp", { clear = true })
      vim.api.nvim_create_autocmd("BufWritePost", {
        group = svelte_group,
        pattern = { "*.js", "*.cjs", "*.mjs", "*.ts", "*.cts", "*.mts", "*.jsx", "*.tsx" },
        callback = function(args)
          for _, client in ipairs(vim.lsp.get_clients { name = "svelte" }) do
            client.notify("$/onDidChangeTsOrJsFile", { uri = vim.uri_from_bufnr(args.buf) })
          end
        end,
      })
    '';
  };
}
