_:
{
  programs.nixvim.keymaps = [
    # Better escape
    { mode = "i"; key = "jk"; action = "<Esc>"; options.desc = "Exit insert mode"; }
    { mode = "i"; key = "jj"; action = "<Esc>"; options.desc = "Exit insert mode"; }

    # Better navigation
    { mode = "n"; key = "<C-d>"; action = "<C-d>zz"; options.desc = "Scroll down and center"; }
    { mode = "n"; key = "<C-u>"; action = "<C-u>zz"; options.desc = "Scroll up and center"; }
    { mode = "n"; key = "n"; action = "nzzzv"; options.desc = "Next search result centered"; }
    { mode = "n"; key = "N"; action = "Nzzzv"; options.desc = "Previous search result centered"; }

    # Buffer navigation
    { mode = "n"; key = "<S-h>"; action = "<cmd>bprevious<cr>"; options.desc = "Previous buffer"; }
    { mode = "n"; key = "<S-l>"; action = "<cmd>bnext<cr>"; options.desc = "Next buffer"; }
    { mode = "n"; key = "<leader>bd"; action = "<cmd>bdelete<cr>"; options.desc = "Delete buffer"; }

    # Window management
    { mode = "n"; key = "<leader>wv"; action = "<C-w>v"; options.desc = "Split window vertically"; }
    { mode = "n"; key = "<leader>ws"; action = "<C-w>s"; options.desc = "Split window horizontally"; }
    { mode = "n"; key = "<leader>we"; action = "<C-w>="; options.desc = "Equalize window sizes"; }
    { mode = "n"; key = "<leader>wc"; action = "<C-w>c"; options.desc = "Close current window"; }

    # Resize windows with arrows
    { mode = "n"; key = "<C-Up>"; action = "<cmd>resize +2<cr>"; options.desc = "Increase window height"; }
    { mode = "n"; key = "<C-Down>"; action = "<cmd>resize -2<cr>"; options.desc = "Decrease window height"; }
    { mode = "n"; key = "<C-Left>"; action = "<cmd>vertical resize -2<cr>"; options.desc = "Decrease window width"; }
    { mode = "n"; key = "<C-Right>"; action = "<cmd>vertical resize +2<cr>"; options.desc = "Increase window width"; }

    # Move lines up/down
    { mode = "v"; key = "J"; action = ":m '>+1<cr>gv=gv"; options.desc = "Move selection down"; }
    { mode = "v"; key = "K"; action = ":m '<-2<cr>gv=gv"; options.desc = "Move selection up"; }

    # Better indenting (stay in visual mode)
    { mode = "v"; key = "<"; action = "<gv"; options.desc = "Indent left and reselect"; }
    { mode = "v"; key = ">"; action = ">gv"; options.desc = "Indent right and reselect"; }

    # Keep cursor in place when joining lines
    { mode = "n"; key = "J"; action = "mzJ`z"; options.desc = "Join lines without moving cursor"; }

    # Clear search highlighting
    { mode = "n"; key = "<Esc>"; action = "<cmd>nohlsearch<cr>"; options.desc = "Clear search highlight"; }

    # Quickfix navigation
    { mode = "n"; key = "<leader>cn"; action = "<cmd>cnext<cr>zz"; options.desc = "Next quickfix item"; }
    { mode = "n"; key = "<leader>cp"; action = "<cmd>cprev<cr>zz"; options.desc = "Previous quickfix item"; }
    { mode = "n"; key = "<leader>co"; action = "<cmd>copen<cr>"; options.desc = "Open quickfix list"; }
    { mode = "n"; key = "<leader>cc"; action = "<cmd>cclose<cr>"; options.desc = "Close quickfix list"; }

    # Yank to end of line
    { mode = "n"; key = "Y"; action = "y$"; options.desc = "Yank to end of line"; }

    # Paste without losing register content
    { mode = "x"; key = "<leader>p"; action = ''"_dP''; options.desc = "Paste without yanking"; }

    # Delete without yanking
    { mode = [ "n" "v" ]; key = "<leader>d"; action = ''"_d''; options.desc = "Delete without yanking"; }

    # Quick save
    { mode = "n"; key = "<C-s>"; action = "<cmd>w<cr>"; options.desc = "Save file"; }
    { mode = "i"; key = "<C-s>"; action = "<Esc><cmd>w<cr>"; options.desc = "Save file"; }

    # Quick quit
    { mode = "n"; key = "<leader>Q"; action = "<cmd>qa<cr>"; options.desc = "Quit all"; }
  ];
}
