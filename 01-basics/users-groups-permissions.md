# Lesson 2 — Users, groups, permissions, and `sudo`

## The mental model

Linux's security model for files and processes is **radically simpler than
Windows' ACL model**, and that simplicity is a feature, not a limitation.
Two ideas do most of the work:

1. **Every user is a UID (an integer). Every group is a GID (another integer).**
   Names like `kaimikan` or `wheel` are just human-friendly labels for those
   integers, looked up in `/etc/passwd` and `/etc/group`. The kernel only
   ever thinks in integers.
2. **Every file has exactly one owner UID, one group GID, and nine permission
   bits** (read / write / execute, for each of: owner, group, everyone else).
   That's it. 12 bits per file (nine plus three special bits we'll cover later),
   and the same 12 bits on every file on the system. No inheritance rules,
   no ACLs (by default), no complex evaluation order.

Windows' model, by contrast, attaches an **ACL (Access Control List)** to
each securable object — an ordered list of rules like "Alice can read,
deny Bob write, inherit from parent, grant Administrators full control."
Far more expressive, but also harder to audit ("who can actually read this
file?" can require walking inheritance and evaluating rule order), and
richer than most users ever need.

> **Scope:** the UID/GID + rwx model is *universal Unix* — the same on Linux,
> macOS, FreeBSD, every distro. POSIX ACLs (`setfacl`/`getfacl`) exist on
> Linux too but are rarely used on desktop systems. We'll stick to the
> classic model; it covers 95% of what you'll encounter.

---

## The three permission bits: `r`, `w`, `x`

Each file has three bits granted to each of three categories (owner, group,
other), giving 9 bits total.

**For a regular file:**

- `r` (read) — can read the file's contents.
- `w` (write) — can modify the file's contents.
- `x` (execute) — can run the file as a program. Required for scripts and
  binaries; irrelevant for data files.

**For a directory** — same letters, different meanings:

- `r` (read) — can **list** the directory's entries (e.g., `ls`).
- `w` (write) — can **add, rename, or delete entries** inside the directory.
  Crucially, this is about the *directory* not the files in it: to delete a
  file, you need `w` on its parent directory, not on the file itself.
- `x` (execute) — can **traverse into** the directory (`cd` into it, or
  access specific paths inside it). Without `x`, the directory is opaque
  even if `r` is set.

The directory distinction is the single most common source of "why can't I
touch this file" confusion on Linux. A directory with `r--` lets you `ls`
its contents but not `cd` into it; `--x` lets you `cd` in (and access files
by full path if you know their names) but not `ls`; `r-x` is the normal
readable-directory combo.

---

## Owner, group, and other — and first-match-wins

Every file records two IDs and three permission triplets:

- The **owner UID** — one specific user.
- The **group GID** — one specific group.
- Three permission triplets — for the owner, for the group, and for "other"
  (everyone else).

When a process tries to access a file, the kernel decides which triplet
applies using a **first-match** rule:

1. If your effective UID matches the owner UID → **owner** bits apply (only).
2. Else, if your effective GID or any of your supplementary group GIDs match
   the file's group GID → **group** bits apply (only).
3. Else → **other** bits apply.

**This is not cumulative.** If you're the owner but the owner triplet says
`---`, you can't access the file even if group says `rwx`. The owner
triplet is evaluated and that's the end. This sometimes surprises people
who assume "more specific = more privileged."

---

## Reading `ls -l` output

Run `ls -l /etc/passwd /etc/shadow /etc/sudoers /etc/group` and you'll see
something like:

```
-rw-r--r-- 1 root root 1998 24 апр 21:55 /etc/passwd
-rw------- 1 root root  975 24 апр 21:55 /etc/shadow
-r--r----- 1 root root 5031 11 яну 00:15 /etc/sudoers
-rw-r--r-- 1 root root 1085 24 апр 21:55 /etc/group
```

Column by column:

| Column              | Example        | Meaning                                              |
|---------------------|----------------|------------------------------------------------------|
| Type + perms        | `-rw-r--r--`   | 10 characters, decoded below                         |
| Hardlink count      | `1`            | How many directory entries point at this inode       |
| Owner               | `root`         | Owning user                                          |
| Group               | `root`         | Owning group                                         |
| Size (bytes)        | `1998`         | File size. Use `-h` with `ls` for human units        |
| mtime               | `24 апр 21:55` | Last modification time                               |
| Name                | `/etc/passwd`  | Path                                                 |

**The 10-character permission string** decomposes as:

```
-   rw-   r--   r--
│   │     │     │
│   │     │     └─ "other" triplet
│   │     └─────── "group" triplet
│   └───────────── "owner" triplet
└───────────────── file type (- file, d dir, l symlink, c char dev, b block dev, s socket, p pipe)
```

So `/etc/passwd` is a regular file, owner `root` can read and write, group
`root` and everyone else can only read. `/etc/shadow` (password hashes) is
root-only: only the owner can read or write, nobody else gets anything.
`/etc/sudoers` is `r--r-----` — readable by owner *root* and group *root*,
denied to everyone else, and not writable by anyone directly (even root —
you're expected to use `visudo`, which is a wrapper that re-checks syntax
before committing).

### Why `/etc/passwd` is world-readable

Surprising at first: a password file that anyone can read? The name is
historical. `/etc/passwd` hasn't actually contained passwords since the
early 90s. It's the username → UID → home directory → shell mapping, which
has to be world-readable so `ls -l` can print owner names, `whoami` can
work, etc. The password hashes were moved to `/etc/shadow`, which is
strictly root-readable. This split is called the **shadow password suite**
and is universal on modern Unix.

---

## Octal notation

The 9 permission bits are three 3-bit numbers, so you can write them as
three octal digits. In each triplet:

```
r  w  x
│  │  │
4  2  1
```

Add them up for the value. The common modes memorized by everyone:

| Octal | Symbolic      | Typical use                                                |
|-------|---------------|------------------------------------------------------------|
| `600` | `rw-------`   | Private files: SSH keys, shell history (`~/.zsh_history`)  |
| `644` | `rw-r--r--`   | Normal data files (text, images, docs)                     |
| `700` | `rwx------`   | Private directories: `~/.ssh`, `~/.gnupg`                  |
| `755` | `rwxr-xr-x`   | Executables, most directories                              |
| `750` | `rwxr-x---`   | Shared executable or dir within a group, denied to others  |
| `666` | `rw-rw-rw-`   | World-writable file (rare; almost always a mistake)        |
| `777` | `rwxrwxrwx`   | World-writable everything — **the classic footgun**        |

Octal shines for *setting a known state*; symbolic notation (next section)
shines for *modifying specific bits*.

---

## `chmod` — changing permissions

Two syntaxes: **symbolic** and **octal**.

### Symbolic form

```
chmod <who><op><perms> file...
```

- `<who>` — one or more of `u` (user/owner), `g` (group), `o` (other), `a` (all).
- `<op>` — `+` (add), `-` (remove), `=` (set exactly).
- `<perms>` — any combination of `r`, `w`, `x`.

Examples:

- `chmod u+x script.sh` — add execute for the owner.
- `chmod go-w file` — remove write for group and other.
- `chmod a=r file` — set all three triplets to read-only exactly (`r--r--r--`).
- `chmod u+x,go-w file` — multiple clauses, comma-separated.

Symbolic form is great when you want to *change* some bits without caring
about the rest.

### Octal form

```
chmod <mode> file...
```

Where `<mode>` is three octal digits: owner, group, other.

- `chmod 644 file` → `rw-r--r--`.
- `chmod 755 script.sh` → `rwxr-xr-x`.
- `chmod 600 ~/.ssh/id_ed25519` → `rw-------`.

Octal is great when you want to *set an exact known state*. It's also what
you'll see in scripts, tutorials, and Stack Overflow answers — so the common
modes (`600`, `644`, `700`, `755`) become muscle memory quickly.

### Recursive: `-R`

```
chmod -R 755 some_dir
```

Applies the mode to `some_dir` and everything beneath it.

### ⚠️ The `chmod -R 777` footgun

`chmod -R 777 something` is the canonical "I'll just make it work"
anti-pattern, and it's almost always wrong. Problems:

1. **It grants the world write access** to everything under the target —
   which usually isn't what you actually want. The real problem is almost
   never "permissions too restrictive for the world," it's "the wrong
   *owner* or *group* is set." Fix ownership with `chown` instead of
   widening permissions.
2. **It sets the `x` bit on regular data files** (because `7` = `rwx`).
   Now every `.txt`, `.json`, `.png` under the tree is "executable." Some
   tools treat that as meaningful; many don't. Either way, it's noise.
3. **Some programs refuse to operate on world-writable files.**
   SSH is famous for this: if `~/.ssh` or `~/.ssh/id_ed25519` is group or
   other writable, OpenSSH will refuse to use it — a security check, not a
   bug. `chmod -R 777 ~/.ssh` would immediately break SSH.
4. **It's almost always a symptom of a different problem** — usually
   ownership mismatch (files owned by root in a dir you're writing as
   yourself) or missing group membership. Fix the root cause.

**Rule of thumb:** if you find yourself reaching for `chmod 777`, stop and
check `ls -l` for the ownership first. 90% of the time `chown` or group
membership is the real answer.

### Safety habit: preview before recursing

`chmod` has no dry-run flag, but you can get the same effect with `find`:

```
find some_dir -type f -perm 644 -exec echo chmod 600 {} \;
```

That *prints* what it would do (the literal word `echo` makes it harmless)
without actually changing anything. Remove the `echo` when you're confident.

---

## `chown` — changing ownership

```
chown <new-owner> file...
chown <new-owner>:<new-group> file...
chown :<new-group> file...
```

- Owner only: `chown kaimikan file`.
- Owner and group: `chown kaimikan:users file`.
- Group only (note the leading colon): `chown :users file`.

**You almost always need `sudo` for `chown`.** Regular users can't change
file ownership (even to give a file away to someone else) — only root can.
This is a deliberate security choice: otherwise, you could drop an
innocent-looking file in another user's home, `chown` it to them, and any
script that runs as them would execute it.

### ⚠️ `chown -R` and symlinks

`chown -R` by default follows *directories* but not *symlinks*. You almost
never want `-H` or `-L` (which follow symlinks) because they'll change
ownership of things outside the tree you thought you were operating on.
Default (`-P`, don't follow) is safe.

**Warning in practice:** `sudo chown -R kaimikan /` would rewrite the owner
of every file on the system to you, completely breaking it. Always
double-check the target path before running a recursive chown as root.

---

## The root user and why you don't log in as them

**Root (UID 0) is special.** The kernel grants UID 0 a bypass on all
permission checks, plus a long list of "capabilities" that regular users
don't have (mounting filesystems, opening privileged sockets, loading
kernel modules, killing any process, etc.).

That power is both why you need it sometimes and why you should be careful
with it. Logging in as root interactively is discouraged on Linux because:

1. **Every command runs with full privileges.** A typo that removes `.`
   when you meant `./foo` is painful as a regular user (scoped to your
   `~/`); as root, it's catastrophic (scoped to your disk).
2. **No audit trail.** When you log in as root, every action is attributed
   to "root." When you `sudo`, it's logged as "kaimikan did X via sudo" in
   `/var/log/auth.log` (or the journal). Matters on multi-user systems.
3. **It breeds bad habits.** Once you're root, there's no natural pause
   before destructive commands. `sudo` forces a moment of "do I really
   want to do this?" by requiring re-authentication.

On CachyOS and most modern distros, **the root account exists but has no
password set for interactive login**. You administer the system via
`sudo`, which elevates individual commands.

### `sudo`: the modern way to be root, briefly

`sudo <command>` runs `<command>` as root (by default) after authenticating
that *you* are allowed to. It asks for *your* password, not root's. After
entering your password, it caches the authentication for 5–15 minutes
(depending on config) so you don't retype on every subsequent command.

**What gates sudo access?** A config file at `/etc/sudoers`, which on
Arch/CachyOS has a line like:

```
%wheel ALL=(ALL:ALL) ALL
```

Translation: members of the group `wheel` may run any command, as any
user, from any host. The `%` means "group" (rather than a username).

This is why the **`wheel` group** is so important: it's the gate. If
you're in `wheel`, you can sudo. If you're not, you can't (absent other
rules).

