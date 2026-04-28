# Lesson roadmap

A working list of candidate future sessions. Not a fixed sequence — at the
end of each session, Kai picks the next one from this list (or proposes
something not on it). Items move out of the roadmap as they ship.

Status legend:
- **Declared next** — the next session has been chosen.
- **Candidate** — on the table, can be picked at any time.
- **Triggered** — wait for a specific event before doing this one (e.g.,
  user friction, kernel update, hardware change).

---

## Tier 1 — Foundational, natural next picks

### Text editor (vim, neovim, nano, or micro)
*Status: candidate · Maps to: `05-dev-tools/`*

Pick a primary terminal editor and learn it well enough to be productive
for `sudoedit /etc/sudoers`, dotfile editing, ad-hoc fixes, and remote
servers. Decision tree: **nano** (gentlest, no modal model, ships
everywhere — fine forever for a "fix one line in a config" workflow);
**micro** (modern nano, mouse support, sane defaults, requires install);
**neovim/vim** (modal model, steep learning curve, eventual high payoff
for power users). Lesson would compare them honestly, install the chosen
one, walk through the foundational keystrokes (open / save / search /
quit), and write a `~/.config/<editor>/` starter config.

### Processes and systemd
*Status: candidate · Maps to: new dir `06-processes-and-systemd/`*

The kernel's process model and systemd's role as PID 1 — the most
foundational topic we haven't covered. Lesson: PIDs, parent/child,
zombies and reaping; `ps` / `top` / `htop` / `btop`; signals (SIGTERM
vs SIGKILL etc); foreground/background and `jobs`/`fg`/`bg`; what
systemd is and the units (service, timer, mount, path, target);
`systemctl` (start/stop/enable/disable/status) and `journalctl` for
logs; system vs user scope (`--user`); a tour of what's actually running
on this CachyOS box. Touched lightly during the failed ssh-agent setup;
deserves real treatment.

### Networking basics
*Status: candidate · Maps to: new dir `07-networking/`*

The 80% of "why can't I reach this thing" troubleshooting toolkit.
Lesson: NetworkManager + `nmcli` (managing wifi/ethernet from the
terminal); `/etc/hosts` and `/etc/resolv.conf`; the `ip` command (modern
replacement for `ifconfig` and `route`); `ss` for ports and sockets;
DNS resolution (systemd-resolved on CachyOS); pinging, tracerouting;
what a "port" actually is. Windows contrast where helpful. Skips the
deep TCP/IP theory; aims for "what to type when X is broken."

### File manipulation, beyond the basics
*Status: candidate · Maps to: `01-basics/` (extends Session 02)*

Builds on the permissions lesson with the file-handling commands you'll
type a hundred times a week: `cp` / `mv` / `rm` with safety habits
(`-i`, `-v`, dry runs), `find` with practical patterns (not just
`find . -name`), `grep` and the modern `rg`/ripgrep alternative,
`sed`/`awk` basics for "I need to bulk-edit a file" cases, archives
(`tar`, `zip`, `unzip`, `7z`), and the underrated `xargs`. Includes
warnings about `rm -rf` / `rm -rf $VAR/` shell-expansion footguns.

### Shell scripting basics
*Status: candidate · Maps to: `03-shell/` (extends Session 05)*

Now that we know fish ≠ bash, write actual scripts in the right
language. Lesson: the shebang line; `set -euo pipefail` and why it
matters; positional args and `"$@"`; functions; conditionals and loops
(POSIX sh / bash, contrasted with fish); when to write in fish vs bash;
shellcheck. Build something small but real — maybe a `serve.sh`-style
helper for another small task in this repo.

---

## Tier 2 — Medium-term, "good to cover when ready"

### KDE Plasma deep cuts
*Status: candidate · Maps to: `04-kde/`*

Power-user features of the desktop you're already using. Lesson:
Wayland vs X11 (and why CachyOS defaulted you to Wayland); KWin
keyboard shortcuts and how to customize them; KRunner (Alt+Space)
power features beyond app launch; panel/widget customization; the KDE
config hierarchy under `~/.config/` (`kdeglobals`, `kwinrc`, `plasma-*`,
etc.); Activities; KWallet basics; theming (Plasma styles vs GTK
themes, when GTK apps look out of place).

### Git, beyond the basics
*Status: candidate · Maps to: `05-dev-tools/`*

You already use git for this repo. This session covers real-world
workflows you'll need on bigger projects: branching strategies; rebase
vs merge (with the safety habits); resolving conflicts; force-push
hygiene; the reflog as a safety net; `git stash`; tags vs branches;
remote management; SSH config for multiple identities. Builds on the
Session 01 git+SSH work.

