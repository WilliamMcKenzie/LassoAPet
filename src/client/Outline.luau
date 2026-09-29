-- The outline on whatever the lasso would catch (an animal or the egg).
--
--   Outline.set(model) -- outline this model; nil clears it
--   Outline.update()   -- every frame, after the target has moved
--
-- Config.LayeredOutline picks the style. Layered: a thin white line hugging the
-- target with a line twice as thick in black around it. Roblox draws every
-- Highlight line at one fixed width, so the black is made of two more Highlights,
-- each on an invisible shell: a copy of each of the target's blocks, puffed out
-- by one and two Config.OutlineWidth steps and kept on the blocks as they
-- animate. Set OutlineWidth to about one line's width so the three lines touch.
-- Off: the old thin yellow line.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local layered = Config.LayeredOutline

local function newHighlight(color)
	local h = Instance.new("Highlight")
	h.FillTransparency = 1
	h.OutlineColor = color
	h.OutlineTransparency = 0
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Enabled = false
	h.Parent = workspace
	return h
end

local inner = newHighlight(if layered then Color3.new(1, 1, 1) else Color3.fromRGB(255, 230, 120))

local shells = {} -- { model, highlight, steps }, outermost last
if layered then
	for steps = 1, 2 do
		local model = Instance.new("Model")
		model.Name = "OutlineShell"
		model.Parent = workspace
		local h = newHighlight(Color3.new(0, 0, 0))
		h.Adornee = model
		table.insert(shells, { model = model, highlight = h, steps = steps })
	end
end

local target
local blocks = {} -- { part = the target's block, copy = its puffed-out copy, steps = puff }

local Outline = {}

function Outline.set(model)
	if model == target then
		return
	end
	target = model
	inner.Adornee = model
	inner.Enabled = model ~= nil
	table.clear(blocks)
	for _, shell in shells do
		shell.model:ClearAllChildren()
		shell.highlight.Enabled = model ~= nil
	end
	if not model then
		return
	end
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") or part.Transparency >= 1 then
			continue
		end
		for _, shell in shells do
			local copy = part:Clone()
			copy:ClearAllChildren() -- no stud textures or joints
			copy.Anchored = true
			copy.CanCollide = false
			copy.CanQuery = false
			copy.CanTouch = false
			copy.CastShadow = false
			copy.Material = Enum.Material.SmoothPlastic
			copy.Transparency = 0.99 -- invisible, but still drawn, so the Highlight can outline it
			copy.Parent = shell.model
			table.insert(blocks, { part = part, copy = copy, steps = shell.steps })
		end
	end
	Outline.update()
end

function Outline.update()
	if not target then
		return
	end
	for _, b in blocks do
		b.copy.Size = b.part.Size + Vector3.one * (2 * Config.OutlineWidth * b.steps)
		b.copy.CFrame = b.part.CFrame
	end
end

return Outline
