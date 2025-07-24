# SRE Workflow Tool

A comprehensive bash script for managing customer-facing tickets with automated git worktree, tmux session, and Obsidian note management.

## Setup

1. Ensure you have a bare git repository at `$HOME/src/<owner>/<repo>`
2. Set environment variables in your shell config or edit `config`:
   ```bash
   export VAULT_PATH="$HOME/Documents/Obsidian"  # Your Obsidian vault
   export REPO_OWNER="your-org"
   export REPO_NAME="your-repo"
   ```

3. Install the scripts:
   ```bash
   make bin
   ```

## Usage

### Starting a new ticket workflow

```bash
# Interactive mode (uses tmux popup if in tmux)
sre

# Direct mode
sre cre-123
```

This will:
1. Create a new tmux session named after the ticket
2. Create a git worktree at `<bare-repo>/<type>/<ticket-name>`
3. Create/touch an Obsidian note in your vault
4. Add a timestamped entry to your daily note
5. Setup atuin command history tracking

### Viewing ticket command history

```bash
# View in terminal
sre-history fraas-25857

# Save to file
sre-history fraas-25857 -o history.txt

# Export as markdown
sre-history fraas-25857 -f markdown -o history.md
```

### Fish shell functions

If using fish shell, additional functions are available:

```fish
# Enable command tagging for current session
ticket_atuin_setup fraas-25857

# Search commands for a ticket
ticket_atuin_search fraas-25857

# Clear ticket tracking
ticket_atuin_clear
```

## Configuration

Edit `~/.config/sre/config` to customize:
- Repository paths and default branch
- Worktree organization (by type or flat)
- Tmux window layout
- Obsidian folder mappings
- Daily note patterns

## Workflow Tips

1. **Resuming work**: Just run `sre <ticket>` again to attach to existing session
2. **Multiple tickets**: Each ticket gets its own tmux session and git worktree
3. **Command history**: All commands run in ticket sessions can be extracted later
4. **Organization**: Worktrees are organized by ticket type (fraas/, cre/, incident/)

## Directory Structure

```
$HOME/
├── src/<owner>/<repo>/          # Bare repository
│   ├── master/                  # Master branch worktree
│   ├── fraas/
│   │   └── fraas-25857/        # Feature ticket worktree
│   ├── cre/
│   │   └── cre-2107/           # CRE ticket worktree
│   └── incident/
│       └── incident-1234/       # Incident worktree
│
└── Documents/Obsidian/          # Vault
    └── Areas/Ping Identity/
        ├── Jira/
        │   ├── fraas-25857.md
        │   └── cre-2107.md
        └── Incidents/
            └── incident-1234.md
```