**Scope:** the `wheel = sudo` convention is universal on Arch/CachyOS,
Fedora, RHEL, openSUSE, macOS. Debian/Ubuntu historically use the `sudo`
group instead of `wheel`; same idea, different name. *Ubuntu also inherits
`wheel` in some places but tends to prefer `sudo`.*

### Windows contrast: sudo vs UAC

- **UAC** (User Account Control) elevates **a whole process**. Once you
  approve the prompt, the launched app runs elevated for its lifetime.
- **sudo** elevates **a single command**. Each command is a separate
  decision, and the elevation ends when that command exits.

The sudo model is finer-grained and leaves a cleaner audit trail, but
requires more deliberate use. Both serve the same goal: make privilege
escalation an explicit, observable act.

---

## Groups

Groups let multiple users share permissions on files. Your user has:

- **A primary group** — the single GID stored in your `/etc/passwd` entry.
  Files you create default to this group. On CachyOS, each user gets a
  group matching their own username (the **"user-private groups"**
  convention from Red Hat, adopted widely): your primary group is
  `kaimikan` (GID 1000), not `users`.
- **Supplementary groups** — additional groups you belong to, listed in
  `/etc/group`. These extend your permissions without changing the default
  group of files you create.

### Your actual groups on this system

From `id` run on your box:

