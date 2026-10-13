"""The Black Widow: a giant boss (QM, Oct 13: "an insanely complex/cool spider, based on the
ivory spider model, a traditional black widow; armour/runes if it looks better; giant since
a boss"). The Ivory Spider (designs/crimson/IvorySpider.bbmodel, QM's file), same bones,
legs and animations, made a black widow:
- glossy black all over, a huge round abdomen (layered boxes) in place of the box one
- the red hourglass: glowing on its belly, and big on its back between rows of steel spikes
- steel armour on its flanks carved with glowing red runes
- a steel helm on the head-body with a spiked crest and a glowing rune line, eight glowing
  red eyes, ivory fangs under the chelicerae
- steel knee guards with spikes and a glowing red rune band round every leg, steel claws
New parts ride the bone they sit on; leg parts sit in the legs' rest frame (their bones
turn them). Preview and convert with ZYX (--zyx), like the Ivory Spider.

Run: python3 tools/black_widow.py [out_dir] [--gif]
Writes designs/bosses/BlackWidow.bbmodel and renders to /mnt/project-files/animals/bosses/.
"""

import copy
import json
import os
import sys
import uuid

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import horse_rig as HR  # noqa: E402

HR.EULER = "ZYX"
import snake_design as S  # noqa: E402
from ivory_spider import iter_nodes  # noqa: E402
from partlib import render  # noqa: E402
import animal_designs as A  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
BASE = os.path.join(ROOT, "designs", "crimson", "IvorySpider.bbmodel")
NAME = "BlackWidow"
MODEL = os.path.join(ROOT, "designs", "bosses", NAME + ".bbmodel")

# the Ivory Spider's textures (ivory, bone, tip, red, texture) recoloured, then new ones
COLORS = {"black": (22, 22, 28), "steel": (96, 100, 116), "claw": (62, 64, 78), "glow": (255, 30, 40),
          "red": (200, 18, 30), "gloss": (48, 48, 62), "fang": (236, 230, 214)}
T = {n: i for i, n in enumerate(COLORS)}


