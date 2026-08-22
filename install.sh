#!/usr/bin/env bash
# =============================================================================
# install.sh — Android Guidelines Skill Installer (Mac / Linux)
# =============================================================================
# Creates a symlink in ~/.gemini/config/skills/ pointing to this repo so that
# the android-guidelines skill is available globally to all AGY projects.
#
# Usage:
#   chmod +x install.sh
#   ./install.sh
#
# To uninstall:
#   rm ~/.gemini/config/skills/android-guidelines
# =============================================================================

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Resolve the absolute path of this repo ───────────────────────────────────
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_NAME="android-guidelines"
SKILLS_DIR="${HOME}/.gemini/config/skills"
LINK_TARGET="${SKILLS_DIR}/${SKILL_NAME}"

echo ""
echo -e "${BOLD}${CYAN}Android Guidelines Skill — Installer${RESET}"
echo "────────────────────────────────────────"
echo -e "  Repo  : ${REPO_DIR}"
echo -e "  Target: ${LINK_TARGET}"
echo ""

# ── Verify SKILL.md exists in repo ───────────────────────────────────────────
if [[ ! -f "${REPO_DIR}/SKILL.md" ]]; then
  echo -e "${RED}✗ SKILL.md not found in ${REPO_DIR}. Aborting.${RESET}"
  exit 1
fi

# ── Create skills directory if it doesn't exist ──────────────────────────────
if [[ ! -d "${SKILLS_DIR}" ]]; then
  echo -e "${YELLOW}⚙ Creating directory: ${SKILLS_DIR}${RESET}"
  mkdir -p "${SKILLS_DIR}"
fi

# ── Remove existing symlink / directory at target ────────────────────────────
if [[ -L "${LINK_TARGET}" ]]; then
  echo -e "${YELLOW}⚙ Removing existing symlink at ${LINK_TARGET}${RESET}"
  rm "${LINK_TARGET}"
elif [[ -d "${LINK_TARGET}" ]]; then
  echo -e "${RED}✗ A real directory already exists at ${LINK_TARGET}.${RESET}"
  echo -e "  Remove it manually and re-run this script."
  exit 1
fi

# ── Create symlink ────────────────────────────────────────────────────────────
ln -s "${REPO_DIR}" "${LINK_TARGET}"

# ── Verify ───────────────────────────────────────────────────────────────────
if [[ -f "${LINK_TARGET}/SKILL.md" ]]; then
  echo -e "${GREEN}✔ Skill installed successfully!${RESET}"
  echo ""
  echo -e "  ${BOLD}android-guidelines${RESET} is now available globally in all AGY projects."
  echo -e "  Run ${CYAN}git pull${RESET} inside the repo to update the skill on this machine."
else
  echo -e "${RED}✗ Installation failed — symlink created but SKILL.md not reachable.${RESET}"
  exit 1
fi
echo ""
