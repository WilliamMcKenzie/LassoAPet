"""Spinosaurus (QM Oct 11): "make a new dinosaur same style as existing TRex".

Reads QM's animated T-Rex (/mnt/project-files/animals/trex/v2/TRex_anim.bbmodel: bones,
legs, body and idle/walk/run kept) and makes it a Spinosaurus:
  - recoloured teal green with darker stripes (cream jaw, belly and teeth colours kept),
  - a long croc snout: the upper jaw carries on past the head, narrower, and the lower jaw
    (Jaw bone, so it still opens) matches it, both with extra teeth,
  - a tall sail along the back: dark red spines with gold tips, the webbing between them in
    stepped columns, red at the base to orange at the top (real blocks, no plates).
Static extras on the existing bones, so QM's animations still fit. Preview with ZYX.

Run from the repo root: python3 tools/spinosaurus.py [gifs]
Writes Spinosaurus.bbmodel and renders in /mnt/project-files/animals/spinosaurus/.
"""

import base64
import io
import json
import math
import os
import sys
import uuid

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
import horse_rig  # noqa: E402
from partlib import render  # noqa: E402
from rock_hog import cube, spike  # noqa: E402
from snow_rig import posed  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
TREX = "/mnt/project-files/animals/trex/v2/TRex_anim.bbmodel"
HORSE = os.path.join(ROOT, "designs", "animals", "Horse.bbmodel")
OUT = "/mnt/project-files/animals/spinosaurus"

RECOLOR = {(240, 140, 52): (64, 172, 132), (168, 82, 32): (36, 116, 92), (90, 44, 20): (24, 76, 60)}
SAIL_LOW, SAIL_HIGH, SPINE, SPINE_TIP = (2 * 0, 2), (2, 2), (4, 2), (6, 2)
NEW = {SAIL_LOW: (214, 52, 44), SAIL_HIGH: (255, 136, 40), SPINE: (150, 28, 40), SPINE_TIP: (255, 214, 90)}
BODY, STRIPE, CREAM, TOOTH = (0, 0), (2, 0), (6, 0), (14, 0)
NOSTRIL = (12, 0)

# sail: spine z positions along the back and their heights above the body's top (y 102)
SAIL_Z = [-40, -31, -22, -13, -4, 5, 14, 23, 32, 41, 50]
JAW_REST = 15
TAIL_SAIL = ("SailSpine10", "SailSpineTip10", "Sail9_", "SailTop9_")  # past the body (z 40): rides the Tail bone
SAIL_TOP = 102.0


def sail_h(z):
    """Sail height above the back at z: a hump peaking a little behind the shoulders."""
    return 14 + 50 * max(0.0, 1 - ((z - 4) / 52) ** 2) ** 0.6  # a wide rounded arch


def find(nodes, gid):
    for n in nodes:
        if isinstance(n, dict):
            if n["uuid"] == gid:
                return n
            r = find(n["children"], gid)
            if r:
                return r


def tooth(name, x, y, z, down=True, w=1.6, h=5.0):
    """Little fang: pyramid hanging down (upper jaw) or standing up (lower jaw)."""
    if down:
        return spike(name, (x - w, 0, z - w), (x + w, y, z + w), (x, y - h, z), TOOTH) if False else _down(name, x, y, z, w, h)
    return spike(name, (x - w, 0, z - w), (x + w, y, z + w), (x, y + h, z), TOOTH)


def _down(name, x, y, z, w, h):
    e = spike(name, (x - w, 0, z - w), (x + w, y, z + w), (x, y - h, z), TOOTH)
    # flip the winding so the faces point outward when the apex is below the base
    for f in e["faces"].values():
        f["vertices"] = f["vertices"][::-1]
    return e


