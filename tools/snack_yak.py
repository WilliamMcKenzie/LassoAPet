"""The Snack Yak (Tundra, medium) from QM's model (designs/snow/SnackYak_QM.bbmodel).

Run: python3 tools/snack_yak.py [out_dir]   rebuild designs/snow/SnackYak.bbmodel, render previews
then: python3 tools/bbmodel_to_luau.py --zyx designs/snow/SnackYak.bbmodel src/shared/Animals/SnackYakModel.luau

QM's file is a painted Blockbench model (made Blockbench's way, so rotations turn Z,
then Y, then X): a shaggy yak with a saddle, a fruit basket on its back, a stick
dangling carrots in front of its nose, and saddlebags with a ham and a fish in them.
QM asked for it 1:1, as a medium animal. This script keeps every block where QM put
it and:
  - gives each block one colour, the colour most of its paint is (Roblox parts are
    one colour each). Where one face is painted quite differently (the pink nose on
    the snout, the red mouth), that face's colour becomes a real slab of the block,
    cut from it, so the shape doesn't change;
  - turns QM's flat planes (carrot leaves, bangs, the rump fringe, the ham's and
    fish's tails) into thin real blocks, and bakes Blockbench's inflate into sizes;
  - names the parts and bones the game needs (head -> neck), moves pivots of bones
    with no rest rotation to their joints (doesn't move any block at rest), puts the
    ham and fish into their bags, and hangs the carrot stick off its own bone;
  - writes idle, walk and gallop.
bb_textured.py draws QM's painted original next to ours for comparison.
"""

import json
import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import horse_rig as HR  # noqa: E402
import snake_design as S  # noqa: E402
import animal_designs as A  # noqa: E402
from bb_textured import FACE_CORNERS, render_textured, textures as painted  # noqa: E402
from horse_rig import write_animations  # noqa: E402
from partlib import render  # noqa: E402
from snake_rig import track  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
SRC = os.path.join(ROOT, "designs", "snow", "SnackYak_QM.bbmodel")
MODEL = os.path.join(ROOT, "designs", "snow", "SnackYak.bbmodel")
TAU = 2 * math.pi

# QM's elements (all named "cube") by their index in the file
NAMES = {
    0: "Body", 13: "Fur", 29: "RumpFringe",
    14: "SaddleFront", 16: "SaddleSeat", 15: "SaddleBack",
    5: "Head", 4: "Snout", 6: "Mouth", 12: "Bangs", 7: "CheekFurR", 8: "CheekFurL",
    9: "HornR", 10: "HornRTip", 11: "HornRPoint", 34: "HornL", 33: "HornLTip", 32: "HornLPoint",
    2: "Thigh", 1: "Shin", 3: "Hoof", 36: "Thigh", 35: "Shin", 37: "Hoof",
    39: "Thigh", 38: "Shin", 40: "Hoof", 42: "Thigh", 41: "Shin", 43: "Hoof",
    21: "Basket", 22: "BasketRim",
    23: "Stick", 28: "StickGrip", 24: "StickTip",
    25: "Carrot", 27: "CarrotTip", 26: "CarrotLeaves", 30: "Carrot", 31: "CarrotTip",
    17: "Bag", 18: "BagFlap", 19: "BagStrap", 20: "BagBottom",
    44: "Bag", 47: "BagFlap", 45: "BagStrap", 46: "BagBottom",
    49: "Ham", 48: "HamBone", 56: "Ham", 55: "HamBone",
    50: "FishHead", 51: "FishBody", 52: "FishSpine", 53: "FishTail", 54: "FishFin",
    57: "FishHead", 61: "FishBody", 59: "FishSpine", 60: "FishTail", 58: "FishFin",
}
STICK = (23, 28, 24)  # the stick's blocks, onto their own bone
# bones: QM's name -> ours, and pivots (Blockbench units) for bones with no rest rotation
RENAME = {"head": "neck", "leg": "legFL", "leg2": "legFR", "leg3": "legBR", "leg4": "legBL",
          "fruits_Basket": "basket", "shark_bag": "bagR", "shark_bag2": "bagL"}
