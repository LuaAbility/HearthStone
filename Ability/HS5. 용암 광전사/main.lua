local particle = import("$.Particle")
local material = import("$.Material")
local attribute = import("$.attribute.Attribute")
local effect = import("$.potion.PotionEffectType")

function Init(abilityData)
	plugin.requireDataPack("HearthStone", "https://blog.kakaocdn.net/dn/sAeFO/btrrxXWPS5C/aODIDmfwRB3boWzAlG6Wo1/HearthStone.zip?attach=1&knm=tfile.zip")
	plugin.registerEvent(abilityData, "HS005-abilityUse", "PlayerInteractEvent", 100)
end

function onEvent(funcTable)
	if funcTable[1] == "HS005-abilityUse" then abilityUse(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
end

function onTimer(player, ability)
	if player:getVariable("HS005-health") == nil then 
		player:setVariable("HS005-health", player:getPlayer():getHealth()) 
		player:setVariable("HS005-healthStack", 0) 
		player:setVariable("HS005-cost", 0) 
		player:setVariable("HS005-requireCost", 3) 
		player:setVariable("HS005-abilityTime", 0)
	end
	
	local str = "§1[§b마나 수정§1] §b"
	local cost = player:getVariable("HS005-cost")
	for i = 1, 10 do
		if i <= cost then str = str .. "●"
		else str = str .. "○" end
	end
	game.sendActionBarMessage(player:getPlayer(), str)
	
	if cost < 10 then
		if player:getVariable("HS005-health") < player:getPlayer():getHealth() then player:setVariable("HS005-health", player:getPlayer():getHealth()) end
		local healthAmount = (player:getVariable("HS005-health") - player:getPlayer():getHealth()) + player:getVariable("HS005-healthStack")
		
		if healthAmount > 1 then
			addCost(player, ability)
		end
	end
	
	local timeCount = player:getVariable("HS005-abilityTime")
	if timeCount > 0 then
		timeCount = timeCount - 2
		player:getPlayer():addPotionEffect(newInstance("$.potion.PotionEffect", {effect.INCREASE_DAMAGE, 20, 0}))
		player:getPlayer():getWorld():spawnParticle(import("$.Particle").LAVA, player:getPlayer():getLocation():add(0,1,0), 3, 0.3, 0.3, 0.3, 0.9)
		if timeCount % util.random(20, 30) == 0 then 
			player:getPlayer():getWorld():playSound(player:getPlayer():getLocation(), import("$.Sound").BLOCK_LAVA_POP, 0.5, 1.0)
			player:getPlayer():getWorld():spawnParticle(import("$.Particle").FLAME, player:getPlayer():getLocation():add(0,1,0), 10, 0.3, 0.3, 0.3, 0.5)
		end
		if timeCount <= 0 then ResetHealth(player, ability) end
		player:setVariable("HS005-abilityTime", timeCount)
	end
end

function abilityUse(LAPlayer, event, ability, id)
	if event:getAction():toString() == "RIGHT_CLICK_AIR" or event:getAction():toString() == "RIGHT_CLICK_BLOCK" then
		if event:getItem() ~= nil then
			if game.isAbilityItem(event:getItem(), "IRON_INGOT") then
				if game.checkCooldown(LAPlayer, game.getPlayer(event:getPlayer()), ability, id, false) then
					if LAPlayer:getVariable("HS005-cost") >= LAPlayer:getVariable("HS005-requireCost") then
						game.sendMessage(event:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b능력을 사용했습니다.")
						LAPlayer:setVariable("HS005-cost", LAPlayer:getVariable("HS005-cost") - LAPlayer:getVariable("HS005-requireCost"))
						LAPlayer:setVariable("HS005-prevHealth", event:getPlayer():getHealth() - 4)
						LAPlayer:setVariable("HS005-abilityTime", 200)
						
						if event:getPlayer():getHealth() > 4 then 
							event:getPlayer():setHealth(4) 
							player:setVariable("HS005-health", 4) 
						end
						event:getPlayer():getAttribute(attribute.GENERIC_MAX_HEALTH):setBaseValue(4)
						event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs5.useline", 1, 1)
					else
						game.sendMessage(event:getPlayer(), "§4[§c" .. ability.abilityName .. "§4] §c마나 수정이 부족합니다! (필요 마나 수정 : " .. LAPlayer:getVariable("HS005-requireCost") .. "개)")
					end
				end
			end
		end
	end
end

function ResetHealth(player, ability)
	game.sendMessage(player:getPlayer(), "§2[§a" .. ability.abilityName .. "§2] §a능력 시전 시간이 종료되었습니다.")
	player:getPlayer():getAttribute(attribute.GENERIC_MAX_HEALTH):setBaseValue(player:getPlayer():getAttribute(attribute.GENERIC_MAX_HEALTH):getDefaultValue())
	if player:getVariable("HS005-prevHealth") > 0 then 
		local newHealth = player:getPlayer():getHealth() + player:getVariable("HS005-prevHealth")
		if newHealth > player:getPlayer():getAttribute(attribute.GENERIC_MAX_HEALTH):getDefaultValue() then newHealth = player:getPlayer():getAttribute(attribute.GENERIC_MAX_HEALTH):getDefaultValue() end
		player:getPlayer():setHealth(newHealth) 
	end
	player:getPlayer():getWorld():spawnParticle(import("$.Particle").SMOKE_NORMAL, player:getPlayer():getLocation():add(0,1,0), 300, 0.2, 0.2, 0.2, 0.9)
	player:getPlayer():getWorld():playSound(player:getPlayer():getLocation(), "hs5.endline", 2, 1)
end

function Reset(player, ability)
	if player:getVariable("HS005-abilityTime") ~= nil and player:getVariable("HS005-abilityTime") > 0 then ResetHealth(player, ability) end
end

function addCost(player, ability)
	local prevCost = player:getVariable("HS005-cost")
	local cost = prevCost
	
	if cost < 10 then
		local healthAmount = (player:getVariable("HS005-health") - player:getPlayer():getHealth()) + player:getVariable("HS005-healthStack")
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
		
		if cost < 10 then player:setVariable("HS005-healthStack", healthAmount)
		else player:setVariable("HS005-healthStack", 0) end
		if (prevCost < cost) then
			player:setVariable("HS005-health", player:getPlayer():getHealth())
			player:setVariable("HS005-cost", cost)
			
			game.sendMessage(player:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b마나 수정이 생성되었습니다! (현재 마나 수정 : " .. cost .. "개)")
			player:getPlayer():playSound(player:getPlayer():getLocation(), import("$.Sound").ENTITY_EXPERIENCE_ORB_PICKUP, 0.5, 2)
			player:getPlayer():spawnParticle(particle.ITEM_CRACK, player:getPlayer():getLocation():add(0,1,0), 50, 0.2, 0.5, 0.2, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").DIAMOND_BLOCK}))
		end
	end
end