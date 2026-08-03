---
name: omyvoid
description: >
  REQUIRED for end-user customization of Linux desktop, window manager, or system config.
  Use when editing ~/.config/hypr/, ~/.config/waybar/, ~/.config/walker/,
  ~/.config/alacritty/, ~/.config/foot/, ~/.config/kitty/, ~/.config/ghostty/, ~/.config/mako/,
  or ~/.config/omyvoid/. Triggers: Hyprland, window rules, animations, keybindings,
  monitors, gaps, borders, blur, opacity, waybar, walker, terminal config, themes,
  background, night light, idle, lock screen, screenshots, reminders, layer rules,
  workspace settings, display config, and user-facing omyvoid commands. Excludes Omyvoid
  source development in ~/.local/share/omyvoid/ and `omyvoid dev` workflows.
---

# Omyvoid Skill

Manage Omyvoid Linux systems: a modern, opinionated Void Linux x86_64-glibc desktop with Hyprland.

This skill is for end-user customization on installed systems.
It is not for contributing to Omyvoid source code.

## When This Skill MUST Be Used

**ALWAYS invoke this skill for end-user requests involving ANY of these:**

- Editing ANY file in `~/.config/hypr/` (window rules, animations, keybindings, monitors, etc.)
- Editing ANY file in `~/.config/waybar/`, `~/.config/walker/`, `~/.config/mako/`
- Editing terminal configs (alacritty, foot, kitty, ghostty)
- Editing ANY file in `~/.config/omyvoid/`
- Window behavior, animations, opacity, blur, gaps, borders
- Layer rules, workspace settings, display/monitor configuration
- Themes, backgrounds, fonts, appearance changes
- User-facing `omyvoid` commands (`omyvoid theme ...`, `omyvoid refresh ...`, `omyvoid restart ...`, etc.)
- Screenshots, screen recording, reminders, night light, idle behavior, lock screen

**If you're about to edit a config file in ~/.config/ on this system, STOP and use this skill first.**

**Do NOT use this skill for Omyvoid development tasks** (editing files in `~/.local/share/omyvoid/`, creating migrations, or running `omyvoid dev ...` workflows).

## Critical Safety Rules

**For end-user customization tasks, NEVER modify anything in `~/.local/share/omyvoid/`** - but READING is safe and encouraged.

This directory contains Omyvoid's source files managed by git. Any changes will be:
- Lost on next `omyvoid update`
- Cause conflicts with upstream
- Break the system's update mechanism

```
~/.local/share/omyvoid/     # READ-ONLY - NEVER EDIT (reading is OK)
├── bin/                    # Source scripts (symlinked to PATH)
├── config/                 # Default config templates
├── themes/                 # Stock themes
├── default/                # System defaults
├── migrations/             # Update migrations
└── install/                # Installation scripts
```

**Reading `~/.local/share/omyvoid/` is SAFE and useful** - do it freely to:
- Understand how omyvoid commands work: `omyvoid theme set --help` or `cat $(which omyvoid-theme-set)`
- See default configs before customizing: `cat ~/.local/share/omyvoid/config/waybar/config.jsonc`
- Check stock theme files to copy for customization
- Reference default hyprland settings: `cat ~/.local/share/omyvoid/default/hypr/*`

**Always use these safe locations instead:**
- `~/.config/` - User configuration (safe to edit)
- `~/.config/omyvoid/themes/<custom-name>/` - Custom themes (must be real directories)
- `~/.config/omyvoid/hooks/` - Custom automation hooks

If the request is to develop Omyvoid itself, this skill is out of scope. Follow repository development instructions instead of this skill.

## System Architecture

Omyvoid is built on:

| Component | Purpose | Config Location |
|-----------|---------|-----------------|
| **Void Linux** | Base OS (XBPS and runit) | `/etc/`, `~/.config/` |
| **Hyprland** | Wayland compositor/WM | `~/.config/hypr/` |
| **Waybar** | Status bar | `~/.config/waybar/` |
| **Walker** | App launcher | `~/.config/walker/` |
| **Alacritty/Foot/Kitty/Ghostty** | Terminals | `~/.config/<terminal>/` |
| **Mako** | Notifications | `~/.config/mako/` |
| **SwayOSD** | On-screen display | `~/.config/swayosd/` |