# legs pivot at the top-back edge of the thigh, the neck at the head's top-back edge
# (QM's rule: legs and neck only rotate forward from rest)
PIVOTS = {"root": (0, 14, 0), "neck": (0, 16, -12),
          "legFL": (-4.5, 9, -4), "legFR": (4.5, 9, -4), "legBL": (-4.5, 9, 11), "legBR": (4.5, 9, 11),
          "basket": (0, 22, 10.5), "bagR": (9.5, 19, 4.5), "bagL": (-9.5, 19, 4.5)}
PLANE = 1.0  # units: depth given to QM's flat planes
MIN_INFLATE = 0.3  # units: an inflated cover sits at least this far out of the block it covers
SLAB = 1.0  # units: depth of a differently painted face's slab
RINGS = {22: 1.0}  # the basket's rim: painted round its edge only, so it's open on top
FACE_AXIS = {"north": (2, -1), "south": (2, 1), "east": (0, 1), "west": (0, -1), "up": (1, 1), "down": (1, -1)}


# ---------------------------------------------------------------- colours

def face_pixels(e, f, texs):
    """{rgb: weight} of a face's painted texels, weighted by the area each covers."""
    arr, uw, uh = texs[f["texture"]]
    H, W = arr.shape[:2]
    u0, v0, u1, v1 = f["uv"]
    x0, x1 = sorted((u0 * W / uw, u1 * W / uw))
    y0, y1 = sorted((v0 * H / uh, v1 * H / uh))
    out = {}
    for cx in range(int(math.floor(x0 + 1e-6)), max(int(math.ceil(x1 - 1e-6)), int(math.floor(x0 + 1e-6)) + 1)):
        for cy in range(int(math.floor(y0 + 1e-6)), max(int(math.ceil(y1 - 1e-6)), int(math.floor(y0 + 1e-6)) + 1)):
            if 0 <= cx < W and 0 <= cy < H and arr[cy, cx, 3] > 0:
                k = tuple(int(c) for c in arr[cy, cx, :3])
                cover = (min(cx + 1, x1) - max(cx, x0)) * (min(cy + 1, y1) - max(cy, y0)) if x1 > x0 and y1 > y0 else 1
                out[k] = out.get(k, 0) + max(cover, 1e-3)
    return out


def dominant(hist, near=45):
    """(colour, share): the most painted colour, averaged with the shades close to it."""
    if not hist:
        return None, 0
    total = sum(hist.values())
    top = np.array(max(hist, key=hist.get), float)
    close = [(np.array(c, float), w) for c, w in hist.items() if np.linalg.norm(np.array(c) - top) < near]
    wsum = sum(w for _, w in close)
    rgb = sum(c * w for c, w in close) / wsum
    return tuple(int(round(v)) for v in rgb), wsum / total


def face_area(e, fname):
    d = np.abs(np.array(e["to"], float) - e["from"])
    ax = FACE_AXIS[fname][0]
    a, b = [d[i] for i in range(3) if i != ax]
    return max(a, 0.5) * max(b, 0.5)


def boxes(m):
    """(element index, R, origin, lo, hi) of every element, in model space at rest."""
    out = []
    for i, e in enumerate(m["elements"]):
        inf = e.get("inflate") or 0
        out.append((i, HR.rotm(e.get("rotation") or (0, 0, 0)), np.array(e.get("origin") or (0, 0, 0), float),
                    np.array(e["from"], float) - inf, np.array(e["to"], float) + inf))
    return out


