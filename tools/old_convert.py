"""Automatic conversion of an old textured Blockbench model into the Lasso For Eggs style,
keeping its bones (names, pivots, rest rotations) so its own animations carry over.

  cubes            flat colour: the median of their faces' texture, a little brighter
  rotated cubes    their own small bone (pivot = the cube's origin, rest = its rotation),
                   so every block is axis-aligned inside a bone
  flat planes      (feathers, fins, crests) voxelised from their texture's alpha into
                   real blocks PLANE_DEPTH deep, merged into rectangles per colour
  dropped          groups/elements named in DROP, and elements on DROP_TEXTURES (effects)

Run: python3 tools/old_convert.py <old.bbmodel> <Name> <k> [out_dir]
k is studs per old unit. Writes designs/converted/<Name>.bbmodel with idle, walk and
gallop taken from the old animations (ANIMS) and a preview.
"""

import base64
import io
import json
import os
import sys
import uuid

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
import convert_designs as C  # noqa: E402
from convert_designs import Conv  # noqa: E402
from partlib import render  # noqa: E402

PLANE_DEPTH = 2.0  # old units
CELL = 1.0  # old units: voxel size for planes
BRIGHTEN = 1.12


def load(path):
    m = json.load(open(path))
    if "groups" not in m:  # format 4.x before 4.10: groups live in the outliner
        gs = []

        def walk(o):
            for c in o:
                if isinstance(c, dict):
                    gs.append(c)
                    walk(c["children"])

        walk(m["outliner"])
        m["groups"] = gs
    return m


def texture_arrays(m):
    out = []
    for t in m["textures"]:
        src = t.get("source", "")
        img = Image.open(io.BytesIO(base64.b64decode(src.split(",", 1)[1]))).convert("RGBA")
        out.append(np.array(img))
    return out


def face_pixels(m, texs, fc):
    T = texs[fc["texture"]]
    sx = T.shape[1] / m["resolution"]["width"]
    sy = T.shape[0] / m["resolution"]["height"]
    u0, v0, u1, v1 = fc["uv"]
    a, b = sorted((int(round(u0 * sx)), int(round(u1 * sx))))
    c, d = sorted((int(round(v0 * sy)), int(round(v1 * sy))))
    px = T[c:max(d, c + 1), a:max(b, a + 1)].reshape(-1, 4)
    return px[px[:, 3] > 128][:, :3]


def bright(c):
    return tuple(int(min(255, v * BRIGHTEN)) for v in c)


def cube_color(m, texs, e):
    px = [face_pixels(m, texs, fc) for fc in e["faces"].values() if fc.get("texture") is not None]
    px = [p for p in px if len(p)]
    if not px:
        return None
    return bright(tuple(int(v) for v in np.median(np.concatenate(px), 0)))


# face -> (u axis, sign of u direction at u0 side picks 'to'), v axis
FACE_AXES = {"north": (0, True, 1), "south": (0, False, 1), "east": (2, True, 1),
             "west": (2, False, 1), "up": (0, False, 2), "down": (0, False, 2)}