| Group            | GID  | What it grants / why it exists                                        |
|------------------|------|-----------------------------------------------------------------------|
| `kaimikan`       | 1000 | Your user-private group — the default group for files you create       |
| `sys`            | 3    | Legacy admin group; various historical uses                            |
| `network`        | 90   | Access to manage network connections via NetworkManager                |
| `nopasswdlogin`  | 957  | CachyOS/SDDM-specific: allows passwordless login via display manager   |
| `rfkill`         | 979  | Control wifi/bluetooth radio blocks (airplane-mode toggles, etc.)      |
| `users`          | 982  | Common "regular user" group — some shared files are owned by it        |
| `video`          | 983  | Direct access to `/dev/dri/*` (GPU devices), framebuffer               |
| `storage`        | 985  | Access to removable media (USB sticks, external disks)                 |
| `lp`             | 989  | Printing (line printer) access                                         |
| `audio`          | 995  | Direct access to `/dev/snd/*` (ALSA audio devices)                     |
| `wheel`          | 998  | **sudo access** — gatekeeper for administrative commands               |

Most of these you'll never think about. The important ones to remember:

- **`wheel`** — you're in it, you can sudo. Remove yourself and you're
  locked out of administration.
- **`video` / `audio`** — matter for certain apps that go straight to
  hardware rather than through PipeWire/PulseAudio. If you ever hit a
  permission error on a media app, check these.
