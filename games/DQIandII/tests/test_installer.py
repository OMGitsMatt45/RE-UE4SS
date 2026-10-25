"""Exercise file ownership, build gates, rollback and backup restoration on fixtures."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parents[1]
PATHS = ['dwmapi.dll', 'ue4ss/UE4SS.dll', 'ue4ss/UE4SS-settings.ini',
         'ue4ss/VTableLayout.ini', 'ue4ss/LICENSE',
         'ue4ss/Mods/DQIandIIProbe/enabled.txt', 'ue4ss/Mods/DQIandIIProbe/scripts/main.lua']

class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='dqiandii-installer-')
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.game = self.root / 'game'
        self.bin = self.game / 'Game/Binaries/Win64'
        self.bin.mkdir(parents=True)
        exe = b'test executable fixture; never a game binary'
        (self.bin / 'DQIandIIHD2DRemake.exe').write_bytes(exe)
        self.package = self.root / 'package'
        self.package.mkdir()
        # Only fixture copies replace the production build pin. No runtime bypass exists.
        script = (SOURCE / 'Manage-DQIandII.ps1').read_text()
        script = script.replace('4c0a3b982bb328320a55f9d06a6f672be7b2d896f3e84ed7ce9446a17213074f', hashlib.sha256(exe).hexdigest())
        self.script = self.package / 'Manage-DQIandII.ps1'
        self.script.write_text(script)
        entries = []
        for name in PATHS:
            data = ('fixture ' + name).encode()
            dest = self.package / 'payload' / name
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(data)
            entries.append({'path': name, 'sha256': hashlib.sha256(data).hexdigest()})
        (self.package / 'manifest.json').write_text(json.dumps({'schema': 1, 'version': 'test', 'files': entries}))
        (self.bin / 'dsound.dll').write_bytes(b'preexisting loader')
        other = self.bin / 'ue4ss/Mods/Unrelated/scripts/main.lua'
        other.parent.mkdir(parents=True)
        other.write_bytes(b'preexisting mod')

    def run_action(self, action, ok=True, replace=False):
        args = ['powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', str(self.script),
                '-Action', action, '-GameDirectory', str(self.game)]
        if replace:
            args.append('-ReplaceExisting')
        env = os.environ.copy()
        # Let Windows PowerShell discover its own built-in module directories.
        env.pop('PSModulePath', None)
        result = subprocess.run(args, capture_output=True, text=True, env=env)
        self.assertEqual(result.returncode == 0, ok, result.stdout + result.stderr)
        return result

    def test_install_verify_uninstall_preserves_unrelated(self):
        self.run_action('Install')
        self.run_action('Verify')
        self.run_action('Uninstall')
        self.assertEqual((self.bin / 'dsound.dll').read_bytes(), b'preexisting loader')
        self.assertEqual((self.bin / 'ue4ss/Mods/Unrelated/scripts/main.lua').read_bytes(), b'preexisting mod')
        self.assertTrue(all(not (self.bin / name).exists() for name in PATHS))

    def test_collision_and_backup_restore(self):
        proxy = self.bin / 'dwmapi.dll'
        proxy.write_bytes(b'old proxy')
        self.run_action('Install', ok=False)
        self.assertEqual(proxy.read_bytes(), b'old proxy')
        self.run_action('Install', replace=True)
        self.run_action('Uninstall')
        self.assertEqual(proxy.read_bytes(), b'old proxy')

    def test_build_checksum_and_legacy_refusals(self):
        exe = self.bin / 'DQIandIIHD2DRemake.exe'
        original = exe.read_bytes()
        exe.write_bytes(b'unknown version')
        self.run_action('Install', ok=False)
        exe.write_bytes(original)
        legacy = self.bin / 'UE4SS.dll'
        legacy.write_bytes(b'old runtime')
        self.run_action('Install', ok=False, replace=True)
        legacy.unlink()
        (self.package / 'payload/ue4ss/UE4SS.dll').write_bytes(b'corrupt')
        self.run_action('Install', ok=False)
        self.assertFalse((self.bin / 'dwmapi.dll').exists())

    def test_edited_file_refuses_all_uninstall_mutations(self):
        self.run_action('Install')
        changed = self.bin / PATHS[-1]
        changed.write_bytes(b'user edit')
        self.run_action('Uninstall', ok=False)
        self.assertEqual(changed.read_bytes(), b'user edit')
        self.assertTrue(all((self.bin / name).exists() for name in PATHS))

    def test_partial_write_failure_rolls_back(self):
        # Fixture-only fault injection after the first successful payload copy.
        script = self.script.read_text().replace('$written += $entry',
            "if ($written.Count -eq 1) { throw 'fixture write failure' }; $written += $entry")
        self.script.write_text(script)
        (self.bin / 'dwmapi.dll').write_bytes(b'old proxy')
        self.run_action('Install', ok=False, replace=True)
        self.assertEqual((self.bin / 'dwmapi.dll').read_bytes(), b'old proxy')
        self.assertFalse((self.bin / '.dqiandii-ue4ss-core/active.json').exists())

    def test_manifest_and_receipt_cannot_escape_root(self):
        manifest = self.package / 'manifest.json'
        valid = manifest.read_text()
        manifest.write_text(valid.replace('dwmapi.dll', '../escape.dll'))
        self.run_action('Install', ok=False)
        manifest.write_text(valid)
        self.run_action('Install')
        receipt = self.bin / '.dqiandii-ue4ss-core/active.json'
        receipt.write_text(receipt.read_text(encoding='utf-8-sig').replace('dwmapi.dll', '../escape.dll'))
        self.run_action('Uninstall', ok=False)
        self.assertTrue((self.bin / 'dwmapi.dll').exists())

if __name__ == '__main__':
    unittest.main()
