# Function to show atuin session info for current ticket
function sre_atuin_info
    if test -n "$argv[1]"
        set ticket $argv[1]
        echo "Atuin session tracking for ticket: $ticket"
        echo "Use Ctrl-R and cycle to 'session' filter mode to see commands from this session"
        echo "Or use 'directory' filter mode to see commands from the worktree"
    else
        echo "Usage: sre_atuin_info <ticket-number>"
    end
end

# Function to search commands by directory (worktree path)
function sre_atuin_search_dir
    if test -n "$argv[1]"
        set ticket $argv[1]
        # Assumes standard worktree structure
        set worktree_path "$HOME/src/*/repo/*/$ticket"
        if test -d $worktree_path[1]
            cd $worktree_path[1]
            echo "Searching atuin history for directory: $worktree_path[1]"
            atuin search --filter-mode directory
        else
            echo "Worktree not found for ticket: $ticket"
        end
    else
        echo "Usage: sre_atuin_search_dir <ticket-number>"
    end
end

# Function to show session ID if available
function sre_session_id
    if test -n "$ATUIN_SESSION"
        echo "Current Atuin session ID: $ATUIN_SESSION"
    else
        echo "No Atuin session ID available"
    end
end