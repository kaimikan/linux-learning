# Lesson 5 — Shells: fish, zsh, bash, and the startup-file maze

## What a shell is

A **shell** is a program that reads commands from a user (or a script)
and runs them. That's it. It's userland — not part of the kernel —
which is why Linux has many of them, all interchangeable, all installable
side by side. The kernel's only contract with shells is: when a user
logs in, exec whatever's listed as their **login shell** in
`/etc/passwd` (last colon-separated field).

This is in stark contrast to Windows, where `cmd.exe` and `powershell.exe`
are distributed as part of the OS and intermingled with system services.
On Linux, your shell is *just an app you happen to run a lot.*

> **Scope:** every Unix-like system works this way: macOS, BSDs, all
> Linux distros. The specific shells available are universal across
> Linux (any distro can install bash, zsh, fish from its repos) but
> the **default** varies (Debian/Ubuntu → bash, macOS → zsh since
> Catalina, CachyOS → fish, vanilla Arch → bash).

## The shell lineage in two minutes

| Shell | Year | Contribution                                                    |
|-------|------|-----------------------------------------------------------------|
| `sh`  | 1977 | The original Bourne shell. Tiny, scriptable, the spec of POSIX  |
| `csh` | 1978 | C-shell — different syntax, popular in BSD; rarely used now     |
| `ksh` | 1983 | Korn shell — added arrays, math, history; influenced everything |
| `bash`| 1989 | "Bourne Again SHell" — sh-compatible, gobs of features          |
| `zsh` | 1990 | Z shell — bash-ish but with vastly better completion + theming  |
| `fish`| 2005 | "Friendly Interactive SHell" — **broke** POSIX for sane defaults|

Two camps:

- **`sh` / `bash` / `zsh` are POSIX-ish.** They share enough syntax that
  most scripts written for one work in the others (with caveats).
  Online tutorials, Stack Overflow answers, and `#!/bin/bash` scripts
  on GitHub assume this dialect.
- **`fish` is intentionally different.** Its authors decided POSIX was
  bad for interactive use and replaced it with a cleaner syntax,
  out-of-the-box autosuggestions, syntax highlighting, and sane
  defaults that bash users typically install plugins to get. The cost:
  bash one-liners often don't paste-and-run in fish.

CachyOS picked **fish** as your login shell and pre-configured it with
their `cachyos-fish-config` package. CachyOS *also* installs zsh with a
similar `cachyos-zsh-config` setup, in case you decide to switch.

## Three different things called "the shell"

When we say "your shell," we might mean any of three different
contexts. They can all be different shells *at the same time* and
that's normal.

| Context              | Set by                                  | On your box right now    |
|----------------------|-----------------------------------------|--------------------------|
| **Login shell**      | `/etc/passwd` last field                | `/bin/fish`              |
| **Interactive shell**| What your terminal emulator launches    | fish (Konsole)           |
| **Script shell**     | The script's `#!` shebang line          | bash (most scripts)      |

A real example you've already lived through:

- You log in (KDE → SDDM → graphical session) — login shell is **fish**.
- Konsole launches an interactive **fish**.
- Inside Konsole, you run `./serve.sh`. Its first line is
  `#!/usr/bin/env bash`, so the kernel exec's bash to run it. That
  script's body executes in **bash**, not fish — even though you
  typed `./serve.sh` from a fish prompt.

This is why "the shell" is a context-dependent question. When in doubt
about what's actually running:

- `getent passwd <user>` → login shell.
- `echo $0` → name of the *current* shell process (works in any shell).
- `ps -p $$ -o comm=` (or `ps -p $fish_pid -o comm=` in fish) →
  same, via the kernel.

## Where fish breaks bash compatibility — the translation table

This is the practical heart of the lesson. When a tutorial or Stack
Overflow answer says *"just run X"* and X is bash syntax, here's what
to do in fish.

### Variables

| What | bash/zsh                | fish                                       |
|------|-------------------------|--------------------------------------------|
| Set local var | `FOO=bar`        | `set FOO bar`                              |
| Set env var (exported) | `export FOO=bar` | `set -gx FOO bar`                  |
| Append to PATH | `export PATH="$PATH:/new/path"` | `fish_add_path /new/path`  |
| Read a var | `echo $FOO` or `echo "$FOO"` | `echo $FOO`                  |
| Universal var (persists across sessions) | (n/a, use a startup file) | `set -U FOO bar`  |