def hidden(i, e, fname, bx):
    """A face is hidden if just outside its middle is inside another block."""
    ax, s = FACE_AXIS[fname]
    lo, hi = np.array(e["from"], float), np.array(e["to"], float)
    c = (lo + hi) / 2
    c[ax] = (hi if s > 0 else lo)[ax] + s * 0.6
    R, o = HR.rotm(e.get("rotation") or (0, 0, 0)), np.array(e.get("origin") or (0, 0, 0), float)
    p = R @ (c - o) + o
    for j, Rj, oj, loj, hij in bx:
        if j != i and j not in RINGS:
            q = Rj.T @ (p - oj) + oj
            if (q >= loj - 1e-6).all() and (q <= hij + 1e-6).all():
                return True
    return False


def colour_blocks(m):
    """Each element's colour, and the slabs to cut for differently painted faces:
    {index: (rgb, [(face, rgb)])}."""
    texs = painted(m)
    bx = boxes(m)
    out = {}
    for i, e in enumerate(m["elements"]):
        faces = {n: f for n, f in e["faces"].items() if f.get("texture") is not None}
        hists = {n: face_pixels(e, f, texs) for n, f in faces.items()}
        vis = {n for n in hists if hists[n] and not hidden(i, e, n, bx)} or {n for n in hists if hists[n]}
        total = {}
        for n in vis:
            h = hists[n]
            s = sum(h.values())
            for c, w in h.items():
                total[c] = total.get(c, 0) + w / s * face_area(e, n)
        rgb, _ = dominant(total)
        slabs = []
        for n in vis:
            fc, share = dominant(hists[n])
            if share >= 0.45 and np.linalg.norm(np.array(fc) - rgb) > 70:
                slabs.append((share * face_area(e, n), n, fc))
        slabs.sort(reverse=True)
        out[i] = (rgb, [(n, fc) for _, n, fc in slabs[:2]])
    return out


# ---------------------------------------------------------------- build

def groups_from_outliner(m):
    """QM's file keeps its bones inside the outliner (Blockbench 4.9); the converter
    and previews read them from a groups list, as Blockbench 4.10+ saves them."""
    if "groups" in m:
        return
    m["groups"] = []

    def walk(node):
        if isinstance(node, str):
            return node
        g = {k: v for k, v in node.items() if k != "children"}
        g.setdefault("rotation", [0, 0, 0])
        m["groups"].append(g)
        return {"uuid": node["uuid"], "isOpen": False, "children": [walk(c) for c in node["children"]]}

    m["outliner"] = [walk(n) for n in m["outliner"]]
    m["meta"]["format_version"] = "5.0"


def new_group(name, origin):
    return {"name": name, "uuid": S.uid(), "origin": list(origin), "rotation": [0, 0, 0],
            "export": True, "visibility": True, "isOpen": False, "color": 0}


def find_node(nodes, uuid):
    for n in nodes:
        if isinstance(n, dict):
            if n["uuid"] == uuid:
                return n
            r = find_node(n["children"], uuid)
            if r:
                return r
    return None


def parent_of(nodes, uuid, parent=None):
    for n in nodes:
        if n == uuid or (isinstance(n, dict) and n["uuid"] == uuid):
            return parent
        if isinstance(n, dict):
            r = parent_of(n["children"], uuid, n)
            if r:
                return r
    return None


def carve(e, fname, depth):
    """Split cube e along a face: (core, slab) with the slab `depth` deep on that face."""
    ax, s = FACE_AXIS[fname]
    lo, hi = list(e["from"]), list(e["to"])
    d = min(depth, (hi[ax] - lo[ax]) / 3)
    core, slab = json.loads(json.dumps(e)), json.loads(json.dumps(e))
    if s > 0:
        core["to"][ax] = round(hi[ax] - d, 4)
        slab["from"][ax] = round(hi[ax] - d, 4)
    else:
        core["from"][ax] = round(lo[ax] + d, 4)
        slab["to"][ax] = round(lo[ax] + d, 4)
    slab["uuid"] = S.uid()
    return core, slab


