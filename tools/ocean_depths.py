"""Ocean depths concept (QM, Oct 2): the ocean gets darker the further you ride,
from the coral reef, through bare sand flats and dark rock with the first lava
streaks, down to a volcanic abyss.

Run: python3 tools/ocean_depths.py [out_dir]

Draft only: renders one ride view per stage plus a top-down strip of the whole
13680-stud ocean. Colours blend smoothly along the course; the stages are just
snapshots of that blend.
"""

import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from partlib import Part, T, Ry, render  # noqa: E402
from desert_ground import noise, CELL, HALF_W  # noqa: E402
import terrain_assets as TA  # noqa: E402
from ocean_ground import underwater  # noqa: E402

LENGTH = 200

# key palettes along the course (t = 0 start of the ocean, 1 the finish line)
#   ground pair, patch pair, wall pair, haze, coral fade, darkness
STAGES = [
    dict(t=0.00, name="1  Coral reef", sand=[(236, 214, 164), (246, 228, 184)], patch=[(64, 178, 122), (80, 196, 138)],
         wall=[(236, 140, 124), (250, 160, 142)], haze=(60, 150, 235), grass=0.30, rock=0.00, lava=0.00, dark=0.00),
    dict(t=0.33, name="2  Sand flats", sand=[(222, 196, 150), (234, 210, 166)], patch=[(76, 150, 112), (90, 164, 124)],
         wall=[(196, 150, 140), (212, 166, 154)], haze=(44, 112, 200), grass=0.08, rock=0.10, lava=0.00, dark=0.12),
    dict(t=0.66, name="3  Dark rock", sand=[(112, 112, 128), (126, 126, 142)], patch=[(70, 72, 90), (82, 84, 102)],
         wall=[(84, 88, 112), (98, 102, 126)], haze=(26, 50, 120), grass=0.00, rock=0.30, lava=0.04, dark=0.32),
    dict(t=1.00, name="4  Volcanic abyss", sand=[(54, 50, 62), (66, 62, 74)], patch=[(36, 34, 44), (46, 44, 54)],
         wall=[(40, 38, 50), (52, 50, 62)], haze=(18, 16, 52), grass=0.00, rock=0.40, lava=0.14, dark=0.45),
]
LAVA = [(255, 110, 20), (255, 160, 40)]
LAVA_DOWN = 1  # lava streaks sit a stud below the floor, like the trenches
ROCK_UP = 1


def mix(a, b, f):
    return tuple(int(round(x + (y - x) * f)) for x, y in zip(a, b))


def at(t):
    """Blend the key stages at course fraction t."""
    for s0, s1 in zip(STAGES, STAGES[1:]):
        if t <= s1["t"]:
            f = (t - s0["t"]) / (s1["t"] - s0["t"])
            out = {}
            for key, v in s0.items():
                w = s1[key]
                if key == "name":
                    out[key] = v
                elif isinstance(v, list):
                    out[key] = [mix(a, b, f) for a, b in zip(v, w)]
                elif isinstance(v, tuple):
                    out[key] = mix(v, w, f)
                else:
                    out[key] = v + (w - v) * f
            return out
    return dict(STAGES[-1])


def layout(nz, t0, t1, seed=41):
    """Kind per 8-stud cell: 0 floor, 1 seagrass / rock patch, 2 lava streak."""
    nx = 2 * HALF_W // CELL
    ts = np.linspace(t0, t1, nz)
    a = noise(nx, nz, 5.0, seed) * 0.7 + noise(nx, nz, 2.2, seed + 1) * 0.3
    streak = np.abs(noise(nx, nz, 4.0, seed + 5) - 0.5)  # ridged noise: thin wandering lines
    kind = np.zeros((nx, nz), int)
    for j, t in enumerate(ts):
        s = at(t)
        share = s["grass"] + s["rock"]
        kind[a[:, j] > 1 - share * 1.6, j] = 1
        if s["lava"] > 0:
            kind[streak[:, j] < s["lava"] * 0.5, j] = 2
    kind[0, :][kind[0, :] == 2] = 0
    kind[-1, :][kind[-1, :] == 2] = 0
    return kind, ts


