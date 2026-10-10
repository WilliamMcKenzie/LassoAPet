-- The lasso's prompt (QM, Oct 10: no buttons while riding): a prompt on the animal you'd
-- lasso, drawn by PromptUi like the others: its name in its rarity's colour, "Lasso"
-- and the E key. A tap of E (no hold: QM, Oct 10), or of the prompt on a phone, lassos.
--
--   LassoPrompt.update(model, name, color) -- the target's model (nil: none)
--   LassoPrompt.onTap = fn                 -- the prompt triggered (E, tapped, gamepad A)

local LassoPrompt = {}

local attachment = Instance.new("Attachment")
attachment.Name = "LassoPrompt"
local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Lasso"
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.GamepadKeyCode = Enum.KeyCode.ButtonA
prompt.HoldDuration = 0
prompt.RequiresLineOfSight = false
prompt.MaxActivationDistance = 10000 -- (Ride says what's in range)
prompt.Style = Enum.ProximityPromptStyle.Custom -- (PromptUi)
prompt.Parent = attachment
prompt.Triggered:Connect(function()
	-- (the prompt takes E from Ride's own key handling while it's up; a second lasso
	-- the same frame does nothing, as one's already flying)
	if LassoPrompt.onTap then
		LassoPrompt.onTap()
	end
end)

local shownOn
function LassoPrompt.update(model, name, color)
	local part = model and model.PrimaryPart
	if not part then
		attachment.Parent = nil
		shownOn = nil
		return
	end
	if shownOn ~= model then
		shownOn = model
		local _, size = model:GetBoundingBox()
		attachment.Parent = part
		attachment.WorldPosition = part.Position + Vector3.new(0, size.Y / 2, 0)
		prompt:SetAttribute("ObjectColor", color)
		prompt.ObjectText = name or ""
	end
end

return LassoPrompt
