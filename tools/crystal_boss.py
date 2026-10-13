"""The Crystal Tyrant: World 2 Crystal Cavern's boss (QM, Oct 13: "a giant evil version of
the crystal guy"). The Living Crystal (tools/living_crystal.py) made bulky and dark: a deep
violet crystal shaft with a glowing cyan facet, a taller tip, angry brows over glowing red
eyes, a jagged grin of white teeth, a crown of lighter shards with glowing cyan tips behind its head, and
shards on its arms. Same bones and animations as the Cactus and the Living Crystal (root,
neck, ArmL, ArmR, LegFL, LegFR); every bone rests at 0.

Run: python3 tools/crystal_boss.py [out_dir] [--gif]
"""

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import horse_rig  # noqa: E402

horse_rig.EULER = "ZYX"  # Blockbench's own order: QM edits it there
import snake_design as S  # noqa: E402
import living_crystal as LC  # noqa: E402
from partlib import render  # noqa: E402
import animal_designs as A  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
MODEL = os.path.join(ROOT, "designs", "bosses", "CrystalTyrant.bbmodel")
NAME = "CrystalTyrant"

COLORS = {"main": (78, 48, 160), "light": (118, 88, 214), "dark": (46, 28, 104), "glow": (92, 225, 255),
          "eye": (255, 40, 64), "brow": (26, 16, 48), "mouth": (30, 18, 52), "tooth": (250, 248, 240),
          "shard": (132, 100, 226)}
T = {n: i for i, n in enumerate(COLORS)}


def box(name, lo, hi, tex, rz=0.0):
    e = LC.box(name, lo, hi, tex)
    e["rotation"] = [0, 0, round(rz, 3)]
    return e


def pyramid(name, x, base_y, z, hw, hd, h, tex):
    p = LC.pyramid(name, base_y, hw, hd, h, tex)
    p["origin"] = [x, base_y, z]
    return p


def shard(name, x, y0, z, w, h, tip, tex=None):
    """A crystal: a square shaft from y0 up h, with a pyramid tip (Blockbench units)."""
    tex = T["shard"] if tex is None else tex
    return [box(name, (x - w / 2, y0, z - w / 2), (x + w / 2, y0 + h, z + w / 2), tex),
            pyramid("Glow_" + name + "Tip", x, y0 + h, z, w / 2, w / 2, tip, T["glow"])]


