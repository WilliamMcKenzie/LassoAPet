"""Robo Shark drafts (QM Oct 4: "design me a robo shark", with QM's shark statue,
designs/ocean/RoboShark_ref_statue.bbmodel: a dark riveted metal shark, glowing
cyan eyes, a toothy open jaw, a diamond dorsal fin and splayed pectoral fins).

Run: python3 tools/robo_shark_design.py [out_dir]   (renders the three takes)

Rest pose (every bone at 0): level, belly down, facing -z. Bones: root (the body;
the rider sits behind the dorsal fin, holding it) -> neck (the head; the lasso
loops round it) -> Jaw; root -> FinL / FinR; root -> Tail1 -> Tail2 -> TailFin
(-> Prop on the propeller take). The tail swings side to side (Y rotations).

Parts named Glow* turn Neon in game, Metal* get Roblox's metal texture.
"""

import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(__file__))
import horse_rig  # noqa: E402
import snake_design as S  # noqa: E402
from partlib import render  # noqa: E402

horse_rig.EULER = "ZYX"  # Blockbench's order, so the file looks the same in Blockbench
S.SIZE = 1.0
ROOT = os.path.join(os.path.dirname(__file__), "..")

# Three takes: palette + tail
TAKES = {
    "A": dict(title="A  Statue: gunmetal, cyan eyes", tail="fin",
              colors={"hull": (86, 80, 94), "plate": (62, 56, 70), "belly": (150, 146, 158), "trim": (226, 176, 52),
                      "glow": (70, 226, 255), "tooth": (245, 245, 240), "mouth": (40, 30, 40), "fin": (74, 68, 82)}),
    "B": dict(title="B  Steel + orange, red eyes, jets", tail="jets",
              colors={"hull": (156, 172, 192), "plate": (104, 118, 140), "belly": (232, 238, 244), "trim": (255, 136, 32),
                      "glow": (255, 56, 56), "tooth": (255, 255, 255), "mouth": (52, 36, 44), "fin": (255, 136, 32)}),
    "C": dict(title="C  Toy: blue + yellow, propeller", tail="prop",
              colors={"hull": (40, 120, 226), "plate": (26, 82, 170), "belly": (236, 244, 252), "trim": (255, 212, 40),
                      "glow": (90, 255, 140), "tooth": (255, 255, 255), "mouth": (36, 40, 70), "fin": (255, 212, 40)}),
}

Y0 = 1.0  # body bottom
BODY = (-3.0, 5.0, 6.0, 5.2)  # z front, z back, width, height
HEAD = (-10.4, -3.0, 5.6)  # z front, z back, width
UP = 1.9  # upper head bottom above Y0 (the mouth line)
JAW_TOP = 1.3  # jaw top above Y0 (a gap for the teeth)
TAIL = [("Tail1", 5.0, 9.4, 4.4, 4.2), ("Tail2", 9.4, 12.6, 2.6, 2.4)]  # name, z0, z1, width, height
OVERLAP = 0.5