def plane_blocks(m, texs, e, thin):
    """Rectangles (lo, hi, colour) in old units voxelising a flat element from its texture."""
    lo, hi = np.array(e["from"], float), np.array(e["to"], float)
    face = {0: ("east", "west"), 1: ("up", "down"), 2: ("north", "south")}[thin]
    fc = next((e["faces"][f] for f in face if f in e["faces"] and e["faces"][f].get("texture") is not None), None)
    if fc is None:
        return []
    ua, flip_u, va = FACE_AXES[face[0] if e["faces"].get(face[0]) is fc else face[1]]
    T = texs[fc["texture"]]
    sx = T.shape[1] / m["resolution"]["width"]
    sy = T.shape[0] / m["resolution"]["height"]
    u0, v0, u1, v1 = fc["uv"]
    nu = max(1, int(round(abs(hi[ua] - lo[ua]) / CELL)))
    nv = max(1, int(round(abs(hi[va] - lo[va]) / CELL)))
    grid = {}
    for i in range(nu):
        for j in range(nv):
            # texel at the cell centre
            fu, fv = (i + 0.5) / nu, (j + 0.5) / nv
            px = T[min(T.shape[0] - 1, int((v0 + (v1 - v0) * fv) * sy)), min(T.shape[1] - 1, int((u0 + (u1 - u0) * fu) * sx))]
            if px[3] > 128:
                grid[i, j] = tuple(int(v) for v in px[:3])
    if not grid:
        return []
    # snap cells to the plane's few main colours so rectangles merge
    cols = np.array(list(grid.values()), float)
    centres = [np.median(cols, 0)]
    for _ in range(2):
        d = np.min([np.linalg.norm(cols - c, axis=1) for c in centres], 0)
        if d.max() < 40:
            break
        centres.append(cols[d.argmax()])
    for _ in range(5):
        lab = np.argmin([np.linalg.norm(cols - c, axis=1) for c in centres], 0)
        centres = [np.median(cols[lab == k], 0) if (lab == k).any() else centres[k] for k in range(len(centres))]
    keys = list(grid)
    lab = dict(zip(keys, np.argmin([np.linalg.norm(cols - c, axis=1) for c in centres], 0)))
    # greedy rectangles
    used, rects = set(), []
    for j in range(nv):
        for i in range(nu):
            if (i, j) not in lab or (i, j) in used:
                continue
            k = lab[i, j]
            w = 1
            while (i + w, j) in lab and lab[i + w, j] == k and (i + w, j) not in used:
                w += 1
            h = 1
            while all((i + x, j + h) in lab and lab[i + x, j + h] == k and (i + x, j + h) not in used for x in range(w)):
                h += 1
            for x in range(w):
                for y in range(h):
                    used.add((i + x, j + y))
            rects.append((i, j, w, h, bright(tuple(int(v) for v in centres[k]))))
    # u0 side of the texture is at 'to' on flipped faces; v0 is at the top (y 'to') for sides
    out = []
    du, dv = (hi[ua] - lo[ua]) / nu, (hi[va] - lo[va]) / nv
    mid = (lo[thin] + hi[thin]) / 2
    for i, j, w, h, col in rects:
        a, b = (lo[ua] + i * du, lo[ua] + (i + w) * du)
        if flip_u:
            a, b = hi[ua] - (i + w) * du, hi[ua] - i * du
        if va == 1:  # side faces: v grows downward
            c, d = hi[1] - (j + h) * dv, hi[1] - j * dv
        else:
            c, d = lo[va] + j * dv, lo[va] + (j + h) * dv
        blo, bhi = np.zeros(3), np.zeros(3)
        blo[ua], bhi[ua] = a, b
        blo[va], bhi[va] = c, d
        blo[thin], bhi[thin] = mid - PLANE_DEPTH / 2, mid + PLANE_DEPTH / 2
        out.append((blo, bhi, col))
    return out


def convert(path, name, k, rarity="Epic", drop=("shadow", "hitbox"), drop_textures=(), skip_planes=()):
    """(Conv animal, old model) with the old bones and blocks."""
    m = load(path)
    texs = texture_arrays(m)
    a = Conv(name, rarity, k)
    gmap = {g["uuid"]: g for g in m["groups"]}
    n = {"i": 0}

    def walk(node, parent):
        for c in node:
            if isinstance(c, dict):
                g = gmap[c["uuid"]]
                if g["name"] in drop:
                    continue
                if g["name"] == "root" and parent is None:
                    a.pivots["root"] = tuple(np.array(g["origin"], float) * k)
                else:
                    a.bone(g["name"], parent or "root", g["origin"], g.get("rotation") or (0, 0, 0))
                walk(c["children"], g["name"])
            else:
                e = next(x for x in m["elements"] if x["uuid"] == c)
                faces = [fc for fc in e["faces"].values() if fc.get("texture") is not None]
                if e["name"] in drop or not faces or all(fc["texture"] in drop_textures for fc in faces):
                    continue
                bone = parent or "root"
                rot = e.get("rotation") or (0, 0, 0)
                n["i"] += 1
                if any(abs(r) > 1e-6 for r in rot):
                    bone = a.bone(f"{bone}_r{n['i']}", bone, e["origin"], rot)
                lo, hi = np.array(e["from"], float), np.array(e["to"], float)
                size = hi - lo
                if size.min() < 0.05:
                    if n["i"] in skip_planes:
                        continue
                    for j, (blo, bhi, col) in enumerate(plane_blocks(m, texs, e, int(np.argmin(size)))):
                        a.b(f"Plain{n['i']}_{j}", blo, bhi, col, bone)
                    continue
                col = cube_color(m, texs, e)
                if col:
                    a.b(f"P{n['i']}", lo, hi, col, bone)

    walk(m["outliner"], None)
    a.meta = {"seat": (0, 0, 0), "neck_loop": {"center": (0, 0, 0), "radius": 1}}
    return a, m


