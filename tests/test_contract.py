import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILL = (ROOT / "SKILL.md").read_text(encoding="utf-8")
README = (ROOT / "README.md").read_text(encoding="utf-8")
MANIFEST = json.loads((ROOT / "bootstrap-manifest.json").read_text(encoding="utf-8"))


class BootstrapContractTests(unittest.TestCase):
    def test_skill_has_portable_frontmatter(self):
        self.assertTrue(SKILL.startswith("---\n"))
        self.assertRegex(SKILL, r"(?m)^name: scout-brainstem-bootstrap$")
        self.assertRegex(SKILL, r"(?m)^version: 1\.0\.0$")
        self.assertRegex(SKILL, r"(?m)^description: .+")

    def test_manifest_and_skill_versions_match(self):
        self.assertEqual(MANIFEST["schema"], "scout-brainstem-bootstrap/1")
        self.assertEqual(MANIFEST["version"], "1.0.0")
        self.assertIn(f"version: {MANIFEST['version']}", SKILL)

    def test_pinned_installers_are_immutable_and_duplicated(self):
        commit = MANIFEST["brainstem"]["installer_commit"]
        self.assertRegex(commit, r"^[0-9a-f]{40}$")
        for platform in ("windows", "unix"):
            artifact = MANIFEST["brainstem"]["installers"][platform]
            self.assertIn(f"/{commit}/", artifact["url"])
            self.assertRegex(artifact["sha256"], r"^[0-9a-f]{64}$")
            self.assertIn(artifact["url"], SKILL)
            self.assertIn(artifact["sha256"], SKILL)

    def test_workflow_keeps_user_out_of_terminal(self):
        self.assertIn("The user never runs a terminal command.", SKILL)
        self.assertIn("Do all terminal", README)
        self.assertNotIn("Run this command in Terminal", README)

    def test_skill_requires_real_health_and_chat(self):
        self.assertIn("status: \"ok\"", SKILL)
        self.assertIn("POST /chat", SKILL)
        self.assertIn("session_id", SKILL)
        self.assertIn("leave_ui_open", MANIFEST["acceptance"])

    def test_skill_preserves_grail_and_private_state(self):
        self.assertIn("Never modify `rapp_brainstem/brainstem.py`", SKILL)
        self.assertIn("preserve", SKILL.lower())
        self.assertIn("Never print, copy, commit, or transmit", SKILL)
        self.assertEqual(
            MANIFEST["acceptance"]["grail_files_immutable"],
            [
                "rapp_brainstem/brainstem.py",
                "rapp_brainstem/index.html",
            ],
        )

    def test_skill_does_not_cross_into_cloud_deployment(self):
        forbidden = (
            "az group create",
            "azuredeploy.json",
            "func azure functionapp publish",
            "deploy.ps1",
            "deploy.sh",
        )
        for value in forbidden:
            self.assertNotIn(value, SKILL)
        self.assertIn("Never deploy Azure resources", SKILL)

    def test_readme_has_the_feedable_raw_skill_and_prompt(self):
        self.assertIn(MANIFEST["skill"]["raw_url"], README)
        self.assertIn("Attach the file to a Scout conversation", README)
        self.assertIn("leave Brainstem open", README)

    def test_support_installers_copy_the_root_skill_exactly(self):
        windows = (ROOT / "scripts" / "install-global-skill.ps1").read_text(
            encoding="utf-8"
        )
        unix = (ROOT / "scripts" / "install-global-skill.sh").read_text(
            encoding="utf-8"
        )
        self.assertIn('"SKILL.md"', windows)
        self.assertIn("Get-FileHash", windows)
        self.assertIn("cmp --silent", unix)
        self.assertNotIn("curl ", windows)
        self.assertNotIn("curl ", unix)

    def test_health_helpers_use_loopback_only(self):
        for name in ("check-brainstem.ps1", "check-brainstem.sh"):
            text = (ROOT / "scripts" / name).read_text(encoding="utf-8")
            self.assertIn("http://127.0.0.1:7071/health", text)
            self.assertNotRegex(text, r"https?://(?!127\.0\.0\.1)")


if __name__ == "__main__":
    unittest.main()
