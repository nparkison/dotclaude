#!/usr/bin/env bash
# install.sh -- interactive installer for the dotclaude repo
# Symlinks hooks, copies skills/templates, and sets up CLAUDE.md.
set -euo pipefail

# ---------------------------------------------------------------------------
# Color helpers (degrade gracefully when the terminal has no color support)
# ---------------------------------------------------------------------------
if [ -t 1 ] && tput colors &>/dev/null && [ "$(tput colors)" -ge 8 ]; then
  BOLD=$(tput bold)
  RESET=$(tput sgr0)
  RED=$(tput setaf 1)
  GREEN=$(tput setaf 2)
  YELLOW=$(tput setaf 3)
  CYAN=$(tput setaf 6)
  DIM=$(tput dim 2>/dev/null || printf '')
else
  BOLD='' RESET='' RED='' GREEN='' YELLOW='' CYAN='' DIM=''
fi

# ---------------------------------------------------------------------------
# Globals
# ---------------------------------------------------------------------------
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="${CLAUDE_DIR}/backups/${TIMESTAMP}"

# Counters used for the final summary
INSTALLED=0
BACKED_UP=0
SKIPPED=0
ERRORS=0

# ---------------------------------------------------------------------------
# Utility functions
# ---------------------------------------------------------------------------

print_banner() {
  printf '%s\n' "${CYAN}${BOLD}"
  printf '%s\n' ' ██████   ██████  ████████  ██████ ██       ██████  ██  ██  ██████   ██████'
  printf '%s\n' ' ██   ██ ██    ██    ██    ██      ██      ██   ██  ██  ██  ██   ██ ██'
  printf '%s\n' ' ██   ██ ██    ██    ██    ██      ██      ██████   ██  ██  ██   ██ █████'
  printf '%s\n' ' ██   ██ ██    ██    ██    ██      ██      ██   ██  ██  ██  ██   ██ ██'
  printf '%s\n' ' ██████   ██████     ██     ██████ ██████  ██   ██  ██████  ██████   ██████'
  printf '%s\n' ''
  printf '%s\n' '  dotclaude installer'
  printf '%s\n' "${RESET}"
}

info()    { printf '  %s%s%s\n' "${CYAN}"   "$*" "${RESET}"; }
success() { printf '  %s%s%s\n' "${GREEN}"  "$*" "${RESET}"; }
warn()    { printf '  %s%s%s\n' "${YELLOW}" "$*" "${RESET}"; }
error()   { printf '  %s%s%s\n' "${RED}"    "$*" "${RESET}"; }
dim()     { printf '  %s%s%s\n' "${DIM}"    "$*" "${RESET}"; }

# Ensure a directory exists, create it if not.
ensure_dir() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
  fi
}

# Back up a file or directory to the timestamped backup folder.
# Returns 0 if a backup was made, 1 if nothing existed to back up.
backup_if_exists() {
  local target="$1"
  if [ -e "$target" ] || [ -L "$target" ]; then
    ensure_dir "$BACKUP_DIR"
    local rel="${target#"${CLAUDE_DIR}/"}"
    local dest="${BACKUP_DIR}/${rel}"
    ensure_dir "$(dirname "$dest")"
    mv "$target" "$dest"
    warn "Backed up: ${target} -> ${dest}"
    BACKED_UP=$((BACKED_UP + 1))
    return 0
  fi
  return 1
}

# Copy a single file, backing up any existing destination first.
install_file() {
  local src="$1"
  local dest="$2"
  ensure_dir "$(dirname "$dest")"
  backup_if_exists "$dest" || true
  if cp "$src" "$dest"; then
    success "Copied:    ${src##"${REPO_DIR}/"} -> ${dest}"
    INSTALLED=$((INSTALLED + 1))
  else
    error "FAILED to copy ${src} -> ${dest}"
    ERRORS=$((ERRORS + 1))
  fi
}

# Create a symlink, backing up any existing destination first.
install_symlink() {
  local src="$1"
  local dest="$2"
  ensure_dir "$(dirname "$dest")"
  backup_if_exists "$dest" || true
  if ln -sf "$src" "$dest"; then
    success "Symlinked: ${src##"${REPO_DIR}/"} -> ${dest}"
    INSTALLED=$((INSTALLED + 1))
  else
    error "FAILED to symlink ${src} -> ${dest}"
    ERRORS=$((ERRORS + 1))
  fi
}

# ---------------------------------------------------------------------------
# OS detection
# ---------------------------------------------------------------------------
detect_os() {
  case "$(uname -s)" in
    Darwin) echo "macOS" ;;
    Linux)  echo "Linux" ;;
    *)      echo "Unknown" ;;
  esac
}

# ---------------------------------------------------------------------------
# Component installers
# ---------------------------------------------------------------------------

install_claude_md() {
  info "Installing CLAUDE.md..."
  local src="${REPO_DIR}/claude.md"
  local dest="${CLAUDE_DIR}/CLAUDE.md"

  if [ ! -f "$src" ]; then
    error "claude.md not found in repo root. Skipping."
    SKIPPED=$((SKIPPED + 1))
    return
  fi

  install_file "$src" "$dest"

  warn "ACTION REQUIRED: Open ${dest} and replace all {{PLACEHOLDER}} values with your specifics."
}

