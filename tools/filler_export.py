"""QM's picks from the luck-padding animals (Nov 7): rigged, animated and into the game.

Run from the repo root: python3 tools/filler_export.py
For each pick: designs/filler/rigged/<Kind>.bbmodel (bones + idle/walk/gallop),
src/shared/Animals/<Kind>Model.luau (tools/bbmodel_to_luau.py), and, unless it's hand-edited
(HAND), src/shared/Animals/<Kind>.luau; its egg (designs/eggs/c_style/<Kind>Egg.bbmodel,
src/shared/Eggs/<Kind>EggModel.luau, assets/ui/<Kind>EggRender.png). Prints the Config lines.

Every model is first scaled to the Horse's silhouette, so the leap and bob read the same on
all of them; how big each one is in game is its size tier (Config.PetTiers), as for every pet.
"""

import json
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import filler_core as C  # noqa: E402
import animal_designs as A  # noqa: E402
from animal_designs import at, leap, pos_y, rot_x, rot_z, GALLOPS  # noqa: E402
from horse_rig import write_animations  # noqa: E402
from partlib import part_faces, write_bbmodel  # noqa: E402
import bbmodel_to_luau  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
RIGGED = os.path.join(ROOT, "designs", "filler", "rigged")
ANIMALS = os.path.join(ROOT, "src", "shared", "Animals")
HORSE_SIL = 9.7  # the Horse model's silhouette (sqrt of its two biggest sides), studs

# kind: (biome module, builder, motion, Lasso rarity, size tier, hatch s, gold/s, speed, stamina, herd weight)
PICKS = {
    # Meadow
    "Snail": ("meadow", "snail", "slide", "Uncommon", 2, 15, 9, 0.8, 0.8, 0.2),
    "Giraffe": ("meadow", "giraffe", "quad", "Epic", 3, 120, 90, 1.35, 2.2, 0.06),
    "HillbackTortoise": ("meadow", "hillback_tortoise", "titan", "Legendary", 4, 3600, 450, 1.6, 3, 0.02),
    # Desert
    "Coyote": ("desert", "coyote", "quad", "Uncommon", 2, 15, 24, 1.5, 1.2, 0.2),
    "Oryx": ("desert", "oryx", "quad", "Rare", 2, 60, 60, 1.77, 1.5, 0.2),
    "Ostrich": ("desert", "ostrich", "biped", "Epic", 3, 90, 240, 1.97, 2, 0.12),
    "MirageElephant": ("desert", "mirage_elephant", "titan", "Legendary", 4, 7200, 750, 2.8, 3, 0.015),
    # Tundra (Config's "Snow")
    "Seal": ("tundra", "seal", "hop", "Uncommon", 2, 15, 75, 2.355, 1.5, 0.25),
    "Reindeer": ("tundra", "reindeer", "quad", "Rare", 2, 60, 300, 2.678, 1.3, 0.18),
    "Walrus": ("tundra", "walrus", "hop", "Rare", 3, 60, 300, 2.5, 2, 0.15),
    "Narwhal": ("tundra", "narwhal", "fish", "Epic", 3, 300, 1260, 2.86, 3, 0.08),
    "GlacierMammoth": ("tundra", "glacier_mammoth", "titan", "Legendary", 4, 7200, 3333, 3.8, 4, 0.015),
    # Volcano
    "FireAnt": ("volcano", "fire_ant", "hop", "Uncommon", 2, 15, 12000, 5.11, 2.5, 0.3),
    "MagmaCrab": ("volcano", "magma_crab", "hop", "Rare", 2, 60, 20000, 6.56, 2.8, 0.15),
    "AshBehemoth": ("volcano", "ash_behemoth", "titan", "Legendary", 4, 7200, 45000, 7.2, 3, 0.02),
    # Dungeon
    "Rat": ("dungeon", "rat", "quad", "Uncommon", 2, 60, 12000, 7.6, 3, 0.3),
    "CaveCricket": ("dungeon", "cave_cricket", "hop", "Uncommon", 2, 60, 12000, 7.4, 3, 0.2),
    "CryptSnail": ("dungeon", "crypt_snail", "slide", "Uncommon", 2, 60, 12000, 7.0, 3, 0.2),
    "WebSpider": ("dungeon", "cave_spider", "hop", "Rare", 2, 300, 20000, 8.2, 3, 0.14),  # (a Cave Spider is already there)
    "AbyssPillbug": ("dungeon", "abyss_pillbug", "slide", "Legendary", 4, 7200, 42500, 8.6, 3, 0.02),
    # Forest
    "StagBeetle": ("forest", "stag_beetle", "hop", "Uncommon", 2, 60, 12000, 7.6, 3, 0.25),
    "Deer": ("forest", "deer", "quad", "Rare", 2, 300, 20000, 8.4, 3, 0.15),
    "BrownBear": ("forest", "brown_bear", "quad", "Epic", 3, 1200, 27500, 7.6, 3, 0.07),
    "AncientMoose": ("forest", "ancient_moose", "titan", "Legendary", 4, 7200, 42500, 8.6, 3, 0.02),
    # Castle
    "Swan": ("castle", "swan", "hop", "Uncommon", 2, 60, 12000, 8.4, 3, 0.25),
    "ArmoredRam": ("castle", "armored_ram", "quad", "Uncommon", 2, 60, 12000, 9.0, 3, 0.22),
    "RoyalStag": ("castle", "royal_stag", "quad", "Rare", 2, 300, 20000, 8.8, 3, 0.14),
    "Griffin": ("castle", "griffin", "quad", "Epic", 3, 1200, 27500, 9.2, 3, 0.05),
    "FortressTortoise": ("castle", "fortress_tortoise", "titan", "Legendary", 4, 7200, 60000, 8.6, 3, 0.01),
    # Ocean
    "Shrimp": ("ocean", "shrimp", "hop", "Uncommon", 2, 60, 12000, 8.2, 3, 0.28),
    "Pelican": ("ocean", "pelican", "fly", "Uncommon", 2, 60, 12000, 8.4, 3, 0.2),
    "Hammerhead": ("ocean", "hammerhead", "fish", "Rare", 3, 300, 20000, 8.8, 3, 0.12),
    "MantaRay": ("ocean", "manta_ray", "fly", "Epic", 3, 1200, 27500, 9.0, 3, 0.07),
    "Anglerfish": ("ocean", "anglerfish", "hop", "Epic", 2, 1200, 27500, 8.6, 3, 0.07),
}
CONFIG_BIOME = {"meadow": "Meadow", "desert": "Desert", "tundra": "Snow", "volcano": "Volcano", "dungeon": "Dungeon",
                "forest": "Forest", "castle": "Castle", "ocean": "Ocean"}
