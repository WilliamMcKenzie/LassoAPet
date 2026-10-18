"""Shared helpers for World 3's Cnidaria (the reef, biome 4) animals: a small builder over
the Blockbench cube/pyramid elements tools/orange_butterfly.py and tools/living_crystal.py use,
and one finish() that writes the .bbmodel, the Roblox model and the previews.

Every model is built in Blockbench's ZYX Euler order with every bone resting at 0: tilts are
baked into the cubes (cube rotation) and pyramids (their vertices). Parts named Glow... turn
Neon in game (bbmodel_to_luau.NEON). Studs in, Blockbench units (x10) out.

    from cnidaria_kit import Build, finish
    b = Build("MoonJellyfish", {"bell": (..), ...})
    root = b.group("root", (0, 6, 0))
    b.box(root, "Bell", (0, 6, 0), (6, 3, 6), "bell")
    ...
    finish(b.model(), animations(), ...)
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
import snake_design as S  # noqa: E402

S.SIZE = 1.0  # (group pivots in plain studs, like the cubes)
import angel_boss as AB  # noqa: E402  (box, axis_rot, rot_to_zyx)
from horse_rig import write_animations  # noqa: E402
from partlib import render  # noqa: E402
from snake_rig import track  # noqa: E402,F401  (re-exported for the animal scripts)
import animal_designs as A  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
DESIGNS = os.path.join(ROOT, "designs", "cnidaria")
RENDERS = "/mnt/project-files/world3/cnidaria/renders"
TAU = 2 * math.pi
BG = (232, 244, 250)  # a pale sea-foam backdrop for the previews
R = AB.axis_rot


def rot(*turns):
    """A rotation from (axis, degrees) pairs, applied right to left like matrix products:
    rot(("y", 30), ("x", 10)) tilts about X first, then turns about Y."""
    M = np.eye(3)
    for axis, deg in turns:
        M = M @ R(axis, deg)
    return M


def frame_to(p0, p1, roll=0.0):
    """Rotation whose local +Y runs from p0 to p1 (for limbs, tentacle links, spines)."""
    d = np.array(p1, float) - np.array(p0, float)
    d /= np.linalg.norm(d)
    ref = np.array([0, 0, 1.0]) if abs(d[2]) < 0.95 else np.array([1.0, 0, 0])
    x = np.cross(d, ref)
    x /= np.linalg.norm(x)
    z = np.cross(x, d)
    M = np.stack([x, d, z], axis=1)
    return M @ R("y", roll)


class Build:
    def __init__(self, name, colors):
        self.name = name
        self.colors = dict(colors)
        self.tex = {n: i for i, n in enumerate(self.colors)}
        self.elements, self.groups, self.outliner = [], [], []

    def group(self, name, pivot, parent=None):
        g = S.group(name, pivot)
        self.groups.append(g)
        node = {"uuid": g["uuid"], "isOpen": True, "children": []}
        (parent["children"] if parent is not None else self.outliner).append(node)
        return node

    def _put(self, node, e):
        self.elements.append(e)
        node["children"].append(e["uuid"])
        return e

    def box(self, node, name, center, size, color, M=None):
        """A cube in studs centred on `center`, its axes turned by M."""
        return self._put(node, AB.box(name, center, size, self.tex[color], M))

    def bar(self, node, name, p0, p1, w, color, d=None, roll=0.0, over=0.0):
        """A block running from p0 to p1, w wide (and d deep), poking `over` past each end."""
        p0, p1 = np.array(p0, float), np.array(p1, float)
        L = np.linalg.norm(p1 - p0) + 2 * over
        return self.box(node, name, (p0 + p1) / 2, (w, L, d if d is not None else w), color, frame_to(p0, p1, roll))

    def pyramid(self, node, name, base, hw, hd, h, color, M=None):
        """A pyramid on a hw x hd (half sizes) base centred at `base`, apex h along local +Y,
        turned by M. Vertices are baked (rotation 0), so any tilt converts."""
        M = np.eye(3) if M is None else M
        loc = {"b0": (-hw, 0, -hd), "b1": (hw, 0, -hd), "b2": (hw, 0, hd), "b3": (-hw, 0, hd), "t": (0, h, 0)}
        v = {k: [round(float(x) * S.BB, 4) for x in M @ np.array(p, float)] for k, p in loc.items()}
        faces = {"base": ["b0", "b1", "b2", "b3"], "s0": ["b0", "b1", "t"], "s1": ["b1", "b2", "t"],
                 "s2": ["b2", "b3", "t"], "s3": ["b3", "b0", "t"]}
        t = self.tex[color]
        return self._put(node, {"name": name, "type": "mesh", "uuid": S.uid(), "color": 0,
                                "origin": [round(float(c) * S.BB, 4) for c in base], "rotation": [0, 0, 0],
                                "vertices": v, "faces": {k: {"texture": t, "vertices": vs, "uv": {q: [0, 0] for q in vs}}
                                                         for k, vs in faces.items()}})

    def spike(self, node, name, base, tip, w, color, d=None):
        """A pyramid from a w x d base at `base` to the point `tip`."""
        base, tip = np.array(base, float), np.array(tip, float)
        return self.pyramid(node, name, base, w / 2, (d or w) / 2, np.linalg.norm(tip - base), color, frame_to(base, tip))

    def eye(self, node, name, center, normal, size, white="white", pupil="pupil", look=(0, 0), glow=False):
        """A googly plate eye facing `normal`: a white plate and a pupil plate just in front."""
        n = np.array(normal, float)
        n /= np.linalg.norm(n)
        # local +Z = the eye's facing; plates are thin in z
        up = np.array([0, 1.0, 0]) if abs(n[1]) < 0.9 else np.array([0, 0, 1.0])
        x = np.cross(up, n)
        x /= np.linalg.norm(x)
        y = np.cross(n, x)
        M = np.stack([x, y, n], axis=1)
        c = np.array(center, float)
        w, h = (size, size * 1.15) if np.isscalar(size) else size
        pre = "Glow" if glow else ""
        self.box(node, pre + "Eye" + name, c, (w, h, 0.05), white, M)
        off = x * look[0] * w * 0.2 + y * look[1] * h * 0.2
        self.box(node, "Pupil" + name, c + n * 0.05 + off, (w * 0.5, h * 0.5, 0.05), pupil, M)

    def scale(self, k):
        for e in self.elements:
            for key in ("from", "to", "origin"):
                if key in e:
                    e[key] = [round(v * k, 4) for v in e[key]]
            if e["type"] == "mesh":
                e["vertices"] = {n: [round(c * k, 4) for c in v] for n, v in e["vertices"].items()}
        for g in self.groups:
            g["origin"] = [round(v * k, 4) for v in g["origin"]]

    def model(self):
        m = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
        m.update(name=self.name, elements=self.elements, groups=self.groups, outliner=self.outliner, animations=[],
                 textures=[S.solid_texture(n, c) for n, c in self.colors.items()])
        m.setdefault("meta", {})["format_version"] = "5.0"
        return m


def on_light(im, pad=50):
    box = im.getbbox()
    if not box:
        return im.convert("RGB")
    x0, y0, x1, y1 = box
    im = im.crop((x0 - pad, y0 - pad, x1 + pad, y1 + pad))
    bg = Image.new("RGBA", im.size, BG + (255,))
    bg.alpha_composite(im)
    return bg.convert("RGB")


def roblox_parts(m):
    """How many Roblox parts the converter makes: cubes 1, pyramids 4."""
    return sum(4 if e["type"] == "mesh" and len(e["vertices"]) == 5 else 1 for e in m["elements"])


def finish(m, anims, hero, sheet_target=(0, 6, 0), sheet_dist=1.0, gif_cam=None, out=RENDERS, luau=False):
    """Write designs/cnidaria/<Name>.bbmodel (with animations), the preview <Name>.png (hero:
    dict(eye, target, fov)), a four-view sheet beside a horse for scale, and with --gif the
    idle/walk/gallop gif. luau=True also writes src/shared/Animals/<Name>Model.luau."""
    name = m["name"]
    os.makedirs(out, exist_ok=True)
    os.makedirs(DESIGNS, exist_ok=True)
    if anims:
        write_animations(m, {g["name"]: g for g in m["groups"]}, anims)
    path = os.path.join(DESIGNS, name + ".bbmodel")
    with open(path, "w") as f:
        json.dump(m, f, separators=(",", ":"))
    if luau:
        import bbmodel_to_luau
        bbmodel_to_luau.ORDER = "ZYX"
        cwd = os.getcwd()
        os.chdir(ROOT)
        try:
            bbmodel_to_luau.main(os.path.join("designs", "cnidaria", name + ".bbmodel"),
                                 os.path.join("src", "shared", "Animals", name + "Model.luau"))
        finally:
            os.chdir(cwd)
    parts = S.posed(m)
    pts = np.vstack([q for p in parts for q in p.polys])
    lo, hi = pts.min(0), pts.max(0)
    print(name, "elements", len(m["elements"]), "roblox parts", roblox_parts(m), "size", (hi - lo).round(1),
          "low", round(lo[1], 2))
    on_light(render(parts, W=1200, H=1000, transparent=True, **hero)).save(os.path.join(out, name + ".png"))
    from horse_rig import pose
    hparts = pose(A.qm_horse("A"), None, 0)
    span = max(hi - lo)
    for p in hparts:
        p.polys = [q + np.array([hi[0] + 6, 0, 0]) for q in p.polys]
    k = sheet_dist * max(1.0, span / 18)
    tx, ty, tz = sheet_target
    cams = [dict(eye=(tx - 24 * k, ty + 16 * k, tz - 32 * k), target=(tx + 4, ty, tz)),
            dict(eye=(tx, ty + 40 * k, tz + 6), target=sheet_target),
            dict(eye=(tx + 34 * k, ty + 4 * k, tz), target=sheet_target),
            dict(eye=(tx + 14 * k, ty + 14 * k, tz + 26 * k), target=sheet_target)]
    W, H = 640, 480
    sheet = Image.new("RGB", (W * 2, H * 2))
    for i, cam in enumerate(cams):
        sheet.paste(render(parts + (hparts if i == 0 else []), W=W, H=H, fov=40, **cam), ((i % 2) * W, (i // 2) * H))
    sheet.save(os.path.join(os.environ.get("SHEET_DIR", out), name + "_sheet.png"))
    if "--gif" in sys.argv and m["animations"]:
        cam = gif_cam or dict(eye=(tx - 24 * k, ty + 14 * k, tz - 28 * k), target=sheet_target)
        side = dict(eye=(tx + 34 * k, ty + 4 * k, tz), target=sheet_target)
        frames = []
        for an, n, loops in (("idle", 24, 1), ("walk", 12, 2), ("gallop", 8, 4)):
            anim = next((a for a in m["animations"] if a["name"] == an), None)
            if not anim:
                continue
            for _ in range(loops):
                for j in range(n):
                    ps = S.posed(m, anim, anim["length"] * j / n)
                    im = Image.new("RGB", (880, 360))
                    im.paste(render(ps, W=440, H=360, fov=40, **cam), (0, 0))
                    im.paste(render(ps, W=440, H=360, fov=40, **side), (440, 0))
                    frames.append(A.label(im, [an] * 2))
        A.gif(os.path.join(os.environ.get("SHEET_DIR", out), name + "_anims.gif"), frames, fps=20)
    return m
