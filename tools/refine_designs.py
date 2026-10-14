"""Refined animals (the animal refinement thread): redraws of in-game animals in the
converted pets' style (tools/convert_designs.py): chunky tiered blocks, real-depth details,
bone rest rotations for the pose, bold colours, and eyes that read against the coat.

Run: python3 tools/refine_designs.py <Name> [out_dir]
writes the model to designs/<biome>/<Name>.bbmodel and a static preview <Name>.png.
Animate after QM approves the look (tools/snow_rig.py for the Penguin).
"""

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
import convert_designs as C  # noqa: E402
from convert_designs import Conv, SIDES, X  # noqa: E402
from partlib import Part, render  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = "/mnt/project-files/animals/refine"


def prism_x(a, name, pts, x0, x1, color, bone):
    """Triangle (z, y) extruded along x: a side-profile wedge, like a beak."""
    k = a.k
    pts = [(z * k, y * k) for z, y in pts]
    x0, x1 = x0 * k, x1 * k
    faces = [[(x0, y, z) for z, y in pts], [(x1, y, z) for z, y in pts[::-1]]]
    for i, j in ((0, 1), (1, 2), (2, 0)):
        (za, ya), (zb, yb) = pts[i], pts[j]
        faces.append([(x0, ya, za), (x1, ya, za), (x1, yb, zb), (x0, yb, zb)])
    p = Part(name, (1, 1, 1), np.eye(4), color, "Poly")
    p.polys = [np.array(f, float) for f in faces]
    p.bone = bone
    a.parts.append(p)
    return p


# ---------------------------------------------------------------- penguin

def penguin():
    """An emperor-style penguin: a pear-shaped black body, a tiered white belly
    warming to gold at the chest, gold cheek patches, eyes on the black head so
    they read, a pointed two-part beak, flippers held out, big orange feet."""
    c = dict(black=(40, 46, 64), white=(250, 250, 250), gold=(255, 200, 60), cheek=(255, 170, 40),
             beak=(255, 140, 30), beak_lo=(230, 100, 30), foot=(255, 150, 30))
    a = Conv("Penguin", "Uncommon", 1.0)
    a.pivots["root"] = (0, 3.6, 0.2)
    # feet: wide orange paddles with three toes poking forward
    for side, sx in SIDES:
        leg = a.bone("Leg" + side, "root", (sx * 1.0, 0.7, -0.4))
        x0, x1 = X(sx, 0.25, 1.85)
        a.b("Foot" + side, (x0, 0, -1.9), (x1, 0.7, 0.4), c["foot"], leg)
        for i, (t0, t1) in enumerate(((0.25, 0.65), (0.85, 1.25), (1.45, 1.85))):
            x0, x1 = X(sx, t0, t1)
            a.b(f"Toe{side}{i}", (x0, 0, -2.5), (x1, 0.45, -1.9), c["foot"], leg)
    # body: wide at the bottom, narrower shoulders
    a.b("Body", (-2.3, 0.7, -1.6), (2.3, 4.5, 2.0), c["black"], "root")
    a.b("Chest", (-1.9, 4.5, -1.4), (1.9, 6.9, 1.7), c["black"], "root")
    # belly: tiers standing proud of the front, gold at the top
    a.b("Belly", (-1.8, 1.0, -2.2), (1.8, 4.5, -1.6), c["white"], "root")
    a.b("Tummy", (-1.4, 1.4, -2.6), (1.4, 3.8, -2.2), c["white"], "root")
    a.b("Bib", (-1.5, 4.5, -2.0), (1.5, 5.8, -1.4), c["white"], "root")
    a.b("BibGold", (-1.5, 5.8, -2.0), (1.5, 6.6, -1.4), c["gold"], "root")
    # tail: a short black wedge out the back
    tail = a.bone("Tail", "root", (0, 1.6, 2.0), (-20, 0, 0))
    prism_x(a, "Tail", [(2.0, 0.9), (2.0, 1.9), (3.1, 0.9)], -0.8, 0.8, c["black"], tail)
    # flippers: held a little out from the shoulders, tapering to the tip
    for side, sx in SIDES:
        wing = a.bone("Wing" + side, "root", (sx * 1.9, 6.4, 0.1), (0, 0, sx * 12))
        x0, x1 = X(sx, 1.9, 2.5)
        a.b("Flipper" + side, (x0, 3.9, -0.9), (x1, 6.5, 1.1), c["black"], wing)
        a.b("FlipperTip" + side, (x0, 2.2, -0.6), (x1, 3.9, 0.8), c["black"], wing)
    # head: black, chin up a touch, gold cheek patches standing out of the sides
    head = a.bone("neck", "root", (0, 6.9, 0), (8, 0, 0))
    a.b("Head", (-1.7, 6.7, -1.8), (1.7, 9.3, 1.4), c["black"], head)
    a.b("Crown", (-1.35, 9.3, -1.5), (1.35, 9.9, 1.1), c["black"], head)
    for side, sx in SIDES:
        x0, x1 = X(sx, 1.7, 1.95)
        a.b("Cheek" + side, (x0, 6.9, -0.7), (x1, 8.1, 0.7), c["cheek"], head)
        # eye: a big white plate, a smaller pupil low and toward the beak
        x0, x1 = X(sx, 0.3, 1.4)
        a.box("Eye" + side, (x0, 7.9, -1.8 - A.PLATE), (x1, 9.15, -1.8), A.EYE_WHITE, head)
        x0, x1 = X(sx, 0.45, 0.95)
        a.box("Pupil" + side, (x0, 8.05, -1.8 - A.PLATE - 0.03), (x1, 8.75, -1.8 - A.PLATE), A.PUPIL, head)
    # beak: a pointed upper wedge over a shorter, darker lower one
    prism_x(a, "Beak", [(-1.8, 7.35), (-1.8, 7.95), (-3.5, 7.35)], -0.55, 0.55, c["beak"], head)
    prism_x(a, "BeakLow", [(-1.8, 7.35), (-1.8, 6.95), (-2.9, 7.35)], -0.45, 0.45, c["beak_lo"], head)
    a.meta = {"seat": (0, 9.9, -0.2), "neck_loop": {"center": (0, 7.9, -0.2), "radius": 2.2}}
    return a


