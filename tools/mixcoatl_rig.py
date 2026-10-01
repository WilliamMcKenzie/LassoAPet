"""Animations for the Mixcoatl (QM's edit of the converted model, designs/converted/Mixcoatl.bbmodel):
a gorilla knuckle-walker (QM 03:16: "full gorilla knuckledragger").

  idle    knuckle stance, slow breathing, a subtle look round
  gallop  knuckle-walk: lateral sequence (left hand, right foot, right hand, left foot),
          the shoulders rolling over the planted arm
  walk    the same knuckle-walk at 0.7x speed
  jaw     its own bone, hinged at the back of the mouth (-X opens); Snake-style teeth
  (charge() is an unused bounding gallop: fists together, then feet)

Keyframes are offsets from QM's rest pose. Signs (from probing the rig): torso -X leans
forward, arm +X swings forward, leg -X swings back, head +X looks up. The root's height
comes from snow_rig.grounded(): each frame the lowest knuckle or foot touches the ground.

Run: python3 tools/mixcoatl_rig.py   (writes the model's animations and preview frames)
"""

import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from horse_rig import write_animations  # noqa: E402
from snake_rig import track  # noqa: E402
from snow_rig import bump, grounded, group_ids  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
MODEL = os.path.join(ROOT, "designs", "converted", "Mixcoatl.bbmodel")
TAU = 2 * math.pi

# the knuckle stance every animation starts from
LEAN, HEAD_UP, ARM, ARM_Y, BICEP, LEG, TAIL = -20, 16, 40, 30, -25, -22, -14  # ARM_Y * side


def s(x):
    return math.sin(x)


def contacts(model):
    """Part names under the hands and legs: what touches the ground."""
    G = {g["uuid"]: g["name"] for g in model["groups"]}
    E = {e["uuid"]: e["name"] for e in model["elements"]}
    out = set()

    def walk(o, inside):
        for c in o:
            if isinstance(c, dict):
                walk(c["children"], inside or G[c["uuid"]] in ("left_hand", "right_hand", "left_leg", "right_leg"))
            elif inside:
                out.add(E[c])

    walk(model["outliner"], False)
    return out


def stance(L, n, torso=lambda u: (0, 0, 0), head=lambda u: (0, 0, 0)):
    t = lambda u: (LEAN + torso(u)[0], torso(u)[1], torso(u)[2])  # noqa: E731
    h = lambda u: (HEAD_UP + head(u)[0], head(u)[1], head(u)[2])  # noqa: E731
    return {"torso": [track(L, t, n)], "head": [track(L, h, n)],
            "tail": [track(L, lambda u: (TAIL, 0, 0), 4)]}


def idle(m, feet):
    """Knuckle stance, slow breathing and a subtle look round (QM 03:23: no drumming)."""
    L, n = 4.0, 32
    tr = stance(L, n, torso=lambda u: (1.5 * s(TAU * u), 0, 0),
                head=lambda u: (2 * s(2 * TAU * u), 10 * s(TAU * u), 2 * s(TAU * u + 0.8)))
    for side, sx in (("left", -1), ("right", 1)):
        tr[side + "_arm"] = [track(L, lambda u, sx=sx: (ARM + 1.5 * s(TAU * u), sx * ARM_Y, 0), n)]
        tr[side + "_bicep"] = [track(L, lambda u: (BICEP, 0, 0), 4)]
        tr[side + "_leg"] = [track(L, lambda u: (LEG, 0, 0), 4)]
    tr["jaw"] = [track(L, lambda u: (-12 * bump(u, 0.6, 0.2), 0, 0), n)]  # a slow open and close
    tr["root"] = grounded(m, L, tr, feet, n)
    return L, tr


