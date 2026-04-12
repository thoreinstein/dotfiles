_:
{
  programs.ripgrep = {
    enable = true;
    arguments = [
      # Display options
      "--max-columns=150"
      "--max-columns-preview"

      # Search hidden files but respect .gitignore
      "--hidden"

      # Smart case searching
      "--smart-case"

      # Global exclusions
      "--glob=!.git/"
      "--glob=!node_modules/"
      "--glob=!*.min.js"
      "--glob=!*.map"
      "--glob=!dist/"
      "--glob=!build/"
      "--glob=!coverage/"
      "--glob=!vendor/"
      "--glob=!*.lock"
      "--glob=!package-lock.json"
      "--glob=!yarn.lock"
      "--glob=!pnpm-lock.yaml"
      "--glob=!.svn/"
      "--glob=!.hg/"
      "--glob=!.sass-cache/"
      "--glob=!*.swp"
      "--glob=!*.swo"
      "--glob=!*~"
      "--glob=!.DS_Store"
      "--glob=!target/"
      "--glob=!.cargo/"
      "--glob=!*.pyc"
      "--glob=!__pycache__/"
      "--glob=!.pytest_cache/"
      "--glob=!.mypy_cache/"
      "--glob=!.ruff_cache/"
      "--glob=!.cache/"
      "--glob=!.idea/"
      "--glob=!.vscode/"
      "--glob=!*.class"
      "--glob=!*.o"
      "--glob=!*.so"
      "--glob=!*.dylib"
      "--glob=!*.dll"
      "--glob=!*.exe"

      # Type definitions
      "--type-add=web:*.{html,htm,css,scss,sass,less,js,jsx,ts,tsx,json,vue,svelte}"
      "--type-add=config:*.{json,yml,yaml,toml,ini,conf,config}"
      "--type-add=docs:*.{md,markdown,txt,rst,adoc,org}"
      "--type-add=shell:*.{sh,bash,zsh,fish}"
      "--type-add=code:*.{py,js,ts,go,rs,c,cpp,h,hpp,java,rb,php,swift,kt,scala,clj}"
      "--type-add=data:*.{csv,tsv,xml,sql}"

      # Color configuration
      "--colors=path:fg:green"
      "--colors=path:style:bold"
      "--colors=line:fg:yellow"
      "--colors=line:style:bold"
      "--colors=match:fg:black"
      "--colors=match:bg:yellow"
      "--colors=match:style:nobold"

      # Encoding
      "--encoding=auto"
    ];
  };
}
