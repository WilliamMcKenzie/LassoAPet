"""Snow animal animations: Penguin, Snowman, PolarBear and IceWyvern.

Run: python3 tools/snow_rig.py [name ...]        all four, or just the ones named

Writes idle, walk and gallop (the run at full speed) into each designs/snow/<Name>.bbmodel,
plus fly for the IceWyvern, and renders preview GIFs to /mnt/project-files/animals/snow/anims/.
The geometry, the group origins and the group rest rotations stay exactly as they are
(PolarBear and IceWyvern are QM's files): only the "animations" list is (re)written.

Keyframes play on top of the bones' rest rotations. The game (Rig.luau) applies them as
rest * keyframe, position included, so the previews here pose the bones the same way
(posed() below; snake_design.posed adds the angles to the rest instead, which only
differs for bones whose rest turns about more than one axis, like the wyvern's wings).

  Penguin    idle    rocks gently, looks about, a flipper flutter
             walk    waddle: rocks onto one foot then the other, flippers out, tail wags
             gallop  fast waddle: leaning forward, flippers flapping, a hop each step
  Snowman    idle    sways, looks round, arms drift; the blocks settle a little
             walk    two hops a loop, twisting left then right; the blocks squash on landing
             gallop  big hops leaning forward, arms thrown back, a deep squash each landing
  PolarBear  idle    breathes (chest and hump), looks about and sniffs, tail flicks
             walk    four-beat, like the horse's: front legs only reach forward, hind legs
                     only kick back; heavy shoulders roll, head swings low
             gallop  the leap (animal_designs.leap, bear sized): front legs reach forward,
                     hind legs kick back in the air
  IceWyvern  idle    wings folded, breathing, neck sways, jaw works, tail sways
             walk    raptor walk on two legs (feet planted by IK), wings folded, head bobs
             gallop  the run: body level, long strides with a flight phase, wings half open
             fly     big wingbeats (the hand lags the arm and folds on the upstroke), legs
                     tucked up, tail streaming; the body rides 2 studs up

Bones are blocks that only turn a little at the joints; blocks that rest on another
(the snowman's stack) sink by however much a tilt would lift their edge, so no gap opens.
Angles are degrees, positions Blockbench units (10 = 1 stud).
"""

import json
import math
import os
import shutil
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from horse_rig import element_polys, rotm, sample, num, swing, write_animations  # noqa: E402
from partlib import Part, render  # noqa: E402
import animal_designs as A  # noqa: E402
from snake_design import textures, element_color  # noqa: E402
from snake_rig import track  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
MODELS = os.path.join(ROOT, "designs", "snow")
OUT = "/mnt/project-files/animals/snow/anims"
TAU = 2 * math.pi
BB = 10
PLAIN = ("Eye", "Pupil", "Nostril", "Coal", "Plain")


def s(x):
    return math.sin(x)


def keys(L, pts, interp="catmullrom", channel="rotation", axis=0):
    """A track from (fraction of the loop, value) on one axis."""
    out = []
    for u, v in pts:
        xyz = [0.0, 0.0, 0.0]
        xyz[axis] = v
        out.append((round(u * L, 4), tuple(xyz)))
    return {"channel": channel, "interp": interp, "keys": out}


def bump(u, at, width):
    """0..1..0 over [at - width, at + width] (cosine), wrapping round the loop."""
    d = min(abs(u - at), abs(u - at + 1), abs(u - at - 1))
    return 0.5 * (1 + math.cos(math.pi * d / width)) if d < width else 0.0


# ---------------------------------------------------------------- posing (as the game does)

def group_ids(model):
    """Bone name -> group, the first group of that name (the wyvern has two "Head"s)."""
    out = {}
    for g in model["groups"]:
        out.setdefault(g["name"], g)
    return out


def anim_tracks(anim, t):
    """{group uuid: {channel: (x, y, z)}} at time t."""
    out = {}
    for uid, a in anim["animators"].items():
        by = {}
        for k in a.get("keyframes", []):
            by.setdefault(k["channel"], []).append(k)
        out[uid] = {ch: sample({"interp": ks[0]["interpolation"], "keys": sorted(
            [(k["time"], tuple(num(k["data_points"][0][c]) for c in "xyz")) for k in ks])}, t) for ch, ks in by.items()}
    return out


