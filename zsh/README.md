
# Zsh Configuration File Guide

Zsh loads different configuration files depending on the type of shell being started. Understanding what goes where helps keep your setup clean, fast, and reliable.

This guide explains the purpose of the main Zsh config files and what should go in each.

---

## 📄 File Overview

| File         | Purpose                              | When It's Loaded                   |
|--------------|---------------------------------------|------------------------------------|
| `.zshenv`    | Universal environment variables        | Every Zsh shell (login, script, etc.) |
| `.zprofile`  | Login shell setup (e.g., SSH, GUI login) | Login shells only                 |
| `.zshrc`     | Interactive shell setup (e.g., Terminal tabs) | Interactive shells only          |

---

## ✅ What to Put in Each File

### `.zshenv` — Universal Environment

Use this for basic environment variables that must be available in **every shell**, even scripts or non-interactive processes.

**Examples:**

```zsh
# ~/.zshenv
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export LANG="en_US.UTF-8"
```

> ⚠️ Avoid putting aliases, functions, or interactive setup here.

---

### `.zprofile` — Login Shell Setup

Loaded only once when you start a **login shell**, like:
- Logging in via SSH
- Opening a new terminal window (on macOS, with login shell enabled)
- Logging into a virtual console

**Use for:**
- Starting background agents (`gpg-agent`, `ssh-agent`)
- GUI-related variables (`DISPLAY`, `GPG_TTY`)
- Additional `PATH` logic (if needed)
- Sourcing shared environment files

**Example:**

```zsh
# ~/.zprofile
[ -f ~/.zshenv ] && source ~/.zshenv

if command -v brew >/dev/null 2>&1; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
```

---

### `.zshrc` — Interactive Shell Setup

Loaded every time you start a **new terminal tab/window**, or run Zsh interactively.

**Use for:**
- Aliases and shell functions
- Prompt configuration (e.g., `starship`)
- Plugin managers (`zinit`, `antigen`, etc.)
- Shell options (`setopt`)
- History settings
- Completions and keybindings

**Example:**

```zsh
# ~/.zshrc

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt INC_APPEND_HISTORY SHARE_HISTORY HIST_REDUCE_BLANKS HIST_IGNORE_ALL_DUPS

# Plugin loader (e.g., zinit)
source ~/.zsh_plugins.zsh

# Prompt
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Aliases
alias ll='ls -lah'
alias gs='git status'
```

---

## ✅ Best Practices

- 🧠 **Set `PATH` in `.zshenv`** so it's always available (even in scripts and non-interactive shells).
- ⚙️ **Use `.zshrc` for interactive-only config** like prompts, plugins, and keybindings.
- 🧼 **Keep each file focused**. Don’t mix aliases and environment variables in the same place.
- 🧩 **Avoid sourcing `.zshrc` from `.zprofile`** — this creates confusing behavior.

---

## 🧪 How Zsh Loads Configs

Depending on the shell type, Zsh loads different files:

| Shell Type            | Files Loaded                       |
|------------------------|------------------------------------|
| **Login**              | `.zshenv` → `.zprofile` → `.zshrc` |
| **Interactive (non-login)** | `.zshenv` → `.zshrc`         |
| **Script / Cron Job**  | `.zshenv` only                     |

---

## 🔧 Example Setup

If you want to share your `PATH` setup in both `.zshenv` and `.zprofile`, keep it in `.zshenv`:

```zsh
# ~/.zshenv
export PATH="/opt/homebrew/bin:$PATH"
```

Then in `.zshrc`, you can safely do:

```zsh
# ~/.zshrc
eval "$(starship init zsh)"
```

---

## 🧹 Summary

| Config File | Put This In |
|-------------|-------------|
| `.zshenv`   | `PATH`, `LANG`, and environment vars needed everywhere |
| `.zprofile` | GUI or login shell environment, agent startup, SSH settings |
| `.zshrc`    | Prompt, plugins, history, aliases, interactivity-related logic |

---

## 🧠 Final Tip

If something works in one terminal but not another, check which type of shell you're running:
```bash
echo $0  # shows '-zsh' for login shells
```

Or check if it's interactive:
```bash
[[ $- == *i* ]] && echo "Interactive"
```

---

Happy Zsh-ing! 🐚✨
