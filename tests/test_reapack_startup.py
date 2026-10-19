import os
import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path


MODULE_PATH = os.environ.get("REAPACK_MODULE")
MODULE = Path(MODULE_PATH) if MODULE_PATH else None
LUA = os.environ.get("LUA", "lua")


def startup_script() -> str:
    assert MODULE is not None
    source = MODULE.read_text()
    marker = 'startupScript = pkgs.writeText "reaper-flake-reapack-startup.lua" \'\'\n'
    start = source.index(marker) + len(marker)
    end = source.index("\n  '';\nin {", start)
    return textwrap.dedent(source[start:end])


@unittest.skipUnless(MODULE, "REAPACK_MODULE is only set by the Nix check")
class ReaPackStartupTests(unittest.TestCase):
    def run_startup(self, transaction_succeeds: bool, *, synchronize=False, queue_succeeds=True, retry=False):
        with tempfile.TemporaryDirectory() as directory:
            resource = Path(directory)
            reapack = resource / "ReaPack"
            reapack.mkdir()
            request = reapack / ".nix-package-request"
            request.write_text("Repo\tCategory\tPackage.lua\t1.0\t0\t0\n")
            sync = reapack / ".nix-sync-requested"
            if synchronize:
                sync.write_text("Repo\n")
            script = resource / "startup.lua"
            script.write_text(startup_script())
            harness = resource / "harness.lua"
            harness.write_text(
                textwrap.dedent(
                    f"""
                    local resource = {str(resource)!r}
                    local transaction_succeeds = {str(transaction_succeeds).lower()}
                    local queue_succeeds = {str(queue_succeeds).lower()}
                    local installed = {{}}
                    local queued = {{}}
                    local messages = {{}}

                    reaper = {{}}
                    function reaper.GetResourcePath() return resource end
                    function reaper.APIExists(_) return true end
                    function reaper.defer(callback) callback() end
                    function reaper.ReaPack_IsBusy(_) return false end
                    function reaper.ReaPack_ExportState(_) return true end
                    function reaper.ReaPack_QueueSynchronization(_) return queue_succeeds end
                    function reaper.ReaPack_LastTransactionSucceeded(_) return transaction_succeeds end
                    function reaper.ReaPack_QueuePackage(repo, category, package, version, pin, prereleases)
                      if not queue_succeeds then return false, "repository index is unavailable" end
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
                    if {str(retry).lower()} then
                      local function exists(path)
                        local file = io.open(path, "r")
                        if file then file:close(); return true end
                        return false
                      end
                      assert(exists(resource .. "/ReaPack/.nix-package-request"))
                      assert(not exists(resource .. "/ReaPack/.nix-managed-packages"))
                      local file = assert(io.open(resource .. "/ReaPack/reaper-flake-startup.log", "r"))
                      local first_log = file:read("*a"); file:close()
                      dofile({str(script)!r})
                      file = assert(io.open(resource .. "/ReaPack/reaper-flake-startup.log", "r"))
                      assert(file:read("*a") == first_log); file:close()
                      assert(#messages == 0)
                      transaction_succeeds = true
                      dofile({str(script)!r})
                    end
                    local message_file = io.open(resource .. "/messages", "w")
                    message_file:write(table.concat(messages, "\\n"))
                    message_file:close()
                    """
                )
            )
            subprocess.run([LUA, str(harness)], check=True)
            return {
                "request": request.exists(),
                "sync": sync.exists(),
                "log": (reapack / "reaper-flake-startup.log").read_text(),
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
        self.assertEqual(result["messages"], "")
        self.assertIn("request was retained", result["log"])
        self.assertIn("package was not installed", result["log"])

    def test_offline_synchronization_retains_both_requests_without_dialogs(self):
        result = self.run_startup(False, synchronize=True)
        self.assertTrue(result["request"])
        self.assertTrue(result["sync"])
        self.assertIsNone(result["managed"])
        self.assertEqual(result["messages"], "")
        self.assertIn("synchronization failed", result["log"])

    def test_queue_errors_are_logged_without_dialogs(self):
        result = self.run_startup(False, queue_succeeds=False)
        self.assertTrue(result["request"])
        self.assertIsNone(result["managed"])
        self.assertEqual(result["messages"], "")
        self.assertIn("repository index is unavailable", result["log"])

    def test_repeated_offline_starts_recover_when_connection_returns(self):
        for synchronize in (False, True):
            with self.subTest(synchronize=synchronize):
                result = self.run_startup(False, synchronize=synchronize, retry=True)
                self.assertFalse(result["request"])
                self.assertFalse(result["sync"])
                self.assertEqual(result["managed"], "Repo\tCategory\tPackage.lua\n")
                self.assertEqual(result["messages"], "")
                self.assertEqual(result["log"], "")


if __name__ == "__main__":
    unittest.main()
