# Lesson 1 — The Linux Filesystem Hierarchy

## The core mental model (the WHY)

On Windows, the filesystem is rooted in **drive letters**: `C:\`, `D:\`, and
so on. Each drive is its own tree. The OS lives on `C:\Windows`, your apps
live in `C:\Program Files`, your data lives in `C:\Users\You`. Configuration
for the OS is mostly hidden inside a binary database called the **Registry**.

On Linux there is exactly **one tree**, rooted at `/` (pronounced "slash" or
"root"). Every file on every disk, every USB stick, every network share, and
even many things that aren't files at all (devices, kernel state, running
processes) are represented as paths *under* `/`. There are no drive letters.
When you plug in a second disk, you don't get `D:`; you **mount** it onto
some directory — say `/mnt/photos/` — and its contents appear there as
if they had always been part of the tree.

This unified tree is one of the oldest Unix ideas. It means:

- Every tool in the system can navigate, search, and back up data the same
  way regardless of where it physically lives.
- "Everything is a file" (or at least, everything has a path) — disks,
  terminals, random-number generators, and kernel knobs all live in the
  same namespace you already know how to use.

The layout *within* that tree is standardized by the **Filesystem Hierarchy
Standard (FHS)**. Most Linux distros follow it, with small variations.
CachyOS / Arch follows it with one modern twist called the **usrmerge**
(explained below).

> **Scope:** The FHS is *universal Linux*. Arch's usrmerge is *distro-level
> but increasingly universal* — Fedora, Arch, openSUSE, and modern Debian all
> do it.

---

## The directories, in teaching order

### `/` — the root of everything

The single top of the tree. Not to be confused with `/root` (see below).
Nothing should live *directly* in `/` except the standard top-level
directories themselves.

**Windows analogue:** there isn't one. Windows has many roots (`C:\`, `D:\`);
Linux has one. When you mount a second disk, it appears *inside* `/` somewhere.

### `/home` — user data

Each regular user gets a subdirectory: `/home/kaimikan/` is yours. Your
documents, downloads, shell config, browser profile, SSH keys — all under
here. Conventionally abbreviated as `~` in the shell (so `~/Projects` =
`/home/kaimikan/Projects`).

**Windows analogue:** `C:\Users\<name>\`. Very direct mapping, including the
`~` shorthand (PowerShell has it too).

**Why separate?** You want user data on its own partition (or subvolume, on
Btrfs) so that reinstalling the OS doesn't touch your files, and so backups
can target `/home` without sucking in system binaries.

### `/root` — the root user's home directory

Special case: the **root user** (the all-powerful admin account, UID 0) has
a home directory too, but it isn't `/home/root`. It's `/root`, one level up,
so that root can still log in and find its config even if `/home` (often a
separate partition) fails to mount.

**Windows analogue:** very roughly `C:\Users\Administrator`, but conceptually
different — on Linux you almost never log in as root directly; you `sudo`
individual commands from your own account.

### `/etc` — system-wide configuration

Plain-text configuration files for the whole system. Network config, user
accounts (`/etc/passwd`, `/etc/shadow`), pacman's config, systemd unit
overrides, SSH daemon config, the fstab that describes what gets mounted at
boot — all here.

**Windows analogue:** the **Registry** plus bits of `C:\ProgramData` and
`C:\Windows\System32\config\`. But the analogy breaks in a beautiful way:
`/etc` is **plain text**. You can `cat`, `grep`, `diff`, version-control,
and edit config files with any editor. The Registry is a binary hierarchical
database that needs `regedit`. This is one of the Linux features you will
learn to love.

**Rule of thumb:** `/etc` is for **system** config. **User** config (per-user
preferences for apps) lives in your home directory under `~/.config/`,
`~/.local/`, or sometimes dotfiles directly in `~/` (e.g., `~/.zshrc`).

### `/var` — variable data

"Variable" in the sense of *changes over time while the system runs*.
The system writes here during normal operation. Subdirectories:

- `/var/log/` — system and service logs (analogue: Event Viewer, but plain-text).
- `/var/cache/` — things that can be regenerated if deleted (e.g., pacman's
  package cache at `/var/cache/pacman/pkg/`).
- `/var/lib/` — persistent state for services: databases, package manager
  metadata (`/var/lib/pacman/` is pacman's brain), Docker images, etc.
- `/var/tmp/` — temp files that should survive a reboot (unlike `/tmp`).
- `/var/spool/` — queued work (print jobs, cron spool, mail queue).

**Windows analogue:** `C:\ProgramData` (app state) + `C:\Windows\Logs` +
`C:\Windows\Temp`, scattered. On Linux, the convention concentrates it under
one top-level name.

**Why separate?** Logs and caches can grow unboundedly. Putting `/var` on its
own partition (common on servers) means a runaway log file can't fill up the
partition that holds the OS binaries and crash the machine.

### `/usr` — the userland (installed programs and their support files)

The acronym originally meant *user* — historically, user home directories
lived here. Today it's re-interpreted as **Unix System Resources**, and it
holds the vast majority of the OS: installed programs (`/usr/bin`),
libraries (`/usr/lib`), headers (`/usr/include`), shared data like icons and
man pages (`/usr/share`), and locally installed stuff (`/usr/local`).

**Windows analogue:** `C:\Program Files` + `C:\Windows\System32` +
`C:\Windows\SysWOW64`. This is where "the OS and its installed software"
lives on Linux.

**Why separate?** Historically, `/usr` could be mounted **read-only** or
even over the network (diskless workstations mounting a shared `/usr` from
a server was a 1980s thing). The boot essentials lived in `/bin`, `/sbin`,
`/lib` at the root, so the system could boot before `/usr` was available.

### `/bin`, `/sbin`, `/lib`, `/lib64` — and the **usrmerge**

Historical split:

- `/bin` — essential binaries for all users (`ls`, `cp`, `mv`, `cat`).
- `/sbin` — essential system binaries for the admin (`mkfs`, `fdisk`, `ip`).
- `/lib`, `/lib64` — libraries those binaries need to run.

The rationale was that these were needed *before* `/usr` was mounted, so they
had to live outside `/usr`. Modern Linux does initramfs at boot, which
obviates the concern. So Arch, Fedora, and most modern distros have done the
**usrmerge**: `/bin`, `/sbin`, `/lib`, `/lib64` are now **symlinks** into
`/usr/bin` and `/usr/lib`. Everything ultimately lives in `/usr`.

You'll see this when you run `ls -l /` below — the `l` at the start of
those lines and the `->` arrow in the listing reveal that they're symlinks.

**Scope:** usrmerge is universal on modern Arch/CachyOS, Fedora, openSUSE,
and recent Debian/Ubuntu. Very old systems and some minimal embedded distros
still keep them split.

### `/boot` — the bootloader's working area

Kernel images (`vmlinuz-linux-*`), initramfs images, bootloader config
(GRUB, systemd-boot, rEFInd), and on UEFI systems the EFI System Partition
(ESP) is often mounted at `/boot` or `/boot/efi`.

**Windows analogue:** the hidden EFI System Partition + `C:\Windows\Boot`.
Windows hides this from you by default; Linux exposes it as a normal
directory you can `ls`.

**Treat with care.** Deleting a kernel image from `/boot` can prevent the
system from booting. This is one of the places to slow down.

### `/dev` — device files

"Everything is a file" made literal. Your hardware appears here as files:

- `/dev/nvme0n1` — your NVMe disk.
- `/dev/nvme0n1p2` — the second partition on it (your root filesystem).
- `/dev/sda`, `/dev/sdb` — SATA/USB disks, if present.
- `/dev/null` — a black hole. Write to it, data vanishes. Read from it,
  get EOF immediately. Used to discard output.
- `/dev/zero` — infinite stream of zero bytes.
- `/dev/urandom` — infinite stream of cryptographic-quality random bytes.
- `/dev/tty`, `/dev/pts/*` — terminals.

You interact with hardware by reading/writing these files. That's how `dd`
can clone a disk with `dd if=/dev/sda of=/dev/sdb` — it's just copying bytes.

**Windows analogue:** the `\\.\PhysicalDrive0` and `\Device\*` namespaces
exist but are generally invisible to users. Linux puts them front-and-center.

**Warning:** `/dev` is where the most dangerous commands operate. Writing
to the wrong device file (`dd of=/dev/sda` when you meant `/dev/sdb`) will
silently and instantly destroy data with no undo. We'll cover `dd` and
partitioning with the respect they deserve in a later session.

### `/tmp` — ephemeral temporary files

Scratch space. On most modern systems including CachyOS, `/tmp` is a
**tmpfs** — a filesystem that lives in RAM — so it's fast and gets wiped
on every reboot. Any program that needs to write a temp file defaults here.

**Windows analogue:** `%TEMP%` / `C:\Users\<you>\AppData\Local\Temp` and
`C:\Windows\Temp`.

Don't put anything here you want to keep past a reboot. Don't put large
files here either — since it's RAM, you can fill up memory. For persistent
temp, use `/var/tmp`.

### `/opt` — optional, self-contained third-party software

Historically for packages that don't follow the FHS layout — things that
ship as "one big vendor directory with all their own binaries, libs, and
data." Google Chrome installs at `/opt/google/chrome/`. Some proprietary
apps like JetBrains IDEs and Android Studio go here.

**Windows analogue:** pretty much all of `C:\Program Files\*` — that's how
Windows apps are *normally* laid out (everything bundled per-app). On Linux
it's the exception, used only when an app refuses to follow the
`/usr/bin` + `/usr/lib` + `/usr/share` split.

### Others you'll see but we won't dwell on yet

- `/mnt` and `/media` — mount points for external drives. `/media` is
  where the desktop auto-mounts USB sticks; `/mnt` is for manual mounts.
- `/proc` — a virtual filesystem exposing kernel and process state as files.
  `cat /proc/cpuinfo`, `cat /proc/meminfo`. Not on disk — the kernel
  synthesizes it on read.
- `/sys` — another virtual filesystem for device and driver state. Where
  you change brightness, fan speed, etc. from the shell.
- `/run` — runtime state for running services (PID files, sockets). Tmpfs.
- `/srv` — data served by services (web server roots, FTP, etc.).
  Convention; often unused on desktops.

`/proc` and `/sys` are the Linux superpower equivalent of Windows'
Performance Counters + WMI + Registry-runtime-keys — but as plain files you
can `cat` and `grep`. We'll explore them properly in a later session.

---

## Why split things up at all — the summary

1. **History:** separate partitions for separate purposes. `/usr`
   read-only or network-mounted; `/var` on a disk big enough for logs;
   `/home` preserved across reinstalls; `/boot` small and on something
   the bootloader understands.
2. **Backup policy:** `/home` gets backed up nightly; `/var/cache` never;
   `/etc` gets version-controlled. A clean layout makes those rules easy.
3. **Permissions and safety:** different trees can have different owners
   and mount options (noexec, nosuid, ro). `/tmp` often mounted `noexec`
   to block a class of attacks.
4. **Separation of concerns:** the OS (`/usr`), its config (`/etc`), its
   runtime state (`/var`), the user's stuff (`/home`), and the hardware
   (`/dev`) are each in their own place. You always know where to look.

Windows achieves some of the same goals, but more loosely — a single
`Program Files` dir holds each app's OS files, config, and data mashed
together, while user data lives in `Users`, the Registry hides config in a
binary DB, and Event Viewer hides logs behind an API. The Linux split is
older, more granular, and more *visible*.

---

## Exploration commands

Run these and read the output carefully. The point isn't the output itself;
it's training your eye to recognize the hierarchy.

### 1. `ls -l /` — the top of the tree, with symlinks revealed

```
ls -l /
```

- `ls` — list directory contents.
- `-l` — "long" format: one entry per line, with permissions, owner, size,
  and modification time. Crucially, also shows **symlink targets** via `->`.

What to look for:

- Lines starting with `d` are directories: `home`, `etc`, `var`, `usr`, `opt`,
  `root`, `boot`, `tmp`, `mnt`, `srv`, `proc`, `sys`, `dev`, `run`.
- Lines starting with `l` are **symlinks**. On CachyOS you'll see
  `bin -> usr/bin`, `sbin -> usr/bin`, `lib -> usr/lib`, `lib64 -> usr/lib`.
  That's the usrmerge in action — exactly what we discussed above.
- The first character of each line encodes the file type (`d` dir, `l` link,
  `-` regular file). Positions 2–10 are the permission bits (`rwx` × owner,
  group, other) — next lesson.

### 2. `ls /etc | head` — peek at system config

```
ls /etc | head
```

- `ls /etc` — list contents of `/etc`.
- `|` — **pipe**: sends the output of the left command as input to the right command.
- `head` — prints the first 10 lines of its input (default). Use `-n 20` for
  the first 20. Prevents a long flood on directories with hundreds of entries.

You should see files like `passwd`, `shadow`, `group`, `fstab`, `hostname`,
`hosts`, `os-release`, and directories like `pacman.d/`, `systemd/`,
`ssh/`. Try `cat /etc/os-release` afterwards — it's the standard place
distros declare their identity. `cat /etc/hostname` shows your machine's
name. These are plain text. You can read them all.

### 3. `df -hT` — what's mounted, where, and on what filesystem

```
df -hT
```

- `df` — "**d**isk **f**ree": shows filesystem usage per mount point.
- `-h` — **h**uman-readable sizes (`12G`, `340M` instead of raw 1K blocks).
- `-T` — show the filesystem **T**ype column (btrfs, tmpfs, vfat, etc.).

What to look for:

- A `btrfs` line mounted at `/`. The **Filesystem** column will say
  `/dev/nvme0n1p2` — that's your root partition, matching what you told me.
- Multiple **tmpfs** lines (in-RAM filesystems) mounted at `/run`, `/tmp`,
  `/dev/shm`, and per-user `/run/user/1000`. Wiped on reboot.
- A `vfat` or `efivarfs` line around `/boot` or `/boot/efi` — the UEFI
  partition, which must be FAT32 because that's what firmware understands.
- If you have any other disks/partitions mounted, they'll show here too.

Bonus observation: you may see the same `/dev/nvme0n1p2` device listed
multiple times at different mount points. That's Btrfs **subvolumes** — one
physical filesystem presented as multiple logical mounts. Your root is
subvolume `/@`, and there are likely sibling subvolumes for `/home`,
`/var/log`, etc. We'll cover Btrfs subvolumes and snapshots properly in a
later session — they are one of the biggest wins of your CachyOS setup.

---

## Cheat-sheet takeaways

- One tree, rooted at `/`. No drive letters.
- `/home` = user data, `/etc` = system config (plain text!), `/var` =
  changing state (logs, caches, service data), `/usr` = the OS and its apps,
  `/boot` = kernel + bootloader, `/dev` = hardware as files, `/tmp` = RAM
  scratch, `/opt` = self-contained third-party apps.
- `/bin`, `/sbin`, `/lib`, `/lib64` are symlinks into `/usr` on modern distros.
- `/proc` and `/sys` are virtual — they don't live on disk.
- When in doubt: `ls -l` tells you *what* something is (dir, file, symlink);
  `df -hT` tells you *where* and *on what* it's stored.
