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
    load_layout, save_layout, save_positions, WidgetRect, LayoutEditor,
    LAYOUT_FILE, POSITIONS_FILE, DEFAULT_SCREEN_W, DEFAULT_SCREEN_H,
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
        monkeypatch.setattr(layout_editor, "LAYOUT_FILE", sample_layout_file)
        result = load_layout()
        assert "test-conky-manager" in result
        assert result["test-conky-manager"]["x"] == 100

    def test_load_layout_has_resolution(self, sample_layout_file, monkeypatch):
        monkeypatch.setattr(layout_editor, "LAYOUT_FILE", sample_layout_file)
        result = load_layout()
        assert "resolution" in result
        assert result["resolution"]["w"] == 1920

    def test_load_layout_missing_file(self, tmp_path, monkeypatch):
        monkeypatch.setattr(layout_editor, "LAYOUT_FILE", tmp_path / "nonexistent.json")
        result = load_layout()
        assert result == {}

    def test_load_layout_corrupted_json(self, tmp_path, monkeypatch):
        corrupted = tmp_path / "corrupted.json"
        corrupted.write_text("{invalid json content")
        monkeypatch.setattr(layout_editor, "LAYOUT_FILE", corrupted)
        result = load_layout()
        assert result == {}


class TestSaveLayout:
    """Test layout saving."""

    def test_save_layout_creates_file(self, tmp_path, monkeypatch):
        layout_file = tmp_path / "layout.json"
        monkeypatch.setattr(layout_editor, "LAYOUT_FILE", layout_file)
        save_layout({"test": {"x": 0, "y": 0, "w": 100, "h": 100}})
        assert layout_file.exists()

    def test_save_layout_atomic(self, tmp_path, monkeypatch):
        layout_file = tmp_path / "layout.json"
        monkeypatch.setattr(layout_editor, "LAYOUT_FILE", layout_file)
        save_layout({"test": {"x": 0, "y": 0, "w": 100, "h": 100}})
        tmp_files = list(tmp_path.glob("*.tmp"))
        assert len(tmp_files) == 0

    def test_save_layout_roundtrip(self, tmp_path, monkeypatch):
        layout_file = tmp_path / "layout.json"
        monkeypatch.setattr(layout_editor, "LAYOUT_FILE", layout_file)
        data = {"resolution": {"w": 2560, "h": 1440},
                "theme-a": {"x": 10, "y": 20, "w": 300, "h": 400}}
        save_layout(data)
        loaded = load_layout()
        assert loaded == data

    def test_save_includes_resolution(self, tmp_path, monkeypatch):
        layout_file = tmp_path / "layout.json"
        monkeypatch.setattr(layout_editor, "LAYOUT_FILE", layout_file)
        save_layout({"resolution": {"w": 3840, "h": 2160}})
        loaded = load_layout()
        assert loaded["resolution"]["w"] == 3840


class TestSavePositions:
    """Test positions.lua generation."""

    def test_save_positions_creates_file(self, tmp_path, monkeypatch):
        pos_file = tmp_path / "positions.lua"
        monkeypatch.setattr(layout_editor, "POSITIONS_FILE", pos_file)
        widget = MagicMock(x=30, y=720)
        save_positions(1920, 1080, {"crypto-conky-manager": widget})
        assert pos_file.exists()

    def test_save_positions_content(self, tmp_path, monkeypatch):
        pos_file = tmp_path / "positions.lua"
        monkeypatch.setattr(layout_editor, "POSITIONS_FILE", pos_file)
        widget1 = MagicMock(x=30, y=720)
        widget2 = MagicMock(x=1640, y=306)
        save_positions(2560, 1440, {
            "crypto-conky-manager": widget1,
            "processes-conky-manager": widget2
        })
        content = pos_file.read_text()
        assert 'screen = {w = 2560, h = 1440}' in content
        assert '["crypto-conky-manager"] = {x = 30, y = 720}' in content
        assert '["processes-conky-manager"] = {x = 1640, y = 306}' in content

    def test_save_positions_atomic(self, tmp_path, monkeypatch):
        pos_file = tmp_path / "positions.lua"
        monkeypatch.setattr(layout_editor, "POSITIONS_FILE", pos_file)
        save_positions(1920, 1080, {})
        tmp_files = list(tmp_path.glob("*.tmp"))
        assert len(tmp_files) == 0