def texel_grid(e, fname, texs):
    """A face's texels in UV order: (grid[v][u] = rgb or None, corners TL, TR, BL in
    the element's own space)."""
    f = e["faces"][fname]
    arr, uw, uh = texs[f["texture"]]
    H, W = arr.shape[:2]
    u0, v0, u1, v1 = f["uv"]
    sx, sy = W / uw, H / uh
    nu, nv = round(abs(u1 - u0) * sx), round(abs(v1 - v0) * sy)

    def px(a0, a1, k, s):
        return int(round(a0 * s)) + k if a1 > a0 else int(round(a0 * s)) - 1 - k

    grid = [[None] * nu for _ in range(nv)]
    for kv in range(nv):
        for ku in range(nu):
            x, y = px(u0, u1, ku, sx), px(v0, v1, kv, sy)
            if 0 <= x < W and 0 <= y < H and arr[y, x, 3] > 0:
                grid[kv][ku] = tuple(int(c) for c in arr[y, x, :3])
    lo, hi = np.array(e["from"], float), np.array(e["to"], float)
    tl, tr, bl = (np.array([(lo, hi)[c[a]][a] for a in range(3)]) for c in FACE_CORNERS[fname])
    return grid, tl, tr, bl


def rects(grid):
    """Greedy cover of a grid's filled cells by rectangles (u0, v0, u1, v1), ends exclusive."""
    nv, nu = len(grid), len(grid[0])
    done = [[grid[v][u] is None for u in range(nu)] for v in range(nv)]
    out = []
    for v in range(nv):
        for u in range(nu):
            if done[v][u]:
                continue
            u1 = u
            while u1 < nu and not done[v][u1]:
                u1 += 1
            v1 = v + 1
            while v1 < nv and all(not done[v1][k] for k in range(u, u1)):
                v1 += 1
            for vv in range(v, v1):
                for uu in range(u, u1):
                    done[vv][uu] = True
            out.append((u, v, u1, v1))
    return out


def sprite_blocks(e, ax, texs):
    """QM's flat planes (carrot leaves, bangs, fringes, tails) as thin real blocks, one
    per rectangle of painted texels, each the colour most of it is."""
    pair = [n for n, (a, _) in FACE_AXIS.items() if a == ax]
    fname = max(pair, key=lambda n: sum(c is not None for row in texel_grid(e, n, texs)[0] for c in row)
                if e["faces"][n].get("texture") is not None else -1)
    grid, tl, tr, bl = texel_grid(e, fname, texs)
    nv, nu = len(grid), len(grid[0])
    out = []
    for u0, v0, u1, v1 in rects(grid):
        a = tl + u0 / nu * (tr - tl) + v0 / nv * (bl - tl)
        b = tl + u1 / nu * (tr - tl) + v1 / nv * (bl - tl)
        lo, hi = np.minimum(a, b), np.maximum(a, b)
        lo[ax], hi[ax] = lo[ax] - PLANE / 2, hi[ax] + PLANE / 2
        hist = {}
        for v in range(v0, v1):
            for u in range(u0, u1):
                hist[grid[v][u]] = hist.get(grid[v][u], 0) + 1
        out.append({**json.loads(json.dumps(e)), "uuid": S.uid(), "from": [round(x, 4) for x in lo],
                    "to": [round(x, 4) for x in hi], "rgb": dominant(hist)[0]})
    return out


def ring_blocks(e, width):
    """The four sides of a rim (open at the top), `width` thick."""
    lo, hi = e["from"], e["to"]
    out = []
    for name, (x0, x1, z0, z1) in (("Front", (lo[0], hi[0], lo[2], lo[2] + width)), ("Back", (lo[0], hi[0], hi[2] - width, hi[2])),
                                   ("Left", (lo[0], lo[0] + width, lo[2] + width, hi[2] - width)),
                                   ("Right", (hi[0] - width, hi[0], lo[2] + width, hi[2] - width))):
        b = json.loads(json.dumps(e))
        b.update(uuid=S.uid(), name=e["name"] + name, **{"from": [x0, lo[1], z0], "to": [x1, hi[1], z1]})
        out.append(b)
    return out


