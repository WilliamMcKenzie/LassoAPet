"""Rockworm (QM Oct 11): the Sandworm reskinned in the Rock Hog's basalt colours, with its
fins, horn and tail spike glowing lava orange (Glow* = Neon in game). QM will give it
cooler mouth fangs.

Run: python3 tools/rockworm.py [out_dir]
Reads designs/desert/Sandworm.bbmodel (QM's file: shapes and animations untouched) and
writes Rockworm.bbmodel, Rockworm.png, Rockworm_vs_horse.png and idle/walk/gallop GIFs.
"""

import base64
import io
import json
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from partlib import render  # noqa: E402
from rock_hog import SCHEMES  # noqa: E402
from snow_rig import posed  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
SANDWORM = os.path.join(ROOT, "designs", "desert", "Sandworm.bbmodel")
HORSE = os.path.join(ROOT, "designs", "animals", "Horse.bbmodel")
OUT = "/mnt/project-files/animals/rockworm"

S = SCHEMES["Basalt"]
COLORS = {  # texture name -> colour
    "sand": S["coat"],
    "plate": S["mane"],
    "belly": (120, 130, 162),
    "dark": S["hooves"],
    "lava": S["lava"],
}
GLOW = ("Fin", "Horn", "TailSpike")  # these move onto the lava texture


def solid(rgb):
    buf = io.BytesIO()
    Image.new("RGBA", (16, 16), (*rgb, 255)).save(buf, "PNG")
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()


def rockworm(m):
    m = json.loads(json.dumps(m))
    m["name"] = "Rockworm"
    lava = dict(m["textures"][0], name="lava", id=str(len(m["textures"])), uuid="7a1c5e0b-1f00-4c2a-9d6e-50c0a7a00001")
    m["textures"].append(lava)
    for t in m["textures"]:
        if t["name"] in COLORS:
            t["source"] = solid(COLORS[t["name"]])
    li = len(m["textures"]) - 1
    for e in m["elements"]:
        base = e["name"].rstrip("0123456789")
        if base.endswith(GLOW) or base in GLOW:
            e["name"] = "Glow" + e["name"]
            for f in e["faces"].values():
                if f.get("texture") is not None:
                    f["texture"] = li
    return m


def parts(model, anim=None, t=0.0):
    ps = posed(model, anim, t)
    for p in ps:
        if p.name.startswith(("Maw", "Eye")):
            p.plain = True
        if p.name.startswith("Glow"):
            p.neon = True
    return ps


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    m = rockworm(json.load(open(SANDWORM)))
    with open(os.path.join(out, "Rockworm.bbmodel"), "w") as f:
        json.dump(m, f, separators=(",", ":"))
    T = 420
    views = [dict(eye=(-22, 12, -24), target=(0, 3, 0), W=T, H=T, fov=38), dict(eye=(-34, 5, 0), target=(0, 3, 0), W=T, H=T, fov=36),
             dict(eye=(-6, 6, -26), target=(0, 3, -4), W=T, H=T, fov=32)]
    sheet = Image.new("RGB", (T * 3, T))
    for i, v in enumerate(views):
        sheet.paste(render(parts(m), **v), (i * T, 0))
    A.label(sheet, ["Rockworm", "side", "face"], 22).save(os.path.join(out, "Rockworm.png"))
    cam = dict(eye=(-30, 12, -30), target=(0, 6, 0), W=T, H=T, fov=36)
    pair = Image.new("RGB", (T * 2, T))
    pair.paste(render(parts(json.load(open(HORSE))), **cam), (0, 0))
    pair.paste(render(parts(m), **cam), (T, 0))
    A.label(pair, ["Horse", "Rockworm"], 22).save(os.path.join(out, "Rockworm_vs_horse.png"))
    for name, n in (("idle", 20), ("walk", 14), ("gallop", 14)):
        anim = next((x for x in m["animations"] if x["name"] == name), None)
        if anim:
            L = anim["length"]
            A.gif(os.path.join(out, f"Rockworm_{name}.gif"),
                  [A.label(render(parts(m, anim, L * i / n), **views[1]), [name], 22) for i in range(n)], fps=n / L)
    print("wrote", out)




