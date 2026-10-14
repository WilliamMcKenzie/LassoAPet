"""Shared builder for World 3's Pirate Cove animals (Oct 14): every tools/pirate_*.py builds its
Blockbench model with this, in Blockbench's ZYX Euler order, every bone resting at 0 (angles
baked into the cubes; spikes, teeth and fins are pyramid meshes).

    m = Model("RedCrab", {"red": (230, 50, 40), ...})
    root = m.group("root", (0, 2, 0))
    m.put(root, [m.box("Body", (0, 2, 0), (4, 2, 4), "red"), ...])
    m.save(animations())          # floors it, writes the bbmodel, the render and the check sheet

Output: designs/world3/pirate/<Name>.bbmodel (convert with bbmodel_to_luau.py --zyx),
/mnt/project-files/world3/pirate_cove/renders/<Name>.png, <Name>_sheet.png (next to the Horse,
front, top, side) and, with --gif, <Name>_anims.gif.
"""

import json
import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import horse_rig  # noqa: E402

horse_rig.EULER = "ZYX"
import angel_boss as AB  # noqa: E402  (sets snake_design.SIZE = 1)
import snake_design as S  # noqa: E402
import animal_designs as A  # noqa: E402
from hawkmoth import pyr as _pyr, light_bg  # noqa: E402
from horse_rig import write_animations  # noqa: E402
from partlib import render  # noqa: E402
from snake_rig import track  # noqa: E402,F401  (re-exported for the animal files)

TAU = 2 * math.pi
ROOT = os.path.join(os.path.dirname(__file__), "..")
DESIGNS = os.path.join(ROOT, "designs", "world3", "pirate")
OUT = "/mnt/project-files/world3/pirate_cove"
R = AB.axis_rot

# Colours every Pirate Cove animal shares (bright, with dark stops: the game's Lighting washes
# colours out). Each animal adds its own.
BASE = {"white": (255, 255, 255), "pupil": (22, 20, 30), "black": (34, 30, 40),
        "gold": (255, 196, 36), "golddark": (206, 140, 22)}


def frame(d, up=None):
    """A rotation whose local +y points along d (local z kept near `up` when given)."""
    y = np.array(d, float) / np.linalg.norm(d)
    ref = np.array(up, float) if up is not None else (np.array([0, 0, 1.0]) if abs(y[2]) < 0.9 else np.array([1.0, 0, 0]))
    x = np.cross(y, ref)
    if np.linalg.norm(x) < 1e-6:
        x = np.cross(y, [1.0, 0, 0])
    x /= np.linalg.norm(x)
    z = np.cross(x, y)
    return np.stack([x, y, z], 1)


