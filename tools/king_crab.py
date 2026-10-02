"""The King Crab (Epic, Ocean, medium) from QM's model (designs/ocean/KingCrab_QM.bbmodel).

Run: python3 tools/king_crab.py [out_dir]

QM's file has the shape and the bone tree but no colours or animations. This
script keeps every block where QM put it and:
  - colours the parts: red shell over a pale underside, gold spikes along the
    back, red legs with darker feet, red claws with dark pincer tips;
  - names the bones the game needs (king_crab -> root, face -> neck) and moves
    the pivots of bones that have no rest rotation to their real joints
    (shoulders, wrists, pincer hinges, hips, knees, mandibles), which doesn't
    move any block at rest;
  - puts the Horse's googly eyes on top of the eye stalks;
  - writes idle, walk and gallop, and the Pets headshot.
Output: designs/ocean/KingCrab.bbmodel (converted by bbmodel_to_luau.py).

QM's left claw dips below the floor at rest, so every animation holds the claws
raised (CLAW_LIFT) and the feet stand on y = 0.
"""

import json
import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import snake_design as S  # noqa: E402
from horse_rig import element_polys, write_animations  # noqa: E402
from partlib import render  # noqa: E402
from snake_rig import track  # noqa: E402
import animal_designs as A  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
SRC = os.path.join(ROOT, "designs", "ocean", "KingCrab_QM.bbmodel")
MODEL = os.path.join(ROOT, "designs", "ocean", "KingCrab.bbmodel")
TAU = 2 * math.pi

COLORS = {"shell": (226, 58, 48), "under": (252, 196, 150), "gold": (255, 196, 64), "stalk": (240, 96, 62),
          "cream": (250, 226, 190), "leg": (232, 70, 52), "shin": (244, 104, 66), "dark": (160, 32, 40),
          "white": (255, 255, 255), "black": (20, 20, 24)}
TEX = {n: i for i, n in enumerate(COLORS)}

# bone renames, and new pivots (Blockbench units) for bones without a rest rotation
RENAME = {"king_crab": "root", "face": "neck"}
PIVOTS = {"root": (0, 11, 0), "neck": (0, 20, -14),
          "mandible0": (4.4, 14, -15), "mandible1": (-4.4, 14, -15),
          "leg0": (11, 12, 4), "leg2": (-11, 12, 4),
          "bottomleg0": (26, 20, 4), "bottomleg1": (25, 20, 12.8),
          "bottomleg2": (-26, 20, 4), "bottomleg3": (-25, 20, 12.8),
          "pincer0": (14, 14.5, -5), "claw": (20, 14, -16), "top_pincer": (22, 6, -29),
          "pincer1": (-14, 10, -6), "top_pincer2": (-12, 5, -17)}
CLAW_LIFT = {"pincer0": 10.0, "pincer1": 26.0}  # degrees, held in every animation


def color_of(e, index):
    n = e["name"]
    if n == "body":
        return "under" if index == 1 else "shell"
    if n == "frills":
        return "gold"
    if n == "face":
        return "stalk"
    if n.startswith("mandible"):
        return "cream"
    if n.startswith("bottompincer"):
        return "dark"
    if n.startswith("bottomleg"):
        return "shin"
    if n.startswith("leg"):
        return "leg"
    if n.startswith("top_pincer"):
        return "dark"
    if n in ("claw", "claws"):
        return "shell" if index == 0 else "dark"
    return "shell"


def build():
    m = json.load(open(SRC))
    m["name"] = "KingCrab"
    m["textures"] = [S.solid_texture(n, c) for n, c in COLORS.items()]
    seen = {}
    for e in m["elements"]:
        k = seen.get(e["name"], 0)
        seen[e["name"]] = k + 1
        tex = TEX[color_of(e, k)]
        for f in e["faces"].values():
            f["texture"] = tex
    for g in m["groups"]:
        g["name"] = RENAME.get(g["name"], g["name"])
        if g["name"] in PIVOTS:
            assert not any(g.get("rotation") or (0, 0, 0)), g["name"]
            g["origin"] = list(PIVOTS[g["name"]])

    # googly eyes on the stalk tips, on the neck bone
    neck = next(g for g in m["groups"] if g["name"] == "neck")
    node = find_node(m["outliner"], neck["uuid"])
    E = 7.0  # eye block, Blockbench units
    for side, sx in (("L", -1), ("R", 1)):
        stalk = next(e for e in m["elements"] if e["name"] == "face" and np.sign(np.vstack(element_polys(e))[:, 0].mean()) == sx)
        pts = np.vstack(element_polys(stalk))
        tip = pts[np.argsort(pts[:, 1])[-4:]].mean(0)
        c = tip + np.array([0, E / 2 - 1.5, 0])
        eye = cube("Eye" + side, c, (E, E, E), TEX["white"])
        pupil = cube("Pupil" + side, c + np.array([0, -0.1 * E, -E / 2 - 0.15]), (0.5 * E, 0.6 * E, 0.3), TEX["black"])
        for el in (eye, pupil):
            m["elements"].append(el)
            node["children"].append(el["uuid"])
    floor(m)
    return m