def posed(model, anim=None, t=0.0):
    """Parts in studs for one frame, posed like Rig.luau: each bone sits at its pivot,
    turned by its rest rotation, then moved and turned by the keyframes (rest * key)."""
    texs = textures(model)
    emap = {e["uuid"]: e for e in model["elements"]}
    gmap = {g["uuid"]: g for g in model["groups"]}
    tracks = anim_tracks(anim, t) if anim else {}
    parts = []

    def walk(node, M):
        if isinstance(node, str):
            e = emap[node]
            if e.get("visibility") is False:
                return
            polys = [(M[:3, :3] @ p.T).T + M[:3, 3] for p in element_polys(e)]
            p = Part(e["name"], (1, 1, 1), np.eye(4), element_color(e, texs), "Poly", plain=e["name"].startswith(PLAIN))
            p.polys = [q / BB for q in polys]
            parts.append(p)
            return
        g = gmap[node["uuid"]]
        o = np.array(g["origin"], float)
        tr = tracks.get(g["uuid"], {})
        Rr = rotm(g.get("rotation") or (0, 0, 0))
        Ra = rotm(tr.get("rotation", (0, 0, 0)))
        L = np.eye(4)
        L[:3, :3] = Rr @ Ra
        L[:3, 3] = o + Rr @ np.array(tr.get("position", (0, 0, 0)), float) - Rr @ Ra @ o
        for c in node["children"]:
            walk(c, M @ L)

    for node in model["outliner"]:
        walk(node, np.eye(4))
    return parts


def lowest(parts, names=None):
    """Lowest point (studs) of the parts, or of the named ones."""
    return min(q[:, 1].min() for p in parts if names is None or p.name in names for q in p.polys)


def as_anim(model, L, tracks):
    """One animation dict (as write_animations writes it) for posing before saving."""
    tmp = {"animations": []}
    write_animations(tmp, group_ids(model), {"_": (L, tracks)})
    return tmp["animations"][0]


def grounded(model, L, tracks, feet, n, extra=lambda u: 0.0, x=lambda u: 0.0, z=lambda u: 0.0):
    """A root position track that keeps the lowest of `feet` on the ground (y = 0),
    plus extra(u) Blockbench units of hop. The root's own rotation is in `tracks`."""
    base = dict(tracks)
    base.pop("root", None)
    rot = [c for c in tracks.get("root", []) if c["channel"] == "rotation"]
    anim = as_anim(model, L, {**base, **({"root": rot} if rot else {})})
    pts = []
    for i in range(n + 1):
        u = i / n
        low = lowest(posed(model, anim, u * L), feet)
        pts.append((round(u * L, 4), (x(u), round(-low * BB + extra(u), 3), z(u))))
    pts[-1] = (pts[-1][0], pts[0][1])
    return rot + [{"channel": "position", "interp": "catmullrom", "keys": pts}]


def clear_ground(model, L, tracks, n, floor=None):
    """Resample the root's position track at n + 1 keys, lifted wherever a part would dip
    below `floor` (studs; default: the rest pose's lowest point, as QM's claws sit at -0.03)."""
    if floor is None:
        floor = lowest(posed(model))
    anim = as_anim(model, L, tracks)
    rot = [c for c in tracks["root"] if c["channel"] == "rotation"]
    pos = next(c for c in tracks["root"] if c["channel"] == "position")
    pts = []
    for i in range(n + 1):
        t = L * i / n
        x, y, z = sample(pos, t)
        dip = floor - lowest(posed(model, anim, t))
        pts.append((round(t, 4), (round(float(x), 3), round(float(y) + max(0.0, dip) * BB, 3), round(float(z), 3))))
    pts[-1] = (pts[-1][0], pts[0][1])
    return rot + [{"channel": "position", "interp": "catmullrom", "keys": pts}]


# ---------------------------------------------------------------- Penguin

