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

### Side findings during Session 02 (recorded in `troubleshooting/`)
- **Battery charge threshold on LOQ 15IRX10.** KDE's "Limit the maximum
  battery charge" toggle is a no-op on this hardware — the standard
  kernel `charge_control_*` sysfs files don't exist for BAT1, and the
  LOQ BIOS doesn't expose a Conservation Mode option either. The fix
  path is the AUR `lenovo-legion-laptop` out-of-tree kernel module, but
  Kai opted to skip it (out-of-tree modules on rolling-release Arch can
  break across kernel updates; the laptop is mostly stationary at home,
  so battery aging is acceptable for now). Documented in
  `troubleshooting/battery-charge-threshold-loq15irx10.md` for revisit
  when either a future kernel adds support or Kai changes his mind.
- **Broken KDE Discover taskbar launcher.** CachyOS ships a default
  Plasma panel that includes a Discover icon, but does not install the
  Discover package — so the launcher points at a missing `.desktop` file
  and KDE complains. Fix: right-click → Unpin. Documented in
  `troubleshooting/kde-discover-broken-launcher.md`.

---

## 2026-04-25 — Session 03: Package management on Arch / CachyOS

Notes saved to `02-package-management/pacman-and-aur.md`.

### Covered
- **The mental shift.** On Linux, the distro's package manager owns all
  installed software, together — one tool, one DB, one cryptographic
  trust chain, one upgrade transaction. On Windows each vendor ships its
  own installer with its own conventions and bundled libraries. The
  Linux model wins on disk space, security update propagation,
  uninstall completeness, and "which package owns this file?" queries.
  The Linux model loses on per-app upgrade independence — partial
  upgrades break Arch.
- **What pacman manages and where.** Configuration in
  `/etc/pacman.conf` + `/etc/pacman.d/`; sync DBs (per-repo) at
  `/var/lib/pacman/sync/`; the local DB at `/var/lib/pacman/local/`;
  the package cache at `/var/cache/pacman/pkg/`. Each has a clear role.
- **Kai's specific repo stack** (in priority order): `cachyos-v3`,
  `cachyos-core-v3`, `cachyos-extra-v3`, `cachyos`, `core`, `extra`,
  `multilib`. The CachyOS v3 repos ship binaries compiled for the
  x86-64-v3 microarchitecture level (AVX2, BMI2, etc.), which the
  i7-13650HX supports — this is a primary source of CachyOS's
  performance reputation. Mainline Arch ships generic 2003-era x86-64
  binaries.
- **The five verbs that compose into all real-world commands.** `-S`
  sync, `-R` remove, `-Q` query local, `-U` install from file, `-F`
  file-DB query. Modifier flags (`-y` refresh, `-u` upgrade, `-i` info,
  `-o` owner, `-l` list-files, `-q` quiet, `-s` search) compose with
  these.
- **The day-to-day commands**: `sudo pacman -Syu` (update everything),
  `sudo pacman -S <pkg>` (install), `sudo pacman -Rns <pkg>` (remove +
  unused deps + config), `pacman -Qi <pkg>` (info), `pacman -Qo <file>`
  (owner). Read-only ops don't need sudo.
- **The `-Sy` footgun.** Arch's #1 newcomer trap. Refreshing the DB and
  installing partially gives you a system with new shared libraries
  paired with old binaries linked against old shared libraries —
  "partial upgrade" — which the Arch wiki treats as unsupported.
  Always `-Syu`, never `-Sy` alone followed by `-S` separately. Muscle
  memory.
- **The AUR.** Community-contributed PKGBUILDs (build recipes, not
  packages). Not official, not signed by Arch, not reviewed by Arch
  developers. Reading the PKGBUILD before installing is the security
  habit. AUR helpers (paru, yay) automate the clone → review → build →
  install flow but don't change the trust model.
- **paru.** CachyOS's pre-installed AUR helper. `paru -Syu` is the
  unified upgrade command (covers both repos and installed AUR
  packages). Build steps run as the regular user; sudo only for the
  final `pacman -U` install step.