class Model:
    def __init__(self, name, colors):
        self.name = name
        self.colors = {**BASE, **colors}
        self.tex = {n: i for i, n in enumerate(self.colors)}
        self.elements, self.groups, self.roots = [], [], []
        self.nodes = {}

    # ---------------------------------------------------------------- building
    def group(self, name, pivot, parent=None):
        g = S.group(name, pivot)
        self.groups.append(g)
        node = {"uuid": g["uuid"], "isOpen": True, "children": []}
        if parent is None:
            self.roots.append(node)
        else:
            parent["children"].append(node)
        self.nodes[name] = node
        return node

    def put(self, node, parts):
        for e in parts:
            self.elements.append(e)
            node["children"].append(e["uuid"])

    def box(self, name, center, size, color, M=None):
        return AB.box(name, center, size, self.tex[color], M)

    def seg(self, name, a, b, w, d, color, up=None):
        """A block from point a to point b, w x d across."""
        a, b = np.array(a, float), np.array(b, float)
        v = b - a
        return AB.box(name, (a + b) / 2, (w, np.linalg.norm(v), d), self.tex[color], frame(v, up))

    def pyr(self, name, base, d, wv, L, hw, ht, color):
        """A pyramid: base rectangle at `base` (half sizes hw along wv, ht across), apex L along d."""
        return _pyr(name, base, d, wv, L, hw, ht, self.tex[color])

    def hull(self, name, pts, color):
        """A low-poly mesh: the convex hull of `pts` (studs), flat triangles (garden_lib's). With
        bbmodel_to_luau.py --meshes, the hulls on a bone in one colour become one MeshPart."""
        import garden_lib as G
        keys, v, faces = {}, {}, {}
        for i, t in enumerate(G.hull_tris(pts)):
            vs = []
            for q in t:
                k = tuple(np.round(q, 5))
                if k not in keys:
                    keys[k] = f"v{len(keys)}"
                    v[keys[k]] = [round(float(x) * S.BB, 4) for x in q]
                vs.append(keys[k])
            faces[f"f{i}"] = {"texture": self.tex[color], "vertices": vs, "uv": {q: [0, 0] for q in vs}}
        return {"name": name, "type": "mesh", "uuid": S.uid(), "color": 0, "origin": [0, 0, 0],
                "rotation": [0, 0, 0], "vertices": v, "faces": faces}

    def eye(self, name, c, side, size=1.2, look=(0, 0, -1), pupil=0.55):
        """A googly plate eye on a side face (side = +-1 on x, or 'front' facing -z): a white
        plate with a dark pupil pushed toward `look`."""
        c = np.array(c, float)
        if side == "front":
            lk = np.array([look[0], look[1], 0.0]) * size * 0.18
            return [self.box(name, c, (size, size, 0.1), "white"),
                    self.box(name + "Pupil", c + np.array([lk[0], lk[1], -0.07]), (size * pupil, size * pupil, 0.05), "pupil")]
        lk = np.array([0, look[1], look[2]]) * size * 0.18
        return [self.box(name, c, (0.1, size, size), "white"),
                self.box(name + "Pupil", c + np.array([side * 0.07, lk[1], lk[2]]), (0.05, size * pupil, size * pupil), "pupil")]

    # ---------------------------------------------------------------- output
    def model(self):
        m = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
        m.update(name=self.name, elements=self.elements, groups=self.groups, outliner=self.roots, animations=[],
                 textures=[S.solid_texture(n, c) for n, c in self.colors.items()])
        m.setdefault("meta", {})["format_version"] = "5.0"
        return m

    def save(self, anims, cam=None, sheet_cams=None, gif_cams=None, floor=True, out=OUT):
        """Floor (lowest point on y = 0), animate, write the bbmodel, render and sheet."""
        m = self.model()
        shift = floor_model(m) if floor else 0.0
        write_animations(m, {g["name"]: g for g in m["groups"]}, anims)
        renders = os.path.join(out, "renders")
        os.makedirs(renders, exist_ok=True)
        os.makedirs(DESIGNS, exist_ok=True)
        for path in (os.path.join(DESIGNS, self.name + ".bbmodel"), os.path.join(out, self.name + ".bbmodel")):
            with open(path, "w") as f:
                json.dump(m, f, separators=(",", ":"))
        parts = S.posed(m)
        P = np.concatenate([q for p in parts for q in p.polys])
        lo, hi = P.min(0), P.max(0)
        span = hi - lo
        ctr = (lo + hi) / 2
        rad = max(span) * 0.5 + 2
        meshes = sum(e["type"] == "mesh" for e in m["elements"])
        print(self.name, "elements", len(m["elements"]), "pyramids", meshes, "shift", round(shift, 3),
              "bounds", lo.round(1), hi.round(1))
        if cam is None:
            d = rad * 2.6
            cam = dict(eye=(ctr[0] - d * 0.62, ctr[1] + d * 0.42, ctr[2] - d * 0.7), target=tuple(ctr))
        light_bg(render(parts, W=1100, H=900, fov=36, transparent=True, **cam)).save(
            os.path.join(renders, self.name + ".png"))
        # the check sheet: next to the Horse (3/4), front, top, side
        horse_rig.EULER = "XYZ"
        hparts = horse_rig.pose(A.qm_horse("A"), None, 0)
        horse_rig.EULER = "ZYX"
        dx = hi[0] + 6
        for p in hparts:
            p.polys = [q + np.array([dx, 0, 0]) for q in p.polys]
        d = rad * 2.8
        if sheet_cams is None:
            sheet_cams = [dict(eye=(ctr[0] - d * 0.6 + dx / 2, ctr[1] + d * 0.4, ctr[2] - d * 0.8), target=(ctr[0] + dx / 2, ctr[1] * 0.7, ctr[2])),
                          dict(eye=(ctr[0], ctr[1] + d * 0.1, ctr[2] - d), target=tuple(ctr)),
                          dict(eye=(ctr[0], ctr[1] + d, ctr[2] + 0.01), target=tuple(ctr)),
                          dict(eye=(ctr[0] + d, ctr[1] + d * 0.1, ctr[2]), target=tuple(ctr))]
        Wd, Ht = 640, 520
        sheet = Image.new("RGB", (Wd * 2, Ht * 2))
        for i, c in enumerate(sheet_cams):
            sheet.paste(render(parts + (hparts if i == 0 else []), W=Wd, H=Ht, fov=40, **c), ((i % 2) * Wd, (i // 2) * Ht))
        sheet.save(os.path.join(out, self.name + "_sheet.png"))
        if "--gif" in sys.argv:
            gc = gif_cams or [sheet_cams[1], dict(eye=(ctr[0] - d * 0.7, ctr[1] + d * 0.4, ctr[2] - d * 0.6), target=tuple(ctr))]
            frames = []
            for name, n, loops in (("idle", 24, 1), ("walk", 12, 3), ("gallop", 8, 4)):
                anim = next(a for a in m["animations"] if a["name"] == name)
                for _ in range(loops):
                    for k in range(n):
                        ps = S.posed(m, anim, anim["length"] * k / n)
                        im = Image.new("RGB", (880, 360))
                        im.paste(render(ps, W=440, H=360, fov=40, **gc[0]), (0, 0))
                        im.paste(render(ps, W=440, H=360, fov=40, **gc[1]), (440, 0))
                        frames.append(A.label(im, [name] * 2))
            A.gif(os.path.join(out, self.name + "_anims.gif"), frames, fps=20)
        return m


def floor_model(model):
    """Shift so the lowest point sits on y = 0."""
    lo = min(q[:, 1].min() for p in S.posed(model) for q in p.polys)
    d = -lo * S.BB
    for e in model["elements"]:
        if e["type"] == "mesh":
            for v in e["vertices"].values():
                v[1] = round(v[1] + d, 4)
        for k in ("from", "to", "origin"):
            if k in e and not (e["type"] == "mesh" and k == "origin"):
                e[k][1] = round(e[k][1] + d, 4)
    for g in model["groups"]:
        g["origin"][1] = round(g["origin"][1] + d, 4)
    return -lo


def lineup(names, path, out=OUT, H=520, labels=None, cols=4):
    """One image of the renders side by side, each labelled."""
    from PIL import ImageDraw, ImageFont
    ims = [Image.open(os.path.join(out, "renders", n + ".png")).convert("RGB") for n in names]
    ims = [im.resize((int(im.width * H / im.height), H)) for im in ims]
    cols = min(len(ims), cols)
    rows = (len(ims) + cols - 1) // cols
    w = max(im.width for im in ims)
    sheet = Image.new("RGB", (w * cols, (H + 40) * rows), (238, 240, 236))
    dr = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 30)
    except OSError:
        font = ImageFont.load_default()
    for i, (n, im) in enumerate(zip(labels or names, ims)):
        x, y = (i % cols) * w, (i // cols) * (H + 40)
        sheet.paste(im, (x + (w - im.width) // 2, y + 40))
        dr.text((x + 16, y + 6), n, fill=(30, 30, 40), font=font)
    sheet.save(path)
