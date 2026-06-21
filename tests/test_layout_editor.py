"""Tests for layout_editor.py functions."""
import json
import os
import tempfile
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

sys_path = str(Path(__file__).parent.parent)
import sys
sys.path.insert(0, sys_path)

import layout_editor
from layout_editor import (
    load_layout, save_layout, WidgetRect, LayoutEditor,
    LAYOUT_FILE, DEFAULT_SCREEN_W, DEFAULT_SCREEN_H,
    RESOLUTION_PRESETS, MIN_SCREEN_W, MIN_SCREEN_H,
    MAX_SCREEN_W, MAX_SCREEN_H
)


@pytest.fixture
def sample_layout_file(tmp_path):
    """Create a sample layout.json file."""
    layout_file = tmp_path / "layout.json"
    layout_file.write_text(json.dumps({
        "resolution": {"w": 1920, "h": 1080},
        "test-conky-manager": {"x": 100, "y": 200, "w": 300, "h": 400},
        "other-conky-manager": {"x": 50, "y": 50, "w": 200, "h": 200},
    }, indent=2))
    return layout_file


class TestLoadLayout:
    """Test layout loading."""

    def test_load_layout_valid_json(self, sample_layout_file, monkeypatch):
        """Valid layout.json loaded correctly."""
        monkeypatch.setattr(layout_editor, "LAYOUT_FILE", sample_layout_file)
        result = load_layout()
        assert "test-conky-manager" in result
        assert result["test-conky-manager"]["x"] == 100

    def test_load_layout_has_resolution(self, sample_layout_file, monkeypatch):
        """Resolution key loaded from layout.json."""
        monkeypatch.setattr(layout_editor, "LAYOUT_FILE", sample_layout_file)
        result = load_layout()
        assert "resolution" in result
        assert result["resolution"]["w"] == 1920
        assert result["resolution"]["h"] == 1080

    def test_load_layout_missing_file(self, tmp_path, monkeypatch):
        """Missing file returns empty dict."""
        monkeypatch.setattr(layout_editor, "LAYOUT_FILE", tmp_path / "nonexistent.json")
        result = load_layout()
        assert result == {}

    def test_load_layout_corrupted_json(self, tmp_path, monkeypatch):
        """Corrupted JSON returns empty dict."""
        corrupted = tmp_path / "corrupted.json"
        corrupted.write_text("{invalid json content")
        monkeypatch.setattr(layout_editor, "LAYOUT_FILE", corrupted)
        result = load_layout()
        assert result == {}


class TestSaveLayout:
    """Test layout saving."""

    def test_save_layout_creates_file(self, tmp_path, monkeypatch):
        """Layout file created on save."""
        layout_file = tmp_path / "layout.json"
        monkeypatch.setattr(layout_editor, "LAYOUT_FILE", layout_file)
        save_layout({"test": {"x": 0, "y": 0, "w": 100, "h": 100}})
        assert layout_file.exists()

    def test_save_layout_atomic(self, tmp_path, monkeypatch):
        """No temp files left after save."""
        layout_file = tmp_path / "layout.json"
        monkeypatch.setattr(layout_editor, "LAYOUT_FILE", layout_file)
        save_layout({"test": {"x": 0, "y": 0, "w": 100, "h": 100}})
        tmp_files = list(tmp_path.glob("*.tmp"))
        assert len(tmp_files) == 0

    def test_save_layout_roundtrip(self, tmp_path, monkeypatch):
        """Save -> load preserves data."""
        layout_file = tmp_path / "layout.json"
        monkeypatch.setattr(layout_editor, "LAYOUT_FILE", layout_file)
        data = {"resolution": {"w": 2560, "h": 1440},
                "theme-a": {"x": 10, "y": 20, "w": 300, "h": 400}}
        save_layout(data)
        loaded = load_layout()
        assert loaded == data

    def test_save_includes_resolution(self, tmp_path, monkeypatch):
        """Save includes resolution key."""
        layout_file = tmp_path / "layout.json"
        monkeypatch.setattr(layout_editor, "LAYOUT_FILE", layout_file)
        save_layout({"resolution": {"w": 3840, "h": 2160}})
        loaded = load_layout()
        assert loaded["resolution"]["w"] == 3840
        assert loaded["resolution"]["h"] == 2160