def cube(name, center, size, tex):
    c, h = np.array(center, float), np.array(size, float) / 2
    return {"name": name, "type": "cube", "uuid": S.uid(), "box_uv": False, "autouv": 0, "color": 0,
            "from": [round(x, 4) for x in c - h], "to": [round(x, 4) for x in c + h],
            "origin": [round(x, 4) for x in c], "rotation": [0, 0, 0],
            "faces": {f: {"uv": [0, 0, 1, 1], "texture": tex} for f in ("north", "east", "south", "west", "up", "down")}}


def find_node(nodes, uuid):
    for n in nodes:
        if isinstance(n, dict):
            if n["uuid"] == uuid:
                return n
            r = find_node(n["children"], uuid)
            if r:
                return r
    return None


def floor(m):
    """Stand the feet on y = 0 (the claws are held up by the animations)."""
    lo = min(np.vstack(element_polys(e))[:, 1].min() for e in m["elements"] if e["name"].startswith("bottompincer"))
    for e in m["elements"]:
        for k in ("from", "to", "origin"):
            e[k][1] = round(e[k][1] - lo, 4)
    for g in m["groups"]:
        g["origin"][1] = round(g["origin"][1] - lo, 4)
    print("floor shift", -lo / 10, "studs")


# ---------------------------------------------------------------- animations
#
# Legs: +Z lifts a right leg (leg0, leg1), -Z a left one (leg2, leg3); +Y swings a
# right leg forward, -Y a left one. Pairs leg0+leg3 and leg1+leg2 step together.
# Claws: +X lifts an arm (the front rises); the pincer jaws open with +X.

RIGHT = {"leg0": 1, "leg1": 1, "leg2": -1, "leg3": -1}
PHASE = {"leg0": 0.0, "leg3": 0.0, "leg1": math.pi, "leg2": math.pi}
KNEE = {"leg0": "bottomleg0", "leg1": "bottomleg1", "leg2": "bottomleg2", "leg3": "bottomleg3"}


def legs(L, lift, swing, knee, speed=1, n=16):
    out = {}
    for leg, s in RIGHT.items():
        ph = PHASE[leg]
        out[leg] = [track(L, lambda u, s=s, ph=ph: (0, s * swing * math.cos(TAU * speed * u + ph),
                                                       s * lift * max(0.0, math.sin(TAU * speed * u + ph))), n)]
        out[KNEE[leg]] = [track(L, lambda u, s=s, ph=ph: (0, 0, -s * knee * max(0.0, math.sin(TAU * speed * u + ph))), n)]
    return out


def claws(L, arm, jaw, n=16):
    """arm(side, u) -> extra lift (degrees) on top of CLAW_LIFT; jaw(side, u) -> 0 shut .. 1 open."""
    out = {}
    for side, (a, hand, j) in enumerate((("pincer0", "claw", "top_pincer"), ("pincer1", "claws", "top_pincer2"))):
        out[a] = [track(L, lambda u, side=side, a=a: (CLAW_LIFT[a] + arm(side, u), 0, 0), n)]
        out[j] = [track(L, lambda u, side=side: (22 * jaw(side, u), 0, 0), n)]
    return out


def mandibles(L, chew, n=16):
    return {"mandible0": [track(L, lambda u: (0, -14 * chew(u), 0), n)],
            "mandible1": [track(L, lambda u: (0, 14 * chew(u), 0), n)]}


