"""Runs Luau in the open Roblox Studio through its MCP server (StudioMCP --stdio), for the
map editor's tools. Picks the Studio that has World 1's place open (126872244121414) unless
STUDIO=<id> says otherwise.

    from studio import run_luau
    text = run_luau(code, "Edit")
"""

import json
import os
import subprocess
import time

STUDIO_MCP = "/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP"
PLACE = "126872244121414"


CHUNK = 90000  # (execute_luau's answer is cut off at about 100,000 characters)


def run_luau(code, datamodel="Edit", place=PLACE, chunked=False):
    """The script's return value as text. chunked: the script defines OFFSET and CHUNK as
    globals (set above it here) and returns string.sub(all, OFFSET + 1, OFFSET + CHUNK) ..
    "\n" .. #all, so a long answer comes back in pieces, one call each."""
    p = subprocess.Popen([STUDIO_MCP, "--stdio"], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                         stderr=subprocess.DEVNULL, text=True)
    try:
        def send(m):
            p.stdin.write(json.dumps(m) + "\n")
            p.stdin.flush()

        def recv(i):
            while True:
                line = p.stdout.readline()
                if not line:
                    raise RuntimeError("Studio's MCP server closed (is Studio open?)")
                m = json.loads(line)
                if m.get("id") == i:
                    return m

        def call(i, name, args):
            send({"jsonrpc": "2.0", "id": i, "method": "tools/call", "params": {"name": name, "arguments": args}})
            r = recv(i)
            if "error" in r:
                raise RuntimeError(str(r["error"]))
            return "\n".join(c.get("text", "") for c in r.get("result", {}).get("content", []))

        send({"jsonrpc": "2.0", "id": 1, "method": "initialize",
              "params": {"protocolVersion": "2024-11-05", "capabilities": {}, "clientInfo": {"name": "mapeditor", "version": "1"}}})
        recv(1)
        send({"jsonrpc": "2.0", "method": "notifications/initialized"})
        time.sleep(4)  # (StudioMCP lists no Studios for a moment after starting)
        sid = os.environ.get("STUDIO")
        if not sid:
            studios = json.loads(call(2, "list_roblox_studios", {})).get("studios", [])
            match = [s for s in studios if place in s.get("name", "")]
            if not match:
                raise RuntimeError("World 1's place isn't open in Studio")
            sid = match[0]["id"]
        if not chunked:
            return call(3, "execute_luau", {"code": code, "datamodel_type": datamodel, "studio_id": sid})
        parts, offset, total, i = [], 0, None, 3
        while total is None or offset < total:
            head = "OFFSET, CHUNK = %d, %d\n" % (offset, CHUNK)
            out = call(i, "execute_luau", {"code": head + code, "datamodel_type": datamodel, "studio_id": sid})
            body, _, n = out.rpartition("\n")
            if not n.strip().isdigit():
                raise RuntimeError("Studio said: " + out[:500])
            total = int(n)
            parts.append(body)
            offset += CHUNK
            i += 1
        return "".join(parts)
    finally:
        p.kill()
