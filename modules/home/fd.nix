_:
{
  programs.fd = {
    enable = true;
    ignores = [
      # Version control
      ".git/"
      ".hg/"
      ".svn/"

      # Dependencies and package managers
      "node_modules/"
      "bower_components/"
      "vendor/"
      ".cargo/"
      "target/"
      "*.egg-info/"
      ".tox/"
      ".venv/"
      "venv/"
      "env/"
      "virtualenv/"

      # Build outputs
      "dist/"
      "build/"
      "out/"
      "*.o"
      "*.so"
      "*.dylib"
      "*.dll"
      "*.exe"
      "*.class"
      "*.pyc"
      "__pycache__/"
      ".pytest_cache/"
      ".mypy_cache/"
      ".ruff_cache/"

      # IDE and editor files
      ".idea/"
      ".vscode/"
      "*.swp"
      "*.swo"
      "*~"
      ".DS_Store"

      # Cache and temporary files
      ".cache/"
      ".sass-cache/"
      "*.log"
      "*.tmp"
      ".temp/"
      "tmp/"

      # Coverage and test reports
      "coverage/"
      "htmlcov/"
      ".coverage"
      "*.cover"
      ".hypothesis/"
      ".nyc_output/"

      # Documentation builds
      "docs/_build/"
      "site/"

      # Compressed files
      "*.zip"
      "*.tar"
      "*.tar.gz"
      "*.tgz"
      "*.rar"
      "*.7z"

      # Minified files
      "*.min.js"
      "*.min.css"
      "*.map"
    ];
  };
}
