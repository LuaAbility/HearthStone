local particle = import("$.Particle")
local material = import("$.Material")
local dustOption = newInstance("$.Particle$DustTransition", {import("$.Color").YELLOW, import("$.Color").RED, 1})

function Init(abilityData)
	plugin.requireDataPack("HearthStone", "https://blog.kakaocdn.net/dn/sAeFO/btrrxXWPS5C/aODIDmfwRB3boWzAlG6Wo1/HearthStone.zip?attach=1&knm=tfile.zip")
	plugin.registerEvent(abilityData, "HS007-abilityUse", "PlayerInteractEvent", 300)
end

function onEvent(funcTable)
	if funcTable[1] == "HS007-abilityUse" then abilityUse(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
end

function onTimer(player, ability)
	if player:getVariable("HS007-health") == nil then 
		player:setVariable("HS007-health", player:getPlayer():getHealth()) 
		player:setVariable("HS007-healthStack", 0) 
		player:setVariable("HS007-cost", 0) 
		player:setVariable("HS007-requireCost", 9) 
	end
	
	local str = "§1[§b마나 수정§1] §b"
	local cost = player:getVariable("HS007-cost")
	for i = 1, 10 do
		if i <= cost then str = str .. "●"
		else str = str .. "○" end
	end
	game.sendActionBarMessage(player:getPlayer(), str)
	
	if cost < 10 then
		if player:getVariable("HS007-health") < player:getPlayer():getHealth() then player:setVariable("HS007-health", player:getPlayer():getHealth()) end
		local healthAmount = (player:getVariable("HS007-health") - player:getPlayer():getHealth()) + player:getVariable("HS007-healthStack")
		
		if healthAmount > 1 then
			addCost(player, ability)
		end
	end
end

function abilityUse(LAPlayer, event, ability, id)
	if event:getItem() ~= nil then
		if game.isAbilityItem(event:getItem(), "IRON_INGOT") then
			if game.checkCooldown(LAPlayer, game.getPlayer(event:getPlayer()), ability, id, false) then
				if LAPlayer:getVariable("HS007-cost") >= LAPlayer:getVariable("HS007-requireCost") then
					if event:getAction():toString() == "RIGHT_CLICK_AIR" or event:getAction():toString() == "RIGHT_CLICK_BLOCK" then
						local players = util.getTableFromList(game.getPlayers())
						for i = 1, #players do
							if getLookingAt(event:getPlayer(), players[i]:getPlayer(), 0.98) then
								if game.targetPlayer(LAPlayer, players[i]) then
									game.sendMessage(event:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b능력을 사용했습니다.")
									LAPlayer:setVariable("HS007-cost", LAPlayer:getVariable("HS007-cost") - LAPlayer:getVariable("HS007-requireCost"))
									drawLine(event:getPlayer():getEyeLocation(), players[i]:getPlayer():getEyeLocation())
									players[i]:getPlayer():setHealth(10)
									players[i]:getPlayer():setFoodLevel(10)
									players[i]:getPlayer():getWorld():spawnParticle(particle.REDSTONE, players[i]:getPlayer():getLocation():add(0, 1, 0), 300, 0.3, 0.5, 0.3, 0.05, dustOption)
									players[i]:getPlayer():getWorld():spawnParticle(particle.SMOKE_NORMAL, players[i]:getPlayer():getLocation():add(0, 1, 0), 300, 0.3, 0.5, 0.3, 0.05)
									event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs7.useline", 0.5, 1)
									event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs7.usebgm", 1, 1)
									players[i]:getPlayer():getWorld():playSound(players[i]:getPlayer():getLocation(), "hs7.hitsfx", 0.5, 1)
								else
									ability:resetCooldown(id)
								end
								return 0
							end
						end
						game.sendMessage(event:getPlayer(), "§4[§c" .. ability.abilityName .. "§4] §c타겟할 플레이어가 없습니다.")
					elseif event:getAction():toString() == "LEFT_CLICK_AIR" or event:getAction():toString() == "LEFT_CLICK_BLOCK" then
						print(1)
						LAPlayer:setVariable("HS007-cost", LAPlayer:getVariable("HS007-cost") - LAPlayer:getVariable("HS007-requireCost"))
						event:getPlayer():getWorld():spawnParticle(particle.REDSTONE, event:getPlayer():getLocation():add(0, 1, 0), 300, 0.3, 0.5, 0.3, 0.05, dustOption)
						event:getPlayer():getWorld():spawnParticle(particle.SMOKE_NORMAL, event:getPlayer():getLocation():add(0, 1, 0), 300, 0.3, 0.5, 0.3, 0.05)
						event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), import("$.Sound").ENTITY_BLAZE_SHOOT, 0.5, 1.2)
						event:getPlayer():setHealth(10)
						event:getPlayer():setFoodLevel(10)
						event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs7.useline", 0.5, 1)
						event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs7.usebgm", 1, 1)
						event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs7.hitsfx", 0.5, 1)
						game.sendMessage(event:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b능력을 사용했습니다.")
					end
				else
					game.sendMessage(event:getPlayer(), "§4[§c" .. ability.abilityName .. "§4] §c마나 수정이 부족합니다! (필요 마나 수정 : " .. LAPlayer:getVariable("HS007-requireCost") .. "개)")
				end
			end
		end
	end
end

function addCost(player, ability)
	local prevCost = player:getVariable("HS007-cost")
	local cost = prevCost
	
	if cost < 10 then
		local healthAmount = (player:getVariable("HS007-health") - player:getPlayer():getHealth()) + player:getVariable("HS007-healthStack")
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
		
		if cost < 10 then player:setVariable("HS007-healthStack", healthAmount)
		else player:setVariable("HS007-healthStack", 0) end
		if (prevCost < cost) then
			player:setVariable("HS007-health", player:getPlayer():getHealth())
			player:setVariable("HS007-cost", cost)
			
			game.sendMessage(player:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b마나 수정이 생성되었습니다! (현재 마나 수정 : " .. cost .. "개)")
			player:getPlayer():playSound(player:getPlayer():getLocation(), import("$.Sound").ENTITY_EXPERIENCE_ORB_PICKUP, 0.5, 2)
			player:getPlayer():spawnParticle(particle.ITEM_CRACK, player:getPlayer():getLocation():add(0,1,0), 50, 0.2, 0.5, 0.2, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").DIAMOND_BLOCK}))
		end
	end
end

function drawLine(point1, point2)
    local world = point1:getWorld()
    local distance = point1:distance(point2)
    local p1 = point1:toVector()
    local p2 = point2:toVector()
    local vector = p2:clone():subtract(p1):normalize()
    for i = 0, distance do
		local loc = newInstance("$.Location", { world, p1:getX(), p1:getY(), p1:getZ() })
        world:spawnParticle(particle.REDSTONE, loc, 50, 0.25, 0.25, 0.25, 0.05, dustOption)
        world:spawnParticle(particle.SMOKE_NORMAL, loc, 50, 0.25, 0.25, 0.25, 0.05)
        world:spawnParticle(particle.FLAME, loc, 50, 0.25, 0.25, 0.25, 0.05)
		p1:add(vector)
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