def build():
    m = json.load(open(SRC))
    m["name"] = "SnackYak"
    groups_from_outliner(m)
    colours = colour_blocks(m)

    # one solid texture per colour
    palette = {}

    def tex(rgb):
        if rgb not in palette:
            palette[rgb] = len(palette)
        return palette[rgb]

    elements = m["elements"]
    texs = painted(m)
    new = []  # (index of the element it came from, new block)
    drop = set()  # elements replaced by their new blocks
    for i, e in enumerate(elements):
        e["name"] = NAMES[i]
        flat = [ax for ax in range(3) if abs(e["to"][ax] - e["from"][ax]) < 1e-6]
        if flat:  # a painted plane: a thin block per run of painted texels
            for b in sprite_blocks(e, flat[0], texs):
                S.retexture(b, tex(b.pop("rgb")))
                new.append((i, b))
            drop.add(e["uuid"])
            continue
        rgb, slabs = colours[i]
        inf = e.pop("inflate", 0) or 0
        if inf > 0:
            inf = max(inf, MIN_INFLATE)
        for ax in range(3):
            e["from"][ax], e["to"][ax] = round(e["from"][ax] - inf, 4), round(e["to"][ax] + inf, 4)
        S.retexture(e, tex(rgb))
        if i in RINGS:  # a rim painted only round its edge: four blocks round the hole
            for b in ring_blocks(e, RINGS[i]):
                new.append((i, b))
            drop.add(e["uuid"])
            continue
        for fname, fc in slabs:
            core, slab = carve(e, fname, SLAB)
            e["from"], e["to"] = core["from"], core["to"]
            slab["name"] = e["name"] + fname.capitalize()
            S.retexture(slab, tex(fc))
            new.append((i, slab))
    for i, b in new:
        elements.append(b)
        node = parent_of(m["outliner"], elements[i]["uuid"])
        kids = node["children"] if node else m["outliner"]
        kids.insert(kids.index(elements[i]["uuid"]) + 1, b["uuid"])
    for node in [None] + [find_node(m["outliner"], g["uuid"]) for g in m["groups"]]:
        kids = node["children"] if node else m["outliner"]
        kids[:] = [k for k in kids if not (isinstance(k, str) and k in drop)]
    m["textures"] = [S.solid_texture(f"c{k}", rgb) for rgb, k in palette.items()]

    groups = {g["name"]: g for g in m["groups"]}
    root = find_node(m["outliner"], groups["root"]["uuid"])
    # the ham and fish go in their bags
    for extra, bag in (("MORESTUFF", "shark_bag"), ("MORESTUFF2", "shark_bag2")):
        node = next(n for n in m["outliner"] if isinstance(n, dict) and n["uuid"] == groups[extra]["uuid"])
        m["outliner"].remove(node)
        m["groups"].remove(groups[extra])
        find_node(m["outliner"], groups[bag]["uuid"])["children"] += node["children"]
    # the stick on its own bone at its butt, the carrots hanging off its tip
    stick_g = new_group("stick", stick_base(elements[23]))
    carrot_g = new_group("carrot", stick_tip(elements[23]))
    m["groups"] += [stick_g, carrot_g]
    stick_node = {"uuid": stick_g["uuid"], "isOpen": False, "children": []}
    carrot_node = {"uuid": carrot_g["uuid"], "isOpen": False, "children": []}
    for i in STICK:
        root["children"].remove(elements[i]["uuid"])
        stick_node["children"].append(elements[i]["uuid"])
    for name in ("carrlot", "carrlot2"):
        node = find_node(m["outliner"], groups[name]["uuid"])
        root["children"].remove(node)
        carrot_node["children"].append(node)
    stick_node["children"].append(carrot_node)
    root["children"].append(stick_node)

    m["elements"] = [e for e in elements if e["uuid"] not in drop]
    for g in m["groups"]:
        g["name"] = RENAME.get(g["name"], g["name"])
        if g["name"] in PIVOTS:
            assert not any(g.get("rotation") or (0, 0, 0)), g["name"]
            g["origin"] = list(PIVOTS[g["name"]])
    return m


