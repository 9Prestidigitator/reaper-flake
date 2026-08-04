import os
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DETECTOR = Path(
    os.environ.get(
        "REAPER_RUNNING_SCRIPT", ROOT / "scripts" / "reaper-is-running.sh"
    )
)
SHELL = os.environ.get("SHELL_FOR_TESTS", "/bin/sh")
PGREP = os.environ.get("PGREP_FOR_TESTS", shutil.which("pgrep") or "pgrep")


class ReaperRunningDetectorTests(unittest.TestCase):
    @unittest.skipUnless(sys.platform.startswith("linux"), "uses Linux prctl")
    def test_detects_nix_makewrapper_process_name(self):
        process = subprocess.Popen(
            [
                sys.executable,
                "-c",
                "import ctypes, time; "
                "ctypes.CDLL(None).prctl(15, b'.reaper-wrapped', 0, 0, 0); "
                "time.sleep(30)",
            ]
        )
        try:
            for _ in range(50):
                result = subprocess.run(
                    [SHELL, DETECTOR, PGREP],
                    check=False,
                    capture_output=True,
                    text=True,
                )
                if result.returncode == 0:
                    break
                time.sleep(0.01)
        finally:
            process.terminate()
            process.wait(timeout=5)

        self.assertEqual(result.returncode, 0, result.stderr)

    def test_checks_native_linux_wrapped_linux_and_macos_names(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            fake_pgrep = Path(temporary_directory) / "pgrep"
            log = Path(temporary_directory) / "patterns"
            fake_pgrep.write_text(
                "#!/bin/sh\n"
                'printf "%s\\n" "$2" >> "$PGREP_LOG"\n'
                "exit 1\n"
            )
            fake_pgrep.chmod(0o755)
            environment = os.environ | {"PGREP_LOG": str(log)}

            result = subprocess.run(
                [SHELL, DETECTOR, fake_pgrep],
                check=False,
                env=environment,
                capture_output=True,
                text=True,
            )

            self.assertEqual(result.returncode, 1)
            self.assertEqual(
                log.read_text().splitlines(),
                ["reaper", "REAPER", "[.]reaper-wrapped"],
            )


if __name__ == "__main__":
    unittest.main()
