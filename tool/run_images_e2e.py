"""Opt-in Android E2E; private fixtures and all evidence stay outside Git."""

import argparse
import base64
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import threading
import time
import uuid
from pathlib import Path


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser()
    parser.add_argument("--image-a", type=Path, required=True)
    parser.add_argument("--image-b", type=Path, required=True)
    parser.add_argument("--uploads-dir", type=Path, required=True)
    parser.add_argument("--adb", default=shutil.which("adb"))
    parser.add_argument(
        "--ui", action="store_true", help="Capture the premium UI journey"
    )
    args = parser.parse_args()
    if not args.adb:
        sdk = os.environ.get("ANDROID_HOME")
        args.adb = str(Path(sdk) / "platform-tools/adb.exe") if sdk else None
    if not args.adb or not all(p.is_file() for p in (args.image_a, args.image_b)):
        parser.error(
            "Provide an available adb executable and two real PNG photographs."
        )
    root = Path(__file__).resolve().parents[1]
    out = root / ("build/ui-redesign" if args.ui else "build/persistent-images")
    out.mkdir(parents=True, exist_ok=True)
    uploads = args.uploads_dir.resolve()
    known = set(uploads.glob("*"))
    observed, deleted, screenshots = {}, set(), []
    result = None
    fixture_bytes = [args.image_a.read_bytes(), args.image_b.read_bytes()]
    device = "emulator-5554"
    package = "com.encuentrau.app"
    fixture_run = uuid.uuid4().hex
    marker = "cache/images_e2e/ready_" + fixture_run
    command = [
        shutil.which("flutter"),
        "test",
        "integration_test/persistent_images_test.dart",
        "-d",
        device,
        "--reporter",
        "expanded",
        "--timeout",
        "10m",
        "--dart-define=API_BASE_URL=http://10.0.2.2:8000",
        "--dart-define=E2E_IMAGE_A=/data/user/0/com.encuentrau.app/cache/images_e2e/front.png",
        "--dart-define=E2E_IMAGE_B=/data/user/0/com.encuentrau.app/cache/images_e2e/side.png",
        "--dart-define=E2E_FIXTURE_RUN=" + fixture_run,
        "--dart-define=E2E_PREMIUM_UI=" + str(args.ui).lower(),
    ]
    process = subprocess.Popen(
        command,
        cwd=root,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
        bufsize=1,
    )

    def logs():
        nonlocal result
        with (out / "android-e2e.log").open("w", encoding="utf-8") as log:
            for line in process.stdout:
                log.write(line)
                log.flush()
                if "IMAGE_E2E_" in line:
                    print(line.strip(), flush=True)
                if "IMAGE_E2E_RESULT " in line:
                    result = json.loads(line.split("IMAGE_E2E_RESULT ", 1)[1])
                if "IMAGE_E2E_SCREENSHOT " in line:
                    name = line.split("IMAGE_E2E_SCREENSHOT ", 1)[1].split()[0]
                    if not re.fullmatch(r"[A-Za-z0-9_]+", name):
                        raise RuntimeError("Invalid screenshot name")
                    data = subprocess.check_output(
                        [args.adb, "-s", device, "exec-out", "screencap", "-p"]
                    )
                    (out / (name + ".png")).write_bytes(data)
                    screenshots.append(name + ".png")

    reader = threading.Thread(target=logs)
    reader.start()
    next_fixture_check = 0
    while process.poll() is None:
        # flutter test owns installation/cleanup. Supply files after the package
        # exists, in its private debug cache; no shared-storage permission needed.
        if time.monotonic() >= next_fixture_check:
            next_fixture_check = time.monotonic() + 1
            present = subprocess.run(
                [
                    args.adb,
                    "-s",
                    device,
                    "shell",
                    "run-as",
                    package,
                    "test",
                    "-f",
                    marker,
                ],
                capture_output=True,
                check=False,
            )
            if present.returncode:
                ready = subprocess.run(
                    [
                        args.adb,
                        "-s",
                        device,
                        "shell",
                        "run-as",
                        package,
                        "mkdir",
                        "-p",
                        "cache/images_e2e",
                    ],
                    capture_output=True,
                    check=False,
                )
                if ready.returncode == 0:
                    for name, data in zip(
                        ["front.png", "side.png"], fixture_bytes, strict=True
                    ):
                        # ASCII transport avoids Windows adb stdin truncating binary
                        # data at Ctrl-Z. Decode only inside the device fixture cache.
                        encoded = "cache/images_e2e/" + name + ".b64"
                        temporary = "cache/images_e2e/" + name + ".tmp"
                        copied = subprocess.run(
                            [
                                args.adb,
                                "-s",
                                device,
                                "shell",
                                "-T",
                                "run-as",
                                package,
                                "tee",
                                encoded,
                            ],
                            input=base64.b64encode(data),
                            check=False,
                            stdout=subprocess.DEVNULL,
                            stderr=subprocess.PIPE,
                        )
                        if copied.returncode:
                            raise RuntimeError(
                                "Could not supply private device fixture"
                            )
                        subprocess.run(
                            [
                                args.adb,
                                "-s",
                                device,
                                "shell",
                                "run-as",
                                package,
                                "sh",
                                "-c",
                                "'base64 -d " + encoded + " > " + temporary + "'",
                            ],
                            check=True,
                            stdout=subprocess.DEVNULL,
                            stderr=subprocess.PIPE,
                        )
                        digest = (
                            subprocess.check_output(
                                [
                                    args.adb,
                                    "-s",
                                    device,
                                    "shell",
                                    "run-as",
                                    package,
                                    "sha256sum",
                                    temporary,
                                ]
                            )
                            .decode()
                            .split()[0]
                        )
                        if digest != hashlib.sha256(data).hexdigest():
                            raise RuntimeError(
                                "Device photograph failed integrity validation"
                            )
                        subprocess.run(
                            [
                                args.adb,
                                "-s",
                                device,
                                "shell",
                                "run-as",
                                package,
                                "mv",
                                temporary,
                                "cache/images_e2e/" + name,
                            ],
                            check=True,
                            stdout=subprocess.DEVNULL,
                            stderr=subprocess.PIPE,
                        )
                    subprocess.run(
                        [
                            args.adb,
                            "-s",
                            device,
                            "shell",
                            "run-as",
                            package,
                            "touch",
                            marker,
                        ],
                        check=True,
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.PIPE,
                    )
        current = set(uploads.glob("*"))
        for file in current - known:
            if file.suffix in {".jpg", ".png", ".webp"}:
                try:
                    observed[file] = hashlib.sha256(file.read_bytes()).hexdigest()
                except FileNotFoundError:
                    pass
        for file in known - current:
            if file in observed:
                deleted.add(observed[file])
        known = current
        time.sleep(0.1)
    reader.join()
    if process.returncode:
        print(
            "\n".join(
                (out / "android-e2e.log").read_text(encoding="utf-8").splitlines()[-65:]
            )
        )
        raise SystemExit(process.returncode)
    required = {
        "LOGIN.png",
        "HOME.png",
        "REPORTS.png",
        "REGISTER_AI.png",
        "MATCHES.png",
        "COMPARISON.png",
        "EVIDENCE.png",
        "PROFILE.png",
    }
    captures_valid = (
        required.issubset(screenshots) if args.ui else len(screenshots) == 3
    )
    if (
        not result
        or not result["passed"]
        or result["old_sha256"] not in deleted
        or not captures_valid
    ):
        raise RuntimeError(
            "Missing E2E result, physical-file replacement or screenshots"
        )
    result.update(
        {"previous_file_removed": True, "screenshots": screenshots, "device": device}
    )
    (out / "e2e-result.json").write_text(
        json.dumps(result, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    print(
        json.dumps(
            {
                "e2e": "passed",
                "previous_file_removed": True,
                "screenshots": len(screenshots),
            }
        )
    )


if __name__ == "__main__":
    main()
