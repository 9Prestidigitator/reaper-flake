import os
import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path


MODULE = Path(os.environ["REAPACK_MODULE"])
LUA = os.environ.get("LUA", "lua")


def startup_script() -> str:
    source = MODULE.read_text()
    marker = 'startupScript = pkgs.writeText "reaper-flake-reapack-startup.lua" \'\'\n'
    start = source.index(marker) + len(marker)
    end = source.index("\n  '';\nin {", start)
    return textwrap.dedent(source[start:end])


class ReaPackStartupTests(unittest.TestCase):
    def run_startup(self, transaction_succeeds: bool):
        with tempfile.TemporaryDirectory() as directory:
            resource = Path(directory)
            reapack = resource / "ReaPack"
            reapack.mkdir()
            request = reapack / ".nix-package-request"
            request.write_text("Repo\tCategory\tPackage.lua\t1.0\t0\t0\n")
            script = resource / "startup.lua"
            script.write_text(startup_script())
            harness = resource / "harness.lua"
            harness.write_text(
                textwrap.dedent(
                    f"""
                    local resource = {str(resource)!r}
                    local transaction_succeeds = {str(transaction_succeeds).lower()}
                    local installed = {{}}
                    local queued = {{}}
                    local messages = {{}}

                    reaper = {{}}
                    function reaper.GetResourcePath() return resource end
                    function reaper.APIExists(_) return true end
                    function reaper.defer(callback) callback() end
                    function reaper.ReaPack_IsBusy(_) return false end
                    function reaper.ReaPack_QueuePackage(repo, category, package, version, pin, prereleases)
                      queued[repo .. "\\t" .. category .. "\\t" .. package] = {{version, pin, prereleases}}
                      return true, ""
                    end
                    function reaper.ReaPack_QueueUninstallPackage(_, _, _) return true, "" end
                    function reaper.ReaPack_ProcessQueue(_)
                      if transaction_succeeds then
                        for identity, value in pairs(queued) do installed[identity] = value end
                      end
                    end
                    function reaper.ReaPack_GetInstalledPackageInfo(repo, category, package)
                      local value = installed[repo .. "\\t" .. category .. "\\t" .. package]
                      if not value then return false, "", 0 end
                      return true, value[1], (value[2] and 1 or 0) + (value[3] and 2 or 0)
                    end
                    function reaper.ShowMessageBox(message, title, _)
                      messages[#messages + 1] = title .. ": " .. message
                    end

                    dofile({str(script)!r})
                    local message_file = io.open(resource .. "/messages", "w")
                    message_file:write(table.concat(messages, "\\n"))
                    message_file:close()
                    """
                )
            )
            subprocess.run([LUA, str(harness)], check=True)
            return {
                "request": request.exists(),
                "managed": (reapack / ".nix-managed-packages").read_text()
                if (reapack / ".nix-managed-packages").exists()
                else None,
                "messages": (resource / "messages").read_text(),
            }

    def test_commits_ledger_only_after_registry_verification(self):
        result = self.run_startup(True)
        self.assertFalse(result["request"])
        self.assertEqual(result["managed"], "Repo\tCategory\tPackage.lua\n")
        self.assertEqual(result["messages"], "")

    def test_retains_request_when_transaction_installs_nothing(self):
        result = self.run_startup(False)
        self.assertTrue(result["request"])
        self.assertIsNone(result["managed"])
        self.assertIn("request was retained", result["messages"])
        self.assertIn("package was not installed", result["messages"])


if __name__ == "__main__":
    unittest.main()
