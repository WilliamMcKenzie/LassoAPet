-- The chat window starts closed (QM, Oct 18): Roblox opens it on joining, over the quest
-- bar top left with its "automatically translates" notice, which isn't the game. Chat
-- stays on (the dev commands, the bubble button up top): only its window is shut, and
-- a player who opens it after that keeps it open.
--
-- SetCore("ChatActive") errors till the chat has loaded and Roblox may open the window
-- again a moment later, so it's shut on a short loop: on until it's been seen closed
-- for CLOSED_FOR seconds, or SETTLE seconds after joining at most.
local StarterGui = game:GetService("StarterGui")

local SETTLE = 15 -- seconds after joining it keeps at it, at most
local CLOSED_FOR = 3 -- seconds it stays closed before this stops (the player's own after that)

task.spawn(function()
	local started = os.clock()
	local closedAt = nil
	while os.clock() - started < SETTLE do
		local ok, active = pcall(StarterGui.GetCore, StarterGui, "ChatActive")
		if ok and active then
			pcall(StarterGui.SetCore, StarterGui, "ChatActive", false)
			closedAt = nil
		elseif ok then
			closedAt = closedAt or os.clock()
			if os.clock() - closedAt >= CLOSED_FOR then
				return
			end
		end
		task.wait(0.25)
	end
end)
