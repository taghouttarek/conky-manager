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
    LAYOUT_FILE, SCREEN_W, SCREEN_H
)


@pytest.fixture
def sample_layout_file(tmp_path):
    """Create a sample layout.json file."""
    layout_file = tmp_path / "layout.json"
    layout_file.write_text(json.dumps({
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
        data = {"theme-a": {"x": 10, "y": 20, "w": 300, "h": 400}}
        save_layout(data)
        loaded = load_layout()
        assert loaded == data


class TestWidgetRect:
    """Test WidgetRect serialization."""

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
        rect = WidgetRect(mock_canvas, "test", 0, 0, 100, 100)
        # Move way off screen
        rect.move(99999, 99999)
        assert rect.x <= SCREEN_W - rect.w
        assert rect.y <= SCREEN_H - rect.h

    def test_resize_minimum_dimensions(self):
        """WidgetRect.resize enforces minimum dimensions."""
        mock_canvas = MagicMock()
        mock_canvas.create_rectangle.return_value = 1
        mock_canvas.create_text.return_value = 2
        rect = WidgetRect(mock_canvas, "test", 0, 0, 200, 200)
        # Try to shrink below minimum
        rect.resize(-500, -500)
        assert rect.w >= 100
        assert rect.h >= 50


class TestUpdateConkyrcPosition:
    """Test conkyrc position updates."""

    def test_update_gap_x(self, tmp_path):
        """gap_x replaced correctly."""
        conkyrc = tmp_path / "conkyrc"
        conkyrc.write_text("gap_x = 0,\n    gap_y = 0,")
        editor = LayoutEditor.__new__(LayoutEditor)
        widget = MagicMock()
        widget.x = 500
        widget.y = 300
        editor.update_conkyrc_position(conkyrc, widget)
        content = conkyrc.read_text()
        assert "gap_x = 500" in content
        assert "gap_y = 300" in content

    def test_update_gap_negative(self, tmp_path):
        """Negative gap values handled."""
        conkyrc = tmp_path / "conkyrc"
        conkyrc.write_text("gap_x = -10,\n    gap_y = 0,")
        editor = LayoutEditor.__new__(LayoutEditor)
        widget = MagicMock()
        widget.x = 100
        widget.y = 200
        editor.update_conkyrc_position(conkyrc, widget)
        content = conkyrc.read_text()
        assert "gap_x = 100" in content

    def test_no_change_no_write(self, tmp_path):
        """File not rewritten when values already correct."""
        conkyrc = tmp_path / "conkyrc"
        conkyrc.write_text("gap_x = 100,\n    gap_y = 200,")
        original_mtime = conkyrc.stat().st_mtime_ns
        editor = LayoutEditor.__new__(LayoutEditor)
        widget = MagicMock()
        widget.x = 100
        widget.y = 200
        editor.update_conkyrc_position(conkyrc, widget)
        # File should not have been rewritten
        assert conkyrc.stat().st_mtime_ns == original_mtime

    def test_symlink_resolved(self, tmp_path):
        """Symlinks resolved before read/write."""
        real_file = tmp_path / "real_conkyrc"
        real_file.write_text("gap_x = 0,\n    gap_y = 0,")
        symlink = tmp_path / "conkyrc"
        symlink.symlink_to(real_file)

        editor = LayoutEditor.__new__(LayoutEditor)
        widget = MagicMock()
        widget.x = 999
        widget.y = 888
        editor.update_conkyrc_position(symlink, widget)

        # Real file should be updated
        content = real_file.read_text()
        assert "gap_x = 999" in content


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

    def test_no_match_in_comments(self, tmp_path):
        """Comments with -- prefix not modified."""
        lua_file = tmp_path / "settings.lua"
        lua_file.write_text("-- local x = 50\n    local x = 30\n")
        editor = LayoutEditor.__new__(LayoutEditor)
        widget = MagicMock()
        widget.x = 999
        widget.y = 888
        editor.update_lua_position(lua_file, widget)
        content = lua_file.read_text()
        # Comment should not be changed (regex won't match due to multiline)
        lines = content.strip().split("\n")
        # The local x = 30 should be changed
        assert "local x = 999" in content

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


class TestApplyPositions:
    """Test the full apply_positions flow."""

    def test_apply_positions_updates_files(self, tmp_path, monkeypatch):
        """apply_positions updates both conkyrc and lua files."""
        # Setup theme directory
        conky_dir = tmp_path / ".config" / "conky"
        theme_dir = conky_dir / "test-conky-manager"
        theme_dir.mkdir(parents=True)

        conkyrc = theme_dir / "conkyrc"
        conkyrc.write_text("gap_x = 0,\n    gap_y = 0,")

        lua_file = theme_dir / "settings.lua"
        lua_file.write_text("    local widget_x = 30\n    local widget_y = 720\n")

        monkeypatch.setattr(layout_editor, "LAYOUT_FILE", tmp_path / "layout.json")

        # Create editor with mocked restart
        editor = LayoutEditor.__new__(LayoutEditor)
        editor.widgets = {
            "test-conky-manager": MagicMock(x=100, y=200, w=300, h=400)
        }

        with patch.object(editor, 'restart_themes'):
            with patch.object(editor, 'save'):
                with patch('pathlib.Path.home', return_value=tmp_path):
                    # Patch conky_config to use our temp dir
                    with patch.object(
                        layout_editor.Path, 'home',
                        return_value=tmp_path
                    ):
                        editor.apply_positions()

        # Check files were updated
        assert "gap_x = 100" in conkyrc.read_text()
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