# ---------------------------------------------------------------- leaping run (on QM's file)
# QM (Oct 11): no ground time: it leaps out of the ground, arcs through the air, dives back
# in and bursts out again, over and over (a porpoise / dolphin run). The body follows one
# sine path through the ground: each piece sits where the head was a moment ago, so a
# wave of the path runs head to tail. Root position rides the path (in bb units, 0.1 stud);
# each bone's pitch is the chord of the path across its piece, relative to its parent.
CHAIN = [("neck", -87, 0), ("root", 0, 32), ("Seg2", 32, 62), ("Seg3", 62, 90), ("Seg4", 90, 116),
         ("Seg5", 116, 138), ("Seg6", 138, 156)]  # bone, piece's front and back z
PARENT = {"neck": "root", "Seg2": "root", "Seg3": "Seg2", "Seg4": "Seg3", "Seg5": "Seg4", "Seg6": "Seg5"}
ROOT_Z = 16  # root pivot


def leap(leap_time, wavelength, amp, ground=0.0, wiggle=8, n=48):
    """One leap (an arc up and a dive back under, wavelength bb units long, amp high and
    deep, taking leap_time s) then ground s of slithering flat along the ground. QM tried
    0.8 s, then went back to none (Oct 11 03:10)."""
    import math
    from snake_rig import track
    TAU = 2 * math.pi
    v = wavelength / leap_time  # bb units a second along the path
    cycle = wavelength + v * ground
    L = leap_time + ground

    def path(x):
        x %= cycle
        return amp * math.sin(TAU * x / wavelength) if x < wavelength else 0.0

    def y(z, u):  # the piece at z is where the root was (z - ROOT_Z) / v seconds ago
        return path(v * L * u - (z - ROOT_Z))

    def pitch(bone, u):  # nose up positive: front higher than back
        _, za, zb = next(c for c in CHAIN if c[0] == bone)
        return math.degrees(math.atan2(y(za, u) - y(zb, u), zb - za))

    def sway(bone, u):  # a side-to-side wave while the root's on the ground
        j = [c[0] for c in CHAIN].index(bone)
        if ground <= 0:
            return 0.0
        on = 1.0 if (v * L * u) % cycle >= wavelength else 0.0
        return on * wiggle * math.sin(TAU * 3 * u * L / ground - 0.9 * j) if bone != "neck" else 0.0

    tr = {"root": [track(L, lambda u: (pitch("root", u), 0, 0), n),
                   track(L, lambda u: (0, y(ROOT_Z, u), 0), n, "position")]}
    for bone, parent in PARENT.items():
        tr[bone] = [track(L, lambda u, b=bone, p=parent: (pitch(b, u) - pitch(p, u), sway(b, u), 0), n)]
    # the fangs gape as it bursts out of the ground and snap shut at the top of the arc
    gape = lambda u: max(0.0, math.sin(TAU * (u * L / leap_time + 0.1))) ** 2 if u * L < leap_time else 0.0  # noqa: E731
    tr["MandTL"] = [track(L, lambda u: (0, 26 * gape(u), 0), n)]
    tr["MandTL2"] = [track(L, lambda u: (0, -26 * gape(u), 0), n)]
    return L, tr


def animate(src, dst=None, out=OUT):
    """Replace walk and gallop in QM's file (src) with the leaping run; keep idle."""
    from horse_rig import write_animations
    from snow_rig import group_ids
    dst = dst or os.path.join(out, "Rockworm_leap.bbmodel")
    m = json.load(open(src))
    idle = next(a for a in m["animations"] if a["name"] == "idle")
    m["animations"] = []
    write_animations(m, group_ids(m), {"walk": leap(1.6, 560, 70), "gallop": leap(1.1, 560, 95)})
    m["animations"].insert(0, idle)
    with open(dst, "w") as f:
        json.dump(m, f, separators=(",", ":"))
    T = 420
    cams = [dict(eye=(-36, 6, 2), target=(0, 1, 3), W=T, H=T, fov=44), dict(eye=(-24, 14, -26), target=(0, 1, 3), W=T, H=T, fov=44)]
    for name, n in (("walk", 40), ("gallop", 32)):
        anim = next(a for a in m["animations"] if a["name"] == name)
        L = anim["length"]
        frames = []
        for i in range(n):
            ps = parts(m, anim, L * i / n)
            im = Image.new("RGB", (T * 2, T))
            for c, cam in enumerate(cams):
                im.paste(render(ps, **cam), (c * T, 0))
            frames.append(A.label(im, [name, ""], 22))
        A.gif(os.path.join(out, f"Rockworm_{name}.gif"), frames, fps=n / L)
    print("wrote", dst)


if __name__ == "__main__":
    if sys.argv[1:2] == ["animate"]:
        animate(*sys.argv[2:])
    else:
        main(*sys.argv[1:])