## Command Discovery

Omyvoid ships a single `omyvoid` CLI that dispatches to all `omyvoid-*` binaries via `omyvoid <group> <action>`. Always prefer this form — it is self-documenting and stable. The underlying `omyvoid-*` binaries still exist on `PATH` and remain safe to read for source.

```bash
# List every documented command and its summary
omyvoid commands

# Show the commands inside a group
omyvoid theme --help
omyvoid refresh --help
omyvoid restart --help

# Show help for a specific command (does not execute it)
omyvoid theme set --help

# Machine-readable listing (binary, route, summary, args, aliases)
omyvoid commands --json

# Read a command's source to understand it
cat $(which omyvoid-theme-set)
```

### Command Groups

Run `omyvoid --help` for the full list. The most common groups:

| Group | Purpose | Example |
|-------|---------|---------|
| `omyvoid refresh` | Reset config to defaults (backs up first) | `omyvoid refresh waybar` |
| `omyvoid restart` | Restart a service/app | `omyvoid restart waybar` |
| `omyvoid toggle` | Toggle feature on/off | `omyvoid toggle nightlight` |
| `omyvoid theme` | Theme management | `omyvoid theme set <name>` |
  | `omyvoid install` | Start the Omyvoid system installer | `omyvoid install` |
  | `omyvoid install <command>` | Install optional software / packages | `omyvoid install browser chromium` |
| `omyvoid launch` | Launch apps | `omyvoid launch browser` |
| `omyvoid capture` | Screenshots and recordings | `omyvoid capture screenshot` |
| `omyvoid reminder` | Desktop notification reminders | `omyvoid reminder 15 "Pickup Jack"` |
| `omyvoid pkg` | Package management | `omyvoid pkg install <pkg>` |
| `omyvoid setup` | Initial setup tasks | `omyvoid setup fingerprint` |
| `omyvoid update` | System updates | `omyvoid update` |

## Configuration Locations

### Hyprland (Window Manager)

```
~/.config/hypr/
├── hyprland.conf      # Main config (sources others)
├── bindings.conf      # Keybindings
├── monitors.conf      # Display configuration
├── input.conf         # Keyboard/mouse settings
├── looknfeel.conf     # Appearance (gaps, borders, animations)
├── envs.conf          # Environment variables
├── autostart.conf     # Startup applications
├── hypridle.conf      # Idle behavior (screen off, lock, suspend)
├── hyprlock.conf      # Lock screen appearance
└── hyprsunset.conf    # Night light / blue light filter
```

**Key behaviors:**
- Hyprland auto-reloads on config save (no restart needed for most changes)
- Use `hyprctl reload` to force reload
- After ANY Hyprland config change, validate with `hyprctl reload` followed by `hyprctl configerrors`
- If `hyprctl configerrors` reports errors, address them and rerun validation until clean or until a real blocker is identified
- Use `omyvoid refresh hyprland` to reset to defaults

### Waybar (Status Bar)

```
~/.config/waybar/
├── config.jsonc       # Bar layout and modules (JSONC format)
└── style.css          # Styling
```

**Waybar does NOT auto-reload.** You MUST run `omyvoid restart waybar` after any config changes.

**Commands:** `omyvoid restart waybar`, `omyvoid refresh waybar`, `omyvoid toggle waybar`

### Terminals

```
~/.config/alacritty/alacritty.toml
~/.config/foot/foot.ini
~/.config/kitty/kitty.conf
~/.config/ghostty/config
```

**Command:** `omyvoid restart terminal`

### Other Configs

