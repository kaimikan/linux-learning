# Battery charge threshold doesn't work on LOQ 15IRX10 (mainline kernel)

## Symptom

In KDE System Settings → Power Management → Advanced Power Settings, the
**"Limit the maximum battery charge"** checkbox can be toggled on, but:

- No threshold percentage slider appears.
- The battery still charges to 100%.
- UPower reports `ChargeThresholdSupported: true` but
  `ChargeThresholdEnabled: false` and both thresholds at `0` even after
  toggling.

## Diagnosis

The standard kernel sysfs interface for charge thresholds is missing for
this battery:

```
$ ls /sys/class/power_supply/BAT1/ | grep charge_control
(no output — the files don't exist)
```

Loaded Lenovo modules on this box:
- `ideapad_laptop` — base IdeaPad/LOQ ACPI driver. Does NOT expose
  `charge_control_*` for this model's battery EC protocol.
- `lenovo_wmi_other`, `lenovo_wmi_gamezone`, `lenovo_wmi_capdata` — newer
  Legion-family WMI drivers. They expose CPU/GPU power tuning at
  `/sys/class/firmware-attributes/lenovo-wmi-other-0/attributes/`
  (`cpu_temp`, `ppt_pl1_spl`, `gpu_nv_ctgp`, etc.) but **not** battery
  thresholds.

So: UPower's "supported" flag reflects what the platform *advertises*, but
no driver in mainline currently writes to whatever EC interface this
specific laptop uses for charge thresholds. KDE's UI lights up because
UPower says supported, but the toggle is effectively a no-op.

The LOQ BIOS/UEFI on this firmware revision also does **not** expose a
"Conservation Mode" or "Battery Charge Threshold" option in setup, so
the firmware-level workaround other Lenovo laptops have is unavailable.

## Status

**Not fixed.** Living with charge-to-100% for now (option C in the
session-02 conversation).

The community kernel module `lenovo-legion-laptop`
(https://github.com/johnfanv2/LenovoLegionLinux, available via AUR) adds
working charge thresholds for Legion-family laptops including some LOQ
variants. Deferred because:

1. Out-of-tree kernel modules on a rolling-release distro need rebuilding
   on every kernel update. DKMS automates this but introduces a non-zero
   risk window where a kernel update lands before the module catches up.
2. The risk of a bad interaction is higher with battery/fan/EC code than
   with userspace tools — in the worst case it could affect thermal
   management.
3. Kai's daily use is mostly stationary at home; some battery aging is
   acceptable in exchange for not running an out-of-tree module.

## What was learned

- `ChargeThresholdSupported: true` from UPower is a *platform capability
  claim*, not a working backend. The real test is whether
  `/sys/class/power_supply/BAT*/charge_control_*` files actually exist
  AND can be written to AND make charging stop at the written value.
- Lenovo battery support in mainline Linux is split across multiple
  drivers (`ideapad_laptop`, `thinkpad_acpi`, `lenovo_wmi_*`) and
  coverage varies by model. ThinkPads have the best support; Legion/LOQ
  is improving but not fully there yet.
- The mainline kernel's path to supporting LOQ-class battery thresholds
  goes through merging the `lenovo-legion-laptop` work upstream. Worth
  re-checking every few major kernel releases.

## To revisit when

- A new `linux-cachyos` kernel release notes mentions Legion/LOQ battery
  EC support, OR
- Kai decides the battery wear matters more than the out-of-tree-module
  risk and wants to install `lenovo-legion-laptop` from the AUR. If that
  happens, treat it as a real exercise — read the project's README,
  understand DKMS, know how to disable/uninstall the module if it
  misbehaves.