def build():
    m = json.load(open(BASE))
    template = m["elements"][0]
    m["textures"] = [S.solid_texture(n, c) for n, c in COLORS.items()]
    groups = {g["uuid"]: g["name"] for g in m["groups"]}
    nodes = {groups[n["uuid"]]: n for n in iter_nodes(m["outliner"])}
    elements = {e["uuid"]: e for e in m["elements"]}

    def cube(name, lo, hi, tex=None, rot=(0, 0, 0)):
        tex = T["glow"] if tex is None else tex
        e = copy.deepcopy(template)
        e.update(name=name, uuid=str(uuid.uuid4()), **{"from": list(lo), "to": list(hi)},
                 origin=[(a + b) / 2 for a, b in zip(lo, hi)], rotation=list(rot))
        for f in e["faces"].values():
            f["texture"] = tex
        return e

    def put(bone, parts):
        for e in parts:
            m["elements"].append(e)
            elements[e["uuid"]] = e
            nodes[bone]["children"].append(e["uuid"])

    def tex_of(e):
        return next(iter(e["faces"].values())).get("texture")

    # recolour what's there: ivory -> black, knee joints -> steel, tips -> claws, eyes -> glowing
    for e in m["elements"]:
        t = tex_of(e)
        new = {0: T["black"], 1: T["steel"], 2: T["claw"], 3: T["glow"], 4: T["red"]}[t]
        for f in e["faces"].values():
            f["texture"] = new
    # the Ivory Spider's eyes (red blocks on top of its head-body) go: the eight new ones replace them
    drop = {e["uuid"] for e in m["elements"] if tex_of(e) in (T["glow"], T["red"])}
    m["elements"] = [e for e in m["elements"] if e["uuid"] not in drop]
    for n in iter_nodes(m["outliner"]):
        n["children"] = [c for c in n["children"] if not (isinstance(c, str) and c in drop)]
    # the chelicerae (the tip-coloured blocks on the head) stay black
    for c in nodes["neck"]["children"]:
        if isinstance(c, str) and elements[c]["from"][1] < 0:
            for f in elements[c]["faces"].values():
                f["texture"] = T["black"]

    # abdomen: the box goes, a big round bulb of layered boxes comes in
    ab = nodes["abdomen"]
    old = next(c for c in ab["children"] if isinstance(c, str) and elements[c]["to"][2] - elements[c]["from"][2] > 30)
    ab["children"].remove(old)
    m["elements"] = [e for e in m["elements"] if e["uuid"] != old]
    for c in ab["children"]:  # spinnerets
        if isinstance(c, str):
            for f in elements[c]["faces"].values():
                f["texture"] = T["gloss"]
    cx, cy, cz = 0, 16, 30
    bulb = []
    for i, (hx, hy, hz, tex) in enumerate(((21, 12, 19, "black"), (17, 16, 19, "black"), (17, 12, 23, "black"),
                                          (12, 18, 15, "gloss"), (12, 8, 25, "black"), (8, 14, 24, "black"))):
        bulb.append(cube(f"Abdomen{i + 1}", (cx - hx, cy - hy, cz - hz), (cx + hx, cy + hy, cz + hz), T[tex]))
    bulb.append(cube("Waist", (-8, 6, 6), (8, 18, 12), T["black"]))
    top, bot = cy + 18, cy - 16
    # the hourglass: big on its back, glowing on its belly
    rows = ((-9, -6, 8), (-6, -3, 5.5), (-3, -1, 3), (-1, 1, 1.5), (1, 3, 3), (3, 6, 5.5), (6, 9, 8))
    for k, (z0, z1, w) in enumerate(rows):
        bulb.append(cube(f"Glow_hourglassTop{k + 1}", (-w, top, cz + z0), (w, top + 0.6, cz + z1), T["glow"]))
        bulb.append(cube(f"Glow_hourglassBelly{k + 1}", (-w, bot - 0.6, cz + z0), (w, bot, cz + z1), T["glow"]))
    # steel spikes in two rows either side of it, and down the back behind
    for k, z in enumerate((cz - 11, cz - 4, cz + 4, cz + 11)):
        for s in (-1, 1):
            x = s * 9
            bulb.append(cube(f"SpikeBase{k}{s}", (x - 2, top - 2.5, z - 2), (x + 2, top + 1.5, z + 2), T["steel"]))
            bulb.append(cube(f"SpikeTip{k}{s}", (x - 1, top + 1.5, z - 1), (x + 1, top + 5, z + 1), T["steel"]))
    # flank armour with runes
    for s in (-1, 1):
        x0, x1 = sorted((s * 21, s * 22))
        bulb.append(cube(f"Flank{s}", (x0, cy - 7, cz - 13), (x1, cy + 7, cz + 13), T["steel"]))
        r0, r1 = sorted((s * 22, s * 22.5))
        for k, z in enumerate((cz - 8, cz, cz + 8)):
            bulb.append(cube(f"Glow_rune{s}{k}a", (r0, cy - 4.5, z - 0.6), (r1, cy + 4.5, z + 0.6), T["glow"]))
            if k == 0:  # ᛉ: the stem with two arms up
                bulb.append(cube(f"Glow_rune{s}{k}b", (r0, cy + 0.5, z - 0.5), (r1, cy + 5, z + 0.5), T["glow"], (45, 0, 0)))
                bulb.append(cube(f"Glow_rune{s}{k}c", (r0, cy + 0.5, z - 0.5), (r1, cy + 5, z + 0.5), T["glow"], (-45, 0, 0)))
            elif k == 1:  # ᚦ: the stem with a point
                bulb.append(cube(f"Glow_rune{s}{k}b", (r0, cy - 1.5, z + 0.5), (r1, cy + 1.5, z + 3.0), T["glow"], (45, 0, 0)))
            else:  # ᛏ: the stem under an arrowhead
                bulb.append(cube(f"Glow_rune{s}{k}b", (r0, cy + 1.5, z - 3), (r1, cy + 2.7, z + 0.2), T["glow"], (-35, 0, 0)))
                bulb.append(cube(f"Glow_rune{s}{k}c", (r0, cy + 1.5, z - 0.2), (r1, cy + 2.7, z + 3), T["glow"], (35, 0, 0)))
    put("abdomen", bulb)

    # the head-body: a steel helm with a spiked crest and a glowing rune line
    helm = [cube("Helm", (-11, 12.5, -16.5), (11, 14.5, 5.5), T["steel"]),
            cube("HelmRim", (-12, 11, -17.6), (12, 13, -15.5), T["claw"]),
            cube("Glow_helmRune", (-0.8, 14.5, -14), (0.8, 15.1, 4), T["glow"])]
    for k, (z, h) in enumerate(((-11, 4), (-5, 6), (1, 4))):
        for s in (-1, 1):
            x = s * 5.5
            helm.append(cube(f"Crest{k}{s}", (x - 1.6, 14.5, z - 1.6), (x + 1.6, 14.5 + h * 0.6, z + 1.6), T["steel"]))
            helm.append(cube(f"CrestTip{k}{s}", (x - 0.8, 14.5 + h * 0.6, z - 0.8), (x + 0.8, 14.5 + h, z + 0.8), T["claw"]))
    put("body", helm)

    # eight eyes on the face and fangs under the chelicerae
    face = [cube("Glow_eyeL1", (-6, 7.5, -25.8), (-2, 11, -25)), cube("Glow_eyeR1", (2, 7.5, -25.8), (6, 11, -25)),
            cube("Glow_eyeL2", (-4.5, 11.3, -25.6), (-2, 12.4, -25)), cube("Glow_eyeR2", (2, 11.3, -25.6), (4.5, 12.4, -25)),
            cube("Glow_eyeL3", (-10, 9, -25.6), (-7.5, 11, -25)), cube("Glow_eyeR3", (7.5, 9, -25.6), (10, 11, -25)),
            cube("Glow_eyeL4", (-12.8, 9.5, -23), (-12.5, 11.5, -20.5)), cube("Glow_eyeR4", (12.5, 9.5, -23), (12.8, 11.5, -20.5))]
    for s in (-1, 1):
        x = s * 7.5
        face += [cube(f"Fang{s}1", (x - 2, 1, -28.5), (x + 2, 4.5, -25), T["black"]),
                 cube(f"Fang{s}2", (x - 1.5 - s * 0.8, -0.2, -30.5), (x + 1.5 - s * 0.8, 2.8, -27.5), T["fang"]),
                 cube(f"Fang{s}3", (x - 0.8 - s * 2, -0.6, -32), (x + 0.8 - s * 2, 1.4, -30), T["fang"])]
    put("neck", face)

    # legs: steel knee guards with a spike, a glowing rune band round the upper leg
    for n in list(iter_nodes(m["outliner"])):
        name = groups[n["uuid"]]
        kids = [elements[c] for c in n["children"] if isinstance(c, str)]
        if "_leg_mid_" in name:
            knee = next(e for e in kids if e["to"][0] - e["from"][0] < 10)
            kx = (knee["from"][0] + knee["to"][0]) / 2
            kz = (knee["from"][2] + knee["to"][2]) / 2
            seg = next(e for e in kids if e["to"][0] - e["from"][0] >= 10)
            bx = (seg["from"][0] + seg["to"][0]) / 2
            put(name, [cube("Glow_" + name + "Band", (bx - 1.2, seg["from"][1] - 0.4, seg["from"][2] - 0.4),
                            (bx + 1.2, seg["to"][1] + 0.4, seg["to"][2] + 0.4), T["glow"]),
                       cube(name + "Guard", (kx - 4.2, 6.2, kz - 4.2), (kx + 4.2, 7.4, kz + 4.2), T["steel"]),
                       cube(name + "Spike", (kx - 2, 7.4, kz - 2), (kx + 2, 10.5, kz + 2), T["steel"]),
                       cube(name + "SpikeTip", (kx - 1, 10.5, kz - 1), (kx + 1, 13.5, kz + 1), T["claw"])])
    m["name"] = NAME
    return m


CAMS = [dict(eye=(-11, 8, -12), target=(0, 1.5, 0.5)), dict(eye=(-15, 3, 0), target=(0, 1.5, 0.5)),
        dict(eye=(9, 11, 13), target=(0, 1.5, 1)), dict(eye=(-1.5, 2.2, -7.5), target=(0, 1.0, -2))]


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
    W, H = 600, 480
    sheet = Image.new("RGB", (W * 2, H * 2))
    parts = posed(m)
    for i, cam in enumerate(CAMS):
        sheet.paste(render(parts, W=W, H=H, fov=40, **cam), ((i % 2) * W, (i // 2) * H))
    sheet.save(os.path.join(out, NAME + ".png"))
    if "--gif" in sys.argv:
        frames = []
        for name, k, loops in (("idle", 20, 1), ("walk", 24, 2), ("gallop", 11, 4)):
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
