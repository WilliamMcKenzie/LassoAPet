"""The Snake (Legendary), rebuilt around QM's head (designs/desert/SnakeHead_QM.bbmodel).

Run: python3 tools/snake_design.py [out_dir]

A long rattlesnake: the neck rears up in an S from the front of the body and
carries QM's head; the body runs back along the ground in plated segments
that taper to an orange rattle. Red back, orange belly and back spikes, the
same two colours (textures) as QM's head. Each body segment is its own bone
under root so the slither can wave them side to side.
"""

import base64
import copy
import io
import json
import math
import os
import sys
import uuid

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from horse_rig import element_polys, rotm, sample, num  # noqa: E402
from partlib import Part, render  # noqa: E402
import animal_designs as A  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
HEAD = os.path.join(ROOT, "designs", "desert", "SnakeHead_QM.bbmodel")
BB = 10  # Blockbench units per stud
SIZE = 1.25  # the whole snake is built at this scale: it's the Legendary, bigger than the rest
HEAD_SCALE = 3.2 * SIZE
RED, ORANGE = 1, 2  # QM's texture slots
NO_TEXTURE = (236, 234, 224)


def uid():
    return str(uuid.uuid4())


def cube(name, center, size, tex, rx=0.0, ry=0.0):
    """A cube in studs, optionally tilted about X, then turned about Y (degrees) around its centre."""
    c = np.array(center, float) * BB * SIZE
    h = np.array(size, float) * BB * SIZE / 2
    uv = [0, 0, 1, 1]
    return {"name": name, "type": "cube", "uuid": uid(), "box_uv": False, "autouv": 0, "color": 0,
            "from": [round(x, 4) for x in c - h], "to": [round(x, 4) for x in c + h],
            "origin": [round(x, 4) for x in c], "rotation": [round(rx, 3), round(ry, 3), 0],
            "faces": {f: {"uv": uv, "texture": tex} for f in ("north", "east", "south", "west", "up", "down")}}


def spike(name, base, length, height, width, tex, ry=0.0):
    """A back spike: a triangular fin standing on `base` (studs, centre of its footprint),
    tall at the front, sloping down toward the tail."""
    x, y, z = (np.array(base, float) * BB * SIZE)
    w, L, H = width * BB * SIZE / 2, length * BB * SIZE, height * BB * SIZE
    v = {"a": [-w, 0, -L / 2], "b": [w, 0, -L / 2], "c": [w, 0, L / 2], "d": [-w, 0, L / 2],
         "e": [-w, H, -L / 2], "f": [w, H, -L / 2]}
    faces = {"bottom": ["a", "b", "c", "d"], "front": ["a", "e", "f", "b"], "slope": ["e", "d", "c", "f"],
             "left": ["a", "d", "e"], "right": ["b", "f", "c"]}
    return {"name": name, "type": "mesh", "uuid": uid(), "color": 0, "origin": [x, y, z], "rotation": [0, round(ry, 3), 0],
            "vertices": {k: [round(c, 4) for c in p] for k, p in v.items()},
            "faces": {k: {"texture": tex, "vertices": vs, "uv": {q: [0, 0] for q in vs}} for k, vs in faces.items()}}


def group(name, origin):
    return {"name": name, "uuid": uid(), "origin": [round(c * BB * SIZE, 4) for c in origin], "rotation": [0, 0, 0],
            "export": True, "visibility": True, "isOpen": True, "color": 0, "children": []}


# ---------------------------------------------------------------- body

# (length, half width, height) for each body segment, front to back from z = 0
SEGMENTS = [(3.0, 1.5, 2.8), (3.0, 1.45, 2.7), (3.0, 1.35, 2.5), (3.0, 1.25, 2.3),
            (3.0, 1.1, 2.0), (3.0, 0.95, 1.7), (2.5, 0.8, 1.4), (2.0, 0.6, 1.1)]
OVERLAP = 0.3  # each segment reaches this far into the one in front, so waving opens no gaps
BELLY = 0.32  # fraction of the height that's orange underneath

# the neck: (from (y, z), to (y, z), half width, thickness) centre lines, rising from the body's front
NECK = [((1.4, 0.8), (3.8, -1.3), 1.45, 2.6),
        ((3.8, -1.3), (6.6, -2.0), 1.4, 2.5),
        ((6.6, -2.0), (8.6, -1.5), 1.35, 2.4)]
HEAD_AT = (0, 9.1, -0.9)  # where the head group's origin lands (studs)


WAVE = 14.0  # studs per side-to-side wave of the resting body
WAVE_AMP = 2.4  # studs of sideways swing at the tail; none where the neck rises


def spine_x(z, total):
    """Sideways offset of the resting body at z: an S that grows toward the tail."""
    amp = WAVE_AMP * min(1.0, max(0.0, z / total)) ** 0.8
    return amp * math.sin(2 * math.pi * z / WAVE)


def spine_yaw(z, total, dz=0.01):
    return math.degrees(math.atan2(spine_x(z + dz, total) - spine_x(z - dz, total), 2 * dz))


