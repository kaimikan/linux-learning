# Broken KDE Discover launcher in default CachyOS taskbar

## Symptom

A taskbar entry showing a generic "blank document" icon labeled
`org.kde.discover.desktop`. KDE notification toast appearing at random:

> System Notifications
> Unknown application folder

with a red error icon.

## Diagnosis

KDE Discover is **not installed** on this system:

```
$ pacman -Q discover
error: package 'discover' was not found
$ which plasma-discover
plasma-discover not found
$ ls /usr/share/applications/org.kde.discover.desktop
ls: cannot access ...: No such file or directory
```

CachyOS's default Plasma panel layout includes a Discover launcher by
default, but CachyOS deliberately does not install the Discover package —
their philosophy is that Arch users should learn `pacman` / `paru` from
the terminal, and Discover is more friction than help on a rolling-release
Arch system.

Result: the panel has a launcher pinned to a `.desktop` file that doesn't
exist on disk, so KDE renders the missing app with the generic icon, and
its notification daemon emits "Unknown application folder" whenever
something tries to interact with it.

## Fix

Right-click the broken icon in the taskbar → **Unpin** (or "Remove from
Task Manager", depending on the Plasma version). One click, done. The
notification stops because nothing references the missing `.desktop` file
anymore.

## Should I install Discover?

Generally no, on CachyOS. Reasons:

- `pacman` and `paru` (CachyOS pre-installs `paru`) cover everything
  Discover does and more, in a way that lets you actually understand
  what's happening.
- Discover's update notifications can be misleading on Arch because of
  its "partial-upgrade" anti-pattern (see Session 03 notes on
  `pacman -Sy` vs `pacman -Syu`).
- If you ever want a GUI app launcher for Flatpaks specifically:
  `sudo pacman -S discover packagekit-qt6 flatpak` would set it up. Skip
  it until you have an actual reason.

## What was learned

- Linux apps are made of multiple separate parts: the binary in
  `/usr/bin/`, the launcher metadata in `/usr/share/applications/*.desktop`,
  the icon in `/usr/share/icons/.../*.png`, and any backend services. A
  taskbar launcher only needs the `.desktop` file to *appear*; it doesn't
  verify the binary exists. So you can have a launcher for a missing app.
- `pacman -Q <name>` is the canonical "is this package installed?" query.
  `which <command>` is the canonical "is this command in my PATH?" query.
  Combining them quickly proves an app is genuinely absent rather than
  just misconfigured.
