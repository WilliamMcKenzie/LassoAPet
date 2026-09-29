"""Rig and animate QM's Toy horse Blockbench model.

Run: python3 tools/horse_rig.py <in.bbmodel> <out.bbmodel> [preview_dir]

Takes QM's edit (bones for root, neck and the front-left leg), adds the missing
legs, the remaining bones (legs, ears, tail) and idle / walk / gallop animations,
then renders preview GIFs of each animation.

Blocks only rotate one way so hidden faces never show:
  legs  swing forward from straight down (pivot at the back-top edge)
  neck  bends forward (pivot at the front-top edge of the body)
  tail  lifts backward (pivot at its top-front edge)
  ears  fold backward (pivot at their front-bottom edge)
Blockbench applies a rotation keyframe straight onto the bone (three.js,
right-handed): +X turns +Y toward +Z. So legs-forward and ears-back are +X,
neck-forward and tail-back are -X.
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
from partlib import Part, render  # noqa: E402

SCALE = 10  # Blockbench units per stud


def uid():
    return str(uuid.uuid4())


# ---------------------------------------------------------------- rig

def find(model, name):
    return [e for e in model["elements"] if e["name"] == name]


def group(name, origin):
    return {"name": name, "uuid": uid(), "export": True, "locked": False, "scope": 0,
            "visibility": True, "origin": list(origin), "rotation": [0, 0, 0], "color": 0,
            "children": [], "reset": False, "shade": True, "mirror_uv": False, "autouv": 0,
            "isOpen": True}


def mirror_cube(e, name, dz=0.0):
    c = copy.deepcopy(e)
    c["uuid"] = uid()
    c["name"] = name
    (x0, y0, z0), (x1, y1, z1) = e["from"], e["to"]
    c["from"] = [-x1, y0, z0 + dz]
    c["to"] = [-x0, y1, z1 + dz]
    ox, oy, oz = e["origin"]
    c["origin"] = [-ox, oy, oz + dz]
    return c


def shift_cube(e, name, dx, dz):
    c = copy.deepcopy(e)
    c["uuid"] = uid()
    c["name"] = name
    c["from"] = [e["from"][0] + dx, e["from"][1], e["from"][2] + dz]
    c["to"] = [e["to"][0] + dx, e["to"][1], e["to"][2] + dz]
    c["origin"] = [e["origin"][0] + dx, e["origin"][1], e["origin"][2] + dz]
    return c


def rig(model):
    els = model["elements"]
    groups = {g["name"]: g for g in model["groups"]}

    # QM's hidden mane-coloured block behind the neck shares the name "Neck"; give it its own.
    necks = find(model, "Neck")
    if len(necks) == 2:
        necks[1]["name"] = "NeckFill"

    # Legs: QM's front-left leg is the template. The body runs z -27..33, so the
    # hind legs sit flush with the rump, 0.01 inside like QM's front-leg fix.
    leg, hoof = find(model, "LegFL")[0], find(model, "HoofFL")[0]
    fl = groups["LegFL"]
    body = find(model, "Body")[0]
    dz_hind = (body["to"][2] - 0.01) - leg["to"][2]
    new_legs = {
        "LegFR": [mirror_cube(leg, "LegFR"), mirror_cube(hoof, "HoofFR")],
        "LegHL": [shift_cube(leg, "LegHL", 0, dz_hind), shift_cube(hoof, "HoofHL", 0, dz_hind)],
        "LegHR": [mirror_cube(leg, "LegHR", dz_hind), mirror_cube(hoof, "HoofHR", dz_hind)],
    }
    px, py, pz = fl["origin"]
    pivots = {"LegFR": (-px, py, pz), "LegHL": (px, py, pz + dz_hind), "LegHR": (-px, py, pz + dz_hind)}
    leg_groups = []
    for name, cubes in new_legs.items():
        g = group(name, pivots[name])
        model["groups"].append(g)
        els.extend(cubes)
        leg_groups.append({"uuid": g["uuid"], "isOpen": True, "children": [c["uuid"] for c in cubes]})

    # Ears fold back about their front-bottom edge.
    ear_groups = []
    ear_uuids = set()
    for side, sx in (("L", -1), ("R", 1)):
        names = [f"Ear{side}A", f"Ear{side}B", f"Ear{side}InA", f"Ear{side}InB"]
        parts = [find(model, n)[0] for n in names]
        ys = [v[1] for p in parts[:2] for v in p["vertices"].values()]
        zs = [v[2] for p in parts[:2] for v in p["vertices"].values()]
        xs = [v[0] for p in parts[:2] for v in p["vertices"].values()]
        g = group("Ear" + side, ((min(xs) + max(xs)) / 2, min(ys), min(zs)))
        model["groups"].append(g)
        ear_groups.append({"uuid": g["uuid"], "isOpen": True, "children": [p["uuid"] for p in parts]})
        ear_uuids |= {p["uuid"] for p in parts}

    # Tail swings back about its top-front edge.
    tail, tip = find(model, "Tail")[0], find(model, "TailTip")[0]
    tg = group("Tail", (0, tail["to"][1], tail["from"][2]))
    model["groups"].append(tg)
    tail_node = {"uuid": tg["uuid"], "isOpen": True, "children": [tail["uuid"], tip["uuid"]]}

    # Rebuild the outliner: root > neck (> ears), body, tail, four legs.
    root = model["outliner"][0]
    new_children = []
    for child in root["children"]:
        if isinstance(child, dict) and child["uuid"] == groups["neck"]["uuid"]:
            child["children"] = [c for c in child["children"] if c not in ear_uuids] + ear_groups
            new_children.append(child)
        elif child in (tail["uuid"], tip["uuid"]):
            continue
        else:
            new_children.append(child)
        if isinstance(child, str) and child == body["uuid"]:
            new_children.append(tail_node)
    new_children += leg_groups
    root["children"] = new_children
    return {g["name"]: g for g in model["groups"]}


# ---------------------------------------------------------------- animations

LEGS = ("LegFL", "LegFR", "LegHL", "LegHR")


def swing(start, dur, amount, length):
    """Leg keys: straight, then forward and back to straight over `dur` seconds.
    Linear keys shaped like a sine bump, so the angle never goes negative.
    A swing that runs past the loop end wraps to the start."""
    shape = [(0, 0), (0.25, 0.7), (0.5, 1), (0.75, 0.7), (1, 0)]
    raw = [(start + f * dur, amount * a) for f, a in shape]

    def value(t):
        for tt in (t, t + length):
            for (t0, v0), (t1, v1) in zip(raw, raw[1:]):
                if t0 <= tt <= t1:
                    return v0 + (v1 - v0) * (tt - t0) / (t1 - t0)
        return 0.0

    keys = {round(t % length, 4): v for t, v in raw}
    keys[0.0] = value(0.0)
    keys[round(length, 4)] = value(0.0)
    return sorted(keys.items())


def rot(keys, sign, interp="linear"):
    return {"channel": "rotation", "interp": interp, "keys": [(t, (sign * v, 0, 0)) for t, v in keys]}


def pos(keys, interp="catmullrom"):
    return {"channel": "position", "interp": interp, "keys": [(t, (0, v, 0)) for t, v in keys]}


LEG_FWD, NECK_FWD, TAIL_BACK, EAR_BACK = 1, -1, -1, 1


def animations():
    anims = {}

    # idle: slow breath in the neck, tail sway, one ear flick
    L = 2.4
    anims["idle"] = (L, {
        "neck": [rot([(0, 0), (1.2, 4), (L, 0)], NECK_FWD, "catmullrom")],
        "Tail": [rot([(0, 4), (1.2, 12), (L, 4)], TAIL_BACK, "catmullrom")],
        "EarL": [rot([(0, 0), (1.5, 0), (1.6, 25), (1.75, 0), (L, 0)], EAR_BACK)],
        "EarR": [rot([(0, 0), (1.55, 0), (1.65, 25), (1.8, 0), (L, 0)], EAR_BACK)],
    })

    # walk: four-beat, each leg steps forward in turn
    L = 1.0
    phase = {"LegHL": 0, "LegFL": 0.25, "LegHR": 0.5, "LegFR": 0.75}
    tracks = {leg: [rot(swing(phase[leg] * L, 0.45 * L, 28, L), LEG_FWD)] for leg in LEGS}
    tracks["root"] = [pos([(0, 0), (0.125, 0.8), (0.25, 0), (0.375, 0.8), (0.5, 0), (0.625, 0.8), (0.75, 0), (0.875, 0.8), (L, 0)])]
    tracks["neck"] = [rot([(0, 0), (0.25, 5), (0.5, 0), (0.75, 5), (L, 0)], NECK_FWD, "catmullrom")]
    tracks["Tail"] = [rot([(0, 8), (0.5, 14), (L, 8)], TAIL_BACK, "catmullrom")]
    anims["walk"] = (L, tracks)

    # gallop: hind pair then front pair reach forward, body hops like a rocking horse
    L = 0.6
    phase = {"LegHL": 0.0, "LegHR": 0.05, "LegFL": 0.3, "LegFR": 0.35}
    tracks = {leg: [rot(swing(phase[leg], 0.28, 50, L), LEG_FWD)] for leg in LEGS}
    tracks["root"] = [
        pos([(0, 1), (0.15, 6), (0.3, 1), (0.45, 6), (L, 1)]),
        {"channel": "rotation", "interp": "catmullrom",
         "keys": [(0, (-4, 0, 0)), (0.3, (4, 0, 0)), (L, (-4, 0, 0))]},
    ]
    tracks["neck"] = [rot([(0, 2), (0.3, 12), (L, 2)], NECK_FWD, "catmullrom")]
    tracks["Tail"] = [rot([(0, 30), (0.3, 50), (L, 30)], TAIL_BACK, "catmullrom")]
    tracks["EarL"] = [rot([(0, 35), (L, 35)], EAR_BACK)]
    tracks["EarR"] = [rot([(0, 35), (L, 35)], EAR_BACK)]
    anims["gallop"] = (L, tracks)
    return anims


def write_animations(model, groups, anims):
    out = []
    for name, (length, tracks) in anims.items():
        animators = {}
        for gname, channels in tracks.items():
            kfs = []
            for ch in channels:
                for t, (x, y, z) in ch["keys"]:
                    kfs.append({"channel": ch["channel"], "data_points": [{"x": round(x, 3), "y": round(y, 3), "z": round(z, 3)}],
                                "uuid": uid(), "time": round(t, 4), "color": -1, "interpolation": ch["interp"]})
            animators[groups[gname]["uuid"]] = {"name": gname, "type": "bone", "keyframes": kfs}
        out.append({"uuid": uid(), "name": name, "loop": "loop", "override": False, "length": length,
                    "snapping": 24, "selected": False, "anim_time_update": "", "blend_weight": "",
                    "start_delay": "", "loop_delay": "", "animators": animators})
    model["animations"] = out


# ---------------------------------------------------------------- preview

def sample(ch, t):
    keys = ch["keys"]
    ts = [k[0] for k in keys]
    vs = [np.array(k[1], float) for k in keys]
    if t <= ts[0]:
        return vs[0]
    if t >= ts[-1]:
        return vs[-1]
    i = max(j for j in range(len(ts)) if ts[j] <= t)
    u = (t - ts[i]) / (ts[i + 1] - ts[i])
    if ch["interp"] == "catmullrom":
        p0 = vs[max(i - 1, 0)]
        p1, p2 = vs[i], vs[i + 1]
        p3 = vs[min(i + 2, len(vs) - 1)]
        return 0.5 * ((2 * p1) + (-p0 + p2) * u + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u * u + (-p0 + 3 * p1 - 3 * p2 + p3) * u ** 3)
    return vs[i] + (vs[i + 1] - vs[i]) * u


def rotm(deg):
    # three.js Euler XYZ: R = Rx * Ry * Rz
    x, y, z = (math.radians(a) for a in deg)
    cx, sx, cy, sy, cz, sz = math.cos(x), math.sin(x), math.cos(y), math.sin(y), math.cos(z), math.sin(z)
    Rx = np.array([[1, 0, 0], [0, cx, -sx], [0, sx, cx]])
    Ry = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])
    Rz = np.array([[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]])
    return Rx @ Ry @ Rz


def palette(model):
    src = model["textures"][0]["source"].split(",", 1)[1]
    return Image.open(io.BytesIO(base64.b64decode(src))).convert("RGB")


def element_polys(e):
    if e["type"] == "cube":
        (x0, y0, z0), (x1, y1, z1) = e["from"], e["to"]
        c = lambda i, j, k: ((x0, x1)[i], (y0, y1)[j], (z0, z1)[k])  # noqa: E731
        quads = [
            [c(1, 0, 0), c(1, 1, 0), c(1, 1, 1), c(1, 0, 1)], [c(0, 0, 1), c(0, 1, 1), c(0, 1, 0), c(0, 0, 0)],
            [c(0, 1, 0), c(0, 1, 1), c(1, 1, 1), c(1, 1, 0)], [c(0, 0, 1), c(0, 0, 0), c(1, 0, 0), c(1, 0, 1)],
            [c(1, 0, 1), c(1, 1, 1), c(0, 1, 1), c(0, 0, 1)], [c(0, 0, 0), c(0, 1, 0), c(1, 1, 0), c(1, 0, 0)],
        ]
        return [np.array(q, float) for q in quads]
    return [np.array([e["vertices"][k] for k in f["vertices"]], float) for f in e["faces"].values()]


def element_color(e, pal):
    if e["type"] == "cube":
        u, v = e["faces"]["north"]["uv"][:2]
    else:
        u, v = next(iter(next(iter(e["faces"].values()))["uv"].values()))
    return pal.getpixel((int(u), int(v)))


def pose(model, anim, t):
    """Parts in studs for one frame of an animation (None = rest pose)."""
    pal = palette(model)
    gmap = {g["uuid"]: g for g in model["groups"]}
    tracks = {}
    if anim:
        for a in anim["animators"].values():
            tracks[a["name"]] = {}
            by_ch = {}
            for k in a["keyframes"]:
                by_ch.setdefault(k["channel"], []).append(k)
            for chn, kfs in by_ch.items():
                kfs.sort(key=lambda k: k["time"])
                ch = {"interp": kfs[0]["interpolation"],
                      "keys": [(k["time"], tuple(float(k["data_points"][0][c]) for c in "xyz")) for k in kfs]}
                tracks[a["name"]][chn] = sample(ch, t)
    emap = {e["uuid"]: e for e in model["elements"]}
    parts = []

    def walk(node, M):
        if isinstance(node, str):
            e = emap[node]
            polys = [(M[:3, :3] @ p.T).T + M[:3, 3] for p in element_polys(e)]
            color = element_color(e, pal)
            plain = e["name"].startswith(("Eye", "Pupil", "Nostril")) or "In" in e["name"]
            p = Part(e["name"], (1, 1, 1), np.eye(4), color, "Poly", plain)
            p.polys = [q / SCALE for q in polys]
            parts.append(p)
            return
        g = gmap[node["uuid"]]
        o = np.array(g["origin"], float)
        tr = tracks.get(g["name"], {})
        R = rotm(tr.get("rotation", (0, 0, 0)))
        L = np.eye(4)
        L[:3, :3] = R
        L[:3, 3] = o - R @ o + np.array(tr.get("position", (0, 0, 0)))
        for c in node["children"]:
            walk(c, M @ L)

    for node in model["outliner"]:
        walk(node, np.eye(4))
    return parts


def preview(model, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    side = dict(eye=(-26, 6.5, -3), target=(0, 5.5, -1), W=420, H=420, fov=34)
    q34 = dict(eye=(-17, 10, -16), target=(0, 5.5, -1), W=420, H=420, fov=34)
    rest = pose(model, None, 0)
    sheet = Image.new("RGB", (840, 420))
    sheet.paste(render(rest, **q34), (0, 0))
    sheet.paste(render(rest, **side), (420, 0))
    sheet.save(os.path.join(out_dir, "rest.png"))
    for anim in model["animations"]:
        fps = 20
        n = max(2, round(anim["length"] * fps * (2 if anim["length"] < 1.2 else 1)))
        frames = []
        for i in range(n):
            t = (i / fps) % anim["length"]
            parts = pose(model, anim, t)
            f = Image.new("RGB", (840, 420))
            f.paste(render(parts, **q34), (0, 0))
            f.paste(render(parts, **side), (420, 0))
            frames.append(f)
        frames[0].save(os.path.join(out_dir, f"{anim['name']}.gif"), save_all=True, append_images=frames[1:],
                       duration=int(1000 / fps), loop=0)
        print(anim["name"], n, "frames")


def main(src, dst, prev=None):
    model = json.load(open(src))
    groups = rig(model)
    write_animations(model, groups, animations())
    model["meta"]["format_version"] = model["meta"].get("format_version", "4.10")
    with open(dst, "w") as f:
        json.dump(model, f, separators=(",", ":"))
    if prev:
        preview(model, prev)


if __name__ == "__main__":
    main(*sys.argv[1:])