def penguin(m):
    feet = {"FootL", "FootR"}
    out = {}

    def waddle(L, roll, yaw, lean, stride, lift, hop, flip_out, flip_flap, flap_rate, flip_back, n=16):
        """roll > 0 at u = 0.25 puts the weight on the left foot (-X) while the right one steps."""
        r = lambda u: roll * s(TAU * u)  # noqa: E731
        tr = {"root": [track(L, lambda u: (lean, yaw * s(TAU * u), r(u)), n)]}
        for side, ph in (("L", 0.5), ("R", 0.0)):
            # the stepping foot (u in [ph, ph + 0.5]) swings forward, the planted one slides back
            def fz(u, ph=ph):  # back to front while stepping (v < 0.5), front to back while planted
                return stride * math.cos(TAU * ((u - ph) % 1))

            def fy(u, ph=ph):
                v = (u - ph) % 1
                return lift * s(TAU * v) if v < 0.5 else 0.0

            tr["Leg" + side] = [track(L, lambda u: (-lean, -yaw * s(TAU * u) * 0.5, -r(u)), n),
                                track(L, lambda u, fz=fz, fy=fy: (0, fy(u), fz(u)), n, "position")]
            sx = -1 if side == "L" else 1
            tr["Wing" + side] = [track(L, lambda u, sx=sx: (-flip_back, 0, sx * (flip_out + flip_flap * s(TAU * flap_rate * u))), n)]
        tr["neck"] = [track(L, lambda u: (-lean * 0.4 + 3 * s(2 * TAU * u), -yaw * 0.6 * s(TAU * u), -0.5 * r(u)), n)]
        tr["Tail"] = [track(L, lambda u: (0, 18 * s(TAU * u + 0.8), 0), n)]
        tr["root"] = grounded(m, L, tr, feet, n, extra=lambda u: hop * abs(s(TAU * u)))
        return L, tr

    # idle: a gentle rock, looking about, a flipper flutter now and then
    L = 2.6
    idle = {"root": [track(L, lambda u: (0, 0, 2.5 * s(TAU * u)), 12)],
            "LegL": [track(L, lambda u: (0, 0, -2.5 * s(TAU * u)), 12)],
            "LegR": [track(L, lambda u: (0, 0, -2.5 * s(TAU * u)), 12)],
            "neck": [track(L, lambda u: (2 * s(2 * TAU * u), 22 * s(TAU * u + 0.5), 7 * s(2 * TAU * u + 1)), 16)],
            "WingL": [track(L, lambda u: (0, 0, -(4 + 26 * bump(u, 0.62, 0.05) + 26 * bump(u, 0.72, 0.05))), 52)],
            "WingR": [track(L, lambda u: (0, 0, 4 + 26 * bump(u, 0.64, 0.05) + 26 * bump(u, 0.74, 0.05)), 52)],
            "Tail": [track(L, lambda u: (0, 12 * s(2 * TAU * u), 0), 12)]}
    idle["root"] = grounded(m, L, idle, feet, 12)
    out["idle"] = (L, idle)
    out["walk"] = waddle(0.8, roll=10, yaw=7, lean=0, stride=4, lift=2.0, hop=0, flip_out=22, flip_flap=8, flap_rate=2, flip_back=0)
    out["gallop"] = waddle(0.45, roll=12, yaw=8, lean=-16, stride=7, lift=2.5, hop=4, flip_out=45, flip_flap=30, flap_rate=2,
                           flip_back=20)
    return out


# ---------------------------------------------------------------- Snowman

MID_HALF = (1.9, 1.75)  # the middle block's half width and depth (studs): its edge lifts by these when it tilts
HEAD_HALF = (1.5, 1.4)


def sink(half, rx, rz):
    """How far (Blockbench units) a block standing on another must sink so a tilt of
    rx, rz degrees about its bottom-centre pivot never lifts an edge off."""
    return BB * (half[1] * abs(math.sin(math.radians(rx))) + half[0] * abs(math.sin(math.radians(rz))))