| App | Location |
|-----|----------|
| btop | `~/.config/btop/btop.conf` |
| fastfetch | `~/.config/fastfetch/config.jsonc` |
| lazygit | `~/.config/lazygit/config.yml` |
| starship | `~/.config/starship.toml` |
| git | `~/.config/git/config` |
| walker | `~/.config/walker/config.toml` |

## Safe Customization Patterns

### Pattern 1: Edit User Config Directly

For simple changes, edit files in `~/.config/`:

```bash
# 1. Read current config
cat ~/.config/hypr/bindings.conf

# 2. Backup before changes
cp ~/.config/hypr/bindings.conf ~/.config/hypr/bindings.conf.bak.$(date +%s)

# 3. Make changes with Edit tool

# 4. Apply changes
# - Hyprland: auto-reloads on save, but MUST validate with `hyprctl reload` and `hyprctl configerrors`
# - Waybar: MUST restart with `omyvoid restart waybar`
# - Walker: MUST restart with `omyvoid restart walker`
# - Terminals: MUST restart with `omyvoid restart terminal`
```

### Pattern 2: Make a new theme

1. Create a directory under ~/.config/omyvoid/themes.
2. See how an existing theme is done via ~/.local/share/omyvoid/themes/catppuccin.
3. Download a matching background (or several) from the internet and put them in ~/.config/omyvoid/themes/[name-of-new-theme]
4. When done with the theme, run `omyvoid theme set "Name of new theme"`

### Pattern 3: Use Hooks for Automation

Create scripts in `~/.config/omyvoid/hooks/` to run automatically on events:

```bash
# Available hooks (see samples in ~/.config/omyvoid/hooks/):
~/.config/omyvoid/hooks/
├── theme-set        # Runs after theme change (receives theme name as $1)
├── font-set         # Runs after font change
└── post-update      # Runs after `omyvoid update`
```

Example hook (`~/.config/omyvoid/hooks/theme-set`):
```bash
#!/bin/bash
THEME_NAME=$1
echo "Theme changed to: $THEME_NAME"
# Add custom actions here
```

### Pattern 4: Reset to Defaults -- ALWAYS SEEK USER CONFIRMATION BEFORE RUNNING

When customizations go wrong:

```bash
# Reset specific config (creates backup automatically)
omyvoid refresh waybar
omyvoid refresh hyprland

# The refresh command:
# 1. Backs up current config with timestamp
# 2. Copies default from ~/.local/share/omyvoid/config/
# 3. Restarts the component
```

## Common Tasks

### Themes

```bash
omyvoid theme list              # Show available themes
omyvoid theme current           # Show current theme
omyvoid theme set <name>        # Apply theme (use "Tokyo Night" not "tokyo-night")
omyvoid theme bg next           # Cycle background
omyvoid theme install <url>     # Install from git repo
```

### Keybindings

Edit `~/.config/hypr/bindings.conf`. Format:
```
bind = SUPER, Return, exec, xdg-terminal-exec
bind = SUPER, Q, killactive
bind = SUPER SHIFT, E, exit
```

View current bindings: `omyvoid menu keybindings --print`

**IMPORTANT: When re-binding an existing key:**

1. First check existing bindings: `omyvoid menu keybindings --print`
2. If the key is already bound, you MUST add an `unbind` directive BEFORE your new `bind`
3. Inform the user what the key was previously bound to

Example - rebinding SUPER+F (which is bound to fullscreen by default):
```
# Unbind existing SUPER+F (was: fullscreen)
unbind = SUPER, F
# New binding for file manager
bind = SUPER, F, exec, nautilus
```

Always tell the user: "Note: SUPER+F was previously bound to fullscreen. I've added an unbind directive to override it."

### Display/Monitors

Edit `~/.config/hypr/monitors.conf`. Format:
```
monitor = eDP-1, 1920x1080@60, 0x0, 1
monitor = HDMI-A-1, 2560x1440@144, 1920x0, 1
```

List monitors: `hyprctl monitors`

### Window Rules

**CRITICAL: Hyprland window rules syntax changes frequently between versions.**