class TestWidgetRect:
    """Test WidgetRect."""

    def test_to_dict(self):
        """WidgetRect serializes to correct dict format."""
        mock_canvas = MagicMock()
        mock_canvas.create_rectangle.return_value = 1
        mock_canvas.create_text.return_value = 2
        rect = WidgetRect(mock_canvas, "test", 100, 200, 300, 400, "#ff0000")
        d = rect.to_dict()
        assert d["x"] == 100
        assert d["y"] == 200
        assert d["w"] == 300
        assert d["h"] == 400

    def test_move_constrains_to_screen(self):
        """WidgetRect.move constrains position within screen bounds."""
        mock_canvas = MagicMock()
        mock_canvas.create_rectangle.return_value = 1
        mock_canvas.create_text.return_value = 2
        rect = WidgetRect(mock_canvas, "test", 0, 0, 100, 100,
                          screen_w=1920, screen_h=1080)
        rect.move(99999, 99999)
        assert rect.x <= 1920 - rect.w
        assert rect.y <= 1080 - rect.h

    def test_move_custom_resolution(self):
        """WidgetRect.move respects custom screen dimensions."""
        mock_canvas = MagicMock()
        mock_canvas.create_rectangle.return_value = 1
        mock_canvas.create_text.return_value = 2
        rect = WidgetRect(mock_canvas, "test", 0, 0, 100, 100,
                          screen_w=2560, screen_h=1440)
        rect.move(99999, 99999)
        assert rect.x <= 2560 - rect.w
        assert rect.y <= 1440 - rect.h

    def test_resize_minimum_dimensions(self):
        """WidgetRect.resize enforces minimum dimensions."""
        mock_canvas = MagicMock()
        mock_canvas.create_rectangle.return_value = 1
        mock_canvas.create_text.return_value = 2
        rect = WidgetRect(mock_canvas, "test", 0, 0, 200, 200)
        rect.resize(-500, -500)
        assert rect.w >= 100
        assert rect.h >= 50

    def test_resize_custom_resolution(self):
        """WidgetRect.resize respects custom screen dimensions."""
        mock_canvas = MagicMock()
        mock_canvas.create_rectangle.return_value = 1
        mock_canvas.create_text.return_value = 2
        rect = WidgetRect(mock_canvas, "test", 0, 0, 200, 200,
                          screen_w=2560, screen_h=1440)
        rect.resize(99999, 99999)
        assert rect.w <= 2560
        assert rect.h <= 1440


class TestUpdateConkyrcPosition:
    """Test conkyrc position updates."""

    def test_update_gap_always_zero(self, tmp_path):
        """gap_x and gap_y always set to 0 (fullscreen window)."""
        conkyrc = tmp_path / "conkyrc"
        conkyrc.write_text("gap_x = 500,\n    gap_y = 300,")
        editor = LayoutEditor.__new__(LayoutEditor)
        editor.screen_w = 2560
        editor.screen_h = 1440
        widget = MagicMock()
        widget.x = 100
        widget.y = 200
        editor.update_conkyrc_position(conkyrc, widget)
        content = conkyrc.read_text()
        assert "gap_x = 0" in content
        assert "gap_y = 0" in content

    def test_update_minimum_width_height(self, tmp_path):
        """minimum_width and minimum_height updated with screen resolution."""
        conkyrc = tmp_path / "conkyrc"
        conkyrc.write_text("minimum_width = 1920, minimum_height = 1080,\ngap_x = 0,\n    gap_y = 0,")
        editor = LayoutEditor.__new__(LayoutEditor)
        editor.screen_w = 2560
        editor.screen_h = 1440
        widget = MagicMock()
        widget.x = 100
        widget.y = 200
        editor.update_conkyrc_position(conkyrc, widget)
        content = conkyrc.read_text()
        assert "minimum_width = 2560" in content
        assert "minimum_height = 1440" in content
        assert "gap_x = 0" in content
        assert "gap_y = 0" in content

    def test_update_gap_negative(self, tmp_path):
        """Negative gap values reset to 0."""
        conkyrc = tmp_path / "conkyrc"
        conkyrc.write_text("gap_x = -10,\n    gap_y = 0,")
        editor = LayoutEditor.__new__(LayoutEditor)
        editor.screen_w = 1920
        editor.screen_h = 1080
        widget = MagicMock()
        widget.x = 100
        widget.y = 200
        editor.update_conkyrc_position(conkyrc, widget)
        content = conkyrc.read_text()
        assert "gap_x = 0" in content

    def test_no_change_no_write(self, tmp_path):
        """File not rewritten when values already correct."""
        conkyrc = tmp_path / "conkyrc"
        conkyrc.write_text("minimum_width = 2560, minimum_height = 1440,\ngap_x = 0,\n    gap_y = 0,")
        original_mtime = conkyrc.stat().st_mtime_ns
        editor = LayoutEditor.__new__(LayoutEditor)
        editor.screen_w = 2560
        editor.screen_h = 1440
        widget = MagicMock()
        widget.x = 100
        widget.y = 200
        editor.update_conkyrc_position(conkyrc, widget)
        assert conkyrc.stat().st_mtime_ns == original_mtime

    def test_symlink_resolved(self, tmp_path):
        """Symlinks resolved before read/write."""
        real_file = tmp_path / "real_conkyrc"
        real_file.write_text("gap_x = 50,\n    gap_y = 60,")
        symlink = tmp_path / "conkyrc"
        symlink.symlink_to(real_file)

        editor = LayoutEditor.__new__(LayoutEditor)
        editor.screen_w = 1920
        editor.screen_h = 1080
        widget = MagicMock()
        widget.x = 999
        widget.y = 888
        editor.update_conkyrc_position(symlink, widget)

        content = real_file.read_text()
        assert "gap_x = 0" in content
        assert "gap_y = 0" in content


