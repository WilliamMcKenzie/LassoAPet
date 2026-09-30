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
NO_TEXTURE = (236, 234, 224)

# Colours (QM's head came in placeholder red/orange): a golden desert snake with
# maroon rattlesnake bands, a cream belly, turquoise horns and spikes, pink mouth.
# Each colour is its own solid texture; slot 0 stays the head's palette (eye iris).
COLORS = {"gold": (240, 186, 72), "cream": (252, 234, 186), "maroon": (168, 48, 78),
          "teal": (48, 196, 214), "pink": (238, 104, 146), "amber": (255, 214, 64),
          "ivory": (250, 248, 238), "tan": (212, 150, 70)}
TEX = {name: i + 1 for i, name in enumerate(COLORS)}
RED, ORANGE = TEX["gold"], TEX["cream"]  # body top, belly
HEAD_COLORS = [  # QM's head parts by name prefix
    (("Cranium", "Long_box_muzzle", "Cheek_", "Chin", "Jaw_rim"), "gold"),
    (("Jaw_floor",), "cream"),
    (("Lower_mouth", "Mouth_roof"), "pink"),
    (("Nostril",), "maroon"),
    (("Eye_white",), "amber"),
    (("Upper_tooth", "Lower_tooth"), "ivory"),
    (("Forehead_crest", "Cheek_spike", "Swept_horn", "Heavy_brow"), "teal"),
]


