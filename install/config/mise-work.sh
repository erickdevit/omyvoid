# Setup default work directory (and tries)
mkdir -p "$HOME/Work"
mkdir -p "$HOME/Work/tries"

if command -v mise >/dev/null 2>&1; then
  # Add ./bin to path for all items in ~/Work
  cat >"$HOME/Work/.mise.toml" <<'EOF'
[env]
_.path = "{{ cwd }}/bin"
EOF

  mise trust ~/Work/.mise.toml

  # Runtimes are installed through XBPS. Mise remains available for
  # project-local selection but never downloads a global runtime here.
fi