def snowman(m):
    out = {}

    # idle: sways, looks round, the arms drift; a slow settle (breath)
    L = 3.0
    mid = lambda u: (0, 4 * s(TAU * u), 2 * s(TAU * u))  # noqa: E731
    head = lambda u: (2 * s(2 * TAU * u), 20 * s(TAU * u + 1.2), -3 * s(TAU * u + 0.4))  # noqa: E731
    out["idle"] = (L, {
        "Mid": [track(L, mid, 16), track(L, lambda u: (0, -sink(MID_HALF, mid(u)[0], mid(u)[2]) - 1.2 * (1 - math.cos(2 * TAU * u)) / 2, 0), 16, "position")],
        "neck": [track(L, head, 16), track(L, lambda u: (0, -sink(HEAD_HALF, head(u)[0], head(u)[2]) - 0.8 * (1 - math.cos(2 * TAU * u)) / 2, 0), 16, "position")],
        "ArmL": [track(L, lambda u: (0, 8 * s(TAU * u + 0.7), 8 * s(TAU * u)), 12)],
        "ArmR": [track(L, lambda u: (0, -8 * s(TAU * u + 2.2), -8 * s(TAU * u + 1.4)), 12)],
    })

    def hops(L, n_hops, height, lean, twist, squash, arm_up, arm_back, nod, contact=0.22):
        """n_hops a loop. Each hop: lands at v = 0, squashes, takes off at v = contact,
        flies a parabola. The stack only leans and twists in the air (flat base on the ground)."""
        def v_of(u):
            return (u * n_hops) % 1

        def hop_i(u):
            return int(u * n_hops) % n_hops

        def air(u):  # 0 on the ground, 0..1..0 over the flight
            v = v_of(u)
            return 0.0 if v < contact else s(math.pi * (v - contact) / (1 - contact))

        def flight(u):  # 0 at takeoff .. 1 at landing
            v = v_of(u)
            return 0.0 if v < contact else (v - contact) / (1 - contact)

        def sq(u):  # squash: 0..1..0 on the ground
            v = v_of(u)
            return s(math.pi * v / contact) if v < contact else 0.0

        def tw(u):
            sign = 1 if hop_i(u) % 2 == 0 else -1
            return sign * twist * s(math.pi * flight(u))

        n = 24 * n_hops
        rx = lambda u: lean * air(u)  # noqa: E731
        head = lambda u: (-nod * sq(u) + 4 * air(u), -0.5 * tw(u), 0)  # noqa: E731
        mid = lambda u: (-2 * sq(u), 0, 0)  # noqa: E731
        tr = {
            "root": [track(L, lambda u: (rx(u), tw(u), 0), n),
                     track(L, lambda u: (0, height * air(u) ** 0.85, 0), n, "position")],
            "Mid": [track(L, mid, n),
                    track(L, lambda u: (0, -squash * sq(u) - sink(MID_HALF, mid(u)[0], 0), 0), n, "position")],
            "neck": [track(L, head, n),
                     track(L, lambda u: (0, -0.7 * squash * sq(u) - sink(HEAD_HALF, head(u)[0], 0), 0), n, "position")],
        }
        for side, sx in (("L", -1), ("R", 1)):
            # up (left -Z) and back (left +Y) in the air, flung down a little on landing
            tr["Arm" + side] = [track(L, lambda u, sx=sx: (0, -sx * arm_back * air(u), sx * (arm_up * air(u) - 18 * sq(u))), n)]
        return L, tr

    out["walk"] = hops(1.0, 2, height=10, lean=-5, twist=10, squash=4, arm_up=30, arm_back=10, nod=4)
    out["gallop"] = hops(0.55, 1, height=24, lean=-12, twist=0, squash=6, arm_up=40, arm_back=40, nod=6, contact=0.2)
    return out


# ---------------------------------------------------------------- PolarBear

def polar_bear(m):
    out = {}
    L = 3.0
    out["idle"] = (L, {
        "Chest": [track(L, lambda u: (1.5 * s(2 * TAU * u), 0, 0), 12)],
        "Hump": [track(L, lambda u: (-1 * s(2 * TAU * u), 0, 0), 12)],
        "neck": [track(L, lambda u: (3 * s(2 * TAU * u + 1) + 2.5 * bump(u, 0.3, 0.04) + 2.5 * bump(u, 0.38, 0.04),
                                     14 * s(TAU * u), 4 * s(TAU * u + 0.3)), 40)],
        "Tail": [track(L, lambda u: (-6 * bump(u, 0.7, 0.06), 0, 14 * bump(u, 0.7, 0.08) * s(TAU * 6 * u)), 36)],
    })

    # walk: four-beat (as QM's horse walk), legs one way only from rest
    L = 1.3
    phase = {"LegHL": 0, "LegFL": 0.25, "LegHR": 0.5, "LegFR": 0.75}
    walk = {leg: [{"channel": "rotation", "interp": "linear",
                   "keys": [(t, ((1 if leg[3] == "F" else -1) * v, 0, 0)) for t, v in swing(phase[leg] * L, 0.42 * L, 24, L)]}]
            for leg in phase}
    walk["root"] = [track(L, lambda u: (0, 0, 2 * s(TAU * u + 1.4)), 16),
                    track(L, lambda u: (0, 1.5 * (0.5 - 0.5 * math.cos(2 * TAU * (u - 0.06))), 0), 16, "position")]
    walk["Chest"] = [track(L, lambda u: (1.5 * s(2 * TAU * u), 2.5 * s(TAU * u + 1.2), 3 * s(TAU * u + 1.4)), 16)]
    walk["neck"] = [track(L, lambda u: (-4 - 4 * s(2 * TAU * u + 0.6), -7 * s(TAU * u + 1.2), -3 * s(TAU * u + 1.4)), 16)]
    walk["Tail"] = [track(L, lambda u: (-4, 10 * s(TAU * u), 0), 12)]
    walk["root"] = clear_ground(m, L, walk, 32)
    out["walk"] = (L, walk)

    # gallop: the leap, bear sized (13 studs tall: higher, legs a touch less spread)
    L, leap = A.leap(L=0.9, height=32, spread=42, pitch=7)
    leap.pop("EarL")
    leap.pop("EarR")
    leap["neck"] = [A.rot_x(A.at(L, [(0, -8), (0.2, 2), (0.5, 4), (0.8, -4), (1, -8)]), "catmullrom")]
    leap["Chest"] = [A.rot_x(A.at(L, [(0, -3), (0.2, 3), (0.5, 5), (0.8, -2), (1, -3)]), "catmullrom")]
    leap["Hump"] = [A.rot_x(A.at(L, [(0, 2), (0.5, -2), (1, 2)]), "catmullrom")]
    leap["Tail"] = [A.rot_x(A.at(L, [(0, -10), (0.3, -40), (0.6, -45), (0.9, -15), (1, -10)]), "catmullrom")]
    leap["root"] = clear_ground(m, L, leap, 36)
    out["gallop"] = (L, leap)
    return out