# ---------------------------------------------------------------- snowman

def snowball(a, name, x, z, y0, y1, color, bone, r=0.3, inset=0.25):
    """A rounded block: a core x by z, plus two bands r wider in x and in z (inset
    from the top and bottom), so it reads round from every side."""
    a.b(name, (-x, y0, -z), (x, y1, z), color, bone)
    a.b(name + "BandX", (-x - r, y0 + inset + r, -z + r), (x + r, y1 - inset - r, z - r), color, bone)
    a.b(name + "BandZ", (-x + r, y0 + inset + r, -z - r), (x - r, y1 - inset - r, z + r), color, bone)


def snowman():
    """Three rounded snowballs, the Horse's eyes, a coal smile, a carrot nose, a red striped
    scarf with a hanging end, a matching beanie with a pom-pom, and stick arms
    raised in a cheer."""
    c = dict(snow=(246, 249, 255), shade=(226, 236, 252), coal=(40, 42, 52), carrot=(250, 132, 40),
             stick=(124, 82, 48), red=(230, 50, 60), stripe=(255, 255, 255))
    a = Conv("Snowman", "Rare", 1.0)
    a.pivots["root"] = (0, 2.1, 0)
    snowball(a, "Bottom", 2.5, 2.3, 0, 4.2, c["snow"], "root", r=0.35)
    mid = a.bone("Mid", "root", (0, 4.2, 0))
    snowball(a, "Middle", 1.9, 1.75, 4.2, 7.3, c["shade"], mid)
    # coal buttons standing out of the middle's front band
    for i, y in enumerate((4.6, 5.7)):
        a.b(f"Button{i}", (-0.3, y, -2.35), (0.3, y + 0.6, -2.05), c["coal"], mid)
    # scarf: a ring round the neck and an end hanging down the front left
    a.b("Scarf", (-2.0, 6.9, -1.9), (2.0, 7.8, 1.9), c["red"], mid)
    a.b("ScarfEnd", (-1.45, 4.9, -2.3), (-0.65, 6.9, -2.05), c["red"], mid)
    a.b("ScarfStripe", (-1.45, 5.5, -2.35), (-0.65, 5.8, -2.05), c["stripe"], mid)
    a.b("ScarfFringe", (-1.45, 4.6, -2.3), (-0.65, 4.9, -2.05), c["stripe"], mid)
    head = a.bone("neck", "Mid", (0, 7.3, 0))
    snowball(a, "Head", 1.5, 1.4, 7.3, 10.6, c["snow"], head, r=0.25, inset=0.15)
    # the Horse's eyes, facing front: a 1x1 stud white plate, a 0.5 x 0.6 pupil
    z = -1.65
    for side, sx in SIDES:
        x0, x1 = X(sx, 0.25, 1.25)
        a.box("Eye" + side, (x0, 9.0, z - A.PLATE), (x1, 10.0, z), A.EYE_WHITE, head)
        x0, x1 = X(sx, 0.5, 1.0)
        a.box("Pupil" + side, (x0, 9.1, z - A.PLATE - 0.03), (x1, 9.7, z - A.PLATE), A.PUPIL, head)
    # carrot nose, pointing forward and a touch down
    nose = a.bone("Nose", head, (0, 8.55, -1.65), (-8, 0, 0))
    a.b("Carrot", (-0.3, 8.25, -2.35), (0.3, 8.85, -1.6), c["carrot"], nose)
    a.pyr("CarrotTip", (-0.3, 8.25, -2.35), (0.3, 8.85, -2.35), "-z", 1.4, c["carrot"], nose)
    # coal smile: five lumps in an arc
    for i, (x, y) in enumerate(((-0.8, 8.05), (-0.4, 7.85), (0, 7.8), (0.4, 7.85), (0.8, 8.05))):
        a.b(f"Mouth{i}", (x - 0.15, y, -1.9), (x + 0.15, y + 0.25, -1.6), c["coal"], head)
    # beanie: a red cap with a white cuff and a pom-pom
    a.b("Beanie", (-1.35, 10.6, -1.25), (1.35, 11.4, 1.25), c["red"], head)
    a.b("BeanieCuff", (-1.6, 10.3, -1.5), (1.6, 10.8, 1.5), c["stripe"], head)
    a.b("PomPom", (-0.4, 11.4, -0.4), (0.4, 12.1, 0.4), c["stripe"], head)
    # stick arms out of the middle, raised, with twig fingers
    for side, sx in SIDES:
        arm = a.bone("Arm" + side, mid, (sx * 1.9, 6.3, 0), (0, 0, sx * 22))
        x0, x1 = X(sx, 1.9, 4.6)
        a.b("Stick" + side, (x0, 6.1, -0.2), (x1, 6.5, 0.2), c["stick"], arm)
        x0, x1 = X(sx, 4.2, 4.6)
        a.b("Twig" + side, (x0, 6.5, -0.2), (x1, 7.6, 0.2), c["stick"], arm)
        x0, x1 = X(sx, 4.6, 5.3)
        a.b("Finger" + side, (x0, 6.1, -0.2), (x1, 6.5, 0.2), c["stick"], arm)
        x0, x1 = X(sx, 3.0, 3.35)
        a.b("Twig2" + side, (x0, 6.5, -0.2), (x1, 7.1, 0.2), c["stick"], arm)
    a.meta = {"seat": (0, 12.1, 0), "neck_loop": {"center": (0, 8.9, 0), "radius": 2.1}}
    return a


