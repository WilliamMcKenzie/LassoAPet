"""Lasso training dummies and chairs for every biome's pen (QM, Oct 8).

Run: python3 tools/biome_dummies.py [out_dir]   renders: the lineup of dummies and chairs
     python3 tools/biome_dummies.py game        writes src/shared/Props/TrainingDummy<Biome>Model.luau
                                                 and TrainingChair<Biome>Model.luau for each biome

Each biome's dummy is one of its plain animals (not a legendary) remade as a sewn
toy: its own model, pupils swapped for stitched X eyes, a stitched seam and patch
on its body, colours softened toward sackcloth, frozen at the top of its gallop and
stuck on a wooden pole. Each biome's is bigger than the last (Grow x per biome).
The Meadow keeps QM's stitched horse (tools/dummy_design.py, Props/TrainingDummy).

The chairs are tools/chair_design.py's chair in each biome's materials, with a
little topper on the back; they stay one size (the player sits in them).

Works on the converted parts (tools/bbmodel_to_luau.convert): bones and parts in
studs, so the result goes straight into the same Luau format Rig builds from.
"""

import json
import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import bbmodel_to_luau as B  # noqa: E402
from horse_rig import sample  # noqa: E402
from partlib import Part, render  # noqa: E402
import chair_design as C  # noqa: E402

SACK = np.array((214, 180, 118), float)
THREAD = (70, 44, 30)
BLACK = (34, 30, 40)
WOOD = (166, 108, 62)
WOOD_DARK = (122, 78, 44)
PATCH = (84, 150, 230)
GROW = 1.3  # each biome's dummy is this much bigger than the last
HORSE_SIZE = 10.4  # the Meadow's stitched horse (Config.PetSmallSize)
CLEAR = 1.6  # studs between the dummy's lowest point and the ground
POLE = 4.5  # studs of pole under the body (the horse's)

# biome index (Meadow is 1), animal, its model, Blockbench euler order, extra rest
# rotations (degrees) and the patch colour
DUMMIES = [
    dict(biome="Desert", animal="Cactus", src="designs/desert/Cactus.bbmodel", patch=(232, 86, 76)),
    dict(biome="Snow", animal="Snowman", src="designs/snow/Snowman.bbmodel", patch=(84, 150, 230)),
    dict(biome="Ocean", animal="Starfish", src="designs/ocean/Starfish.bbmodel", patch=(250, 214, 60),
         gallop=False, rest={"root": (-40, 0, 0)}, fit=1.3),
    dict(biome="Godlands", animal="WarElephant", src="designs/godlands/WarElephant.bbmodel", order="ZYX",
         patch=(160, 100, 220)),
]


def T(p):
    m = np.eye(4)
    m[:3, 3] = p
    return m


def R4(R):
    m = np.eye(4)
    m[:3, :3] = R
    return m


def xyz(R):
    """XYZ euler degrees of R = Rx * Ry * Rz."""
    y = math.asin(max(-1, min(1, R[0, 2])))
    x = math.atan2(-R[1, 2], R[2, 2])
    z = math.atan2(-R[0, 1], R[0, 0])
    return [round(math.degrees(a), 4) + 0.0 for a in (x, y, z)]


def peak_pose(model):
    """Bone rotations (degrees) at the top of the gallop: where root rises highest."""
    anim = next((a for a in model.get("animations", []) if a["name"] == "gallop"), None)
    if not anim:
        return {}
    tracks = {}
    for a in anim["animators"].values():
        by = {}
        for k in a.get("keyframes", []):
            by.setdefault(k["channel"], []).append(k)
        for ch, kfs in by.items():
            kfs.sort(key=lambda k: k["time"])
            tracks.setdefault(a["name"], {})[ch] = {"interp": kfs[0]["interpolation"],
                                                    "keys": [(k["time"], tuple(B.num(k["data_points"][0][c]) for c in "xyz")) for k in kfs]}
    ts = np.linspace(0, anim["length"], 81)
    pos = tracks.get("root", {}).get("position")
    t = ts[int(np.argmax([sample(pos, t)[1] for t in ts]))] if pos else anim["length"] / 2
    return {b: tuple(sample(ch["rotation"], t)) for b, ch in tracks.items() if "rotation" in ch}


def world(bones):
    """Bone name -> 4x4 world transform at rest (Rig.buildFromData's joints)."""
    W, piv = {}, {}
    for name, parent, pivot, rot in bones:
        pp = piv[parent] if parent else np.zeros(3)
        W[name] = (W[parent] if parent else np.eye(4)) @ T(pivot - pp) @ R4(B.euler(rot))
        piv[name] = pivot
    return W, piv