class TestUpdateLuaPosition:
    """Test Lua position updates."""

    def test_update_widget_x(self, tmp_path):
        """local widget_x = N replaced correctly."""
        lua_file = tmp_path / "settings.lua"
        lua_file.write_text("    local widget_x = 30\n    local widget_y = 720\n")
        editor = LayoutEditor.__new__(LayoutEditor)
        widget = MagicMock()
        widget.x = 500
        widget.y = 300
        editor.update_lua_position(lua_file, widget)
        content = lua_file.read_text()
        assert "local widget_x = 500" in content
        assert "local widget_y = 300" in content

    def test_update_local_x(self, tmp_path):
        """local x = N replaced correctly."""
        lua_file = tmp_path / "settings.lua"
        lua_file.write_text("    local x = 30\n    local y = 100\n")
        editor = LayoutEditor.__new__(LayoutEditor)
        widget = MagicMock()
        widget.x = 200
        widget.y = 400
        editor.update_lua_position(lua_file, widget)
        content = lua_file.read_text()
        assert "local x = 200" in content
        assert "local y = 400" in content

    def test_no_change_no_write(self, tmp_path):
        """File not rewritten when values already correct."""
        lua_file = tmp_path / "settings.lua"
        lua_file.write_text("    local widget_x = 100\n")
        original_mtime = lua_file.stat().st_mtime_ns
        editor = LayoutEditor.__new__(LayoutEditor)
        widget = MagicMock()
        widget.x = 100
        widget.y = 200
        editor.update_lua_position(lua_file, widget)
        assert lua_file.stat().st_mtime_ns == original_mtime

    def test_symlink_resolved(self, tmp_path):
        """Symlinks resolved before read/write."""
        real_file = tmp_path / "real_settings.lua"
        real_file.write_text("    local widget_x = 30\n")
        symlink = tmp_path / "settings.lua"
        symlink.symlink_to(real_file)

        editor = LayoutEditor.__new__(LayoutEditor)
        widget = MagicMock()
        widget.x = 555
        widget.y = 666
        editor.update_lua_position(symlink, widget)

        content = real_file.read_text()
        assert "local widget_x = 555" in content


