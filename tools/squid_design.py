"""The Squid (Epic, Ocean, medium): QM's Kraken model (designs/ocean/Kraken.bbmodel)
with its animations, recoloured pink and orange. Only the colour textures change,
and the run (QM, Oct 2): instead of the Kraken's tentacle sweep the Squid swims like a
real one. It lifts off the floor and leans in, its tentacles hang together in a
bundle streaming back behind it, and every so often they flare out and snap shut
to jet it forward.

Run: python3 tools/squid_design.py [out_dir]
Writes designs/ocean/Squid.bbmodel, a preview and the Pets headshot assets/ui/PetSquid.png.
"""

import copy
import json
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import snake_design as S  # noqa: E402
from partlib import render  # noqa: E402
from horse_rig import write_animations  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
SRC = os.path.join(ROOT, "designs", "ocean", "Kraken.bbmodel")
MODEL = os.path.join(ROOT, "designs", "ocean", "Squid.bbmodel")

# the Kraken's textures by name -> the Squid's colours (eye white and pupil stay)
COLORS = {"navy": (255, 150, 160), "band": (236, 112, 132), "cap": (255, 138, 72),
          "capdark": (226, 100, 50), "pink": (255, 214, 120)}


def glide(m):
    """The run: a jet-propelled glide (positions in Blockbench units, 0.1 stud)."""
    import math
    from snake_rig import track
    from kraken_rig import arms
    TAU = 2 * math.pi
    L = 1.2
    rest = {g["name"]: (g.get("rotation") or (0, 0, 0))[0] for g in m["groups"]}

    def stroke(u):
        """0 bundled and streaming, 1 flared out: opens slowly, snaps shut fast."""
        if u < 0.35:
            return math.sin(math.pi / 2 * u / 0.35) ** 2
        if u < 0.5:
            return math.cos(math.pi / 2 * (u - 0.35) / 0.15) ** 2
        return 0.0

    def surge(u):
        """The jet's kick, peaking just after the tentacles snap shut, easing off in the glide."""
        d = (u - 0.45) % 1.0
        return math.exp(-d * 5) * min(1.0, d / 0.06)

    def arm(i, yaw, j, u):
        f = stroke(u)
        if j < 0:  # gather in toward the back while bundled
            return (0, 0, 0)
        name = f"T{i + 1}{'abcd'[j]}"
        r = rest[name]
        straight = (-90 - r) if j == 0 else -r  # each tentacle hanging straight down from the funnel
        ripple = (0, 3, 6, 9)[j] * math.sin(TAU * u * 2 - 1.1 * j) * (1 - f)
        flare = ((-90 - r) * 0.25, -r * 0.6, -r * 0.4, 6.0)[j]  # flared: well out from the bundle, tips curling
        return (straight * (1 - f) + flare * f + ripple, 0, 0)

    anim = {**arms(m, L, arm, 24),
            "root": [track(L, lambda u: (-16 - 6 * surge(u) + 4 * stroke(u), 0, 0), 24),
                     track(L, lambda u: (0, 95 + 14 * surge(u) - 10 * stroke(u), -12 * surge(u)), 24, "position")],
            "neck": [track(L, lambda u: (-34 + 16 * stroke(u), 0, 0), 24)]}
    tmp = {"animations": []}
    groups = {g["name"]: g for g in m["groups"]}
    write_animations(tmp, groups, {"gallop": (L, anim)})
    m["animations"] = [a for a in m["animations"] if a["name"] != "gallop"] + tmp["animations"]


def build():
    m = copy.deepcopy(json.load(open(SRC)))
    m["name"] = "Squid"
    for t in m["textures"]:
        if t["name"] in COLORS:
            new = S.solid_texture(t["name"], COLORS[t["name"]])
            t["source"] = new["source"]
    glide(m)
    return m


def main(out="/mnt/project-files/animals/ocean"):
    m = build()
    for path in (MODEL, os.path.join(out, "Squid.bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    parts = S.posed(m)
    W, H = 480, 440
    cams = [dict(eye=(0, 12, -42), target=(0, 10, 0)), dict(eye=(-32, 26, -30), target=(0, 10, 0))]
    sheet = Image.new("RGB", (W * 2, H))
    for i, cam in enumerate(cams):
        sheet.paste(render(parts, W=W, H=H, fov=44, **cam), (i * W, 0))
    sheet.save(os.path.join(out, "Squid.png"))
    import refine_designs as R
    R.HEAD_KEYS = R.HEAD_KEYS + ("cap",)
    R.headshot("Squid", MODEL)
    path = os.path.join(ROOT, "assets", "ui", "PetSquid.png")
    im = Image.open(path)
    im = im.crop(im.getbbox())
    s = max(im.size) + 24
    pad = Image.new("RGBA", (s, s))
    pad.paste(im, ((s - im.width) // 2, (s - im.height) // 2))
    pad.resize((512, 512), Image.LANCZOS).save(path)


if __name__ == "__main__":
    main(*sys.argv[1:])
