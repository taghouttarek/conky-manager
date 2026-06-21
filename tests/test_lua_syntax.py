"""Validate Lua syntax and correctness across all theme files."""
import subprocess
import textwrap
from pathlib import Path

import pytest

REPO_DIR = Path(__file__).parent.parent
THEMES_DIR = REPO_DIR / "themes"


def get_all_lua_files():
    """Get all .lua files from themes."""
    return list(THEMES_DIR.glob("*-conky-manager/**/*.lua"))


def get_settings_lua_files():
    """Get all settings.lua files from themes."""
    return list(THEMES_DIR.glob("*-conky-manager/settings.lua"))


def run_luac(file_path):
    """Run luac -p on a file to check syntax."""
    try:
        result = subprocess.run(
            ["luac", "-p", str(file_path)],
            capture_output=True, text=True, timeout=10
        )
        return result.returncode == 0, result.stderr
    except FileNotFoundError:
        pytest.skip("luac not installed")


class TestLuaSyntax:
    """Validate Lua file syntax using luac."""

    def test_all_settings_lua_parse(self):
        """All settings.lua files must parse without syntax errors."""
        for lua_file in get_settings_lua_files():
            ok, err = run_luac(lua_file)
            assert ok, f"{lua_file.name} has syntax errors:\n{err}"

    def test_calendar_lua_widgets_parse(self):
        """Calendar lua_widgets.lua must parse without syntax errors."""
        lua_file = THEMES_DIR / "calendar-conky-manager" / "conky" / "lua_widgets.lua"
        if lua_file.exists():
            ok, err = run_luac(lua_file)
            assert ok, f"lua_widgets.lua has syntax errors:\n{err}"

    def test_revisited_settings_parse(self):
        """All revisited settings.lua variants must parse."""
        revisited_dir = THEMES_DIR / "revisited-conky-manager"
        for lua_file in revisited_dir.rglob("settings.lua"):
            ok, err = run_luac(lua_file)
            assert ok, f"{lua_file.relative_to(revisited_dir)} has syntax errors:\n{err}"


class TestLuaCorrectness:
    """Validate Lua code correctness patterns."""

    def test_hex2rgb_present(self):
        """hex2rgb function must exist in all settings.lua files."""
        for lua_file in get_settings_lua_files():
            content = lua_file.read_text()
            assert "function hex2rgb(hex)" in content, \
                f"{lua_file.name} missing hex2rgb function"

    def test_hex2rgb_blue_channel_fixed(self):
        """hex2rgb must not have the blue channel division bug."""
        buggy = 'tonumber(("0x"..hex:sub(5,6))/255)'
        for lua_file in get_settings_lua_files():
            content = lua_file.read_text()
            assert buggy not in content, \
                f"{lua_file.name} still has hex2rgb blue channel bug"

    def test_os_setlocale_present(self):
        """os.setlocale must be present in all settings.lua files."""
        for lua_file in get_settings_lua_files():
            content = lua_file.read_text()
            assert "os.setlocale" in content, \
                f"{lua_file.name} missing os.setlocale"

    def test_update_num_nil_guard(self):
        """update_num must have nil guard before comparison."""
        for lua_file in get_settings_lua_files():
            content = lua_file.read_text()
            # Check that no bare "if update_num > 5" exists without nil check
            if "update_num > 5" in content:
                assert "update_num and update_num > 5" in content or \
                       'tonumber(updates or "0") > 5' in content or \
                       'tonumber(updates) or 0' in content, \
                    f"{lua_file.name} has update_num without nil guard"

    def test_conky_start_widgets_entry(self):
        """conky_start_widgets function must exist in all settings.lua files."""
        for lua_file in get_settings_lua_files():
            content = lua_file.read_text()
            assert "function conky_start_widgets()" in content, \
                f"{lua_file.name} missing conky_start_widgets function"

    def test_no_io_popen_in_settings(self):
        """settings.lua files should not use io.popen (use os.getenv instead)."""
        for lua_file in get_settings_lua_files():
            content = lua_file.read_text()
            assert "io.popen" not in content, \
                f"{lua_file.name} uses io.popen instead of os.getenv"

    def test_no_docker_typo(self):
        """Docker settings.lua must not have size * 05 typo."""
        docker_lua = THEMES_DIR / "docker-conky-manager" / "settings.lua"
        if docker_lua.exists():
            content = docker_lua.read_text()
            assert "size * 05" not in content, \
                "docker settings.lua still has size * 05 typo"

    def test_local_variables_in_draw_functions(self):
        """draw_function should use local variables for x, y."""
        for lua_file in get_settings_lua_files():
            content = lua_file.read_text()
            # Check that x and y in draw_function are declared local
            if "function draw_function(cr)" in content:
                # Find the draw_function body
                match = re.search(
                    r'function draw_function\(cr\)(.*?)end',
                    content, re.DOTALL
                )
                if match:
                    body = match.group(1)
                    # Should have local x or local widget_x
                    assert "local x =" in body or "local widget_x =" in body, \
                        f"{lua_file.name}: draw_function x not declared local"
                    assert "local y =" in body or "local widget_y =" in body, \
                        f"{lua_file.name}: draw_function y not declared local"


# Need re for the last test
import re
