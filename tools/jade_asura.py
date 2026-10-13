"""The Jade Asura: World 2 Temple's boss (QM, Oct 13: "take our asura and give it tusks and
make it look 10x cooler and more intimidating and jade color scheme"). The Asura
(designs/crimson/Asura.bbmodel, tools/asura.py), same bones, pose and animations, in deep
jade and light jade armour with gold trim and adds:
- two big ivory boar tusks curling forward and up out of its jaw
- two huge dark jade demon horns with gold tips sweeping up and back off the helm, and a
  gold crown of spikes with a glowing jade gem on the front
- glowing gold eyes
- gold spikes on both shoulder pads
- a gold chest plate with a glowing jade gem
- a ring of gold behind its back with glowing jade flames round it (an aureole)
- a pale jade blade
New parts ride the bone they sit on (tusks, horns and crown on neck; spikes on the shoulders;
the chest gem and aureole on body); none of them get bones of their own.

Run: python3 tools/jade_asura.py [out_dir] [--gif]
Writes designs/bosses/JadeAsura.bbmodel and renders to /mnt/project-files/animals/bosses/.
"""

import json
import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import horse_rig as HR  # noqa: E402

HR.EULER = "ZYX"  # Blockbench's own order
import snake_design as S  # noqa: E402
import angel_boss as AB  # noqa: E402
from ivory_spider import iter_nodes  # noqa: E402
from partlib import render  # noqa: E402
import animal_designs as A  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
BASE = os.path.join(ROOT, "designs", "crimson", "Asura.bbmodel")
NAME = "JadeAsura"
MODEL = os.path.join(ROOT, "designs", "bosses", NAME + ".bbmodel")

# the Asura's colours (tools/asura.py PALETTE, same order) recoloured, then the new ones
RECOLOR = {"slate": (22, 128, 92), "dark": (10, 78, 58), "light": (120, 214, 170), "steel": (220, 160, 30),
           "cyan": (96, 226, 168), "blade": (196, 255, 226), "black": (6, 22, 16), "red": (255, 214, 60)}
NEW = {"ivory": (250, 242, 214), "gold": (255, 196, 40), "deepgold": (214, 140, 20), "horn": (8, 60, 44),
       "glow": (60, 255, 170)}


def direction(d):
    d = np.array(d, float)
    return d / np.linalg.norm(d)


def frame(d):
    """Rotation whose local Y is d (local X kept as level as it can be)."""
    y = direction(d)
    ref = np.array([0, 0, 1.0]) if abs(y[2]) < 0.9 else np.array([1.0, 0, 0])
    x = np.cross(y, ref)
    x /= np.linalg.norm(x)
    z = np.cross(x, y)
    return np.column_stack([x, y, z])


def curve(name, start, steps, tex, tip_tex=None):
    """A chain of boxes (studs): steps = [(direction, length, width)], each starting where
    the last one ended; the last box takes tip_tex."""
    p = np.array(start, float)
    out = []
    for i, (d, L, w) in enumerate(steps):
        d = direction(d)
        t = tip_tex if (tip_tex is not None and i == len(steps) - 1) else tex
        out.append(AB.box(f"{name}{i + 1}", p + d * L / 2, (w, L + w * 0.3, w), t, frame(d)))
        p = p + d * L
    return out


