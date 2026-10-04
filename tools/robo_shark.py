"""The Robo Shark from QM's shark statue (designs/ocean/RoboShark_ref_statue.bbmodel).

Run: python3 tools/robo_shark.py [out_dir]   rebuild designs/ocean/RoboShark.bbmodel, render previews
then: python3 tools/bbmodel_to_luau.py --zyx designs/ocean/RoboShark.bbmodel src/shared/Animals/RoboSharkModel.luau

QM Oct 4: "pretty much 1:1 with my initial blockbench model, only changing the tail fin
to be not a 2d plane and change the teeth to be pyramids". This script keeps every
block where QM put it (its jaw hangs open and its tail bends, as in the statue) and:
  - gives each block one colour, the colour most of its paint is (snack_yak's rules);
  - turns the painted cyan eyes and the gold marks into small raised blocks (the eyes
    glow);
  - turns the painted tail fin plane into real blocks FIN deep, one per run of texels;
  - turns the painted teeth on the three tooth planes into pyramids hanging from the
    head, one per tooth, as wide as the painted tooth and as long;
  - adds the bones the game needs: root (body) -> neck (head) -> Jaw; root -> FinL /
    FinR; root -> Tail -> TailFin.
"""

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import horse_rig as HR  # noqa: E402
import snake_design as S  # noqa: E402
import snack_yak as Y  # noqa: E402
from bb_textured import render_textured, textures as painted  # noqa: E402
from partlib import render  # noqa: E402

HR.EULER = "ZYX"
ROOT = os.path.join(os.path.dirname(__file__), "..")
SRC = os.path.join(ROOT, "designs", "ocean", "RoboShark_ref_statue.bbmodel")
MODEL = os.path.join(ROOT, "designs", "ocean", "RoboShark.bbmodel")

# QM's elements by index: (name, bone)
ELEMENTS = {0: ("Head", "neck"), 1: ("Jaw", "Jaw"), 2: ("Body", "root"), 3: ("Tail", "Tail"),
            4: ("Dorsal", "root"), 5: ("TailFin", "TailFin"), 6: ("TeethR", "neck"), 7: ("TeethFront", "neck"),
            8: ("TeethL", "neck"), 9: ("FinR", "FinR"), 10: ("FinL", "FinL")}
TEETH = (6, 7, 8)
FIN = 5
# bones: (name, parent, pivot in Blockbench units)
BONES = [("root", None, (0, 16, 0)), ("neck", "root", (0, 14, -10)), ("Jaw", "neck", (0, 14, -10)),
         ("FinR", "root", (7, 8, 0)), ("FinL", "root", (-7, 8, 0)),
         ("Tail", "root", (0, 14.5, 10)), ("TailFin", "Tail", (4.28772, 14.5, 19.55582))]
FIN_DEPTH = 3.0  # units: the tail fin's thickness (the tail is 8 wide)
TOOTH_DEPTH = 1.6  # units: how far a side tooth's base reaches into the mouth
ACCENT = 0.4  # units: how far the eyes and gold marks stand out of their faces
GLOW = lambda c: c[2] > 200 and c[0] < 170  # noqa: E731  the cyan eye paint


def accents(e, texs):
    """Raised blocks for the strongly coloured paint on a block's faces (eyes, gold)."""
    out = []
    for fname, f in e["faces"].items():
        if f.get("texture") is None or f["uv"][0] == f["uv"][2] or f["uv"][1] == f["uv"][3]:
            continue
        grid, tl, tr, bl = Y.texel_grid(e, fname, texs)
        acc = [[c if c and max(c) - min(c) > 70 else None for c in row] for row in grid]
        nv, nu = len(acc), len(acc[0])
        ax, s = Y.FACE_AXIS[fname]
        for u0, v0, u1, v1 in Y.rects(acc):
            a = tl + u0 / nu * (tr - tl) + v0 / nv * (bl - tl)
            b = tl + u1 / nu * (tr - tl) + v1 / nv * (bl - tl)
            lo, hi = np.minimum(a, b), np.maximum(a, b)
            lo[ax], hi[ax] = (hi[ax] - ACCENT, hi[ax] + ACCENT) if s > 0 else (lo[ax] - ACCENT, lo[ax] + ACCENT)
            hist = {}
            for v in range(v0, v1):
                for u in range(u0, u1):
                    hist[acc[v][u]] = hist.get(acc[v][u], 0) + 1
            rgb = Y.dominant(hist)[0]
            out.append({**json.loads(json.dumps(e)), "uuid": S.uid(), "name": ("GlowEye" if GLOW(rgb) else "Gold"),
                        "from": [round(x, 4) for x in lo], "to": [round(x, 4) for x in hi], "rgb": rgb})
    return out


def tooth(name, e, base, apex, tex):
    """A square pyramid mesh: base corners and apex in the element's own (unrotated)
    space; it keeps the element's origin and rotation so it sits where QM's paint was."""
    o = np.array(e["origin"], float)
    v = {k: [round(c, 4) for c in np.array(p, float) - o] for k, p in zip("abcd", base)}
    v["t"] = [round(c, 4) for c in np.array(apex, float) - o]
    faces = {"base": {"uv": {k: [0, 0] for k in "dcba"}, "texture": tex, "vertices": list("dcba")}}
    for i, (p, q) in enumerate((("a", "b"), ("b", "c"), ("c", "d"), ("d", "a"))):
        faces[f"s{i}"] = {"uv": {k: [0, 0] for k in (p, q, "t")}, "texture": tex, "vertices": [p, q, "t"]}
    return {"name": name, "type": "mesh", "uuid": S.uid(), "color": 0, "origin": list(e["origin"]),
            "rotation": list(e.get("rotation") or (0, 0, 0)), "export": True, "visibility": True,
            "vertices": v, "faces": faces}


