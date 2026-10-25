"""Deterministic VII Reimagined release; Python 3.10+, no third-party dependencies or network."""
import argparse
import hashlib
import json
from pathlib import Path
import zipfile

VERSION = '0.1.0'
RUNTIME = '3.0.1-1181-g83330635'
COMMIT = '8333063595fa3c49ad307f3b0f732accbb760d25'
ARCHIVE_SHA256 = '82378cd7f679d055026286f11347355ac67c712f21eb892060c902bb0184b907'
EXE_SHA256 = '83c568ca6de8d8429a1926b79d2b78b0175d7d6fecd304ecb2cf7b5b32a27404'
DLLS = {
    'dwmapi.dll': '93b9431a5a4f32c675d269c5da1c9b3ec6f88552ec20c282ab435f411e9271fb',
    'ue4ss/UE4SS.dll': 'ce5e3c46a920cc00b2817ac61e438c9162830290379d0b5b9c4dfc2b29459290',
}

def digest(data):
    return hashlib.sha256(data).hexdigest()

def text(path):
    return path.read_text(encoding='utf-8-sig').replace('\r\n', '\n').encode('utf-8')

def build(archive, output):
    root = Path(__file__).resolve().parent
    if digest(archive.read_bytes()) != ARCHIVE_SHA256:
        raise ValueError('Unexpected official runtime archive SHA-256')
    files = {}
    with zipfile.ZipFile(archive) as upstream:
        for name, expected in DLLS.items():
            data = upstream.read(name)
            if digest(data) != expected:
                raise ValueError(f'Unexpected runtime bytes: {name}')
            files['payload/' + name] = data
        files['payload/ue4ss/LICENSE'] = upstream.read('ue4ss/LICENSE')
    for source, target in {
        'profile/UE4SS-settings.ini': 'ue4ss/UE4SS-settings.ini',
        'profile/MemberVariableLayout.ini': 'ue4ss/MemberVariableLayout.ini',
        'profile/main.lua': 'ue4ss/Mods/DQVIIProbe/scripts/main.lua',
    }.items():
        files['payload/' + target] = text(root / source)
    files['payload/ue4ss/Mods/DQVIIProbe/enabled.txt'] = b''
    manifest = {
        'schema': 1, 'version': VERSION,
        'game': {'store': 'Steam', 'appid': 2499860, 'version': '1.1.1.0',
                 'buildid': '22412021', 'exe_sha256': EXE_SHA256},
        'runtime': {'version': RUNTIME, 'source_commit': COMMIT,
                    'archive_sha256': ARCHIVE_SHA256,
                    'url': 'https://github.com/UE4SS-RE/RE-UE4SS/releases/download/experimental-latest/zDEV-UE4SS_v' + RUNTIME + '.zip'},
        'files': [{'path': name.removeprefix('payload/'), 'sha256': digest(data)}
                  for name, data in sorted(files.items())],
    }
    files['manifest.json'] = (json.dumps(manifest, indent=2) + '\n').encode()
    for name in ['README.md', 'VALIDATION.md', 'LICENSE', 'Manage-DQVII.ps1', 'RELEASE-NOTES.md']:
        files[name] = text(root / name)
    # Include the exact compatibility sources and optional QA, never game data or private logs.
    for path in sorted(root.rglob('*')):
        if path.is_file() and '__pycache__' not in path.parts:
            if path.suffix in {'.py', '.ps1', '.md', '.lua', '.ini', '.txt'} or path.name in {'LICENSE', '.gitattributes'}:
                files['SOURCE/' + path.relative_to(root).as_posix()] = text(path)
    files['SHA256SUMS.txt'] = ''.join(f'{digest(data)}  {name}\n' for name, data in sorted(files.items())).encode()
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as release:
        for name, data in sorted(files.items()):
            info = zipfile.ZipInfo(name, date_time=(2026, 10, 25, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            release.writestr(info, data, compresslevel=9)
    sums = output.with_suffix('.sha256')
    sums.write_text(f'{digest(output.read_bytes())}  {output.name}\n', encoding='ascii', newline='\n')
    print(json.dumps({'zip': str(output), 'sha256': digest(output.read_bytes()), 'files': len(files)}))

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--runtime-archive', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    build(args.runtime_archive, args.output)
