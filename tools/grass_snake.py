"""Grass Snake prop: QM's Snake recoloured as a plain grass snake, coiled in its idle
round a gold podium column (QM's edit, Oct 4). Renders a still and the idle GIF.

Run: python3 tools/grass_snake.py [out_dir]

designs/props/GrassSnake.bbmodel is QM's file (QM added the Podium group, column and cap,
and turned the coil in the idle). build() made the first recolour from
designs/desert/Snake.bbmodel; `python3 tools/grass_snake.py rebuild` would overwrite
QM's file with it, so don't. Convert it for the game with
  python3 tools/bbmodel_to_luau.py designs/props/GrassSnake.bbmodel src/shared/Props/GrassSnakeModel.luau
"""

import base64
import io
import json
import os
import sys
import uuid

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from partlib import render  # noqa: E402
import animal_designs as A  # noqa: E402
from snake_design import posed  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
SRC = os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")
OUT = os.path.join(ROOT, "designs", "props", "GrassSnake.bbmodel")

# Snake texture name -> (new name, colour)
RECOLOUR = {
    "gold": ("green", (104, 186, 64)),
    "cream": ("belly", (240, 236, 168)),
    "maroon": ("band", (52, 110, 44)),
    "teal": ("darkgreen", (70, 140, 52)),
    "tan": ("tailgreen", (88, 160, 58)),
}
COLLAR = ("collar", (255, 214, 64))
BLACK = ("black", (40, 44, 40))


def solid(rgb):
    buf = io.BytesIO()
    Image.new("RGBA", (16, 16), rgb + (255,)).save(buf, "PNG")
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()


def build():
    m = json.load(open(SRC))
    m["name"] = "GrassSnake"
    for t in m["textures"]:
        if t["name"] in RECOLOUR:
            t["name"], rgb = RECOLOUR[t["name"]]
            t["source"] = solid(rgb)
            t.pop("relative_path", None)
            t.pop("path", None)
    for name, rgb in (COLLAR, BLACK):
        t = dict(m["textures"][1], name=name, uuid=str(uuid.uuid4()), source=solid(rgb))
        t.pop("relative_path", None)
        t.pop("path", None)
        m["textures"].append(t)
    ids = {t["name"]: i for i, t in enumerate(m["textures"])}
    for e in m["elements"]:
        tex = {"Neck3": ids["collar"], "Neck2": ids["black"]}.get(e["name"])
        if tex is not None:
            for f in e["faces"].values():
                if f.get("texture") is not None:
                    f["texture"] = tex
    m["animations"] = [a for a in m["animations"] if a["name"] == "idle"]
    return m


def main(out="/mnt/project-files/animals/grass_snake"):
    if out == "rebuild":
        with open(OUT, "w") as f:
            json.dump(build(), f, separators=(",", ":"))
        return
    m = json.load(open(OUT))
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, "GrassSnake.bbmodel"), "w") as f:
        json.dump(m, f, separators=(",", ":"))
    cams = [dict(eye=(-40, 28, -30), target=(0, 3, 8)), dict(eye=(0, 80, 7), target=(0, 0, 7.5))]
    W, H = 480, 440
    idle = m["animations"][0]
    still = Image.new("RGB", (W * 2, H))
    for c, cam in enumerate(cams):
        still.paste(render(posed(m, idle, idle["length"] * 0.25), W=W, H=H, fov=40, outline=False, **cam), (c * W, 0))
    A.label(still, ["grass snake podium (idle)", "from above"]).save(os.path.join(out, "GrassSnake.png"))
    frames = []
    n = 24
    for _ in range(2):
        for i in range(n):
            im = Image.new("RGB", (W * 2, H))
            for c, cam in enumerate(cams):
                im.paste(render(posed(m, idle, idle["length"] * i / n), W=W, H=H, fov=40, outline=False, **cam), (c * W, 0))
            frames.append(A.label(im, ["idle", "from above"]))
    A.gif(os.path.join(out, "GrassSnake_idle.gif"), frames, fps=20)
    print("wrote", out)


if __name__ == "__main__":
    main(*sys.argv[1:])