def walk(m, feet, L=1.3, n=32, stride_arm=24, stride_leg=20, sway=7):
    # lateral sequence: left hand 0, right foot 0.25, right hand 0.5, left foot 0.75
    phase = {"left_arm": 0.0, "right_leg": 0.25, "right_arm": 0.5, "left_leg": 0.75}
    tr = stance(L, n, torso=lambda u: (2 * s(2 * TAU * u), sway * s(TAU * u), -4 * s(TAU * u)),
                head=lambda u: (-2 * s(2 * TAU * u), -sway * 0.8 * s(TAU * u), 3 * s(TAU * u)))
    for bone, ph in phase.items():
        if bone.endswith("arm"):
            sx = -1 if bone.startswith("left") else 1
            tr[bone] = [track(L, lambda u, ph=ph, sx=sx: (ARM + stride_arm * s(TAU * (u - ph)), sx * ARM_Y, 0), n)]
            side = bone.split("_")[0]
            # the swinging arm bends a little to clear the ground
            tr[side + "_bicep"] = [track(L, lambda u, ph=ph: (BICEP - 14 * max(0.0, math.cos(TAU * (u - ph))), 0, 0), n)]
        else:
            tr[bone] = [track(L, lambda u, ph=ph: (LEG + stride_leg * s(TAU * (u - ph)), 0, 0), n)]
    tr["tail"] = [track(L, lambda u: (TAIL, 10 * s(TAU * u + 1.2), 0), n)]
    # mouth a little open, snapping wide and shut once a stride
    tr["jaw"] = [track(L, lambda u: (-5 - 14 * bump(u, 0.4, 0.15), 0, 0), n)]
    tr["root"] = grounded(m, L, tr, feet, n)
    return L, tr


def charge(m, feet, L=0.6, n=24):
    # fists together at 0, feet together at 0.5; the back pitches between them
    tr = stance(L, n, torso=lambda u: (9 * s(TAU * u + 0.6), 0, 0),
                head=lambda u: (-7 * s(TAU * u + 0.6), 0, 0))
    for side, sx in (("left", -1), ("right", 1)):
        tr[side + "_arm"] = [track(L, lambda u, sx=sx: (ARM + 4 + 34 * s(TAU * u + 1.4), sx * ARM_Y, 0), n)]
        tr[side + "_bicep"] = [track(L, lambda u: (BICEP - 18 * max(0.0, math.cos(TAU * u + 1.4)), 0, 0), n)]
        tr[side + "_leg"] = [track(L, lambda u: (LEG + 30 * s(TAU * u - 1.7), 0, 0), n)]
    tr["tail"] = [track(L, lambda u: (TAIL - 10 * s(TAU * u), 0, 0), n)]
    tr["root"] = grounded(m, L, tr, feet, n, extra=lambda u: 6 * max(0.0, s(TAU * u + 0.3)))
    return L, tr


# ---------------------------------------------------------------- model edits (QM 03:24)

TOOTH_UV = (5.0, 3.0)  # the palette cell of the tooth white (250, 248, 238)


def tooth(name, base_lo, base_hi, tip):
    """A Snake-style tooth: a square pyramid mesh, base rectangle in a horizontal plane
    (y = base_lo[1]) and its tip straight above or below."""
    import uuid
    (x0, y, z0), (x1, _, z1) = base_lo, base_hi
    v = {"a": [x0, y, z0], "b": [x1, y, z0], "c": [x1, y, z1], "d": [x0, y, z1], "t": list(tip)}
    up = tip[1] > y
    tris = [("a", "b"), ("b", "c"), ("c", "d"), ("d", "a")]
    faces = {}
    base = ["a", "b", "c", "d"] if up else ["d", "c", "b", "a"]
    faces["base"] = {"uv": {k: list(TOOTH_UV) for k in base}, "texture": 0, "vertices": base}
    for i, (p, q) in enumerate(tris):
        vs = [q, p, "t"] if up else [p, q, "t"]
        faces[f"s{i}"] = {"uv": {k: list(TOOTH_UV) for k in vs}, "texture": 0, "vertices": vs}
    return {"name": name, "color": 0, "origin": [0, 0, 0], "rotation": [0, 0, 0], "export": True,
            "visibility": True, "locked": False, "render_order": "default", "allow_mirror_modeling": True,
            "vertices": v, "faces": faces, "type": "mesh", "uuid": str(uuid.uuid4())}