def teeth(e, texs, tex):
    """Each painted tooth (a run of columns sharing a height) on a tooth plane as a
    pyramid hanging from the plane's top edge, reaching into the mouth."""
    ax = next(a for a in range(3) if abs(e["to"][a] - e["from"][a]) < 1e-6)
    fname = next(n for n, (a, s) in Y.FACE_AXIS.items() if a == ax and s > 0)
    grid, tl, tr, bl = Y.texel_grid(e, fname, texs)
    nv, nu = len(grid), len(grid[0])
    du, dv = (tr - tl) / nu, (bl - tl) / nv
    # inward: toward the head's middle (x = 0 for the side planes, +z for the front one)
    inward = np.zeros(3)
    inward[ax] = -np.sign(tl[ax]) if ax == 0 else 1.0
    out = []
    u = 0
    while u < nu:
        h = sum(grid[v][u] is not None for v in range(nv))
        if not h:
            u += 1
            continue
        u1 = u + 1
        while u1 < nu and sum(grid[v][u1] is not None for v in range(nv)) > 0:
            u1 += 1
        h = max(sum(grid[v][k] is not None for v in range(nv)) for k in range(u, u1))
        w = (u1 - u) * np.linalg.norm(du)
        d = min(TOOTH_DEPTH, w) * inward
        p0, p1 = tl + u * du, tl + u1 * du
        base = [p0, p1, p1 + d, p0 + d]
        apex = (p0 + p1) / 2 + d / 2 + h * dv
        out.append(tooth(f"Tooth{len(out)}", e, base, apex, tex))
        u = u1
    return out


def build():
    m = json.load(open(SRC))
    m["name"] = "RoboShark"
    texs = painted(m)
    colours = Y.colour_blocks(m)
    palette = {}

    def tex(rgb):
        if rgb not in palette:
            palette[rgb] = len(palette)
        return palette[rgb]

    bones = {name: [] for name, _, _ in BONES}
    for i, e in enumerate(m["elements"]):
        name, bone = ELEMENTS[i]
        if i in TEETH:
            col = Y.dominant(Y.face_pixels(e, next(f for f in e["faces"].values() if f["uv"][0] != f["uv"][2]), texs))[0]
            for t in teeth(e, texs, tex(col)):
                t["name"] = name + t["name"]
                bones[bone].append(t)
            continue
        if i == FIN:  # the fin plane as real blocks
            Y.PLANE = FIN_DEPTH
            for b in Y.sprite_blocks(e, 0, texs):
                b["name"] = name
                S.retexture(b, tex(b.pop("rgb")))
                bones[bone].append(b)
            continue
        for b in accents(e, texs):
            b["name"] += name
            S.retexture(b, tex(b.pop("rgb")))
            bones[bone].append(b)
        e["name"] = "Metal" + name
        S.retexture(e, tex(colours[i][0]))
        bones[bone].append(e)

    m["elements"] = [e for es in bones.values() for e in es]
    m["groups"], nodes = [], {}
    for name, parent, pivot in BONES:
        g = Y.new_group(name, pivot)
        m["groups"].append(g)
        nodes[name] = {"uuid": g["uuid"], "isOpen": True, "children": [e["uuid"] for e in bones[name]]}
        if parent:
            nodes[parent]["children"].append(nodes[name])
    m["outliner"] = [nodes["root"]]
    m["textures"] = [S.solid_texture(f"c{k}", rgb) for rgb, k in palette.items()]
    m.setdefault("meta", {})["format_version"] = "5.0"
    m["animations"] = []
    return m


def floor(m):
    """Shift everything so the lowest point sits on y = 0; returns the shift (units)."""
    lo = min(q[:, 1].min() for p in S.posed(m) for q in p.polys) * S.BB
    for e in m["elements"]:
        for k in ("from", "to", "origin"):
            if k in e:
                e[k][1] = round(e[k][1] - lo, 4)
    for g in m["groups"]:
        g["origin"][1] = round(g["origin"][1] - lo, 4)
    return -lo


def posed(m, anim=None, t=0.0):
    ps = S.posed(m, anim, t)
    for p in ps:
        p.neon = p.name.startswith("Glow")
        p.plain = p.plain or p.neon
    return ps


def previews(m, out, shift):
    src = json.load(open(SRC))
    W, H = 520, 440
    cams = [((-7.5, 5, -8.5), (0, 1.2, 0.3)), ((-11, 1.6, 0.5), (0, 1.2, 0.5)), ((6.5, 6, 8), (0, 1.2, 0.5))]
    ps = posed(m)
    sheet = Image.new("RGB", (W * 3, H * 2), (255, 255, 255))
    for i, (eye, target) in enumerate(cams):
        sheet.paste(render(ps, W=W, H=H, fov=26, eye=eye, target=target), (i * W, 0))
        # QM's painted statue from the same camera (QM's units are 0.1 stud; ours were lifted by `shift`)
        lift = np.array((0, shift, 0))
        q = render_textured(src, eye=np.array(eye) * 10 - lift, target=np.array(target) * 10 - lift, W=W, H=H, fov=26)
        sheet.paste(q, (i * W, H))
    sheet.save(os.path.join(out, "RoboShark.png"))


def main(out="/mnt/project-files/animals/robo_shark"):
    os.makedirs(out, exist_ok=True)
    m = build()
    shift = floor(m)
    for path in (MODEL, os.path.join(out, "RoboShark.bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    print("elements", len(m["elements"]), "shift", round(shift, 3))
    previews(m, out, shift)


if __name__ == "__main__":
    main(*sys.argv[1:])
