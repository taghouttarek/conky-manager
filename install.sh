#!/bin/bash
# Conky Manager Installation Script

set -e

INSTALL_DIR="$HOME/.local/share/conky-manager"
BIN_DIR="$HOME/.local/bin"
SCRIPT_NAME="conky-manager"
DESKTOP_FILE="$HOME/.local/share/applications/conky-manager.desktop"
ICON_DIR="$HOME/.local/share/icons"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing Conky Manager..."

# Create directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$HOME/.local/share/applications"
mkdir -p "$ICON_DIR"
mkdir -p "$HOME/.config/conky"

# Copy manager files
cp "$REPO_DIR/conky_manager.py" "$INSTALL_DIR/conky_manager.py"
chmod +x "$INSTALL_DIR/conky_manager.py"

if [ -f "$REPO_DIR/layout_editor.py" ]; then
    cp "$REPO_DIR/layout_editor.py" "$INSTALL_DIR/layout_editor.py"
fi

if [ -f "$REPO_DIR/VERSION" ]; then
    cp "$REPO_DIR/VERSION" "$INSTALL_DIR/VERSION"
fi

# Backup existing themes before overwrite
BACKUP_DIR="$INSTALL_DIR/backups/$(date +%Y%m%d_%H%M%S)"
if ls "$HOME/.config/conky/"*-conky-manager 1>/dev/null 2>&1; then
    mkdir -p "$BACKUP_DIR"
    for theme_dir in "$HOME/.config/conky/"*-conky-manager; do
        if [ -d "$theme_dir" ]; then
            cp -r "$theme_dir" "$BACKUP_DIR/"
        fi
    done
    echo "Backup saved to $BACKUP_DIR"
fi

# Copy only *-conky-manager themes
if [ -d "$REPO_DIR/themes" ]; then
    for theme_dir in "$REPO_DIR/themes/"*-conky-manager; do
        if [ -d "$theme_dir" ]; then
            theme_name=$(basename "$theme_dir")
            rm -rf "$HOME/.config/conky/$theme_name"
            cp -r "$theme_dir" "$HOME/.config/conky/$theme_name"
        fi
    done
    echo "Themes installed to ~/.config/conky/"
fi

# Copy non-conky-manager themes (calendar, revisited, etc.)
for theme_dir in "$REPO_DIR/themes/"*/; do
    theme_name=$(basename "$theme_dir")
    if [ -d "$theme_dir" ] && [[ ! "$theme_name" == *"-conky-manager" ]]; then
        # Skip if already handled or is the old system-widgets
        if [ "$theme_name" != "system-widgets" ] && [ "$theme_name" != "conkyrc" ]; then
            rm -rf "$HOME/.config/conky/$theme_name"
            cp -r "$theme_dir" "$HOME/.config/conky/$theme_name"
        fi
    fi
done

# Copy icon
if [ -f "$REPO_DIR/icon.svg" ]; then
    cp "$REPO_DIR/icon.svg" "$INSTALL_DIR/icon.svg"
fi
if [ -f "$REPO_DIR/icon.png" ]; then
    cp "$REPO_DIR/icon.png" "$INSTALL_DIR/icon.png"
fi

# Create wrapper script in ~/.local/bin
cat > "$BIN_DIR/$SCRIPT_NAME" << 'EOF'
#!/bin/bash
exec python3 "$HOME/.local/share/conky-manager/conky_manager.py" "$@"
EOF
chmod +x "$BIN_DIR/$SCRIPT_NAME"

# Create .desktop file
cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=Conky Manager
Comment=Manage and configure Conky themes
Exec=$BIN_DIR/$SCRIPT_NAME
Icon=$INSTALL_DIR/icon.svg
Terminal=false
Type=Application
Categories=Utility;System;
Keywords=conky;monitor;system;widget;
EOF

# Update desktop database
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi

# Add to PATH if not already there
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$HOME/.bashrc"
    echo "Added $BIN_DIR to PATH in .bashrc"
fi

echo ""
echo "Installation complete!"
echo ""
echo "You can now run: $SCRIPT_NAME"
echo "Or find 'Conky Manager' in your application menu"