# Seats placed by hand (model units before scaling): on the hill, the keep's roof, the blanket
SEATS = {"HillbackTortoise": (0, 17.0, -5.0), "FortressTortoise": (0, 24.0, -4.5), "MirageElephant": (0, 56.0, 0.0),
         "AshBehemoth": (0, 24.0, 3.0), "GlacierMammoth": (0, 30.0, 5.0)}
# Modules written by hand (not overwritten): the Hillback's pine is the map's mesh
HAND = {"HillbackTortoise"}
DROP = {"BrownBear": ("Fish",), "HillbackTortoise": ("Trunk", "Leaves", "Leaves2")}  # (QM, Nov 7)


def build(kind):
    mod, fn, *_ = PICKS[kind]
    m = __import__("filler_" + mod)
    a = getattr(m, fn)()
    a.name = kind
    a.parts = [p for p in a.parts if p.name not in DROP.get(kind, ())]
    return a


def pts(parts):
    return np.concatenate([np.concatenate([w for w, _ in part_faces(p)]) for p in parts])


def box(parts):
    P = pts(parts)
    return P.min(0), P.max(0)


def silhouette(parts):
    lo, hi = box(parts)
    d = sorted(hi - lo)
    return float(np.sqrt(d[1] * d[2]))


# ---------------------------------------------------------------- bones

def assign_bones(a, motion):
    """Legs, tail, wings and fins onto their own bones (by part name); the rest stay put."""
    for p in a.parts:
        n = p.name
        if n[:3] == "Leg" and n[3:5] in ("FL", "FR", "HL", "HR") or n[:4] == "Foot" and n[4:6] in ("FL", "FR", "HL", "HR"):
            p.bone = "Leg" + (n[3:5] if n.startswith("Leg") else n[4:6])
        elif motion == "biped" and n in ("LegL", "FootL"):
            p.bone = "LegFL"
        elif motion == "biped" and n in ("LegR", "FootR"):
            p.bone = "LegHR"
        elif n.startswith(("Tail", "TailTip")) and p.bone == "root":
            p.bone = "Tail"
        elif motion == "fish" and n in ("TailRoot", "FinTop", "FinBottom", "Dorsal", "BigDorsal", "TallDorsal"):
            p.bone = "Tail"
        elif n[:4] == "Wing" and n[-1] in "LR":
            p.bone = "Wing" + n[-1]
        elif motion == "fish" and n in ("FinL", "FinR"):
            p.bone = n


