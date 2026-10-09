"""The arc home base (QM, Oct 9; design/base_arc/SPEC.md): writes tools/arc_base.luau.

Run: python3 tools/arc_base.py

Then run tools/arc_base.luau in Studio's command bar (Edit, not Play) on the place.
It reads design/base_arc/arc_layout.json for the dirt tiles, the props and the bull
pads. The pens are tools/pens.py (Workspace.Pens); Carl and the podium are Config.

What the Luau does to Workspace.World (re-running it is fine: it rebuilds the same):
  - the home walls and their caps: moved and resized to x -W..W, z 0..D (the same
    48-high checker walls, the corridor left open), like tools/home_base.py
  - the home floor: the old single Ground part goes; in its place rectangles named
    "Ground" (grass, top at 0) and "Dirt" (top 1 stud lower), each 2 studs deep at
    the bottom like tools/meadow_ground.py, on 8-stud cells (a cell is dirt where half or
    more of the layout's 4-stud tiles are), so the checker stays in step from part
    to part, as on the course. They're tagged "ArcBase" so a
    re-run finds them. WorldColors paints them by name (the Meadow's), and
    Ground.heightAt reads the sunk dirt.
  - World.BaseDecor: copies of the Meadow's Stone, Bush, Boulder and BoulderSplit
    (World.Obstacles), not course obstacles, standing on the floor under them
  - World.BullPads: a placeholder pad per pen (BullPadN, "Pen" attribute), a red
    mat 18 across with a bull on a post, facing the yard; with BULL_PADS off (now),
    none, and any already there go
"""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LAYOUT = ROOT / "design" / "base_arc" / "arc_layout.json"
OUT = ROOT / "tools" / "arc_base.luau"

TILE = 4  # the layout's dirt tiles
BULL_PADS = False  # QM, Oct 9: none for now (their spots stay in the layout's "bulls")
CELL = 8  # what's built: the meadow's 8-stud cells (QM, Oct 9: on 4-stud parts the checker
# fell out of step; on 8 every part starts on a whole checker square, like the course's)


def rects(grid, nx, nz):
    """Greedy rectangles of equal cells: (kind, i0, j0, i1, j1), i/j exclusive ends."""
    used = [[False] * nz for _ in range(nx)]
    out = []
    for j in range(nz):
        for i in range(nx):
            if used[i][j]:
                continue
            k = grid[i][j]
            i1 = i
            while i1 < nx and not used[i1][j] and grid[i1][j] == k:
                i1 += 1
            j1 = j + 1
            while j1 < nz and all(not used[a][j1] and grid[a][j1] == k for a in range(i, i1)):
                j1 += 1
            for a in range(i, i1):
                for b in range(j, j1):
                    used[a][b] = True
            out.append((k, i, j, i1, j1))
    return out