install_hooks() {
  info "Installing hooks..."
  local hooks_src="${REPO_DIR}/hooks"
  local hooks_dest="${CLAUDE_DIR}/hooks"
  ensure_dir "$hooks_dest"

  local count=0
  for hook_file in "${hooks_src}"/*.py "${hooks_src}"/*.sh; do
    # Skip glob patterns that matched nothing
    [ -e "$hook_file" ] || continue
    # Skip the Obsidian hook here; it is handled by its own installer
    [[ "$(basename "$hook_file")" == "session-to-obsidian.py" ]] && continue
    install_symlink "$hook_file" "${hooks_dest}/$(basename "$hook_file")"
    count=$((count + 1))
  done

  if [ "$count" -eq 0 ]; then
    warn "No hook files found in ${hooks_src}. Skipping."
    SKIPPED=$((SKIPPED + 1))
    return
  fi

  warn "ACTION REQUIRED: Register hooks in ~/.claude/settings.json under the 'hooks' key."
  dim "  Example: { \"hooks\": { \"PreToolUse\": [{ \"matcher\": \"Bash\", \"hooks\": [{ \"type\": \"command\", \"command\": \"python3 ~/.claude/hooks/push-guard.py\" }] }] } }"
}

install_skills() {
  info "Installing skills..."
  local skills_src="${REPO_DIR}/skills"
  local skills_dest="${CLAUDE_DIR}/skills"
  ensure_dir "$skills_dest"

  local count=0
  # Walk all .md files in any subdirectory of skills/
  while IFS= read -r -d '' skill_file; do
    local rel="${skill_file#"${skills_src}/"}"
    local dest="${skills_dest}/${rel}"
    install_file "$skill_file" "$dest"
    count=$((count + 1))
  done < <(find "$skills_src" -name "*.md" -not -name "README.md" -print0)

  if [ "$count" -eq 0 ]; then
    warn "No skill files found in ${skills_src}. Skipping."
    SKIPPED=$((SKIPPED + 1))
    return
  fi

  warn "ACTION REQUIRED: Skills must be registered in settings.json to be callable."
  dim "  Add each skill under the 'skills' key with its path and description."
}

install_convention_templates() {
  info "Installing convention doc templates into current project..."
  local templates_src="${REPO_DIR}/docs/templates"
  # Templates go into .claude/docs/ relative to the directory the installer is run from,
  # NOT into the home directory. This is intentionally project-scoped.
  local project_dir
  project_dir="$(pwd)"
  local templates_dest="${project_dir}/.claude/docs"
  ensure_dir "$templates_dest"

  local count=0
  for tmpl_file in "${templates_src}"/*.md; do
    [ -e "$tmpl_file" ] || continue
    local dest="${templates_dest}/$(basename "$tmpl_file")"
    install_file "$tmpl_file" "$dest"
    count=$((count + 1))
  done

  if [ "$count" -eq 0 ]; then
    warn "No templates found in ${templates_src}. Skipping."
    SKIPPED=$((SKIPPED + 1))
    return
  fi

  warn "ACTION REQUIRED: Open each file in ${templates_dest} and fill in project-specific details."
}

install_obsidian_integration() {
  info "Installing Obsidian integration..."
  local hook_src="${REPO_DIR}/hooks/session-to-obsidian.py"
  local hook_dest="${CLAUDE_DIR}/hooks/session-to-obsidian.py"

  if [ ! -f "$hook_src" ]; then
    error "session-to-obsidian.py not found. Skipping."
    SKIPPED=$((SKIPPED + 1))
    return
  fi

  # Prompt user for their vault path before installing.
  printf '\n  %sObsidian vault path%s (e.g. ~/Documents/MyVault or /home/user/vault): ' "${BOLD}" "${RESET}"
  local vault_path
  read -r vault_path

  if [ -z "$vault_path" ]; then
    warn "No vault path provided. Skipping Obsidian integration."
    SKIPPED=$((SKIPPED + 1))
    return
  fi

  # Expand ~ manually since it won't expand inside a variable assignment.
  vault_path="${vault_path/#\~/$HOME}"

  if [ ! -d "$vault_path" ]; then
    warn "Vault path does not exist: ${vault_path}"
    warn "Installing anyway. Edit VAULT_ROOT_FALLBACK in the hook file once the vault is accessible."
  fi

  ensure_dir "${CLAUDE_DIR}/hooks"
  backup_if_exists "$hook_dest" || true

  # Copy the hook and patch the fallback vault path in one step.
  # The hook uses VAULT_ROOT_FALLBACK = Path("/path/to/your/obsidian/vault")
  if sed "s|/path/to/your/obsidian/vault|${vault_path}|g" "$hook_src" > "$hook_dest"; then
    success "Installed Obsidian hook to ${hook_dest}"
    success "Vault path set to: ${vault_path}"
    INSTALLED=$((INSTALLED + 1))
  else
    if cp "$hook_src" "$hook_dest"; then
      success "Installed Obsidian hook to ${hook_dest}"
      warn "Could not auto-patch vault path. Edit VAULT_ROOT_FALLBACK in ${hook_dest}"
      INSTALLED=$((INSTALLED + 1))
    else
      error "FAILED to install Obsidian hook."
      ERRORS=$((ERRORS + 1))
      return
    fi
  fi

  warn "ACTION REQUIRED: Register session-to-obsidian.py in settings.json under the Stop hook."
}

# ---------------------------------------------------------------------------
# Menu
# ---------------------------------------------------------------------------

MENU_ITEMS=(
  "CLAUDE.md (copy to ~/.claude/CLAUDE.md)"
  "Hooks (symlink hooks/ to ~/.claude/hooks/)"
  "Skills (copy skills/ to ~/.claude/skills/)"
  "Convention Doc Templates (copy docs/templates/ to .claude/docs/ in current project)"
  "Obsidian Integration (install session-to-obsidian.py, prompt for vault path)"
)

MENU_FUNCS=(
  install_claude_md
  install_hooks
  install_skills
  install_convention_templates
  install_obsidian_integration
)

show_menu() {
  printf '\n%s%sComponents available to install:%s\n\n' "${BOLD}" "${CYAN}" "${RESET}"
  local i=1
  for item in "${MENU_ITEMS[@]}"; do
    printf '  %s[%d]%s %s\n' "${YELLOW}" "$i" "${RESET}" "$item"
    i=$((i + 1))
  done
  printf '\n  %s[all]%s Install everything\n\n' "${YELLOW}" "${RESET}"
}

# Parse the user's selection string into a list of indices (1-based).
# Accepts: "1 3 5", "all", "1,3,5", mixed whitespace/comma separators.
parse_selection() {
  local input="$1"
  local max="${#MENU_ITEMS[@]}"
  local selected=()

  if [[ "$input" == "all" ]]; then
    for i in $(seq 1 "$max"); do
      selected+=("$i")
    done
    echo "${selected[*]}"
    return
  fi

  # Replace commas with spaces, then split on whitespace.
  local normalized
  normalized="${input//,/ }"
  for token in $normalized; do
    if [[ "$token" =~ ^[0-9]+$ ]] && [ "$token" -ge 1 ] && [ "$token" -le "$max" ]; then
      selected+=("$token")
    else
      warn "Ignoring unrecognized selection: ${token}"
    fi
  done

  if [ ${#selected[@]} -eq 0 ]; then
    echo ""
  else
    echo "${selected[*]}"
  fi
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

print_summary() {
  printf '\n%s%s--- Install summary ---%s\n' "${BOLD}" "${CYAN}" "${RESET}"
  printf '  %sInstalled:%s %d item(s)\n'  "${GREEN}"  "${RESET}" "$INSTALLED"
  printf '  %sBacked up:%s %d item(s)\n'  "${YELLOW}" "${RESET}" "$BACKED_UP"
  printf '  %sSkipped:  %s %d item(s)\n'  "${DIM}"    "${RESET}" "$SKIPPED"

  if [ "$ERRORS" -gt 0 ]; then
    printf '  %sErrors:   %s %d item(s) -- check output above\n' "${RED}" "${RESET}" "$ERRORS"
  fi

  if [ "$BACKED_UP" -gt 0 ]; then
    printf '\n  Backups are in: %s\n' "$BACKUP_DIR"
  fi

  printf '\n%sNext steps:%s\n' "${BOLD}" "${RESET}"
  printf '  1. Replace any {{PLACEHOLDER}} values in installed files.\n'
  printf '  2. Register hooks and skills in ~/.claude/settings.json.\n'
  printf '  3. Restart Claude Code to pick up the new configuration.\n'
  printf '\n'
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  print_banner

  local os
  os="$(detect_os)"
  info "Detected OS: ${os}"
  info "Repo root:   ${REPO_DIR}"
  info "Claude dir:  ${CLAUDE_DIR}"
  printf '\n'

  ensure_dir "$CLAUDE_DIR"

  show_menu

  printf '%sSelect components to install%s (e.g. "1 3" or "all"): ' "${BOLD}" "${RESET}"
  local raw_selection
  read -r raw_selection

  if [ -z "$raw_selection" ]; then
    warn "No selection made. Exiting."
    exit 0
  fi

  local indices
  indices="$(parse_selection "$raw_selection")"

  if [ -z "$indices" ]; then
    warn "No valid selections. Exiting."
    exit 0
  fi

  printf '\n'

  for idx in $indices; do
    local fn="${MENU_FUNCS[$((idx - 1))]}"
    printf '%s%s[%d/%d] %s%s\n' "${BOLD}" "${CYAN}" "$idx" "${#MENU_ITEMS[@]}" "${MENU_ITEMS[$((idx - 1))]}" "${RESET}"
    # Call the installer function; catch failures so one bad component won't abort everything.
    if ! "$fn"; then
      error "Installer function ${fn} exited with an error."
      ERRORS=$((ERRORS + 1))
    fi
    printf '\n'
  done

  print_summary
}

main "$@"
