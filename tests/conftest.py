"""Shared fixtures for conky-manager tests"""
import json
import os
import shutil
import tempfile
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

REPO_DIR = Path(__file__).parent.parent
THEMES_DIR = REPO_DIR / "themes"


@pytest.fixture
def tmp_conky_dir(tmp_path):
    """Create a temporary conky config directory with sample themes."""
    conky_dir = tmp_path / ".config" / "conky"
    conky_dir.mkdir(parents=True)
    return conky_dir


@pytest.fixture
def sample_conkyrc(tmp_path):
    """Create a minimal valid conkyrc file."""
    conkyrc = tmp_path / "conkyrc"
    conkyrc.write_text("""\
conky.config = {
    background = false,
    update_interval = 1,
    own_window = true,
    own_window_type = 'normal',
    font = 'Dejavu Sans:size=10',
    minimum_width = 1920,
    minimum_height = 1080,
    alignment = 'top_left',
    gap_x = 0,
    gap_y = 0,
    lua_load = 'settings.lua',
    lua_draw_hook_pre = 'start_widgets',
}

conky.text = [[
${cpu}%
]]
""")
    return conkyrc


@pytest.fixture
def sample_settings_lua(tmp_path):
    """Create a minimal valid settings.lua file."""
    lua = tmp_path / "settings.lua"
    lua.write_text("""\
require 'cairo'
os.setlocale("en_US.utf8", "numeric")

HTML_color = "#FFFFFF"
transparency_bg = 0.6

mode = 1
operator = {CAIRO_OPERATOR_SOURCE, CAIRO_OPERATOR_CLEAR}

function hex2rgb(hex)
    hex = hex:gsub("#","")
    return (tonumber("0x"..hex:sub(1,2))/255), (tonumber("0x"..hex:sub(3,4))/255), tonumber("0x"..hex:sub(5,6))/255
end

r, g, b = hex2rgb(HTML_color)

function draw_square(cr, pos_x, pos_y, rectangle_x, rectangle_y, trans)
    cairo_set_operator(cr, operator[mode])
    cairo_set_source_rgba(cr, r, g, b, trans)
    cairo_rectangle(cr, pos_x, pos_y, rectangle_x, rectangle_y)
    cairo_fill(cr)
end

function draw_function(cr)
    local x = 30
    local y = 100
    draw_square(cr, x, y, 200, 100, 0.6)
end

function conky_start_widgets()
    local function draw_conky_function(cr)
        draw_function(cr)
    end

    if conky_window == nil then return end
    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
    local cr = cairo_create(cs)
    local updates = conky_parse('${updates}')
    local update_num = tonumber(updates or "0")
    if update_num and update_num > 5 then
        draw_conky_function(cr)
    end
    cairo_surface_destroy(cs)
    cairo_destroy(cr)
end
""")
    return lua


@pytest.fixture
def sample_layout_json(tmp_path):
    """Create a valid layout.json file."""
    layout_file = tmp_path / "layout.json"
    layout_file.write_text(json.dumps({
        "crypto-conky-manager": {"x": 30, "y": 720, "w": 250, "h": 250},
        "network-conky-manager": {"x": 30, "y": 220, "w": 220, "h": 160},
    }, indent=2))
    return layout_file


@pytest.fixture
def sample_theme_dir(tmp_conky_dir, sample_conkyrc, sample_settings_lua):
    """Create a minimal valid theme directory."""
    theme_dir = tmp_conky_dir / "test-conky-manager"
    theme_dir.mkdir()
    shutil.copy(sample_conkyrc, theme_dir / "conkyrc")
    shutil.copy(sample_settings_lua, theme_dir / "settings.lua")
    return theme_dir


@pytest.fixture
def patch_conky_dirs(tmp_conky_dir, monkeypatch):
    """Monkeypatch CONKY_DIR and CONKY_CONFIG_DIR to temp directories."""
    monkeypatch.setattr("pathlib.Path.home", lambda: tmp_conky_dir.parent.parent)
    return tmp_conky_dir


@pytest.fixture
def mock_pgrep_running():
    """Mock subprocess.run for pgrep to simulate running conky processes."""
    def mock_run(cmd, **kwargs):
        if cmd[0] == "pgrep":
            result = MagicMock()
            if "-a" in cmd:
                result.stdout = (
                    "12345 conky -c /home/user/.config/conky/test-conky-manager/conkyrc -d\n"
                    "12346 conky -c /home/user/.config/conky/other-conky-manager/conkyrc -d\n"
                )
            else:
                result.stdout = "12345\n12346\n"
            result.returncode = 0
            return result
        return MagicMock(returncode=1, stdout="")
    return mock_run


@pytest.fixture
def mock_pgrep_empty():
    """Mock subprocess.run for pgrep to simulate no running conky processes."""
    def mock_run(cmd, **kwargs):
        result = MagicMock()
        result.stdout = ""
        result.returncode = 1
        return result
    return mock_run
