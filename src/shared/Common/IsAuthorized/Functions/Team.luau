--[[
	Team permission check.

	Condition: "Team:<Name>"

	Matches Player.Team.Name directly, or abbreviations in ReplicatedStorage.Information.Teams
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TeamAbbreviations = require(ReplicatedStorage.Information.Teams)

return function(player, name)
	local team = player.Team
	if not team then
		return false
	end
	if team.Name == name then
		return true
	end
	return TeamAbbreviations[team.Name] == name
end