### Language toolchains on Arch
*Status: candidate · Maps to: `05-dev-tools/`*

How to install and manage Python, Node, Rust, Go (etc.) on Arch
without making a mess. Lesson: the Arch philosophy (pacman provides
recent versions; for project-specific versions, use a version manager);
Python's `pipx` + `venv` (revisited from Session 04); Node's `nvm` vs
the system `nodejs` package; Rust's `rustup`; Go modules; how
`asdf` / `mise` unify the per-project version pinning story. Avoids the
Windows-style "install one global version of each from the website"
trap.

### Deploy the MkDocs site to GitHub Pages
*Status: candidate · Triggered: when Kai wants the site public · Maps to: `02-package-management/` or new `08-ci/`*

Doubles as a "GitHub Actions, conceptually" lesson. Lesson: what a CI
runner is; YAML workflow files; the `gh-pages` branch convention vs
the newer "Pages from Actions" deploy; the workflow we'd add at
`.github/workflows/deploy-docs.yml`; secrets, permissions, and
branch-protection basics.

---

## Tier 3 — Hardware/security/niche, "when you actually hit this"

### Bluetooth peripherals
*Status: triggered · Trigger: when Kai wants to use the Logitech Pebble 2 Combo without USB · Maps to: new dir or `04-kde/`*

Pair the Logitech Pebble 2 Combo via Bluetooth. Lesson: `bluez` /
`bluetoothctl`; KDE's Bluetooth applet; pairing trust modes
(persistent vs one-shot); persistence across reboots and across
suspend/resume; troubleshooting common Linux Bluetooth issues. Often
finicky; documented as a discrete lesson because it earns one.

### NVIDIA + KDE on hybrid graphics
*Status: triggered · Trigger: graphics weirdness, gaming workload, or external display issues · Maps to: new dir*

The RTX 5070 + Intel iGPU situation. Lesson: driver choice (`nvidia-open`
vs proprietary `nvidia` vs `nvidia-dkms`); Wayland vs X11 session
trade-offs (NVIDIA's Wayland support is recent and patchy); PRIME
offloading (running specific apps on the dGPU only); environment
variables (`__NV_PRIME_RENDER_OFFLOAD`, etc.); thermal/power management
implications. Skipped until needed because it's a rabbit hole.

### ssh-agent and credential helpers, properly
*Status: triggered · Trigger: when typing the SSH passphrase per push starts to annoy · Maps to: `00-setup/` or `05-dev-tools/`*

The deep dive we deferred in Session 01. Lesson: `ssh-agent` lifecycle;
the `systemd --user` service approach (this time done right, in fish);
KDE's `ksshaskpass` integration with KWallet for graphical prompts and
auto-unlock at login; gpg-agent's SSH support as an alternative; the
`keychain` helper. Drive from the Arch Wiki SSH keys page; everything
runs in Konsole, no Claude `!` shortcuts.

### `lenovo-legion-laptop` AUR module — battery threshold revisit
*Status: triggered · Trigger: kernel adds Legion EC support, OR Kai decides battery wear matters more than out-of-tree-module risk · Maps to: existing `troubleshooting/battery-charge-threshold-loq15irx10.md` follow-up*

Install the AUR module to get a working charge threshold on the LOQ
15IRX10. Lesson: real exercise of the AUR (read the PKGBUILD), DKMS
mechanics, what happens when the module fails after a kernel update,
how to disable/uninstall safely.

### Firewall basics
*Status: candidate · Triggered if Kai ever exposes a service · Maps to: new dir*

`nftables` (the modern Linux firewall) vs `iptables` (legacy); `ufw`
as the friendly frontend; what's running on this box that listens
externally (probably nothing right now); when this matters (laptop on
public wifi, running a local dev server you don't want exposed) and
when it doesn't (everything bound to localhost is unreachable from
outside regardless).

### Audio on Linux (PipeWire era)
*Status: candidate · Maps to: `04-kde/` or new dir*

CachyOS uses PipeWire (the modern Linux audio server). Lesson:
PipeWire vs PulseAudio vs ALSA vs JACK (the historical context); KDE's
audio applet; routing apps to specific outputs (HDMI vs speakers vs
Bluetooth headphones); per-app volume; troubleshooting; when this
matters (e.g., latency-sensitive workloads).

---

## Process notes

- At the top of each session: Kai picks the next topic from this list.
- At the end of each session: any new topics surfaced go into this file
  (Tier 3 by default, promoted up if they're foundational).
- Items shipped get **moved to the daily-log** under the relevant
  session entry, not deleted from history — but removed from this
  roadmap so it stays the *forward-looking* list.
- Triggered items don't need an explicit decision; they get picked up
  when the trigger fires.