def carry_animations(old, model, k, picks):
    """picks: {new name: (old name, time scale)}. Copies keyframes by bone name; positions
    scale by k * 10 (old units to Blockbench units at 10 per stud); every animation loops."""
    groups = {g["name"]: g["uuid"] for g in model["groups"]}
    oldg = {g["uuid"]: g["name"] for g in old["groups"]}
    anims = {x["name"]: x for x in old["animations"]}
    out = []
    for new, (src, ts) in picks.items():
        an = anims[src]
        animators = {}
        for uid, ar in an["animators"].items():
            gname = ar.get("name") or oldg.get(uid)
            if gname not in groups or not ar.get("keyframes"):
                continue
            kfs = []
            for kf in ar["keyframes"]:
                if kf["channel"] not in ("rotation", "position"):
                    continue
                dp = []
                for p in kf["data_points"]:
                    q = {}
                    for c in "xyz":
                        v = float(p.get(c, 0) or 0)
                        q[c] = round(v * k * 10 if kf["channel"] == "position" else v, 4)
                    dp.append(q)
                kfs.append({**{x: kf[x] for x in kf if x not in ("data_points", "time", "uuid")},
                            "data_points": dp, "time": round(kf["time"] * ts, 4), "uuid": str(uuid.uuid4())})
            animators[groups[gname]] = {"name": gname, "type": "bone", "keyframes": kfs}
        out.append({"uuid": str(uuid.uuid4()), "name": new, "loop": "loop", "override": False,
                    "length": round(an["length"] * ts, 4), "snapping": 24, "selected": False,
                    "anim_time_update": "", "blend_weight": "", "start_delay": "", "loop_delay": "",
                    "animators": animators})
    model["animations"] = out


def preview(parts, path, W=320):
    lo, hi = C.bounds(parts)
    c = (lo + hi) / 2
    r = np.linalg.norm(hi - lo) / 2
    ims = []
    for v in ((-19, 9, -21), (0, 3, -30), (-30, 4, 0)):
        v = np.array(v, float)
        eye = c + v / np.linalg.norm(v) * r / np.tan(np.radians(17)) * 1.05
        ims.append(render(parts, eye=eye, target=c, W=W, H=W, fov=34))
    sheet = Image.new("RGB", (W * len(ims), W))
    for i, im in enumerate(ims):
        sheet.paste(im, (i * W, 0))
    sheet.save(path)


def horse_side_eyes(a, bone, x, yc, zc, k):
    """The Horse's eyes (1x1 stud white plate, 0.5 x 0.6 pupil toward the front, 0.1 up from
    the bottom) on the +-x faces at |x| (old units), centred at yc, zc (old units)."""
    for side, sx in (("L", -1), ("R", 1)):
        xs = sx * x * k
        y0, z0 = yc * k - 0.5, zc * k - 0.5
        x0, x1 = sorted((xs, xs + sx * A.PLATE))
        a.box("Eye" + side, (x0, y0, z0), (x1, y0 + 1, z0 + 1), A.EYE_WHITE, bone)
        x0, x1 = sorted((xs, xs + sx * (A.PLATE + 0.03)))
        a.box("Pupil" + side, (x0, y0 + 0.1, z0 + A.PUPIL_BACK), (x1, y0 + 0.7, z0 + 0.5 + A.PUPIL_BACK), A.PUPIL, bone)
