-- Every one of the game's screens covers the whole screen, edge to edge (QM, Oct 4: on
-- phones the HUD's buttons sat well in from the sides). A ScreenGui with IgnoreGuiInset
-- set keeps the device's safe-area insets (round a phone's notch and home bar), which
-- pushed everything in on phones; this takes them off, so the buttons sit their margin
-- from the real edges. Roblox's own screens (the touch controls, chat) are left alone.

local Players = game:GetService("Players")

local ROBLOX = { TouchGui = true, Chat = true, BubbleChat = true, Freecam = true }

local function edgeToEdge(screen)
	if screen:IsA("ScreenGui") and not ROBLOX[screen.Name] then
		screen.ScreenInsets = Enum.ScreenInsets.None
		screen.SafeAreaCompatibility = Enum.SafeAreaCompatibility.None
	end
end

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
for _, screen in playerGui:GetChildren() do
	edgeToEdge(screen)
end
playerGui.ChildAdded:Connect(edgeToEdge)
