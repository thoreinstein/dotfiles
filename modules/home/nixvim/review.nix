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
  };
}
