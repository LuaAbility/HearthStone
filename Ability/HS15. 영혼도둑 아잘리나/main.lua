local particle = import("$.Particle")
local material = import("$.Material")
local types = import("$.entity.EntityType")

function Init(abilityData)
	plugin.requireDataPack("HearthStone", "https://blog.kakaocdn.net/dn/sAeFO/btrrxXWPS5C/aODIDmfwRB3boWzAlG6Wo1/HearthStone.zip?attach=1&knm=tfile.zip")
	plugin.registerEvent(abilityData, "HS015-abilityUse", "PlayerInteractEvent", 100)
end

function onEvent(funcTable)
	if funcTable[1] == "HS015-abilityUse" then abilityUse(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
end

function onTimer(player, ability)
	if player:getVariable("HS015-health") == nil then 
		player:setVariable("HS015-health", player:getPlayer():getHealth()) 
		player:setVariable("HS015-healthStack", 0) 
		player:setVariable("HS015-cost", 0) 
		player:setVariable("HS015-requireCost", 7) 
	end
	
	local str = "§1[§b마나 수정§1] §b"
	local cost = player:getVariable("HS015-cost")
	for i = 1, 10 do
		if i <= cost then str = str .. "●"
		else str = str .. "○" end
	end
	game.sendActionBarMessage(player:getPlayer(), str)
	
	if cost < 10 then
		if player:getVariable("HS015-health") < player:getPlayer():getHealth() then player:setVariable("HS015-health", player:getPlayer():getHealth()) end
		local healthAmount = (player:getVariable("HS015-health") - player:getPlayer():getHealth()) + player:getVariable("HS015-healthStack")
		
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
					if LAPlayer:getVariable("HS015-cost") >= LAPlayer:getVariable("HS015-requireCost") then
						local players = util.getTableFromList(game.getPlayers())
						for i = 1, #players do
							if not players[i]:getPlayer():isDead() and getLookingAt(event:getPlayer(), players[i]:getPlayer(), 0.98) then
								game.sendMessage(event:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b능력을 사용했습니다.")
								event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs15.usebgm", 0.5, 1)
								event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs15.useline", 1, 1)
								LAPlayer:setVariable("HS015-cost", LAPlayer:getVariable("HS015-cost") - LAPlayer:getVariable("HS015-requireCost"))
								drawLine(event:getPlayer(), players[i]:getPlayer())
								return 0
							end
						end
					else
						game.sendMessage(event:getPlayer(), "§4[§c" .. ability.abilityName .. "§4] §c마나 수정이 부족합니다! (필요 마나 수정 : " .. LAPlayer:getVariable("HS015-requireCost") .. "개)")
					end
				end
			end
		end
	end
end

function addCost(player, ability)
	local prevCost = player:getVariable("HS015-cost")
	local cost = prevCost
	
	if cost < 10 then
		local healthAmount = (player:getVariable("HS015-health") - player:getPlayer():getHealth()) + player:getVariable("HS015-healthStack")
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
		
		if cost < 10 then player:setVariable("HS015-healthStack", healthAmount)
		else player:setVariable("HS015-healthStack", 0) end
		if (prevCost < cost) then
			player:setVariable("HS015-health", player:getPlayer():getHealth())
			player:setVariable("HS015-cost", cost)
			
			game.sendMessage(player:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b마나 수정이 생성되었습니다! (현재 마나 수정 : " .. cost .. "개)")
			player:getPlayer():playSound(player:getPlayer():getLocation(), import("$.Sound").ENTITY_EXPERIENCE_ORB_PICKUP, 0.5, 2)
			player:getPlayer():spawnParticle(particle.ITEM_CRACK, player:getPlayer():getLocation():add(0,1,0), 50, 0.2, 0.5, 0.2, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").DIAMOND_BLOCK}))
		end
	end
end

function getLookingAt(player, player1, checkDouble)
	local eye = player:getEyeLocation()
	local toEntity = player1:getEyeLocation():toVector():subtract(eye:toVector())
	local dot = toEntity:normalize():dot(eye:getDirection())
	
	if player:getWorld():getEnvironment() ~= player1:getWorld():getEnvironment() then dot = 0
	elseif player:getPlayer():getLocation():distance(player1:getLocation()) > 20 then dot = 0 end

	if not player:hasLineOfSight(player1) then dot = 0 end
	
	return dot > checkDouble
end

function drawLine(player1, player2)
	local armorStand = player2:getLocation():getWorld():spawnEntity(player2:getLocation(), types.ARMOR_STAND)
	armorStand:setGravity(false)
	armorStand:setVisible(false)
	
	local item = newInstance("$.inventory.ItemStack", {material.PLAYER_HEAD})
	local sm = item:getItemMeta()
	sm:setOwner(player2:getName())
	item:setItemMeta(sm)

	armorStand:getEquipment():setHelmet(item)
	
	local result = armorStand:getLocation():toVector()
    for j = 0, 20 do
		util.runLater(function()
			local timeCount = j
			local tempResult = result:clone()
			local addVec = player1:getLocation():toVector():clone():subtract(tempResult:clone()):multiply(timeCount / 20)
			
			
			tempResult:add(addVec)
			armorStand:teleport(newInstance("$.Location", {armorStand:getWorld(), tempResult:getX(), tempResult:getY(), tempResult:getZ()}))
			
			armorStand:getWorld():spawnParticle(particle.REDSTONE, armorStand:getLocation():add(0,1,0), 20, 0.5, 0.5, 0.5, 0.9, newInstance("$.Particle$DustOptions", { import("$.Color"):fromRGB(222, 255, 255), 1.5 }))
			armorStand:getWorld():spawnParticle(particle.REDSTONE, armorStand:getLocation():add(0,1,0), 20, 0.5, 0.5, 0.5, 0.9, newInstance("$.Particle$DustOptions", { import("$.Color"):fromRGB(255, 255, 255), 1.5 }))
			armorStand:getWorld():spawnParticle(particle.ITEM_CRACK, armorStand:getLocation():add(0,1,0), 40, 0.5, 0.5, 0.5, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").SNOW_BLOCK}))
		end, j)
	end
	
	util.runLater(function() 
		player1:getInventory():setContents(player2:getInventory():getContents())
		player1:getInventory():setExtraContents(player2:getInventory():getExtraContents())
		player1:getInventory():setArmorContents(player2:getInventory():getArmorContents())
		
		player1:getWorld():spawnParticle(particle.SPIT, player1:getLocation():add(0,1,0), 200, 0.5, 0.5, 0.5, 0.3)
		player1:getWorld():spawnParticle(particle.ITEM_CRACK, player1:getLocation():add(0,1,0), 200, 0.5, 0.5, 0.5, 0.3, newInstance("$.inventory.ItemStack", {import("$.Material").SNOW_BLOCK}))
		armorStand:remove()
	end, 21)
end