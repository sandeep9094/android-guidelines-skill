# Android Guidelines Skill for AI Agents

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/sandeep9094)
A global [Antigravity (AGY)](https://developers.google.com/gemini) agent skill that teaches the AI assistant modern Android architecture, Jetpack Compose best practices, and SDK design patterns.

Once installed, this skill is available in **every AGY project** on your machine without any per-project setup.

---

## 🚀 What's Included

This skill enforces strict guidelines for the agent to follow when generating or modifying Android code:

- **Android Architecture & Jetpack Compose** — Strict separation of UI State, ViewModels, and Composables into separate files.
- **Compose Single Responsibility Principle (SRP)** — One entity per file, with reusable widgets cleanly extracted into `components/`.
- **Jetpack Compose Resource Management** — Standardized handling for Strings, Colors, Typography, Themes, Dimensions, and Icons.
- **UI Strings vs. Internal Business Logic** — Forces user-facing text into `strings.xml` and internal constants into centralized objects/enums.
- **Generic Entry Point Design Pattern** — Clean public interfaces with internal implementations and thread-safe Builder patterns for SDKs.
- **App Environment Design Pattern** — Centralized `AppEnv` with scalable `SdkProductFlavours`.
- **SDK Exception & Logging Frameworks** — Standardized error codes and safe, environment-gated logging.
- **Room Database Migration Guidelines** — Strict rules against destructive migrations; mandates explicit version increments and SQL migrations to prevent data loss.

---

## ⚙️ Installation

Clone this repository once per machine, then run the appropriate installer. The installer creates a **symlink/junction** from the AGY global skills directory to this repo, so future `git pull`s automatically update the skill — no re-install needed!

### macOS / Linux

```bash
git clone https://github.com/sandeep9094/android-guidelines-skill.git
cd android-guidelines-skill
chmod +x install.sh
./install.sh
```

### Windows (PowerShell)

```powershell
git clone https://github.com/sandeep9094/android-guidelines-skill.git
cd android-guidelines-skill
.\install.ps1
```

> **Tip:** If you see an execution-policy error on Windows, run this first:
> ```powershell
> Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
> ```

---

## 🔄 Updating the Skill

On any machine where the skill is already installed, simply pull the latest changes:

```bash
git pull
```

Because the AGY skills directory is symlinked/junctioned to the repo, the agent picks up the new guidelines immediately!

---

## 🛠️ How it works

```text
~/.gemini/config/skills/
└── android-guidelines/        ← symlink / junction
    └── SKILL.md               ← resolves to this repo's SKILL.md
```

AGY's global discovery automatically scans `~/.gemini/config/skills/`. Any `<name>/SKILL.md` found there becomes a globally available skill across all your local projects.

---

## 🗑️ Uninstalling

### macOS / Linux
```bash
rm ~/.gemini/config/skills/android-guidelines
```

### Windows (PowerShell)
```powershell
Remove-Item "$env:USERPROFILE\.gemini\config\skills\android-guidelines"
```

---

## 🤝 Contributing

1. Edit `SKILL.md` with updated guidelines
2. `git commit` and `git push`
3. All machines with the skill installed will get the update on their next `git pull`

---

## ☕ Support

If you found this useful, consider buying me a coffee!

<a href="https://www.buymeacoffee.com/sandeep9094" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>
