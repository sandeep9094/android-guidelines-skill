# Android Guidelines Skill

A global [Antigravity (AGY)](https://developers.google.com/gemini) agent skill that teaches the AI assistant Android SDK design patterns and Jetpack Compose resource management guidelines.

Once installed, this skill is available in **every AGY project** on your machine without any per-project setup.

---

## What's included

- **Generic Entry Point Design Pattern** — Public interface + internal implementation, thread-safe singleton Builder
- **App Environment Design Pattern** — Centralized `AppEnv` with `SdkProductFlavours`
- **SDK Exception Framework** — `SDKErrorCode` constants + `SDKException` class
- **SDK Logging Pattern** — `SDKLog` with `AppEnv`-gated inline logging helpers
- **Jetpack Compose Resource Management** — Strings, Colors, Typography, Themes, Dimensions, Icons
- **Kotlin & Compose Coding Style** — No FQCN, explicit imports, clean call-sites

---

## Installation

Clone this repository once per machine, then run the appropriate installer. The installer creates a **symlink/junction** from the AGY global skills directory to this repo, so future `git pull`s automatically update the skill — no re-install needed.

### macOS / Linux

```bash
git clone https://github.com/YOUR_USERNAME/android-guidelines-skill.git
cd android-guidelines-skill
chmod +x install.sh
./install.sh
```

### Windows (PowerShell)

```powershell
git clone https://github.com/YOUR_USERNAME/android-guidelines-skill.git
cd android-guidelines-skill
.\install.ps1
```

> **Tip:** If you see an execution-policy error, run this first:
> ```powershell
> Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
> ```

---

## Updating the skill

On any machine where the skill is already installed, simply pull the latest changes:

```bash
git pull
```

Because the AGY skills directory is symlinked/junctioned to the repo, the agent picks up the new `SKILL.md` immediately — no re-install required.

---

## How it works

```
~/.gemini/config/skills/
└── android-guidelines/        ← symlink / junction
    └── SKILL.md               ← resolves to this repo's SKILL.md
```

AGY's global discovery scans `~/.gemini/config/skills/` automatically. Any `<name>/SKILL.md` found there becomes a globally available skill across all projects.

---

## Uninstalling

### macOS / Linux
```bash
rm ~/.gemini/config/skills/android-guidelines
```

### Windows (PowerShell)
```powershell
Remove-Item "$env:USERPROFILE\.gemini\config\skills\android-guidelines"
```

---

## Contributing

1. Edit `SKILL.md` with updated guidelines
2. `git commit` and `git push`
3. All machines with the skill installed will get the update on their next `git pull`