def posed_parts(bones, parts):
    """partlib Parts in world space, for renders and measuring."""
    W, piv = world(bones)
    out = []
    shape = {"WedgePart": "Wedge", "CornerWedgePart": "CornerWedge"}
    for name, bone, cls, size, center, R, rgb, plain, neon, metal in parts:
        cf = W[bone] @ T(-piv[bone]) @ T(center) @ R4(R)
        p = Part(name, size, cf, tuple(int(c) for c in rgb), shape.get(cls, "Block"), plain)
        p.bone = bone
        out.append(p)
    return out


def corners(p):
    h = p.size / 2
    pts = np.array([[sx * h[0], sy * h[1], sz * h[2], 1] for sx in (-1, 1) for sy in (-1, 1) for sz in (-1, 1)])
    return (p.cf @ pts.T).T[:, :3]


def box_size(ps):
    pts = np.concatenate([corners(p) for p in ps])
    d = np.sort(pts.max(0) - pts.min(0))
    return math.sqrt(d[1] * d[2]), pts


def soften(rgb, k=0.3):
    c = np.array(rgb, float)
    if min(c) > 235 or max(c) < 50:  # eye whites and blacks stay
        return tuple(int(x) for x in c)
    return tuple(int(round(x)) for x in c * (1 - k) + SACK * k)


def part(name, bone, size, center, rgb, plain=True, R=None):
    return (name, bone, "Part", np.array(size, float), np.array(center, float), np.eye(3) if R is None else R,
            tuple(rgb), plain, False, False)


def x_squares(eye, bone, out_sign, axis, color=BLACK):
    """A pixel X (5x5 grid, both diagonals) on an eye plate's outer face."""
    _, _, _, size, center, R, *_ = eye
    others = [i for i in range(3) if i != axis]
    span = min(size[others[0]], size[others[1]]) * 0.95
    c = span / 5
    res = []
    for i in range(5):
        for j in {i, 4 - i}:
            pos = np.array(center, float)
            pos[axis] = center[axis] + out_sign * (size[axis] / 2 + 0.02)
            # rows run down the vertical axis (y) when it's one of the face's axes
            a, b = (1, [o for o in others if o != 1][0]) if 1 in others else others
            pos[a] = center[a] + span / 2 - (i + 0.5) * c
            pos[b] = center[b] - span / 2 + (j + 0.5) * c
            sz = np.full(3, c)
            sz[axis] = 0.04
            res.append(part(f"PupilX{i}{j}", bone, sz, pos, color))
    return res


def stitch_body(parts, body, patch):
    """A stitched seam down both sides of the body block, and a patch on its left."""
    _, bone, _, size, center, R, *_ = body
    h = size / 2
    out = []
    for sx in (-1, 1):
        x = center[0] + sx * (h[0] + 0.03)
        n = max(3, int(size[1] / 0.45))
        for i in range(n):
            y = center[1] - h[1] + (i + 0.5) * size[1] / n
            out.append(part(f"PlainStitch{'LR'[sx > 0]}{i}", bone, (0.06, 0.16, 0.5), (x, y, center[2]), THREAD))
    pw, ph = size[2] * 0.3, size[1] * 0.35
    pz, py = center[2] + size[2] * 0.2, center[1] + size[1] * 0.05
    x = center[0] - h[0] - 0.025
    out.append(part("PlainPatch", bone, (0.05, ph, pw), (x, py, pz), patch))
    for k, (dy, dz, sy, sz) in enumerate(((ph / 2, 0, 0.35, 0.16), (-ph / 2, 0, 0.35, 0.16), (0, pw / 2, 0.16, 0.35), (0, -pw / 2, 0.16, 0.35))):
        n = 4
        for i in range(n):
            u = (i + 0.5) / n - 0.5
            yy = py + (dy if dy else u * ph)
            zz = pz + (dz if dz else u * pw)
            out.append(part(f"PlainPatchStitch{k}{i}", bone, (0.06, sy, sz), (x - 0.03, yy, zz), THREAD))
    return out


