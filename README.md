# System Configuration Bootstrap

This repository provides a portable, secure, and scalable way to manage personal and professional homebrew dependencies, dotfiles, SSH keys, and Git configuration. All sensitive data is generated with the bootstrap script, so all you need to do is distribute the generated public keys as needed when prompted.

## TLDR
If your laptop get water damage and you need to buy a new one and get back to work in 15 minutes... Check out this repo, update the `bootstrap.yaml` with your personal information, and run the `bootstrap.sh` command and copy/paste the generated public keys where you need to and you will be back up and running in no time.
## Features
- 📁 Uses stow to manage dotfiles cleanly and modularly
- 🔐 Generates one SSH key per GitHub identity for scoped access and easier rotation
- 🧠 Central config-as-code via bootstrap.yaml
- 🛠 Dynamically builds .gitconfig and .ssh/config
- ✅ Includes a verification script to test SSH key setup
- 🍺 Ensures all dependencies are installed via Homebrew

## Getting Started
### 1. Clone this repo
```
git clone https://github.com/sailorgeoffrey/system-config.git`
cd system-config
```
### 2. Create a bootstrap.yaml
#### Each id will:
- Generate an SSH key at ~/.ssh/id_github_<id>
- Create an SSH config entry gh-<id>
- Rewrite Git URLs like git@github.com:<org>/ → git@gh-<id>:<org>/

```
full_name: Geoffrey Chandler
email: geoffc@gmail.com

github_identities:
- id: geoff
  orgs:
    - sailorgeoffrey
    - advantageous

- id: ev
  orgs:
    - evin...
    - unif...

- id: az
  orgs:
    - RDI...
```

### 3. Run the bootstrap

`bootstrap/bootstrap.sh`

#### This will:
- Install dependencies (like yq, stow)
- Create any missing SSH keys
- Write .gitconfig and .ssh/config
- Symlink your other dotfiles via stow
- Print out public keys to add to GitHub

### 4. Add your SSH keys to GitHub
```
After bootstrapping, you’ll see:
📋 SSH Public Keys (add these to GitHub):
🔑 geoff:
ssh-ed25519 AAAAC3...
```
Go to https://github.com/settings/keys and paste each key as needed.

### 5. Verify the setup
`bootstrap/verify_github_keys.sh`

### This will:
- Check that each key file exists
- Confirm it’s loaded in ssh-agent
- Attempt SSH authentication via your aliases (e.g. git@gh-geoff)


## Notes
- This setup avoids stowing .ssh/ and .gitconfig directly — instead, they are generated from config.
- GitHub aliases (gh-<id>) allow multiple identities to co-exist and rotate independently.
- You can re-run ./bootstrap.sh any time to regenerate config and add identities.


## License
MIT, but be smart with your secrets 🙂
