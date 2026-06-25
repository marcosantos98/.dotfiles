#!/usr/bin/env python3
import base64
import hashlib
import hashlib
import json
import secrets
import socket
import struct
import uuid
from pathlib import Path

CONFIG = Path.home() / ".config/obs-studio/plugin_config/obs-websocket/config.json"
SCENES_DIR = Path.home() / ".config/obs-studio/basic/scenes"
USER_INI = Path.home() / ".config/obs-studio/user.ini"


def load_ws_config():
    if not CONFIG.exists():
        return None
    data = json.loads(CONFIG.read_text())
    return {
        "host": "127.0.0.1",
        "port": int(data.get("server_port", 4455)),
        "password": data.get("server_password", ""),
    }


def scene_collection_file():
    if not USER_INI.exists():
        return SCENES_DIR / "Untitled.json"
    for line in USER_INI.read_text().splitlines():
        if line.startswith("SceneCollectionFile="):
            return SCENES_DIR / line.split("=", 1)[1].strip()
    return SCENES_DIR / "Untitled.json"


def scenes_from_file():
    path = scene_collection_file()
    if not path.exists():
        return [], None
    data = json.loads(path.read_text())
    scenes = [item["name"] for item in data.get("scene_order", []) if item.get("name")]
    current = data.get("current_program_scene") or data.get("current_scene")
    return scenes, current


def auth_string(password, salt, challenge):
    secret = base64.b64encode(
        hashlib.sha256((password + salt).encode()).digest()
    ).decode()
    return base64.b64encode(
        hashlib.sha256((secret + challenge).encode()).digest()
    ).decode()


def ws_connect(cfg):
    sock = socket.create_connection((cfg["host"], cfg["port"]), timeout=2)
    key = base64.b64encode(secrets.token_bytes(16)).decode()
    sock.send(
        (
            f"GET / HTTP/1.1\r\n"
            f"Host: {cfg['host']}:{cfg['port']}\r\n"
            "Upgrade: websocket\r\n"
            "Connection: Upgrade\r\n"
            f"Sec-WebSocket-Key: {key}\r\n"
            "Sec-WebSocket-Version: 13\r\n"
            "\r\n"
        ).encode()
    )
    buf = b""
    while b"\r\n\r\n" not in buf:
        chunk = sock.recv(4096)
        if not chunk:
            raise ConnectionError("OBS websocket handshake failed")
        buf += chunk
    return sock


def ws_send(sock, payload):
    data = json.dumps(payload).encode()
    mask = secrets.token_bytes(4)
    frame = bytearray([0x81])
    length = len(data)
    if length < 126:
        frame.append(0x80 | length)
    elif length < 65536:
        frame.extend([0x80 | 126, (length >> 8) & 0xFF, length & 0xFF])
    else:
        frame.extend([0x80 | 127] + [(length >> (8 * i)) & 0xFF for i in range(7, -1, -1)])
    frame.extend(mask)
    frame.extend(b ^ mask[i % 4] for i, b in enumerate(data))
    sock.send(frame)


def ws_recv(sock):
    header = sock.recv(2)
    if len(header) < 2:
        raise ConnectionError("OBS websocket closed")
    length = header[1] & 0x7F
    if length == 126:
        length = struct.unpack(">H", sock.recv(2))[0]
    elif length == 127:
        length = struct.unpack(">Q", sock.recv(8))[0]
    if header[1] & 0x80:
        sock.recv(4)
    payload = b""
    while len(payload) < length:
        chunk = sock.recv(length - len(payload))
        if not chunk:
            raise ConnectionError("OBS websocket truncated frame")
        payload += chunk
    return json.loads(payload.decode())


def obs_request(request_type, request_data=None):
    cfg = load_ws_config()
    if cfg is None:
        return None
    sock = ws_connect(cfg)
    try:
        hello = ws_recv(sock)
        identify = {"op": 1, "d": {"rpcVersion": 1}}
        auth = hello.get("d", {}).get("authentication")
        if auth:
            identify["d"]["authentication"] = auth_string(
                cfg["password"], auth["salt"], auth["challenge"]
            )
        ws_send(sock, identify)
        ws_recv(sock)
        req_id = str(uuid.uuid4())
        req = {"op": 6, "d": {"requestType": request_type, "requestId": req_id}}
        if request_data is not None:
            req["d"]["requestData"] = request_data
        ws_send(sock, req)
        while True:
            msg = ws_recv(sock)
            if msg.get("op") == 7 and msg.get("d", {}).get("requestId") == req_id:
                status = msg["d"].get("requestStatus", {})
                if not status.get("result"):
                    raise RuntimeError(status.get("comment", "OBS request failed"))
                return msg["d"].get("responseData")
    finally:
        sock.close()


def scenes_live():
    file_scenes, file_current = scenes_from_file()
    try:
        data = obs_request("GetSceneList")
        if data:
            current = data.get("currentProgramSceneName") or file_current
            ws_scenes = {s["sceneName"] for s in data.get("scenes", [])}
            scenes = [name for name in file_scenes if name in ws_scenes]
            for name in ws_scenes:
                if name not in scenes:
                    scenes.append(name)
            return scenes, current
    except (OSError, RuntimeError, json.JSONDecodeError, KeyError):
        pass
    return file_scenes, file_current


def switch_scene(name):
    try:
        obs_request("SetCurrentProgramScene", {"sceneName": name})
    except (OSError, RuntimeError, json.JSONDecodeError, KeyError) as err:
        raise RuntimeError(
            "Could not switch scene — restart OBS after enabling WebSocket in Tools → WebSocket Server Settings"
        ) from err


def sync_scenes():
    scenes_path = Path("/tmp/obs-waybar-scenes.list")
    current_path = Path("/tmp/obs-waybar-current.scene")
    hash_path = Path("/tmp/obs-waybar-scenes.hash")
    scenes, current = scenes_live()
    digest = hashlib.md5(f"{'|'.join(scenes)}|{current or ''}".encode()).hexdigest()
    if hash_path.exists() and hash_path.read_text().strip() == digest:
        return
    scenes_path.write_text("\n".join(scenes) + ("\n" if scenes else ""))
    current_path.write_text(current or "")
    hash_path.write_text(digest)


def main():
    import sys

    if len(sys.argv) < 2:
        return
    cmd = sys.argv[1]
    if cmd == "list":
        scenes, current = scenes_live()
        print(json.dumps({"scenes": scenes, "current": current}))
    elif cmd == "switch" and len(sys.argv) >= 3:
        switch_scene(sys.argv[2])
    elif cmd == "sync-scenes":
        sync_scenes()


if __name__ == "__main__":
    main()