# ---------------------------------------------------------------- IceWyvern

# Leg chain in the root's own (unrotated) frame, (y, z) in Blockbench units: hip, knee, ankle
# pivots straight below each other; rest rotations thigh 34, shin -70, foot 36; root 10.
HIP = np.array([73.43, 18.0])
THIGH, SHIN = 36.0, 41.4
REST_T, REST_S, REST_F, REST_ROOT = 34.0, -70.0, 36.0, 10.0
ROOT_O = np.array([78.83, 0.0])


def rx2(a, v):
    """Turn (y, z) by a degrees about X (+ turns +Y toward +Z)."""
    c, sn = math.cos(math.radians(a)), math.sin(math.radians(a))
    return np.array([v[0] * c - v[1] * sn, v[0] * sn + v[1] * c])


def ankle_local(c1, c2):
    """Ankle (y, z) in the root's frame for cumulative thigh/shin angles."""
    return HIP + rx2(c1, (-THIGH, 0)) + rx2(c2, (-SHIN, 0))


def to_world(p, root_rx, root_pos):
    """Root frame -> world (game order: rest, then the key's position, then its turn)."""
    return ROOT_O + rx2(REST_ROOT, np.asarray(root_pos) + rx2(root_rx, np.asarray(p) - ROOT_O))


def to_local(w, root_rx, root_pos):
    return ROOT_O + rx2(-root_rx, rx2(-REST_ROOT, np.asarray(w) - ROOT_O) - np.asarray(root_pos))


ANKLE_REST_W = to_world(ankle_local(REST_T, REST_T + REST_S), 0, (0, 0))


def leg_ik(target_w, foot_w, root_rx, root_pos):
    """Thigh, shin, foot keyframe angles (on top of rest) putting the ankle at
    target_w (world y, z) with the foot at foot_w degrees in the world (rest = 10)."""
    t = to_local(target_w, root_rx, root_pos)
    d = t - HIP
    D = float(np.clip(np.linalg.norm(d), abs(THIGH - SHIN) + 1, (THIGH + SHIN) * 0.995))
    dn = d / np.linalg.norm(d)
    t = HIP + dn * D
    alpha = math.degrees(math.acos((THIGH ** 2 + D ** 2 - SHIN ** 2) / (2 * THIGH * D)))
    best = None
    for sgn in (1, -1):
        u1 = rx2(sgn * alpha, dn)  # thigh direction
        knee = HIP + u1 * THIGH
        if best is None or knee[1] < best[1][1]:  # the knee forward (-Z), as at rest
            best = (u1, knee)
    u1, knee = best
    u2 = (t - knee) / SHIN
    c1 = math.degrees(math.atan2(-u1[1], -u1[0]))
    c2 = math.degrees(math.atan2(-u2[1], -u2[0]))
    c3 = foot_w - REST_ROOT - root_rx
    return c1 - REST_T, (c2 - c1) - REST_S, (c3 - c2) - REST_F