class TestWidgetRect:
    """Test WidgetRect."""

    def test_to_dict(self):
        mock_canvas = MagicMock()
        mock_canvas.create_rectangle.return_value = 1
        mock_canvas.create_text.return_value = 2
        rect = WidgetRect(mock_canvas, "test", 100, 200, 300, 400, "#ff0000")
        d = rect.to_dict()
        assert d["x"] == 100
        assert d["y"] == 200

    def test_move_custom_resolution(self):
        mock_canvas = MagicMock()
        mock_canvas.create_rectangle.return_value = 1
        mock_canvas.create_text.return_value = 2
        rect = WidgetRect(mock_canvas, "test", 0, 0, 100, 100,
                          screen_w=2560, screen_h=1440)
        rect.move(99999, 99999)
        assert rect.x <= 2560 - rect.w
        assert rect.y <= 1440 - rect.h

    def test_resize_custom_resolution(self):
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

    def test_update_minimum_width_height(self, tmp_path):
        conkyrc = tmp_path / "conkyrc"
        conkyrc.write_text("minimum_width = 1920, minimum_height = 1080,\ngap_x = 0,\n    gap_y = 0,")
        editor = LayoutEditor.__new__(LayoutEditor)
        editor.screen_w = 2560
        editor.screen_h = 1440
        widget = MagicMock()
        editor.update_conkyrc_position(conkyrc, widget)
        content = conkyrc.read_text()
        assert "minimum_width = 2560" in content
        assert "minimum_height = 1440" in content

    def test_gap_always_zero(self, tmp_path):
        conkyrc = tmp_path / "conkyrc"
        conkyrc.write_text("gap_x = 500,\n    gap_y = 300,")
        editor = LayoutEditor.__new__(LayoutEditor)
        editor.screen_w = 1920
        editor.screen_h = 1080
        widget = MagicMock()
        editor.update_conkyrc_position(conkyrc, widget)
        content = conkyrc.read_text()
        assert "gap_x = 0" in content
        assert "gap_y = 0" in content

    def test_no_change_no_write(self, tmp_path):
        conkyrc = tmp_path / "conkyrc"
        conkyrc.write_text("minimum_width = 2560, minimum_height = 1440,\ngap_x = 0,\n    gap_y = 0,")
        original_mtime = conkyrc.stat().st_mtime_ns
        editor = LayoutEditor.__new__(LayoutEditor)
        editor.screen_w = 2560
        editor.screen_h = 1440
        widget = MagicMock()
        editor.update_conkyrc_position(conkyrc, widget)
        assert conkyrc.stat().st_mtime_ns == original_mtime


class TestResolutionFeature:
    """Test resolution configuration feature."""

    def test_resolution_presets_exist(self):
        assert "1920x1080" in RESOLUTION_PRESETS
        assert "2560x1440" in RESOLUTION_PRESETS
        assert "3840x2160" in RESOLUTION_PRESETS
        assert "Custom" in RESOLUTION_PRESETS

    def test_resolution_bounds(self):
        assert MIN_SCREEN_W == 800
        assert MIN_SCREEN_H == 600

    def test_save_load_resolution_roundtrip(self, tmp_path, monkeypatch):
        layout_file = tmp_path / "layout.json"
        monkeypatch.setattr(layout_editor, "LAYOUT_FILE", layout_file)
        data = {"resolution": {"w": 2560, "h": 1440}}
        save_layout(data)
        loaded = load_layout()
        assert loaded["resolution"]["w"] == 2560

    def test_widget_respects_custom_resolution(self):
        mock_canvas = MagicMock()
        mock_canvas.create_rectangle.return_value = 1
        mock_canvas.create_text.return_value = 2
        rect = WidgetRect(mock_canvas, "test", 2500, 1400, 100, 50,
                          screen_w=2560, screen_h=1440)
        rect.move(1000, 0)
        assert rect.x == 2460

    def test_current_preset_detection(self):
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


class TestApplyPositions:
    """Test the full apply_positions flow."""

    def test_apply_positions_writes_positions_lua(self, tmp_path, monkeypatch):
        """Apply writes positions.lua with correct values."""
        conky_dir = tmp_path / ".config" / "conky"
        theme_dir = conky_dir / "test-conky-manager"
        theme_dir.mkdir(parents=True)

        conkyrc = theme_dir / "conkyrc"
        conkyrc.write_text("minimum_width = 1920, minimum_height = 1080,\ngap_x = 0,\n    gap_y = 0,")

        monkeypatch.setattr(layout_editor, "LAYOUT_FILE", tmp_path / "layout.json")
        monkeypatch.setattr(layout_editor, "POSITIONS_FILE", tmp_path / "positions.lua")

        editor = LayoutEditor.__new__(LayoutEditor)
        editor.screen_w = 2560
        editor.screen_h = 1440

        # Create real WidgetRect-like objects
        mock_canvas = MagicMock()
        mock_canvas.create_rectangle.return_value = 1
        mock_canvas.create_text.return_value = 2
        editor.widgets = {
            "test-conky-manager": WidgetRect(
                mock_canvas, "test-conky-manager", 100, 200, 300, 400, "#ff0000"
            )
        }

        with patch.object(editor, 'restart_themes'):
            with patch.object(layout_editor.Path, 'home', return_value=tmp_path):
                editor.apply_positions()

        # Check positions.lua was written
        pos_file = tmp_path / "positions.lua"
        assert pos_file.exists()
        content = pos_file.read_text()
        assert 'screen = {w = 2560, h = 1440}' in content
        assert '["test-conky-manager"] = {x = 100, y = 200}' in content

        # Check conkyrc was updated
        assert "minimum_width = 2560" in conkyrc.read_text()
        assert "minimum_height = 1440" in conkyrc.read_text()


class TestGetRunningThemes:
    """Test running theme detection."""

    def test_detection_from_pgrep(self):
        editor = LayoutEditor.__new__(LayoutEditor)
        with patch("layout_editor.subprocess.run") as mock_run:
            mock_run.return_value = MagicMock(
                stdout="12345 conky -c /home/user/.config/conky/test-conky-manager/conkyrc -d\n",
                returncode=0
            )
            running = editor.get_running_themes()
            assert "test-conky-manager" in running

    def test_detection_empty(self):
        editor = LayoutEditor.__new__(LayoutEditor)
        with patch("layout_editor.subprocess.run") as mock_run:
            mock_run.return_value = MagicMock(stdout="", returncode=1)
            running = editor.get_running_themes()
            assert len(running) == 0
