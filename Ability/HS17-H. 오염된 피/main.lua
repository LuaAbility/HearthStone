local particle = import("$.Particle")
local material = import("$.Material")

function Init(abilityData)
	plugin.requireDataPack("HearthStone", "https://blog.kakaocdn.net/dn/sAeFO/btrrxXWPS5C/aODIDmfwRB3boWzAlG6Wo1/HearthStone.zip?attach=1&knm=tfile.zip")
	plugin.registerEvent(abilityData, "HS017-abilityUse", "EntityDamageEvent", 0)
end

function onEvent(funcTable)
	if funcTable[1] == "HS017-abilityUse" and funcTable[2]:getEventName() == "EntityDamageByEntityEvent" then abilityUse(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
end

function onTimer(player, ability)
	if player:getVariable("HS017-blood") == nil then 
		player:setVariable("HS017-blood", 0) 
	end
	
	local count = player:getVariable("HS017-blood")
	if count >= 100 then 
		count = 0
		damage(player:getPlayer())
	end
	count = count + 2
	player:setVariable("HS017-blood", count)
end

function abilityUse(LAPlayer, event, ability, id)
	if event:getDamager():getType():toString() == "PLAYER" and event:getEntity():getType():toString() == "PLAYER" and util.random() <= 0.2 then
		if game.checkCooldown(LAPlayer, game.getPlayer(event:getDamager()), ability, id) then
			event:getEntity():getWorld():playSound(event:getDamager():getLocation(), "hs17.hitsfx", 1, 1)
			util.runLater(function() game.addAbility(game.getPlayer(event:getEntity()), "LA-HS-017-HIDDEN") end, 5)
			game.sendMessage(event:getEntity(), "§4오염된 피§c에 감염되었습니다.")
		end
	end
end

function damage(player)
	player:getWorld():playSound(player:getLocation(), "hs17.hitsfx", 1, 1)
	util.runLater(function() player:damage(2) end, 5)
end