Before writing ANY window rules, you MUST fetch the current documentation from the official Hyprland wiki:
- https://github.com/hyprwm/hyprland-wiki/blob/main/content/Configuring/Window-Rules.md

DO NOT rely on cached or memorized window rule syntax. The format has changed multiple times and using outdated syntax will cause errors or unexpected behavior.

Window rules go in `~/.config/hypr/hyprland.conf` or a sourced file. Always verify the current syntax from the wiki first.

### Fonts

```bash
omyvoid font list               # Available fonts
omyvoid font current            # Current font
omyvoid font set <name>         # Change font
```

### System

```bash
omyvoid update                  # Full system update
omyvoid version                 # Show Omyvoid version
omyvoid debug --no-sudo --print # Debug info (ALWAYS use these flags)
omyvoid system lock             # Lock screen
omyvoid system shutdown         # Shutdown
omyvoid system reboot           # Reboot
```

**IMPORTANT:** Always run `omyvoid debug` with `--no-sudo --print` flags to avoid interactive sudo prompts that will hang the terminal.

## Troubleshooting

```bash
# Get debug information (ALWAYS use these flags to avoid interactive prompts)
omyvoid debug --no-sudo --print

# Upload logs for support
omyvoid upload log

# Reset specific config to defaults
omyvoid refresh <app>

# Refresh specific config file
# config-file path is relative to ~/.config/
# eg. `omyvoid refresh config hypr/hyprlock.conf` will refresh ~/.config/hypr/hyprlock.conf
omyvoid refresh config <config-file>

# Full reinstall of configs (nuclear option)
omyvoid reinstall
```

## Decision Framework

When user requests system changes:

1. **Is it a stock omyvoid command?** Use it directly
2. **Is it a config edit?** Edit in `~/.config/`, never `~/.local/share/omyvoid/`
3. **Is it a theme customization?** Create a NEW custom theme directory
4. **Is it automation?** Use hooks in `~/.config/omyvoid/hooks/`
5. **Is it a package install?** Use `omyvoid pkg add <pkgs...>` (uses XBPS repositories)
6. **Unsure if command exists?** Run `omyvoid commands` (or `omyvoid <group> --help` for one group)

### Reminder Requests

When the user asks to set a reminder, use `omyvoid reminder <minutes> [message]` directly. Convert natural language durations to minutes and title-case short reminder labels when appropriate.

```bash
omyvoid reminder 15 "Pickup Jack"
omyvoid reminder 60 "Check laundry"
omyvoid reminder show
omyvoid reminder clear
```

## Out of Scope

This skill intentionally does not cover Omyvoid source development. Do not use this skill for:
- Editing files in `~/.local/share/omyvoid/` (`bin/`, `config/`, `default/`, `themes/`, `migrations/`, etc.)
- Creating or editing migrations
- Running `omyvoid dev ...` commands

## Example Requests

- "Change my theme to catppuccin" -> `omyvoid theme set catppuccin`
- "Add a keybinding for Super+E to open file manager" -> Check existing bindings first, add `unbind` if needed, then add `bind` in `~/.config/hypr/bindings.conf`
- "Configure my external monitor" -> Edit `~/.config/hypr/monitors.conf`
- "Make the window gaps smaller" -> Edit `~/.config/hypr/looknfeel.conf`
- "Set up night light to turn on at sunset" -> `omyvoid toggle nightlight` or edit `~/.config/hypr/hyprsunset.conf`
- "Set a reminder to pickup jack in 15 minutes" -> `omyvoid reminder 15 "Pickup Jack"`
- "Show my reminders" -> `omyvoid reminder show`
- "Clear all reminders" -> `omyvoid reminder clear`
- "Customize the catppuccin theme colors" -> Create `~/.config/omyvoid/themes/catppuccin-custom/` by copying from stock, then edit
- "Run a script every time I change themes" -> Create `~/.config/omyvoid/hooks/theme-set`
- "Reset waybar to defaults" -> `omyvoid refresh waybar`
