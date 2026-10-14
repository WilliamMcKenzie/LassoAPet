"""Shared builder for World 3's Garden animals (tools/garden_*.py), in the Hawkmoth's style
(tools/hawkmoth.py): free-form cubes turned by a rotation matrix (baked into the cube, Blockbench
ZYX) and pyramid meshes, bones as groups that all rest at 0.

    g = Garden("Ladybug", {"red": (220, 30, 40), ...})
    root = g.group("root", (0, 3, 0))
    g.box(root, "Shell", (0, 3, 0), (5, 2, 6), "red")
    g.eyes(root, ...)
    g.finish(animations)            # floor, animations, save designs/garden/<Name>.bbmodel, renders

Part names: Eye/Pupil plain (no studs), Glow... Neon. Convert with bbmodel_to_luau.py --zyx.
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
import angel_boss as AB  # noqa: E402  (sets S.SIZE = 1; box, axis_rot)
from partlib import render  # noqa: E402
import animal_designs as A  # noqa: E402
from horse_rig import write_animations  # noqa: E402
from snake_rig import track  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = "/mnt/project-files/world3/garden"
TAU = 2 * math.pi
R = AB.axis_rot
EYE_WHITE = (255, 255, 255)
PUPIL = (24, 22, 30)
sin = math.sin


def Rm(*turns):
    """Rm(("y", 30), ("x", -20)) = Ry(30) @ Rx(-20): the last turn applies first."""
    M = np.eye(3)
    for ax, d in turns:
        M = M @ R(ax, d)
    return M


class Garden:
    def __init__(self, name, colors, group="garden"):
        self.name = name
        colors = dict(colors)
        colors.setdefault("eyewhite", EYE_WHITE)
        colors.setdefault("pupil", PUPIL)
        self.colors = colors
        self.tex = {n: i for i, n in enumerate(colors)}
        self.elements, self.groups, self.outliner = [], [], []
        self.path = os.path.join(ROOT, "designs", group, name + ".bbmodel")
        self.count = {}

    # ------------------------------------------------------------ building
    def group(self, name, pivot, parent=None):
        g = S.group(name, pivot)
        self.groups.append(g)
        node = {"uuid": g["uuid"], "isOpen": True, "children": []}
        (parent["children"] if parent is not None else self.outliner).append(node)
        return node

    def _name(self, name):
        k = self.count.get(name, 0)
        self.count[name] = k + 1
        return name if k == 0 else f"{name}{k + 1}"

    def put(self, node, e):
        self.elements.append(e)
        node["children"].append(e["uuid"])
        return e

    def box(self, node, name, center, size, col, M=None):
        return self.put(node, AB.box(self._name(name), center, size, self.tex[col], M))

    def pyr(self, node, name, base, d, L, hw, ht=None, col="black", wv=None):
        """A pyramid: base rectangle centred on `base` (half sizes hw, ht), apex L along d."""
        ht = hw if ht is None else ht
        d = np.array(d, float) / np.linalg.norm(d)
        if wv is None:
            wv = np.array([1.0, 0, 0]) if abs(d[0]) < 0.9 else np.array([0, 0, 1.0])
        wv = np.array(wv, float)
        wv = wv - d * (wv @ d)
        wv /= np.linalg.norm(wv)
        tv = np.cross(d, wv)
        b = np.array(base, float)
        pts = [b - wv * hw - tv * ht, b + wv * hw - tv * ht, b + wv * hw + tv * ht, b - wv * hw + tv * ht, b + d * L]
        v = {f"v{i}": [round(float(x) * S.BB, 4) for x in q] for i, q in enumerate(pts)}
        faces = {"base": ["v0", "v1", "v2", "v3"], "s0": ["v0", "v1", "v4"], "s1": ["v1", "v2", "v4"],
                 "s2": ["v2", "v3", "v4"], "s3": ["v3", "v0", "v4"]}
        t = self.tex[col]
        return self.put(node, {"name": self._name(name), "type": "mesh", "uuid": S.uid(), "color": 0,
                               "origin": [0, 0, 0], "rotation": [0, 0, 0], "vertices": v,
                               "faces": {k: {"texture": t, "vertices": vs, "uv": {q: [0, 0] for q in vs}}
                                         for k, vs in faces.items()}})

    def hull(self, node, name, pts, col):
        """A low-poly mesh: the convex hull of `pts` (studs), flat triangles. With
        bbmodel_to_luau.py --meshes, every non-plain element on a bone in one colour
        becomes one MeshPart."""
        pts = np.array(pts, float)
        tris = hull_tris(pts)
        keys, v = {}, {}
        for t in tris:
            for q in t:
                k = tuple(np.round(q, 5))
                if k not in keys:
                    keys[k] = f"v{len(keys)}"
                    v[keys[k]] = [round(float(x) * S.BB, 4) for x in q]
        t_ = self.tex[col]
        faces = {}
        for i, t in enumerate(tris):
            vs = [keys[tuple(np.round(q, 5))] for q in t]
            faces[f"f{i}"] = {"texture": t_, "vertices": vs, "uv": {q: [0, 0] for q in vs}}
        return self.put(node, {"name": self._name(name), "type": "mesh", "uuid": S.uid(), "color": 0,
                               "origin": [0, 0, 0], "rotation": [0, 0, 0], "vertices": v, "faces": faces})

    def spike(self, node, name, base, d, L, w, col, shaft=0.0, shaft_col=None):
        """A cube shaft (optional) plus a pyramid tip, pointing along d."""
        d = np.array(d, float) / np.linalg.norm(d)
        b = np.array(base, float)
        if shaft > 0:
            M = frame(d)
            self.box(node, name + "Shaft", b + d * shaft / 2, (w * 2, shaft, w * 2), shaft_col or col, M)
            b = b + d * shaft
        return self.pyr(node, name, b, d, L, w, w, col)

    def eye(self, node, side, center, size, normal=(0, 0, -1), pupil=0.55, look=(0, 0), glow=False, white="eyewhite"):
        """A googly plate eye: a white plate facing `normal`, a dark pupil plate on its face,
        nudged by `look` (fractions of the eye size, across and up)."""
        n = np.array(normal, float)
        n /= np.linalg.norm(n)
        M = frame(n)  # local y along the normal
        c = np.array(center, float)
        w, h = (size, size) if np.isscalar(size) else size
        self.box(node, f"Eye{side}", c, (w, 0.2, h), white, M)
        across, upv = M @ np.array([1.0, 0, 0]), -(M @ np.array([0, 0, 1.0]))  # local z points down
        pc = c + n * 0.13 + across * look[0] * w + upv * look[1] * h
        self.box(node, f"{'Glow_Pupil' if glow else 'Pupil'}{side}", pc, (w * pupil, 0.08, h * pupil),
                 glow or "pupil", M)

    # ------------------------------------------------------------ output
    def model(self):
        m = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
        m.update(name=self.name, elements=self.elements, groups=self.groups, outliner=self.outliner, animations=[],
                 textures=[S.solid_texture(n, c) for n, c in self.colors.items()])
        m.setdefault("meta", {})["format_version"] = "5.0"
        return m

    def finish(self, anims=None, gap=0.0, out=OUT, lineup_cam=None):
        m = self.model()
        shift = floor(m, gap)
        if anims:
            write_animations(m, {g["name"]: g for g in m["groups"]}, anims(m) if callable(anims) else anims)
        os.makedirs(os.path.dirname(self.path), exist_ok=True)
        os.makedirs(os.path.join(out, "renders"), exist_ok=True)
        for p in (self.path, os.path.join(out, self.name + ".bbmodel")):
            with open(p, "w") as f:
                json.dump(m, f, separators=(",", ":"))
        parts = posed(m)
        P = np.concatenate([q for p in parts for q in p.polys])
        lo, hi = P.min(0), P.max(0)
        print(self.name, "elements", len(m["elements"]), "bones", len(m["groups"]), "shift", round(shift, 2),
              "size", (hi - lo).round(1))
        hero(parts).save(os.path.join(out, "renders", self.name + ".png"))
        sheet(parts).save(os.path.join(out, self.name + "_sheet.png"))
        return m


def frame(d):
    """A rotation whose local +y points along d (local x kept as level as possible)."""
    d = np.array(d, float) / np.linalg.norm(d)
    ref = np.array([0, 1.0, 0]) if abs(d[1]) < 0.95 else np.array([0, 0, -1.0])
    x = np.cross(ref, d)
    if np.linalg.norm(x) < 1e-6:
        x = np.array([1.0, 0, 0])
    x /= np.linalg.norm(x)
    z = np.cross(x, d)
    return np.stack([x, d, z], 1)


def floor(m, gap=0.0):
    lo = min(q[:, 1].min() for p in S.posed(m) for q in p.polys)
    d = (gap - lo) * S.BB
    for e in m["elements"]:
        if e["type"] == "mesh":
            e["vertices"] = {k: [v[0], round(v[1] + d, 4), v[2]] for k, v in e["vertices"].items()}
        for k in ("from", "to", "origin"):
            if k in e and not (e["type"] == "mesh" and k == "origin"):
                e[k][1] = round(e[k][1] + d, 4)
    for g in m["groups"]:
        g["origin"][1] = round(g["origin"][1] + d, 4)
    return gap - lo


def posed(m, anim=None, t=0.0):
    ps = S.posed(m, anim, t)
    for p in ps:
        if p.name.startswith(("Eye", "Pupil", "Glow", "Smooth")):
            p.plain = True
        if p.name.startswith("Glow"):
            p.neon = True
    return ps


def bounds(parts):
    P = np.concatenate([q for p in parts for q in p.polys])
    return P.min(0), P.max(0)


def cam(parts, view=(-14, 8, -24), fov=30, fill=1.0):
    lo, hi = bounds(parts)
    c = (lo + hi) / 2
    r = np.linalg.norm(hi - lo) / 2
    v = np.array(view, float)
    return dict(eye=c + v / np.linalg.norm(v) * r / np.tan(np.radians(fov / 2)) * fill, target=c, fov=fov)


def hero(parts, W=1000, H=900, view=(-14, 8, -24)):
    img = render(parts, W=W, H=H, transparent=True, **cam(parts, view))
    bg = Image.new("RGBA", img.size, (238, 240, 236, 255))
    bg.alpha_composite(img)
    return bg.convert("RGB")


def sheet(parts):
    Wd, Ht = 640, 520
    out = Image.new("RGB", (Wd * 2, Ht * 2))
    for i, v in enumerate([(-14, 8, -24), (0, 4, -30), (24, 10, 16), (-30, 6, 0)]):
        out.paste(render(parts, W=Wd, H=Ht, **cam(parts, v)), ((i % 2) * Wd, (i // 2) * Ht))
    return out


def gif(m, out_path, cams=((0, 4, -30), (-30, 6, 0)), names=(("idle", 24, 1), ("walk", 14, 2), ("gallop", 10, 2))):
    base = posed(m)
    cs = [cam(base, v, fov=40, fill=1.15) for v in cams]
    Wd, Ht = 440, 360
    frames = []
    for name, n, loops in names:
        anim = next(a for a in m["animations"] if a["name"] == name)
        for _ in range(loops):
            for k in range(n):
                ps = posed(m, anim, anim["length"] * k / n)
                im = Image.new("RGB", (Wd * len(cs), Ht))
                for i, c in enumerate(cs):
                    im.paste(render(ps, W=Wd, H=Ht, **c), (i * Wd, 0))
                frames.append(A.label(im, [name] * len(cs)))
    A.gif(out_path, frames, fps=20)


# ------------------------------------------------------------ animation helpers

# ------------------------------------------------------------ low-poly shapes (point sets for Garden.hull)

def hull_tris(pts, eps=1e-4):
    """Outward triangles (each 3x3) of the convex hull of a small point set, each flat
    face fanned once (no scipy: every plane through three points that has all the
    others behind it is a face)."""
    P = np.unique(np.round(np.array(pts, float), 5), axis=0)
    n = len(P)
    i, j, k = np.array([(a, b, c) for a in range(n) for b in range(a + 1, n) for c in range(b + 1, n)]).T
    N = np.cross(P[j] - P[i], P[k] - P[i])
    ok = np.linalg.norm(N, axis=1) > 1e-6
    N = N[ok] / np.linalg.norm(N[ok], axis=1)[:, None]
    i = i[ok]
    D = (P @ N.T) - np.einsum("ij,ij->i", P[i], N)  # [point, plane]
    out = np.all(D <= eps, 0)
    inn = np.all(D >= -eps, 0)
    planes = {}
    for q in np.nonzero(out | inn)[0]:
        nrm = N[q] if out[q] else -N[q]
        key = tuple(np.round(np.append(nrm, nrm @ P[i[q]]), 3))
        if key not in planes:
            planes[key] = (nrm, np.nonzero(np.abs(D[:, q]) <= eps)[0])
    tris = []
    for nrm, idx in planes.values():
        F = P[idx]
        c = F.mean(0)
        e1 = F[0] - c
        e1 /= np.linalg.norm(e1)
        e2 = np.cross(nrm, e1)
        F = F[np.argsort(np.arctan2((F - c) @ e2, (F - c) @ e1))]
        for t in range(1, len(F) - 1):
            tris.append(np.array([F[0], F[t], F[t + 1]]))
    return tris


def ellipsoid(c, r, seg=8, rings=4, M=None, cut=None, twist=0.5):
    """Points of a faceted ellipsoid: centre c, radii r (x, y, z), `seg` around Y and
    `rings` from pole to pole (alternate rings turned half a step, for chunky facets).
    cut: drop the points below this local y (a flat bottom), M turns it."""
    M = np.eye(3) if M is None else M
    r = np.array(r, float)
    pts = [(0, 1, 0), (0, -1, 0)]
    for i in range(1, rings):
        phi = math.pi * i / rings
        for k in range(seg):
            a = TAU * (k + twist * (i % 2)) / seg
            pts.append((math.sin(phi) * math.cos(a), math.cos(phi), math.sin(phi) * math.sin(a)))
    P = np.array(pts) * r
    if cut is not None:
        P[:, 1] = np.maximum(P[:, 1], cut)
    return (M @ P.T).T + np.array(c, float)


def dome(c, r, h, seg=10, rings=3, M=None, base=0.0):
    """A faceted dome: a ring of radius r (x, z: r may be a pair) at c, rising h; `base`
    adds a straight band below the ring that deep."""
    M = np.eye(3) if M is None else M
    rx, rz = (r, r) if np.isscalar(r) else r
    pts = [(0, h, 0)]
    for i in range(rings):
        phi = (math.pi / 2) * i / rings
        for k in range(seg):
            a = TAU * (k + 0.5 * (i % 2)) / seg
            pts.append((rx * math.cos(phi) * math.cos(a), h * math.sin(phi), rz * math.cos(phi) * math.sin(a)))
    if base:
        for k in range(seg):
            a = TAU * k / seg
            pts.append((rx * math.cos(a), -base, rz * math.sin(a)))
    return (M @ np.array(pts, float).T).T + np.array(c, float)


def prism(c, r, h, seg=8, top=1.0, M=None):
    """A faceted cylinder (top scales the top ring: < 1 tapers it) standing on c."""
    M = np.eye(3) if M is None else M
    rx, rz = (r, r) if np.isscalar(r) else r
    pts = []
    for y, s in ((0, 1.0), (h, top)):
        for k in range(seg):
            a = TAU * (k + 0.5) / seg
            pts.append((rx * s * math.cos(a), y, rz * s * math.sin(a)))
    return (M @ np.array(pts, float).T).T + np.array(c, float)


def plates(g, node, name, pts, dirs, col, fill=0.75, most=None, seg=8):
    """Flat round spots lying in the flat faces of hull(pts), sunk in a little: one in the face
    facing most along each direction in dirs (of those within ~30 degrees, the roomiest),
    centred in it and sized to fit inside its edges (fill of the room), so none overhangs an
    edge. They're meshes, so they merge into one MeshPart."""
    faces = {}
    for t in hull_tris(pts):
        n = np.cross(t[1] - t[0], t[2] - t[0])
        n /= np.linalg.norm(n)
        key = tuple(np.round(n, 3))
        faces.setdefault(key, (n, []))[1].extend(t)
    polys = []
    for n, P in faces.values():
        P = np.unique(np.round(np.array(P), 5), axis=0)
        c = P.mean(0)
        e1 = P[0] - c
        e1 /= np.linalg.norm(e1)
        e2 = np.cross(n, e1)
        P = P[np.argsort(np.arctan2((P - c) @ e2, (P - c) @ e1))]
        room = min(np.linalg.norm(np.cross(P[(i + 1) % len(P)] - P[i], c - P[i])) / np.linalg.norm(P[(i + 1) % len(P)] - P[i])
                   for i in range(len(P)))
        polys.append((n, c, room))
    used = set()
    for d in dirs:
        d = np.array(d, float) / np.linalg.norm(d)
        near = [i for i in range(len(polys)) if i not in used and polys[i][0] @ d > 0.85] or \
            [max((i for i in range(len(polys)) if i not in used), key=lambda i: polys[i][0] @ d)]
        k = max(near, key=lambda i: polys[i][2])
        used.add(k)
        n, c, room = polys[k]
        size = room * fill if most is None else min(room * fill, most)
        g.hull(node, name, prism(c - n * 0.15, size, 0.2, seg=seg, M=frame(n)), col)