def main():
    d = json.loads(LAYOUT.read_text())
    x0, x1 = d["base"]["x"]
    z0, z1 = d["base"]["z"]
    W, D = x1, z1
    nx = (x1 - x0) // CELL
    nz = (z1 + 8 - z0) // CELL  # (and under the back wall, as the old floor went)
    # an 8-stud cell is dirt if at least half its four 4-stud tiles are
    count = [[0] * nz for _ in range(nx)]
    for cx, cz in d["dirt_tiles_4stud"]:
        i, j = int((cx - x0) // CELL), int((cz - z0) // CELL)
        if 0 <= i < nx and 0 <= j < nz:
            count[i][j] += 1
    grid = [[1 if count[i][j] >= 2 else 0 for j in range(nz)] for i in range(nx)]
    floor = []
    for k, i0, j0, i1, j1 in rects(grid, nx, nz):
        lx, lz = x0 + i0 * CELL, z0 + j0 * CELL
        floor.append((k, lx, lz, (i1 - i0) * CELL, (j1 - j0) * CELL))
    c = d["base"]["corridor_half_width"]
    walls = [  # (name, which, centre, size), as tools/home_base.py LAYOUT
        ("Wall", "back", (0, 24, D + 4), (2 * W + 16, 48, 8)),
        ("Cap", "back", (0, 49, D + 3), (2 * W + 16, 2, 10)),
        ("Wall", "left", (-W - 4, 24, D / 2 - 4), (8, 48, D + 8)),
        ("Cap", "left", (-W - 3, 49, D / 2), (10, 2, D - 4)),
        ("Wall", "right", (W + 4, 24, D / 2 - 4), (8, 48, D + 8)),
        ("Cap", "right", (W + 3, 49, D / 2), (10, 2, D - 4)),
        ("Wall", "frontleft", (-(W + c) / 2, 24, -4), (W - c, 48, 8)),
        ("Cap", "frontleft", (-(W + c + 6) / 2, 49, -3), (W - c + 10, 2, 10)),
        ("Wall", "frontright", ((W + c) / 2, 24, -4), (W - c, 48, 8)),
        ("Cap", "frontright", ((W + c + 6) / 2, 49, -3), (W - c + 10, 2, 10)),
    ]
    centre = d["arc"]["centre"]

    def lua_list(rows):
        return "\n".join("\t{ " + ", ".join(rows_fmt(r)) + " }," for r in rows)

    def rows_fmt(r):
        return [f'"{v}"' if isinstance(v, str) else f"{v:g}" for v in r]

    walls_lua = "\n".join(
        f'\t{{ "{n}", "{w}", Vector3.new({p[0]:g}, {p[1]:g}, {p[2]:g}), Vector3.new({s[0]:g}, {s[1]:g}, {s[2]:g}) }},'
        for n, w, p, s in walls)
    props_lua = lua_list([(p["asset"], p["pos"][0], p["pos"][1], p["yaw"]) for p in d["props"]])
    bulls_lua = lua_list([(b["pen"], b["pos"][0], b["pos"][1]) for b in d["bulls"]] if BULL_PADS else [])
    floor_lua = lua_list(floor)
    text = TEMPLATE
    for key, value in {"W": W, "D": D, "CX": centre[0], "CZ": centre[1], "WALLS": walls_lua, "FLOOR": floor_lua,
                       "PROPS": props_lua, "BULLS": bulls_lua}.items():
        text = text.replace(f"@{key}@", f"{value:g}" if isinstance(value, (int, float)) else value)
    OUT.write_text(text)
    print(f"tools/arc_base.luau: {len(floor)} floor rectangles, {len(d['props'])} props, {len(d['bulls']) if BULL_PADS else 0} bull pads")


TEMPLATE = """-- The arc home base (QM, Oct 9; design/base_arc/SPEC.md). Made by tools/arc_base.py
-- from design/base_arc/arc_layout.json: edit those and re-make it, not this.
-- Run in Studio's command bar (Edit, not Play) on the place. Re-running is fine.

local W, D = @W@, @D@
local YARD = Vector3.new(@CX@, 0, @CZ@)
local world = workspace.World

-- The walls and caps: { name, which, centre, size }.
local WALLS = {
@WALLS@
}
-- The floor: { dirt (1) or grass (0), low x, low z, size x, size z }, on 8-stud cells.
local FLOOR = {
@FLOOR@
}
-- Meadow props: { model, x, z, yaw (degrees) }.
local PROPS = {
@PROPS@
}
-- Bull pads: { pen, x, z }.
local BULLS = {
@BULLS@
}

-- Walls: the home base's are the ones round z 0..the old depth; which is which by where they are.
local function which(p)
	local c = p.Position
	if c.Z > 20 and math.abs(c.X) < 40 then
		return "back"
	elseif c.Z > 20 and c.X < 0 then
		return "left"
	elseif c.Z > 20 then
		return "right"
	elseif c.Z > -10 and c.Z < 0 and math.abs(c.X) > 56 then
		return if c.X < 0 then "frontleft" else "frontright"
	end
	return nil
end
local moved = 0
for _, p in world.Walls:GetChildren() do
	if p:IsA("BasePart") and (p.Name == "Wall" or p.Name == "Cap") and p.Position.Z + p.Size.Z / 2 > -10 then
		local w = which(p)
		for _, spec in WALLS do
			if spec[1] == p.Name and spec[2] == w then
				p.Size, p.CFrame = spec[4], CFrame.new(spec[3])
				moved += 1
			end
		end
	end
end

-- The floor: the old single home Ground part (or a previous run's rectangles) goes.
local template
for _, p in world.Ground:GetChildren() do
	if p:IsA("BasePart") and (p:GetAttribute("ArcBase") or (p.Name == "Ground" and p.Position.Z > 0 and p.Size.X > 200)) then
		template = template or p:Clone()
		p:Destroy()
	end
end
assert(template, "no home Ground part to copy the look of")
for _, t in template:GetChildren() do
	if not t:IsA("Texture") then
		t:Destroy()
	end
end
template:SetAttribute("ArcBase", true)
for _, r in FLOOR do
	local dirt, x, z, sx, sz = r[1] == 1, r[2], r[3], r[4], r[5]
	local top = if dirt then -1 else 0
	local p = template:Clone()
	p.Name = if dirt then "Dirt" else "Ground"
	p.Size = Vector3.new(sx, top + 2, sz)
	p.CFrame = CFrame.new(x + sx / 2, (top - 2) / 2, z + sz / 2)
	-- (on 8-stud cells every corner starts on a whole checker square: no offsets, like the course)
	p.Parent = world.Ground
end

-- The floor's top under (x, z): 0 on grass, -1 on dirt.
local function topAt(x, z)
	for _, r in FLOOR do
		if r[1] == 1 and x >= r[2] and x < r[2] + r[4] and z >= r[3] and z < r[3] + r[5] then
			return -1
		end
	end
	return 0
end

-- Meadow props round the walls.
local decor = world:FindFirstChild("BaseDecor") or Instance.new("Folder")
decor.Name = "BaseDecor"
decor:ClearAllChildren()
local templates = {}
for _, o in world.Obstacles:GetChildren() do
	local cf = if o:IsA("Model") then o:GetPivot() elseif o:IsA("BasePart") then o.CFrame else nil
	if cf and cf.Z < 0 and cf.Z > -760 and not templates[o.Name] then
		templates[o.Name] = o
	end
end
local placed = 0
for _, r in PROPS do
	local from = templates[r[1]]
	if from then
		local copy = from:Clone()
		for _, name in { "FunnelPivot", "FunnelScale", "FunnelCF", "FunnelSize" } do
			copy:SetAttribute(name, nil)
		end
		-- standing on the floor as the original does: its invisible Base's top on the
		-- floor's (a turned model's bounding box reaches lower than its parts: Oct 9,
		-- standing that on the floor left them floating)
		local pivot = if copy:IsA("Model") then copy:GetPivot() else copy.CFrame
		local base = copy:FindFirstChild("Base")
		local up = if base and base:IsA("BasePart") then pivot.Y - (base.Position.Y + base.Size.Y / 2) else pivot.Y
		local cf = CFrame.new(r[2], topAt(r[2], r[3]) + up, r[3]) * CFrame.Angles(0, math.rad(r[4]), 0)
		if copy:IsA("Model") then
			copy:PivotTo(cf)
		else
			copy.CFrame = cf
		end
		copy.Parent = decor
		placed += 1
	end
end
decor.Parent = world

-- Bull pads (placeholders): a red mat 18 across, a post and a bull on it, facing the yard.
local pads = world:FindFirstChild("BullPads") or Instance.new("Folder")
pads.Name = "BullPads"
pads:ClearAllChildren()
local function block(parent, name, size, cf, color, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.Size, p.CFrame, p.Color = size, cf, color
	p.Parent = parent
	return p
end
if #BULLS == 0 then
	pads:Destroy() -- (none for now: BULL_PADS in tools/arc_base.py)
	pads = nil
end
for _, r in BULLS do
	local at = Vector3.new(r[2], topAt(r[2], r[3]), r[3])
	local face = CFrame.lookAt(at, Vector3.new(YARD.X, at.Y, YARD.Z))
	local m = Instance.new("Model")
	m.Name = "BullPad" .. r[1]
	m:SetAttribute("Pen", r[1])
	block(m, "Mat", Vector3.new(0.4, 18, 18), face * CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(210, 60, 60), Enum.PartType.Cylinder)
	block(m, "Post", Vector3.new(1, 4, 1), face * CFrame.new(0, 2.4, 0), Color3.fromRGB(90, 90, 100))
	block(m, "Bull", Vector3.new(3, 2.4, 5.5), face * CFrame.new(0, 5.6, 0), Color3.fromRGB(120, 72, 44))
	block(m, "Head", Vector3.new(2.2, 2, 2), face * CFrame.new(0, 6.2, -3.4), Color3.fromRGB(110, 64, 38))
	m.PrimaryPart = m.Mat
	m.Parent = pads
end
if pads then
	pads.Parent = world
end

return string.format("arc base: %d walls moved, %d floor parts, %d props, %d bull pads", moved, #FLOOR, placed, #BULLS)
"""

if __name__ == "__main__":
    main()
