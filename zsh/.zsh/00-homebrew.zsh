# Detect and configure Homebrew for cross-platform compatibility
# Supports: macOS (Apple Silicon & Intel), Linux (Homebrew & Linuxbrew)

# Find Homebrew installation
if [[ -x /opt/homebrew/bin/brew ]]; then
  # macOS Apple Silicon
  HOMEBREW_PREFIX="/opt/homebrew"
elif [[ -x /usr/local/bin/brew ]]; then
  # macOS Intel
  HOMEBREW_PREFIX="/usr/local"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  # Linux (Linuxbrew)
  HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
elif command -v brew >/dev/null 2>&1; then
  # Fallback: brew in PATH
  HOMEBREW_PREFIX="$(brew --prefix)"
else
  # No Homebrew found
  return
fi

# Initialize Homebrew environment
eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"

# Load Zsh plugins if available
if [[ -f "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

if [[ -f "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
