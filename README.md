# Linux Learning

A personal learning journal for my switch from Windows to Linux.
Host: CachyOS (Arch-based) + KDE Plasma on Btrfs, on a dedicated hobby/dev laptop.

## Why this repo

I'm a long-time Windows power user and software engineer. I've decided to
learn Linux properly — not by following a tutorial end-to-end, but by
building up real mental models one topic at a time, using Claude Code as
a patient tutor.

This directory is:

- The **lesson archive** — longer-form notes from each session, organized by topic.
- The **running journal** — `daily-log.md` records what I actually did and learned.
- The **cheatsheet stash** — terse references I'll come back to.
- The **troubleshooting log** — problems I hit, and how I fixed them.

## Layout

| Path                     | Purpose                                      |
|--------------------------|----------------------------------------------|
| `00-setup/`              | Install notes, initial system config         |
| `01-basics/`             | Filesystem, permissions, core commands       |
| `02-package-management/` | pacman, AUR, paru, update workflow           |
| `03-shell/`              | zsh config, dotfiles, PATH, aliases          |
| `04-kde/`                | KDE Plasma tweaks                            |
| `05-dev-tools/`          | Editor, git, language toolchains             |
| `cheatsheets/`           | Quick-reference notes                        |
| `troubleshooting/`       | Problems hit + how I fixed them              |
| `daily-log.md`           | Session-by-session log                       |
| `CLAUDE.md`              | Persistent context for Claude Code           |

## How I'm learning

- **Slow and deep.** One topic understood is worth ten skimmed.
- **WHY before WHAT.** If I can't explain why a command exists, I can't really use it.
- **Windows as anchor.** New Linux concept → find the Windows analogue →
  note where the analogy breaks.
- **Scope labels.** Arch-specific? Universal Linux? Distro-dependent? Always flag.
- **Safety first for destructive ops.** Warn, dry-run, snapshot, then act.
