{ pkgs, inputs, proxy, ... }:
let
	packages = import ./packages.nix { inherit pkgs; };

in
	{
		home.packages = packages;

		manual.manpages.enable = true;

		programs.bat = {
			enable = true;
			config = {
				pager = "less -FR";
				theme = "TwoDark";
			};
			themes = {
				dracula = builtins.readFile (pkgs.fetchFromGitHub {
					owner = "dracula";
					repo = "sublime"; # Bat uses sublime syntax for its themes
					rev = "26c57ec282abcaa76e57e055f38432bd827ac34e";
					sha256 = "019hfl4zbn4vm4154hh3bwk6hm7bdxbr1hdww83nabxwjn99ndhv";
				} + "/Dracula.tmTheme");
			};
		};

		programs.bash = {
			enable = true;
			historyControl = [
				"erasedups"
				"ignoredups"
				"ignorespace"
			];
			shellAliases = {
				l = "${pkgs.coreutils}/bin/ls -halF";
				vim = "nvim";
			};
		};

		programs.zsh = {
			enable = true;
			enableAutosuggestions = true;
			enableCompletion = true;
			autocd = true;
			defaultKeymap = "emacs";
			dotDir = ".config/zsh";
			history.path = ".config/zsh/zsh_history";
			shellAliases = {
				l = "exa -halF";
				vim = "nvim";
				git = "hub";
				cat = "bat";
				find = "fd";
				ls = "exa";
				drs = "~/src/dotfiles/result/sw/bin/darwin-rebuild switch --flake . --impure";
			};
			initExtraFirst = ''
				source ~/.nix-profile/etc/profile.d/nix.sh

				autoload -U edit-command-line
				zle -N edit-command-line
				bindkey -M vicmd v edit-command-line

				export GPG_TTY="$(tty)"
				export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
				gpgconf --launch gpg-agent

				source $HOME/.config/zsh/*.zsh
				source $HOME/.secrets.zsh

				export PATH=$HOME/.local/bin:$PATH
				export PATH=$HOME/bin:$PATH
				export PATH=/Users/kon8522/.luarocks/bin:$PATH
				export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin":$PATH
			'';

			envExtra = pkgs.lib.mkIf proxy ''
				export ftp_proxy=http://127.0.0.1:3128
				export http_proxy=http://127.0.0.1:3128
				export https_proxy=http://127.0.0.1:3128
				export FTP_PROXY=http://127.0.0.1:3128
				export HTTP_PROXY=http://127.0.0.1:3128
				export HTTPS_PROXY=http://127.0.0.1:3128
			'';
		};

		programs.dircolors = {
			enable = true;
			enableBashIntegration = true;
			enableZshIntegration = true;
			extraConfig = builtins.readFile ../config/dir_colors;
		};

		programs.direnv = {
			enable = true;
			enableBashIntegration = true;
			enableZshIntegration = true;
			enableNixDirenvIntegration = true;
	};

	programs.fzf = {
		enable = true;
		enableBashIntegration = true;
		enableZshIntegration = true;
	};

	programs.git = import ./git.nix { inherit pkgs; };

	programs.gpg = {
		enable = true;
		settings = {
			personal-cipher-preferences = "AES256 AES192 AES";
			personal-digest-preferences = "SHA512 SHA384 SHA256";
			personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
			default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
			cert-digest-algo = "SHA512";
			s2k-digest-algo = "SHA512";
			s2k-cipher-algo = "AES256";
			charset = "utf-8";
			fixed-list-mode = true;
			no-comments = true;
			no-emit-version = true;
			no-greeting = true;
			keyid-format = "0xlong";
			list-options = "show-uid-validity";
			verify-options = "show-uid-validity";
			with-fingerprint = true;
			require-cross-certification = true;
			no-symkey-cache = true;
			use-agent = true;
			throw-keyids = true;
		};
	};

	programs.home-manager.enable = true;

	programs.man = {
		enable = true;
	};

	programs.neovim = import ./vim { inherit pkgs inputs; };

	programs.starship = {
		enable = true;
		enableBashIntegration = true;
		enableZshIntegration = true;
	};

	programs.tmux = {
		enable = true;
		shell = "${pkgs.zsh}/bin/zsh";
		sensibleOnTop = true;
		terminal = "screen-256color";
		shortcut = "s";
		clock24 = true;
		escapeTime = 50;
		baseIndex = 1;
		keyMode = "vi";
		plugins = with pkgs.tmuxPlugins; [
			prefix-highlight
			vim-tmux-navigator
			pain-control
		];
		extraConfig = ''
			set -g mouse on
			set -g @dracula-show-powerline true
			set -g @dracula-military-time true
			set -g @dracula-show-timezone false
			set -g @dracula-show-flags true
			set -g @dracula-show-left-icon 
			set -g @dracula-border-contrast true
			set -g @dracula-cpu-usage true
			set -g @dracula-ram-usage true

			run-shell $HOME/src/tmux/dracula.tmux
		'';
	};

	home.file = {
		".gnupg/gpg-agent.conf".source = ../config/gpg-agent.conf;
		".config/nvim" = {
			source = ../modules/vim/config;
			recursive = true;
		};
		".curlrc" = pkgs.lib.mkIf proxy {
			text = "proxy=http://127.0.0.1:3128";
		};
		".config/zsh/functions.zsh".source = ../config/functions.zsh;
		".config/spotifyd/spotifyd.conf".source = ../config/spotifyd.conf;
	};

	home.sessionVariables = {
		TERMINFO_DIRS = "/Applications/kitty.app/Contents/Resources/kitty/terminfo";                                                                                                                                             
	};
}