def build(take):
    cfg = TAKES[take]
    tex = {n: i for i, n in enumerate(cfg["colors"])}
    elements, groups = [], []

    def add_group(name, pivot, parent):
        g = S.group(name, pivot)
        groups.append(g)
        node = {"uuid": g["uuid"], "isOpen": True, "children": []}
        if parent is not None:
            parent["children"].append(node)
        return node

    def put(node, *parts):
        for e in parts:
            elements.append(e)
            node["children"].append(e["uuid"])

    def c(name, center, size, col, rot=(0, 0, 0)):
        e = S.cube(name, center, size, tex[col])
        e["rotation"] = [round(r, 3) for r in rot]
        return e

    z0, z1, w, h = BODY
    zc = (z0 + z1) / 2
    top = Y0 + h
    BEL = 1.5

    # ---- body (root)
    root = add_group("root", (0, Y0 + h / 2, 0), None)
    put(root, c("MetalBody", (0, Y0 + BEL + (h - BEL) / 2, zc), (w, h - BEL, z1 - z0), "hull"),
        c("MetalBelly", (0, Y0 + BEL / 2, zc), (w - 0.3, BEL, z1 - z0 - 0.1), "belly"))
    # armour band round the middle with rivets
    for zb in (1.6,):
        put(root, c("MetalBandTop", (0, top + 0.1, zb), (w + 0.2, 0.2, 0.7), "plate"))
        for sx in (-1, 1):
            put(root, c(f"MetalBand{'LR'[sx > 0]}", (sx * (w / 2 + 0.1), Y0 + BEL + (h - BEL) / 2, zb), (0.2, h - BEL, 0.7), "plate"))
            for k, y in enumerate((Y0 + 2.4, Y0 + 3.6, Y0 + 4.8)):
                put(root, c(f"Rivet{k}{'LR'[sx > 0]}", (sx * (w / 2 + 0.25), y, zb), (0.2, 0.36, 0.36), "trim"))
    # glowing gill slots
    for sx in (-1, 1):
        for k, z in enumerate((-2.2, -1.4, -0.6)):
            put(root, c(f"GlowGill{k}{'LR'[sx > 0]}", (sx * (w / 2 + 0.05), Y0 + 3.2, z), (0.12, 1.8, 0.32), "glow"))
    # back panel the rider sits on, and a stripe along the spine in front of the fin
    put(root, c("MetalSeat", (0, top + 0.1, 3.4), (3.2, 0.2, 2.6), "plate"))
    put(root, c("Stripe", (0, top + 0.08, -2.6), (1.0, 0.16, 0.8), "trim"))
    # dorsal fin, stepped and swept back; the rider holds it
    for k, (fz0, fz1, fh) in enumerate([(-2.2, 1.0, 1.2), (-1.3, 1.2, 1.1), (-0.4, 1.3, 1.0), (0.4, 1.3, 0.8)]):
        y = top + sum(s[2] for s in [(-2.2, 1.0, 1.2), (-1.3, 1.2, 1.1), (-0.4, 1.3, 1.0), (0.4, 1.3, 0.8)][:k])
        put(root, c(f"MetalDorsal{k}", (0, y + fh / 2, (fz0 + fz1) / 2), (0.7, fh, fz1 - fz0), "fin"))
    if cfg["tail"] == "jets":  # twin boosters on the flanks behind the band
        for sx in (-1, 1):
            put(root, c(f"MetalJet{'LR'[sx > 0]}", (sx * (w / 2 + 0.7), Y0 + 2.4, 3.6), (1.4, 1.4, 2.8), "plate"),
                c(f"JetRing{'LR'[sx > 0]}", (sx * (w / 2 + 0.7), Y0 + 2.4, 5.1), (1.6, 1.6, 0.3), "trim"),
                c(f"GlowJet{'LR'[sx > 0]}", (sx * (w / 2 + 0.7), Y0 + 2.4, 5.3), (1.0, 1.0, 0.2), "glow"))

    # ---- head (neck)
    hz0, hz1, hw = HEAD
    neck = add_group("neck", (0, Y0 + h / 2, hz1), root)
    uh = h - UP  # upper head height
    put(neck, c("MetalHead", (0, Y0 + UP + uh / 2, (hz0 + 1.6 + hz1 + OVERLAP) / 2), (hw, uh, hz1 + OVERLAP - hz0 - 1.6), "hull"),
        # the snout: lower and narrower, its top stepping down to the nose
        c("MetalSnout", (0, Y0 + UP + 1.3, hz0 + 0.9), (hw - 1.2, 2.6, 1.8), "hull"),
        c("MetalNose", (0, Y0 + UP + 0.9, hz0 - 0.3), (hw - 2.4, 1.8, 0.8), "plate"),
        c("MetalBrowPlate", (0, Y0 + h + 0.12, -6.4), (hw - 0.8, 0.24, 4.4), "plate"),
        c("MouthBack", (0, Y0 + (JAW_TOP + UP) / 2, -6.2), (hw - 0.8, UP - JAW_TOP + 0.4, 6.6), "mouth"))
    for sx in (-1, 1):
        s = "LR"[sx > 0]
        # visor eyes under a heavy brow, like the statue's
        put(neck, c("GlowEye" + s, (sx * (hw / 2 + 0.06), Y0 + 3.7, -7.6), (0.12, 0.7, 1.6), "glow"),
            c("MetalBrow" + s, (sx * (hw / 2 + 0.15), Y0 + 4.3, -7.4), (0.3, 0.4, 2.4), "plate"))
        for k, y in enumerate((Y0 + 3.0, Y0 + 4.5)):
            put(neck, c(f"HeadRivet{k}{s}", (sx * (hw / 2 + 0.1), y, -4.0), (0.2, 0.32, 0.32), "trim"))
    # upper teeth along the front and sides of the mouth
    teeth = [(x, hz0 + 2.0) for x in (-1.6, -0.55, 0.55, 1.6)] + \
            [(sx * (hw / 2 - 0.45), z) for sx in (-1, 1) for z in (-7.4, -6.1, -4.8)]
    for k, (x, z) in enumerate(teeth):
        put(neck, c(f"ToothU{k}", (x, Y0 + UP - 0.25, z), (0.45, 0.5, 0.45), "tooth"))
    jaw = add_group("Jaw", (0, Y0 + JAW_TOP / 2, hz1 - 0.4), neck)
    put(jaw, c("MetalJaw", (0, Y0 + JAW_TOP / 2, (hz0 + 2.2 + hz1) / 2), (hw - 0.6, JAW_TOP, hz1 - hz0 - 2.2), "plate"),
        c("MetalChin", (0, Y0 + 0.35, hz0 + 1.4), (hw - 1.6, 0.7, 1.0), "belly"))
    for k, (x, z) in enumerate(teeth):
        put(jaw, c(f"ToothL{k}", (x * 0.92, Y0 + JAW_TOP + 0.2, z + 0.6), (0.4, 0.4, 0.4), "tooth"))

    # ---- pectoral fins, splayed down and back like the statue's
    for sx in (-1, 1):
        s = "LR"[sx > 0]
        fin = add_group("Fin" + s, (sx * w / 2, Y0 + 1.4, -0.6), root)
        rot = (0, sx * 22, sx * 24)
        R = horse_rig.rotm(np.array(rot, float))
        fc = np.array((sx * (w / 2 + 1.6), Y0 + 1.0, 0.0))
        put(fin, c("MetalFin" + s, fc, (3.4, 0.5, 2.4), "fin", rot),
            c("FinTip" + s, fc + R @ np.array((sx * 1.9, 0.0, 0.5)), (1.4, 0.42, 1.4), "plate", rot))

    # ---- tail
    parent = root
    for name, tz0, tz1, tw, th in TAIL:
        ty = Y0 + 1.2 + th / 2
        node = add_group(name, (0, ty, tz0), parent)
        put(node, c("Metal" + name, (0, ty, (tz0 - OVERLAP + tz1) / 2), (tw, th, tz1 - tz0 + OVERLAP), "hull"),
            c(name + "Belly", (0, ty - th / 2 + 0.3, (tz0 - OVERLAP + tz1) / 2), (tw - 0.2, 0.6, tz1 - tz0 + OVERLAP - 0.1), "belly"),
            c(name + "Ridge", (0, ty + th / 2 + 0.15, (tz0 + tz1) / 2), (0.5, 0.3, (tz1 - tz0) * 0.7), "plate"))
        parent = node
    fz = TAIL[-1][2]
    fy = Y0 + 1.2 + TAIL[-1][4] / 2
    tfin = add_group("TailFin", (0, fy, fz), parent)
    if cfg["tail"] == "prop":
        put(tfin, c("MetalHub", (0, fy, fz + 0.5), (1.6, 1.6, 1.4), "plate"),
            c("MetalHubRing", (0, fy, fz + 1.05), (2.0, 2.0, 0.3), "trim"))
        prop = add_group("Prop", (0, fy, fz + 1.5), tfin)
        put(prop, c("PropCap", (0, fy, fz + 1.5), (0.9, 0.9, 0.6), "trim"))
        for k in range(3):
            a = 90 + 120 * k
            r = 2.0
            put(prop, c(f"MetalBlade{k}", (r * math.cos(math.radians(a)), fy + r * math.sin(math.radians(a)), fz + 1.5),
                        (3.4, 1.3, 0.25), "fin", (20, 0, a)))
    else:
        put(tfin, c("MetalFinRoot", (0, fy, fz + 0.5), (1.0, 1.8, 1.4), "plate"),
            c("MetalLobeUp", (0, fy + 2.2, fz + 1.6), (0.6, 4.2, 1.6), "fin", (34, 0, 0)),
            c("MetalLobeDown", (0, fy - 1.4, fz + 1.2), (0.6, 2.6, 1.4), "fin", (-36, 0, 0)))
        if cfg["tail"] == "fin":
            put(tfin, c("LobeTrim", (0, fy + 3.95, fz + 2.85), (0.7, 0.5, 0.5), "trim", (34, 0, 0)))
        else:  # jets: a glowing nozzle at the tail root
            put(tfin, c("GlowNozzle", (0, fy, fz + 1.25), (0.7, 0.9, 0.2), "glow"))

    model = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
    model.update(name="RoboShark", elements=elements, groups=groups, outliner=[root], animations=[],
                 textures=[S.solid_texture(n, col) for n, col in cfg["colors"].items()])
    model.setdefault("meta", {})["format_version"] = "5.0"
    return model


