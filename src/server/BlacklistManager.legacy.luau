local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")

local BlacklistedGroups = require(game.ReplicatedStorage.Information.BlacklistedGroups)

Players.PlayerAdded:Connect(function(player)
	local blacklisted = {}

	for _, groupId in pairs(BlacklistedGroups) do
		if player:IsInGroupAsync(groupId) then
			local Groups = GroupService:GetGroupsAsync(groupId)
			table.insert(blacklisted, Groups.Name)
		end
	end

	if #blacklisted > 0 then
		local reason = "You are a member of blacklisted group(s): "
			.. table.concat(blacklisted, ", ")
			.. ". Contact Community Safety to appeal."

		local success, err = pcall(function()
			Players:BanAsync({
				UserIds = {player.UserId},
				Duration = -1,
				DisplayReason = reason,
				PrivateReason = "Blacklisted group membership: " .. table.concat(blacklisted, ", "),
				ExcludeAltAccounts = false,
				ApplyToUniverse = true,
			})
		end)

		if success then
			print(player.Name .. " was successfully banned.")
		else
			warn("Ban failed for " .. player.Name .. ": " .. tostring(err))

			-- Failsafe in case ban fails for whatever reason
			player:Kick(reason)
		end
	end
end)