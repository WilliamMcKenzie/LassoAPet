-- The 100x Luck Event's sign (Config.LuckEvent, QM Nov 7): built fresh over the course's mouth
-- (Shared/LuckEventSign; it's also placed in Edit mode so it shows in Studio). The event itself
-- is only the clock (Config.luckEventLeft): Config.luck multiplies everyone's luck while it's on.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.Shared.LuckEventSign).build()
