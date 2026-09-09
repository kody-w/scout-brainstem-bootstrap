import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(sys.platform == "win32", "Requires Windows PowerShell 5.1")
class WindowsBootstrapReproTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        powershell = (
            Path(os.environ["SystemRoot"])
            / "System32"
            / "WindowsPowerShell"
            / "v1.0"
            / "powershell.exe"
        )
        cls.command = [
            str(powershell),
            "-NoProfile",
            "-NonInteractive",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "repro-windows-bootstrap.ps1"),
            "-PythonPath",
            sys.executable,
        ]
        result = subprocess.run(
            cls.command,
            capture_output=True,
            text=True,
            timeout=45,
            check=True,
        )
        cls.report = json.loads(result.stdout)

    def test_offline_reproduction_does_not_execute_the_installer(self):
        self.assertEqual(self.report["schema"], "scout-bootstrap-windows-repro/1")
        self.assertEqual(self.report["source"], "offline-fixture")
        self.assertIsNone(self.report["pin_verified"])
        self.assertFalse(self.report["installer_executed"])
        self.assertFalse(self.report["runtime_touched"])
        self.assertTrue(self.report["source_unchanged"])
        self.assertTrue(self.report["temporary_files_removed"])

    def test_utf8_source_is_valid_but_ansi_fixture_is_not(self):
        encoding = self.report["encoding"]
        self.assertEqual(encoding["explicit_utf8_parse_error_count"], 0)
        self.assertGreater(encoding["windows_1252_fixture_error_count"], 0)
        if self.report["default_code_page"] == 1252:
            self.assertGreater(encoding["default_parse_error_count"], 0)

    def test_separate_native_streams_preserve_a_successful_exit(self):
        native = self.report["native_stderr"]
        self.assertTrue(native["merged_stream_error_id"].startswith("NativeCommandError"))
        self.assertEqual(native["separate_stream_exit_code"], 0)
        self.assertTrue(native["stdout_captured"])
        self.assertTrue(native["stderr_captured"])

    def test_unpinned_local_installer_is_rejected_without_modification(self):
        with tempfile.TemporaryDirectory(prefix="scout-bootstrap-test-") as directory:
            installer = Path(directory) / "untrusted-install.ps1"
            source = b'throw "This installer must never execute."\n'
            installer.write_bytes(source)
            result = subprocess.run(
                self.command + ["-InstallerPath", str(installer)],
                capture_output=True,
                text=True,
                timeout=45,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("hash mismatch", result.stderr.lower())
            self.assertEqual(installer.read_bytes(), source)


if __name__ == "__main__":
    unittest.main()
