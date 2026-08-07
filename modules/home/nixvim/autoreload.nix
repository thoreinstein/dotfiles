_:
{
  programs.nixvim = {
    # Files change underneath us constantly — agents edit buffers we have open.
    # Without autoread + a checktime trigger, nvim either prompts modally or
    # lets a stale buffer overwrite the agent's work on the next :w.
    opts.autoread = true;

    autoGroups.external-file-changes.clear = true;

    autoCmd = [
      {
        group = "external-file-changes";
        event = [ "CursorHold" "CursorHoldI" "FocusGained" "TermLeave" ];
        desc = "Re-stat all buffers so autoread can pick up external edits";
        callback.__raw = ''
          function()
            -- checktime errors inside the command-line window. Bare :checktime
            -- covers every buffer, not just the current one.
            if vim.fn.getcmdwintype() == "" then
              vim.cmd.checktime()
            end
          end
        '';
      }
      {
        group = "external-file-changes";
        event = [ "FileChangedShellPost" ];
        desc = "Make autoread reloads visible without a modal prompt";
        callback.__raw = ''
          function(args)
            vim.notify(
              vim.fn.fnamemodify(args.file, ":t") .. " reloaded from disk",
              vim.log.levels.INFO
            )
          end
        '';
      }
    ];
  };
}
