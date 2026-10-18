"""Opt-in Android workflow against the real local API; never persists credentials."""

import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import re
import secrets
import shutil
import subprocess
import sys
import threading
import time
import urllib.request
import uuid


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    parser = argparse.ArgumentParser()
    parser.add_argument('--backend-root', type=Path, required=True)
    parser.add_argument('--image-a', type=Path, required=True)
    parser.add_argument('--image-b', type=Path, required=True)
    parser.add_argument('--adb', required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    out = root / 'build/claims-chat-e2e'
    out.mkdir(parents=True, exist_ok=True)
    for endpoint in ('health', 'health/database'):
        with urllib.request.urlopen('http://127.0.0.1:8000/' + endpoint) as response:
            if response.status != 200:
                raise RuntimeError('Local backend is not healthy')
    with urllib.request.urlopen('http://127.0.0.1:8000/openapi.json') as response:
        paths = json.load(response)['paths']
        if '/api/v1/admin/claims' not in paths:
            raise RuntimeError('Restart the existing backend to load the new workflow routes')
    run = uuid.uuid4().hex[:16]
    credentials = {'email': f'claims.admin.{run}@example.com', 'password': secrets.token_urlsafe(32), 'run': run}
    # Execute the same CLI entry point with private in-memory prompt adapters.
    # Production interactive invocation uses getpass; no public admin endpoint.
    provision = """
import json,sys
from app.cli.create_admin import main
value=json.load(sys.stdin)
answers=iter(['Revision Comunidad',value['email'],'ADMIN'+value['run']])
raise SystemExit(main(input_fn=lambda _:next(answers),password_fn=lambda _:value['password']))
"""
    result = subprocess.run([str(args.backend_root / '.venv/Scripts/python.exe'), '-c', provision],
                            cwd=args.backend_root, input=json.dumps(credentials), text=True,
                            capture_output=True, check=False)
    if result.returncode:
        raise RuntimeError('Secure admin CLI provisioning failed; credentials were not logged')
    device = ['-s', 'emulator-5554']
    package = 'com.encuentrau.app'
    folder = 'cache/claims_chat_e2e'
    marker = folder + '/ready_' + run
    payloads = {'front.png': args.image_a.read_bytes(), 'side.png': args.image_b.read_bytes(),
                'fixture.json': json.dumps(credentials).encode()}
    command = [shutil.which('flutter'), 'test', 'integration_test/claims_chat_test.dart',
               '-d', 'emulator-5554', '--reporter', 'expanded', '--timeout', '20m',
               '--dart-define=API_BASE_URL=http://10.0.2.2:8000',
               '--dart-define=E2E_CLAIMS_FIXTURE=/data/user/0/' + package + '/' + folder + '/fixture.json',
               '--dart-define=E2E_FIXTURE_RUN=' + run]
    process = subprocess.Popen(command, cwd=root, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                               text=True, encoding='utf-8', errors='replace', bufsize=1)
    final = None
    screenshots = []

    def logs():
        nonlocal final
        with (out / 'android-e2e.log').open('w', encoding='utf-8') as log:
            for line in process.stdout:
                log.write(line)
                log.flush()
                if 'CLAIMS_E2E_' in line:
                    # Only IDs, statuses and screenshot markers are emitted by the test.
                    print(line.strip(), flush=True)
                if 'CLAIMS_E2E_RESULT ' in line:
                    final = json.loads(line.split('CLAIMS_E2E_RESULT ', 1)[1])
                if 'CLAIMS_E2E_SCREENSHOT ' in line:
                    name = line.split('CLAIMS_E2E_SCREENSHOT ', 1)[1].split()[0]
                    if not re.fullmatch('[A-Z_]+', name):
                        raise RuntimeError('Invalid evidence filename')
                    data = subprocess.check_output([args.adb, *device, 'exec-out', 'screencap', '-p'])
                    (out / (name + '.png')).write_bytes(data)
                    screenshots.append(name)
                    subprocess.run([args.adb, *device, 'shell', 'run-as', package, 'touch', folder + '/captured_' + name], capture_output=True, check=True)

    reader = threading.Thread(target=logs)
    reader.start()
    while process.poll() is None:
        ready = subprocess.run([args.adb, *device, 'shell', 'run-as', package, 'test', '-f', marker], capture_output=True)
        if ready.returncode:
            available = subprocess.run([args.adb, *device, 'shell', 'run-as', package, 'mkdir', '-p', folder], capture_output=True)
            if available.returncode == 0:
                for name, data in payloads.items():
                    encoded, temporary, target = (folder + '/' + name + suffix for suffix in ('.b64', '.tmp', ''))
                    subprocess.run([args.adb, *device, 'shell', '-T', 'run-as', package, 'tee', encoded],
                                   input=base64.b64encode(data), stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, check=True)
                    subprocess.run([args.adb, *device, 'shell', 'run-as', package, 'sh', '-c',
                                    "'base64 -d " + encoded + ' > ' + temporary + "'"],
                                   stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, check=True)
                    digest = subprocess.check_output([args.adb, *device, 'shell', 'run-as', package, 'sha256sum', temporary]).decode().split()[0]
                    if digest != hashlib.sha256(data).hexdigest():
                        raise RuntimeError('Private fixture integrity check failed')
                    subprocess.run([args.adb, *device, 'shell', 'run-as', package, 'mv', temporary, target], capture_output=True, check=True)
                    subprocess.run([args.adb, *device, 'shell', 'run-as', package, 'rm', encoded], capture_output=True, check=True)
                subprocess.run([args.adb, *device, 'shell', 'run-as', package, 'touch', marker], capture_output=True, check=True)
        time.sleep(1)
    reader.join()
    # Remove any private credential fixture left by an interrupted test.
    subprocess.run([args.adb, *device, 'shell', 'run-as', package, 'rm', '-f', folder + '/fixture.json'], capture_output=True)
    if process.returncode:
        print('\n'.join((out / 'android-e2e.log').read_text(encoding='utf-8').splitlines()[-65:]))
        raise SystemExit(process.returncode)
    if not final or not final.get('passed') or len(screenshots) < 8:
        raise RuntimeError('Incomplete real E2E evidence')
    final.update(device='emulator-5554', screenshots=screenshots)
    (out / 'e2e-result.json').write_text(json.dumps(final, indent=2, ensure_ascii=False), encoding='utf-8')
    print(json.dumps({'e2e': 'passed', 'screenshots': len(screenshots)}))


if __name__ == '__main__':
    main()