def dummy(d, index):
    """(bones, parts) of one biome's dummy, scaled, posed and on its pole."""
    B.ORDER = d.get("order", "XYZ")
    model = json.load(open(d["src"]))
    bones, parts = B.convert(model)
    parts = [(n, b, c, np.array(sz, float), np.array(ce, float), np.array(R, float), *rest) for n, b, c, sz, ce, R, *rest in parts]
    # size: the animal's own box at rest (as Config sizes pets), then this biome's step up
    k = d.get("fit", 1) * HORSE_SIZE * GROW ** index / box_size(posed_parts([(n, p, np.array(v, float), r) for n, p, v, r in bones], parts))[0]
    pose = peak_pose(model) if d.get("gallop", True) else {}
    # rest x gallop pose (Rig plays animations on top of the rest), then the extra rests,
    # all as XYZ euler degrees from here on (what CFrame.Angles takes)
    bones = [(n, p, np.array(v, float), B.euler(r) @ B.euler(pose.get(n, (0, 0, 0))) @ B.euler(d.get("rest", {}).get(n, (0, 0, 0))))
             for n, p, v, r in bones]
    B.ORDER = "XYZ"
    bones = [(n, p, v, xyz(M)) for n, p, v, M in bones]
    bones = [(n, p, v * k, r) for n, p, v, r in bones]
    parts = [(n, b, c, s * k, ce * k, R, soften(rgb), pl, ne, me) for n, b, c, s, ce, R, rgb, pl, ne, me in parts]
    # stitched X eyes: drop the pupils, sew an X on each eye plate's outer face
    eyes = [p for p in parts if p[0].startswith("Eye")]
    parts = [p for p in parts if not p[0].startswith("Pupil")]
    for e in eyes:
        axis = int(np.argmin(e[3]))
        if axis == 2:
            sign = -1  # front-facing eyes (the cactus)
        else:
            sign = 1 if e[4][axis] > 0 else -1
        parts += x_squares(e, e[1], sign, axis, BLACK if e[6][0] > 200 else (250, 250, 246))
    body = max((p for p in parts if p[1] == "root" and p[2] == "Part"), key=lambda p: np.prod(p[3]))
    parts += stitch_body(parts, body, d["patch"])
    # onto the pole: the lowest point CLEAR studs up, the pole under the body's middle
    posed = posed_parts(bones, parts)
    _, pts = box_size(posed)
    root_pts = np.concatenate([corners(p) for p in posed if p.bone == "root"])
    # at least POLE studs of pole showing under the body, and nothing lower than CLEAR
    lift = max(CLEAR * GROW ** index - pts[:, 1].min(), POLE * GROW ** index - root_pts[:, 1].min())
    bones = [(n, p, v + (0, lift, 0) if True else v, r) for n, p, v, r in bones]
    parts = [(n, b, c, s, ce + (0, lift, 0), R, *rest) for n, b, c, s, ce, R, *rest in parts]
    px, pz = (root_pts[:, 0].min() + root_pts[:, 0].max()) / 2, (root_pts[:, 2].min() + root_pts[:, 2].max()) / 2
    top = root_pts[:, 1].min() + lift + 0.3
    w = 0.8 * GROW ** index
    g = GROW ** index
    pole = [part("Pole", "Pole", (w, top - 0.8 * g, w), (px, (top + 0.8 * g) / 2, pz), WOOD, False),
            part("FootX", "Pole", (6 * g, 0.8 * g, 1.2 * g), (px, 0.4 * g, pz), WOOD_DARK, False),
            part("FootZ", "Pole", (1.2 * g, 0.8 * g, 6 * g), (px, 0.4 * g, pz), WOOD_DARK, False),
            part("Collar", "Pole", (1.4 * g, 0.6 * g, 1.4 * g), (px, 1.1 * g, pz), WOOD_DARK, False)]
    bones = [("Pole", None, np.array((px, 0, pz)), [0, 0, 0])] + [(n, p or "Pole", v, r) for n, p, v, r in bones]
    # the lasso closes round the head bone's parts
    head = "neck" if any(n == "neck" for n, *_ in bones) else "root"
    hp = np.concatenate([corners(p) for p in posed_parts(bones, pole + parts) if p.bone == head])
    neck = dict(center=(hp.min(0) + hp.max(0)) / 2, radius=float(np.sort(hp.max(0) - hp.min(0))[1] / 2))
    # front at -z: the Starfish stands up facing the chair, everyone else faces -z already
    return model, bones, pole + parts, neck


