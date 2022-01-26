local particle = import("$.Particle")
local material = import("$.Material")

function Init(abilityData)
	plugin.requireDataPack("HearthStone", "https://blog.kakaocdn.net/dn/sAeFO/btrrxXWPS5C/aODIDmfwRB3boWzAlG6Wo1/HearthStone.zip?attach=1&knm=tfile.zip")
	plugin.registerEvent(abilityData, "HS020-abilityUse", "EntityDamageEvent", 0)
end

function onEvent(funcTable)
	if funcTable[1] == "HS020-abilityUse" then abilityUse(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
end

function abilityUse(LAPlayer, event, ability, id)
	if event:getEntity():getType():toString() == "PLAYER" and util.random() <= 0.4 then
		if game.checkCooldown(LAPlayer, game.getPlayer(event:getEntity()), ability, id) then
			local players = util.getTableFromList(game.getPlayers())
			local randomIndex = util.random(1, #players)
			while players[randomIndex]:getPlayer() == event:getEntity() do randomIndex = util.random(1, #players) end
			
			local loc = event:getEntity():getLocation():clone()
			loc:setPitch(0)
			loc:setYaw(0)
			players[randomIndex]:getPlayer():teleport(loc)
			event:getEntity():getWorld():playSound(event:getEntity():getLocation(), "hs20.useline", 1, 1)
		end
	end
end