- **arch-update** is the CachyOS-specific polish layer (from the
  `cachy-update` package). Wraps `paru -Syu` with pre/post-update
  hygiene (keyring refresh, `.pacnew` detection, cache pruning,
  kernel-reboot reminders) and a tray notification icon. Functionally
  equivalent to `paru -Syu` but with niceties.
- **CachyOS's Btrfs snapshot safety net.** `snap-pac` (libalpm hook at
  `/usr/share/libalpm/hooks/05-snap-pac-pre.hook`) auto-snapshots `/`
  before every pacman transaction. `snapper` manages lifecycle.
  `limine-snapper-sync` exposes snapshots as bootable entries in the
  limine boot menu. Rollback workflow on a broken upgrade: reboot →
  pick previous snapshot in limine → boot the pre-upgrade state →
  optionally `snapper rollback <id>` to make permanent. This safety
  net is a major reason CachyOS is gentle for newcomers; it's
  unavailable on Windows (System Restore is slower/weaker) and
  unavailable on most Linux distros (you'd set it up manually, and
  ext4/xfs don't support snapshots).
- **Decision logged at the end of Session 02 still applies:**
  installing the `lenovo-legion-laptop` AUR module to fix the battery
  threshold issue is deferred. Session 03 made the AUR mental model
  concrete, but didn't change the risk calculus on out-of-tree kernel
  modules.

### Exploration suggested
- `pacman -Qq | wc -l`, `pacman -Qqe | wc -l`, `pacman -Qqm | wc -l` —
  total / explicit / AUR package counts. Expected on this box: 1217 /
  217 / 0.
- `pacman -Qi pacman` — full info on the pacman package itself,
  showing the metadata fields available.
- `pacman -Qo /usr/bin/git`, `pacman -Qo /etc/pacman.conf`,
  `pacman -Qo /etc/fstab` — file ownership lookups.
- `snapper list` — see existing snapshots (at minimum one pair from
  the bootstrap `arch-update` run).

---

## 2026-04-28 — Session 04: MkDocs Material site + a clickable launcher

The lesson is the system itself this time — no separate `.md` reference.
The configuration files (`mkdocs.yml`, `serve.sh`, `docs/` symlinks) are
the artifact, and `02-package-management/pacman-and-aur.md` covered the
pipx prerequisites.

### Covered

- **Static site generators, conceptually.** Markdown source → HTML/CSS/JS
  output. `mkdocs build` produces a static `site/` once; `mkdocs serve`
  runs a local web server + file watcher for the authoring loop. Output
  is just files — deploy anywhere or open with `file://`.
- **Python tooling on modern Linux: PEP 668.** Arch (and Fedora/Debian/
  Ubuntu) mark the system Python as "externally managed." `sudo pip
  install` is blocked by default to prevent pip and pacman from
  clobbering each other's files. The four right ways to install Python
  software now: `pacman -S python-X` (system), `pipx install <cli>`
  (isolated CLIs), `python -m venv` (project-local dev), or as a last
  resort `pip --break-system-packages` (don't).
- **`pipx` mechanics.** Installs each CLI tool into its own venv at
  `~/.local/share/pipx/venvs/<name>/`, and exposes the entry-point
  scripts as symlinks in `~/.local/bin/`. No system pollution; one venv
  per app; clean upgrades and removals.
- **The `pipx install` + `pipx inject` pattern for CLI + plugins.**
  `mkdocs-material` is a *theme* (a library), not a CLI. The first
  attempt — `pipx install mkdocs-material` — correctly failed because
  pipx's mental model is "one CLI per venv." The right pattern:
  `pipx install mkdocs` (creates the CLI venv) followed by
  `pipx inject mkdocs mkdocs-material` (adds the theme into the same
  venv). Cleaner than `--include-deps` which would dump 8 unrelated
  little CLIs into `~/.local/bin/`.
- **Project layout decision.** `docs/` directory with **symlinks**
  pointing at the canonical lesson files in their numbered dirs.
  Source of truth stays where CLAUDE.md declared it; the published
  site is explicitly the set of symlinks in `docs/`. mkdocs follows
  symlinks correctly; git tracks them as 1-line files. No content
  duplication.
- **`mkdocs.yml`** — site metadata, the Material theme with light/dark
  toggle, navigation tree, and a curated set of `markdown_extensions`
  (`admonition`, `pymdownx.highlight`, `pymdownx.superfences`,
  `pymdownx.tasklist`, etc.). Each setting is commented inline so the
  config explains itself.
- **`serve.sh`** — committed shell script that `cd`'s to its own
  directory (so it works regardless of where it's invoked from),
  optionally launches the browser via `xdg-open` if `--open` is passed,
  and `exec`s `mkdocs serve` so Ctrl+C reaches the server cleanly.
  Made executable with `chmod +x` (callback to Session 02 — the `x`
  bit on a file is the difference between data and program).
- **The freedesktop `.desktop` file** at
  `~/.local/share/applications/linux-learning-docs.desktop` — KDE's
  app launcher / Krunner / pinnable taskbar icon. Lives outside the
  repo because it has machine-specific absolute paths. The mechanism
  is the same as the broken Discover launcher we found in Session 02
  — but pointed at a script that exists, with the working directory
  set, and Konsole's `--hold` flag so error output doesn't vanish.
  Launchable via Alt+Space → "Linux Learning" → Enter, or pinned to
  the taskbar for one-click access.
- **`.gitignore`** added — `site/` (build output) and the usual
  Python/editor/OS noise.

### Verified
- `mkdocs build` succeeds in <1s; `site/` is ~3MB (mostly Material's
  theme assets and the search index).
- `mkdocs serve` reachable at `http://127.0.0.1:8000/` with the full
  navigation, search, and dark/light toggle working.
- Live-reload loop: edit a `.md` → mkdocs detects → rebuilds → browser
  auto-refreshes. The authoring loop for everything that follows.
- The `.desktop` file passes `desktop-file-validate`, appears in
  Krunner, can be pinned to the taskbar.

---

## 2026-04-28 — Session 05: Shells: fish, zsh, bash, and the startup-file maze

Notes saved to `03-shell/shells-and-startup-files.md`.

### Covered
- **What a shell actually is.** A userland program that reads commands
  and runs them. Not part of the kernel, not part of the OS in any
  meaningful sense. The kernel's only contract: at login, exec the
  program named in the user's `/etc/passwd` last field. Everything else
  is "an app you happen to run a lot." This is foundationally different
  from Windows where `cmd.exe` and `powershell.exe` ship as part of the
  OS.
- **Shell lineage.** sh (1977) → ksh (1983) → bash (1989) → zsh (1990)
  → fish (2005). Two camps: sh / bash / zsh are POSIX-ish and share
  most syntax; fish *intentionally* broke POSIX compatibility for
  cleaner defaults and out-of-the-box autosuggestions/highlighting.
- **The three "shell" contexts.** Login shell (set in `/etc/passwd`),
  interactive shell (what your terminal launches), script shell (set
  by the shebang). They can all be different. Concrete example from
  this very project: login = fish, interactive = fish, but
  `./serve.sh` runs in bash because of its `#!/usr/bin/env bash`
  shebang. Resolves the "what shell am I in?" confusion conclusively.
- **Where fish breaks bash compatibility** — the practical translation
  table: `set -gx X y` (not `export X=y`), `(cmd)` (not `$(cmd)`),
  `$fish_pid` (not `$$`), `$status` (not `$?`), `for ... end` (not
  `for ... do ... done`), no heredocs, abbreviations as a strict
  upgrade over aliases (`abbr ll 'ls -la'` shows the expansion as you
  type). The practical shortcut: for multi-line bash advice, save it
  to a file with `#!/usr/bin/env bash`, `chmod +x`, run from fish.
- **Startup file order, per shell:**
  - **Fish:** system `config.fish` → `vendor_conf.d/*` → `/etc/fish/conf.d/*` →
    `~/.config/fish/conf.d/*.fish` → `~/.config/fish/config.fish` →
    functions on demand. Pattern: one file per concern in `conf.d/`.
  - **Zsh:** `.zshenv` (every invocation, including scripts) →
    `.zprofile` (login only, pre-zshrc) → `.zshrc` (interactive only) →
    `.zlogin` (login only, post-zshrc) → `.zlogout` (login exit). Env
    vars belong in `.zshenv`. The Session 01 mistake (putting
    `SSH_AUTH_SOCK` in `~/.zshenv` for a fish login shell) is now
    obvious in retrospect.
  - **Bash:** fragmented enough that the standard pattern is to source
    `~/.bashrc` from `~/.bash_profile`.
- **The above-shell escape hatch:** `~/.config/environment.d/<topic>.conf`
  with plain `KEY=VALUE` lines. systemd's PAM hook loads these into the
  user session at login, so every program — every shell, every Konsole
  tab, every GUI app — inherits them. This is what we *should* have
  used for `SSH_AUTH_SOCK` in Session 01.
- **What CachyOS pre-configured in `/usr/share/cachyos-fish-config/`:**
  the `fish_greeting` override that calls `fastfetch` (the system info
  banner you see in new tabs); `MANPAGER` piping man pages through
  `bat` for syntax highlighting; the `__done` plugin notifications
  with a 10-second threshold; `~/.local/bin` PATH addition; classic
  `!!` and `!$` history shortcuts implemented via custom fish
  functions.
- **`chsh` to change login shells**, with the `/etc/shells` whitelist.
  But the right answer for now: **stay on fish for interactive use,
  write scripts with `#!/usr/bin/env bash` shebangs, don't switch.**
  Fish's bash incompatibility matters at script time, and the shebang
  takes care of that.

### Other Session 05 deliverables
- **Lesson roadmap split out** to `lesson-roadmap.md` at the repo root.
  Captures candidate future sessions in three tiers (foundational
  next-picks; medium-term; hardware/security/niche). Each entry lists
  what would be covered, why it matters, and any trigger event.
  Replaces the ad-hoc Backlog section that had been growing in this
  log. Going forward: roadmap is the forward-looking list; daily-log
  records what shipped.

### Next up

Open. Pick from `lesson-roadmap.md` at the start of the next session.
Strong candidates from Tier 1: **text editor**, **processes/systemd**,
**networking basics**, **file manipulation deeper**, or **shell
scripting basics** (which would build directly on this session). Any
of those is a sensible next step.
  Per the original project plan: now that we have 3 lessons of content
  (`filesystem-hierarchy.md`, `users-groups-permissions.md`,
  `pacman-and-aur.md`) plus the daily log and troubleshooting entries,
  it's time to layer a navigable static site on top. The setup is
  itself a lesson:
  - **Python tooling on Arch.** Why you don't `sudo pip install` on
    modern Arch (PEP 668 / externally-managed environments). The
    options: `pipx` for isolated CLI app installs (the right answer
    here), `python -m venv` for project-local virtual environments,
    or system-wide via pacman when an Arch package exists.
  - **Installing `mkdocs-material` via `pipx`** so we don't pollute the
    system Python and we get an isolated, upgradable install.
  - **Project layout** — `mkdocs.yml`, the `docs/` directory, and how
    the existing `01-basics/`, `02-package-management/`, etc. structure
    maps onto it. Decide whether to symlink, copy, or re-root the
    markdown into `docs/`.
  - **`mkdocs serve`** — the local dev server with hot reload.
    Foundational for understanding "edit a file → see the change in
    the browser" workflows on Linux.
  - **The Material theme's basics**: navigation config, search,
    syntax highlighting, dark mode, admonitions (the
    `!!! note` blocks).
  - **A `Makefile` or shell helper** for common operations (`make
    serve`, `make build`, etc.), so we don't have to remember the
    exact commands. Optional but worth it.
  - **What to defer**: deploying to GitHub Pages (a separate session
    when we want the site to be public), navigation polish, custom
    CSS, plugin ecosystem.

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
