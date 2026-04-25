# Linux Learning — Project Context

This file is auto-loaded by Claude Code every session. It is the persistent brief
for any assistant working with Kai in this directory. Read it first.

## About Kai

- Software engineer based in Bulgaria.
- Strong Windows power-user background — comfortable with programming concepts
  (PATH, environment variables, processes, file I/O, version control).
- This is his **first serious Linux attempt**. Linux-specific conventions, FHS,
  init systems, package management idioms, and shell culture are all new.
- Windows mental models are his anchor. Draw parallels and contrasts with
  Windows whenever relevant — it dramatically accelerates his intuition.

## System

- Distro: **CachyOS** (Arch-based, rolling release).
- Desktop: **KDE Plasma**.
- Shell: **zsh** (CachyOS default; configured with fish-like ergonomics —
  autosuggestions, syntax highlighting). Note: `/bin/fish` may appear in some
  tool environments, but `$SHELL` is `/usr/bin/zsh`.
- Filesystem: **Btrfs** with subvolumes. Root on `/dev/nvme0n1p2`, subvolume `/@`.
- Hardware: Lenovo LOQ 15IRX10 — Intel **i7-13650HX** (Raptor Lake hybrid,
  14C/20T), 32GB RAM, 1TB NVMe, **NVIDIA RTX 5070** dGPU + Intel iGPU
  (hybrid graphics), FHD display.
- Peripherals: Logitech **Pebble 2 Combo** (Bluetooth keyboard + mouse).
- Laptop is a dedicated hobby/dev machine — experimentation is encouraged,
  but destructive operations still need the standard warnings.

## How Kai wants to learn

1. **Slow and deep over fast and shallow.** Foundational tangents are welcome.
2. **Explain the WHY, not just the WHAT.** Mental models, not memorized incantations.
3. **Break down every flag and argument.** No bare `ls -lah` — always explain `-l`, `-a`, `-h`.
4. **Windows ↔ Linux contrasts** whenever the analogy helps.
5. **Label scope clearly:** Arch/CachyOS-specific vs universal Linux vs
   distribution-dependent. Don't teach Debian-isms as if they were universal.
6. **Warn before anything destructive** and teach the safety habit alongside the
   command (dry-run flags, `--noconfirm` awareness, snapshots, backups).

## Project structure

```
00-setup/              install notes, initial system config
01-basics/             filesystem, permissions, core commands
02-package-management/ pacman, AUR, paru, update workflow
03-shell/              zsh config, dotfiles, PATH, aliases
04-kde/                KDE Plasma tweaks
05-dev-tools/          editor, git, language toolchains
cheatsheets/           Kai's own quick-reference notes
troubleshooting/       problems Kai has hit + solutions
daily-log.md           session-by-session notes, what was learned
README.md              overview of the journey
```

Notes on convention:

- Numeric prefixes keep topics ordered in file listings.
- `cheatsheets/` is for Kai's own terse notes. `01-basics/` etc. are for the
  longer-form teaching material generated during lessons.
- `troubleshooting/` entries should be one file per problem, with symptom,
  cause, fix, and what was learned.
- `daily-log.md` is the canonical session journal — append a dated section
  each session, ending with a "Next up" note.

## Presentation layer (planned)

Lesson notes stay as plain markdown — that is the source of truth and the
format Kai works in directly. Once we have ~3–4 lessons of content (target:
around Session 04), we'll layer **MkDocs with the Material theme** on top
to generate a navigable static site (search, syntax highlighting, sidebar,
dark mode). The setup will itself be a lesson — Python tooling on Arch,
`pipx` vs venvs, local dev servers, file watchers. Until then, do not
introduce a site generator or hand-author HTML.

## Session conventions

- Start each session by skimming `daily-log.md` to see the last "Next up" note.
- End each session by appending a new dated entry to `daily-log.md` covering
  what was learned and what the next session should tackle.
- When a lesson produces a durable reference, save it into the matching
  numbered directory (e.g., the FHS tour → `01-basics/filesystem-hierarchy.md`).
- Keep language plain. Kai reads English fluently but values precision over
  jargon — define Linux-specific terms on first use.

## Already accomplished

- Installed CachyOS from a USB stick.
- Wiped and reformatted the install USB afterwards.
- Installed Claude Code via the native installer.
- Ran the first `arch-update` (CachyOS's curated wrapper around `pacman -Syu`
  and AUR updates).
