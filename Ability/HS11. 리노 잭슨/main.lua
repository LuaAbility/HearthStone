local particle = import("$.Particle")
local material = import("$.Material")
local attribute = import("$.attribute.Attribute")

function Init(abilityData)
	plugin.requireDataPack("HearthStone", "https://blog.kakaocdn.net/dn/sAeFO/btrrxXWPS5C/aODIDmfwRB3boWzAlG6Wo1/HearthStone.zip?attach=1&knm=tfile.zip")
	plugin.registerEvent(abilityData, "HS011-abilityUse", "PlayerInteractEvent", 600)
end

function onEvent(funcTable)
	if funcTable[1] == "HS011-abilityUse" then abilityUse(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
end

function onTimer(player, ability)
	if player:getVariable("HS011-health") == nil then 
		player:setVariable("HS011-health", player:getPlayer():getHealth()) 
		player:setVariable("HS011-healthStack", 0) 
		player:setVariable("HS011-cost", 0) 
		player:setVariable("HS011-requireCost", 7) 
	end
	
	local str = "§1[§b마나 수정§1] §b"
	local cost = player:getVariable("HS011-cost")
	for i = 1, 10 do
		if i <= cost then str = str .. "●"
		else str = str .. "○" end
	end
	game.sendActionBarMessage(player:getPlayer(), str)
	
	if cost < 10 then
		if player:getVariable("HS011-health") < player:getPlayer():getHealth() then player:setVariable("HS011-health", player:getPlayer():getHealth()) end
		local healthAmount = (player:getVariable("HS011-health") - player:getPlayer():getHealth()) + player:getVariable("HS011-healthStack")
		
		if healthAmount > 1 then
			addCost(player, ability)
		end
	end
end

function abilityUse(LAPlayer, event, ability, id)
	if event:getAction():toString() == "RIGHT_CLICK_AIR" or event:getAction():toString() == "RIGHT_CLICK_BLOCK" then
		if event:getItem() ~= nil then
			if game.isAbilityItem(event:getItem(), "IRON_INGOT") then
				if game.checkCooldown(LAPlayer, game.getPlayer(event:getPlayer()), ability, id, false) then
					local inventory = event:getPlayer():getInventory()
					local itemTable = newInstance("java.util.ArrayList", {})
					for i = 0, 8 do
						local itemType = inventory:getItem(i)
						if itemType == nil then itemType = newInstance("$.inventory.ItemStack", {import("$.Material").AIR}) end
						if not itemTable:contains(itemType) then itemTable:add(itemType) end
					end
					
					if itemTable:size() < 9 then
						game.sendMessage(event:getPlayer(), "§4[§c" .. ability.abilityName .. "§4] §c능력 사용 조건이 맞지 않습니다!")
					else
						if LAPlayer:getVariable("HS011-cost") >= LAPlayer:getVariable("HS011-requireCost") then
							game.sendMessage(event:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b능력을 사용했습니다.")
							LAPlayer:setVariable("HS011-cost", LAPlayer:getVariable("HS011-cost") - LAPlayer:getVariable("HS011-requireCost"))
							event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs11.useline", 0.5, 1)
							event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs11.usebgm", 1, 1)
							
							for i = 0, 12 do
								util.runLater(function() 
									local x = util.random(-15, 15)
									local y = util.random(5, 20)
									local z = util.random(-15, 15)
									
									if x ~= 0 then x = x / 10 end
									if y ~= 0 then y = y / 10 end
									if z ~= 0 then z = z / 10 end
									event:getPlayer():getWorld():spawnParticle(particle.ITEM_CRACK, event:getPlayer():getLocation():add(x,y,z), 10, 0.3, 0.3, 0.3, 0.1, newInstance("$.inventory.ItemStack", {import("$.Material").RAW_GOLD_BLOCK}))
									event:getPlayer():getWorld():spawnParticle(particle.ITEM_CRACK, event:getPlayer():getLocation():add(x,y,z), 10, 0.3, 0.3, 0.3, 0.1, newInstance("$.inventory.ItemStack", {import("$.Material").GOLD_BLOCK}))
									event:getPlayer():getWorld():spawnParticle(particle.ITEM_CRACK, event:getPlayer():getLocation():add(x,y,z), 10, 0.3, 0.3, 0.3, 0.1, newInstance("$.inventory.ItemStack", {import("$.Material").GLOWSTONE}))
									event:getPlayer():getWorld():spawnParticle(particle.ITEM_CRACK, event:getPlayer():getLocation():add(x,y,z), 10, 0.3, 0.3, 0.3, 0.1, newInstance("$.inventory.ItemStack", {import("$.Material").YELLOW_CONCRETE}))
									event:getPlayer():getWorld():spawnParticle(particle.ITEM_CRACK, event:getPlayer():getLocation():add(x,y,z), 10, 0.3, 0.3, 0.3, 0.1, newInstance("$.inventory.ItemStack", {import("$.Material").YELLOW_GLAZED_TERRACOTTA}))
									
									util.runLater(function()
										event:getPlayer():getWorld():spawnParticle(particle.ITEM_CRACK, event:getPlayer():getLocation():add(x,0,z), 20, 0.5, 0.1, 0.5, 0.1, newInstance("$.inventory.ItemStack", {import("$.Material").RAW_GOLD_BLOCK}))
										event:getPlayer():getWorld():spawnParticle(particle.ITEM_CRACK, event:getPlayer():getLocation():add(x,0,z), 20, 0.5, 0.1, 0.5, 0.1, newInstance("$.inventory.ItemStack", {import("$.Material").GOLD_BLOCK}))
										event:getPlayer():getWorld():spawnParticle(particle.ITEM_CRACK, event:getPlayer():getLocation():add(x,0,z), 20, 0.5, 0.1, 0.5, 0.1, newInstance("$.inventory.ItemStack", {import("$.Material").GLOWSTONE}))
										event:getPlayer():getWorld():spawnParticle(particle.ITEM_CRACK, event:getPlayer():getLocation():add(x,0,z), 20, 0.5, 0.1, 0.5, 0.1, newInstance("$.inventory.ItemStack", {import("$.Material").YELLOW_CONCRETE}))
										event:getPlayer():getWorld():spawnParticle(particle.ITEM_CRACK, event:getPlayer():getLocation():add(x,0,z), 20, 0.5, 0.1, 0.5, 0.1, newInstance("$.inventory.ItemStack", {import("$.Material").YELLOW_GLAZED_TERRACOTTA}))
									end, 5)
								end, i * 3)
							end
							util.runLater(function() 
								event:getPlayer():getWorld():spawnParticle(particle.REDSTONE, event:getPlayer():getLocation():add(0, 1, 0), 150, 0.7, 0.7, 0.7, 0.9, newInstance("$.Particle$DustOptions", {import("$.Color").YELLOW, 2}))
								event:getPlayer():setHealth(event:getPlayer():getAttribute(attribute.GENERIC_MAX_HEALTH):getValue())
								event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs11.usesfx", 1, 1) 
								event:getPlayer():getWorld():spawnParticle(particle.ITEM_CRACK, event:getPlayer():getLocation(), 30, 1, 0.2, 1, 0.1, newInstance("$.inventory.ItemStack", {import("$.Material").RAW_GOLD_BLOCK}))
								event:getPlayer():getWorld():spawnParticle(particle.ITEM_CRACK, event:getPlayer():getLocation(), 30, 1, 0.2, 1, 0.1, newInstance("$.inventory.ItemStack", {import("$.Material").GOLD_BLOCK}))
								event:getPlayer():getWorld():spawnParticle(particle.ITEM_CRACK, event:getPlayer():getLocation(), 30, 1, 0.2, 1, 0.1, newInstance("$.inventory.ItemStack", {import("$.Material").GLOWSTONE}))
								event:getPlayer():getWorld():spawnParticle(particle.ITEM_CRACK, event:getPlayer():getLocation(), 30, 1, 0.2, 1, 0.1, newInstance("$.inventory.ItemStack", {import("$.Material").YELLOW_CONCRETE}))
								event:getPlayer():getWorld():spawnParticle(particle.ITEM_CRACK, event:getPlayer():getLocation(), 30, 1, 0.2, 1, 0.1, newInstance("$.inventory.ItemStack", {import("$.Material").YELLOW_GLAZED_TERRACOTTA}))	
							end, 40)
						else
							game.sendMessage(event:getPlayer(), "§4[§c" .. ability.abilityName .. "§4] §c마나 수정이 부족합니다! (필요 마나 수정 : " .. LAPlayer:getVariable("HS011-requireCost") .. "개)")
						end
					end
				end
			end
		end
	end
end

function addCost(player, ability)
	local prevCost = player:getVariable("HS011-cost")
	local cost = prevCost
	
	if cost < 10 then
		local healthAmount = (player:getVariable("HS011-health") - player:getPlayer():getHealth()) + player:getVariable("HS011-healthStack")
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
		
		if cost < 10 then player:setVariable("HS011-healthStack", healthAmount)
		else player:setVariable("HS011-healthStack", 0) end
		if (prevCost < cost) then
			player:setVariable("HS011-health", player:getPlayer():getHealth())
			player:setVariable("HS011-cost", cost)
			
			game.sendMessage(player:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b마나 수정이 생성되었습니다! (현재 마나 수정 : " .. cost .. "개)")
			player:getPlayer():playSound(player:getPlayer():getLocation(), import("$.Sound").ENTITY_EXPERIENCE_ORB_PICKUP, 0.5, 2)
			player:getPlayer():spawnParticle(particle.ITEM_CRACK, player:getPlayer():getLocation():add(0,1,0), 50, 0.2, 0.5, 0.2, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").DIAMOND_BLOCK}))
		end
	end
end
