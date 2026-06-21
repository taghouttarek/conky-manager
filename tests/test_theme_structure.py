"""Validate theme directory structure and configuration consistency."""
import re
from pathlib import Path

import pytest

REPO_DIR = Path(__file__).parent.parent
THEMES_DIR = REPO_DIR / "themes"


def get_theme_dirs():
    """Get all theme directories from the repo."""
    return [d for d in THEMES_DIR.iterdir()
            if d.is_dir() and d.name.endswith("-conky-manager")]


def get_conkyrc_files():
    """Get all conkyrc files (including symlinks) from themes."""
    files = []
    for theme_dir in get_theme_dirs():
        conkyrc = theme_dir / "conkyrc"
        if conkyrc.exists() or conkyrc.is_symlink():
            files.append(conkyrc)
    return files


def get_settings_lua_files():
    """Get all settings.lua files from themes."""
    return list(THEMES_DIR.glob("*-conky-manager/settings.lua"))


class TestThemeStructure:
    """Validate theme directory structure."""

    def test_all_themes_have_conkyrc(self):
        """Every theme directory must have a conkyrc file or symlink."""
        for theme_dir in get_theme_dirs():
            conkyrc = theme_dir / "conkyrc"
            # claude-conky-manager uses conkyrc.txt instead
            conkyrc_txt = theme_dir / "conkyrc.txt"
            has_config = (conkyrc.exists() or conkyrc.is_symlink() or
                         conkyrc_txt.exists() or conkyrc_txt.is_symlink())
            assert has_config, \
                f"{theme_dir.name} missing conkyrc"

    def test_theme_naming_convention(self):
        """All themes must end with -conky-manager."""
        for theme_dir in get_theme_dirs():
            assert theme_dir.name.endswith("-conky-manager"), \
                f"{theme_dir.name} doesn't follow naming convention"

    def test_theme_has_lua_files(self):
        """Themes with lua_load in conkyrc must have .lua files."""
        for conkyrc in get_conkyrc_files():
            content = conkyrc.read_text()
            if "lua_load" in content:
                theme_dir = conkyrc.parent
                lua_files = list(theme_dir.rglob("*.lua"))
                assert len(lua_files) > 0, \
                    f"{theme_dir.name} uses lua_load but has no .lua files"

    def test_theme_no_old_paths(self):
        """No theme should reference ~/.conky/ paths."""
        for conkyrc in get_conkyrc_files():
            content = conkyrc.read_text()
            assert "~/.conky/" not in content, \
                f"{conkyrc.name} contains old path ~/.conky/"

        for lua_file in get_settings_lua_files():
            content = lua_file.read_text()
            assert "~/.conky/" not in content, \
                f"{lua_file.name} contains old path ~/.conky/"

    def test_unified_positioning_fullscreen(self):
        """All themes must use fullscreen windows (1920x1080+)."""
        for conkyrc in get_conkyrc_files():
            content = conkyrc.read_text()
            if "minimum_width" in content:
                match = re.search(r'minimum_width\s*=\s*(\d+)', content)
                if match:
                    width = int(match.group(1))
                    assert width >= 1920, \
                        f"{conkyrc.parent.name}: minimum_width={width} < 1920"

    def test_unified_positioning_gap_zero(self):
        """All themes must have gap_x = 0."""
        for conkyrc in get_conkyrc_files():
            content = conkyrc.read_text()
            if "gap_x" in content:
                match = re.search(r'gap_x\s*=\s*(-?\d+)', content)
                if match:
                    gap_x = int(match.group(1))
                    assert gap_x == 0, \
                        f"{conkyrc.parent.name}: gap_x={gap_x} != 0"

    def test_theme_has_alignment(self):
        """All themes must have alignment setting."""
        for conkyrc in get_conkyrc_files():
            content = conkyrc.read_text()
            assert "alignment" in content, \
                f"{conkyrc.parent.name} missing alignment setting"

    def test_theme_has_gap_values(self):
        """All themes must have gap_x and gap_y."""
        for conkyrc in get_conkyrc_files():
            content = conkyrc.read_text()
            assert "gap_x" in content, \
                f"{conkyrc.parent.name} missing gap_x"
            assert "gap_y" in content, \
                f"{conkyrc.parent.name} missing gap_y"

    def test_theme_minimum_height(self):
        """All themes must have minimum_height >= 1080."""
        for conkyrc in get_conkyrc_files():
            content = conkyrc.read_text()
            if "minimum_height" in content:
                match = re.search(r'minimum_height\s*=\s*(\d+)', content)
                if match:
                    height = int(match.group(1))
                    assert height >= 1080, \
                        f"{conkyrc.parent.name}: minimum_height={height} < 1080"
