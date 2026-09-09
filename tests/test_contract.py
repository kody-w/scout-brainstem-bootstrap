import json
import hashlib
import unittest
import uuid
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILL = (ROOT / "SKILL.md").read_text(encoding="utf-8")
README = (ROOT / "README.md").read_text(encoding="utf-8")
MANIFEST = json.loads((ROOT / "bootstrap-manifest.json").read_text(encoding="utf-8"))
ADDON = json.loads((ROOT / "brainstem-addon.json").read_text(encoding="utf-8"))


class BootstrapContractTests(unittest.TestCase):
    def test_skill_has_portable_frontmatter(self):
        self.assertTrue(SKILL.startswith("---\n"))
        self.assertRegex(SKILL, r"(?m)^name: scout-brainstem-bootstrap$")
        self.assertRegex(SKILL, r"(?m)^version: 1\.1\.0$")
        self.assertRegex(SKILL, r"(?m)^description: .+")

    def test_manifest_and_skill_versions_match(self):
        self.assertEqual(MANIFEST["schema"], "scout-brainstem-bootstrap/1")
        self.assertEqual(MANIFEST["version"], "1.1.0")
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
        self.assertTrue(MANIFEST["acceptance"]["leave_workspace_preview_open"])
        self.assertFalse(MANIFEST["acceptance"]["leave_ui_open"])
        self.assertEqual(
            MANIFEST["acceptance"]["workspace_preview_status"],
            "connected",
        )

    def test_skill_preserves_grail_and_private_state(self):
        self.assertIn("do not edit `brainstem.py` or `index.html`", SKILL)
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
        self.assertIn("leave Brainstem connected", README)

    def test_workspace_is_the_primary_experience(self):
        workspace = MANIFEST["workspace"]
        self.assertEqual(
            workspace["preview"],
            "rapp_brainstem/index.html",
        )
        self.assertEqual(
            workspace["collaboration_root"],
            "rapp_brainstem/agents/experimental/scout",
        )
        self.assertEqual(
            workspace["collaboration_directories"],
            ["candidates", "evidence", "handoffs"],
        )
        self.assertIn("Do not open a separate browser window.", SKILL)
        self.assertIn("middle pane", SKILL)
        self.assertIn("real static `index.html`", SKILL)
        self.assertIn("Do not create `SCOUT.html`", SKILL)
        self.assertIn("Do not create `SCOUT.html`", SKILL)
        self.assertIn("or a sidecar gateway", SKILL)

    def test_workspace_setup_materializes_exact_working_pattern(self):
        setup = (ROOT / "scripts" / "setup-workspace.ps1").read_text(
            encoding="utf-8"
        )
        self.assertIn("Get-FileHash", setup)
        self.assertIn(ADDON["source"]["commit"], setup)
        self.assertIn(ADDON["source"]["ref"], setup)
        self.assertIn("rapp_brainstem/index.html", json.dumps(ADDON))
        self.assertIn("agents\\experimental\\scout", setup)
        self.assertIn("config core.autocrlf false", setup)
        self.assertIn("sparse-checkout init --no-cone", setup)
        self.assertIn("/rapp_brainstem/.brainstem_data/", setup)
        self.assertIn("update-index --assume-unchanged", setup)
        self.assertNotIn("SCOUT.html", setup)
        self.assertNotIn("scout_gateway.py", setup)

    def test_collaboration_contract_is_colocated(self):
        skill = (ROOT / "addon" / "SKILL.md").read_text(encoding="utf-8")
        map_text = (ROOT / "addon" / "COLLABORATION.md").read_text(
            encoding="utf-8"
        )
        setup = (ROOT / "scripts" / "setup-workspace.ps1").read_text(
            encoding="utf-8"
        )
        self.assertIn("scout-rapp-brainstem", skill)
        self.assertIn("candidates/", map_text)
        self.assertIn("evidence/", map_text)
        self.assertIn("handoffs/", map_text)
        self.assertIn("agents/experimental/scout", map_text)
        self.assertIn("install-addon.ps1", setup)

    def test_first_addon_is_rapp1_compliant(self):
        self.assertEqual(ADDON["schema"], "rapp-brainstem-addon/1")
        self.assertEqual(ADDON["name"], "@rapp/scout-native")
        self.assertRegex(
            ADDON["identity"]["rappid"],
            r"^rappid:@kody-w/scout-native:[0-9a-f]{64}$",
        )
        self.assertEqual(ADDON["protocol"]["spec"], "rapp/1")
        self.assertRegex(ADDON["protocol"]["commit"], r"^[0-9a-f]{40}$")
        self.assertRegex(
            ADDON["protocol"]["revision_frame_hash"],
            r"^[0-9a-f]{64}$",
        )
        self.assertEqual(ADDON["wire"]["transport"], "POST /chat")
        self.assertFalse(ADDON["wire"]["new_endpoints"])
        self.assertFalse(ADDON["wire"]["new_envelopes"])
        mint = uuid.UUID(ADDON["identity"]["mint"]["uuid"])
        expected_tail = hashlib.sha256(
            b"rapp/1:rappid\n" + mint.bytes
        ).hexdigest()
        self.assertTrue(
            ADDON["identity"]["rappid"].endswith(f":{expected_tail}")
        )

    def test_addon_declares_its_public_json_schema(self):
        schema = json.loads(
            (
                ROOT / "schemas" / "rapp-brainstem-addon-1.schema.json"
            ).read_text(encoding="utf-8")
        )
        self.assertEqual(
            ADDON["$schema"],
            schema["$id"],
        )
        self.assertEqual(
            schema["properties"]["schema"]["const"],
            "rapp-brainstem-addon/1",
        )
        self.assertEqual(
            schema["properties"]["wire"]["properties"]["transport"]["const"],
            "POST /chat",
        )

    def test_addon_payload_hashes_match(self):
        declared = {
            item["path"]: item for item in ADDON["payload"]["files"]
        }
        actual = {
            str(path.relative_to(ROOT / "addon")).replace("\\", "/"): path
            for path in (ROOT / "addon").rglob("*")
            if path.is_file() and "__pycache__" not in path.parts
        }
        self.assertEqual(set(declared), set(actual))
        for relative, path in actual.items():
            content = path.read_bytes()
            self.assertEqual(declared[relative]["bytes"], len(content))
            self.assertEqual(
                declared[relative]["sha256"],
                hashlib.sha256(content).hexdigest(),
            )

    def test_addon_uses_exact_static_preview_pattern(self):
        controller = (ROOT / "addon" / "brainstem-workspace.ps1").read_text(
            encoding="utf-8-sig"
        )
        self.assertIn("preview-config.js", controller)
        self.assertIn("Write-PreviewConfig", controller)
        self.assertIn("brainstem.py", controller)
        self.assertIn(
            "Refusing to stop an unverified or recycled process",
            controller,
        )
        self.assertNotIn("scout_gateway", controller)
        self.assertEqual(ADDON["install"]["preview"], "../../../index.html")
        self.assertEqual(
            ADDON["install"]["generated_config"],
            "preview-config.js",
        )

    def test_addon_spec_defines_reusable_public_shape(self):
        profile = (ROOT / "ADDON-SPEC.md").read_text(encoding="utf-8")
        self.assertIn("rapp-brainstem-addon/1", profile)
        self.assertIn("brainstem-addon.json", profile)
        self.assertIn("addon/", profile)
        self.assertIn("POST /chat", profile)
        self.assertIn("@rapp/scout-native", profile)

    def test_skill_has_post_setup_launchpad_and_approval_gate(self):
        for path in (
            "Teach my twin",
            "Build a daily loop",
            "Make a work briefing",
            "Prototype an automation",
            "Promote a tested draft",
        ):
            self.assertIn(path, SKILL)
        self.assertIn("Copilot Studio", SKILL)
        self.assertIn("Microsoft Copilot Cowork", SKILL)
        self.assertIn("published: false", SKILL)
        self.assertIn("explicit user confirmation", SKILL)

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