The `-g` is "global within the session," `-x` is "exported to subprocess
env." `-U` is "universal" — saved to `~/.config/fish/fish_variables` and
shared across all fish instances.

### Substitution and conditionals

| What | bash/zsh                  | fish                                  |
|------|---------------------------|---------------------------------------|
| Command substitution | `$(date)` or backticks | `(date)`                  |
| Test command | `[[ -f file ]]` or `[ -f file ]` | `test -f file`        |
| AND / OR | `cmd1 && cmd2`            | `cmd1 && cmd2` (works in fish 3+; older fish: `cmd1; and cmd2`) |
| Negation | `! cmd` or `if ! cmd; then` | `not cmd` or `! cmd`                |
| Last exit status | `$?`                | `$status`                             |
| Process ID | `$$`                      | `$fish_pid`                           |
| Last argument of previous cmd | `!$` (history, works in interactive bash/zsh) | (no direct equivalent; CachyOS's fish config defines `!$` via a function) |

That `$$` vs `$fish_pid` thing is exactly what bit you when running my
`echo "shell PID=$$"` diagnostic in fish. You haven't hit the others
yet but they'll come up.

### Loops and functions

| What | bash/zsh                                  | fish                                            |
|------|-------------------------------------------|--------------------------------------------------|
| `for` | `for i in a b c; do echo $i; done`        | `for i in a b c; echo $i; end`                  |
| `if`  | `if [[ -f x ]]; then ...; fi`             | `if test -f x; ...; end`                        |
| `function` | `myfunc() { ... }` or `function myfunc { ... }` | `function myfunc; ...; end`           |
| `while` | `while true; do ...; done`              | `while true; ...; end`                          |
| Block terminator | `done` / `fi` / `}`               | `end` (universal)                               |

Fish's universal `end` keyword is one of the things that makes its
syntax cleaner once you adapt — but it does mean a bash one-liner needs
real translation.

### Strings, arrays, redirection

| What | bash/zsh                                            | fish                                              |
|------|-----------------------------------------------------|----------------------------------------------------|
| Array | `arr=(a b c); echo ${arr[1]}`                       | `set arr a b c; echo $arr[1]` (fish indexes from 1) |
| Heredoc | `cat <<EOF\nstuff\nEOF`                          | (no heredocs — use `printf` or `string` builtins)  |
| Stderr to /dev/null | `cmd 2>/dev/null`                     | `cmd 2>/dev/null` (works since fish 3+)            |
| Pipe stdout+stderr | `cmd 2>&1 \| tee log` or `cmd \|& tee log` | `cmd &\| tee log`                              |
| Append redirect | `cmd >> file`                            | `cmd >> file` (same)                               |

### Aliases vs abbreviations (a fish-specific upgrade)

fish has both aliases AND **abbreviations**. They feel similar but work
differently:

```fish
alias ll 'ls -la'              # alias: hidden, lazy, expanded at runtime
abbr ll 'ls -la'               # abbreviation: visible, expanded as you type
```

When you type `ll<space>` with an abbr, fish replaces it with `ls -la` *in
the command line itself, before you press Enter*. You can edit the
expanded command, see what's actually running, and learn the underlying
command. It's a strict upgrade over aliases for interactive use.

### The mental shortcut

When you see bash syntax in a tutorial:

- **One-liners**: paste into bash via `bash -c 'the bash command'`. Fish
  hands you off cleanly:
  ```
  bash -c 'for i in {1..5}; do echo $i; done'
  ```
- **Longer scripts**: save to a file with `#!/usr/bin/env bash` shebang,
  `chmod +x`, run. The script runs in bash; you can call it from fish.
- **Configuration-style snippets** (e.g., "add this to your `.bashrc`"):
  translate to fish syntax and put in `~/.config/fish/config.fish` or
  `~/.config/fish/conf.d/<topic>.fish`.

You don't need to memorize the whole table — just remember "fish is not
bash" so you don't paste blindly. Look up the specific translation when
you need it.

## The startup-file maze

Each shell has its own set of files it reads during startup, in a
specific order, depending on whether it's a login shell, an interactive
shell, both, or neither. **This is one of the all-time confusion sources
in Unix.** Treating it carefully is what saves you from the kind of
"why isn't my env var set?" debugging we hit in Session 01.

### Fish (your daily driver)

Fish has the simplest startup model of the three. In order, on every
fish session:

1. **`/etc/fish/config.fish`** (system-wide, root-owned, often empty)
2. **`/usr/share/fish/vendor_conf.d/*.fish`** (system, packages drop files here)
3. **`/etc/fish/conf.d/*.fish`** (system admin's snippets)
4. **`~/.config/fish/conf.d/*.fish`** (user, alphabetical) ← **drop env-var files here**
5. **`~/.config/fish/config.fish`** (user, the main one)
6. **Functions** are auto-loaded on first call from `~/.config/fish/functions/*.fish` and the system search path.

Universal variables — set with `set -U` — are loaded from
`~/.config/fish/fish_variables` on session start, *before* config.fish
runs.

**The two practical rules for fish config:**

1. **Per-topic snippets in `~/.config/fish/conf.d/<topic>.fish`** —
   easier to manage than one giant `config.fish`. Each conf.d file owns
   one concern (e.g., `paths.fish`, `aliases.fish`, `prompt.fish`).
2. **`config.fish` for things that must run last or that depend on
   conf.d having executed** — usually nothing important, since most
   setup belongs in conf.d.

### Zsh (the alternate, also installed and configured on this box)

Zsh has **five** startup files in a specific order. The mental model:

| File         | Sourced for             | Purpose                                              |
|--------------|-------------------------|------------------------------------------------------|
| `.zshenv`    | **Every** invocation    | Env vars used by all shells (including scripts!)     |
| `.zprofile`  | Login shells only       | Pre-zshrc setup; rarely used on non-server systems   |
| `.zshrc`     | Interactive shells only | Aliases, prompt, key bindings, functions             |
| `.zlogin`    | Login shells only       | Post-zshrc setup; even more rarely used              |
| `.zlogout`   | Login shell exit        | Cleanup at logout                                    |

The system-wide versions (`/etc/zsh/zshenv`, etc.) are read first; the
per-user versions next.

The `.zshenv` confusion in Session 01 was a perfect demo: I created
`~/.zshenv` to set `SSH_AUTH_SOCK`, but your login shell is fish, not
zsh, so zsh's startup files weren't being sourced at all. **Set env vars
in the right shell's startup file** — or ideally, set them at a level
above the shell entirely (see below).

### Bash (also installed, used by `/bin/sh` and most shebangs)

Bash's startup logic is famously confusing because it depends on a
combination of:

- Whether the shell is a login shell.
- Whether the shell is interactive.
- Whether it was invoked as `sh` (POSIX mode) or `bash` (full features).

The simplified order:

- **Login + interactive**: `/etc/profile` → first existing of
  `~/.bash_profile`, `~/.bash_login`, `~/.profile`.
- **Non-login + interactive**: `/etc/bash.bashrc` → `~/.bashrc`.
- **Non-interactive (scripts)**: only `BASH_ENV` if set; usually nothing.

Because of this fragmentation, most people put a single line in
`~/.bash_profile` to source `~/.bashrc`, so both login and interactive
shells get the same environment. You'll see this everywhere.

### The above-shell escape hatch: `~/.config/environment.d/`

For env vars that should apply to **every program in your user session**
— not just one shell — there's a better place than any shell startup
file:

```
~/.config/environment.d/<topic>.conf
```

Format is plain `KEY=VALUE` lines. systemd's PAM hook loads these into
the user session at login, so every child process (every shell, every
GUI app, every Konsole tab) inherits them.

This is what we *would* have used for `SSH_AUTH_SOCK` in Session 01 if
we'd known to. The trade-off: changes require a re-login to take effect,
not just a new shell.

> **Scope:** `environment.d` works on any systemd-based Linux (so all
> modern desktop distros). Not portable to non-systemd systems but
> nothing else on a desktop matters.

## What CachyOS pre-configured for your fish

Your `~/.config/fish/config.fish` is two non-comment lines:

```fish
source /usr/share/cachyos-fish-config/cachyos-config.fish
```

That sourced file is the real config. Highlights of what it sets up:

- **Greeting via `fastfetch`** — the system-info banner you see when
  opening a new Konsole tab is from CachyOS overriding `fish_greeting`
  to call `fastfetch`. To disable: define your own empty `fish_greeting`
  function in `~/.config/fish/config.fish`:
  ```fish
  function fish_greeting; end
  ```
- **`MANPAGER`** set to pipe through `bat` for syntax-highlighted man pages.
- **`__done` plugin settings** — desktop notifications when long
  commands finish. Threshold is 10 seconds (`__done_min_cmd_duration`
  is 10000 ms).
- **PATH additions** — adds `~/.local/bin` if it exists. Plus
  `~/Applications/depot_tools` for Chromium devs (won't apply unless
  you have that directory).
- **`!!` and `!$` history shortcuts** — bash-style history expansion
  via custom fish functions. `!!` repeats the previous command, `!$`
  expands to the last argument.
- **`done.fish` from conf.d** sourced first — provides the underlying
  notification machinery.

The CachyOS approach is "configure sensibly out of the box, but in the
package's own files, so the user's `~/.config/fish/config.fish` stays
mostly empty and clean for their own customizations." If you ever want
to see what's been configured, `cat /usr/share/cachyos-fish-config/cachyos-config.fish`.

## Switching shells

If you ever want to change your login shell:

```
chsh -s /bin/zsh
```

- `chsh` — **ch**ange **sh**ell. Updates the last field of your
  `/etc/passwd` entry.
- `-s <shell>` — the new login shell.

Constraints:

- The shell must be listed in `/etc/shells` (a whitelist of "shells
  permitted as login shells"). On your box: bash, fish, zsh, plus
  rbash (restricted bash) and a couple of niche entries.
- Change takes effect at **next login** (not in any current terminal).
  Log out and back in (or reboot) to pick it up.
- You can preview a shell *without* changing your login shell — just
  type its name in your current terminal:
  ```
  zsh             # drops you into a zsh subshell, type `exit` to leave
  bash            # same for bash
  ```
  This is the right way to "try before you commit."

For most users on CachyOS, the right answer is: **stay on fish for
interactive use, write scripts with `#!/usr/bin/env bash` (or `sh`)
shebangs, and don't switch.** Fish is great; the bash compatibility
gap matters only at script time, and the shebang takes care of that.

## Exploration commands

### 1. Confirm what each "shell" context is

```
echo "login shell:        "; getent passwd $USER | awk -F: '{print $7}'
echo "current shell name: "; ps -p $fish_pid -o comm=
echo "what /bin/sh is:    "; readlink -f /bin/sh
echo "what runs scripts:  "; cat /etc/shells | grep -v '^#'
```

(Run that block as one paste.) Tells you all four shell-context answers
in one go.

### 2. Inspect what fish actually has loaded

```
functions               # list every function fish knows
functions fish_greeting # show the source of one specific function
abbr                    # list every abbreviation
alias                   # list every alias
set                     # list every variable (a lot — pipe to grep)
set | grep PATH         # just the PATH-related variables
```

### 3. Compare prompts in zsh and fish without committing

In Konsole:

```
zsh
```

You'll drop into zsh. Notice the prompt, the slightly different feel.
Run a few commands. Type `exit` to return to fish. (CachyOS's
`cachyos-zsh-config` makes zsh feel almost like fish — autosuggestions
and syntax highlighting are configured on both.)

### 4. See what would happen if you switched login shells

```
chsh -l 2>/dev/null || cat /etc/shells
```

`chsh -l` (some versions) lists allowed shells; otherwise just `cat
/etc/shells`. Shows what `chsh -s` would accept.

### 5. Read CachyOS's fish config

```
cat /usr/share/cachyos-fish-config/cachyos-config.fish | less
```

(Press `q` to exit `less`.) Worth a slow read — every line is a small
lesson in fish syntax.

---

## Cheat-sheet takeaways

- A shell is just a userland program. You have many; they coexist.
- Login shell vs interactive vs script-shell are three different
  questions and can all have different answers.
- Fish is your daily driver. POSIX-ish (bash/zsh) is what most
  tutorials assume — translate, don't paste blindly.
- For env vars that need to apply system-wide to your session, use
  `~/.config/environment.d/<topic>.conf`. For shell-specific things
  that only matter inside a shell, use that shell's startup file.
- `chsh -s` changes your login shell. `/etc/shells` is the whitelist.
  Try before you commit by just typing the shell's name in a current
  terminal.
- CachyOS preconfigured fish (and zsh, in case you switch) with sane
  defaults at `/usr/share/cachyos-{fish,zsh}-config/`. Your own
  `~/.config/fish/config.fish` is intentionally minimal so you have
  room to customize.
