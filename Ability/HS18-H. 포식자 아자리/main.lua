local particle = import("$.Particle")
local material = import("$.Material")
local types = import("$.entity.EntityType")

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
		player:setVariable("HS018-requireCost", 10) 
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
		if count >= 600 * plugin.getPlugin().gameManager.cooldownMultiply then 
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
						game.sendMessage(event:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b능력을 사용했습니다.")
						local players = util.getTableFromList(game.getPlayers())
						for i = 1, #players do
							players[i]:getPlayer():playSound(players[i]:getPlayer():getLocation(), "hs18.finaluseline", 1, 1)
							players[i]:getPlayer():playSound(players[i]:getPlayer():getLocation(), "hs18.finalusebgm", 1, 1)
							if players[i]:getPlayer() ~= LAPlayer:getPlayer() then
								removeInventory(players[i]:getPlayer())
							end
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

function removeInventory(target)
	local armorStand = target:getWorld():spawnEntity(target:getEyeLocation():add(0, 8, 0), types.ARMOR_STAND)
	armorStand:setSmall(true)
	armorStand:setGravity(false)
	armorStand:setVisible(false)
	
	local result = armorStand:getLocation():toVector()
	
	target:getWorld():playSound(target:getLocation(), "hs18.hitsfx", 1, 1)
	for j = 0, 20 do
		util.runLater(function()
			armorStand:getWorld():spawnParticle(particle.REDSTONE, armorStand:getLocation(), 100, 0.4, 0.4, 0.4, 0.05, newInstance("$.Particle$DustOptions", { import("$.Color"):fromRGB(0, 102, 0), 1 }))
			armorStand:getWorld():spawnParticle(particle.SMOKE_NORMAL, armorStand:getLocation(), 50, 0.4, 0.4, 0.4, 0.05)
			armorStand:getWorld():spawnParticle(particle.FLAME, armorStand:getLocation(), 20, 0.4, 0.4, 0.4, 0.05)
		end, j)
	end
	
	for j = 0, 20 do
		util.runLater(function()
			local timeCount = j
			local tempResult = result:clone()
			local addVec = target:getEyeLocation():toVector():clone():subtract(tempResult:clone()):multiply(timeCount / 20)
			
			tempResult:add(addVec)
			armorStand:teleport(newInstance("$.Location", {armorStand:getWorld(), tempResult:getX(), tempResult:getY(), tempResult:getZ()}))
			
			armorStand:getWorld():spawnParticle(particle.ITEM_CRACK, armorStand:getLocation(), 50, 0.3, 0.3, 0.3, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").EMERALD_BLOCK}))
			armorStand:getWorld():spawnParticle(particle.REDSTONE, armorStand:getLocation(), 100, 0.3, 0.3, 0.3, 0.05, newInstance("$.Particle$DustOptions", { import("$.Color"):fromRGB(0, 102, 0), 1 }))
			armorStand:getWorld():spawnParticle(particle.SMOKE_NORMAL, armorStand:getLocation(), 50, 0.3, 0.3, 0.3, 0.05)
			armorStand:getWorld():spawnParticle(particle.FLAME, armorStand:getLocation(), 20, 0.3, 0.3, 0.3, 0.05)
		end, j + 20)
	end
	
	util.runLater(function() 
		target:getWorld():spawnParticle(particle.FLAME, target:getLocation(), 20, 0.3, 0.3, 0.3, 0.8)
		target:getWorld():spawnParticle(particle.SMOKE_NORMAL, target:getLocation():add(0,1,0), 200, 0.2, 0.2, 0.2, 0.8)
		target:getWorld():spawnParticle(particle.ITEM_CRACK, target:getLocation():add(0,1,0), 300, 0.4, 0.4, 0.4, 0.8, newInstance("$.inventory.ItemStack", {import("$.Material").EMERALD_BLOCK}))
		target:getWorld():spawnParticle(particle.REDSTONE, target:getLocation():add(0,1,0), 400, 0.3, 0.3, 0.3, 0.05, newInstance("$.Particle$DustOptions", { import("$.Color"):fromRGB(0, 102, 0), 1 }))
		target:getInventory():clear()
		armorStand:remove()
	end, 41)
end