def segment_parts(name, z0, z1, hw, h, total, back_spike=True):
    """One body segment centred on the resting S, turned (about Y) along it."""
    parts = []
    belly = h * BELLY
    zc = (z0 + z1) / 2
    xc, yaw = spine_x(zc, total), spine_yaw(zc, total)
    L = (z1 - z0) / math.cos(math.radians(yaw))
    parts.append(cube(name + "Belly", (xc, belly / 2, zc), (2 * hw, belly, L), ORANGE, ry=yaw))
    parts.append(cube(name, (xc, belly + (h - belly) / 2, zc), (2 * hw, h - belly, L), RED, ry=yaw))
    if back_spike:
        parts.append(spike(name + "Spike", (xc, h, zc + 0.2), min(1.2, (z1 - z0) * 0.45), 0.55 + 0.25 * hw, 0.36, ORANGE, ry=yaw))
    return parts


def tilted_segment(name, p0, p1, hw, t, extra=0.35):
    """A neck block along p0 -> p1 in the (y, z) plane, belly on its front/under side."""
    (y0, z0), (y1, z1) = p0, p1
    dy, dz = y1 - y0, z1 - z0
    L = math.hypot(dy, dz) + extra
    # the block's local +z runs from p1 back to p0 (tail-ward); tilt about X
    ang = math.degrees(math.atan2(dy, -dz))  # 0 = lying flat facing -z, 90 = standing up
    cy, cz = (y0 + y1) / 2, (z0 + z1) / 2
    # local up (+y) after tilting by ang about X is (0, cos, sin): belly goes the other way
    up = np.array([0, math.cos(math.radians(ang)), math.sin(math.radians(ang))])
    belly = t * BELLY
    c_red = np.array([0, cy, cz]) + up * (belly / 2)
    c_bel = np.array([0, cy, cz]) - up * ((t - belly) / 2)
    return [cube(name + "Belly", c_bel, (2 * hw, belly, L), ORANGE, ang),
            cube(name, c_red, (2 * hw, t - belly, L), RED, ang)]


def head_parts():
    """QM's head, scaled up and moved onto the neck. Returns (elements, outliner node, groups)."""
    m = json.load(open(HEAD))
    k = HEAD_SCALE
    src_origin = np.array(next(g for g in m["groups"] if g["name"] == "Head")["origin"], float)
    offset = np.array(HEAD_AT, float) * BB * SIZE - src_origin * k
    for e in m["elements"]:
        for key in ("from", "to"):
            if key in e:
                e[key] = [round(c * k + o, 4) for c, o in zip(e[key], offset)]
        if "origin" in e:
            e["origin"] = [round(c * k + o, 4) for c, o in zip(e["origin"], offset)]
        if "vertices" in e:
            e["vertices"] = {n: [round(c * k, 4) for c in v] for n, v in e["vertices"].items()}
    for g in m["groups"]:
        g["origin"] = [round(c * k + o, 4) for c, o in zip(g["origin"], offset)]
    return m


def build():
    head = head_parts()
    elements, groups = [], []
    root = group("root", (0, 1.4, 3))
    groups.append(root)
    outliner = {"uuid": root["uuid"], "isOpen": True, "children": []}

    def add_group(g, parent_node):
        groups.append(g)
        node = {"uuid": g["uuid"], "isOpen": True, "children": []}
        parent_node["children"].append(node)
        return node

    # body segments, each its own bone (pivot at its front, on the centre line)
    total = sum(L for L, _, _ in SEGMENTS)
    z = 0.0
    for i, (L, hw, h) in enumerate(SEGMENTS):
        name = f"Seg{i + 1}"
        node = add_group(group(name, (spine_x(z, total), h / 2, z)), outliner)
        z0 = z - (OVERLAP if i else 0.6)
        for e in segment_parts(name, z0, z + L, hw, h, total, back_spike=i >= 2):
            elements.append(e)
            node["children"].append(e["uuid"])
        z += L
        last = node
    # the rattle on the tail tip: stacked orange beads
    for j, (d, hw, h, tex) in enumerate(((0.8, 0.55, 1.0, ORANGE), (0.7, 0.48, 0.9, RED), (0.6, 0.4, 0.75, ORANGE))):
        zc = z + d / 2
        e = cube(f"Rattle{j + 1}", (spine_x(zc, total), 0.05 + h / 2, zc), (2 * hw, h, d / math.cos(math.radians(spine_yaw(zc, total)))), tex,
                 ry=spine_yaw(zc, total))
        elements.append(e)
        last["children"].append(e["uuid"])
        z += d

    # neck: the base rise, then "neck" (which the lasso loops round) carrying the head
    base = add_group(group("NeckBase", (0, 1.4, 0.8)), outliner)
    for e in tilted_segment("Neck1", *NECK[0][:2], NECK[0][2], NECK[0][3]):
        elements.append(e)
        base["children"].append(e["uuid"])
    neck = add_group(group("neck", (0, 3.8, -1.3)), base)
    for n, (p0, p1, hw, t) in enumerate(NECK[1:], start=2):
        for e in tilted_segment(f"Neck{n}", p0, p1, hw, t):
            elements.append(e)
            neck["children"].append(e["uuid"])
    # spikes down the back of the neck
    for n, (y, zz) in enumerate(((2.9, 0.2), (5.0, -0.6), (7.2, -0.6))):
        e = spike(f"NeckSpike{n + 1}", (0, y, zz), 0.9, 0.8, 0.36, ORANGE)
        e["rotation"] = [-60 + 10 * n, 0, 0]
        elements.append(e)
        neck["children"].append(e["uuid"])

    # QM's head goes in as it is, under neck
    elements += head["elements"]
    groups += head["groups"]
    neck["children"] += head["outliner"]

    model = copy.deepcopy(head)
    model["name"] = "Snake"
    model["elements"] = elements
    model["groups"] = groups
    model["outliner"] = [outliner]
    model["animations"] = []
    model["resolution"] = {"width": 16, "height": 16}
    return model


