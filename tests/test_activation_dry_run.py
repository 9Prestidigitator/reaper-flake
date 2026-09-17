import json
import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import unittest


@unittest.skipUnless(os.environ.get("ACTIVATION_ENTRIES"), "requires Nix activation fixtures")
class ActivationDryRunTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.root = self.directory / "resources"
        entries = json.loads(Path(os.environ["ACTIVATION_ENTRIES"]).read_text())
        self.entries = []
        for index, entry in enumerate(entries):
            # Relocate the evaluated scripts into an isolated test directory.
            script_path = shlex.split(entry)[1]
            script = self.directory / f"activation-{index}"
            script.write_text(Path(script_path).read_text().replace(
                "/REAPER_TEST_ROOT", str(self.root)))
            script.chmod(0o755)
            self.entries.append(entry.replace(script_path, str(script)))

    def activate(self, dry_run):
        # Home Manager's run contract: print commands when DRY_RUN is set,
        # otherwise execute them. Exercise the actual evaluated entry points.
        shell = '''
set -euo pipefail
run() {
    if [[ -v DRY_RUN ]]; then
        printf 'would run: %s\\n' "$*"
    else
        "$@"
    fi
}
'''
        environment = os.environ.copy()
        environment.pop("DRY_RUN", None)
        if dry_run:
            environment["DRY_RUN"] = "1"
        return subprocess.run(
            [os.environ["TEST_SHELL"], "-c", shell + "\n".join(self.entries)],
            env=environment, check=True, capture_output=True, text=True)

    def snapshot(self):
        return {
            str(path.relative_to(self.root)): (
                "link", os.readlink(path)
            ) if path.is_symlink() else (
                "directory",
            ) if path.is_dir() else (
                "file", path.read_bytes(), path.stat().st_mode, path.stat().st_mtime_ns
            )
            for path in self.root.rglob("*")
        }

    def test_dry_run_does_not_create_resource_directory(self):
        result = self.activate(dry_run=True)
        self.assertFalse(self.root.exists())
        self.assertEqual(result.stdout.count("would run:"), 3)

    def test_dry_run_preserves_existing_configuration_and_state(self):
        self.activate(dry_run=False)
        self.assertIn("test=managed", (self.root / "reaper.ini").read_text())
        self.assertTrue((self.root / "seed.txt").exists())
        self.assertTrue((self.root / "Data/theme.txt").is_symlink())
        self.assertTrue((self.root / "linked.txt").is_symlink())
        self.assertTrue((self.root / "generated.txt").exists())
        self.assertTrue((self.root / "Scripts/test.lua").exists())
        self.assertTrue((self.root / "ReaPack/.nix-sync-requested").exists())
        (self.root / "reaper.ini").write_text("[reaper]\ntest=user-change\n")
        stale = self.root / ".nix-managed/stale.ini"
        stale.write_text(json.dumps({"version": 2, "sections": {"old": {"key": "value"}}}))
        (self.root / "stale.ini").write_text("[old]\nkey=value\n")
        before = self.snapshot()
        self.activate(dry_run=True)
        self.assertEqual(self.snapshot(), before)
        self.activate(dry_run=False)
        self.assertIn("test=managed", (self.root / "reaper.ini").read_text())
        self.assertFalse(stale.exists())
        self.assertNotIn("key=value", (self.root / "stale.ini").read_text())


if __name__ == "__main__":
    unittest.main()