def wyvern_legs(L, n, root_rx, root_y, stride, lift, stance, toe=20, raise_=None):
    """Both legs by IK. Each foot is planted for `stance` of the loop, sliding back
    from -stride to +stride (Blockbench units, about its rest spot), then swings forward
    `lift` high. root_rx(u), root_y(u): the root's keyframes, to keep the feet planted.
    The foot stays flat while planted and the toes droop (toe degrees) while it swings.
    raise_: {side: [extra lift per key]} (see feet_on_ground)."""
    tracks = {}
    for side, ph in (("L", 0.0), ("R", 0.5)):
        rows = []
        for i in range(n + 1):
            u = i / n
            v = (u - ph) % 1
            if stance >= 1:
                dz, dy, fw = 0.0, 0.0, 0.0
            elif v < stance:
                k = v / stance
                dz, dy, fw = -stride + 2 * stride * k, 0.0, 0.0
                fw = -toe * 0.8 * max(0.0, (k - 0.75) / 0.25)  # heel peels off at the end
            else:
                k = (v - stance) / (1 - stance)
                dz = stride - 2 * stride * (0.5 - 0.5 * math.cos(math.pi * k))
                dy = lift * s(math.pi * k)
                fw = -toe * s(math.pi * min(1.0, k * 1.15)) - toe * 0.8 * max(0.0, 1 - k * 4)
            target = ANKLE_REST_W + np.array([dy + (raise_[side][i] if raise_ else 0.0), dz])
            rows.append((round(u * L, 4), leg_ik(target, REST_ROOT + fw, root_rx(u), (root_y(u), 0))))
        rows[-1] = (rows[-1][0], rows[0][1])
        for bone, j in (("LegH" + side, 0), ("Shin" + side, 1), ("Foot" + side, 2)):
            tracks[bone] = [{"channel": "rotation", "interp": "catmullrom",
                             "keys": [(t, (round(a[j], 3), 0, 0)) for t, a in rows]}]
    return tracks


FOOT_PARTS = {side: {"Foot" + side, "Ankle" + side} | {f"Claw{side}{k}" for k in range(3)} for side in "LR"}


def feet_on_ground(m, L, tracks, n, legs, stance, rounds=4):
    """legs(raise_) -> leg tracks (wyvern_legs). Lifts each ankle wherever its foot or claws
    would dip below the ground (a toe pointing down as the heel peels off, a tilted root),
    and sets each planted foot (the first `stance` of its step) down onto it."""
    raise_ = {side: [0.0] * (n + 1) for side in "LR"}
    for _ in range(rounds):
        anim = as_anim(m, L, {**tracks, **legs(raise_)})
        moved = False
        for i in range(n + 1):
            parts = posed(m, anim, L * i / n)
            for side, ph in (("L", 0.0), ("R", 0.5)):
                dip = -lowest(parts, FOOT_PARTS[side])
                if (i / n - ph) % 1 < stance and dip < -0.005 or dip > 0.005:
                    raise_[side][i] += dip * BB
                    moved = True
        if not moved:
            break
    return legs(raise_)


def wings(L, n, arm, hand, spar=lambda u: 0.0):
    """arm(u) -> (Y back, Z down) and hand(u) -> (Y fold, Z) for the left wing; the right mirrors."""
    out = {}
    for side, sx in (("L", 1), ("R", -1)):
        out["Wing" + side] = [track(L, lambda u, sx=sx: (0, sx * arm(u)[0], sx * arm(u)[1]), n)]
        out["WingHand" + side] = [track(L, lambda u, sx=sx: (0, sx * hand(u)[0], sx * hand(u)[1]), n)]
        out["WingSpar" + side] = [track(L, lambda u, sx=sx: (0, sx * spar(u), 0), n)]
    return out


# Wing poses for the left wing (Y, Z); the right mirrors. +Y sweeps the arm back, +Z lowers it.
# The hand folds up and over the arm about Z (a flat fold about Y would swing the outer
# membrane out in front of the hand), short of 180 so the two membranes never lie flat
# on each other, and turned back (-Y) so the hands don't cross over the back.
FOLD_ARM = (10, 35)  # folded along the sides (idle, walk)
FOLD_HAND = (-35, -160)
HALF_ARM = (20, -5)  # half open, raised like sails (run); same fold, so walk <-> run blends cleanly
HALF_HAND = (-25, -72)


