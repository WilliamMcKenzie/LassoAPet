"""Living Mushrooms: World 2's Crystal Cavern animals, fat little mushroom guys in three
sizes coloured like the cavern's fungus props (tools/crystal_meshes.py on the rock
meshes branch): a giant purple one (#86538E with white spots), a medium brown one
(#836267) and a smaller red one with white spots.

Run: python3 tools/living_mushroom.py [out_dir]

Few parts (QM): a chunky cream body on two stubby legs with two stubby arms, a
domed cap with a darker underside and raised white spots, and the animals' standard
white plate eyes with dark pupils on the body's sides under the cap (QM: same style guide). Bones: root (body), neck (cap and eyes, the lasso loops
round it), ArmL/R, LegFL/FR (named like the Cactus's, so the gallop kicks up dust).
"""

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import snake_design as S  # noqa: E402
from partlib import render  # noqa: E402
import animal_designs as A  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
STEM, STEM_DARK, SPOT = (226, 212, 194), (196, 178, 156), (250, 248, 252)
EYE_WHITE, PUPIL = (255, 255, 255), (24, 20, 32)


def darker(c, k=0.72):
    return tuple(int(v * k) for v in c)


# name: (size, cap colour, spots, cap width x body width) — the giant has the broadest cap
KINDS = {"PurpleMushroom": (1.5, (0x86, 0x53, 0x8E), True, 1.4),
         "BrownMushroom": (1.1, (0x83, 0x62, 0x67), False, 1.3),
         "RedMushroom": (0.8, (210, 62, 40), True, 1.35)}


def build(name):
    size, cap, spots, capk = KINDS[name]
    S.SIZE = size
    colors = {"stem": STEM, "stemdark": STEM_DARK, "cap": cap, "under": darker(cap), "spot": SPOT, "white": EYE_WHITE, "pupil": PUPIL}
    T = {n: i for i, n in enumerate(colors)}
    elements, groups = [], []

    def add_group(gname, pivot, parent):
        g = S.group(gname, pivot)
        groups.append(g)
        node = {"uuid": g["uuid"], "isOpen": True, "children": []}
        if parent is not None:
            parent["children"].append(node)
        return node

    def put(node, parts):
        for e in parts:
            elements.append(e)
            node["children"].append(e["uuid"])

    bw = 3.8  # body width (studs, before size): fat
    root = add_group("root", (0, 2.4, 0), None)
    # fat round body: a wide middle, narrower shaded bottom and a narrower top under the cap
    put(root, [S.cube("Body", (0, 2.5, 0), (bw, 2.0, bw), T["stem"]),
               S.cube("Belly", (0, 1.15, 0), (bw - 0.8, 0.7, bw - 0.8), T["stemdark"]),
               S.cube("Shoulders", (0, 3.75, 0), (bw - 0.8, 0.5, bw - 0.8), T["stem"])])
    for s, sx in (("L", -1), ("R", 1)):
        leg = add_group("LegF" + s, (sx * 0.9, 0.9, 0), root)
        put(leg, [S.cube("LegF" + s, (sx * 0.9, 0.45, 0), (1.0, 0.9, 1.1), T["stemdark"])])
        arm = add_group("Arm" + s, (sx * bw / 2, 2.8, 0.6), root)
        put(arm, [S.cube("Arm" + s, (sx * (bw / 2 + 0.35), 2.3, 0.6), (0.7, 1.1, 0.9), T["stem"])])

    cw = bw * capk
    head = add_group("neck", (0, 4.0, 0), root)
    # a domed cap: brim, middle, crown, with a darker underside
    put(head, [S.cube("Underside", (0, 4.1, 0), (cw - 0.5, 0.3, cw - 0.5), T["under"]),
               S.cube("Cap", (0, 4.7, 0), (cw, 0.9, cw), T["cap"]),
               S.cube("CapMid", (0, 5.55, 0), (cw * 0.8, 0.8, cw * 0.8), T["cap"]),
               S.cube("CapTop", (0, 6.2, 0), (cw * 0.52, 0.5, cw * 0.52), T["cap"])])
    # plate eyes on the body's sides by the front, pupils looking forward and set back
    # from the plate's front edge (QM's z-fighting rule)
    ey0, ey1, ez0, ez1 = 2.6, 3.8, -bw / 2 + 0.1, -bw / 2 + 1.5
    for s, sx in (("L", -1), ("R", 1)):
        put(head, [S.cube("Eye" + s, (sx * (bw / 2 + 0.025), (ey0 + ey1) / 2, (ez0 + ez1) / 2), (0.05, ey1 - ey0, ez1 - ez0), T["white"]),
                   S.cube("Pupil" + s, (sx * (bw / 2 + 0.055), ey0 + 0.5, ez0 + 0.025 + 0.4), (0.05, 0.8, 0.75), T["pupil"])])
    if spots:
        r1, r2, r3 = cw / 2 - 0.25, cw * 0.4 - 0.4, cw * 0.26 - 0.45
        for i, (x, y, z, w) in enumerate([(-r1 * 0.6, 5.15, -r1, 0.7), (r1, 5.15, r1 * 0.5, 0.7), (-r1, 5.15, r1 * 0.7, 0.6),
                                          (r2, 5.95, -r2, 0.65), (-r2, 5.95, r2 * 0.2, 0.6), (r3, 6.45, r3, 0.55)]):
            put(head, [S.cube(f"Spot{i + 1}", (x, y + 0.08, z), (w, 0.16, w), T["spot"])])

    model = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
    model.update(name=name, elements=elements, groups=groups, outliner=[root], animations=[],
                 textures=[S.solid_texture(n, c) for n, c in colors.items()])
    meta = {"seat": (0, 6.45 * size, 0), "neck_loop": {"center": (0, 4.7 * size, 0), "radius": cw / 2 * size}}
    return model, meta


def main(out="/mnt/project-files/animals/living_mushroom"):
    os.makedirs(out, exist_ok=True)
    os.makedirs(os.path.join(ROOT, "designs", "crystal"), exist_ok=True)
    parts, x = [], -14.0
    for name in KINDS:
        model, _ = build(name)
        for path in (os.path.join(ROOT, "designs", "crystal", f"{name}.bbmodel"), os.path.join(out, f"{name}.bbmodel")):
            with open(path, "w") as f:
                json.dump(model, f, separators=(",", ":"))
        ps = S.posed(model)
        for p in ps:
            p.polys = [q + np.array([x, 0, 0]) for q in p.polys]
        parts += ps
        x += 3.2 * KINDS[name][3] * KINDS[name][0] / 2 + 4.5
        print(name, len(model["elements"]), "elements")
    from horse_rig import pose
    hparts = pose(A.qm_horse("A"), None, 0)
    for p in hparts:
        p.polys = [q + np.array([x + 2, 0, 0]) for q in p.polys]
    W, H = 1120, 520
    sheet = Image.new("RGB", (W, H * 2))
    sheet.paste(render(parts + hparts, W=W, H=H, fov=34, eye=(-26, 10, -28), target=(-4, 3.5, 0)), (0, 0))
    sheet.paste(render(parts + hparts, W=W, H=H, fov=34, eye=(4, 16, 30), target=(-4, 3.5, 0)), (0, H))
    sheet.save(os.path.join(out, "LivingMushrooms.png"))


if __name__ == "__main__":
    main(*sys.argv[1:])