def bone_list(a):
    """(name, parent, pivot) for every bone a part is on, pivots from the parts' boxes."""
    by = {}
    for p in a.parts:
        by.setdefault(getattr(p, "bone", "root"), []).append(p)
    root_lo, root_hi = box(by["root"])
    out = [("root", None, tuple((root_lo + root_hi) / 2))]
    for b, parts in by.items():
        if b == "root":
            continue
        lo, hi = box(parts)
        c = (lo + hi) / 2
        if b == "neck":
            piv = a.pivots.get("neck") or (0, lo[1], hi[2])
        elif b.startswith("Leg"):
            piv = (c[0], hi[1], c[2])
        elif b == "Tail":
            piv = (0, hi[1], lo[2])
        elif b.startswith(("Wing", "Fin")):
            piv = (lo[0] if b.endswith("R") else hi[0], c[1], c[2])
        elif b.startswith("Ear"):
            piv = a.pivots.get(b) or (c[0], lo[1], c[2])
        else:
            piv = tuple(c)
        parent = "neck" if b.startswith("Ear") and "neck" in by else "root"
        out.append((b, parent, tuple(float(x) for x in piv)))
    return out


# ---------------------------------------------------------------- animations

def filtered(anims, bones):
    names = {b for b, _, _ in bones}
    return {k: (L, {b: t for b, t in tracks.items() if b in names}) for k, (L, tracks) in anims.items()}


def neck_idle(L=2.4, amp=4):
    return (L, {"neck": [rot_x([(0, 0), (L / 2, amp), (L, 0)], "catmullrom")],
                "Tail": [rot_x([(0, 0), (L / 2, -8), (L, 0)], "catmullrom")]})


def hop(L, h, pitch=6):
    return (L, {
        "root": [pos_y(at(L, [(0, 0), (0.15, 0), (0.5, h), (0.85, 0), (1, 0)])),
                 {"channel": "rotation", "interp": "catmullrom",
                  "keys": [(t, (v, 0, 0)) for t, v in at(L, [(0, 0), (0.15, pitch), (0.5, 0), (0.85, -pitch), (1, 0)])]}],
        "neck": [rot_x(at(L, [(0, -6), (0.5, 2), (1, -6)]), "catmullrom")],
        "Tail": [rot_x(at(L, [(0, -10), (0.5, -30), (1, -10)]), "catmullrom")],
    })


def slide(L, h):
    return (L, {
        "root": [pos_y(at(L, [(0, 0), (0.5, h), (1, 0)])),
                 {"channel": "rotation", "interp": "catmullrom",
                  "keys": [(t, (v, 0, 0)) for t, v in at(L, [(0, 0), (0.25, 3), (0.75, -3), (1, 0)])]}],
        "neck": [rot_x(at(L, [(0, 0), (0.5, 6), (1, 0)]), "catmullrom")],
    })


def flaps(L, amp, h=0):
    keys = at(L, [(0, amp), (0.5, -amp * 0.6), (1, amp)])
    tracks = {"WingL": [rot_z([(t, -v) for t, v in keys], "catmullrom")], "WingR": [rot_z(keys, "catmullrom")]}
    if h:
        tracks["root"] = [pos_y(at(L, [(0, 0), (0.5, h), (1, 0)]))]
    return tracks


def animations(motion, kind):
    if motion in ("quad", "biped", "titan"):
        anims = A.quad_animations()
        if motion == "titan":
            anims["gallop"] = leap(**GALLOPS["B"])
    elif motion == "hop":
        anims = {"idle": neck_idle(), "walk": hop(0.6, 6), "gallop": hop(0.5, 16)}
    elif motion == "slide":
        anims = {"idle": neck_idle(3.0, 3), "walk": slide(1.0, 2), "gallop": slide(0.6, 4)}
    elif motion == "fish":
        anims = A.fish_animations()
    elif motion == "fly":
        anims = {"idle": (1.2, flaps(1.2, 20, 5)), "walk": (0.7, flaps(0.7, 30, 8)), "gallop": (0.5, flaps(0.5, 40, 12))}
    if kind == "Griffin":  # wings beat on its run
        for name, L in (("idle", None), ("walk", None), ("gallop", None)):
            length, tracks = anims[name]
            tracks = dict(tracks)
            tracks.update(flaps(length, 25 if name == "gallop" else 10))
            anims[name] = (length, tracks)
    return anims


