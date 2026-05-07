#!/usr/bin/env python3
"""Generate, master, and install the Lumen sound kit via SunoAPI.

Requires SUNOAPI_KEY in the environment. The key is only used in an
Authorization header and is never written to disk.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any, Optional


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "Design" / "sound-kit" / "source-files"
DESIGN_ALARMS = ROOT / "Design" / "sound-kit" / "alarms"
DESIGN_BREATHING = ROOT / "Design" / "sound-kit" / "breathing"
APP_ALARMS = ROOT / "Apple" / "lumen" / "Shared" / "Resources" / "Sounds" / "Alarm"
APP_BREATHING = ROOT / "Apple" / "lumen" / "Shared" / "Resources" / "Sounds" / "Breathing"
MANIFEST = ROOT / "Apple" / "lumen" / "Shared" / "Resources" / "Sounds" / "Sounds.json"
API_BASE = "https://api.sunoapi.org/api/v1"


ASSETS: list[dict[str, Any]] = [
    {
        "id": "alarm-aube",
        "kind": "alarm",
        "displayKey": "sound.alarm.aube",
        "duration": 30,
        "lufs": -16,
        "default": True,
        "ambiance": "aube",
        "tempo": 50,
        "key": "C",
        "prompt": "warm gentle morning piano arpeggio, C or G major, 50 bpm, subtle warm pad, no vocals, no drums, no hooks, soft sunrise, 30 s seamless loop.",
    },
    {
        "id": "breath-aube",
        "kind": "breathing",
        "displayKey": "sound.breathing.aube",
        "duration": 60,
        "lufs": -20,
        "default": True,
        "ambiance": "aube",
        "tempo": 60,
        "key": "C",
        "prompt": "very subtle extension of warm morning piano/pad ambience, 4 s rise and 4 s fall breathing swell, background only, 60 s, 2 s fade in/out.",
    },
    {
        "id": "alarm-bois",
        "kind": "alarm",
        "displayKey": "sound.alarm.bois",
        "duration": 30,
        "lufs": -16,
        "default": False,
        "ambiance": "bois",
        "tempo": None,
        "key": "Any",
        "prompt": "quiet northern forest morning, soft Tibetan bowl every 4-5 s, subtle wind, very distant wood creak, no loud birds, no melody, 30 s seamless loop.",
    },
    {
        "id": "breath-bois",
        "kind": "breathing",
        "displayKey": "sound.breathing.bois",
        "duration": 60,
        "lufs": -20,
        "default": False,
        "ambiance": "bois",
        "tempo": None,
        "key": "Any",
        "prompt": "quiet northern forest room tone, soft wind-level breathing swell, almost no birds, warm natural background, no melody, 60 s, 2 s fade in/out.",
    },
    {
        "id": "alarm-cloche",
        "kind": "alarm",
        "displayKey": "sound.alarm.cloche",
        "duration": 30,
        "lufs": -14,
        "default": False,
        "ambiance": "silence",
        "tempo": None,
        "key": "Any",
        "prompt": "single muted Tibetan bell every 6-8 s, natural short reverb, no background pad, no melody, no percussion, minimal meditation chime, 30 s.",
    },
    {
        "id": "breath-silence",
        "kind": "breathing",
        "displayKey": "sound.breathing.silence",
        "duration": 60,
        "lufs": -32,
        "default": False,
        "ambiance": "silence",
        "tempo": None,
        "key": "Any",
        "prompt": "warm near-silence room tone, very soft breath bell at 0 s and 58 s only, no music bed, no noise events, 60 s.",
    },
    {
        "id": "alarm-marée",
        "kind": "alarm",
        "displayKey": "sound.alarm.maree",
        "duration": 30,
        "lufs": -16,
        "default": False,
        "ambiance": None,
        "tempo": None,
        "key": "Any",
        "prompt": "distant slow ocean waves, low 80 Hz warm drone, gentle swell every 8 s, no melody, no percussion, hypnotic calm, 30 s seamless loop.",
    },
    {
        "id": "alarm-souffle",
        "kind": "alarm",
        "displayKey": "sound.alarm.souffle",
        "duration": 30,
        "lufs": -16,
        "default": False,
        "ambiance": None,
        "tempo": None,
        "key": "Any",
        "prompt": "warm analog low-pass drone, slow organic microtonal movement, breath-like swell, no attack, no beat, no vocals, 30 s seamless loop.",
    },
]


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    sys.exit(1)


def require_tools() -> None:
    missing = [
        name
        for name in ("ffmpeg", "ffprobe", "afconvert", "afinfo")
        if shutil.which(name) is None
    ]
    if missing:
        fail("missing required audio tools: " + ", ".join(missing))


def api_json(method: str, path: str, key: str, payload: Optional[dict[str, Any]] = None) -> dict[str, Any]:
    body = None if payload is None else json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(
        API_BASE + path,
        data=body,
        method=method,
        headers={
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "LumenSoundKit/1.0",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=45) as response:
            data = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        detail = error.read().decode("utf-8", errors="replace")
        fail(f"SunoAPI HTTP {error.code} for {path}: {detail}")
    if data.get("code") != 200:
        fail(f"SunoAPI error for {path}: code={data.get('code')} msg={data.get('msg')}")
    return data


def remaining_credits(key: str) -> int:
    data = api_json("GET", "/generate/credit", key)
    return int(data["data"])


def create_task(asset: dict[str, Any], key: str) -> str:
    payload = {
        "prompt": asset["prompt"],
        "model": "V5",
        "soundLoop": asset["kind"] == "alarm",
        "soundKey": asset.get("key") or "Any",
        "grabLyrics": False,
    }
    if asset.get("tempo"):
        payload["soundTempo"] = asset["tempo"]
    data = api_json("POST", "/generate/sounds", key, payload)
    return str(data["data"]["taskId"])


def record_info(task_id: str, key: str) -> dict[str, Any]:
    query = urllib.parse.urlencode({"taskId": task_id})
    return api_json("GET", f"/generate/record-info?{query}", key)["data"]


def wait_for_task(task_id: str, key: str, timeout_seconds: int = 900) -> dict[str, Any]:
    deadline = time.time() + timeout_seconds
    while time.time() < deadline:
        info = record_info(task_id, key)
        status = info.get("status")
        if status == "SUCCESS":
            return info
        if status in {"CREATE_TASK_FAILED", "GENERATE_AUDIO_FAILED", "CALLBACK_EXCEPTION", "SENSITIVE_WORD_ERROR"}:
            fail(f"Suno task {task_id} failed with status {status}: {info.get('errorMessage')}")
        time.sleep(20)
    fail(f"timed out waiting for Suno task {task_id}")


def candidate_urls(info: dict[str, Any]) -> list[str]:
    response = info.get("response") or {}
    suno_data = response.get("sunoData") or []
    urls = []
    for item in suno_data:
        url = item.get("audioUrl") or item.get("streamAudioUrl")
        if url:
            urls.append(str(url))
    return urls


def download(url: str, destination: Path) -> None:
    request = urllib.request.Request(url, headers={"User-Agent": "LumenSoundKit/1.0"})
    with urllib.request.urlopen(request, timeout=180) as response:
        destination.write_bytes(response.read())


def run(command: list[str]) -> None:
    subprocess.run(command, cwd=ROOT, check=True)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def final_paths(asset: dict[str, Any]) -> tuple[Path, Path]:
    extension = "caf" if asset["kind"] == "alarm" else "m4a"
    design_destination = (DESIGN_ALARMS if asset["kind"] == "alarm" else DESIGN_BREATHING) / f"{asset['id']}.{extension}"
    app_destination = (APP_ALARMS if asset["kind"] == "alarm" else APP_BREATHING) / f"{asset['id']}.{extension}"
    return design_destination, app_destination


def master(asset: dict[str, Any], source: Path) -> Path:
    asset_id = asset["id"]
    duration = str(asset["duration"])
    target = asset["lufs"]
    channels = "1" if asset["kind"] == "alarm" else "2"
    channel_layout = "mono" if asset["kind"] == "alarm" else "stereo"
    wav = SOURCE_DIR / f"{asset_id}-master.wav"
    design_destination, app_destination = final_paths(asset)

    filters = [
        f"aformat=sample_rates=44100:channel_layouts={channel_layout}",
        f"loudnorm=I={target}:TP=-1.5:LRA=7",
        f"apad,atrim=0:{duration}",
    ]
    if asset["kind"] == "breathing":
        filters.append(f"afade=t=in:st=0:d=2,afade=t=out:st={asset['duration'] - 2}:d=2")

    run([
        "ffmpeg",
        "-y",
        "-i",
        str(source),
        "-vn",
        "-af",
        ",".join(filters),
        "-ar",
        "44100",
        "-ac",
        channels,
        "-c:a",
        "pcm_s16le",
        str(wav),
    ])
    if asset["kind"] == "alarm":
        run(["afconvert", "-f", "caff", "-d", "LEI16@44100", str(wav), str(design_destination)])
    else:
        run([
            "ffmpeg",
            "-y",
            "-i",
            str(wav),
            "-vn",
            "-ar",
            "44100",
            "-ac",
            "2",
            "-c:a",
            "aac",
            "-b:a",
            "128k",
            str(design_destination),
        ])
    shutil.copy2(design_destination, app_destination)
    return design_destination


def write_manifest() -> None:
    sounds = []
    for asset in ASSETS:
        extension = "caf" if asset["kind"] == "alarm" else "m4a"
        sounds.append({
            "id": asset["id"],
            "displayKey": asset["displayKey"],
            "kind": asset["kind"],
            "filename": f"{asset['id']}.{extension}",
            "durationSeconds": asset["duration"],
            "lufsTarget": asset["lufs"],
            "isDefault": asset["default"],
            "ambiance": asset["ambiance"],
        })
    MANIFEST.write_text(json.dumps({"sounds": sounds}, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--one-candidate", action="store_true", help="Force one generation task per asset.")
    parser.add_argument("--dry-run", action="store_true", help="Write manifest and print planned prompts only.")
    parser.add_argument("--regenerate-existing", action="store_true", help="Regenerate assets even when final files already exist.")
    args = parser.parse_args()

    for directory in (SOURCE_DIR, DESIGN_ALARMS, DESIGN_BREATHING, APP_ALARMS, APP_BREATHING):
        directory.mkdir(parents=True, exist_ok=True)
    write_manifest()

    if args.dry_run:
        for asset in ASSETS:
            print(f"{asset['id']}: {asset['prompt']}")
        return

    key = os.environ.get("SUNOAPI_KEY")
    if not key:
        fail("SUNOAPI_KEY is not set")
    require_tools()

    assets_to_generate = []
    for asset in ASSETS:
        final_path, app_path = final_paths(asset)
        if args.regenerate_existing or not (final_path.exists() and app_path.exists()):
            assets_to_generate.append(asset)

    credits = remaining_credits(key)
    if credits < len(assets_to_generate):
        fail(f"remaining credits ({credits}) cannot cover the minimum {len(assets_to_generate)} generation tasks")
    candidates_per_asset = 1 if args.one_candidate or credits < len(assets_to_generate) * 2 else 2
    print(f"credits={credits}; candidates_per_asset={candidates_per_asset}")

    run_metadata: dict[str, Any] = {
        "generatedAt": dt.datetime.now(dt.timezone.utc).isoformat(),
        "provider": "SunoAPI",
        "model": "V5",
        "commercialUseAssumption": "Approved by account owner/user confirmation.",
        "candidateCountPerAsset": candidates_per_asset,
        "resumePolicy": "Existing final files are reused unless --regenerate-existing is passed.",
        "assets": [],
    }

    for asset in ASSETS:
        final_path, app_path = final_paths(asset)
        asset_meta = {
            "id": asset["id"],
            "prompt": asset["prompt"],
            "tasks": [],
            "selectedCandidate": None,
            "sourceUrl": None,
            "sourceSha256": None,
            "finalSha256": None,
        }
        if not args.regenerate_existing and final_path.exists() and app_path.exists():
            asset_meta["reusedExistingFinal"] = True
            asset_meta["finalFile"] = str(final_path.relative_to(ROOT))
            asset_meta["appFile"] = str(app_path.relative_to(ROOT))
            asset_meta["finalSha256"] = sha256(final_path)
            asset_meta["appSha256"] = sha256(app_path)
            asset_meta["provenanceNote"] = "Final file existed before this run; task IDs may be in a previous interrupted run."
            run_metadata["assets"].append(asset_meta)
            print(f"reused {asset['id']}")
            continue
        selected_source: Optional[Path] = None
        for index in range(candidates_per_asset):
            task_id = create_task(asset, key)
            info = wait_for_task(task_id, key)
            urls = candidate_urls(info)
            if not urls:
                fail(f"task {task_id} returned no audio URL")
            source_url = urls[0]
            suffix = Path(urllib.parse.urlparse(source_url).path).suffix or ".mp3"
            source_path = SOURCE_DIR / f"{asset['id']}-candidate-{index + 1}{suffix}"
            download(source_url, source_path)
            task_meta = {
                "taskId": task_id,
                "candidateIndex": index + 1,
                "sourceUrl": source_url,
                "sourceFile": str(source_path.relative_to(ROOT)),
                "sourceSha256": sha256(source_path),
                "recordInfo": info,
            }
            asset_meta["tasks"].append(task_meta)
            if selected_source is None:
                selected_source = source_path
                asset_meta["selectedCandidate"] = index + 1
                asset_meta["sourceUrl"] = source_url
                asset_meta["sourceSha256"] = task_meta["sourceSha256"]
        if selected_source is None:
            fail(f"no source candidate selected for {asset['id']}")
        final_path = master(asset, selected_source)
        asset_meta["finalFile"] = str(final_path.relative_to(ROOT))
        asset_meta["finalSha256"] = sha256(final_path)
        _, app_path = final_paths(asset)
        asset_meta["appFile"] = str(app_path.relative_to(ROOT))
        asset_meta["appSha256"] = sha256(app_path)
        run_metadata["assets"].append(asset_meta)

    metadata_path = SOURCE_DIR / "sunoapi-generation-metadata.json"
    metadata_path.write_text(json.dumps(run_metadata, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {metadata_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
