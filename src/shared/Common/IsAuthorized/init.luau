--[[

	Usage:
		local IsAuthorized = require(path.to.IsAuthorized)
		if IsAuthorized(Player, PermissionData) then
			-- allowed
		end

	Permission format:
		{
			{ "Team:SC" },                                      -- rule 1
			{ "Group:SC:2-255", "User:859791892" },             -- rule 2: EITHER condition (default OR)
			{ "Group:SVSD", "Group:AA", requireAll = true },    -- rule 3: BOTH conditions (AND)
			{ "!Team:GOC" },                                    -- rule 4: passes if NOT provided condition
		}

]]

local IsAuthorized = {}

local FunctionsFolder = script.Functions

-- Cache resolved (and failed) lookups
local functionCache = {}

local function getPermissionFunction(kind)
	if functionCache[kind] ~= nil then
		local cached = functionCache[kind]
		return cached ~= false and cached or nil
	end

	local moduleScript = FunctionsFolder:FindFirstChild(kind)
	if not moduleScript then
		functionCache[kind] = false
		return nil
	end

	local ok, fn = pcall(require, moduleScript)
	if not ok or type(fn) ~= "function" then
		warn(("IsAuthorized: PermissionFunctions.%s did not return a function"):format(kind))
		functionCache[kind] = false
		return nil
	end

	functionCache[kind] = fn
	return fn
end

local function warnBadCondition(condition, reason)
	warn(("IsAuthorized: bad condition %q (%s)"):format(tostring(condition), reason))
end

-- evaluate a single condition string against a player, with "!" negating it if it passes
local function evaluateCondition(player, condition)
	if type(condition) ~= "string" then
		warnBadCondition(condition, "not a string")
		return false
	end

	local negate = false
	if condition:sub(1, 1) == "!" then
		negate = true
		condition = condition:sub(2)
	end

	if condition == "" then
		warnBadCondition(condition, "empty condition after '!'")
		return false
	end

	local parts = string.split(condition, ":")
	local kind = parts[1]

	local fn = getPermissionFunction(kind)
	if not fn then
		warnBadCondition(condition, "unknown condition type " .. tostring(kind))
		return false
	end

	local ok, result = pcall(fn, player, table.unpack(parts, 2))
	if not ok then
		warn(("IsAuthorized: PermissionFunctions.%s errored: %s"):format(kind, tostring(result)))
		return false
	end

	local passed = result == true
	if negate then
		return not passed
	end
	return passed
end

-- RequireAll; if true, all conditions in a rule must pass
local function getRequireAll(rule)
	for key, value in pairs(rule) do
		if type(key) == "string" and key:lower() == "requireall" then
			return value == true
		end
	end
	return false
end

local function evaluateRule(player, rule)
	if type(rule) ~= "table" then
		return false
	end

	local requireAll = getRequireAll(rule)
	local anyChecked = false

	if requireAll then
		for _, condition in ipairs(rule) do
			anyChecked = true
			if not evaluateCondition(player, condition) then
				return false
			end
		end
	else
		for _, condition in ipairs(rule) do
			anyChecked = true
			if evaluateCondition(player, condition) then
				return true
			end
		end
	end

	if not anyChecked then
		return false
	end

	return requireAll
end

-- Returns true if player matches at least one rule in permissions, or if "All" is used

function IsAuthorized.Check(player, permissionData)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		warn("[IsAuthorized] Expected a Player instance")
		return false
	end

	if permissionData == "All" then
		return true
	end

	if type(permissionData) ~= "table" or #permissionData == 0 then
		return false
	end

	for _, rule in ipairs(permissionData) do
		if evaluateRule(player, rule) then
			return true
		end
	end

	return false
end

-- allow calling the module directly (see usage at top)
return setmetatable(IsAuthorized, {
	__call = function(_, player, permissionData)
		return IsAuthorized.Check(player, permissionData)
	end,
})