def edit_model(m):
    """Snake-style teeth on the upper snout and the jaw, the jaw hinged at its back
    centre, and the right eye mirrored from the left (QM's copy was dark and off)."""
    import copy
    import uuid
    G = {g["name"]: g for g in m["groups"]}
    if any(e["name"].startswith("Upper_tooth") for e in m["elements"]):
        return
    nodes = {}

    def walk(o):
        for c in o:
            if isinstance(c, dict):
                nodes[G_by_uuid[c["uuid"]]["name"]] = c
                walk(c["children"])

    G_by_uuid = {g["uuid"]: g for g in m["groups"]}
    walk(m["outliner"])
    # jaw hinge: centre of the jaw's back top edge
    G["jaw"]["origin"] = [0, 98.39, -5.14]
    # teeth: upper ones hang from the snout (y 101.32), lower ones stand on the jaw (y 98.39),
    # staggered so they interleave when the mouth shuts
    w = 1.4
    up_z, lo_z = (-17.3, -13.4, -9.5), (-15.4, -11.5, -7.6)
    for sx, side in ((-1, "L"), (1, "R")):
        for i, z in enumerate(up_z):
            x = sx * 5.4
            t = tooth(f"Upper_tooth_{side}_{i}", (x - w, 101.32, z - w), (x + w, 101.32, z + w), (x, 97.1, z))
            m["elements"].append(t)
            nodes["head"]["children"].append(t["uuid"])
        for i, z in enumerate(lo_z):
            x = sx * 5.4
            t = tooth(f"Lower_tooth_{side}_{i}", (x - w, 98.39, z - w), (x + w, 98.39, z + w), (x, 102.6, z))
            m["elements"].append(t)
            nodes["jaw"]["children"].append(t["uuid"])
    # eyes: drop QM's right copy and mirror the left one into the mirrored bone
    eyes = [e for e in m["elements"] if e["name"] in ("EyeL", "PupilL")]
    right = [e for e in eyes if e["from"][0] > 0]
    left = [e for e in eyes if e["from"][0] < 0]
    gone = {e["uuid"] for e in right}
    m["elements"] = [e for e in m["elements"] if e["uuid"] not in gone]
    for n in nodes.values():
        n["children"] = [c for c in n["children"] if not (isinstance(c, str) and c in gone)]
    src_bone = next(b for b, n in nodes.items() if left[0]["uuid"] in n["children"])
    g = G[src_bone]
    mirror = next(b for b in G if b != src_bone and G[b]["origin"] == [-g["origin"][0], *g["origin"][1:]]
                  and [round(v, 3) for v in G[b]["rotation"]] == [round(g["rotation"][0], 3), -round(g["rotation"][1], 3), -round(g["rotation"][2], 3)])
    for e in left:
        r = copy.deepcopy(e)
        r["uuid"] = str(uuid.uuid4())
        r["name"] = e["name"][:-1] + "R"
        r["from"], r["to"] = [-e["to"][0], *e["from"][1:]], [-e["from"][0], *e["to"][1:]]
        if "origin" in r:
            r["origin"] = [-e["origin"][0], *e["origin"][1:]]
        if "rotation" in r:
            r["rotation"] = [e["rotation"][0], -e["rotation"][1], -e["rotation"][2]]
        if "east" in r["faces"] and "west" in r["faces"]:
            r["faces"]["east"], r["faces"]["west"] = r["faces"]["west"], r["faces"]["east"]
        m["elements"].append(r)
        nodes[mirror]["children"].append(r["uuid"])


def main(path=MODEL):
    m = json.load(open(path))
    m["meta"]["format_version"] = "4.10"  # keyframes in the 4.x sign convention
    m["animations"] = []
    edit_model(m)
    feet = contacts(m)
    anims = {"idle": idle(m, feet), "walk": walk(m, feet, L=round(1.3 / 0.7, 3)), "gallop": walk(m, feet)}  # QM 03:23: the knuckle-walk is the gallop, the walk is it at 0.7x
    write_animations(m, group_ids(m), anims)
    with open(path, "w") as f:
        json.dump(m, f, separators=(",", ":"))
    return m


if __name__ == "__main__":
    main(*sys.argv[1:])
