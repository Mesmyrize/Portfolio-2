local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsAuthorized = require(ReplicatedStorage.Common.IsAuthorized)

local SeniorDeveloper = {
	{"Group:MAD:25", "Group:MAD:50-255"}, -- Senior Developer+
}

return function(Player)
	return IsAuthorized(Player, SeniorDeveloper)
end