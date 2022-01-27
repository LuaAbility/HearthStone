local particle = import("$.Particle")
local material = import("$.Material")
local effect = import("$.potion.PotionEffectType")

function Init(abilityData)
	plugin.requireDataPack("HearthStone", "https://blog.kakaocdn.net/dn/sAeFO/btrrxXWPS5C/aODIDmfwRB3boWzAlG6Wo1/HearthStone.zip?attach=1&knm=tfile.zip")
	plugin.registerEvent(abilityData, "HS014-abilityUse", "AbilityConfirmEvent", 200)
	plugin.registerEvent(abilityData, "HS014-cancelAttack", "EntityDamageEvent", 0)
end

function onEvent(funcTable)
	if funcTable[1] == "HS014-abilityUse" then abilityUse(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
	if funcTable[1] == "HS014-cancelAttack" and funcTable[2]:getEventName() == "EntityDamageByEntityEvent" then cancelAttack(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
end

function onTimer(player, ability)
	if player:getVariable("HS014-currentCandle") == nil then 
		local candleCount = #util.getTableFromList(game.getPlayers())
		player:setVariable("HS014-currentCandle", 1)
	end
	
	local candle = player:getVariable("HS014-currentCandle")
	if candle == 0 then
		player:getPlayer():addPotionEffect(newInstance("$.potion.PotionEffect", {effect.INCREASE_DAMAGE, 10, 1}))
		player:getPlayer():addPotionEffect(newInstance("$.potion.PotionEffect", {effect.DAMAGE_RESISTANCE, 10, 1}))
		player:getPlayer():getWorld():spawnParticle(particle.SMOKE_NORMAL, player:getPlayer():getLocation():add(0,1,0), 10, 0.3, 0.7, 0.3, 0.05)
	else 
		game.sendActionBarMessage(player:getPlayer(), "§6[§e남은 양초§6] : §e" .. candle .. "개")
	end
end

function abilityUse(LAPlayer, event, ability, id)
	local abilityUser = event:getPlayer():getPlayer()
	if LAPlayer:getPlayer() ~= abilityUser and util.random() <= 1 then
		local candle = LAPlayer:getVariable("HS014-currentCandle")
		if candle ~= nil and candle > 0 then
			if game.checkCooldown(LAPlayer, LAPlayer, ability, id, false, false) then
				candle = candle - 1
				
				LAPlayer:getPlayer():getWorld():spawnParticle(particle.SMOKE_NORMAL, LAPlayer:getPlayer():getLocation():add(0,1,0), 200, 0.3, 0.7, 0.3, 0.05)
				LAPlayer:getPlayer():getWorld():playSound(LAPlayer:getPlayer():getLocation(), "hs14.triggerline", 0.5, 1)
				LAPlayer:getPlayer():getWorld():playSound(LAPlayer:getPlayer():getLocation(), import("$.Sound").BLOCK_FIRE_EXTINGUISH, 1.5, 0.7)
				game.sendMessage(LAPlayer:getPlayer(), "§7양초가 꺼졌습니다. (남은 양초 : " .. candle .. "개)")
				
				abilityUser:getWorld():playSound(abilityUser:getLocation(), "hs14.triggerline", 0.5, 1)
				abilityUser:getWorld():playSound(abilityUser:getLocation(), import("$.Sound").BLOCK_FIRE_EXTINGUISH, 1.5, 0.7)
				game.sendMessage(abilityUser, "§7당신의 능력 발동으로 인해 §8양초 1개§7가 꺼졌습니다.")
				
				util.runLater(function() 
					if candle <= 0 then revive(LAPlayer:getPlayer()) end
					LAPlayer:setVariable("HS014-currentCandle", candle)
				end, 60)
			end
		end
	end
end

function revive(player)
	game.broadcastMessage("§8어둠의 존재§7가 깨어납니다.")
	local players = util.getTableFromList(game.getPlayers())
	for i = 1, #players do
		players[i]:getPlayer():playSound(players[i]:getPlayer():getLocation(), "hs14.useline", 1, 1)
		players[i]:getPlayer():playSound(players[i]:getPlayer():getLocation(), "hs14.usebgm", 0.5, 1)
	end
	
	for i = 1, 35 do
		util.runLater(function()
			player:getWorld():spawnParticle(particle.SMOKE_NORMAL, player:getLocation():add(0,1,0), 50, 0.3, 0.7, 0.3, 0.05)
		end, i)
	end
	
	for i = 0, 20 do
		util.runLater(function()
			circleEffect(player:getLocation():add(0,1,0), ((i * 0.5) + 1))
		end, i + 40) 
	end
end

function cancelAttack(LAPlayer, event, ability, id)
	local damager = event:getDamager()
	if event:getCause():toString() == "PROJECTILE" then damager = event:getDamager():getShooter() end
	
	if damager:getType():toString() == "PLAYER" then
		if game.checkCooldown(LAPlayer, game.getPlayer(damager), ability, id, false, false) then
			if LAPlayer:getVariable("HS014-currentCandle") > 0 then
				event:setCancelled(true)
			end
		end
	end
end

function circleEffect(loc, radius)
    local location = loc:clone()
    for i = 0, 90 do
        local angle = 2 * math.pi * i / 90
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius
        location:add(x, 0, z)
		location:getWorld():spawnParticle(particle.SMOKE_LARGE, location, 5, 0.5, 0, 0.5, 0.1)
		location:getWorld():spawnParticle(particle.REDSTONE, location, 10, 0.5, 0, 0.5, 0.9, newInstance("$.Particle$DustOptions", { import("$.Color").BLACK, 1.5 }))
        location:subtract(x, 0, z)
    end
end