local particle = import("$.Particle")
local material = import("$.Material")

function Init(abilityData)
	plugin.requireDataPack("HearthStone", "https://blog.kakaocdn.net/dn/sAeFO/btrrxXWPS5C/aODIDmfwRB3boWzAlG6Wo1/HearthStone.zip?attach=1&knm=tfile.zip")
	plugin.registerEvent(abilityData, "HS018-abilityUse", "PlayerInteractEvent", 100)
end

function onEvent(funcTable)
	if funcTable[1] == "HS018-abilityUse" then abilityUse(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
end

function onTimer(player, ability)
	if player:getVariable("HS018-passiveCount") == nil then 
		player:setVariable("HS018-passiveCount", 0) 
		player:setVariable("HS018-cost", 0) 
		player:setVariable("HS018-requireCost", 6) 
		player:setVariable("HS018-abilityCount", 0) 
	end
	
	local str = "§1[§b마나 수정§1] §b"
	local cost = player:getVariable("HS018-cost")
	for i = 1, 10 do
		if i <= cost then str = str .. "●"
		else str = str .. "○" end
	end
	game.sendActionBarMessage(player:getPlayer(), str)
	
	if cost < 10 then
		local count = player:getVariable("HS018-passiveCount")
		if count >= 400 * plugin.getPlugin().gameManager.cooldownMultiply then 
			count = 0
			addCost(player, ability)
		end
		count = count + 2
		player:setVariable("HS018-passiveCount", count)
	else 
		player:setVariable("HS018-passiveCount", 0)
	end
end

function abilityUse(LAPlayer, event, ability, id)
	if event:getAction():toString() == "RIGHT_CLICK_AIR" or event:getAction():toString() == "RIGHT_CLICK_BLOCK" then
		if event:getItem() ~= nil then
			if game.isAbilityItem(event:getItem(), "IRON_INGOT") then
				if game.checkCooldown(LAPlayer, game.getPlayer(event:getPlayer()), ability, id, false) then
					if LAPlayer:getVariable("HS018-cost") >= LAPlayer:getVariable("HS018-requireCost") then
						LAPlayer:setVariable("HS018-cost", LAPlayer:getVariable("HS018-cost") - LAPlayer:getVariable("HS018-requireCost"))
						
						local abilityCount = LAPlayer:getVariable("HS018-abilityCount")
						abilityCount = abilityCount + 1
						game.sendMessage(event:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b능력을 사용했습니다. (사용 횟수 : " .. abilityCount .. "회)")
						
						event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs18.useline", 0.5, 1)
						event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs18.usebgm", 1, 1)
						LAPlayer:setVariable("HS018-abilityCount", abilityCount)
						for j = 0, 60 do
							util.runLater(function()
								local multiply = (abilityCount * 0.5)
								event:getPlayer():getWorld():spawnParticle(particle.REDSTONE, event:getPlayer():getLocation():add(0, 0.25, 0), 40 * multiply, multiply, 0.1, multiply, 0.05, newInstance("$.Particle$DustOptions", { import("$.Color").PURPLE, multiply }))
								local smoke = particle.SMOKE_NORMAL
								if abilityCount >= 4 then smoke = particle.SMOKE_LARGE end
								event:getPlayer():getWorld():spawnParticle(smoke, event:getPlayer():getLocation():add(0, 0.25, 0), 20 * multiply, multiply, 0.1, multiply, 0.05)
							end, j)
						end
						
						if abilityCount >= 5 then
							util.runLater(function()
								game.sendMessage(event:getPlayer(), "§2[§a" .. ability.abilityName .. "§2] §a능력을 5번 사용하여 능력이 변경됩니다.")
								LAPlayer:setVariable("HS018-passiveCount", 0) 
								LAPlayer:setVariable("HS018-cost", 0) 
								LAPlayer:setVariable("HS018-requireCost", 10) 
								LAPlayer:setVariable("HS018-abilityCount", 0) 
								util.runLater(function() game.changeAbility(LAPlayer, ability, "LA-HS-018-HIDDEN", false) end, 1)
							end, 70)
						end
					else
						game.sendMessage(event:getPlayer(), "§4[§c" .. ability.abilityName .. "§4] §c마나 수정이 부족합니다! (필요 마나 수정 : " .. LAPlayer:getVariable("HS018-requireCost") .. "개)")
					end
				end
			end
		end
	end
end

function addCost(player, ability)
	local cost = player:getVariable("HS018-cost")
	if cost == nil then player:setVariable("HS018-cost", 0) cost = 0 end
	if cost < 10 then
		cost = cost + 1
		player:setVariable("HS018-cost", cost)
		game.sendMessage(player:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b마나 수정이 생성되었습니다! (현재 마나 수정 : " .. player:getVariable("HS018-cost") .. "개)")
		player:getPlayer():playSound(player:getPlayer():getLocation(), import("$.Sound").ENTITY_EXPERIENCE_ORB_PICKUP, 0.5, 2)
		player:getPlayer():spawnParticle(particle.ITEM_CRACK, player:getPlayer():getLocation():add(0,1,0), 50, 0.2, 0.5, 0.2, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").DIAMOND_BLOCK}))
	end
end