def write_luau(model, bones, parts, name, dst):
    """bbmodel_to_luau's writer with our bones and parts, and idle/hit animations on root (and neck)."""
    import copy
    import uuid
    m = copy.deepcopy(model)
    gid = {g["name"]: g["uuid"] for g in m["groups"]}

    def track(keys):
        return [{"channel": "rotation", "data_points": [{"x": x, "y": 0, "z": z}], "uuid": str(uuid.uuid4()), "time": t,
                 "color": -1, "interpolation": "catmullrom"} for t, x, z in keys]
    idle = {gid["root"]: {"name": "root", "type": "bone", "keyframes": track([(0, 0, 0), (0.6, 1.5, 2), (1.2, 0, 0), (1.8, -1.5, -2), (2.4, 0, 0)])}}
    hit = {gid["root"]: {"name": "root", "type": "bone", "keyframes": track([(0, 0, 0), (0.1, -10, 6), (0.25, 7, -5), (0.4, -4, 3), (0.55, 2, -1.5), (0.7, -1, 0.5), (0.9, 0, 0)])}}
    if "neck" in gid:
        hit[gid["neck"]] = {"name": "neck", "type": "bone", "keyframes": track([(0, 0, 0), (0.12, 12, 0), (0.3, -6, 0), (0.5, 3, 0), (0.9, 0, 0)])}
    m["animations"] = [dict(name="idle", length=2.4, animators=idle), dict(name="hit", length=0.9, animators=hit)]
    import tempfile
    tmp = os.path.join(tempfile.gettempdir(), name + ".bbmodel")  # only carries the animations; the parts are ours
    with open(tmp, "w") as f:
        json.dump(m, f, separators=(",", ":"))
    real = B.convert
    B.convert = lambda _: (bones, parts)
    try:
        B.main(tmp, dst)
    finally:
        B.convert = real
    lines = open(dst).read().split("\n")
    lines[0] = "-- GENERATED by tools/biome_dummies.py game (from %s). Don't edit by hand:" % model.get("name", name)
    lines[1] = "-- change the script or the animal's .bbmodel and regenerate."
    open(dst, "w").write("\n".join(lines))


# ---------------------------------------------------------------- chairs

CHAIRS = {
    "Meadow": dict(wood=(122, 78, 44), seat=(196, 136, 80), slat=(166, 108, 62)),
    "Desert": dict(wood=(214, 160, 96), seat=(240, 200, 130), slat=(226, 180, 112), top="cactus"),
    "Snow": dict(wood=(150, 200, 236), seat=(214, 238, 252), slat=(180, 220, 246), top="snow"),
    "Ocean": dict(wood=(236, 120, 130), seat=(255, 196, 176), slat=(250, 160, 150), top="shell"),
    "Godlands": dict(wood=(240, 190, 60), seat=(250, 246, 236), slat=(255, 214, 90), top="crown"),
}


def chair(biome):
    c = CHAIRS[biome]
    a = C.chair()
    for p in a.parts:
        p.color = {C.WOOD_DARK: c["wood"], C.WOOD_LIGHT: c["seat"], C.WOOD: c["slat"]}.get(p.color, p.color)
    top, W, D, y = c.get("top"), C.W, C.D, C.BACK_TOP + 0.5
    if top == "cactus":  # a little cactus on each post
        for s, sx in (("L", -1), ("R", 1)):
            x = sx * (W - C.LEG / 2)
            a.box("Cactus" + s, (x - 0.3, y, D - 0.55), (x + 0.3, y + 1.4, D + 0.05), (118, 204, 64), "root")
            a.box("CactusArm" + s, (x + sx * 0.3, y + 0.5, D - 0.4), (x + sx * 0.7, y + 0.8, D - 0.1), (118, 204, 64), "root")
            a.box("CactusArmUp" + s, (x + sx * 0.4, y + 0.8, D - 0.4), (x + sx * 0.7, y + 1.2, D - 0.1), (118, 204, 64), "root")
    elif top == "snow":  # a cap of snow along the top and on the seat's back edge
        a.box("Snow", (-W - 0.1, y, D - 0.6), (W + 0.1, y + 0.4, D + 0.1), (250, 252, 255), "root")
        a.box("SnowLump", (-W * 0.4, y + 0.4, D - 0.5), (W * 0.3, y + 0.7, D), (250, 252, 255), "root")
    elif top == "shell":  # a scallop shell in the middle of the top
        for i, (w, h) in enumerate(((1.4, 0.4), (1.0, 0.4), (0.6, 0.4))):
            a.box(f"Shell{i}", (-w, y + i * h, D - 0.45), (w, y + (i + 1) * h, D - 0.05), (255, 226, 200), "root")
        a.box("PlainPearl", (-0.25, y + 0.2, D - 0.6), (0.25, y + 0.7, D - 0.45), (250, 250, 250), "root")
    elif top == "crown":  # three gold points, a gem in the middle
        for i, x in enumerate((-W + 0.25, 0, W - 0.25)):
            h = 1.2 if i == 1 else 0.8
            a.box(f"Crown{i}", (x - 0.25, y, D - 0.4), (x + 0.25, y + h, D - 0.1), (240, 190, 60), "root")
        a.box("PlainGem", (-0.3, y + 0.3, D - 0.55), (0.3, y + 0.9, D - 0.4), (90, 200, 240), "root")
    return a