def spino(m):
    m = json.loads(json.dumps(m))
    m["name"] = "Spinosaurus"
    t = m["textures"][0]
    im = Image.open(io.BytesIO(base64.b64decode(t["source"].split(",", 1)[1]))).convert("RGBA")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if (r, g, b) in RECOLOR:
                px[x, y] = (*RECOLOR[(r, g, b)], a)
    for (cx, cy), col in NEW.items():
        for dx in (0, 1):
            for dy in (0, 1):
                px[cx + dx, cy + dy] = (*col, 255)
    buf = io.BytesIO()
    im.save(buf, "PNG")
    t["source"] = "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()

    groups = {g["name"]: g for g in m["groups"]}

    def add(bone, els):
        m["elements"].extend(els)
        find(m["outliner"], groups[bone]["uuid"])["children"].extend(e["uuid"] for e in els)

    # long croc snout: upper jaw on neck (the head's bone), lower on Jaw
    up = [cube("SnoutLong", (-13, 98, -152), (13, 114, -118), BODY), cube("SnoutStripe", (-13.2, 106, -140), (13.2, 114.2, -134), STRIPE),
          cube("SnoutTip", (-15, 96, -162), (15, 112, -150), BODY), cube("NostrilLongL", (-13.6, 108, -158), (-13, 111, -154), NOSTRIL),
          cube("NostrilLongR", (13, 108, -158), (13.6, 111, -154), NOSTRIL), cube("PalateLong", (-11, 97.8, -158), (11, 98, -118), CREAM)]
    for i, z in enumerate((-124, -134, -144, -156)):
        for side, x in (("L", -11), ("R", 11)):
            up.append(_down(f"ToothLong{side}{i}", x, 98, z, 1.5, 5.0))
    add("neck", up)
    low = [cube("JawLong", (-11, 75, -158), (11, 85, -116), CREAM), cube("JawLongFloor", (-9, 85, -156), (9, 85.2, -116), CREAM)]
    for i, z in enumerate((-122, -132, -142, -152)):
        for side, x in (("L", -9), ("R", 9)):
            low.append(tooth(f"ToothJaw{side}{i}", x, 85, z, down=False, w=1.4, h=4.5))
    add("Jaw", low)
    # the sail
    sail = []
    for i, z in enumerate(SAIL_Z):
        h = sail_h(z) + 8
        sail.append(cube(f"SailSpine{i}", (-2.4, SAIL_TOP - 2, z - 2.4), (2.4, SAIL_TOP + h, z + 2.4), SPINE))
        sail.append(spike(f"SailSpineTip{i}", (-2.4, 0, z - 2.4), (2.4, SAIL_TOP + h, z + 2.4), (0, SAIL_TOP + h + 9, z), SPINE_TIP))
    for i in range(len(SAIL_Z) - 1):
        z0, z1 = SAIL_Z[i] + 2.4, SAIL_Z[i + 1] - 2.4
        for j, (a, b) in enumerate(((z0, (z0 + z1) / 2), ((z0 + z1) / 2, z1))):
            h = sail_h((a + b) / 2)
            split = SAIL_TOP + h * 0.4
            sail.append(cube(f"Sail{i}_{j}", (-1.4, SAIL_TOP - 2, a), (1.4, split, b), SAIL_LOW))
            sail.append(cube(f"SailTop{i}_{j}", (-1.4, split, a), (1.4, SAIL_TOP + h, b), SAIL_HIGH))
    add("root", [e for e in sail if not e["name"].startswith(TAIL_SAIL)])
    add("Tail", [e for e in sail if e["name"].startswith(TAIL_SAIL)])
    # the long jaw hangs too far at the T-Rex's -35 rest: open it less (-15), and scale the
    # animations' shutting turns to match so they still close it exactly
    k = JAW_REST / 35.0
    for g in m["groups"]:
        if g["name"] in ("Jaw", "Jaw2"):
            g["rotation"] = [-JAW_REST, 0, 0]
            for a in m["animations"]:
                for kf in a["animators"].get(g["uuid"], {}).get("keyframes", []):
                    if kf["channel"] == "rotation":
                        for dp in kf["data_points"]:
                            dp["x"] = round(float(dp["x"]) * k, 3)
    return m