def wyvern(m):
    out = {}

    def neck(L, n, base, bob=0.0, sway=0.0, head_level=1.0, rate=2):
        """base: (neck, Neck2, Head) X. The head turns back by head_level of the bob."""
        nb, n2, hd = base
        return {"neck": [track(L, lambda u: (nb + bob * s(rate * TAU * u), sway * s(TAU * u), 0), n)],
                "Neck2": [track(L, lambda u: (n2 - 0.5 * bob * s(rate * TAU * u - 0.6), 0, 0), n)],
                "Head": [track(L, lambda u: (hd - head_level * 0.5 * bob * s(rate * TAU * u - 1.0), -sway * 0.6 * s(TAU * u), 0), n)]}

    def tail(L, n, base, sway, lift=0.0, rate=1, lag=0.9):
        out = {}
        for j, b in enumerate(("Tail", "Tail2", "Tail3")):
            out[b] = [track(L, lambda u, j=j: (base[j] + lift * s(rate * TAU * u - lag * (j + 1)),
                                                sway * (1 + 0.3 * j) * s(TAU * u - lag * (j + 1)), 0), n)]
        return out

    def jaw(L, n, fn):
        return {"Jaw": [track(L, lambda u: (fn(u), 0, 0), n)]}

    # idle: wings folded, breathing, neck sways, jaw works (rest is wide open: + closes it)
    L = 3.2
    n = 24
    breath = lambda u: 0.5 - 0.5 * math.cos(2 * TAU * u)  # noqa: E731
    idle = {**neck(L, n, (0, 0, 0), bob=0, sway=8),
            **tail(L, n, (0, 0, 0), sway=6),
            **jaw(L, n, lambda u: 14 - 18 * bump(u, 0.62, 0.1)),
            **wings(L, n, lambda u: (FOLD_ARM[0], FOLD_ARM[1] - 3 * breath(u)), lambda u: FOLD_HAND)}
    idle["neck"] = [track(L, lambda u: (3 * breath(u) - 2, 8 * s(TAU * u), 0), n)]
    root_y = lambda u: -2 + 2 * breath(u)  # noqa: E731
    root_rx = lambda u: 0.8 * breath(u)  # noqa: E731
    idle["root"] = [track(L, lambda u: (root_rx(u), 0, 0), n), track(L, lambda u: (0, root_y(u), 0), n, "position")]
    idle.update(wyvern_legs(L, n, root_rx, root_y, 0, 0, 1.0))
    out["idle"] = (L, idle)

    # walk: raptor walk, two steps a loop; the body rides highest over the planted foot
    L = 1.1
    n = 32
    root_y = lambda u: -3 + 3 * math.cos(2 * TAU * u)  # noqa: E731
    root_rx = lambda u: -3 + 1.5 * math.cos(2 * TAU * u)  # noqa: E731
    walk = {**neck(L, n, (-6, 2, 4), bob=5, sway=4),
            **tail(L, n, (2, -4, 4), sway=7),
            **jaw(L, n, lambda u: 12),
            **wings(L, n, lambda u: (FOLD_ARM[0], FOLD_ARM[1] - 4 * s(2 * TAU * u)), lambda u: FOLD_HAND)}
    walk["root"] = [track(L, lambda u: (root_rx(u), 3 * s(TAU * u), -3 * s(TAU * u)), n),
                    track(L, lambda u: (0, root_y(u), 0), n, "position")]
    walk.update(feet_on_ground(m, L, walk, n, lambda r: wyvern_legs(L, n, root_rx, root_y, 22, 14, 0.6, raise_=r), 0.6))
    out["walk"] = (L, walk)

    # run: body level and low, long strides with a flight phase, wings half open
    L = 0.62
    n = 32
    stance = 0.38

    def run_y(u):
        w = (2 * u) % 1
        st = stance / 0.5  # a foot's stance as a fraction of its step (a step is half the loop)
        return -6 * s(math.pi * w / st) if w < st else 5 * s(math.pi * (w - st) / (1 - st))

    root_rx = lambda u: -11 + 2 * s(2 * TAU * u)  # noqa: E731
    run = {**neck(L, n, (-16, 6, 12), bob=4, sway=3),
           **tail(L, n, (8, -16, 20), sway=6, lift=3, rate=2),
           **jaw(L, n, lambda u: 4 + 4 * s(2 * TAU * u)),
           **wings(L, n, lambda u: (HALF_ARM[0], HALF_ARM[1] + 5 * s(2 * TAU * u - 1)),
                   lambda u: (HALF_HAND[0], HALF_HAND[1] + 6 * s(2 * TAU * u - 1.6)))}
    run["root"] = [track(L, lambda u: (root_rx(u), 4 * s(TAU * u), -3 * s(TAU * u)), n),
                   track(L, lambda u: (0, run_y(u), 0), n, "position")]
    run.update(feet_on_ground(m, L, run, n, lambda r: wyvern_legs(L, n, root_rx, run_y, 32, 20, stance, toe=30, raise_=r), stance))
    out["gallop"] = (L, run)

    # fly: big wingbeats (down 0..0.45, up 0.45..1), the hand lagging the arm; legs tucked,
    # tail streaming out straight; the body bobs up on each downstroke
    L = 1.0
    n = 40

    def beat(u):  # 1 at the top of the upstroke (u = 0), -1 at the bottom (u = 0.45)
        return math.cos(math.pi * u / 0.45) if u < 0.45 else -math.cos(math.pi * (u - 0.45) / 0.55)

    arm_z = lambda u: -8 - 46 * beat(u)  # noqa: E731
    fly = {**neck(L, n, (-26, 14, 14), bob=-4, sway=0, rate=1),
           **tail(L, n, (12, -20, 26), sway=4, lift=6, rate=1, lag=0.7),
           **jaw(L, n, lambda u: 10),
           **wings(L, n, lambda u: (6 - 6 * beat(u), arm_z(u)),
                   lambda u: (30 * s(math.pi * (u - 0.45) / 0.55) if u > 0.45 else 0.0,
                              0.6 * (arm_z((u - 0.1) % 1) - arm_z(u))),
                   lambda u: -18 * (max(0.0, s(math.pi * (u - 0.45) / 0.55)) if u > 0.45 else 0.0))}
    fly["root"] = [track(L, lambda u: (-10 + 2 * beat(u), 0, 0), n),
                   track(L, lambda u: (0, 20 - 5 * beat((u - 0.1) % 1), 0), n, "position")]
    fly["LegHL"] = [track(L, lambda u: (55 + 4 * beat(u), 0, 0), n)]
    fly["LegHR"] = [track(L, lambda u: (55 + 4 * beat((u + 0.05) % 1), 0, 0), n)]
    fly["ShinL"] = [track(L, lambda u: (-62, 0, 0), 2)]
    fly["ShinR"] = [track(L, lambda u: (-62, 0, 0), 2)]
    fly["FootL"] = [track(L, lambda u: (-30, 0, 0), 2)]
    fly["FootR"] = [track(L, lambda u: (-30, 0, 0), 2)]
    out["fly"] = (L, fly)
    return out


