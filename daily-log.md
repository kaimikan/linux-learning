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
  - Default login shell: **initially claimed to be zsh** based on `echo $SHELL`
    returning `/usr/bin/zsh`. **This was wrong** — see the 2026-04-25
    continuation for the discovery. The canonical login shell lives in the
    last field of `/etc/passwd`, which reported `/bin/fish` all along. The
    `$SHELL` env var was being set to zsh inside Claude's subprocess, which
    doesn't reflect what Konsole actually runs. Lesson: `getent passwd <user>`
    is authoritative for login shell; `$SHELL` is just an env var and can lie.
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

### 2026-04-25 — Session 01 continued: git identity + SSH to GitHub

- **Configured global git identity** — `git config --global user.name "kaimikan"`
  and `user.email "kaimikan@protonmail.com"`. Writes to `~/.gitconfig`; applies
  to every repo on this machine. Same command on Linux as on Windows — git
  itself is cross-platform and identity setup is not an OS-level concern.
- **Generated an `ed25519` SSH keypair** at `~/.ssh/id_ed25519` (+ `.pub`).
  - First attempt via Claude's `!` tool silently produced a key with an
    empty passphrase. Root cause: ssh-keygen's passphrase-source fallback
    chain is (1) TTY, (2) `$SSH_ASKPASS` program, (3) silent empty. Claude's
    `!` has no TTY; CachyOS doesn't ship a default askpass binary
    (`/usr/lib/ssh/ssh-askpass` missing); so the key was generated with no
    encryption at rest. Fixed by running `ssh-keygen -p -f ~/.ssh/id_ed25519`
    in a real Konsole, which re-encrypts the existing private key with a new
    passphrase. The keypair's identity (public key, fingerprint) stays the
    same after `-p`.
  - **Takeaway:** interactive commands (passphrase prompts, `vim`, `top`,
    anything reading stdin) need a real terminal. Run them in Konsole,
    not via Claude's `!`.
- **Attempted an ssh-agent setup** as a `systemd --user` service with a
  `~/.zshenv` env var. It didn't work because the login shell is fish, not
  zsh — so `.zshenv` was never read. Rolled the attempt back entirely: unit
  file (`~/.config/systemd/user/ssh-agent.service`), enable symlink, and
  `~/.zshenv` all removed. Keypair kept. Agent setup deferred to its own
  session when the per-push passphrase prompt actually starts to hurt
  (see Backlog).
- **Registered the public key with GitHub** (Settings → SSH and GPG keys).
  Verified with `ssh -T git@github.com` → "Hi kaimikan! You've successfully
  authenticated, but GitHub does not provide shell access." (The "but..." is
  expected — GitHub doesn't hand out shells, only git-protocol access.)
  First-connection TOFU prompt: GitHub's ED25519 fingerprint matched the
  published one at docs.github.com/../githubs-ssh-key-fingerprints.
- **Created the GitHub repo** `github.com/kaimikan/linux-learning`
  (SSH URL: `git@github.com:kaimikan/linux-learning.git`), renamed local
  branch `master` → `main` (`git branch -M main`) to match GitHub's modern
  default, added the remote (`git remote add origin ...`), and pushed
  (`git push -u origin main`). Push succeeded: 12 objects, 13.73 KiB, branch
  tracking set. `-u` / `--set-upstream` recorded `origin/main` as the
  tracking ref for local `main`, so future bare `git push`/`git pull` know
  what to talk to.

### Retrospective on Session 01

- **Worked well:** FHS tour (mental models landed, exploration commands run),
  git identity inline, SSH key generation and GitHub push end-to-end.
- **Didn't go well:** Claude overcomplicated the SSH setup by reaching for a
  systemd-user ssh-agent unit when simple per-session passphrase prompts
  were fine for now. It also dismissed the session's starting system context
  (which reported fish as the shell) based on one misleading `$SHELL`
  readback and burned time on zsh config that never ran. Kai had to push
  back twice (on deferring SSH setup, and on the agent complexity) to steer
  back to minimum-viable.
