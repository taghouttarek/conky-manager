"""Tests for ConkyManager class business logic."""
import json
import os
import shutil
import tempfile
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

sys_path = str(Path(__file__).parent.parent)
import sys
sys.path.insert(0, sys_path)

import conky_manager
from conky_manager import ConkyManager


@pytest.fixture
def manager(tmp_path, monkeypatch):
    """Create a ConkyManager instance with temp directories."""
    conky_dir = tmp_path / ".config" / "conky"
    conky_dir.mkdir(parents=True)
    data_dir = tmp_path / ".local" / "share" / "conky-manager"
    data_dir.mkdir(parents=True)
    autostart_dir = tmp_path / ".config" / "autostart"
    autostart_dir.mkdir(parents=True)

    monkeypatch.setattr(conky_manager, "CONKY_DIR", conky_dir)
    monkeypatch.setattr(conky_manager, "CONKY_CONFIG_DIR", conky_dir)
    monkeypatch.setattr(conky_manager, "DATA_DIR", data_dir)
    monkeypatch.setattr(conky_manager, "SETTINGS_FILE", data_dir / "settings.json")
    monkeypatch.setattr(conky_manager, "LOG_FILE", data_dir / "manager.log")
    monkeypatch.setattr(conky_manager, "AUTOSTART_DIR", autostart_dir)

    m = ConkyManager()
    m.conky_dir = conky_dir
    m.autostart_dir = autostart_dir
    return m


class TestLoadSaveSettings:
    """Test settings persistence."""

    def test_load_settings_creates_default(self, manager):
        """Default settings created when file doesn't exist."""
        result = manager.load_settings()
        assert "running_themes" in result

    def test_load_settings_reads_json(self, manager):
        """Settings loaded correctly from JSON file."""
        conky_manager.SETTINGS_FILE.write_text(json.dumps({
            "running_themes": ["test-theme"],
            "autostart_enabled": False,
            "window_position": {"x": 100, "y": 200}
        }))
        result = manager.load_settings()
        assert result["running_themes"] == ["test-theme"]
        assert result["window_position"]["x"] == 100

    def test_save_settings_roundtrip(self, manager):
        """Load -> save -> load preserves data."""
        manager.settings = {
            "running_themes": ["theme-a", "theme-b"],
            "autostart_enabled": False,
        }
        manager.save_settings()
        loaded = manager.load_settings()
        assert loaded["running_themes"] == ["theme-a", "theme-b"]

    def test_save_settings_atomic(self, manager):
        """Settings saved atomically (no temp files left)."""
        manager.settings = {"running_themes": [], "autostart_enabled": False}
        manager.save_settings()
        tmp_files = list(conky_manager.SETTINGS_FILE.parent.glob("*.tmp"))
        assert len(tmp_files) == 0


class TestLog:
    """Test logging functionality."""

    def test_log_creates_file(self, manager):
        """Log file created on first call."""
        manager.log("Test message")
        assert conky_manager.LOG_FILE.exists()

    def test_log_appends_entries(self, manager):
        """Log entries are appended correctly."""
        manager.log("First message")
        manager.log("Second message")
        content = conky_manager.LOG_FILE.read_text()
        assert "First message" in content
        assert "Second message" in content

    def test_log_contains_timestamp(self, manager):
        """Log entries contain timestamps."""
        manager.log("Test")
        content = conky_manager.LOG_FILE.read_text()
        assert any(c.isdigit() for c in content)