def build():
    cactus = json.load(open(LC.CACTUS))
    groups = {g["name"]: g for g in cactus["groups"]}
    elements, new_groups = [], []

    def add_group(gname, parent):
        g = S.group(gname, (0, 0, 0))
        g["origin"] = list(groups[gname]["origin"])
        new_groups.append(g)
        node = {"uuid": g["uuid"], "isOpen": True, "children": []}
        if parent is not None:
            parent["children"].append(node)
        return node

    def put(node, parts):
        for e in parts:
            elements.append(e)
            node["children"].append(e["uuid"])

    root = add_group("root", None)
    zf = -14  # the front face
    put(root, [box("Body", (-17, 32, -14), (17, 110, 14), T["main"]),
               box("Glow_facet", (-18, 38, -15), (-11, 104, -13), T["glow"]),
               box("FacetSide", (17, 38, 4), (18, 104, 11), T["light"]),
               # glowing red eyes under angry brows (inner ends down)
               box("Glow_eyeL", (-10, 90, zf - 0.6), (-3, 97, zf), T["eye"]),
               box("Glow_eyeR", (3, 90, zf - 0.6), (10, 97, zf), T["eye"]),
               box("PupilL", (-7.5, 91.5, zf - 0.9), (-4.5, 95.5, zf - 0.5), T["brow"]),
               box("PupilR", (4.5, 91.5, zf - 0.9), (7.5, 95.5, zf - 0.5), T["brow"]),
               box("BrowL", (-12, 98, zf - 1.4), (-1, 102, zf), T["brow"], -22),
               box("BrowR", (1, 98, zf - 1.4), (12, 102, zf), T["brow"], 22),
               # a jagged grin
               box("Mouth", (-9, 70, zf - 0.6), (9, 84, zf), T["mouth"])])
    teeth = []
    for i, x in enumerate((-7, -2.5, 2.5, 7)):  # top row, pointing down
        teeth.append(box(f"ToothT{i + 1}", (x - 1.6, 79, zf - 1.0), (x + 1.6, 84, zf - 0.4), T["tooth"]))
    for i, x in enumerate((-4.75, 0, 4.75)):  # bottom row, between them
        teeth.append(box(f"ToothB{i + 1}", (x - 1.6, 70, zf - 1.0), (x + 1.6, 74.5, zf - 0.4), T["tooth"]))
    put(root, teeth)
    # a crown of shards rising behind its head
    crown = []
    for i, (x, z, w, h, tip) in enumerate(((-12, 18, 8, 70, 18), (0, 20, 10, 92, 24), (12, 18, 8, 62, 16),
                                           (-20, 10, 6, 50, 14), (20, 10, 6, 56, 14))):
        crown += shard(f"Crown{i + 1}", x, 66, z, w, h, tip)
    put(root, crown)

    neck = add_group("neck", root)
    put(neck, [LC.pyramid("Tip", 110, 17, 14, 46, T["main"])])
    for s in ("L", "R"):
        arm = add_group("Arm" + s, root)
        src = [e for e in cactus["elements"] if e["name"] in ("Arm" + s, "Forearm" + s)]
        parts = [box(e["name"], [c - 1.5 for c in e["from"]],
                     [c + 1.5 for c in e["to"]], T["main"]) for e in src]
        if s == "L":  # the raised fist: a shard on top, one on the elbow
            parts += shard("ArmShardL1", -29.5, 102.5, 0, 6, 6, 12)
            parts += shard("ArmShardL2", -20, 83.5, 0, 5, 3, 9)
        else:  # the lowered arm: shards along its top
            parts += shard("ArmShardR1", 22, 79.5, 0, 5, 3, 9)
            parts += shard("ArmShardR2", 30, 79.5, 0, 5, 5, 11)
        put(arm, parts)
        leg = add_group("LegF" + s, root)
        e = next(e for e in cactus["elements"] if e["name"] == "Leg" + s)
        put(leg, [box("Leg" + s, [e["from"][0] - 1.5, 0, e["from"][2] - 1.5], [e["to"][0] + 1.5, e["to"][1], e["to"][2] + 1.5], T["dark"])])

    by_name = {g["name"]: g["uuid"] for g in new_groups}
    old = {g["uuid"]: g["name"] for g in cactus["groups"]}
    anims = []
    for a in json.loads(json.dumps(cactus.get("animations", []))):
        a["animators"] = {by_name[old[u]]: v for u, v in a["animators"].items() if old.get(u) in by_name}
        anims.append(a)

    model = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
    model.update(name=NAME, elements=elements, groups=new_groups, outliner=[root], animations=anims,
                 textures=[S.solid_texture(n, c) for n, c in COLORS.items()])
    model.setdefault("meta", {})["format_version"] = "5.0"
    return model


CAMS = [dict(eye=(-12, 13, -30), target=(0, 7, 0)), dict(eye=(0, 9, -32), target=(0, 7.5, 0)),
        dict(eye=(30, 10, 10), target=(0, 7, 0)), dict(eye=(14, 16, 30), target=(0, 7, 0))]


def main(out="/mnt/project-files/animals/bosses"):
    os.makedirs(out, exist_ok=True)
    m = build()
    for path in (MODEL, os.path.join(out, NAME + ".bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    print("elements", len(m["elements"]))
    parts = S.posed(m)
    blue = S.posed(json.load(open(os.path.join(ROOT, "designs", "crystal", "BlueCrystal.bbmodel"))))
    for p in blue:
        p.polys = [q + np.array([-9, 0, -4]) for q in p.polys]
    Wd, Ht = 640, 560
    sheet = Image.new("RGB", (Wd * 2, Ht * 2))
    for i, cam in enumerate(CAMS):
        sheet.paste(render(parts + (blue if i == 0 else []), W=Wd, H=Ht, fov=40, **cam), ((i % 2) * Wd, (i // 2) * Ht))
    sheet.save(os.path.join(out, NAME + ".png"))
    if "--gif" in sys.argv:
        frames = []
        for name, n, loops in (("idle", 24, 1), ("walk", 12, 2), ("gallop", 8, 3)):
            anim = next(a for a in m["animations"] if a["name"] == name)
            for _ in range(loops):
                for k in range(n):
                    ps = S.posed(m, anim, anim["length"] * k / n)
                    im = Image.new("RGB", (800, 360))
                    im.paste(render(ps, W=400, H=360, fov=40, **CAMS[0]), (0, 0))
                    im.paste(render(ps, W=400, H=360, fov=40, **CAMS[2]), (400, 0))
                    frames.append(A.label(im, [name] * 2))
        A.gif(os.path.join(out, NAME + "_anims.gif"), frames, fps=20)


if __name__ == "__main__":
    main(*[a for a in sys.argv[1:] if not a.startswith("--")])
