# System Configuration

Automated macOS setup using [GNU Stow](https://www.gnu.org/software/stow/) for dotfile management and [1Password](https://1password.com/) for SSH key management.

## Features

- **Automated package installation** via Homebrew
- **Dotfile management** with GNU Stow for clean, symlinked configurations
- **1Password SSH agent integration** for secure key management
- **Multi-identity Git setup** with automatic work/personal account switching
- **AWS SSO profile management** with pre-configured sessions

## Quick Start

```bash
git clone https://github.com/sailorgeoffrey/system-config.git ~/system-config
cd ~/system-config
./bootstrap.sh
```

## What It Does

The bootstrap script will:

1. Install Homebrew (if not present)
2. Install packages from `Brewfile`
3. Stow dotfiles for:
   - zsh (shell configuration with antidote plugin manager)
   - tmux (terminal multiplexer)
   - git (with commit signing via 1Password)
   - ssh (config for multiple identities)
   - aws-sso-profile (AWS SSO session manager)
   - 1Password (SSH agent configuration)
4. Configure 1Password SSH agent
5. Generate public key files from 1Password SSH keys
6. Create `~/.ssh/authorized_keys` for remote access
7. Create `~/.ssh/allowed_signers` for Git commit verification

## Requirements

- macOS (tested on Apple Silicon)
- 1Password with SSH agent enabled
- Git

## Customization

Fork this repository and customize:

- `Brewfile` - Add/remove packages
- Individual dotfiles in each stow package directory
- `bootstrap.sh` - Modify setup steps
- Git configs in `git/.gitconfig` and `git/.gitconfig-ev`

## Structure

```
.
├── 1Password/          # 1Password SSH agent config
├── aws-sso-profile/    # AWS SSO session profiles
├── git/                # Git configuration with signing
├── ssh/                # SSH config with multi-identity support
├── tmux/               # tmux configuration
├── zsh/                # zsh with starship prompt
├── Brewfile            # Homebrew packages
└── bootstrap.sh        # Setup script
```

## Notes

- SSH keys are managed by 1Password - never committed to the repository
- The `.gitignore` excludes sensitive files (`authorized_keys`, private keys, credentials)
- Git commit signing uses 1Password's SSH agent
- Work/personal Git identities switch automatically based on directory