class TestAnalyzeTheme:
    """Test theme analysis functions."""

    def test_analyze_theme_dir_with_conkyrc(self, manager, tmp_path):
        """Detects theme with conkyrc file."""
        theme_dir = tmp_path / "test-theme"
        theme_dir.mkdir()
        (theme_dir / "conkyrc").write_text("conky.config = {}")
        result = manager.analyze_theme_dir(theme_dir)
        assert result is not None
        assert result["name"] == "test-theme"

    def test_analyze_theme_dir_with_conf(self, manager, tmp_path):
        """Detects theme with .conf file."""
        theme_dir = tmp_path / "test-theme"
        theme_dir.mkdir()
        (theme_dir / "config.conf").write_text("conky.config = {}")
        result = manager.analyze_theme_dir(theme_dir)
        assert result is not None

    def test_analyze_theme_dir_empty(self, manager, tmp_path):
        """Empty directory returns no theme."""
        theme_dir = tmp_path / "empty-theme"
        theme_dir.mkdir()
        result = manager.analyze_theme_dir(theme_dir)
        assert result is None

    def test_analyze_theme_file_valid(self, manager, tmp_path):
        """Valid config file analyzed correctly."""
        config = tmp_path / "conkyrc"
        config.write_text("conky.config = { gap_x = 0 }")
        result = manager.analyze_theme_file(config)
        assert result is not None
        assert result["config"] == str(config)

    def test_analyze_theme_file_missing(self, manager, tmp_path):
        """Missing file still returns a dict (no existence check in code)."""
        config = tmp_path / "nonexistent"
        result = manager.analyze_theme_file(config)
        # analyze_theme_file doesn't check existence, returns dict anyway
        assert result is not None


class TestFindThemeByName:
    """Test theme lookup by name."""

    def test_find_theme_by_name_found(self, manager):
        """Theme found by name."""
        manager.themes = [
            {"name": "theme-a", "config": "/path/a"},
            {"name": "theme-b", "config": "/path/b"},
        ]
        result = manager.find_theme_by_name("theme-a")
        assert result is not None
        assert result["name"] == "theme-a"

    def test_find_theme_by_name_not_found(self, manager):
        """Missing theme returns None."""
        manager.themes = [{"name": "theme-a", "config": "/path/a"}]
        result = manager.find_theme_by_name("theme-b")
        assert result is None


class TestScanThemes:
    """Test theme scanning."""

    def test_scan_themes_finds_themes(self, manager, tmp_path):
        """scan_themes discovers all themes in directory."""
        for name in ["theme-a-conky-manager", "theme-b-conky-manager"]:
            theme_dir = manager.conky_dir / name
            theme_dir.mkdir()
            (theme_dir / "conkyrc").write_text("conky.config = {}")

        themes = manager.scan_themes()
        names = [t["name"] for t in themes]
        assert "theme-a-conky-manager" in names
        assert "theme-b-conky-manager" in names

    def test_scan_themes_empty_dir(self, manager):
        """Empty directory returns no themes."""
        themes = manager.scan_themes()
        assert len(themes) == 0


class TestStartStopConky:
    """Test conky process management."""

    @patch("conky_manager.subprocess.Popen")
    @patch("conky_manager.subprocess.run")
    def test_start_conky_launches_process(self, mock_run, mock_popen, manager, tmp_path):
        """conky subprocess launched with correct args."""
        theme_dir = manager.conky_dir / "test-conky-manager"
        theme_dir.mkdir()
        config = theme_dir / "conkyrc"
        config.write_text("conky.config = {}")

        # Mock is_theme_running to return False
        mock_run.return_value = MagicMock(stdout="", returncode=1)
        mock_popen.return_value = MagicMock()

        theme = {"name": "test-conky-manager", "config": str(config)}
        result = manager.start_conky(theme)

        assert result is True
        # Find the Popen call (not the pgrep call)
        popen_calls = [c for c in mock_popen.call_args_list]
        assert len(popen_calls) >= 1
        call_args = popen_calls[0][0][0]
        assert "conky" in call_args[0]
        assert "-c" in call_args

    @patch("conky_manager.subprocess.run")
    def test_is_theme_running_true(self, mock_run, manager):
        """Returns True when pgrep finds process."""
        mock_run.return_value = MagicMock(
            stdout="12345 conky -c /path/to/conkyrc\n",
            returncode=0
        )
        theme = {"config": "/path/to/conkyrc"}
        assert manager.is_theme_running(theme) is True

    @patch("conky_manager.subprocess.run")
    def test_is_theme_running_false(self, mock_run, manager):
        """Returns False when pgrep finds nothing."""
        mock_run.return_value = MagicMock(stdout="", returncode=1)
        theme = {"config": "/path/to/conkyrc"}
        assert manager.is_theme_running(theme) is False

    @patch("conky_manager.subprocess.run")
    def test_is_conky_running_true(self, mock_run, manager):
        """Returns True when conky processes exist."""
        mock_run.return_value = MagicMock(stdout="12345\n", returncode=0)
        assert manager.is_conky_running() is True

    @patch("conky_manager.subprocess.run")
    def test_is_conky_running_false(self, mock_run, manager):
        """Returns False when no conky processes."""
        mock_run.return_value = MagicMock(stdout="", returncode=1)
        assert manager.is_conky_running() is False