- **`network`** — NetworkManager access. Without this you can't manage
  wifi as a regular user; you'd need sudo.

### Adding yourself to a group

```
sudo usermod -aG <groupname> <username>
```

Flags:

- `-a` — **append** to supplementary groups. **Critical.**
- `-G` — the **G**roups list to modify (supplementary groups).
- `<groupname>` — the group to add.
- `<username>` — the user to modify. Default is your current user if omitted on some distros, but always spell it out.

Group membership changes take effect on **next login**, not immediately
in your current shell. Log out and back in to pick them up. You can get a
shell with the updated groups without full logout via `newgrp <group>` but
it has rough edges; full logout is cleaner.

### ⚠️ `usermod -G` without `-a` is a catastrophic footgun

```
sudo usermod -G developers kaimikan       # DO NOT run this
```

Without `-a`, `-G` **replaces** your supplementary groups with exactly the
list given. That command would set your supplementary groups to just
`developers`, dropping you from `wheel` (no more sudo), `network`,
`video`, `audio`, everything. You'd be left with a working account but no
way to administer the system — recovery requires booting into rescue mode
or using another admin account.

**Always use `-aG`.** If you see a tutorial that says `usermod -G`, stop
and verify it's what's really meant; 99% of the time it's a copy-paste
error from someone who forgot `-a`.

---

## Your tool family

| Command                           | What it shows/does                                                      |
|-----------------------------------|-------------------------------------------------------------------------|
| `id`                              | UID, primary GID, all supplementary group memberships                    |
| `id <user>`                       | Same for another user                                                    |
| `groups`                          | Just the group names you belong to                                       |
| `whoami`                          | Current effective username (what files you create would be owned by)    |
| `getent passwd <user>`            | Full `/etc/passwd` entry for a user (via the NSS lookup chain)           |
| `getent group <group>`            | Full `/etc/group` entry for a group                                      |
| `stat <file>`                     | Detailed view: owner, group, perms (symbolic + octal), timestamps, inode |
| `ls -l <file>`                    | Terse perms, owner, group, size, mtime                                   |
| `sudo -l`                         | List what commands *you* can run via sudo, per `/etc/sudoers`            |
| `sudo -v`                         | Refresh your sudo timestamp (extend the 5–15min cache)                   |

