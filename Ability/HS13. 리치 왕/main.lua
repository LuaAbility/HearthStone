local particle = import("$.Particle")
local material = import("$.Material")
local attribute = import("$.attribute.Attribute")
local types = import("$.entity.EntityType")
local effects = import("$.potion.PotionEffectType")

function Init(abilityData)
	plugin.requireDataPack("HearthStone", "https://blog.kakaocdn.net/dn/sAeFO/btrrxXWPS5C/aODIDmfwRB3boWzAlG6Wo1/HearthStone.zip?attach=1&knm=tfile.zip")
	plugin.registerEvent(abilityData, "HS013-abilityUse", "PlayerInteractEvent", 600)
	plugin.registerEvent(abilityData, "HS013-cancelTarget", "EntityTargetEvent", 0)
	plugin.registerEvent(abilityData, "HS013-addStray", "PlayerDeathEvent", 0)
	plugin.registerEvent(abilityData, "HS013-fireOff", "EntityCombustEvent", 0)
end

function onEvent(funcTable)
	if funcTable[1] == "HS013-abilityUse" then abilityUse(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
	if funcTable[1] == "HS013-cancelTarget" and funcTable[2]:getEventName() == "EntityTargetLivingEntityEvent" then cancelTarget(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
	if funcTable[1] == "HS013-addStray" then addStray(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
	if funcTable[1] == "HS013-fireOff" then fireOff(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
end

function onTimer(player, ability)
	if player:getVariable("HS013-health") == nil then 
		player:setVariable("HS013-health", player:getPlayer():getHealth()) 
		player:setVariable("HS013-healthStack", 0) 
		player:setVariable("HS013-cost", 0) 
		player:setVariable("HS013-requireCost", 4) 
		player:setVariable("HS013-summonCount", 3) 
	end
	
	local str = "§1[§b마나 수정§1] §b"
	local cost = player:getVariable("HS013-cost")
	for i = 1, 10 do
		if i <= cost then str = str .. "●"
		else str = str .. "○" end
	end
	game.sendActionBarMessage(player:getPlayer(), "HS013", str)
	
	if cost < 10 then
		if player:getVariable("HS013-health") < player:getPlayer():getHealth() then player:setVariable("HS013-health", player:getPlayer():getHealth()) end
		local healthAmount = (player:getVariable("HS013-health") - player:getPlayer():getHealth()) + player:getVariable("HS013-healthStack")
		
		if healthAmount > 1 then
			addCost(player, ability)
		end
	end
end

function Reset(player, ability)
	game.sendActionBarMessageToAll("HS013", "")
end

function abilityUse(LAPlayer, event, ability, id)
	if event:getAction():toString() == "RIGHT_CLICK_AIR" or event:getAction():toString() == "RIGHT_CLICK_BLOCK" then
		if event:getItem() ~= nil then
			if game.isAbilityItem(event:getItem(), "IRON_INGOT") then
				if game.checkCooldown(LAPlayer, game.getPlayer(event:getPlayer()), ability, id, false) then
					if LAPlayer:getVariable("HS013-cost") >= LAPlayer:getVariable("HS013-requireCost") then
						LAPlayer:setVariable("HS013-cost", LAPlayer:getVariable("HS013-cost") - LAPlayer:getVariable("HS013-requireCost"))
						game.sendMessage(event:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b능력을 사용했습니다.")
						local count = LAPlayer:getVariable("HS013-summonCount")
						
						event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs13.useline", 1, 1)
						event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs13.usebgm", 1, 1)
						effect(event:getPlayer())
						for i = 1, 60 do
							util.runLater(function()
								event:getPlayer():getWorld():spawnParticle(import("$.Particle").SPIT, event:getPlayer():getLocation():add(0,1,0), 10, 0.5, 1, 0.5, 0.5)
								if i == 60 then event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs13.usesfx", 1, 1) end
							end, i)
						end
						
						util.runLater(function()
							for i = 0, 40 do
								util.runLater(function()
									circleEffect(event:getPlayer():getLocation():add(0,1,0), ((i * 0.5) + 1))
								end, math.floor(((i / 4) + 10) + 0.5))
							end
							
							for i = 1, count do
								local entity = event:getPlayer():getWorld():spawnEntity(event:getPlayer():getLocation():add(0, 4, 0), types.STRAY)
								entity:addPotionEffect(newInstance("$.potion.PotionEffect", {effects.FIRE_RESISTANCE, 600, 0}))
								entity:getWorld():spawnParticle(import("$.Particle").SPIT, entity:getLocation():add(0,1,0), 50, 0.5, 0.5, 0.5, 0.5)
								entity:setCustomName("§7스컬지")
								util.runLater(function()
									if entity:isDead() then 
										local maxHealth = event:getPlayer():getAttribute(attribute.GENERIC_MAX_HEALTH):getValue()
										local newHealth = event:getPlayer():getHealth() + 4
										if newHealth > maxHealth then newHealth = maxHealth end
										event:getPlayer():setHealth(newHealth)
										event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), import("$.Sound").ENTITY_STRAY_DEATH, 0.5, 1)
										event:getPlayer():getWorld():spawnParticle(import("$.Particle").SMOKE_NORMAL, event:getPlayer():getLocation():add(0,1,0), 500, 0.5, 0.7, 0.5, 0.05)
									end
									if entity:isValid() then 
										entity:getWorld():spawnParticle(import("$.Particle").SMOKE_NORMAL, entity:getLocation():add(0,1,0), 1000, 0.5, 0.7, 0.5, 0.05)
										entity:remove() 
									end 
								end, 600)
							end
						end, 70)
					else
						game.sendMessage(event:getPlayer(), "§4[§c" .. ability.abilityName .. "§4] §c마나 수정이 부족합니다! (필요 마나 수정 : " .. LAPlayer:getVariable("HS013-requireCost") .. "개)")
						ability:resetCooldown(id)
					end
				end
			end
		end
	end
end

function addCost(player, ability)
	local prevCost = player:getVariable("HS013-cost")
	local cost = prevCost
	
	if cost < 10 then
		local healthAmount = (player:getVariable("HS013-health") - player:getPlayer():getHealth()) + player:getVariable("HS013-healthStack")
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
		
		if cost < 10 then player:setVariable("HS013-healthStack", healthAmount)
		else player:setVariable("HS013-healthStack", 0) end
		if (prevCost < cost) then
			player:setVariable("HS013-health", player:getPlayer():getHealth())
			player:setVariable("HS013-cost", cost)
			
			game.sendMessage(player:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b마나 수정이 생성되었습니다! (현재 마나 수정 : " .. cost .. "개)")
			player:getPlayer():playSound(player:getPlayer():getLocation(), import("$.Sound").ENTITY_EXPERIENCE_ORB_PICKUP, 0.5, 2)
			player:getPlayer():spawnParticle(particle.ITEM_CRACK, player:getPlayer():getLocation():add(0,1,0), 50, 0.2, 0.5, 0.2, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").DIAMOND_BLOCK}))
		end
	end
end

function effect(player)
	for i = 1, 100 do
		util.runLater(function() 
			for j = 0, 4 do
				local angle = 2 * math.pi * util.random(1, 360) / 360
				local x = math.cos(angle) * util.random(-7, 7)
				local z = math.sin(angle) * util.random(-7, 7)
				local block = player:getWorld():getHighestBlockAt(player:getLocation():getX() + x, player:getLocation():getZ() + z)
				local randomIndex = util.random(1, 10)
				if randomIndex <= 9 then util.setBlockType(block, material.SNOW_BLOCK)
				else util.setBlockType(block, material.ICE) end
			end
		end, i)
	end
end

function cancelTarget(LAPlayer, event, ability, id)
	if event:getTarget() ~= nil and event:getEntity() ~= nil then
		if event:getTarget():getType():toString() == "PLAYER" and event:getEntity():getType():toString() == "STRAY" then
			if string.find(event:getEntity():getCustomName(), "스컬지") and game.getTeamManager():getMyTeam(LAPlayer, false):contains(game.getPlayer(event:getTarget())) then
				event:setTarget(nil)
				event:setCancelled(true)
			end
		elseif event:getTarget():getType():toString() == "STRAY" and event:getEntity():getType():toString() == "STRAY" then
			if string.find(event:getTarget():getCustomName(), "스컬지") and string.find(event:getEntity():getCustomName(), "스컬지") then
				event:setTarget(nil)
				event:setCancelled(true)
			end
		end
	end
end

function fireOff(LAPlayer, event, ability, id)
	if event:getEntity() ~= nil then
		if event:getEntity():getType():toString() == "STRAY" then
			if game.checkCooldown(LAPlayer, LAPlayer, ability, id) then
				event:getEntity():setVisualFire(false)
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
		location:getWorld():spawnParticle(particle.SPIT, location, 2, 0.5, 0, 0.5, 0.1)
		location:getWorld():spawnParticle(particle.REDSTONE, location, 2, 0.5, 0, 0.5, 0.9, newInstance("$.Particle$DustOptions", { import("$.Color"):fromRGB(222, 255, 255), 1.5 }))
        location:subtract(x, 0, z)
    end
end

function addStray(LAPlayer, event, ability, id)
	local damageEvent = event:getEntity():getLastDamageCause()
	
	if (damageEvent ~= nil and damageEvent:isCancelled() == false and damageEvent:getEventName() == "EntityDamageByEntityEvent") then
		local damagee = damageEvent:getEntity()
		local damager = util.getRealDamager(damageEvent:getDamager())
		
		
		if damager ~= nil and damagee:getType():toString() == "PLAYER" then
			if damager:getType():toString() == "PLAYER" and game.checkCooldown(LAPlayer, game.getPlayer(damager), ability, id) then
				LAPlayer:setVariable("HS013-summonCount", LAPlayer:getVariable("HS013-summonCount") + 1) 
				game.sendMessage(LAPlayer:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b스컬지 소환 수가 증가했습니다. (" .. LAPlayer:getVariable("HS013-summonCount") .. "명)")
			elseif damager:getType():toString() == "STRAY" and game.checkCooldown(LAPlayer, LAPlayer, ability, id) then
				LAPlayer:setVariable("HS013-summonCount", LAPlayer:getVariable("HS013-summonCount") + 1) 
				game.sendMessage(LAPlayer:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b스컬지 소환 수가 증가했습니다. (" .. LAPlayer:getVariable("HS013-summonCount") .. "명)")
			end
		end
	end
end