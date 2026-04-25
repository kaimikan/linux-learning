# Daily Log

One dated entry per session. Append to the top of this file so the newest is
always first. Each entry ends with a **Next up** note for the following session.

---

## 2026-04-24 — Session 01: Bootstrapping + Filesystem Hierarchy

### Already accomplished before this session
- Installed **CachyOS** from a USB stick onto the dedicated hobby/dev laptop.
  KDE Plasma desktop, Btrfs root on `/dev/nvme0n1p2` (subvolume `/@`).
- Wiped and reformatted the install USB after the install was verified.
- Installed **Claude Code** via the native installer.
- Ran the first **`arch-update`** — CachyOS's curated wrapper around
  `pacman -Syu` (+ AUR), which handled initial system updates.

### This session
- Set up the learning project:
  - Created the directory scaffold (`00-setup/` through `05-dev-tools/`,
    plus `cheatsheets/` and `troubleshooting/`).
  - Wrote `CLAUDE.md` (persistent context loaded every session).
  - Wrote `README.md` (human-facing overview).
  - Started this log.
- Confirmed environment details:
  - Default login shell is **zsh** (`$SHELL = /usr/bin/zsh`), not fish.
    CachyOS ships zsh preconfigured with fish-like ergonomics.
  - The **usrmerge** is in effect on this system: `/bin`, `/sbin`, `/lib`,
    `/lib64` are all symlinks pointing into `/usr`. (More on why in the lesson.)
- **Lesson 1 — Linux Filesystem Hierarchy (FHS).**
  Notes saved to `01-basics/filesystem-hierarchy.md`.
  Tour of `/`, `/home`, `/etc`, `/var`, `/usr`, `/tmp`, `/opt`, `/root`,
  `/bin`, `/sbin`, `/boot`, `/dev` — what each is for, the historical
  reasons for the split, the Windows analogues, and where the analogy breaks.
  Ran exploration commands: `ls -l /`, `ls /etc`, `df -hT`.

### Post-session notes (added 2026-04-25)
- Captured hardware spec into context: Lenovo LOQ 15IRX10, i7-13650HX,
  32GB RAM, 1TB NVMe, **RTX 5070** dGPU + Intel iGPU (hybrid graphics),
  Logitech Pebble 2 Combo (Bluetooth kbd + mouse). The NVIDIA dGPU and
  Bluetooth peripherals will get dedicated attention in later sessions.
- Decided on a **presentation layer** for these lesson notes: keep
  markdown as the source of truth, but generate a navigable site with
  **MkDocs + Material theme** once we have 3–4 lessons of content
  (target: around Session 04). Until then, plain `.md` files only.

### Next up
- **Session 02 — Users, groups, permissions, and `sudo`.**
  - The Unix permission model (`rwx`, owner/group/other, octal notation).
  - How `chmod` and `chown` work; when and why to use each.
  - The `root` user vs `sudo`: why you almost never log in as root.
  - Kai's user, default groups (`wheel`, `users`, `video`, etc.), and what
    each group grants.
  - Contrast with Windows ACLs, UAC, and Administrator accounts.
  - Safety: why `chmod -R 777` is the classic footgun and what to do instead.

### Backlog (slot in when ready)
- **MkDocs Material setup** — likely Session 04, after we have 3–4 lessons.
  Will double as a real lesson on Python tooling (pacman vs pipx vs venv),
  local dev servers, and file watchers.
- **NVIDIA + KDE** — driver choice (`nvidia-open` vs proprietary),
  Wayland vs X11 session, PRIME offloading for hybrid graphics.
- **Bluetooth peripherals** — pairing the Logitech Pebble 2 Combo,
  `bluetoothctl`, KDE's Bluetooth applet, persistence across reboots.
- **ssh-agent / credential-helpers on Linux** — not a Windows analogue Kai
  is familiar with. Covers: why an agent exists (decrypted keys in memory,
  passphrase typed once per session), the options on Arch (`ssh-agent` as
  a systemd user service, `gpg-agent` with SSH support, KDE's KWallet +
  `ksshaskpass` for graphical prompts, the `keychain` helper), tradeoffs
  between them, and picking one. Deferred until Kai has felt the "type
  passphrase on every push" friction enough to know which tradeoffs matter
  to him. When we do it, drive from the Arch Wiki "SSH keys" page and let
  Kai run every command in Konsole — no Claude `!` shortcuts.
