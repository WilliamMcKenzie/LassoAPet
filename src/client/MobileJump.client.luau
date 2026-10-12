-- On a phone, Roblox's jump button sits in the bottom right corner, under the base's
-- button column (BaseUi's Merge, Index, Shop, Invite): QM, Oct 12. This keeps it just
-- left of that column while the column's up, and puts it back where Roblox had it when
-- it's not (riding, menus). Roblox rebuilds TouchGui on respawn, so it's found anew
-- each frame.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

if not UserInputService.TouchEnabled then
	return
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GAP = 12 -- pixels between the jump button and the column

local home = setmetatable({}, { __mode = "k" }) -- [JumpButton] = the Position Roblox gave it

RunService.RenderStepped:Connect(function()
	local touch = playerGui:FindFirstChild("TouchGui")
	local jump = touch and touch:FindFirstChild("JumpButton", true)
	if not jump then
		return
	end
	home[jump] = home[jump] or jump.Position
	local base = playerGui:FindFirstChild("BaseUi")
	local menu = base and base.Enabled and base:FindFirstChild("Menu", true)
	local covered = false
	if menu and menu.Visible and menu.AbsoluteSize.X > 0 then
		-- (covered: the jump button's box and the column's overlap)
		local a0, a1 = jump.AbsolutePosition, jump.AbsolutePosition + jump.AbsoluteSize
		local b0, b1 = menu.AbsolutePosition, menu.AbsolutePosition + menu.AbsoluteSize
		local moved = jump.Position ~= home[jump]
		covered = moved or (a0.X < b1.X and b0.X < a1.X and a0.Y < b1.Y and b0.Y < a1.Y)
		if covered then
			local frame = jump.Parent
			local left = menu.AbsolutePosition.X - GAP - jump.AbsoluteSize.X - frame.AbsolutePosition.X
			local want = UDim2.new(0, left, home[jump].Y.Scale, home[jump].Y.Offset)
			if jump.Position ~= want then
				jump.Position = want
			end
		end
	end
	if not covered and jump.Position ~= home[jump] then
		jump.Position = home[jump]
	end
end)