- **Rules captured as a result** (in Claude's memory, will apply going forward):
  - Don't dismiss conflicting system signals — reconcile them.
  - Don't over-defer small familiar tasks to the backlog; do them inline.
  - Commit at natural session boundaries in this repo.
  - No Claude/Anthropic attribution trailer in commit messages (global pref).

---

## 2026-04-25 — Session 02: Users, groups, permissions, and `sudo`

Notes saved to `01-basics/users-groups-permissions.md`.

### Covered
- **The mental model.** Linux security = UID + GID + 9 rwx bits. Simpler
  than Windows ACLs (which attach an ordered rule list to every securable
  object). Linux does have POSIX ACLs via `setfacl`/`getfacl` but they're
  the exception, not the default.
- **The three bits, and how they differ for files vs directories.**
  For a directory: `r` = list entries, `w` = add/delete entries (not
  modify the file's content), `x` = traverse (`cd` into). The directory
  `x` vs `r` distinction is the #1 source of "why can't I touch this
  file" confusion. Deleting a file requires `w` on its *parent directory*,
  not on the file itself.
- **First-match-wins evaluation.** Owner → group → other, not cumulative.
  If the owner triplet denies you, that's final — even if group would
  grant it. Root (UID 0) bypasses the check entirely.
- **Reading `ls -l` output.** Type char + 3 triplets of `rwx`, then owner,
  group, size, mtime, path.
- **Octal notation.** `r=4 w=2 x=1`. The four common modes to memorize:
  `600` (private files like SSH keys), `644` (normal data), `700` (private
  dirs like `~/.ssh`), `755` (executables, most dirs).
- **`chmod`** — symbolic form (`u+x`, `go-w`) for tweaks, octal form for
  known states. **`chmod -R 777` is the classic footgun**: it masks
  ownership problems, marks data files executable, and breaks SSH (OpenSSH
  refuses to use world-writable keys). Fix ownership with `chown` or add
  yourself to the right group instead.
- **`chown`** — needs `sudo`. Syntaxes: `chown user file`,
  `chown user:group file`, `chown :group file`. `chown -R` as root on the
  wrong path is catastrophic — double-check targets.
- **Root vs sudo.** Root UID 0 bypasses all checks. On CachyOS the root
  account has no login password set by default; admin is via `sudo`.
  `sudo` elevates one command at a time (contrast UAC, which elevates a
  whole process). Gate on Arch is membership in the `wheel` group,
  defined in `/etc/sudoers` (`%wheel ALL=(ALL:ALL) ALL`). Debian/Ubuntu
  use the `sudo` group instead — same idea, different name.
- **Groups on this system.** 11 supplementary groups from `id`:
  `kaimikan` (user-private group, default for new files), `wheel` (sudo),
  `video`/`audio` (direct device access), `network` (NetworkManager),
  `nopasswdlogin` (CachyOS/SDDM autologin), plus legacy ones.
- **`usermod -aG` vs `usermod -G` footgun.** Always `-aG` to append. Bare
  `-G` *replaces* supplementary groups, which can drop you from `wheel`
  and lock you out of sudo. Recovery requires rescue boot.

### Exploration
- `id` — confirmed UID/GID/groups listing matches the lesson.
- `ls -l /etc/passwd /etc/shadow /etc/sudoers /etc/group` — saw the
  permission patterns: `passwd` and `group` are `644` (world-readable
  name-mapping files), `shadow` is `600` (root-only, password hashes),
  `sudoers` is `440` (read-only even for its owner — edit via `visudo`).
- `cat /etc/shadow` as regular user → `Permission denied`, as expected.
- `stat ~/.zshrc` vs `stat /etc/passwd` — both `0644/-rw-r--r--`, but
  different owners (`kaimikan` vs `root`). This led to the key insight
  below.

### Key insight that clicked this session
Same mode string ≠ same effective access. `~/.zshrc` and `/etc/passwd`
are both `0644`, but Kai has `rw-` on his zshrc (he's the owner → owner
triplet applies) and only `r--` on `/etc/passwd` (he's not owner, not in
group root → "other" triplet applies). The mode describes *potential*
access per category; which category applies depends on who you are
relative to the file. Verified with `echo "# experiment" >> ~/.zshrc`
(succeeds) vs `echo "# experiment" >> /etc/passwd` (permission denied).

### Next up
- **Session 03 — Package management on Arch/CachyOS.**
  - What `pacman` does under the hood: the sync database, the local DB at
    `/var/lib/pacman/`, and where packages come from (repos in
    `/etc/pacman.conf`).
  - The core verbs: `-S` sync/install, `-R` remove, `-Q` query, `-U`
    install from file, `-Syu` full system upgrade (and why you never
    mix `-Sy` without `-u` — "partial upgrades" are the #1 way to brick
    an Arch system).
  - **The AUR** — what it is, what it *isn't* (not an official repo; user
    contributions with real review responsibility on you), and how
    `paru`/`yay` wrap `pacman` + `makepkg` for it.
  - What `arch-update` (which Kai has already run) actually does — it's
    a CachyOS-specific curated wrapper on top of `pacman -Syu` + AUR
    helper + system maintenance tasks.
  - **CachyOS's safety net**: Btrfs snapshots via `snapper` (or
    `limine-snapper-sync`) taken automatically before pacman transactions.
    Rollback workflow if an update breaks the system. This is a major
    reason CachyOS is pleasant for beginners.
  - Windows contrasts: no unified package manager on Windows 10 (third-
    party MSI/exe installers per app; Windows Store for UWP; winget later).
    Linux's unified package-manager-owns-everything model is one of the
    biggest day-to-day quality-of-life wins.

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
