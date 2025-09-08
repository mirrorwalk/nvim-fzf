#!/usr/bin/env bash

CONFIG_DIR="$HOME/.config/nvim-fzf"
CONFIG_FILE="$CONFIG_DIR/config"

# If config file doesn't exist, help the user set it up
if [ ! -f "$CONFIG_FILE" ]; then
  echo "⚠️  Config file not found at: $CONFIG_FILE"
  read -rp "Do you want me to create a template config for you? [y/N] " reply
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_FILE" <<EOF
# Example config for nvim-fzf
# One entry per line

[roots]
\$HOME/projects
\$HOME/notes
\$HOME/.config/nixos

[ignore]
.git
node_modules
target
.direnv
EOF
    echo "✅ Created template config at $CONFIG_FILE"
    echo "Opening directory so you can edit it..."
    cd "$CONFIG_DIR" || exit 1
    exec ${EDITOR:-nvim} config
  else
    echo "❌ No config, exiting."
    exit 1
  fi
fi

# --- Parse config ---
roots=()
ignore=()

section=""
while IFS= read -r line || [ -n "$line" ]; do
  [[ -z "$line" || "$line" =~ ^# ]] && continue

  if [[ "$line" == "[roots]" ]]; then
    section="roots"
    continue
  elif [[ "$line" == "[ignore]" ]]; then
    section="ignore"
    continue
  fi

  if [[ "$section" == "roots" ]]; then
    roots+=("${line/#\~/$HOME}")
    roots+=("${line//\$HOME/$HOME}")
  elif [[ "$section" == "ignore" ]]; then
    ignore+=("$line")
  fi
done < "$CONFIG_FILE"

# Build prune expression
prune_expr=()
for pat in "${ignore[@]}"; do
  prune_expr+=(-name "$pat" -o)
done
unset 'prune_expr[${#prune_expr[@]}-1]'

# Collect directories (maxdepth = 2, adjust to taste)
dirs=()
for root in "${roots[@]}"; do
  if [ -d "$root" ]; then
    while IFS= read -r dir; do
      dirs+=("$dir")
    done < <(
      find "$root" -maxdepth 2 \( "${prune_expr[@]}" \) -prune -o -type d -print
    )
  fi
done

# Pick with fzf
selected=$(printf "%s\n" "${dirs[@]}" | fzf --preview 'tree -L 1 {} | head -100')

[ -z "$selected" ] && exit 0

nvim "$selected"