def posed(m, anim=None, t=0.0):
    ps = S.posed(m, anim, t)
    for p in ps:
        p.neon = p.name.startswith("Glow")
        p.plain = p.plain or p.neon
    return ps


def sheet(out):
    W, H = 520, 420
    cams = [dict(eye=(-26, 17, -28), target=(0, 3.5, 0)), dict(eye=(-40, 7, 1), target=(0, 3.5, 1)),
            dict(eye=(22, 20, 28), target=(0, 3.5, 2))]
    im = Image.new("RGB", (W * len(cams), (H + 40) * len(TAKES)), (255, 255, 255))
    dr = ImageDraw.Draw(im)
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 26)
    except OSError:
        font = None
    for r, take in enumerate(TAKES):
        m = build(take)
        with open(os.path.join(out, f"RoboShark_{take}.bbmodel"), "w") as f:
            json.dump(m, f, separators=(",", ":"))
        ps = posed(m)
        dr.text((16, r * (H + 40) + 6), TAKES[take]["title"], fill=(20, 20, 20), font=font)
        for i, cam in enumerate(cams):
            im.paste(render(ps, W=W, H=H, fov=40, **cam), (i * W, r * (H + 40) + 40))
    im.save(os.path.join(out, "RoboShark_takes.png"))
    print("elements", len(build("A")["elements"]))


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/animals/robo_shark"
    os.makedirs(out, exist_ok=True)
    sheet(out)
