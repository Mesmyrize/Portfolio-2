local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsAuthorized = require(ReplicatedStorage.Common.IsAuthorized)

local Directorate = {
	{"Group:SCPF:250-255"},
}

return function(Player)
	return IsAuthorized(Player, Directorate)
end