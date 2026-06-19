# Conky Manager

A full-featured Python/Tkinter GUI for managing Conky themes on Linux.

![Conky Manager Screenshot](image.png)

## Features

- **Theme Discovery** - Automatically scans `~/.conky/` and `~/.config/conky/` for themes
- **Theme Switching** - Activate/deactivate themes with one click
- **Multi-Theme Support** - Run multiple themes simultaneously
- **Archive Import** - Import themes from zip, tar, tar.gz, tar.xz, 7z
- **Folder Import** - Import themes directly from local folders
- **Autostart** - Configure themes to start on login via `.desktop` entries
- **Theme Editing** - Edit theme configs directly from the manager
- **Theme Deletion** - Remove unused themes

## Included Themes

| Theme | Description |
|-------|-------------|
| `claude` | Claude-themed system monitor |
| `Conky_Revisited_2` | Revisited desktop widgets |
| `Conky-Calendar-Extra` | Calendar with circular design (conky 1.19 compatible) |
| `Conky-Weather` | Weather display with OpenWeatherMap API |
| `modern` | Modern system widgets |
| `system-widgets` | System monitoring widgets |

## Installation

### Quick Install

```bash
chmod +x install.sh
./install.sh
```

### Manual Install

```bash
# Install dependencies
sudo apt install conky python3-tk lua5.3

# Copy files
mkdir -p ~/.local/share/conky-manager
cp conky_manager.py ~/.local/share/conky-manager/
chmod +x ~/.local/share/conky-manager/conky_manager.py

# Create launcher
cat > ~/.local/bin/conky-manager << 'EOF'
#!/bin/bash
exec python3 "$HOME/.local/share/conky-manager/conky_manager.py" "$@"
EOF
chmod +x ~/.local/bin/conky-manager
```

### Additional Dependencies (for specific themes)

```bash
# Weather theme
pip3 install pyowm

# Calendar theme
sudo apt install lm-sensors

# Lua support
sudo apt install lua5.3 libcairo2-dev
```

## Usage

```bash
# Launch the GUI
conky-manager

# Or run directly
python3 conky_manager.py
```

### Manual Conky Commands

```bash
# Start a theme
conky -c ~/.config/conky/<theme-name>/config &

# Stop all conky instances
killall conky

# Check running instances
ps aux | grep conky | grep -v grep
```

## Conky 1.19 Compatibility

This manager supports Conky 1.19+ with Lua-based configuration:

```lua
conky.config = {
    background = false,
    update_interval = 1,
    own_window = true,
    own_window_type = 'normal',
    font = 'Dejavu Sans:size=10',
    minimum_width = 300,
    minimum_height = 200,
}

conky.text = [[
${cpu}%
]]
```

### Deprecated Syntax (do not use)

- `xftfont` → use `font`
- `minimum_size W H` → use `minimum_width = W,` and `minimum_height = H,`

## Uninstall

```bash
chmod +x uninstall.sh
./uninstall.sh
```

## License

MIT License