def build():
    m = json.load(open(BASE))
    names = [t["name"] for t in m["textures"]]
    m["textures"] = [S.solid_texture(n, RECOLOR[n]) for n in names] + [S.solid_texture(n, c) for n, c in NEW.items()]
    T = {n: i for i, n in enumerate(names + list(NEW))}
    for e in m["elements"]:
        if e["name"].startswith("GlowEye"):
            pass  # red -> glowing gold via RECOLOR
    groups = {g["uuid"]: g["name"] for g in m["groups"]}
    nodes = {groups[n["uuid"]]: n for n in iter_nodes(m["outliner"])}

    def put(bone, parts):
        for e in parts:
            m["elements"].append(e)
            nodes[bone]["children"].append(e["uuid"])

    # tusks: out of the jaw's corners, down and forward, then curling up past the visor
    for s, side in ((-1, "L"), (1, "R")):
        put("neck", curve(f"Tusk{side}", (s * 0.5, 6.95, -0.3),
                          [((s * 0.5, -0.5, -1), 0.55, 0.42), ((s * 0.45, 0.1, -1), 0.5, 0.36),
                           ((s * 0.35, 0.8, -0.8), 0.5, 0.3), ((s * 0.15, 1, -0.2), 0.45, 0.22),
                           ((0, 1, 0.3), 0.3, 0.14)], T["ivory"]))
        # demon horns off the helm's sides: out, then up, then back
        put("neck", curve(f"Horn{side}", (s * 0.7, 8.45, 0.35),
                          [((s * 1, 0.25, 0.1), 0.8, 0.62), ((s * 0.8, 0.8, 0.25), 0.8, 0.52),
                           ((s * 0.25, 1, 0.45), 0.9, 0.42), ((0, 1, 0.8), 0.8, 0.3),
                           ((-s * 0.1, 0.4, 1), 0.6, 0.2)], T["horn"], T["gold"]))
    # a gold crown of spikes round the helm, a glowing gem on its front
    crown = [AB.box("CrownBand", (0, 8.75, 0.55), (1.6, 0.3, 1.7), T["gold"])]
    for i, (x, h) in enumerate(((-0.5, 0.6), (0, 1.1), (0.5, 0.6))):
        crown += curve(f"Crown{i + 1}_", (x, 8.85, -0.28), [((x * 0.4, 1, 0), h * 0.6, 0.36), ((x * 0.4, 1, 0), h * 0.4, 0.18)],
                       T["gold"])
    crown.append(AB.box("GlowCrownGem", (0, 8.8, -0.33), (0.3, 0.3, 0.12), T["glow"], AB.axis_rot("z", 45)))
    put("neck", crown)

    # gold spikes on the shoulder pads (in the pads' own rest frame: their bones turn them)
    for s, side in ((-1, "left"), (1, "right")):
        spikes = []
        for i, (z, h) in enumerate(((-0.05, 0.7), (0.65, 1.0), (1.35, 0.7))):
            spikes += curve(f"Spike{side}{i + 1}_", (s * 1.6, 7.39, z),
                            [((s * 0.35, 1, 0), h * 0.6, 0.4), ((s * 0.5, 1, 0), h * 0.4, 0.2)], T["deepgold"], T["gold"])
        put(side + "_shoulder", spikes)

    # chest: a gold plate with a glowing jade gem
    put("body", [AB.box("ChestPlate", (0, 6.25, -0.2), (1.2, 1.2, 0.12), T["gold"], AB.axis_rot("z", 45)),
                 AB.box("GlowChestGem", (0, 6.25, -0.27), (0.6, 0.6, 0.1), T["glow"], AB.axis_rot("z", 45))])

    # the aureole: a gold ring behind its back with glowing flames round it
    c, R, n = np.array([0, 6.4, 1.75]), 3.0, 18
    ring = []
    for k in range(n):
        th = 2 * math.pi * k / n
        r = np.array([math.sin(th), math.cos(th), 0])
        t = np.array([math.cos(th), -math.sin(th), 0])
        M = np.column_stack([t, r, [0, 0, 1.0]])
        ring.append(AB.box(f"Aureole{k + 1}", c + R * r, (2 * math.pi * R / n * 1.1, 0.32, 0.18), T["gold"], M))
        L = 0.9 if k % 2 == 0 else 0.55
        ring.append(AB.box(f"GlowFlame{k + 1}", c + (R + 0.16 + L / 2) * r, (0.3, L, 0.14), T["glow"], M))
    put("body", ring)
    m["name"] = NAME
    return m


CAMS = [dict(eye=(-12, 9, -18), target=(0, 6, 0)), dict(eye=(0, 8, -16), target=(0, 7, 0)),
        dict(eye=(14, 10, 16), target=(0, 6, 0)), dict(eye=(-4, 8.6, -5.5), target=(0, 7.8, 0))]


def posed(m, anim=None, t=0.0):
    ps = S.posed(m, anim, t) if anim else S.posed(m)
    for p in ps:
        p.neon = p.name.startswith("Glow")
    return ps


def main(out="/mnt/project-files/animals/bosses"):
    os.makedirs(out, exist_ok=True)
    m = build()
    for path in (MODEL, os.path.join(out, NAME + ".bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    print("elements", len(m["elements"]))
    W, H = 600, 600
    parts = posed(m)
    sheet = Image.new("RGB", (W * 2, H * 2))
    for i, cam in enumerate(CAMS):
        sheet.paste(render(parts, W=W, H=H, fov=40, **cam), ((i % 2) * W, (i // 2) * H))
    sheet.save(os.path.join(out, NAME + ".png"))
    if "--gif" in sys.argv:
        frames = []
        for name, k, loops in (("idle", 24, 1), ("walk", 20, 2), ("gallop", 12, 3)):
            anim = next(a for a in m["animations"] if a["name"] == name)
            for _ in range(loops):
                for i in range(k):
                    ps = posed(m, anim, anim["length"] * i / k)
                    im = Image.new("RGB", (W * 2, H))
                    for c in (0, 2):
                        im.paste(render(ps, W=W, H=H, fov=40, **CAMS[c]), ((c // 2) * W, 0))
                    frames.append(A.label(im, ["run" if name == "gallop" else name] * 2))
        A.gif(os.path.join(out, NAME + "_anims.gif"), frames, fps=20)


if __name__ == "__main__":
    main(*[a for a in sys.argv[1:] if not a.startswith("--")])