def stick_point(e, along):
    """A point on the stick's axis, `along` of the way from its butt (0) to its tip (1)."""
    lo, hi = np.array(e["from"], float), np.array(e["to"], float)
    p = np.array([(lo[0] + hi[0]) / 2, lo[1] + along * (hi[1] - lo[1]), (lo[2] + hi[2]) / 2])
    R, o = HR.rotm(e["rotation"]), np.array(e["origin"], float)
    return [round(v, 3) for v in R @ (p - o) + o]


def stick_base(e):
    return stick_point(e, 0.0)


def stick_tip(e):
    return stick_point(e, 0.88)


# ---------------------------------------------------------------- animations
#
# Blockbench units for positions, degrees for rotations. +X turns a leg's foot
# forward (front = -Z), and tips the head down; legs and neck only turn forward of
# rest (QM's rule). +Z rolls the body to its left.

LEGS = {"legFL": 0.0, "legBR": 0.0, "legFR": 0.5, "legBL": 0.5}  # walk: diagonal pairs
GALLOP = {"legFL": 0.0, "legFR": 0.12, "legBL": 0.5, "legBR": 0.62}  # a bounding run


def step(u, phase, duty=0.5):
    """0 at rest, rising to 1 and back while the foot is off the ground (the first
    `duty` of the cycle after its phase)."""
    w = (u - phase) % 1.0
    return 0.5 - 0.5 * math.cos(TAU * w / duty) if w < duty else 0.0


def legs(L, phases, swing, n=24):
    return {leg: [track(L, lambda u, ph=ph: (swing * step(u, ph), 0, 0), n)] for leg, ph in phases.items()}


def animations():
    L = 3.0
    idle = {"root": [track(L, lambda u: (0.8 * math.sin(TAU * u), 0, 0), 16),
                     track(L, lambda u: (0, 0.25 * math.sin(TAU * u), 0), 16, "position")],
            "neck": [track(L, lambda u: (3 + 3 * math.sin(TAU * u), 5 * math.sin(TAU * u * 0.5 * 2), 0), 24)],
            "carrot": [track(L, lambda u: (4 * math.sin(TAU * u), 0, 5 * math.sin(TAU * u + 1.2)), 24)],
            "stick": [track(L, lambda u: (1.5 * math.sin(TAU * u - 0.6), 0, 0), 16)],
            "bagR": [track(L, lambda u: (0, 0, 1.5 * math.sin(TAU * u)), 12)],
            "bagL": [track(L, lambda u: (0, 0, -1.5 * math.sin(TAU * u)), 12)]}

    Lw = 1.0
    walk = {**legs(Lw, LEGS, 26),
            "root": [track(Lw, lambda u: (0, 0, 2.0 * math.sin(TAU * u)), 16),
                     track(Lw, lambda u: (0, 0.6 * abs(math.sin(TAU * u)), 0), 16, "position")],
            "neck": [track(Lw, lambda u: (4 + 4 * math.sin(TAU * u * 2), 0, -2 * math.sin(TAU * u)), 16)],
            "stick": [track(Lw, lambda u: (3 * math.sin(TAU * u * 2 - 0.8), 0, 0), 16)],
            "carrot": [track(Lw, lambda u: (10 * math.sin(TAU * u * 2 - 1.6), 0, 12 * math.sin(TAU * u - 1.2)), 24)],
            "basket": [track(Lw, lambda u: (0, 0, -1.5 * math.sin(TAU * u - 0.5)), 16)],
            "bagR": [track(Lw, lambda u: (2 * math.sin(TAU * u * 2), 0, 3 + 4 * math.sin(TAU * u - 0.8)), 16)],
            "bagL": [track(Lw, lambda u: (2 * math.sin(TAU * u * 2), 0, -3 + 4 * math.sin(TAU * u - 0.8)), 16)]}

    Lg = 0.55
    gallop = {**legs(Lg, GALLOP, 42),
              "root": [track(Lg, lambda u: (-6 * math.sin(TAU * u), 0, 0), 16),
                       track(Lg, lambda u: (0, 2.2 * max(0.0, math.sin(TAU * u)), 0), 16, "position")],
              "neck": [track(Lg, lambda u: (6 + 6 * math.sin(TAU * u + 0.6), 0, 0), 16)],
              "stick": [track(Lg, lambda u: (6 * math.sin(TAU * u - 1.0), 0, 0), 16)],
              "carrot": [track(Lg, lambda u: (22 * math.sin(TAU * u - 1.8), 0, 8 * math.sin(TAU * u * 0.5)), 24)],
              "basket": [track(Lg, lambda u: (3 * math.sin(TAU * u - 1.2), 0, 0), 16)],
              "bagR": [track(Lg, lambda u: (4 * math.sin(TAU * u - 1.0), 0, 6 + 8 * max(0.0, math.sin(TAU * u - 1.0))), 16)],
              "bagL": [track(Lg, lambda u: (4 * math.sin(TAU * u - 1.0), 0, -6 - 8 * max(0.0, math.sin(TAU * u - 1.0))), 16)]}
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