def parts(model, anim=None, t=0.0):
    ps = posed(model, anim, t)
    for p in ps:
        if p.name.startswith(("Eye", "Pupil")):
            p.plain = True
    return ps


def main(out=OUT):
    horse_rig.EULER = "ZYX"
    os.makedirs(out, exist_ok=True)
    m = spino(json.load(open(TREX)))
    with open(os.path.join(out, "Spinosaurus.bbmodel"), "w") as f:
        json.dump(m, f, separators=(",", ":"))
    T = 480
    views = [dict(eye=(-42, 22, -46), target=(0, 9, -2), W=T, H=T, fov=40), dict(eye=(-62, 9, -2), target=(0, 9, -2), W=T, H=T, fov=38),
             dict(eye=(-14, 16, -56), target=(0, 10, -6), W=T, H=T, fov=34)]
    sheet = Image.new("RGB", (T * 3, T))
    for i, v in enumerate(views):
        sheet.paste(render(parts(m), **v), (i * T, 0))
    A.label(sheet, ["Spinosaurus", "side", "face"], 22).save(os.path.join(out, "Spinosaurus.png"))
    cam = dict(eye=(-46, 18, -46), target=(0, 8, 0), W=T, H=T, fov=40)
    pair = Image.new("RGB", (T * 2, T))
    pair.paste(render(parts(json.load(open(HORSE))), **cam), (0, 0))
    pair.paste(render(parts(m), **cam), (T, 0))
    A.label(pair, ["Horse", "Spinosaurus"], 22).save(os.path.join(out, "Spinosaurus_vs_horse.png"))
    if "gifs" in sys.argv:
        for name, n in (("idle", 20), ("walk", 16), ("gallop", 16)):
            anim = next((x for x in m["animations"] if x["name"] == name), None)
            if not anim:
                continue
            L = anim["length"]
            A.gif(os.path.join(out, f"Spinosaurus_{name}.gif"),
                  [A.label(render(parts(m, anim, L * i / n), **views[0]), [name], 22) for i in range(n)], fps=n / L)
    print("wrote", out, len(m["elements"]), "elements")



# ---------------------------------------------------------------- on QM's edit (Oct 11 09:08)
# QM rebuilt the sail as a fan of nine thin spines, each turned about X, and started the
# webbing (thin orange slabs turned with the spines) at the front. finish_sail fills every
# gap QM left: each gap gets three stacked slabs, each turned to the two spines' mean angle
# and as wide as the gap at its top, so they meet the spines all the way up with no holes.


def _spine_line(e):
    """A turned spine cube's bottom and top centre points in model space (y, z)."""
    a = math.radians(e.get("rotation", [0, 0, 0])[0])
    oy, oz = e["origin"][1], e["origin"][2]
    zc = (e["from"][2] + e["to"][2]) / 2

    def rot(y, z):
        dy, dz = y - oy, z - oz
        return (oy + dy * math.cos(a) - dz * math.sin(a), oz + dy * math.sin(a) + dz * math.cos(a))

    return rot(e["from"][1], zc), rot(e["to"][1], zc), a


