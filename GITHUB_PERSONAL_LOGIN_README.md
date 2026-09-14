# Project-only GitHub login

This guide lets this project push to your personal GitHub account:

- GitHub account: `abisheksanthoshkumar`
- Git email for this repo: `abhisheksanthosh77@gmail.com`
- Repo: `git@github-personal:AbishekSanthoshKumar/European-Job-Sponsorship-Achiever.git`

It avoids changing your global Git config and avoids touching any work-account
GitHub login already saved on this machine.

## Recommended setup: separate SSH key

Use a separate SSH key plus a `github-personal` host alias. Your work account can
keep using the normal `github.com` host and whatever global credentials it
already has.

## 1. Create a personal SSH key

Run this once:

```bash
ssh-keygen -t ed25519 -C "abhisheksanthosh77@gmail.com" -f ~/.ssh/id_ed25519_github_personal
```

When asked for a passphrase, use one if you want extra protection.

## 2. Add the public key to your personal GitHub account

Copy the public key:

```bash
pbcopy < ~/.ssh/id_ed25519_github_personal.pub
```

Then open GitHub while signed in as `abisheksanthoshkumar`:

```text
GitHub -> Settings -> SSH and GPG keys -> New SSH key
```

Paste the key, give it a title like:

```text
MacBook personal project key
```

Then save it.

## 3. Add an SSH host alias

Edit `~/.ssh/config` and add this block:

```sshconfig
Host github-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_github_personal
  IdentitiesOnly yes
```

This creates a separate GitHub route named `github-personal`. It does not alter
the default `github.com` route your work account may already use.

## 4. Configure only this repo's Git identity

From this project folder:

```bash
git config --local user.name "abisheksanthoshkumar"
git config --local user.email "abhisheksanthosh77@gmail.com"
```

Check that these are local to this repo:

```bash
git config --local --get user.name
git config --local --get user.email
```

Do not use `--global` for this project identity.

## 5. Point this repo at the personal GitHub remote

From this project folder:

```bash
git remote add origin git@github-personal:AbishekSanthoshKumar/European-Job-Sponsorship-Achiever.git
```

If `origin` already exists, update only this repo's remote:

```bash
git remote set-url origin git@github-personal:AbishekSanthoshKumar/European-Job-Sponsorship-Achiever.git
```

Confirm it:

```bash
git remote -v
```

You should see `github-personal`, not plain `github.com`.

## 6. Test the personal SSH login

Run:

```bash
ssh -T git@github-personal
```

Expected result:

```text
Hi AbishekSanthoshKumar! You've successfully authenticated, but GitHub does not provide shell access.
```

If GitHub prints a different username, stop and check the SSH key attached to
the `github-personal` alias.

## 7. Push this project

If this folder is not a Git repo yet:

```bash
git init
git add .
git commit -m "Initial project setup"
git branch -M main
git push -u origin main
```

If it is already a Git repo:

```bash
git add .
git commit -m "Update project"
git push
```

## Safety checklist

Before pushing, verify these:

```bash
git config --global --get user.email
git config --local --get user.email
git remote -v
```

The global email can remain your work email. The local email should be
`abhisheksanthosh77@gmail.com`. The remote should use `github-personal`.

Also make sure `.env` is ignored and not staged:

```bash
git status --short
```

If `.env` appears in the staged or unstaged file list, do not push. This project
contains Supabase credentials in `.env`, so it must stay local.

## Optional: isolated GitHub CLI login

You do not need GitHub CLI for normal Git pushes if SSH is configured as above.
If you still want a temporary, isolated GitHub CLI login for this project, use a
project-local config directory:

```bash
mkdir -p .github-personal-gh
GH_CONFIG_DIR="$PWD/.github-personal-gh" gh auth login
GH_CONFIG_DIR="$PWD/.github-personal-gh" gh auth status
```

This keeps `gh` auth files inside `.github-personal-gh` instead of your normal
global GitHub CLI config.

Add this folder to `.gitignore`:

```gitignore
.github-personal-gh/
```

For Git push/pull, prefer the SSH setup above. It is simpler and keeps account
selection tied directly to this repo's remote URL.
