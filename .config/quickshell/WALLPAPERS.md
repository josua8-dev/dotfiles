# Wallpapers — where they live, how they're chosen, how they're applied

## Where they live

| Source | Location | Count |
| --- | --- | --- |
| Still images (the default set) | `~/.local/share/wallpapers/` | 40 `.jpg/.png/…` |
| Videos | `~/.local/share/wallpapers/animated/` | dropped in by hand |
| Steam Wallpaper Engine | `~/.steam/root/steamapps/workshop/content/431960/<id>/` | 30 projects, each with `project.json` + `preview.*` |
| Anything else the user picked | any absolute path, remembered in state | — |

Nothing is copied: the picker shows files where they are. `~/.local/share/wallpapers/`
is a curated `XDG_DATA_HOME` folder, not a cache, and `~/wallpapers/` and `~/Pictures/`
are *not* scanned — the list is exactly that one folder plus the workshop.

## How one is selected

`services/WallpaperService.qml` runs `scripts/theme_manager.py list-wallpapers`
once at startup. That returns a single flat array: **40 stills + 30 Wallpaper Engine
projects = 70 tiles**. Wallpaper Engine entries carry an extra `engine` field holding
the project folder, and their `path` is the project's `preview.jpg`, so they are
ordinary picture entries everywhere that draws a picture (picker tile, overview,
lock screen, profile resolution, palette extraction).

The picker (`bar/island/AppearancePanel.qml`) marks the applied tile by comparing
`entry.path === WallpaperService.chosen`, where `chosen` is `currentMotion ||
currentWallpaper`. Picking a tile runs `theme_manager.py set-wallpaper <path>`.

The choice is persisted in `~/.local/state/quickshell/state.json`
(`currentWallpaper`, `currentMotion`, `enginePid`) and restored at login by
`theme_manager.py restore`, which WallpaperService runs on startup.

## How it is applied

```
set-wallpaper <path>
 ├─ is it a video?      → poster frame + mpvpaper  (currentMotion)
 ├─ does its folder have project.json?
 │    yes → stop_engine() then start_engine(folder)     ← Wallpaper Engine
 │    no  → stop_engine()                               ← take it back down
 └─ awww img <still>  → sets the picture, runs the wipe/slide/fade
                        transition, extracts the palette, pushes it to
                        kitty/btop/cava/yazi/nvim/GTK/Qt/KDE/Papirus/
                        Vesktop/Spotify/VSCodium/Zen, links the file
```

Both layers are kept deliberately: **awww** owns the still (it is what the palette
is read from and what shows if anything else dies) and, when a workshop project is
active, **linux-wallpaperengine** is drawn on `--layer background` *on top of* it,
with the same `--screen-root` for every monitor. Widgets, bar and windows sit at
level 1+, so they stay above the live wallpaper.

`start_engine()` launches
`~/.local/bin/linux-wallpaperengine --layer background --fps 30 --silent
--screen-root HDMI-A-1 --screen-root DP-1 <project dir>` with `start_new_session=True`,
records its pid in `state.enginePid`, and `stop_engine()` signals the whole process
group (SIGTERM, then SIGKILL). The pid is used rather than a process name because
the launcher is a Python wrapper that spawns the real renderer as a child — killing
the launcher alone leaves the wallpaper up — and because `linux-wallpaperengine`
exceeds the 15-character `pgrep -x` limit.

`restore()` restarts a renderer that is not running at login, the same way mpvpaper
is restarted for a video.

## Tinting

`TERMINAL_TINT` (0.22) in `theme_manager.py` mixes the wallpaper's accent into
kitty's `background`. `decoration:blur:vibrancy` (0.04) and `brightness` (1.2) in
`hypr/modules/look.lua` decide how much of the wallpaper's own colour survives the
frost — `ignore_opacity` is what lets the blur show through a translucent kitty at
`background_opacity 0.78`.
