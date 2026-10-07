import os
from pathlib import Path
import plistlib
import subprocess
import unittest


class ManagedLauncherTests(unittest.TestCase):
    def test_launchers(self):
        darwin = Path(os.environ["DARWIN_WRAPPER"])
        linux = Path(os.environ["LINUX_WRAPPER"])
        base = Path(os.environ["BASE_PACKAGE"])
        app = darwin / "Applications/REAPER (flake).app"
        self.assertFalse((darwin / "Applications/Reaper.app").exists())
        self.assertEqual(list((darwin / "Applications").iterdir()), [app])
        self.assertFalse(app.is_symlink())
        with (app / "Contents/Info.plist").open("rb") as f:
            info = plistlib.load(f)
        with (base / "Applications/Reaper.app/Contents/Info.plist").open("rb") as f:
            original = plistlib.load(f)
        self.assertEqual(info["CFBundleIdentifier"], "com.cockos.reaper.reaper-flake")
        self.assertEqual(original["CFBundleIdentifier"], "com.cockos.reaper")
        self.assertEqual((app / "Contents/Resources" / info["CFBundleIconFile"]).read_text(), "icon\n")
        executable = app / "Contents/MacOS" / info["CFBundleExecutable"]
        self.assertIn(str(base / "Applications/Reaper.app/Contents/MacOS/REAPER"), executable.read_text())
        for launcher in [darwin / "bin/reaper", executable, linux / "bin/reaper"]:
            with self.subTest(launcher=str(launcher)):
                text = launcher.read_text()
                self.assertNotIn("DYLD_LIBRARY_PATH", text)
                if launcher != linux / "bin/reaper":
                    self.assertNotIn("LD_LIBRARY_PATH", text)
                else:
                    self.assertIn("export LD_LIBRARY_PATH=", text)
                def launch(args):
                    return subprocess.check_output([str(launcher), *args], text=True).splitlines()
                self.assertEqual(launch(["project with spaces.rpp"]), [
                    "-cfgfile", "/tmp/managed reaper's config/reaper.ini", "project with spaces.rpp"
                ])
                for flag in ["-cfgfile", "--cfgfile"]:
                    for args in [[flag, "/custom config.ini"], [flag + "=/custom config.ini"]]:
                        self.assertEqual(launch(args + ["project.rpp"]), args + ["project.rpp"])


if __name__ == "__main__":
    unittest.main()