def bands(c, r, cuts, seg=10, M=None, tips=True):
    """A faceted ellipsoid along its local z (centre c, radii r) cut into bands at the local
    z values `cuts` (from -r[2] to r[2]): one point set per band, rings shared at each cut so
    the bands meet flush (a striped bee's abdomen). tips: the end bands close to a point."""
    M = np.eye(3) if M is None else M
    r = np.array(r, float)

    def ring_at(z, twist=0.0):
        k = math.sqrt(max(0.0, 1 - (z / r[2]) ** 2))
        return [(r[0] * k * math.cos(TAU * (i + twist) / seg), r[1] * k * math.sin(TAU * (i + twist) / seg), z)
                for i in range(seg)]
    out = []
    for i, (z0, z1) in enumerate(zip(cuts, cuts[1:])):
        pts = ring_at(z0) + ring_at(z1) + ring_at((z0 + z1) / 2)
        if tips and i == 0:
            pts.append((0, 0, -r[2]))
        if tips and i == len(cuts) - 2:
            pts.append((0, 0, r[2]))
        out.append((M @ np.array(pts, float).T).T + np.array(c, float))
    return out


def legs(L, pairs, swing, n=16, axis=0):
    """{bone: track}: legs swing about X; pairs = [(bone, phase in turns)]."""
    out = {}
    for b, ph in pairs:
        def fn(u, ph=ph):
            v = [0.0, 0.0, 0.0]
            v[axis] = swing * sin(TAU * (u + ph))
            return tuple(v)
        out[b] = [track(L, fn, n)]
    return out


def rot(L, fn, n=16):
    return [track(L, fn, n)]


def bob(L, amp, freq=2, lean=0.0, n=16, roll=0.0, ph=0.0):
    """Root: a lean (X) plus a rocking roll, and an up-down bob in Blockbench units (0.1 stud)."""
    return [track(L, lambda u: (lean, 0, roll * sin(TAU * u)), n),
            track(L, lambda u: (0, amp * abs(sin(TAU * (u * freq / 2) + ph)) if freq else 0, 0), n, "position")]
