-- The outline on whatever the lasso would catch (an animal or the egg): a thin
-- white line hugging the target, drawn by a Highlight.
--
--   Outline.set(model) -- outline this model; nil clears it

local highlight = Instance.new("Highlight")
highlight.FillTransparency = 1
highlight.OutlineColor = Color3.new(1, 1, 1)
highlight.OutlineTransparency = 0
highlight.DepthMode = Enum.HighlightDepthMode.Occluded
highlight.Enabled = false
highlight.Parent = workspace

local target

local Outline = {}

function Outline.set(model)
	if model == target then
		return
	end
	target = model
	highlight.Adornee = model
	highlight.Enabled = model ~= nil
end

return Outline
