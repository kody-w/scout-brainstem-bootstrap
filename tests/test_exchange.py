import ast
import importlib.util
import sys
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "addon" / "exchange.py"
SPEC = importlib.util.spec_from_file_location("scout_exchange", MODULE_PATH)
exchange = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = exchange
SPEC.loader.exec_module(exchange)


class ExchangeSafetyTests(unittest.TestCase):
    def test_agent_skill_agent_round_trip_is_exact(self):
        with TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "hello_agent.py"
            original = b"""from agents.basic_agent import BasicAgent\n\nclass HelloAgent(BasicAgent):\n    pass\n"""
            source.write_bytes(original)
            skill = root / "SKILL.md"
            restored = root / "restored_agent.py"
            exchange.agent_to_skill(source, skill)
            exchange.skill_to_agent(skill, restored)
            self.assertEqual(restored.read_bytes(), original)

    def test_skill_name_cannot_escape_generated_python_literal(self):
        with TemporaryDirectory() as directory:
            root = Path(directory)
            skill = root / "SKILL.md"
            skill.write_text(
                "---\n"
                'name: bad""";PWNED=True;"""\n'
                "description: Preserved guidance.\n"
                "---\n",
                encoding="utf-8",
            )
            agent = root / "generated_agent.py"
            exchange.skill_to_agent(skill, agent)
            generated = agent.read_text(encoding="utf-8")
            tree = ast.parse(generated)
            assigned = {
                target.id
                for node in ast.walk(tree)
                if isinstance(node, ast.Assign)
                for target in node.targets
                if isinstance(target, ast.Name)
            }
            self.assertNotIn("PWNED", assigned)

    def test_squad_export_refuses_private_files(self):
        with TemporaryDirectory() as directory:
            root = Path(directory)
            squad = root / "squad"
            squad.mkdir()
            (squad / "team.md").write_text("# Team\n", encoding="utf-8")
            (squad / ".env").write_text("TOKEN=private\n", encoding="utf-8")
            with self.assertRaises(exchange.ExchangeError):
                exchange.squad_to_skill(squad, root / "skill.md")

    def test_windows_and_unc_paths_are_refused(self):
        for path in (
            r"C:\outside.txt",
            r"\\server\share\outside.txt",
            r"folder\outside.txt",
        ):
            with self.subTest(path=path):
                with self.assertRaises(exchange.ExchangeError):
                    exchange._safe_relative(path)

    def test_squad_restore_requires_new_destination(self):
        with TemporaryDirectory() as directory:
            root = Path(directory)
            squad = root / "squad"
            squad.mkdir()
            (squad / "team.md").write_text("# Team\n", encoding="utf-8")
            skill = root / "skill.md"
            exchange.squad_to_skill(squad, skill)
            destination = root / "existing"
            destination.mkdir()
            with self.assertRaises(exchange.ExchangeError):
                exchange.skill_to_squad(skill, destination)


if __name__ == "__main__":
    unittest.main()
