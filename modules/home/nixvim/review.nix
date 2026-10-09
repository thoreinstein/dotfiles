_:
{
  programs.nixvim = {
    # Reviewing an agent changeset is walking a list, not hunting a directory.
    # Quickfix composes with navigation this config already has: <leader>cn,
    # <leader>cp, ]q, [q, and <leader>xQ to view the same list in Trouble.
    userCommands.QfGitChanged = {
      desc = "Load files changed vs a rev (default HEAD), plus untracked, into quickfix";
      nargs = "?";
      command.__raw = ''
        function(cmd)
          local rev = cmd.args ~= "" and cmd.args or "HEAD"

          local function git(args)
            local out = vim.fn.systemlist(vim.list_extend({ "git" }, args))
            if vim.v.shell_error ~= 0 then
              return nil, table.concat(out, "\n")
            end
            return out, nil
          end

          local root, err = git({ "rev-parse", "--show-toplevel" })
          if not root then
            vim.notify("QfGitChanged: not a git repository\n" .. err, vim.log.levels.ERROR)
            return
          end
          root = root[1]

          local items = {}
          local seen = {}

          local function add(path, status)
            if path == "" or seen[path] then
              return
            end
            seen[path] = true
            table.insert(items, {
              filename = root .. "/" .. path,
              lnum = 1,
              col = 1,
              text = status,
            })
          end

          -- Tracked changes. --name-status gives us the status letter for free.
          local changed, changed_err = git({ "diff", "--name-status", "--diff-filter=ACMR", rev })
          if not changed then
            vim.notify("QfGitChanged: git diff failed\n" .. changed_err, vim.log.levels.ERROR)
            return
          end
          for _, line in ipairs(changed) do
            -- Renames and copies arrive as "R100<TAB>old<TAB>new"; the score
            -- suffix is optional and the new path is the one worth reviewing.
            local status, rest = line:match("^(%a)%d*%s+(.+)$")
            if rest then
              add(rest:match("([^\t]+)$"), status)
            end
          end

          -- Untracked files. Agents create these constantly and
          -- `git diff` never reports them.
          local untracked = git({ "ls-files", "--others", "--exclude-standard" })
          for _, path in ipairs(untracked or {}) do
            add(path, "?")
          end

          if #items == 0 then
            vim.notify("QfGitChanged: no changes vs " .. rev, vim.log.levels.INFO)
            return
          end

          vim.fn.setqflist({}, "r", {
            title = "Changed vs " .. rev,
            items = items,
          })
          vim.cmd.copen()
        end
      '';
    };

    # Findings also show as diagnostics on their lines, so they read next to
    # the code; ]d / [d jump between them with the full text in a float.
    extraConfigLua = ''
      local wb_review_ns = vim.api.nvim_create_namespace("wb_review")
      local wb_review_severity = {
        blocking = vim.diagnostic.severity.ERROR,
        ["should-fix"] = vim.diagnostic.severity.WARN,
        nit = vim.diagnostic.severity.HINT,
      }

      -- items: quickfix items (from setqflist input or getqflist output).
      function _G.WbReviewDiagnostics(items)
        vim.diagnostic.reset(wb_review_ns)
        local by_buf = {}
        for _, it in ipairs(items) do
          local bufnr = it.bufnr or vim.fn.bufadd(it.filename)
          vim.fn.bufload(bufnr)
          local severity, message = it.text:match("^(%S+): (.+)$")
          by_buf[bufnr] = by_buf[bufnr] or {}
          table.insert(by_buf[bufnr], {
            lnum = it.lnum - 1,
            col = 0,
            severity = wb_review_severity[severity] or vim.diagnostic.severity.INFO,
            message = message or it.text,
            source = "wb review",
          })
        end
        for bufnr, diags in pairs(by_buf) do
          vim.diagnostic.set(wb_review_ns, bufnr, diags)
        end
      end
    '';

    # Findings from `wb review` (see workbench) live in <git-dir>/wb/. The
    # quickfix list is the triage surface; `dd` in it writes removals back to
    # the findings file so `wb review --post` only sends what was kept.
    userCommands.PrReview = {
      desc = "Diff vs review base + wb review findings in quickfix";
      command.__raw = ''
        function()
          local function git(args)
            local out = vim.fn.systemlist(vim.list_extend({ "git" }, args))
            if vim.v.shell_error ~= 0 then
              return nil, table.concat(out, "\n")
            end
            return out, nil
          end

          local gitdir, err = git({ "rev-parse", "--absolute-git-dir" })
          if not gitdir then
            vim.notify("PrReview: not a git repository\n" .. err, vim.log.levels.ERROR)
            return
          end
          local top = git({ "rev-parse", "--show-toplevel" })
          if not top then
            vim.notify("PrReview: not in a worktree", vim.log.levels.ERROR)
            return
          end
          local root = top[1]
          local dir = gitdir[1] .. "/wb"

          if vim.fn.filereadable(dir .. "/meta") == 0 then
            vim.notify("PrReview: no review yet (run wb review)", vim.log.levels.WARN)
            return
          end
          local meta = {}
          for _, l in ipairs(vim.fn.readfile(dir .. "/meta")) do
            local k, v = l:match("^(%w+)=(.*)$")
            if k then
              meta[k] = v
            end
          end

          local findings = dir .. "/findings"
          local items = {}
          if vim.fn.filereadable(findings) == 1 then
            for _, l in ipairs(vim.fn.readfile(findings)) do
              local path, lnum, text = l:match("^(.-):(%d+): (.+)$")
              if path then
                table.insert(items, {
                  filename = root .. "/" .. path,
                  lnum = tonumber(lnum),
                  text = text,
                  user_data = l,
                })
              end
            end
          end

          vim.fn.setqflist({}, "r", {
            title = "PR review",
            items = items,
            context = { wb_findings = findings },
          })
          WbReviewDiagnostics(items)
          -- Quickfix stays in this tab as the index; diffview opens its own tab.
          vim.cmd("copen 15")
          vim.wo.wrap = true
          -- --imply-local: the HEAD side is the real files, so the findings
          -- diagnostics show in the diff.
          vim.cmd("DiffviewOpen " .. meta.base .. "...HEAD --imply-local")
          vim.notify(("PrReview: %d findings shown in the code (]d / [d), list in previous tab, diff vs %s"):format(#items, meta.base))
        end
      '';
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>gq";
        action = "<cmd>QfGitChanged<cr>";
        options.desc = "Changed files → quickfix";
      }
      {
        mode = "n";
        key = "<leader>xq";
        action.__raw = ''
          function()
            vim.diagnostic.setqflist({ open = true })
          end
        '';
        options.desc = "Workspace diagnostics → quickfix";
      }
    ];

    autoCmd = [
      {
        event = "FileType";
        pattern = "qf";
        desc = "dd drops a PrReview finding and saves the list";
        callback.__raw = ''
          function(ev)
            vim.keymap.set("n", "dd", function()
              if vim.fn.getwininfo(vim.api.nvim_get_current_win())[1].loclist == 1 then
                return
              end
              local info = vim.fn.getqflist({ context = 0, items = 0, title = 0 })
              local ctx = info.context
              if type(ctx) ~= "table" or not ctx.wb_findings then
                return
              end
              local idx = vim.fn.line(".")
              table.remove(info.items, idx)
              vim.fn.setqflist({}, "r", { title = info.title, items = info.items, context = ctx })
              WbReviewDiagnostics(info.items)
              local lines = {}
              for _, it in ipairs(info.items) do
                table.insert(lines, it.user_data)
              end
              vim.fn.writefile(lines, ctx.wb_findings)
              if #info.items > 0 then
                vim.api.nvim_win_set_cursor(0, { math.min(idx, #info.items), 0 })
              end
            end, { buffer = ev.buf, desc = "Drop PR review finding" })
          end
        '';
      }
    ];
  };
}
