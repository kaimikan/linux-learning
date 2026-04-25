# Lesson 3 — Package management on Arch / CachyOS

## The mental model

On Windows, software installation is a **per-app affair**. Each vendor
ships their own `.exe` or `.msi` installer. Each installer makes its own
choices about where to put files (`C:\Program Files\<Vendor>\<App>\`),
how to register the app for uninstall (Registry entries under
`HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\`), and whether
to bundle its own copies of any shared libraries it needs. There's no
central registry that tracks *every file from every installed app*. The
"Installed Apps" list in Settings is essentially a UI on top of those
Registry uninstall entries.

On Linux, the **distro's package manager owns all installed software,
together**. On Arch (and CachyOS by extension), that's `pacman`. The
package manager knows:

- Every package installed on the system, with version and install date.
- Every file each package contributed.
- The dependency graph between packages.
- Which packages are explicitly-installed (you asked for them) vs.
  pulled in as dependencies (you got them for free).
- Cryptographic signatures verifying every package came from where it
  claimed.

This unified accounting is one of Linux's biggest day-to-day quality-of-
life wins compared to Windows. You can ask the system "which package
owns `/usr/bin/git`?" and get an authoritative answer
(`pacman -Qo /usr/bin/git` → `git 2.x-y`). You can ask "what files did
the `tree` package install?" and get a complete list. You can upgrade
*every* package in one command, with shared libraries getting upgraded
once and benefiting every package that depends on them.

The trade-off: package upgrades happen as a coordinated transaction.
Mixing newly-built and old packages on the same system breaks things
(see "the `-Sy` footgun" below). On Windows each app has its own
upgrade cadence, with redundancy as the cost.

> **Scope:** every Linux distro has a primary package manager. The
> *commands* differ: `pacman` on Arch/CachyOS, `apt`/`dpkg` on
> Debian/Ubuntu, `dnf`/`rpm` on Fedora/RHEL, `zypper` on openSUSE. The
> *concepts* (repos, package files, local DB, dependency resolution,
> hooks) are universal. Windows' `winget` and `choco` are partial
> retrofits of this model — they coexist with traditional installers,
> rather than owning the OS the way a Linux package manager does.

---

## What pacman actually manages

Four locations are worth knowing:

### 1. The configuration: `/etc/pacman.conf` + `/etc/pacman.d/`

This file declares which **repositories** pacman pulls from, plus
options like `SigLevel` (signature verification policy), `ParallelDownloads`,
`Color`, etc. Each `[repo-name]` block enables a repo; the `Include`
directive points at a *mirror list* (a list of HTTP/HTTPS URLs serving
the same content from different geographies).

### 2. The sync databases: `/var/lib/pacman/sync/`

When you run `pacman -Sy` (or `-Syu`), pacman downloads small per-repo
databases from the mirrors. Each database is a list of *every package
available in that repo*, with versions, dependencies, sizes, and file
hashes. These files are what `pacman -S <pkg>` consults to find a
package. Without a current sync DB, pacman doesn't know what's available
to install.

### 3. The local database: `/var/lib/pacman/local/`

A directory per installed package, containing metadata about what files
were installed, what version, what dependencies, and any scripts to run
on install/upgrade/removal. This is pacman's "what's on this system"
brain. If this directory got corrupted, pacman would lose track of every
package on the system — backing it up is a real disaster-recovery move.

### 4. The package cache: `/var/cache/pacman/pkg/`

Every package file (`.pkg.tar.zst`) you've ever installed lives here,
including older versions. The cache lets you downgrade a package to its
previous version (useful if an update broke something) without
re-downloading. It also grows unboundedly; `paccache -r` (from the
`pacman-contrib` package) prunes old versions, keeping only the most
recent N.

---

## Your specific repos (CachyOS layout)

From `grep '^\[' /etc/pacman.conf` on this box:

```
[cachyos-v3]
[cachyos-core-v3]
[cachyos-extra-v3]
[cachyos]
[core]
[extra]
[multilib]
```

Read top-to-bottom; **earlier entries have higher priority** when a
package is available in multiple repos.

**The CachyOS-specific repos** (`cachyos-v3`, `cachyos-core-v3`,
`cachyos-extra-v3`, `cachyos`) ship binaries compiled for the
**x86-64-v3** microarchitecture level. Your i7-13650HX (Raptor Lake)
supports v3 (and even v4) — meaning these binaries can use AVX2, BMI2,
and other newer-CPU instructions for measurable performance gains over
the generic `x86-64` binaries that mainline Arch ships. CachyOS's
performance reputation comes substantially from this. Some users see
2–10% improvements on CPU-bound workloads, more on workloads that
benefit from SIMD.

**The official Arch repos** (`core`, `extra`, `multilib`) come after
the CachyOS ones, so packages CachyOS hasn't rebuilt fall through to
the upstream Arch binaries.

- **`core`** — minimum viable Arch system: kernel, glibc, coreutils,
  pacman itself.
- **`extra`** — desktop apps, server software, libraries, languages —
  the bulk of installed software.
- **`multilib`** — 32-bit packages, needed for Steam, Wine, and 32-bit
  games. Disabled by default on minimal Arch but enabled on CachyOS
  because gaming is a target use case.

> **Scope:** the v3/v4 optimization tier is *CachyOS-specific*. Mainline
> Arch may eventually adopt similar tiers. The `core`/`extra`/`multilib`
> split is *Arch-universal*; Manjaro and EndeavourOS use the same
> structure.

---

## The core verbs

`pacman` uses **single-letter operation flags** that compose. The five
foundational ones:

| Op | Stands for | What it does                                                  |
|----|------------|---------------------------------------------------------------|
| `-S` | Sync     | Install from a remote repo, or refresh the sync DB            |
| `-R` | Remove   | Uninstall                                                      |
| `-Q` | Query    | Inspect the local DB (what's installed)                        |
| `-U` | Upgrade  | Install from a local `.pkg.tar.zst` file                       |
| `-F` | File     | Query the *file* database (which package owns/provides a path) |

These compose with **modifier flags** to refine the action:

- `-y` — refresh repository databases (used with `-S`).
- `-u` — upgrade everything that's outdated (used with `-S`).
- `-i` — show detailed info (used with `-Q` or `-S`).
- `-l` — list files in a package.
- `-o` — print which package **owns** a given path.
- `-q` — quiet (less verbose output, machine-readable).
- `-s` — search by name/description (used with `-S` or `-Q`).
- `-w` — download package(s) to cache without installing.
- `-c` — clear the cache (used with `-S`).

### The most-used commands, in practice

```
sudo pacman -Syu                     # The full upgrade. Use this. Always this.
sudo pacman -S <package>             # Install a package and any deps.
sudo pacman -Rs <package>            # Remove a package + its now-unused deps.
sudo pacman -Rns <package>           # Same as -Rs, also removes the package's config files.
pacman -Q                            # List all installed packages.
pacman -Qe                           # List explicitly-installed packages (the ones you asked for).
pacman -Qi <package>                 # Show details about an installed package.
pacman -Qo /path/to/file             # Which package owns this file?
pacman -Ql <package>                 # List all files installed by a package.
pacman -Si <package>                 # Show details about a package in the sync DB (not yet installed).
pacman -Ss <search-term>             # Search the sync DB by name/description.
pacman -Qs <search-term>             # Same, but only across installed packages.
pacman -F <filename>                 # Which package provides this file? (consult file DB)
sudo pacman -Fy                      # Refresh the file DB (occasional).
```

Note that **read-only operations** (`-Q`, `-S` without modifiers like
`-y`/`-u`/`-w`, `-F` without `-y`) **don't need sudo**. Anything that
modifies the system (install, remove, refresh DB, upgrade) does.

---

## ⚠️ The `-Sy` footgun — the #1 Arch newcomer trap

```
sudo pacman -Sy            # DANGEROUS WHEN FOLLOWED BY -S WITHOUT -u
sudo pacman -S firefox     # bricked your system if -Sy was already done
```

What's happening:

- `-Sy` refreshes the sync DB. After this, pacman *thinks* the latest
  available versions of every package are what's on the mirrors right
  now.
- But your *installed* packages are still at whatever versions they were
  before. They haven't been upgraded.
- If you now `-S firefox`, pacman will pull the **latest** firefox and
  its dependencies' **latest** versions. Some of those dependencies are
  *also* dependencies of unrelated installed packages (glibc, openssl,
  zlib — you name it).
- After the install, you have an inconsistent system: the new firefox +
  its new shared libraries, but old versions of every other package
  that depended on those same shared libraries. Some will keep working
  by luck (ABI compatibility); others will crash on first use; the
  worst breakages aren't immediate but show up at the next reboot.

**The rule:** never refresh the DB and install partially. Always do
both in one transaction.

- ✅ `sudo pacman -Syu` — refresh DB **and** upgrade everything **and** install nothing else.
- ✅ `sudo pacman -Syu firefox` — refresh DB, upgrade everything, install firefox in the same coordinated transaction.
- ❌ `sudo pacman -Sy` followed later by `sudo pacman -S firefox` — the bug.

The Arch wiki calls this the "**partial upgrade**" anti-pattern and
treats it as an unsupported configuration — meaning if you break your
system this way and ask for help, you'll be told to reinstall.

If you ever just want to *check* whether updates are available without
applying them, do `pacman -Qu` after a `-Sy`, then either run `-Syu` or
revert with `pacman -S` of nothing (the DB stays refreshed but you
haven't installed anything inconsistent yet, so you're safe — the
problem only manifests when you install a package while the DB is
ahead of your installed state).

In practice: just type `-Syu` every time. Muscle memory.

---

## The AUR — Arch User Repository

The AUR is a **community-driven collection of build recipes** for
software not in the official repos. Two things matter to internalize:

### What the AUR *is*

- A web-based catalog at `aur.archlinux.org`.
- Each entry is a **PKGBUILD** — a shell script that declares: where to
  download upstream source from, how to build it, what dependencies it
  needs, what files end up in the package, and what scripts to run on
  install/upgrade/removal.
- "Installing from the AUR" means downloading the PKGBUILD, building
  the package locally on your machine using `makepkg`, and then
  installing the resulting `.pkg.tar.zst` file via `pacman -U`.
- AUR helpers (paru, yay) automate this download → review → build →
  install loop.

### What the AUR is *not*

- **Not an official Arch repo.** Arch's developers don't review AUR
  packages. The maintainer is a regular community member. The Arch
  team will not help you debug an AUR install that broke your system.
- **Not signed by Arch.** Sync repos (`core`, `extra`) are
  cryptographically signed by Arch's signing keys; pacman verifies each
  package. AUR packages are not signed by Arch — you trust the upstream
  source, the AUR maintainer's PKGBUILD, and your own review of the
  PKGBUILD. If a malicious actor gains control of an AUR package, they
  can run arbitrary code as root during installation.
- **Not always up-to-date.** Some AUR packages are abandoned. Always
  check the "last updated" date and the comments on aur.archlinux.org.

### The security habit

Before installing anything from the AUR:

1. **Read the PKGBUILD.** AUR helpers like `paru` show it to you by
   default and pause for review. Look for: where the source comes from
   (legitimate upstream URL? GitHub? official project page?), and what
   any `prepare()`, `build()`, `package()` functions do. Anything weird
   is a red flag.
2. **Check the package page on aur.archlinux.org** for recent comments
   — if the build is broken or someone reported the maintainer going
   missing, the comments will say so.
3. **Prefer well-maintained packages**: lots of votes, recent updates,
   active maintainer. The AUR has a "popularity" score for this.
4. **`-bin` vs source vs `-git` variants:** many packages have multiple
   AUR entries. `<name>-bin` downloads upstream's prebuilt binary
   (faster install, you're trusting upstream); plain `<name>` builds
   from upstream's release tarball (slower, but auditable);
   `<name>-git` builds from latest git HEAD (bleeding edge, more
   chance of breakage). Pick what matches your tolerance.

> **The lenovo-legion-laptop module** we discussed in Session 02 is
> an AUR package. The reasoning for skipping it ("I don't want an
> out-of-tree kernel module that could break across kernel updates") is
> the same kind of risk-assessment you'll do for every AUR install.
> Most AUR packages are far less risky than out-of-tree kernel modules
> — they're just userspace apps.

---

## paru — the AUR helper

`paru` is a CachyOS pre-installed AUR helper. It wraps `pacman` and
adds AUR-aware operations.

```
paru                          # Interactive search + install (TUI menu).
paru -S <pkg>                 # Install — checks repos first, falls through to AUR.
paru -Syu                     # Upgrade everything: repo packages AND installed AUR packages.
paru -Ss <search-term>        # Search both repo and AUR.
paru -G <pkg>                 # Get the PKGBUILD without building/installing — just clones the AUR repo.
paru -Qua                     # List AUR packages with available updates (Q-uery, U-pdates, A-UR).
```

Notes:

- **`paru` runs as your regular user**, not root, until the actual
  install step (where it elevates via sudo). This is correct: the build
  steps must run as a non-privileged user (security hygiene — you don't
  want `make` running as root). `paru` will prompt for your sudo
  password when it's about to invoke `pacman -U`.
- **`paru` shows you the PKGBUILD** before building. Read it.
- **`paru -Syu` is the unified "update everything" command** for both
  repos and AUR. Without paru, you'd run `pacman -Syu` and then
  separately `paru -Sua` (or similar) for AUR — paru combines them.

> **Scope:** AUR helpers exist on Arch/CachyOS/Manjaro and any
> Arch-derivative. `paru` is one of several (`yay` is the other very
> popular one; `aurman`, `trizen` exist but are less maintained). They
> all do roughly the same thing — pick one and learn it.

---

## arch-update — CachyOS's wrapper

`/usr/bin/arch-update` is owned by the `cachy-update` package
(CachyOS's curated update tool). It's a shell + Python wrapper around
`paru -Syu` (and `pacman -Syu`) that adds:

- A **system tray notification** when updates are available (icon
  updates color when there are pending updates).
- **Pre-update checks**: refreshing keyrings, checking for `.pacnew`
  files (distro config updates that didn't auto-apply), checking
  orphaned packages.
- **Post-update tasks**: cleaning the cache (with `paccache`),
  prompting about removing unused dependencies, reminding you to
  reboot if the kernel was updated.

You ran this once already during your CachyOS bootstrap (it's the same
"first arch-update" we noted in the Session 01 log). You can keep using
it for routine updates, OR you can run `paru -Syu` directly — they end
up making the same changes; arch-update just adds polish.

> **Scope:** *CachyOS-specific*. Vanilla Arch doesn't have arch-update;
> users there run `pacman -Syu` (or their AUR helper's equivalent)
> directly. Other distros have their own equivalents (`apt update &&
> apt upgrade` chains on Debian/Ubuntu, `dnf upgrade` on Fedora).

---

## The Btrfs snapshot safety net (CachyOS's killer feature)

This is the thing that makes Arch tractable for newcomers, and one of
the biggest reasons CachyOS is a great choice for someone learning.

### The mechanism

Three pieces interact:

1. **Btrfs subvolumes + snapshots.** Btrfs is a copy-on-write
   filesystem. A "snapshot" is a near-instant clone of a subvolume —
   creating one takes microseconds and zero extra space at first
   (only blocks that change after the snapshot consume new space).
2. **`snapper`** — the snapshot manager. It owns the policy: how often
   to take snapshots, how many to keep, when to clean old ones.
3. **`snap-pac`** — a libalpm hook (lives in
   `/usr/share/libalpm/hooks/05-snap-pac-pre.hook`) that **runs before
   every pacman transaction** and asks snapper to create a "pre"
   snapshot. After the transaction, a "post" snapshot.
4. **`limine-snapper-sync`** — a service that updates the **limine
   bootloader's** menu after snapshots are created, so previous
   snapshots show up as bootable entries in your boot menu.

### The workflow when an update breaks something

1. You run `sudo pacman -Syu` (or `arch-update`).
2. snap-pac auto-creates a "pre" Btrfs snapshot of `/` *before* pacman
   runs.
3. pacman applies the upgrade. Suppose it breaks something — kernel
   doesn't boot, video driver crashes the desktop, etc.
4. Reboot. At the limine boot menu, pick the **previous snapshot**.
5. The system boots from the pre-upgrade state. You're back.
6. From there, you can either roll back permanently (`snapper rollback
   <id>`) or investigate the failure with the broken state still
   available as another snapshot.

This is a level of safety that's *unavailable on Windows* (Windows'
System Restore is far slower, less reliable, and doesn't snapshot user
data the same way) and *unavailable on most Linux distros* (you'd have
to set this up manually, and on ext4/xfs you can't because they don't
support snapshots).

### Day-to-day relevance

You probably won't need to roll back often. But knowing it's there
lowers the cost of trying things. Arch users on ext4 are rightly
conservative about what they install; CachyOS users with snap-pac can
be more adventurous because the worst case is "boot the previous
snapshot, the broken state is gone."

### Useful snapshot commands

```
snapper list                     # See all snapshots.
snapper list-configs             # See which subvolumes are tracked (root, home).
sudo snapper -c root create-config /                   # one-time setup (CachyOS does this for you)
sudo snapper -c root create --description "manual"     # take a snapshot manually
sudo snapper -c root delete <number>                   # delete a specific snapshot
```

> **Scope:** *CachyOS does this out of the box*. On vanilla Arch you'd
> install `snapper`, `snap-pac`, `grub-btrfs` (or `limine-snapper-sync`)
> and configure them yourself. The Arch wiki has the recipe. On
> non-Btrfs filesystems you can't do this — the filesystem itself has to
> support snapshots.

---

## Windows contrasts in one table

| Concept                           | Linux (Arch/CachyOS)                                      | Windows                                                                  |
|-----------------------------------|-----------------------------------------------------------|--------------------------------------------------------------------------|
| Where does software come from?    | One repo system per distro, signed                        | Each vendor's website (.exe/.msi), Microsoft Store (UWP), winget         |
| Centralized installed-list?       | Yes — `pacman -Q` is authoritative                         | Sort of — Add/Remove Programs derived from registry uninstall keys       |
| Shared libraries                  | One copy, used by all packages depending on it             | Each installer typically bundles its own                                 |
| Security updates to a library     | Update once, every package benefits immediately            | Each vendor must ship their own update                                   |
| Cryptographic verification        | Pacman verifies signatures by default for repo packages    | Authenticode signatures exist but enforcement is per-installer policy    |
| Uninstall completeness            | `pacman -Rns` removes every file the package installed     | Per-installer; many leave behind config and registry cruft               |
| Rollback                          | Btrfs snapshots (CachyOS) — instant, near-free             | System Restore — slow, less reliable                                     |
| Update cadence                    | Coordinated — system-wide upgrade in one transaction       | Per-app, asynchronous                                                    |
| Trade-off                         | Must keep system consistent (`-Syu`); partial upgrades break | Apps can be updated independently; library duplication                   |

---

## Exploration commands

All read-only (no `sudo` needed). Run them and read the output.

### 1. `pacman -Q` summary

```
pacman -Qq | wc -l
pacman -Qqe | wc -l
pacman -Qqm | wc -l
```

Flag-by-flag:

- `-Q` — query the local DB (installed packages).
- `-q` — **q**uiet: print only package names, not version strings. This
  makes the output pipe-friendly.
- `-e` — only **e**xplicitly-installed packages (the ones you actually
  asked for; not deps).
- `-m` — only foreign / locally-built packages (the AUR ones).
- `wc -l` — count lines (so we get the count rather than the list).

Expected on your system right now: ~1217 total installed, ~217 explicit,
0 from the AUR.

### 2. Inspect a real package

```
pacman -Qi pacman
```

- `-i` — show detailed **i**nfo. With `-Q` it's info about the locally-installed copy.

You'll see fields like Name, Version, Description, Architecture, URL,
Licenses, Groups, Provides, Depends On, Optional Deps, Required By,
Optional For, Conflicts With, Replaces, Installed Size, Packager,
Build Date, Install Date, Install Reason, Install Script, Validated By.

The "Required By" field tells you which other installed packages
depend on this one — useful before considering removal.

### 3. Who owns this file?

```
pacman -Qo /usr/bin/git
pacman -Qo /etc/pacman.conf
pacman -Qo /etc/fstab
```

- `-o` — which package **o**wns this path.

`/usr/bin/git` should report the `git` package. `/etc/pacman.conf`
should report `pacman` (the package owns its own config). `/etc/fstab`
should report `filesystem` — the very-base package that lays out the
top-level directory structure.

### 4. Search

```
pacman -Ss '^htop$'
```

- `-Ss` — **s**earch the sync DB by name/description.
- `'^htop$'` — regex: name must be exactly "htop" (anchors prevent
  matching things like "btop" or "htop-vim").

You'll see whether `htop` is installable from your repos, plus its
description and version.

### 5. List the repos pacman is using

```
grep '^\[' /etc/pacman.conf
```

- `grep '^\['` — match lines starting with `[`. The `^` anchors the
  match to the start of line.

You'll see the repo block headers — `[options]`, the seven repos,
in the priority order they're consulted.

### 6. See your snapshot history

```
snapper list
```

(No flags needed.) This shows all Btrfs snapshots tracked by snapper,
including pre/post pairs created by snap-pac before each pacman
transaction. You should see one snapshot pair from when you ran
`arch-update` during your CachyOS bootstrap.

---

## Cheat-sheet takeaways

- One package manager owns everything; this is the philosophical core
  of Linux distros vs Windows.
- The verbs you'll actually type:
  `sudo pacman -Syu` (update),
  `sudo pacman -S <pkg>` (install),
  `sudo pacman -Rns <pkg>` (remove),
  `pacman -Qi <pkg>` (info),
  `pacman -Qo <file>` (which package owns).
- **Always `-Syu`, never `-Sy`-then-`-S`.** This is the Arch newcomer
  killer.
- AUR = community PKGBUILDs, not official, not signed. **Read the
  PKGBUILD before installing.** `paru` is your helper.
- `arch-update` is CachyOS's polish on top of `paru -Syu`. Use it or
  `paru -Syu` directly; same effect.
- Snap-pac + snapper + limine-snapper-sync = automatic pre-upgrade
  snapshot, bootable from limine. This is the safety net that makes
  CachyOS gentle for newcomers.
- v3 / v4 CachyOS-specific repos ship binaries optimized for newer
  CPUs. Yours qualifies — you're getting the optimized ones by default.
