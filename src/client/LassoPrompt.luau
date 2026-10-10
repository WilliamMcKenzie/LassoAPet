-- The lasso's prompt (QM, Oct 10: no buttons while riding): a prompt on the animal you'd
-- lasso, drawn by PromptUi like the others: its name in its rarity's colour, "Lasso"
-- and the E key. E (Ride's own key) lassos; on a phone, tapping the prompt does.
--
--   LassoPrompt.update(model, name, color) -- the target's model (nil: none)
--   LassoPrompt.onTap = fn                 -- the prompt tapped on a touch screen

local UserInputService = game:GetService("UserInputService")

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
	-- (E and the gamepad's A already lasso in Ride: only a tap goes through here)
	if UserInputService:GetLastInputType() == Enum.UserInputType.Touch and LassoPrompt.onTap then
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