class TestResolutionFeature:
    """Test resolution configuration feature."""

    def test_resolution_presets_exist(self):
        """All expected presets are defined."""
        assert "1920x1080" in RESOLUTION_PRESETS
        assert "2560x1440" in RESOLUTION_PRESETS
        assert "3840x2160" in RESOLUTION_PRESETS
        assert "Custom" in RESOLUTION_PRESETS

    def test_resolution_bounds(self):
        """Min/max bounds are defined."""
        assert MIN_SCREEN_W == 800
        assert MIN_SCREEN_H == 600
        assert MAX_SCREEN_W == 7680
        assert MAX_SCREEN_H == 4320

    def test_save_load_resolution_roundtrip(self, tmp_path, monkeypatch):
        """Resolution saved and loaded correctly."""
        layout_file = tmp_path / "layout.json"
        monkeypatch.setattr(layout_editor, "LAYOUT_FILE", layout_file)
        data = {
            "resolution": {"w": 2560, "h": 1440},
            "theme-a": {"x": 10, "y": 20, "w": 300, "h": 400}
        }
        save_layout(data)
        loaded = load_layout()
        assert loaded["resolution"]["w"] == 2560
        assert loaded["resolution"]["h"] == 1440

    def test_widget_respects_custom_resolution(self):
        """WidgetRect uses custom screen dimensions for clamping."""
        mock_canvas = MagicMock()
        mock_canvas.create_rectangle.return_value = 1
        mock_canvas.create_text.return_value = 2

        # 2560x1440 resolution
        rect = WidgetRect(mock_canvas, "test", 2500, 1400, 100, 50,
                          screen_w=2560, screen_h=1440)
        # Move right — should clamp to 2560-100=2460
        rect.move(1000, 0)
        assert rect.x == 2460

    def test_widget_rescales_with_resolution(self):
        """Widget positions scale proportionally with resolution change."""
        mock_canvas = MagicMock()
        mock_canvas.create_rectangle.return_value = 1
        mock_canvas.create_text.return_value = 2

        # At 1920x1080: widget at (960, 540) = center
        rect = WidgetRect(mock_canvas, "test", 960, 540, 200, 100,
                          screen_w=1920, screen_h=1080)

        # Scale to 2560x1440: 960 * (2560/1920) = 1280, 540 * (1440/1080) = 720
        sx = 2560 / 1920
        sy = 1440 / 1080
        rect.x = int(rect.x * sx)
        rect.y = int(rect.y * sy)
        rect.w = int(rect.w * sx)
        rect.h = int(rect.h * sy)
        rect.screen_w = 2560
        rect.screen_h = 1440

        assert rect.x == 1280
        assert rect.y == 720
        assert rect.w == 266  # 200 * 1.333
        assert rect.h == 133  # 100 * 1.333

    def test_current_preset_detection(self):
        """_current_preset returns correct preset name."""
        editor = LayoutEditor.__new__(LayoutEditor)
        editor.screen_w = 1920
        editor.screen_h = 1080
        assert editor._current_preset() == "1920x1080"

        editor.screen_w = 2560
        editor.screen_h = 1440
        assert editor._current_preset() == "2560x1440"

        editor.screen_w = 1366
        editor.screen_h = 768
        assert editor._current_preset() == "Custom"

    def test_conkyrc_gets_resolution_on_apply(self, tmp_path):
        """Apply writes minimum_width/minimum_height and gap=0 to conkyrc."""
        conkyrc = tmp_path / "conkyrc"
        conkyrc.write_text(
            "minimum_width = 1920, minimum_height = 1080,\n"
            "gap_x = 50,\n    gap_y = 60,"
        )
        editor = LayoutEditor.__new__(LayoutEditor)
        editor.screen_w = 3840
        editor.screen_h = 2160
        widget = MagicMock()
        widget.x = 100
        widget.y = 200
        editor.update_conkyrc_position(conkyrc, widget)
        content = conkyrc.read_text()
        assert "minimum_width = 3840" in content
        assert "minimum_height = 2160" in content
        assert "gap_x = 0" in content
        assert "gap_y = 0" in content


class TestApplyPositions:
    """Test the full apply_positions flow."""

    def test_apply_positions_updates_files(self, tmp_path, monkeypatch):
        """apply_positions updates both conkyrc and lua files."""
        conky_dir = tmp_path / ".config" / "conky"
        theme_dir = conky_dir / "test-conky-manager"
        theme_dir.mkdir(parents=True)

        conkyrc = theme_dir / "conkyrc"
        conkyrc.write_text("minimum_width = 1920, minimum_height = 1080,\ngap_x = 0,\n    gap_y = 0,")

        lua_file = theme_dir / "settings.lua"
        lua_file.write_text("    local widget_x = 30\n    local widget_y = 720\n")

        monkeypatch.setattr(layout_editor, "LAYOUT_FILE", tmp_path / "layout.json")

        editor = LayoutEditor.__new__(LayoutEditor)
        editor.screen_w = 2560
        editor.screen_h = 1440
        editor.widgets = {
            "test-conky-manager": MagicMock(x=100, y=200, w=300, h=400)
        }

        with patch.object(editor, 'restart_themes'):
            with patch.object(editor, 'save'):
                with patch.object(layout_editor.Path, 'home', return_value=tmp_path):
                    editor.apply_positions()

        content = conkyrc.read_text()
        assert "gap_x = 0" in content
        assert "gap_y = 0" in content
        assert "minimum_width = 2560" in content
        assert "minimum_height = 1440" in content
        assert "local widget_x = 100" in lua_file.read_text()


class TestGetRunningThemes:
    """Test running theme detection."""

    def test_detection_from_pgrep(self):
        """Running themes detected from pgrep output."""
        editor = LayoutEditor.__new__(LayoutEditor)
        with patch("layout_editor.subprocess.run") as mock_run:
            mock_run.return_value = MagicMock(
                stdout="12345 conky -c /home/user/.config/conky/test-conky-manager/conkyrc -d\n",
                returncode=0
            )
            running = editor.get_running_themes()
            assert "test-conky-manager" in running

    def test_detection_empty(self):
        """No running themes returns empty set."""
        editor = LayoutEditor.__new__(LayoutEditor)
        with patch("layout_editor.subprocess.run") as mock_run:
            mock_run.return_value = MagicMock(stdout="", returncode=1)
            running = editor.get_running_themes()
            assert len(running) == 0
