local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsAuthorized = require(ReplicatedStorage.Common.IsAuthorized)

local Developer = {
	{"Group:MAD:15-255"}, -- Junior Developer+
}

return function(Player)
	return IsAuthorized(Player, Developer)
end