# ---------------------------------------------------------------- deep assets

BASALT, BASALT_L, BASALT_D = (58, 56, 70), (76, 74, 90), (42, 40, 52)


def basalt_rock(k):
    """Medium: tilted dark slabs with a lava crack across the top."""
    k.at("Rock", (0, 1.4, 0), (9, 3.0, 7), BASALT, TA.rot(12, 3, -4))
    k.at("Rock", (0.6, 3.3, -0.4), (6, 1.6, 5), BASALT_L, TA.rot(-10, -3, 5))
    k.at("Lava", (0.6, 4.15, -0.4), (5.2, 0.2, 0.8), LAVA[1], TA.rot(30, 0, 0))


def vent(k):
    """Large: a stack of basalt columns with a glowing lava top (a black smoker)."""
    for x, z, h, w in ((0, 0, 9, 4), (-3.2, 1.4, 6, 3), (2.8, -1.6, 5, 3), (1.4, 2.6, 3.5, 2.6)):
        k.box("Vent", (x - w / 2, 0, z - w / 2), (x + w / 2, h, z + w / 2), BASALT if h > 4 else BASALT_D)
        k.box("Lava", (x - w / 2 + 0.5, h, z - w / 2 + 0.5), (x + w / 2 - 0.5, h + 0.3, z + w / 2 - 0.5), LAVA[0])
    k.box("Rock", (-6, 0, -4), (6, 1.2, 4.5), BASALT_D)


def fade(parts, f):
    """Wash coral towards dark basalt: f 0 untouched, 1 fully stone."""
    if f <= 0:
        return parts
    return [Part(p.name, p.size, p.cf, mix(p.color, BASALT_L, f), p.shape, p.plain) for p in parts]


def asset(builder, x, z, yaw, f=0.0):
    k = TA.Kit()
    builder(k)
    M = T(x, 0, z) @ Ry(yaw)
    keep = [Part(p.name, p.size, M @ p.cf, p.color, p.shape, p.plain) for p in k.parts]
    lava = [p for p in keep if p.name == "Lava"]
    return fade([p for p in keep if p.name != "Lava"], f) + lava


# clusters hug the walls, alternating sides (QM, Oct 1); x is the wall side
CLUSTERS = [(-1, -40), (1, -95), (-1, -150), (1, -195)]


def stage_assets(i):
    out = []
    for n, (side, z) in enumerate(CLUSTERS):
        x = side * (HALF_W - 12)
        if i == 0:
            picks = [(TA.reef_rock, 0, 0), (TA.tube_coral, -side * 9, 6), (TA.fan_coral, -side * 4, -8)]
        elif i == 1:
            picks = [(TA.reef_rock, 0, 0), (TA.brain_coral, -side * 9, 5)] if n % 2 == 0 else [(TA.brain_coral, 0, 0)]
        elif i == 2:
            picks = [(basalt_rock, 0, 0), (TA.reef_rock, -side * 10, 7)] if n % 2 == 0 else [(basalt_rock, 0, 0)]
        else:
            picks = [(vent, 0, 0), (basalt_rock, -side * 10, 6)] if n % 2 == 0 else [(vent, 0, 0)]
        for b, dx, dz in picks:
            out += asset(b, x + dx, z + dz, 20 * n + dx, f=(0, 0.25, 0.8, 1)[i])
    return out


