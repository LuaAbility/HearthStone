local particle = import("$.Particle")
local material = import("$.Material")
local enchantment = import("$.enchantments.Enchantment")
local effect = import("$.potion.PotionEffectType")

function Init(abilityData)
	plugin.requireDataPack("HearthStone", "https://blog.kakaocdn.net/dn/sAeFO/btrrxXWPS5C/aODIDmfwRB3boWzAlG6Wo1/HearthStone.zip?attach=1&knm=tfile.zip")
	plugin.registerEvent(abilityData, "꿈", "PlayerInteractEvent", 100)
	plugin.registerEvent(abilityData, "HS009-cancelDamage", "EntityDamageEvent", 0)
end

function onEvent(funcTable)
	if funcTable[1] == "꿈" then abilityUse(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
	if funcTable[1] == "HS009-cancelDamage" then cancelDamage(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
end

function onTimer(player, ability)
	if player:getVariable("HS009-health") == nil then 
		player:setVariable("HS009-health", player:getPlayer():getHealth()) 
		player:setVariable("HS009-healthStack", 0) 
		player:setVariable("HS009-cost", 0) 
		player:setVariable("HS009-requireCost", 3) 
		player:setVariable("HS009-abilityTime", 0)
	end
	
	local str = "§1[§b마나 수정§1] §b"
	local cost = player:getVariable("HS009-cost")
	for i = 1, 10 do
		if i <= cost then str = str .. "●"
		else str = str .. "○" end
	end
	game.sendActionBarMessage(player:getPlayer(), str)
	
	if cost < 10 then
		if player:getVariable("HS009-health") < player:getPlayer():getHealth() then player:setVariable("HS009-health", player:getPlayer():getHealth()) end
		local healthAmount = (player:getVariable("HS009-health") - player:getPlayer():getHealth()) + player:getVariable("HS009-healthStack")
		
		if healthAmount > 1 then
			addCost(player, ability)
		end
	end
	
	local timeCount = player:getVariable("HS009-abilityTime")
	if timeCount > 0 then
		timeCount = timeCount - 2
		if timeCount <= 0 then game.sendMessage(player:getPlayer(), "§1[§b꿈§1] §b능력 시전 시간이 종료되었습니다.") end
		player:getPlayer():getWorld():spawnParticle(particle.REDSTONE, player:getPlayer():getLocation():add(0, 1, 0), 15, 0.3, 0.5, 0.3, 0.05, newInstance("$.Particle$DustOptions", {import("$.Color").LIME, 1}))
		player:setVariable("HS009-abilityTime", timeCount)
	end
end

function abilityUse(LAPlayer, event, ability, id)
	if event:getAction():toString() == "RIGHT_CLICK_AIR" or event:getAction():toString() == "RIGHT_CLICK_BLOCK" then
		if event:getItem() ~= nil then
			if game.isAbilityItem(event:getItem(), "IRON_INGOT") then
				if game.checkCooldown(LAPlayer, game.getPlayer(event:getPlayer()), ability, id, false) and LAPlayer:getVariable("HS009-abilityTime") <= 0 then
					if LAPlayer:getVariable("HS009-cost") >= LAPlayer:getVariable("HS009-requireCost") then
						LAPlayer:setVariable("HS009-cost", LAPlayer:getVariable("HS009-cost") - LAPlayer:getVariable("HS009-requireCost"))
						game.sendMessage(event:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b능력을 사용했습니다.")
						event:getPlayer():getWorld():spawnParticle(particle.REDSTONE, event:getPlayer():getLocation():add(0, 1, 0), 300, 0.3, 0.5, 0.3, 0.05, newInstance("$.Particle$DustOptions", {import("$.Color").LIME, 1}))
						local randomNumber = util.random(1, 3)
						if randomNumber == 1 then nightmare(event:getPlayer())
						elseif randomNumber == 2 then dream(event:getPlayer())
						elseif randomNumber == 3 then allSleep(event:getPlayer())
						else goodOmen(event:getPlayer()) end
						event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs9.useline", 0.5, 1)
						event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs9.usebgm", 1, 1)
						event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs9.usesfx", 0.5, 1)
					else
						game.sendMessage(event:getPlayer(), "§4[§c" .. ability.abilityName .. "§4] §c마나 수정이 부족합니다! (필요 마나 수정 : " .. LAPlayer:getVariable("HS009-requireCost") .. "개)")
						ability:resetCooldown(id)
					end
				end
			elseif event:getItem():getType() == material.GREEN_DYE and event:getItem():getItemMeta():getDisplayName("§a꿈") then
				if game.checkCooldown(LAPlayer, game.getPlayer(event:getPlayer()), ability, id, false) then
					local materialItem = { event:getItem():clone() }
					materialItem[1]:setAmount(1)
					event:getPlayer():getInventory():removeItem( materialItem )
					game.sendMessage(event:getPlayer(), "§1[§b꿈§1] §b능력을 사용했습니다.")
					LAPlayer:setVariable("HS009-abilityTime", 200)
				end
			elseif event:getItem():getType() == material.BRICK and event:getItem():getItemMeta():getDisplayName("§7기면") then
				if game.checkCooldown(LAPlayer, game.getPlayer(event:getPlayer()), ability, id, false) then
					local materialItem = { event:getItem():clone() }
					materialItem[1]:setAmount(1)
					event:getPlayer():getInventory():removeItem( materialItem )
					game.sendMessage(event:getPlayer(), "§1[§b기면§1] §b능력을 사용했습니다.")
					
					local players = util.getTableFromList(game.getPlayers())
					event:getPlayer():getWorld():setTime(18000)
					for i = 1, #players do
						if event:getPlayer() ~= players[i]:getPlayer() and game.targetPlayer(LAPlayer, players[i], false) then
							local bed = players[i]:getPlayer():getWorld():getBlockAt(players[i]:getPlayer():getLocation():add(0, 0, 0))
							bed:setType(material.LIME_BED)
							local bedData = bed:getBlockData()
							bedData:setPart(import("$.block.data.type.Bed$Part").HEAD)
							bed:setBlockData(bedData)
							
							local bed2 = players[i]:getPlayer():getWorld():getBlockAt(players[i]:getPlayer():getLocation():add(0, 0, 1))
							bed2:setType(material.LIME_BED)
							local bed2Data = bed2:getBlockData()
							bed2Data:setPart(import("$.block.data.type.Bed$Part").FOOT)
							bed2:setBlockData(bed2Data)
							
							players[i]:getPlayer():sleep(bed:getLocation(), true)
						end
					end
				end
			end
		end
	end
end

function nightmare(player)
	local item = newInstance("$.inventory.ItemStack", {material.NETHERITE_SWORD, 1})
	local itemMeta = item:getItemMeta()
	itemMeta:setDamage(2031)
	itemMeta:setDisplayName("§5약몽")
	itemMeta:addEnchant(enchantment.DAMAGE_ALL, 5, true)
	itemMeta:setRepairCost(9999999)
	item:setItemMeta(itemMeta)
	player:getWorld():dropItemNaturally(player:getLocation(), item)
end

function dream(player)
	local item = newInstance("$.inventory.ItemStack", {material.GREEN_DYE, 1})
	local itemMeta = item:getItemMeta()
	itemMeta:setDisplayName("§a꿈")
	
	local lore = newInstance("java.util.ArrayList", {})
	lore:add("§7우 클릭 시 10초 간 모든 데미지를 받지 않습니다.")
	itemMeta:setLore( lore )
	
	item:setItemMeta(itemMeta)
	player:getWorld():dropItemNaturally(player:getLocation(), item)
end

function goodOmen(player)
	local item = newInstance("$.inventory.ItemStack", {material.POTION, 1})
	local itemMeta = item:getItemMeta()
	itemMeta:setDisplayName("§b길몽")
	itemMeta:addCustomEffect(newInstance("$.potion.PotionEffect", {effect.DAMAGE_RESISTANCE, 600, 1}), true)
	itemMeta:addCustomEffect(newInstance("$.potion.PotionEffect", {effect.FIRE_RESISTANCE, 600, 0}), true)
	itemMeta:addCustomEffect(newInstance("$.potion.PotionEffect", {effect.INCREASE_DAMAGE, 600, 0}), true)
	itemMeta:addCustomEffect(newInstance("$.potion.PotionEffect", {effect.REGENERATION, 600, 1}), true)
	itemMeta:setColor(import("$.Color").LIME)
	item:setItemMeta(itemMeta)
	player:getWorld():dropItemNaturally(player:getLocation(), item)
end

function allSleep(player)
	local item = newInstance("$.inventory.ItemStack", {material.BRICK, 1})
	local itemMeta = item:getItemMeta()
	itemMeta:setDisplayName("§7기면")
	
	local lore = newInstance("java.util.ArrayList", {})
	lore:add("§7우 클릭 시 자신을 제외한 모든 플레이어가 그 자리에서 잠듭니다.")
	itemMeta:setLore( lore )
	
	item:setItemMeta(itemMeta)
	player:getWorld():dropItemNaturally(player:getLocation(), item)
end

function cancelDamage(LAPlayer, event, ability, id)
	if event:getEntity():getType():toString() == "PLAYER" then
		if LAPlayer:getVariable("HS009-abilityTime") ~= nil and LAPlayer:getVariable("HS009-abilityTime") > 0 then
			if game.checkCooldown(LAPlayer, game.getPlayer(event:getEntity()), ability, id) then
				event:setCancelled(true)
			end
		end
	end
end

function addCost(player, ability)
	local prevCost = player:getVariable("HS009-cost")
	local cost = prevCost
	
	if cost < 10 then
		local healthAmount = (player:getVariable("HS009-health") - player:getPlayer():getHealth()) + player:getVariable("HS009-healthStack")
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
		
		if cost < 10 then player:setVariable("HS009-healthStack", healthAmount)
		else player:setVariable("HS009-healthStack", 0) end
		if (prevCost < cost) then
			player:setVariable("HS009-health", player:getPlayer():getHealth())
			player:setVariable("HS009-cost", cost)
			
			game.sendMessage(player:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b마나 수정이 생성되었습니다! (현재 마나 수정 : " .. cost .. "개)")
			player:getPlayer():playSound(player:getPlayer():getLocation(), import("$.Sound").ENTITY_EXPERIENCE_ORB_PICKUP, 0.5, 2)
			player:getPlayer():spawnParticle(particle.ITEM_CRACK, player:getPlayer():getLocation():add(0,1,0), 50, 0.2, 0.5, 0.2, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").DIAMOND_BLOCK}))
		end
	end
end