BIOME = {"Penguin": "snow", "Snowman": "snow"}
BUILDERS = {"Penguin": penguin, "Snowman": snowman}


def preview(name, out, old=None):
    """3/4 front and side views of the new model, beside the old one when given."""
    a, model, parts = C.build(BUILDERS[name])
    path = os.path.join(ROOT, "designs", BIOME[name], name + ".bbmodel")
    with open(path, "w") as f:
        json.dump(model, f, separators=(",", ":"))
    sets = [("new", parts)]
    if old:
        from snow_rig import posed
        op = posed(json.load(open(old)))
        for p in op:
            if p.name.startswith(C.PLAIN):
                p.plain = True
        sets.insert(0, ("old", op))
    W = 320
    ims = []
    lo, hi = C.bounds(parts)
    c = (lo + hi) / 2
    r = np.linalg.norm(hi - lo) / 2
    for label, ps in sets:
        for v in ((-19, 9, -21), (-30, 4, 0)):
            v = np.array(v, float)
            eye = c + v / np.linalg.norm(v) * r / np.tan(np.radians(17)) * 1.05
            ims.append(A.label(render(ps, eye=eye, target=c, W=W, H=W, fov=34), [f"{name} {label}"], 15))
    sheet = Image.new("RGB", (W * len(ims), ims[0].height))
    for i, im in enumerate(ims):
        sheet.paste(im, (i * W, 0))
    os.makedirs(out, exist_ok=True)
    sheet.save(os.path.join(out, name + ".png"))
    print("wrote", path, len(parts), "parts")
    return a