# ---------------------------------------------------------------- export

def seat_and_neck(a, kind, k):
    root = [p for p in a.parts if getattr(p, "bone", "root") == "root"]
    lo, hi = box(root)
    if kind in SEATS:
        seat = tuple(np.array(SEATS[kind], float) * k)
    else:
        zc = (lo[2] + hi[2]) / 2
        top = lo[1]
        for p in root:
            plo, phi = box([p])
            if plo[0] <= 0 <= phi[0] and plo[2] <= zc <= phi[2] and not p.name.startswith(("Spike", "Crest", "Quill", "Glow")):
                top = max(top, phi[1])
        seat = (0.0, float(top), float(zc))
    head = [p for p in a.parts if p.name == "Head"] or [p for p in a.parts if getattr(p, "bone", "") == "neck"] or root
    hlo, hhi = box(head)
    c = (hlo + hhi) / 2
    r = float(np.hypot(hhi[1] - hlo[1], hhi[2] - hlo[2]) / 2)
    return seat, (float(c[0]), float(c[1]), float(c[2])), max(r, 1.0)


def v3(v):
    return "Vector3.new({:g}, {:g}, {:g})".format(*(round(float(x), 2) + 0.0 for x in v))


NUDGE = 0.025  # model units: 0.25 Blockbench pixels (QM, Nov 7: "extend one out by 0.25 pixels")


def faces(p):
    """A block's six faces as (normal, plane offset, centre, two in-plane half-axes)."""
    R, c, h = p.cf[:3, :3], p.cf[:3, 3], p.size / 2
    out = []
    for ax in range(3):
        for sg in (-1, 1):
            n = R[:, ax] * sg
            u, v = [R[:, a] * h[a] for a in range(3) if a != ax]
            fc = c + n * h[ax]
            out.append((ax, sg, n, n @ fc, fc, u, v))
    return out


def overlap(f, g):
    """Do two coplanar faces share area? (Separating axes in the plane.)"""
    _, _, n, _, c1, u1, v1 = f
    _, _, _, _, c2, u2, v2 = g
    for axis in (u1, v1, u2, v2):
        L = np.linalg.norm(axis)
        a = axis / L
        r1 = abs(u1 @ a) + abs(v1 @ a)
        r2 = abs(u2 @ a) + abs(v2 @ a)
        if abs((c2 - c1) @ a) >= r1 + r2 - 1e-3:
            return False
    return True


def unfight(parts):
    """No z-fighting: where two blocks have flush faces facing the same way and overlapping,
    extend the smaller one out past the other by NUDGE. Returns how many faces moved."""
    blocks = [p for p in parts if p.shape == "Block"]
    moved = 0
    for _ in range(4):
        fixes = {}
        for i, p in enumerate(blocks):
            for q in blocks[i + 1:]:
                for f in faces(p):
                    for g in faces(q):
                        if f[2] @ g[2] > 0.999 and abs(f[3] - g[3]) < NUDGE - 1e-6 and overlap(f, g):
                            (small, face), big = ((p, f), g) if np.prod(p.size) <= np.prod(q.size) else ((q, g), f)
                            step = big[3] + NUDGE - face[3]  # out to NUDGE past the other's face
                            key = (id(small), face[0], face[1])
                            if step > fixes.get(key, (0, 0, 0))[2]:
                                fixes[key] = (small, face, step)
        if not fixes:
            break
        for small, (ax, sg, n, *_), step in fixes.values():
            small.size[ax] += step
            small.cf[:3, 3] += n * step / 2
            moved += 1
    return moved


