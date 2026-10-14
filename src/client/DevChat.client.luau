-- Replies to the dev chat commands (/give ...: Hatchery.server), shown only to you
-- in the chat window.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

ReplicatedStorage:WaitForChild("DevChat").OnClientEvent:Connect(function(text)
	local channels = TextChatService:FindFirstChild("TextChannels")
	local system = channels and channels:FindFirstChild("RBXSystem")
	if system then
		system:DisplaySystemMessage(text)
	end
end)