def animations():
    # position keys are in Blockbench units (0.1 stud)
    L = 3.0
    idle = {**legs(L, 4, 0, 0),
            **claws(L, lambda s, u: 6 * math.sin(TAU * u + s * 1.5),
                    lambda s, u: max(0.0, math.sin(TAU * u * 2 + s * 2.0)) ** 4),
            **mandibles(L, lambda u: max(0.0, math.sin(TAU * u * 3)) ** 2),
            "neck": [track(L, lambda u: (4 * math.sin(TAU * u * 2), 8 * math.sin(TAU * u), 0), 24)],
            "root": [track(L, lambda u: (0, 0, 1.5 * math.sin(TAU * u)), 16),
                     track(L, lambda u: (0, 0.6 * math.sin(TAU * u * 2), 0), 16, "position")]}
    # idle legs: a slow shuffle only, so zero the pair phase lift for a calm stand
    for leg in RIGHT:
        idle[leg] = [track(L, lambda u, s=RIGHT[leg], ph=PHASE[leg]: (0, 0, s * 3 * math.sin(TAU * u + ph)), 16)]

    Lw = 0.9
    walk = {**legs(Lw, 22, 18, 16),
            **claws(Lw, lambda s, u: 8 * math.sin(TAU * u + s * math.pi), lambda s, u: 0.3 + 0.3 * math.sin(TAU * u * 2)),
            **mandibles(Lw, lambda u: 0.5 + 0.5 * math.sin(TAU * u * 2)),
            "neck": [track(Lw, lambda u: (0, 0, -4 * math.sin(TAU * u)), 16)],
            "root": [track(Lw, lambda u: (0, 0, 4 * math.sin(TAU * u)), 16),
                     track(Lw, lambda u: (0, 2.0 * abs(math.sin(TAU * u)), 0), 16, "position")]}

    Lg = 0.5
    gallop = {**legs(Lg, 30, 26, 22),
              **claws(Lg, lambda s, u: 22 + 6 * math.sin(TAU * u * 2), lambda s, u: max(0.0, math.sin(TAU * u * 2 + s * math.pi))),
              **mandibles(Lg, lambda u: 0.5 + 0.5 * math.sin(TAU * u * 2)),
              "neck": [track(Lg, lambda u: (-6, 0, -5 * math.sin(TAU * u)), 12)],
              "root": [track(Lg, lambda u: (-3, 0, 6 * math.sin(TAU * u)), 12),
                       track(Lg, lambda u: (0, 4.0 * abs(math.sin(TAU * u)), 0), 12, "position")]}
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


def main(out="/mnt/project-files/animals/ocean"):
    m = build()
    groups = {g["name"]: g for g in m["groups"]}
    write_animations(m, groups, animations())
    for path in (MODEL, os.path.join(out, "KingCrab.bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    rest = S.posed(m, next(a for a in m["animations"] if a["name"] == "idle"), 0)
    lo = np.min([q.min(0) for p in rest for q in p.polys], 0)
    hi = np.max([q.max(0) for p in rest for q in p.polys], 0)
    print("bounds", np.round(lo, 2), np.round(hi, 2))
    W, H = 480, 400
    cams = [dict(eye=(0, 6, -12), target=(0, 1.2, -0.5)), dict(eye=(-9, 8, -9), target=(0, 1.2, -0.5))]
    sheet = Image.new("RGB", (W * 2, H))
    for i, cam in enumerate(cams):
        sheet.paste(render(rest, W=W, H=H, fov=40, **cam), (i * W, 0))
    sheet.save(os.path.join(out, "KingCrab.png"))
    if "--still" in sys.argv:
        return
    # Pets headshot: the whole crab from the front-left, cropped square
    for p in rest:
        if p.name.startswith(("Eye", "Pupil")):
            p.plain = True
    im = render(rest, eye=(-6.5, 6.5, -8.5), target=(0, 1.4, -1.0), W=700, H=700, fov=40, transparent=True)
    im = im.crop(im.getbbox())
    s = max(im.size) + 24
    pad = Image.new("RGBA", (s, s))
    pad.paste(im, ((s - im.width) // 2, (s - im.height) // 2))
    pad.resize((512, 512), Image.LANCZOS).save(os.path.join(ROOT, "assets", "ui", "PetKingCrab.png"))
    frames = []
    W, H = 400, 340
    for name, label, n, loops in (("idle", "idle", 30, 1), ("walk", "walk", 14, 2), ("gallop", "run", 10, 3)):
        anim = next(a for a in m["animations"] if a["name"] == name)
        for _ in range(loops):
            for k in range(n):
                parts = S.posed(m, anim, anim["length"] * k / n)
                im = Image.new("RGB", (W * 2, H))
                im.paste(render(parts, W=W, H=H, fov=40, **cams[1]), (0, 0))
                im.paste(render(parts, W=W, H=H, fov=40, eye=(-12, 3, 1), target=(0, 1.2, -0.5)), (W, 0))
                frames.append(A.label(im, [label] * 2))
    A.gif(os.path.join(out, "KingCrab_anims.gif"), frames, fps=20)
    print("wrote", out)


if __name__ == "__main__":
    main(*[a for a in sys.argv[1:] if not a.startswith("--")])