def finish_sail(m):
    web_uv = next(e for e in m["elements"] if e["name"].startswith("SailSpine") and e["to"][0] - e["from"][0] < 2)["faces"]
    spines = sorted((e for e in m["elements"] if e["name"].startswith("SailSpine") and e["to"][0] - e["from"][0] > 4),
                    key=lambda e: (e["from"][2] + e["to"][2]) / 2)
    root = next(g for g in m["groups"] if g["name"] == "root")
    node = find(m["outliner"], root["uuid"])
    # gaps QM already filled: the webs' own spine (origin) z
    filled = {round(e["origin"][2]) for e in m["elements"] if e["name"].startswith("SailSpine") and e["to"][0] - e["from"][0] < 2}
    new = []
    for i in range(len(spines) - 1):
        s0, s1 = spines[i], spines[i + 1]
        if round(s0["origin"][2]) in filled:
            continue
        (b0, t0, a0), (b1, t1, a1) = _spine_line(s0), _spine_line(s1)
        a = (a0 + a1) / 2
        d = (math.cos(a), math.sin(a))  # the slab's up (y, z)
        n = (-math.sin(a), math.cos(a))  # across the gap (y, z)
        for j in range(3):
            f0, f1 = j / 3, (j + 1) / 3
            p = [(b0[0] + (t0[0] - b0[0]) * f, b0[1] + (t0[1] - b0[1]) * f) for f in (f0, f1)]
            q = [(b1[0] + (t1[0] - b1[0]) * f, b1[1] + (t1[1] - b1[1]) * f) for f in (f0, f1)]
            pts = p + q
            cy = sum(v[0] for v in pts) / 4
            cz = sum(v[1] for v in pts) / 4
            along = [(v[0] - cy) * d[0] + (v[1] - cz) * d[1] for v in pts]
            across = [(v[0] - cy) * n[0] + (v[1] - cz) * n[1] for v in pts]
            h0, h1 = min(along) - 1.0, max(along) + 1.0
            w0, w1 = min(across), max(across)
            e = {"name": f"SailWeb{i}_{j}", "type": "cube", "uuid": str(uuid.uuid4()), "box_uv": False,
                 "from": [-0.5, cy + h0, cz + w0], "to": [0.5, cy + h1, cz + w1], "origin": [0, cy, cz],
                 "rotation": [round(math.degrees(a), 3), 0, 0], "autouv": 0, "color": 0,
                 "faces": json.loads(json.dumps(web_uv))}
            new.append(e)
    # the front web (before the first spine) mirrored onto the back
    front = min((e for e in m["elements"] if e["name"].startswith("SailSpine") and e["to"][0] - e["from"][0] < 2),
                key=lambda e: e["origin"][2])
    back = json.loads(json.dumps(front))
    back.update(name="SailWebBack", uuid=str(uuid.uuid4()), origin=[0, front["origin"][1], -front["origin"][2]],
                rotation=[-front["rotation"][0], 0, 0])
    back["from"] = [front["from"][0], front["from"][1], -front["to"][2]]
    back["to"] = [front["to"][0], front["to"][1], -front["from"][2]]
    new.append(back)
    m["elements"] += new
    node["children"] += [e["uuid"] for e in new]
    return m


