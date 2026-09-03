# 2026-09-03: MacBook heat and "micro-freezes" investigation

Session log, written by Claude Code. Machines: new MacBook Pro (M1 Pro, 32 GB, macOS 26.6.2)
and the old M1 (2020), both driving an LG ULTRAWIDE 3440x1440 @ 85 Hz through a CalDigit TS4
(Apple TB4 cable) and a DisplayPort-to-HDMI adapter. The LG's DisplayPort input is taken by a
gaming PC at 160 Hz, so the Mac stays on HDMI.

## Symptom

Both Macs feel warm during normal work. On the new Mac the mouse cursor sticks for a fraction
of a second, only on the external LG, never on the built-in display. Mostly noticed while the
Claude desktop app is in front.

## Result

**Not a fault.** WindowServer (the macOS compositor) uses 40-60 % of one core all day on this
display pair, and the old Mac measures the same (32-47 %) with the same monitor. That is the
macOS 26 baseline for an XDR ProMotion panel plus a 3440x1440 external display. The cursor
hitches are dropped frames: whenever something pushes WindowServer past a full core, the fixed
85 Hz LG shows a skipped frame, while the adaptive ProMotion panel hides it. Heat is the same
half-busy core plus whatever spikes on top of it.

## What was measured and excluded (30 s WindowServer samples unless noted)

| Candidate | Result |
|---|---|
| Visible apps (Telegram, Chrome, Claude, all hidden) | no change; hiding everything went *up* |
| Grammarly, JetBrains Toolbox, BambuStudio quit | no change |
| Reduce transparency | no change (46-50 %) |
| LG at 50 Hz instead of 85 | ~15 % relative drop only |
| Aerial wallpaper, desktop widgets | idle at 0 % CPU while a still frame is shown |
| HDR flag | was a GPU capability entry, not a display setting |
| Screen capture / recording, link retrains, DisplayLink | none present |
| Display role TV -> "Computer monitor" (BetterDisplay) | no change |
| RGB-only EDID override (patched file, BetterDisplay) | no change |
| True Tone + auto-brightness off | no change (46 %) |
| BetterDisplay itself | +4 points, and 20-45 % CPU of its own |
| Per display (BetterDisplay disconnect) | built-in alone ~33 %, LG alone ~23 %, both ~28-50 % |
| Old Mac, same monitor | 32-47 % -> same baseline |

Untested: "Displays have separate Spaces" off (needs logout).

## Spike sources found on the way (these are the real levers)

- Telegram: 1.1 GB / 1650 files of media cache written in one hour on the fresh install; macOS
  filed a disk-writes report. Fix: Settings -> Data and Storage -> automatic media download off
  for groups/channels, cache limit set.
- One Chrome renderer tab at up to 155 % CPU (Window -> Task Manager to identify).
- BambuStudio idling at 1.6 GB / 12-16 % CPU for 13 h.
- Grammarly Desktop (`app_inkwell`) running permanently at 4-8 %.
- The Claude desktop app rendering a 7 MB session (renderer 800 MB, 5-25 %).

## Tooling added

- `macmon` (Brewfile.macos) and a `temp` alias: one-line chip temperature / watts / core usage.
- BetterDisplay was installed for the tests and should be reset and removed
  (`brew uninstall --cask betterdisplay`).

## Lessons for next time

- Measure WindowServer over 30 s; single samples swing 15-70 %.
- `duti`/default apps on macOS 26 need a per-file-type Finder consent dialog; a stack of them
  freezes the Mac for a while (that was one "freeze").
- Timing scripts: never call the pyenv `python3` shim in a tight loop (100-200 ms each); use
  zsh `$EPOCHREALTIME` with `zmodload zsh/datetime zsh/mathfunc`.
- macOS awk has no `asort`; use `sort -n` for medians.