# ---------------------------------------------------------------- previews

def main(out="/mnt/project-files/animals/snow"):
    HR.EULER = "ZYX"  # QM's parts turn the Blockbench way
    m = build()
    groups = {g["name"]: g for g in m["groups"]}
    write_animations(m, groups, animations())
    with open(MODEL, "w") as f:
        json.dump(m, f, separators=(",", ":"))
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, "SnackYak.bbmodel"), "w") as f:
        json.dump(m, f, separators=(",", ":"))
    print(len(m["elements"]), "blocks,", len(m["textures"]), "colours")
    qm = json.load(open(SRC))
    rest = S.posed(m)
    lo = np.min([q.min(0) for p in rest for q in p.polys], 0)
    hi = np.max([q.max(0) for p in rest for q in p.polys], 0)
    print("bounds", np.round(lo, 2), np.round(hi, 2))
    # QM's painted model (top) over ours (bottom), from three sides
    W, H = 420, 420
    cams = [dict(eye=(-4.5, 4.5, -6.5), target=(0, 2.2, -0.2)), dict(eye=(7.5, 3.0, 0.5), target=(0, 2.2, -0.2)),
            dict(eye=(3.5, 5.5, 6.5), target=(0, 2.2, 0.2))]
    sheet = Image.new("RGB", (W * 3, H * 2), (255, 255, 255))
    for i, cam in enumerate(cams):
        sheet.paste(render_textured(qm, eye=np.array(cam["eye"]) * 10, target=np.array(cam["target"]) * 10, W=W, H=H, fov=40),
                    (i * W, 0))
        sheet.paste(render(rest, W=W, H=H, fov=40, **cam), (i * W, H))
    sheet.save(os.path.join(out, "SnackYak.png"))
    if "--still" in sys.argv:
        return
    frames = []
    W, H = 400, 340
    for name, label, n, loops in (("idle", "idle", 30, 1), ("walk", "walk", 20, 2), ("gallop", "run", 11, 3)):
        anim = next(a for a in m["animations"] if a["name"] == name)
        for _ in range(loops):
            for k in range(n):
                parts = S.posed(m, anim, anim["length"] * k / n)
                im = Image.new("RGB", (W * 2, H))
                im.paste(render(parts, W=W, H=H, fov=40, **cams[0]), (0, 0))
                im.paste(render(parts, W=W, H=H, fov=40, eye=(-9, 2.6, 0), target=(0, 2.0, -0.2)), (W, 0))
                frames.append(A.label(im, [label] * 2))
    A.gif(os.path.join(out, "SnackYak_anims.gif"), frames, fps=20)
    print("wrote", out)


if __name__ == "__main__":
    main(*[a for a in sys.argv[1:] if not a.startswith("--")])