def animations(m):
    """The Spinosaurus's own moves (QM's file holds the jaw open -15 at rest; +X shuts it, so
    jaw keys stay within 0..15). Heavier and swayier than the T-Rex: the long tail swings
    wide, the sail rolls with the body, and idle dips the snout to fish, snaps sideways, then
    rears up with a roar."""
    from snake_rig import track
    from snow_rig import bump, grounded
    s, TAU = math.sin, 2 * math.pi
    feet = {e["name"] for e in m["elements"] if e["name"].startswith(("Foot", "Toe", "Claw"))}

    def jaws(L, f, n):
        return {j: [track(L, lambda u: (f(u), 0, 0), n)] for j in ("Jaw", "Jaw2")}

    def run(L, stride, lean, roll, sway, bob, hop, shut, n=16):
        tr = {"root": [track(L, lambda u: (lean, 0, roll * s(TAU * u)), n)]}
        for side, ph in (("L", 0.0), ("R", 0.5)):
            tr["Leg" + side] = [track(L, lambda u, ph=ph: (-lean + stride * s(TAU * (u + ph)), 0, 0), n)]
            tr["Arm" + side] = [track(L, lambda u, ph=ph: (14 * s(TAU * (u + ph + 0.25)), 0, 0), n)]
        tr["neck"] = [track(L, lambda u: (-lean * 0.6 + bob * s(2 * TAU * u), -sway * 0.5 * s(TAU * u), 0), n)]
        tr["Tail"] = [track(L, lambda u: (-lean * 0.5 + 2 * s(2 * TAU * u), sway * s(TAU * u - 0.5), 0), n)]
        tr["Tail2"] = [track(L, lambda u: (2 * s(2 * TAU * u - 1), sway * 1.5 * s(TAU * u - 1.4), 0), n)]
        tr.update(jaws(L, lambda u: shut * (0.5 + 0.5 * s(2 * TAU * u)), n))
        tr["root"] = grounded(m, L, tr, feet, n, extra=lambda u: hop * abs(s(TAU * u)))
        return L, tr

    out = {}
    L = 5.0
    dip = lambda u: bump(u, 0.3, 0.12)  # noqa: E731  fishing: snout down
    snap = lambda u: bump(u, 0.45, 0.04)  # noqa: E731  quick sideways snap
    roar = lambda u: bump(u, 0.78, 0.08)  # noqa: E731
    out["idle"] = (L, {
        "root": [track(L, lambda u: (1.5 * s(TAU * u) + 6 * dip(u) - 6 * roar(u), 0, 0), 40)],
        "neck": [track(L, lambda u: (14 * dip(u) - 16 * roar(u) + 1.5 * s(TAU * u), 26 * snap(u) + 10 * s(TAU * u) * (1 - roar(u)), 0), 80)],
        "Tail": [track(L, lambda u: (-4 * dip(u), 12 * s(TAU * u + 1), 0), 40)],
        "Tail2": [track(L, lambda u: (0, 15 * s(TAU * u + 0.2), 0), 40)],
        "ArmL": [track(L, lambda u: (-20 * roar(u) + 10 * dip(u), 0, 0), 60)],
        "ArmR": [track(L, lambda u: (-20 * roar(u) + 10 * dip(u), 0, 0), 60)],
        **jaws(L, lambda u: 15 * (1 - roar(u)) * (1 - snap(u)) * (0.5 + 0.5 * (1 - dip(u))), 80),
    })
    out["walk"] = run(1.2, stride=22, lean=3, roll=5, sway=14, bob=3, hop=0, shut=12)
    out["gallop"] = run(0.6, stride=40, lean=11, roll=4, sway=9, bob=5, hop=9, shut=8)
    return out


def animate(src, dst=os.path.join(OUT, "Spinosaurus_anim.bbmodel")):
    """QM's edit (src): finish the sail webbing, replace the animations, write dst + GIFs."""
    horse_rig.EULER = "ZYX"
    from horse_rig import write_animations
    from snow_rig import group_ids
    m = finish_sail(json.load(open(src)))
    m["animations"] = []
    write_animations(m, group_ids(m), animations(m))
    with open(dst, "w") as f:
        json.dump(m, f, separators=(",", ":"))
    T = 480
    views = [dict(eye=(-46, 22, -50), target=(0, 9, -2), W=T, H=T, fov=40), dict(eye=(-66, 9, -2), target=(0, 10, -2), W=T, H=T, fov=38),
             dict(eye=(-14, 16, -60), target=(0, 10, -6), W=T, H=T, fov=34)]
    sheet = Image.new("RGB", (T * 3, T))
    for i, v in enumerate(views):
        sheet.paste(render(parts(m), **v), (i * T, 0))
    A.label(sheet, ["Spinosaurus", "side", "face"], 22).save(os.path.join(OUT, "Spinosaurus_anim.png"))
    if "gifs" in sys.argv:
        for name, n in (("idle", 40), ("walk", 16), ("gallop", 12)):
            anim = next(x for x in m["animations"] if x["name"] == name)
            L = anim["length"]
            A.gif(os.path.join(OUT, f"Spinosaurus_{name}.gif"),
                  [A.label(render(parts(m, anim, L * i / n), **views[1]), [name], 22) for i in range(n)], fps=n / L)
    print("wrote", dst, len(m["elements"]), "elements")


if __name__ == "__main__":
    animate(sys.argv[2]) if sys.argv[1:2] == ["animate"] else main()