def solid_texture(name, rgb):
    im = Image.new("RGBA", (16, 16), tuple(rgb) + (255,))
    buf = io.BytesIO()
    im.save(buf, "PNG")
    return {"name": name, "path": "", "folder": "", "namespace": "", "id": "0", "width": 16, "height": 16,
            "uv_width": 16, "uv_height": 16, "particle": False, "render_mode": "default", "render_sides": "auto",
            "visible": True, "internal": True, "saved": False, "uuid": uid(),
            "source": "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()}


def retexture(e, tex):
    for f in e["faces"].values():
        f["texture"] = tex


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
#
# Rest pose (every bone at 0): the snake lies straight and flat on its belly,
# every cube axis-aligned, head in front facing -z. Bones chain from the root
# (the front body segment, where you sit) back to the tail and forward to the
# head, so bending is all bone rotation: the reared-up S is the "pose" animation.

# (length, half width, height) for each body segment, front to back from z = 0
SEGMENTS = [(3.0, 1.5, 2.8), (3.0, 1.45, 2.7), (3.0, 1.35, 2.5), (3.0, 1.25, 2.3),
            (3.0, 1.1, 2.0), (3.0, 0.95, 1.7), (2.5, 0.8, 1.4), (2.0, 0.6, 1.1)]
# neck segments from z = 0 forward: (length, half width, height)
NECK = [("NeckBase", "Neck1", 2.8, 1.45, 2.6), ("neck", "Neck2", 2.8, 1.4, 2.5), ("NeckTop", "Neck3", 2.4, 1.35, 2.4)]
OVERLAP = 0.5  # each block reaches this far back past its joint, so bending opens no gaps
BELLY = 0.32  # fraction of the height that's cream underneath

# The reared-up pose, as bone rotations (degrees): neck bones lift (+X raises the
# front), the head levels out again, and the body swings side to side (Y).
NECK_LIFT = {"NeckBase": 44, "neck": 32, "NeckTop": 28, "Head": -104}
WAVE = 14.0  # studs per side-to-side wave of the posed body
WAVE_AMP = 2.4  # studs of sideways swing at the tail


def spine_yaw(z, total, dz=0.01):
    def x(z):
        return WAVE_AMP * min(1.0, max(0.0, z / total)) ** 0.8 * math.sin(2 * math.pi * z / WAVE)
    return math.degrees(math.atan2(x(z + dz) - x(z - dz), 2 * dz))


def slab(name, z_front, z_back, hw, h, spike_on=True, band=True):
    """A straight block lying on the ground from z_front to z_back (z_front < z_back):
    cream belly, maroon band across the front, gold top, turquoise spike."""
    parts = []
    belly = h * BELLY
    L = z_back - z_front
    zc = (z_front + z_back) / 2
    parts.append(cube(name + "Belly", (0, belly / 2, zc), (2 * hw, belly, L), TEX["cream"]))
    top = (0, belly + (h - belly) / 2)
    if band:
        bl = L * 0.3
        parts.append(cube(name + "Band", (0, top[1], z_front + bl / 2), (2 * hw + 0.02, h - belly + 0.02, bl), TEX["maroon"]))
        parts.append(cube(name, (0, top[1], z_front + bl + (L - bl) / 2), (2 * hw, h - belly, L - bl), TEX["gold"]))
    else:
        parts.append(cube(name, (0, top[1], zc), (2 * hw, h - belly, L), TEX["gold"]))
    if spike_on:
        parts.append(spike(name + "Spike", (0, h, zc + 0.2), min(1.2, L * 0.4), 0.55 + 0.25 * hw, 0.36, TEX["teal"]))
    return parts


def head_parts(z_back):
    """QM's head, scaled, its back at z_back and its lowest point (the open jaw) on the ground."""
    m = json.load(open(HEAD))
    k = HEAD_SCALE
    src_origin = np.array(next(g for g in m["groups"] if g["name"] == "Head")["origin"], float)

    def move(offset):
        for e in m["elements"]:
            for key in ("from", "to", "origin"):
                if key in e:
                    e[key] = [round(c + o, 4) for c, o in zip(e[key], offset)]
        for g in m["groups"]:
            g["origin"] = [round(c + o, 4) for c, o in zip(g["origin"], offset)]

    for e in m["elements"]:
        for key in ("from", "to", "origin"):
            if key in e:
                e[key] = [c * k for c in e[key]]
        if "vertices" in e:
            e["vertices"] = {n: [round(c * k, 4) for c in v] for n, v in e["vertices"].items()}
    for g in m["groups"]:
        g["origin"] = [c * k for c in g["origin"]]
    move(np.array([0, 0, z_back * BB * SIZE]) - src_origin * k)
    low = min(q[:, 1].min() for p in posed(m) for q in p.polys)
    move(np.array([0, -low * BB, 0]))
    for e in m["elements"]:
        for prefixes, color in HEAD_COLORS:
            if e["name"].startswith(prefixes):
                retexture(e, TEX[color])
    m["textures"] = m["textures"][:1] + [solid_texture(n, c) for n, c in COLORS.items()]
    return m


def build():
    elements, groups = [], []

    def add_group(name, pivot, parent):
        g = group(name, pivot)
        groups.append(g)
        node = {"uuid": g["uuid"], "isOpen": True, "children": []}
        if parent is not None:
            parent["children"].append(node)
        return node

    def put(node, parts):
        for e in parts:
            elements.append(e)
            node["children"].append(e["uuid"])

    # body: root is the front segment; each one after hangs off the one before
    L, hw, h = SEGMENTS[0]
    root = add_group("root", (0, h / 2, L / 2), None)
    put(root, slab("Seg1", -OVERLAP, L, hw, h, spike_on=False))
    parent, z = root, L
    for i, (L, hw, h) in enumerate(SEGMENTS[1:], start=2):
        node = add_group(f"Seg{i}", (0, h / 2, z), parent)
        put(node, slab(f"Seg{i}", z - OVERLAP, z + L, hw, h, spike_on=i >= 3))
        parent, z = node, z + L
    for j, (d, rw, rh, tex) in enumerate(((0.8, 0.55, 1.0, "cream"), (0.7, 0.48, 0.9, "tan"), (0.6, 0.4, 0.75, "cream"))):
        put(parent, [cube(f"Rattle{j + 1}", (0, 0.05 + rh / 2, z + d / 2), (2 * rw, rh, d), TEX[tex])])
        z += d

    # neck: forward from the front segment, each bone's pivot at its back joint
    parent, z = root, 0.0
    for bone, name, L, hw, h in NECK:
        node = add_group(bone, (0, h / 2, z), parent)
        put(node, slab(name, z - L, z + OVERLAP, hw, h, band=False))
        parent, z = node, z - L

    # QM's head, its back against the neck's front
    head = head_parts(z + 0.3)
    head_group = next(g for g in head["groups"] if g["name"] == "Head")
    head_group["origin"] = [0, round(NECK[-1][4] / 2 * BB * SIZE, 4), round(z * BB * SIZE, 4)]
    elements += head["elements"]
    groups += head["groups"]
    parent["children"] += head["outliner"]

    model = copy.deepcopy(head)
    model["name"] = "Snake"
    model["elements"] = elements
    model["groups"] = groups
    model["outliner"] = [root]
    model["resolution"] = {"width": 16, "height": 16}
    model["animations"] = []
    pose_anim(model)
    return model


def pose_anim(model):
    """The reared-up S as a one-frame "pose" animation (idle, walk and run come later)."""
    from horse_rig import write_animations
    groups = {g["name"]: g for g in model["groups"]}
    total = sum(L for L, _, _ in SEGMENTS)
    tracks = {name: [{"channel": "rotation", "interp": "linear", "keys": [(0, (a, 0, 0)), (1, (a, 0, 0))]}]
              for name, a in NECK_LIFT.items()}
    z, prev = SEGMENTS[0][0], 0.0
    for i, (L, _, _) in enumerate(SEGMENTS[1:], start=2):
        yaw = spine_yaw(z + L / 2, total)
        tracks[f"Seg{i}"] = [{"channel": "rotation", "interp": "linear", "keys": [(0, (0, yaw - prev, 0)), (1, (0, yaw - prev, 0))]}]
        prev, z = yaw, z + L
    write_animations(model, groups, {"pose": (1.0, tracks)})


META = {"seat": (0, 2.8 * SIZE, 1.6 * SIZE),
        "neck_loop": {"center": (0, 1.25 * SIZE, -(NECK[0][2] + NECK[1][2] / 2) * SIZE), "radius": 1.8 * SIZE}}


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
    rest = posed(model)
    reared = posed(model, model["animations"][0], 0)
    W, H = 640, 460
    q34 = dict(eye=(-36, 24, -30), target=(0, 4, 8))
    side = dict(eye=(-58, 10, 6), target=(0, 3, 6))
    top = dict(eye=(0, 75, 6.5), target=(0, 0, 7))
    sheet = Image.new("RGB", (W * 3, H * 2))
    for r, parts in enumerate((rest, reared)):
        for c, cam in enumerate((q34, side, top)):
            sheet.paste(render(parts, W=W, H=H, fov=40, **cam), (c * W, r * H))
    A.label(sheet, ["top: rest, all bones at 0", "bottom: the pose animation", ""], 22).save(os.path.join(out, "Snake_rest.png"))
    im = Image.new("RGB", (W * 2, H))
    im.paste(render(reared, W=W, H=H, fov=40, **q34), (0, 0))
    im.paste(render(reared, W=W, H=H, fov=40, **side), (W, 0))
    im.save(os.path.join(out, "Snake.png"))
    print("wrote", len(model["elements"]), "elements")


if __name__ == "__main__":
    main(*sys.argv[1:])