def export(kind):
    biome, fn, motion, rarity, tier, *_ = PICKS[kind]
    a = build(kind)
    k = HORSE_SIL / silhouette(a.parts)
    C.grow(a, k)
    a.nudged = unfight(a.parts)
    for p in a.parts:
        if not hasattr(p, "bone"):
            p.bone = "root"
    assign_bones(a, motion)
    bones = bone_list(a)
    model, groups = write_bbmodel(a.parts, kind, None, bones=bones)
    write_animations(model, groups, filtered(animations(motion, kind), bones))
    os.makedirs(RIGGED, exist_ok=True)
    src = os.path.join(RIGGED, kind + ".bbmodel")
    with open(src, "w") as f:
        json.dump(model, f, separators=(",", ":"))
    bbmodel_to_luau.main(src, os.path.join(ANIMALS, kind + "Model.luau"))
    seat, nc, nr = seat_and_neck(a, kind, k)
    if kind not in HAND:
        label = C.display(a) if a.label else kind
        with open(os.path.join(ANIMALS, kind + ".luau"), "w") as f:
            f.write(f"""-- {label}: World 1 {CONFIG_BIOME[biome]}'s {rarity} (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_{biome}.py ({fn}), rigged by tools/filler_export.py into
-- designs/filler/rigged/{kind}.bbmodel and converted into {kind}Model.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local {kind}Model = require(script.Parent.{kind}Model)

return Horse.variant("{kind}", {kind}Model, "{rarity}", {{
	seat = {v3(seat)},
	neck = {{ center = {v3(nc)}, radius = {round(nr, 2)} }},
}})
""")
    if kind == "HillbackTortoise":
        hillback_module(k, seat, nc, nr)
    print(f"{kind:18} {len(a.parts):3} parts, x{k:.2f}, seat {v3(seat)}, {a.nudged} faces nudged")
    return a, k, seat, nc, nr


# The Hillback's tree (QM, Nov 7: "an actual tree mesh"): the map's tall pine, its MeshParts
# copied from ServerStorage.WorldAssets.PineTall into ReplicatedStorage.AnimalMeshes as
# PineTall_<piece> by Server/AnimalMeshCopies, standing on the hill (its base at TREE_AT,
# TREE_SCALE x the map's size, in model units before the model's own scaling).
PINE = (("Trunk", (120, 84, 58)), ("Tier1", (46, 125, 80)), ("Tier2", (58, 140, 88)), ("Tier3", (40, 112, 72)), ("Tier4", (66, 150, 96)))
TREE_AT, TREE_SCALE = (0.0, 16.8, 1.0), 0.85  # (QM, Nov 7: was 19, the trunk floated over the hill; its top is ~17)


def hillback_module(k, seat, nc, nr):
    lines = []
    for piece, rgb in PINE:
        V = np.array([list(map(float, l.split()[1:4])) for l in open(os.path.join(ROOT, "assets", "meshes", f"PineTall_{piece}.obj"))
                      if l.startswith("v ")])
        lo, hi = V.min(0), V.max(0)
        centre = (np.array(TREE_AT) + ((lo + hi) / 2 - np.array([0, -0.5, 0])) * TREE_SCALE) * k
        size = (hi - lo) * TREE_SCALE * k
        lines.append(f'\t{{ name = "Pine{piece}", bone = "root", class = "MeshPart", mesh = "PineTall_{piece}", '
                     f'size = {v3(size)}, cframe = CFrame.new({centre[0]:.2f}, {centre[1]:.2f}, {centre[2]:.2f}), color = Color3.fromRGB{rgb} }},')
    body = "\n".join(lines)
    with open(os.path.join(ANIMALS, "HillbackTortoise.luau"), "w") as f:
        f.write(f"""-- Hillback Tortoise: World 1 Meadow's Legendary titan (QM, Nov 7: one of the luck-padding animals
-- QM picked), a giant tortoise with a grassy hill on its shell and the map's tall pine growing
-- on it (QM: "an actual tree mesh"). Model from tools/filler_meadow.py, rigged by
-- tools/filler_export.py (which writes this file) into HillbackTortoiseModel.luau. The pine's
-- MeshParts come from ReplicatedStorage.AnimalMeshes (Server/AnimalMeshCopies copies them from
-- the map's ServerStorage.WorldAssets.PineTall).

local Horse = require(script.Parent.Horse)
local HillbackTortoiseModel = require(script.Parent.HillbackTortoiseModel)

local PINE = {{
{body}
}}

local data = table.clone(HillbackTortoiseModel)
data.parts = table.clone(HillbackTortoiseModel.parts)
for _, part in PINE do
	table.insert(data.parts, part)
end

return Horse.variant("HillbackTortoise", data, "Legendary", {{
	seat = {v3(seat)},
	neck = {{ center = {v3(nc)}, radius = {round(nr, 2)} }},
}})
""")


if __name__ == "__main__":
    kinds = sys.argv[1:] or list(PICKS)
    for kind in kinds:
        export(kind)
