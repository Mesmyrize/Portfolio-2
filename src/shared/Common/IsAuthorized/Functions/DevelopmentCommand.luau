local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsAuthorized = require(ReplicatedStorage.Common.IsAuthorized)

local DevelopmentCommand = {
	{"Group:MAD:50-255"}, -- Development Coordinator+
}

return function(Player)
	return IsAuthorized(Player, DevelopmentCommand)
end