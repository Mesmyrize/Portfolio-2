--[[
	User permission check.

	Condition: "User:<UserId>"
]]

return function(player, idStr)
	local id = tonumber(idStr)
	if not id then
		warn(("IsAuthorized/User: invalid UserId %q"):format(tostring(idStr)))
		return false
	end
	return player.UserId == id
end