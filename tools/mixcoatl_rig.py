"""Animations for the Mixcoatl (QM's edit of the converted model, designs/converted/Mixcoatl.bbmodel):
a gorilla knuckle-walker (QM 03:16: "full gorilla knuckledragger").

  idle    knuckle stance, slow breathing, a subtle look round
  gallop  knuckle-walk: lateral sequence (left hand, right foot, right hand, left foot),
          the shoulders rolling over the planted arm
  walk    the same knuckle-walk at 0.7x speed
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
from snow_rig import grounded, group_ids  # noqa: E402

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


def main(path=MODEL):
    m = json.load(open(path))
    m["meta"]["format_version"] = "4.10"  # keyframes in the 4.x sign convention
    m["animations"] = []
    feet = contacts(m)
    anims = {"idle": idle(m, feet), "walk": walk(m, feet, L=round(1.3 / 0.7, 3)), "gallop": walk(m, feet)}  # QM 03:23: the knuckle-walk is the gallop, the walk is it at 0.7x
    write_animations(m, group_ids(m), anims)
    with open(path, "w") as f:
        json.dump(m, f, separators=(",", ":"))
    return m


if __name__ == "__main__":
    main(*sys.argv[1:])