---

## Exploration commands

### 1. `id` — who am I, to the kernel?

```
id
```

No flags needed. Output is one line:

```
uid=1000(kaimikan) gid=1000(kaimikan) groups=1000(kaimikan),3(sys),90(network),957(nopasswdlogin),979(rfkill),982(users),983(video),985(storage),989(lp),995(audio),998(wheel)
```

- `uid=1000(kaimikan)` — your user ID (integer) and its name (label).
- `gid=1000(kaimikan)` — your **primary** group ID and its name. This is
  the group files you create default to.
- `groups=...` — all groups you belong to, including the primary. This is
  the set the kernel checks when deciding "does the group bit apply?"

Compare against the table above. You'll recognize every entry.

### 2. `ls -l /etc/passwd /etc/shadow /etc/sudoers /etc/group`

```
ls -l /etc/passwd /etc/shadow /etc/sudoers /etc/group
```

- `ls -l` — long format, already covered in Lesson 1.

What to look for:

- `/etc/passwd` → `rw-r--r--` = `644`. World-readable (for name lookups);
  only root can modify.
- `/etc/shadow` → `rw-------` = `600`. Password hashes. Owner-only, period.
  Even `cat /etc/shadow` as yourself will fail with "Permission denied."
  **Try it** — seeing the deny is educational.
- `/etc/sudoers` → `r--r-----` = `440`. Readable only by root and group
  root. Not writable by *anyone* via direct edit — you must use `sudo
  visudo`, which syntax-checks before saving. Breaking `/etc/sudoers` with
  a syntax error can lock you out of sudo, so the safety is real.
- `/etc/group` → `rw-r--r--` = `644`. Same reasoning as `/etc/passwd`.

Notice a pattern: **the configuration that defines "who is who" lives in
plain text, world-readable, root-writable.** This is a Linux design choice
— transparent and auditable. Windows' SAM database (where account info
lives) is a binary file locked even from the Administrator during runtime.

### 3. `stat` on something you own vs something root owns

```
stat ~/.zshrc
stat /etc/passwd
```

- `stat <file>` — prints a detailed ownership/permission view plus
  timestamps and inode info.

Compare the two. Key fields:

- `Access: (0644/-rw-r--r--)` — the mode, in both octal and symbolic form,
  side by side. This is the single best way to burn octal ↔ symbolic
  conversion into your brain.
- `Uid: ( 1000/kaimikan)` vs `Uid: (    0/    root)` — yours vs root's.
- `Gid: ( 1000/kaimikan)` vs `Gid: (    0/    root)`.
- Three timestamps: `Access` (atime, last read), `Modify` (mtime, last
  content change), `Change` (ctime, last metadata change).

### Bonus: try to read `/etc/shadow` without sudo

```
cat /etc/shadow
```

Expected: `cat: /etc/shadow: Permission denied`.

You'll run into this exact error whenever you try to read a file the
owner-or-group denied you. The fix is not `chmod 777` — it's to use `sudo`
if the task genuinely needs root, or to examine what group owns the file
and whether you should be in that group.

---

## Cheat-sheet takeaways

- Every file has one owner UID, one group GID, nine `rwx` bits.
- **First match wins**: owner → group → other, not cumulative.
- For directories: `r` = list, `w` = add/delete entries, `x` = traverse into.
- Octal: `r=4 w=2 x=1`. `600`, `644`, `700`, `755` cover 95% of cases.
- `chmod` changes permissions, `chown` changes ownership. `-R` for recursive.
- **Never reach for `chmod -R 777`** — fix ownership or groups instead.
- **Always use `-aG`, never bare `-G`, with `usermod`** — you'll lock yourself out of sudo.
- Don't log in as root. `sudo` single commands. Membership in `wheel` is what grants sudo on Arch.
- Windows analogs: UAC ≈ sudo (per-process vs per-command), ACLs ≈ POSIX
  ACLs (both exist but aren't the default on Linux), `whoami` is literally
  the same command on both OSes.
