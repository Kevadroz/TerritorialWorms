dofile_once("data/scripts/lib/utilities.lua")

local player_count = 0
local singular_player
for _, player in ipairs(EntityGetWithTag("player_unit")) do
	if EntityGetIsAlive(player) and GameGetGameEffectCount(player, "WORM_DETRACTOR") <= 0 then
		player_count = player_count + 1
		singular_player = player
	end
end

if player_count < 1 then
	return
end

local worm = GetUpdatedEntityID()
local components = EntityGetComponent(worm, "WormAIComponent")
if components then
	if player_count == 1 then
		for _, comp_id in ipairs(components) do
			if ComponentGetValue2(comp_id, "mTargetEntityId") ~= singular_player then
				ComponentSetValue2(comp_id, "mTargetEntityId", singular_player)
			end
		end
	else
		local x, y = EntityGetTransform(worm)
		local players = EntityGetWithTag("player_unit")
		local distances = {}
		for _, player in ipairs(players) do
			local px, py = EntityGetTransform(player)
			px, py = vec_sub(px, py, x, y)
			table.insert(distances, { vec_length(px, py), player })
		end
		local closest_player
		local closest_distance = -1
		for _, dist in ipairs(distances) do
			if closest_distance == -1 or dist[1] < closest_distance then
				closest_player = dist[2]
				closest_distance = dist[1]
			end
		end
		for _, comp_id in ipairs(components) do
			if ComponentGetValue2(comp_id, "mTargetEntityId") ~= closest_player then
				ComponentSetValue2(comp_id, "mTargetEntityId", closest_player)
			end
		end
	end
end