if __name__ == "__main__":
    preview(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else OUT,
            old=sys.argv[3] if len(sys.argv) > 3 else None)


# ---------------------------------------------------------------- horse eyes

def horse_eyes(path):
    """Give a .bbmodel the Horse's eyes (QM: the default style, no rims): a 1x1 stud white
    plate, a pupil 0.5 wide and 0.6 tall, 0.1 stud up from the plate's bottom, standing
    0.03 proud. On a side eye the pupil sits 0.025 back from the plate's front edge (as on
    the Horse); on a front eye it is centred. Removes any EyeSocket parts."""
    m = json.load(open(path))
    socks = {e["uuid"] for e in m["elements"] if e["name"].startswith("EyeSocket")}
    els = {e["name"]: e for e in m["elements"]}
    for side in ("L", "R"):
        eye, pupil = els["Eye" + side], els.get("Pupil" + side)
        lo, hi = np.array(eye["from"], float), np.array(eye["to"], float)
        axis = int(np.argmin(hi - lo))
        out = -1 if pupil["from"][axis] < lo[axis] else 1
        if socks:  # the eye was moved out onto its socket: put it back on the face
            d = out * (hi[axis] - lo[axis])
            lo[axis] -= d
            hi[axis] -= d
        c = (lo + hi) / 2
        elo, ehi = c - 5, c + 5
        elo[axis], ehi[axis] = lo[axis], hi[axis]
        plo, phi = elo.copy(), ehi.copy()
        face = hi[axis] if out > 0 else lo[axis]
        plo[axis], phi[axis] = sorted((face - out * (hi[axis] - lo[axis]), face + out * 0.3))
        plo[1], phi[1] = elo[1] + 1, elo[1] + 7
        h = 2 if axis == 0 else 0  # the pupil's across axis
        if axis == 0:  # side eye: pupil at the front (-z) edge
            plo[h], phi[h] = elo[h] + 0.25, elo[h] + 5.25
        else:
            plo[h], phi[h] = c[h] - 2.5, c[h] + 2.5
        for e, l, u in ((eye, elo, ehi), (pupil, plo, phi)):
            e["from"], e["to"] = [round(v, 4) for v in l], [round(v, 4) for v in u]
            e["origin"] = [round(v, 4) for v in (l + u) / 2]
    m["elements"] = [e for e in m["elements"] if e["uuid"] not in socks]

    def drop(node):
        for c in node:
            if isinstance(c, dict):
                c["children"] = [x for x in c["children"] if not (isinstance(x, str) and x in socks)]
                drop(c["children"])

    drop(m["outliner"])
    m["outliner"] = [x for x in m["outliner"] if not (isinstance(x, str) and x in socks)]
    with open(path, "w") as f:
        json.dump(m, f, separators=(",", ":"))
    print(path, "horse eyes")

HEAD_KEYS = ("head", "eye", "snout", "muzzle", "face", "nose", "beak", "jaw", "forehead", "hat")


def headshot(name, path, out=os.path.join(ROOT, "assets", "ui")):
    """Pets-panel headshot (assets/ui/Pet<Name>.png) from a .bbmodel file, framed like
    tools/snow_headshots.py, for models whose file (not a builder) is the source of truth."""
    import snow_designs as SD
    from snow_rig import posed
    parts = posed(json.load(open(path)))
    for p in parts:
        if p.name.startswith(C.PLAIN) or p.name.startswith(SD.PLAIN):
            p.plain = True
    head = [p for p in parts if any(k in p.name.lower() for k in HEAD_KEYS)]
    lo, hi = SD.bounds(head)
    c = (lo + hi) / 2
    size = np.linalg.norm(hi - lo)
    target = c - np.array([0, size * 0.18, 0])
    blo, bhi = SD.bounds(parts)
    eye = target + SD.Q34_DIR * max(size * 3.1, (bhi[1] - blo[1]) * 1.6)
    im = render(parts, eye=eye, target=target, W=512, H=512, fov=30, transparent=True)
    im.save(os.path.join(out, f"Pet{name}.png"))
    print("wrote", f"Pet{name}.png")