class TestAutostart:
    """Test autostart functionality."""

    def test_set_autostart_creates_desktop(self, manager):
        """Desktop file created in autostart dir."""
        theme = {
            "name": "test-theme",
            "config": "/tmp/conkyrc",
        }
        manager.set_autostart(theme, True)

        desktop_files = list(conky_manager.AUTOSTART_DIR.glob("*.desktop"))
        assert len(desktop_files) == 1
        content = desktop_files[0].read_text()
        assert "test-theme" in content

    def test_set_autostart_removes_desktop(self, manager):
        """Desktop file removed."""
        # Create a desktop file with the correct naming convention (conky-*.desktop)
        desktop = conky_manager.AUTOSTART_DIR / "conky-test-theme.desktop"
        desktop.write_text("[Desktop Entry]\nName=test\nExec=/usr/bin/conky -c /tmp/conkyrc -m 0\n")

        theme = {"name": "test-theme", "config": "/tmp/conkyrc"}
        manager.set_autostart(theme, False)

        assert not desktop.exists()

    def test_is_autostart_true(self, manager):
        """Returns True for autostarted theme."""
        # Create desktop file with correct naming convention
        desktop = conky_manager.AUTOSTART_DIR / "conky-test-theme.desktop"
        desktop.write_text("[Desktop Entry]\nName=test\nExec=/usr/bin/conky -c /tmp/conkyrc -m 0\n")

        # Add theme to manager.themes so get_autostart_themes can match it
        manager.themes = [{"name": "test-theme", "config": "/tmp/conkyrc"}]
        theme = {"name": "test-theme", "config": "/tmp/conkyrc"}
        assert manager.is_autostart(theme) is True

    def test_is_autostart_false(self, manager):
        """Returns False for non-autostarted theme."""
        theme = {"name": "test-theme", "config": "/tmp/conkyrc"}
        assert manager.is_autostart(theme) is False


class TestFindThemeInDir:
    """Test theme config discovery in directories."""

    def test_find_theme_in_dir_with_conkyrc(self, manager, tmp_path):
        """Theme config found in extracted dir."""
        theme_dir = tmp_path / "extracted"
        theme_dir.mkdir()
        (theme_dir / "conkyrc").write_text("conky.config = {}")
        result = manager.find_theme_in_dir(theme_dir)
        assert result is not None

    def test_find_theme_in_dir_with_lua_load(self, manager, tmp_path):
        """Theme config with lua_load found."""
        theme_dir = tmp_path / "extracted"
        theme_dir.mkdir()
        (theme_dir / "config.conf").write_text(
            "conky.config = { lua_load = 'settings.lua' }"
        )
        result = manager.find_theme_in_dir(theme_dir)
        assert result is not None

    def test_find_theme_in_dir_not_found(self, manager, tmp_path):
        """No config found returns the dir itself."""
        theme_dir = tmp_path / "empty"
        theme_dir.mkdir()
        (theme_dir / "readme.txt").write_text("no config here")
        result = manager.find_theme_in_dir(theme_dir)
        # Returns the dir path as fallback, not None
        assert result is not None


class TestArchiveExtensions:
    """Test archive type detection."""

    def test_archive_extensions_dict(self):
        """ARCHIVE_EXTENSIONS has correct mappings."""
        from conky_manager import ARCHIVE_EXTENSIONS
        assert ".zip" in ARCHIVE_EXTENSIONS
        assert ".tar.gz" in ARCHIVE_EXTENSIONS
        assert ".tar.xz" in ARCHIVE_EXTENSIONS
        assert ".7z" in ARCHIVE_EXTENSIONS