def main(out="/mnt/project-files/design/dummies"):
    os.makedirs(out, exist_ok=True)
    horse = json.load(open("designs/props/TrainingDummy.bbmodel"))
    B.ORDER = "XYZ"
    hb, hp = B.convert(horse)
    rows = [("Meadow · Horse", posed_parts(hb, hp))]
    for i, d in enumerate(DUMMIES, 1):
        _, bones, parts, neck = dummy(d, i)
        rows.append((f"{d['biome']} · {d['animal']}", posed_parts(bones, parts)))
        print(d["biome"], len(parts), "parts, neck", np.round(neck["center"], 2), round(neck["radius"], 2))
    # one wide shot, side by side 22 studs apart, the chair beside each
    scene, names = [], []
    x = 0
    for i, (label, ps) in enumerate(rows):
        biome = label.split(" ·")[0]
        g = GROW ** i
        for p in ps:
            q = Part(p.name, p.size, T((x, 0, 0)) @ p.cf, p.color, p.shape, p.plain)
            if p.shape == "Poly":
                q.polys = p.polys
            scene.append(q)
        for p in chair(biome).parts:
            q = Part(p.name, p.size, T((x - 4 - 3 * g, 0, -6)) @ p.cf, p.color, p.shape, p.plain)
            if p.shape == "Poly":
                q.polys = p.polys
            scene.append(q)
        names.append((label, x))
        x -= 16 + 9 * g
    cx = x / 2 + 10
    im = render(scene, eye=(cx + 10, 26, -95), target=(cx, 9, 0), W=2000, H=760, fov=40, outline=False)
    from PIL import ImageDraw
    import animal_designs as A
    dr = ImageDraw.Draw(im)
    # labels under each pair (projected roughly by x)
    im.save(os.path.join(out, "biome_dummies.png"))
    # each dummy on its own, close
    tiles = []
    for i, (label, ps) in enumerate(rows):
        g = GROW ** i
        cam = dict(eye=(-23 * g, 15 * g, -25 * g), target=(0, 7 * g, -0.5), W=400, H=460, fov=38, outline=False)
        tiles.append(render(ps, **cam))
    sheet = Image.new("RGB", (400 * len(tiles), 460))
    for i, t in enumerate(tiles):
        sheet.paste(t, (400 * i, 0))
    A.label(sheet, [r[0] for r in rows], 22).save(os.path.join(out, "biome_dummies_close.png"))
    ctiles = [render(chair(b).parts, eye=(-9, 7, -10), target=(0, 3.2, 0), W=320, H=360, fov=40, outline=False) for b in CHAIRS]
    cs = Image.new("RGB", (320 * len(ctiles), 360))
    for i, t in enumerate(ctiles):
        cs.paste(t, (320 * i, 0))
    A.label(cs, list(CHAIRS), 22).save(os.path.join(out, "biome_chairs.png"))
    print("written to", out)


def game():
    import chair_design
    os.makedirs(os.path.join("designs", "props"), exist_ok=True)
    meta = {}
    for i, d in enumerate(DUMMIES, 1):
        model, bones, parts, neck = dummy(d, i)
        name = "TrainingDummy" + d["biome"]
        write_luau(model, bones, parts, name, os.path.join("src", "shared", "Props", name + "Model.luau"))
        meta[d["biome"]] = neck
    for biome in CHAIRS:
        if biome == "Meadow":
            continue
        a = chair(biome)
        a.name = "TrainingChair" + biome
        import animal_designs as A
        model, _ = A.write_bbmodel(a.parts, a.name, None, bones=a.bones())
        model["animations"] = []
        path = os.path.join("designs", "props", a.name + ".bbmodel")
        with open(path, "w") as f:
            json.dump(model, f, separators=(",", ":"))
        B.ORDER = "XYZ"
        B.main(path, os.path.join("src", "shared", "Props", a.name + "Model.luau"))
    for b, n in meta.items():
        print(b, "neck", np.round(n["center"], 2), round(n["radius"], 2))


if __name__ == "__main__":
    if sys.argv[1:2] == ["game"]:
        game()
    else:
        main(*sys.argv[1:])