def scene(i):
    s = STAGES[i]
    kind, ts = layout(LENGTH // CELL, s["t"], s["t"], seed=41 + i * 7)
    parts = []
    nx, nz = kind.shape
    for ci in range(nx):
        for cj in range(nz):
            k = kind[ci, cj]
            top = (0, ROCK_UP if s["rock"] > s["grass"] else 0, -LAVA_DOWN)[k]
            pal = (s["sand"], s["patch"], LAVA)[k]
            for di in (0, 1):
                for dj in (0, 1):
                    x = -HALF_W + ci * CELL + di * 4 + 2
                    z = -cj * CELL - dj * 4 - 2
                    parts.append(Part("Floor", (4, top + 2, 4), T(x, (top - 2) / 2, z), pal[(di + dj) % 2],
                                      plain=(k == 2)))
    rng = np.random.default_rng(i)
    for side in (-1, 1):
        for zi in range(LENGTH // 4):
            for yi in range(5):
                c = s["wall"][(zi + yi) % 2]
                # lava seams run down the abyss walls
                if s["lava"] > 0.1 and yi < 4 and rng.random() < 0.05:
                    c = LAVA[0]
                parts.append(Part("Wall", (4, 4, 4), T(side * (HALF_W + 2), yi * 4 + 2, -zi * 4 - 2), c, plain=True))
    return parts + stage_assets(i), kind


def grade(img, s):
    """Underwater haze in the stage's colour, then darken everything but the lava glow."""
    a = np.asarray(img, float)
    hot = (a[..., 0] > 220) & (a[..., 1] > 60) & (a[..., 1] < 190) & (a[..., 2] < 90)
    out = np.asarray(underwater_tint(img, s["haze"]), float)
    out = out * (1 - s["dark"])
    out[hot] = a[hot] * 0.9 + np.array([255, 120, 30]) * 0.1  # lava cuts through the haze
    return Image.fromarray(out.clip(0, 255).astype(np.uint8))


def underwater_tint(img, haze):
    import ocean_ground as OG
    old = OG.HAZE
    OG.HAZE = np.array(haze, float)
    try:
        return underwater(img, strength=0.55)
    finally:
        OG.HAZE = old


def strip(W=1600, H=150):
    """Top-down of the whole ocean, start on the left, finish on the right."""
    nz = 13680 // CELL
    kind, ts = layout(nz, 0, 1)
    nx = kind.shape[0]
    img = np.zeros((nx, nz, 3))
    for j, t in enumerate(ts):
        s = at(t)
        for ci in range(nx):
            k = kind[ci, j]
            img[ci, j] = (s["sand"], s["patch"], LAVA)[k][(ci + j) % 2]
    im = Image.fromarray(img.astype(np.uint8)).resize((W, H - 30), Image.NEAREST)
    board = Image.new("RGB", (W, H), (20, 20, 30))
    board.paste(im, (0, 30))
    d = ImageDraw.Draw(board)
    for s in STAGES:
        x = int(s["t"] * (W - 200)) + 6
        d.text((x, 4), s["name"][3:], fill=(255, 255, 255), font=TA.font(18), stroke_width=2, stroke_fill=(0, 0, 0))
    return board


def main(out):
    os.makedirs(out, exist_ok=True)
    kw = dict(W=800, H=520, fog=False, ground=False)
    board = Image.new("RGB", (1600, 1040 + 150), (20, 20, 30))
    for i, s in enumerate(STAGES):
        parts, _ = scene(i)
        ride = grade(render(parts, eye=(0, 70, 30), target=(0, 0, -70), fov=50, **kw), s)
        ride.save(os.path.join(out, f"depth{i + 1}.png"))
        board.paste(ride, ((i % 2) * 800, (i // 2) * 520))
        d = ImageDraw.Draw(board)
        d.text(((i % 2) * 800 + 12, (i // 2) * 520 + 10), s["name"], fill=(255, 255, 255), font=TA.font(26),
               stroke_width=3, stroke_fill=(0, 0, 0))
    board.paste(strip(), (0, 1040))
    board.save(os.path.join(out, "ocean_depths.png"))
    print("wrote", os.path.join(out, "ocean_depths.png"))


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    main(args[0] if args else "/mnt/project-files/biomes/ocean/depths")
