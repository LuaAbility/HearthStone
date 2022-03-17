local particle = import("$.Particle")
local material = import("$.Material")

function Init(abilityData)
	plugin.requireDataPack("HearthStone", "https://blog.kakaocdn.net/dn/sAeFO/btrrxXWPS5C/aODIDmfwRB3boWzAlG6Wo1/HearthStone.zip?attach=1&knm=tfile.zip")
	plugin.registerEvent(abilityData, "HS010-abilityUse", "PlayerInteractEvent", 200)
	plugin.registerEvent(abilityData, "HS010-removeDamage", "EntityDamageEvent", 0)
end

function onEvent(funcTable)
	if funcTable[1] == "HS010-abilityUse" then abilityUse(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
	if funcTable[1] == "HS010-removeDamage" then removeDamage(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
end

function onTimer(player, ability)
	if player:getVariable("HS010-health") == nil then 
		player:setVariable("HS010-health", player:getPlayer():getHealth()) 
		player:setVariable("HS010-healthStack", 0) 
		player:setVariable("HS010-cost", 0) 
		player:setVariable("HS010-requireCost", 10) 
		player:setVariable("HS010-abilityTime", 0)
	end
	
	local str = "§1[§b마나 수정§1] §b"
	local cost = player:getVariable("HS010-cost")
	for i = 1, 10 do
		if i <= cost then str = str .. "●"
		else str = str .. "○" end
	end
	game.sendActionBarMessage(player:getPlayer(), str)
	
	if cost < 10 then
		if player:getVariable("HS010-health") < player:getPlayer():getHealth() then player:setVariable("HS010-health", player:getPlayer():getHealth()) end
		local healthAmount = (player:getVariable("HS010-health") - player:getPlayer():getHealth()) + player:getVariable("HS010-healthStack")
		
		if healthAmount > 1 then
			addCost(player, ability)
		end
	end
	
	local timeCount = player:getVariable("HS010-abilityTime")
	if timeCount > 0 then
		timeCount = timeCount - 1
		if timeCount <= 0 then damage(player, ability) end
		player:setVariable("HS010-abilityTime", timeCount)
	end
end

function abilityUse(LAPlayer, event, ability, id)
	if event:getAction():toString() == "RIGHT_CLICK_AIR" or event:getAction():toString() == "RIGHT_CLICK_BLOCK" then
		if event:getItem() ~= nil then
			if game.isAbilityItem(event:getItem(), "IRON_INGOT") then
				if game.checkCooldown(LAPlayer, game.getPlayer(event:getPlayer()), ability, id, false) then
					if LAPlayer:getVariable("HS010-cost") >= LAPlayer:getVariable("HS010-requireCost") then
						LAPlayer:setVariable("HS010-cost", LAPlayer:getVariable("HS010-cost") - LAPlayer:getVariable("HS010-requireCost"))
						event:getPlayer():setVelocity(newInstance("$.util.Vector", {0, 3, 0}))
						event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs10.usebgm", 2, 1)
						event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs10.useline", 1, 1)
						event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs10.usesfx", 1.25, 1)
						event:getPlayer():getWorld():spawnParticle(particle.SMOKE_NORMAL, event:getPlayer():getLocation():add(0,1,0), 1500, 0.2, 0.5, 0.2, 0.75)
						LAPlayer:setVariable("HS010-abilityTime", 100)
						
						util.runLater(function()
							event:getPlayer():setVelocity(newInstance("$.util.Vector", {0, -5, 0}))
							event:getPlayer():getWorld():spawnParticle(particle.SMOKE_NORMAL, event:getPlayer():getLocation():add(0,1,0), 1500, 0.2, 0.5, 0.2, 0.75)
						end, 60)
					else
						game.sendMessage(event:getPlayer(), "§4[§c" .. ability.abilityName .. "§4] §c마나 수정이 부족합니다! (필요 마나 수정 : " .. LAPlayer:getVariable("HS010-requireCost") .. "개)")
					end
				end
			end
		end
	end
end

function removeDamage(LAPlayer, event, ability, id)
	if event:getCause():toString() == "FALL" and event:getEntity():getType():toString() == "PLAYER" then
		if game.checkCooldown(LAPlayer, game.getPlayer(event:getEntity()), ability, id) and LAPlayer:getVariable("HS010-abilityTime") > 0 then
			event:setCancelled(true)
			damage(LAPlayer, ability)
		end
	end
end

function damage(player, ability)
	player:getPlayer():getWorld():playSound(player:getPlayer():getLocation(), import("$.Sound").ENTITY_ENDER_DRAGON_GROWL, 0.5, 1.5)
	local loc = player:getPlayer():getLocation():clone()
	for i = 0, 30 do
		util.runLater(function()
			circleEffect(loc, (i + 1))
		end, i)
	end
	
	local players = util.getTableFromList(game.getPlayers())
	for i = 1, #players do
		if player:getPlayer() ~= players[i]:getPlayer() and game.targetPlayer(player, players[i], false) and
			player:getPlayer():getWorld():getEnvironment() == players[i]:getPlayer():getPlayer():getWorld():getEnvironment() and 
			(player:getPlayer():getLocation():distance(players[i]:getPlayer():getLocation()) <= 30) then
			util.runLater(function()
				players[i]:getPlayer():damage(25, player:getPlayer())
				players[i]:getPlayer():getWorld():playSound(players[i]:getPlayer():getLocation(), import("$.Sound").ENTITY_ZOMBIE_BREAK_WOODEN_DOOR, 0.5, 0.6)
				players[i]:getPlayer():getWorld():spawnParticle(particle.SMOKE_NORMAL, players[i]:getPlayer():getLocation():add(0,1,0), 100, 0.2, 0.5, 0.2, 0.2)
				players[i]:getPlayer():getWorld():createExplosion(players[i]:getPlayer():getLocation(), 1)
			end, math.floor(player:getPlayer():getLocation():distance(players[i]:getPlayer():getLocation()) + 0.5))
		end
	end
	
	player:setVariable("HS010-abilityTime", 0)
	player:getPlayer():getInventory():clear()
	util.runLater(function() game.removeAbilityAsID(player, ability.abilityID) end, 2)
end

function circleEffect(loc, radius)
    local location = loc:clone()
	
    for i = 0, 90 do
        local angle = 2 * math.pi * i / 90
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius
        location:add(x, 0, z)
		location:getWorld():spawnParticle(particle.FLAME, location:getWorld():getHighestBlockAt(location):getLocation():add(0,1,0), 1, 0, 0, 0, 0.05)
		location:getWorld():spawnParticle(particle.LAVA, location:getWorld():getHighestBlockAt(location):getLocation():add(0,1,0), 1, 0, 0, 0, 0.05)
		location:getWorld():spawnParticle(particle.SMOKE_NORMAL, location:getWorld():getHighestBlockAt(location):getLocation():add(0,1,0), 1, 0, 0, 0, 0.05)
		location:getWorld():spawnParticle(particle.EXPLOSION_LARGE, location:getWorld():getHighestBlockAt(location):getLocation():add(0,1,0), 1, 0, 0, 0, 0.05)
        location:subtract(x, 0, z)
    end
end

function addCost(player, ability)
	local prevCost = player:getVariable("HS010-cost")
	local cost = prevCost
	
	if cost < 10 then
		local healthAmount = (player:getVariable("HS010-health") - player:getPlayer():getHealth()) + player:getVariable("HS010-healthStack")
		while cost <= 10 do
			if cost <= 6 then
				if (healthAmount - 2 >= 0) then
					cost = cost + 1
					healthAmount = healthAmount - 2
				else break end
			else
				if (healthAmount - 4 >= 0) then
					cost = cost + 1
					healthAmount = healthAmount - 4
				else break end
			end
		end
		
		if cost < 10 then player:setVariable("HS010-healthStack", healthAmount)
		else player:setVariable("HS010-healthStack", 0) end
		if (prevCost < cost) then
			player:setVariable("HS010-health", player:getPlayer():getHealth())
			player:setVariable("HS010-cost", cost)
			
			game.sendMessage(player:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b마나 수정이 생성되었습니다! (현재 마나 수정 : " .. cost .. "개)")
			player:getPlayer():playSound(player:getPlayer():getLocation(), import("$.Sound").ENTITY_EXPERIENCE_ORB_PICKUP, 0.5, 2)
			player:getPlayer():spawnParticle(particle.ITEM_CRACK, player:getPlayer():getLocation():add(0,1,0), 50, 0.2, 0.5, 0.2, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").DIAMOND_BLOCK}))
		end
	end
end