META = {"seat": (0, 3.0 * SIZE, 3.2 * SIZE), "neck_loop": {"center": (0, 5.2 * SIZE, -1.7 * SIZE), "radius": 1.8 * SIZE}}


# ---------------------------------------------------------------- preview

def textures(model):
    out = []
    for t in model["textures"]:
        im = Image.open(io.BytesIO(base64.b64decode(t["source"].split(",", 1)[1]))).convert("RGBA")
        out.append((im, t.get("uv_width", 16)))
    return out


def element_color(e, texs):
    face = next(iter(e["faces"].values()))
    tex = face.get("texture")
    if tex is None:
        return NO_TEXTURE
    im, uvw = texs[tex]
    px = [p for p in im.getdata() if p[3] > 0]
    if len(set(px)) == 1:
        return px[0][:3]
    uv = face["uv"]
    u, v = (uv[0], uv[1]) if isinstance(uv, list) else next(iter(uv.values()))
    s = im.size[0] / uvw
    return im.getpixel((min(int((u + 0.5) * s), im.size[0] - 1), min(int((v + 0.5) * s), im.size[1] - 1)))[:3]


def posed(model, anim=None, t=0.0):
    texs = textures(model)
    emap = {e["uuid"]: e for e in model["elements"]}
    gmap = {g["uuid"]: g for g in model["groups"]}
    tracks = {}
    if anim:
        for a in anim["animators"].values():
            by = {}
            for k in a.get("keyframes", []):
                by.setdefault(k["channel"], []).append(k)
            tracks[a["name"]] = {ch: sample({"interp": ks[0]["interpolation"], "keys": sorted(
                [(k["time"], tuple(num(k["data_points"][0][c]) for c in "xyz")) for k in ks])}, t) for ch, ks in by.items()}
    parts = []

    def walk(node, M):
        if isinstance(node, str):
            e = emap[node]
            polys = [(M[:3, :3] @ p.T).T + M[:3, 3] for p in element_polys(e)]
            name = e["name"]
            p = Part(name, (1, 1, 1), np.eye(4), element_color(e, texs), "Poly",
                     plain=name.startswith(("Eye", "Pupil", "Nostril", "Amber", "Slit", "Upper_tooth", "Lower_tooth")))
            p.polys = [q / BB for q in polys]
            parts.append(p)
            return
        g = gmap[node["uuid"]]
        o = np.array(g["origin"], float)
        tr = tracks.get(g["name"], {})
        R = rotm(np.array(tr.get("rotation", (0, 0, 0))) + np.array(g.get("rotation") or (0, 0, 0)))
        L = np.eye(4)
        L[:3, :3] = R
        L[:3, 3] = o - R @ o + np.array(tr.get("position", (0, 0, 0)))
        for c in node["children"]:
            walk(c, M @ L)

    for node in model["outliner"]:
        walk(node, np.eye(4))
    return parts


def main(out="/mnt/project-files/animals/desert"):
    model = build()
    path = os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")
    with open(path, "w") as f:
        json.dump(model, f, separators=(",", ":"))
    with open(os.path.join(out, "Snake.bbmodel"), "w") as f:
        json.dump(model, f, separators=(",", ":"))
    parts = posed(model)
    horse = A.qm_horse("A")
    from horse_rig import pose
    hparts = pose(horse, None, 0)
    for p in hparts:
        p.polys = [q + np.array([12, 0, 8]) for q in p.polys]
    W, H = 640, 460
    cams = [dict(eye=(-36, 24, -30), target=(0, 4, 8)), dict(eye=(-54, 9, 10), target=(0, 6, 10)),
            dict(eye=(30, 22, 50), target=(0, 4, 10)), dict(eye=(0, 70, 9.5), target=(0, 0, 10))]
    sheet = Image.new("RGB", (W * 2, H * 2))
    for i, cam in enumerate(cams):
        ps = parts + (hparts if i == 1 else [])
        sheet.paste(render(ps, W=W, H=H, fov=40, **cam), ((i % 2) * W, (i // 2) * H))
    sheet.save(os.path.join(out, "Snake.png"))
    print("wrote", len(model["elements"]), "elements")


if __name__ == "__main__":
    main(*sys.argv[1:])
