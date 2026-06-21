#!/bin/bash
# Conky Manager Uninstallation Script

set -e

INSTALL_DIR="$HOME/.local/share/conky-manager"
BIN_DIR="$HOME/.local/bin"
SCRIPT_NAME="conky-manager"
DESKTOP_FILE="$HOME/.local/share/applications/conky-manager.desktop"

echo "Uninstalling Conky Manager..."

# Remove installed files
rm -rf "$INSTALL_DIR"
rm -f "$BIN_DIR/$SCRIPT_NAME"
rm -f "$DESKTOP_FILE"

# Ask about themes
echo ""
read -p "Remove installed themes from ~/.config/conky? (y/N): " remove_themes
if [[ "$remove_themes" =~ ^[Yy]$ ]]; then
    for theme_dir in "$HOME/.config/conky/"*-conky-manager; do
        if [ -d "$theme_dir" ]; then
            rm -rf "$theme_dir"
            echo "Removed $(basename "$theme_dir")"
        fi
    done
    echo "Themes removed."
else
    echo "Themes kept in ~/.config/conky/"
fi

# Update desktop database
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi

echo ""
echo "Uninstallation complete!"