# ---------------------------------------------------------------- files and previews

ANIMALS = {
    # name: (animations, preview cameras, render size)
    "Penguin": (penguin, [dict(eye=(-14, 11, -15), target=(0, 4.2, 0)), dict(eye=(0, 5, -22), target=(0, 4.2, 0)),
                          dict(eye=(-22, 5, 0), target=(0, 4.2, 0))]),
    "Snowman": (snowman, [dict(eye=(-16, 12, -17), target=(0, 5.5, 0)), dict(eye=(0, 6, -25), target=(0, 6, 0)),
                          dict(eye=(-25, 6, 0), target=(0, 6, 0))]),
    "PolarBear": (polar_bear, [dict(eye=(-26, 16, -28), target=(0, 6, 0)), dict(eye=(-40, 7, 0), target=(0, 6.5, 0)),
                               dict(eye=(22, 14, 30), target=(0, 6, 1))]),
    "IceWyvern": (wyvern, [dict(eye=(-46, 30, -50), target=(0, 8, 0)), dict(eye=(-70, 10, 0), target=(0, 8, 0)),
                           dict(eye=(0, 14, -62), target=(0, 9, 2))]),
}


def build(name):
    path = os.path.join(MODELS, name + ".bbmodel")
    m = json.load(open(path))
    fn, _ = ANIMALS[name]
    write_animations(m, group_ids(m), fn(m))
    with open(path, "w") as f:
        json.dump(m, f, separators=(",", ":"))
    return m


def preview(name, m, out=OUT):
    os.makedirs(out, exist_ok=True)
    _, cams = ANIMALS[name]
    W, H = 340, 340
    for anim in m["animations"]:
        fps = 20
        n = max(8, round(anim["length"] * fps))
        loops = max(1, round(2.4 / anim["length"]))
        frames = []
        for i in range(n):
            parts = posed(m, anim, anim["length"] * i / n)
            im = Image.new("RGB", (W * len(cams), H))
            for c, cam in enumerate(cams):
                im.paste(render(parts, W=W, H=H, fov=40, **cam), (c * W, 0))
            frames.append(A.label(im, [f"{name} {anim['name']}"] * len(cams)))
        A.gif(os.path.join(out, f"{name}_{anim['name']}.gif"), frames * loops, fps=fps)
        print(name, anim["name"], f"{anim['length']}s", n, "frames")
    shutil.copy(os.path.join(MODELS, name + ".bbmodel"), os.path.join(out, name + ".bbmodel"))


def main(*names):
    for name in names or ANIMALS:
        m = build(name)
        preview(name, m)


if __name__ == "__main__":
    main(*sys.argv[1:])
