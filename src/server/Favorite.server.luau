-- "/favourite" (QM, Oct 13): Roblox's "add to favourites" prompt, any time (Favorite.client
-- shows it). A command on the server, as the chat only runs those.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local remote = Instance.new("RemoteEvent")
remote.Name = "PromptFavorite"
remote.Parent = ReplicatedStorage

local command = Instance.new("TextChatCommand")
command.Name = "Favourite"
command.PrimaryAlias = "/favourite"
command.SecondaryAlias = "/favorite"
command.Triggered:Connect(function(source)
	local player = Players:GetPlayerByUserId(source.UserId)
	if player then
		remote:FireClient(player)
	end
end)
command.Parent = game:GetService("TextChatService")
