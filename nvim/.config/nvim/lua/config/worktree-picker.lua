local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local M = {}

function M.find_file_in_worktrees()
  local current_file = vim.fn.expand("%:p")
  
  if current_file == "" then
    vim.notify("No file currently open", vim.log.levels.WARN)
    return
  end
  
  local git_root = vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", "")
  if vim.v.shell_error ~= 0 then
    vim.notify("Not in a git repository", vim.log.levels.ERROR)
    return
  end
  
  -- Get the common git directory (parent of all worktrees)
  local git_common_dir = vim.fn.system("git rev-parse --git-common-dir"):gsub("\n", "")
  local worktree_parent = vim.fn.fnamemodify(git_common_dir, ":h:h")
  
  -- Calculate relative path from current worktree root
  local relative_path = current_file:sub(#git_root + 2)
  
  local worktrees = {}
  local worktree_output = vim.fn.system("cd " .. vim.fn.shellescape(git_root) .. " && git worktree list --porcelain")
  
  for line in worktree_output:gmatch("[^\n]+") do
    if line:match("^worktree ") then
      local worktree_path = line:match("^worktree (.+)")
      local candidate_file = worktree_path .. "/" .. relative_path
      
      if vim.fn.filereadable(candidate_file) == 1 then
        table.insert(worktrees, {
          path = candidate_file,
          worktree = worktree_path,
          branch = vim.fn.system("cd " .. vim.fn.shellescape(worktree_path) .. " && git branch --show-current"):gsub("\n", "")
        })
      end
    end
  end
  
  if #worktrees == 0 then
    vim.notify("File not found in any worktrees", vim.log.levels.INFO)
    return
  end
  
  pickers.new({}, {
    prompt_title = "Select Worktree",
    finder = finders.new_table({
      results = worktrees,
      entry_maker = function(entry)
        local display = entry.branch .. " | " .. vim.fn.fnamemodify(entry.worktree, ":t")
        return {
          value = entry,
          display = display,
          ordinal = display,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          vim.cmd("vsplit " .. vim.fn.fnameescape(selection.value.path))
        end
      end)
      return true
    end,
  }):find()
end

return M