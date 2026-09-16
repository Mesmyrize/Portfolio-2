--[[
	Group permission check.

	Conditions:
		"Group:<GroupIdOrAbbrev>"            -- in the group, any rank
		"Group:<GroupIdOrAbbrev>:<Min-Max>"  -- rank within a range (or just 1 rank if not specified range)

	Abbreviations are in ReplicatedStorage.Information.Groups

]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GroupIds = require(ReplicatedStorage.Information.Groups)

local function resolveGroupId(identifier)
	local numericId = tonumber(identifier)
	if numericId then
		return numericId
	end
	return GroupIds[identifier]
end

-- "50" -> (50, 50) meaning exactly rank 50; "2-255" -> (2, 255) meaning an inclusive range.
local function parseRankSpec(rankStr)
	local minStr, maxStr = rankStr:match("^(%d+)%-(%d+)$")
	if minStr then
		return tonumber(minStr), tonumber(maxStr)
	end

	local single = tonumber(rankStr)
	if single then
		return single, single
	end

	return nil, nil
end

-- rankCache[player][groupId] = rank, kept for the player's whole session.
local rankCache = {}

Players.PlayerRemoving:Connect(function(player)
	rankCache[player] = nil
end)

local function getRank(player, groupId)
	local playerCache = rankCache[player]
	if playerCache and playerCache[groupId] ~= nil then
		return playerCache[groupId]
	end

	local ok, rank = pcall(function()
		return player:GetRankInGroupAsync(groupId)
	end)

	if not ok then
		warn(("IsAuthorized/Group: GetRankInGroupAsync failed for %s: %s"):format(player.Name, tostring(rank)))
		return 0 -- fail closed; don't cache a failed lookup so it retries next time
	end

	playerCache = playerCache or {}
	playerCache[groupId] = rank
	rankCache[player] = playerCache

	return rank
end

return function(player, groupIdentifier, rankStr)
	local groupId = resolveGroupId(groupIdentifier)
	if not groupId then
		warn(("IsAuthorized/Group: unknown GroupId/abbreviation %q"):format(tostring(groupIdentifier)))
		return false
	end

	local rank = getRank(player, groupId)

	if rank == 0 then
		-- not in the group at all
		return false
	end

	if rankStr ~= nil then
		local minRank, maxRank = parseRankSpec(rankStr)
		if not minRank then
			warn(("IsAuthorized/Group: invalid rank spec %q"):format(tostring(rankStr)))
			return false
		end
		if rank < minRank then
			return false
		end
		if maxRank and rank > maxRank then
			return false
		end
		return true
	end

	return true
end