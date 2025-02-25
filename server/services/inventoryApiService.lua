---@diagnostic disable: undefined-global
InventoryAPI = {}
UsableItemsFunctions = {}
local allplayersammo = {}

-- by default assign this
CustomInventoryInfos = {
	default = {
		name = "Satchel",
		limit = Config.MaxItemsInInventory.Items,
		shared = false,
		---@type table<string, integer>
		limitedItems = {},
		---@type boolean
		ignoreItemStackLimit = false,
		---@type boolean
		whitelistItems = false,
		---@type table<string, integer>
		PermissionTakeFrom = {},
		---@type table<string, integer>
		PermissionMoveTo = {},
		---@type boolean
		UsePermissions = false,
		---@type boolean
		UseBlackList = false,
		---@type table<string>
		BlackListItems = {},
		---@type boolean
		whitelistWeapons = false,
		---@type table<string, integer>
		limitedWeapons = {}
	}
}

local function contains(table, element)
	if table ~= 0 then
		for k, v in pairs(table) do
			if string.upper(v) == string.upper(element) then
				return true
			end
		end
	end
	return false
end

InventoryAPI.canCarryAmountItem = function(player, amount, cb)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local charid = sourceCharacter.charIdentifier
	local userInventory = UsersInventories["default"][identifier]

	if userInventory and Config.MaxItemsInInventory.Items ~= -1 then
		local sourceInventoryItemCount = InventoryAPI.getUserTotalCount(identifier, charid)
		local finalAmount = sourceInventoryItemCount + amount
		if finalAmount <= Config.MaxItemsInInventory.Items then
			cb(true)
		else
			cb(false)
		end
	else
		cb(false)
	end
end

InventoryAPI.canCarryItem = function(player, itemName, amount, cb)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local charid = sourceCharacter.charIdentifier
	local svItem = svItems[itemName]

	if svItem == nil then
		Log.print("[^2API CanCarryItem^7] ^1Error^7: Item [^3" .. tostring(itemName) .. "^7] does not exist in DB.")
		cb(false)
		return
	end

	local limit = svItem:getLimit()

	if limit ~= -1 then
		local items = SvUtils.FindAllItemsByName("default", identifier, itemName)
		local count = 0
		for _, item in pairs(items) do
			count = count + item:getCount()
		end
		local total = count + amount

		if total <= limit then
			if Config.MaxItemsInInventory.Items ~= -1 then
				local sourceInventoryItemCount = InventoryAPI.getUserTotalCount(identifier, charid)
				local finalAmount = sourceInventoryItemCount + amount
				if finalAmount <= Config.MaxItemsInInventory.Items then
					cb(true)
				else
					cb(false)
				end
			else
				cb(true)
			end
		else
			cb(false)
		end
	else
		if Config.MaxItemsInInventory.Items ~= -1 then
			local totalAmount = InventoryAPI.getUserTotalCount(identifier, charid)
			local finalAmount = totalAmount + amount
			if finalAmount <= Config.MaxItemsInInventory.Items then
				cb(true)
			else
				cb(false)
			end
		else
			cb(true)
		end
	end
end

InventoryAPI.getInventory = function(player, cb)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local userInventory = UsersInventories["default"][identifier]

	if userInventory then
		local playerItems = {}

		for _, item in pairs(userInventory) do
			local newItem = {
				id = item:getId(),
				label = item:getLabel(),
				name = item:getName(),
				metadata = item:getMetadata(),
				type = item:getType(),
				count = item:getCount(),
				limit = item:getLimit(),
				canUse = item:getCanUse()
			}
			table.insert(playerItems, newItem)
		end
		cb(playerItems)
	end
end

InventoryAPI.registerUsableItem = function(name, cb)
	UsableItemsFunctions[name] = cb
	if Config.Debug then
		Wait(9000) -- so it doesn't print everywhere in the console
		Log.print("Callback for item[^3" .. name .. "^7] ^2Registered!^7")
	end
end

InventoryAPI.getUserWeapon = function(player, cb, weaponId)
	local weapon = {}
	local userWeapons = UsersWeapons["default"]

	if (userWeapons[weaponId]) then
		local foundWeapon = userWeapons[weaponId]
		weapon.name = foundWeapon:getName()
		weapon.id = foundWeapon:getId()
		weapon.propietary = foundWeapon:getPropietary()
		weapon.used = foundWeapon:getUsed()
		weapon.ammo = foundWeapon:getAllAmmo()
		weapon.desc = foundWeapon:getDesc()
	end
	cb(weapon)
end

InventoryAPI.getUserWeapons = function(player, cb)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local charidentifier = sourceCharacter.charIdentifier
	local usersWeapons = UsersWeapons["default"]

	local userWeapons2 = {}

	for _, currentWeapon in pairs(usersWeapons) do
		if currentWeapon:getPropietary() == identifier and currentWeapon:getCharId() == charidentifier then
			local weapon = {
				name = currentWeapon:getName(),
				id = currentWeapon:getId(),
				propietary = currentWeapon:getPropietary(),
				used = currentWeapon:getUsed(),
				ammo = currentWeapon:getAllAmmo(),
				desc = currentWeapon:getDesc()
			}
			table.insert(userWeapons2, weapon)
		end
	end
	cb(userWeapons2)
end

InventoryAPI.getWeaponBullets = function(player, cb, weaponId)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local userWeapons = UsersWeapons["default"]

	if (userWeapons[weaponId]) then
		if userWeapons[weaponId]:getPropietary() == identifier then
			cb(userWeapons[weaponId]:getAllAmmo())
		end
	end
end

AddEventHandler('playerDropped', function(reason)
	local _source = source
	allplayersammo[_source] = nil
end)

RegisterServerEvent("vorpinventory:removeammo") -- new event
AddEventHandler("vorpinventory:removeammo", function(player)
	local _source = player
	allplayersammo[_source]["ammo"] = {}
	TriggerClientEvent("vorpinventory:updateuiammocount", _source, allplayersammo[_source]["ammo"])
end)

RegisterServerEvent("vorpinventory:getammoinfo")
AddEventHandler("vorpinventory:getammoinfo", function()
	local _source = source
	if allplayersammo[_source] then
		TriggerClientEvent("vorpinventory:recammo", _source, allplayersammo[_source])
	end
end)

RegisterServerEvent("vorpinventory:servergiveammo")
AddEventHandler("vorpinventory:servergiveammo", function(ammotype, amount, target, maxcount)
	local _source = source
	local player1ammo = allplayersammo[_source]["ammo"][ammotype]
	local player2ammo = allplayersammo[target]["ammo"][ammotype]

	if allplayersammo[target]["ammo"][ammotype] == nil then
		allplayersammo[target]["ammo"][ammotype] = 0
	end

	if player1ammo == nil or player2ammo == nil then
		TriggerClientEvent("vorp_inventory:ProcessingReady", _source)
		return
	end

	if 0 > (player1ammo - amount) then
		TriggerClientEvent("vorp:Tip", _source, T.notenoughammo, 2000)
		TriggerClientEvent("vorp_inventory:ProcessingReady", _source)
		return
	elseif (player2ammo + amount) > maxcount then
		TriggerClientEvent("vorp:Tip", _source, T.fullammoyou, 2000)
		TriggerClientEvent("vorp:Tip", target, T.fullammo, 2000)
		TriggerClientEvent("vorp_inventory:ProcessingReady", _source)
		return
	end

	allplayersammo[_source]["ammo"][ammotype] = allplayersammo[_source]["ammo"][ammotype] - amount
	allplayersammo[target]["ammo"][ammotype] = allplayersammo[target]["ammo"][ammotype] + amount
	local charidentifier = allplayersammo[_source]["charidentifier"]
	local charidentifier2 = allplayersammo[target]["charidentifier"]
	MySQL.update("UPDATE characters Set ammo=@ammo WHERE charidentifier=@charidentifier",
		{ ['charidentifier'] = charidentifier, ['ammo'] = json.encode(allplayersammo[_source]["ammo"]) })
	MySQL.update("UPDATE characters Set ammo=@ammo WHERE charidentifier=@charidentifier",
		{ ['charidentifier'] = charidentifier2, ['ammo'] = json.encode(allplayersammo[target]["ammo"]) })
	TriggerClientEvent("vorpinventory:updateuiammocount", _source, allplayersammo[_source]["ammo"])
	TriggerClientEvent("vorpinventory:updateuiammocount", target, allplayersammo[target]["ammo"])
	TriggerClientEvent("vorpinventory:setammotoped", _source, allplayersammo[_source]["ammo"])
	TriggerClientEvent("vorpinventory:setammotoped", target, allplayersammo[target]["ammo"])
	TriggerClientEvent("vorp:Tip", _source, T.transferedammo .. Config.Ammolabels[ammotype] .. " : " .. amount, 2000)
	TriggerClientEvent("vorp:Tip", target, T.recammo .. Config.Ammolabels[ammotype] .. " : " .. amount, 2000)
	TriggerClientEvent("vorp_inventory:ProcessingReady", _source)
end)

RegisterServerEvent("vorpinventory:updateammo")
AddEventHandler("vorpinventory:updateammo", function(ammoinfo)
	local _source = source

	if not _source then
		return
	end

	allplayersammo[_source] = ammoinfo
	MySQL.update("UPDATE characters Set ammo=@ammo WHERE charidentifier=@charidentifier",
		{ ['charidentifier'] = ammoinfo["charidentifier"], ['ammo'] = json.encode(ammoinfo["ammo"]) })
end)

InventoryAPI.LoadAllAmmo = function()
	local _source = source

	if not _source then
		return
	end

	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local charidentifier = sourceCharacter.charIdentifier
	MySQL.query('SELECT ammo FROM characters WHERE charidentifier = @charidentifier ',
		{ ['charidentifier'] = charidentifier }, function(result)
			if result[1] then
				local ammo = json.decode(result[1].ammo)
				allplayersammo[_source] = { charidentifier = charidentifier, ammo = ammo }
				if next(ammo) then
					for k, v in pairs(ammo) do
						local ammocount = tonumber(v)
						if ammocount and ammocount > 0 then
							TriggerClientEvent("vorpCoreClient:addBullets", _source, k, ammocount)
						end
					end
				end
			end
		end)
end

InventoryAPI.addBullets = function(player, bulletType, amount)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local charidentifier = sourceCharacter.charIdentifier
	MySQL.query('SELECT ammo FROM characters WHERE charidentifier = @charidentifier;',
		{ ['charidentifier'] = charidentifier }, function(result)
			local ammo = json.decode(result[1].ammo)
			if ammo[bulletType] then
				ammo[bulletType] = tonumber(ammo[bulletType]) + amount
			else
				ammo[bulletType] = amount
			end
			allplayersammo[_source]["ammo"] = ammo
			TriggerClientEvent("vorpinventory:updateuiammocount", _source, allplayersammo[_source]["ammo"])
			TriggerClientEvent("vorpCoreClient:addBullets", _source, bulletType, ammo[bulletType])
			MySQL.update("UPDATE characters Set ammo=@ammo WHERE charidentifier=@charidentifier",
				{ ['charidentifier'] = charidentifier, ['ammo'] = json.encode(ammo) })
		end)
end

InventoryAPI.subBullets = function(weaponId, bulletType, amount)
	local _source = source
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local userWeapons = UsersWeapons["default"]

	if (userWeapons[weaponId]) then
		if userWeapons[weaponId]:getPropietary() == identifier then
			userWeapons[weaponId]:subAmmo(bulletType, amount)
			TriggerClientEvent("vorpCoreClient:subBullets", _source, bulletType, amount)
		end
	end
end

InventoryAPI.getItems = function(player, cb, itemName, metadata)
	local _source = player

	if not _source then
		return Log.error("InventoryAPI.getItems: specify a source")
	end

	local User = Core.getUser(_source)
	if not User then
		return Log.error("InventoryAPI.getItems: User dont exist ")
	end

	local identifier = User.getUsedCharacter.identifier
	local svItem = svItems[itemName]

	if not svItem then
		Log.print("[^2API GetItems^7] ^1Error^7: Item [^3" .. tostring(itemName) .. "^7] does not exist in DB.")
		return cb(0)
	end

	metadata = SharedUtils.MergeTables(svItem.metadata, metadata or {})
	local userInventory = UsersInventories["default"][identifier]

	if userInventory then
		local item = SvUtils.FindItemByNameAndMetadata("default", identifier, itemName, metadata)
		if not item then
			item = SvUtils.FindItemByNameAndMetadata("default", identifier, itemName, nil)
		end
		if item then
			return cb(item:getCount())
		else
			return cb(0)
		end
	end
end



InventoryAPI.getItemByName = function(player, itemName, cb)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local svItem = svItems[itemName]

	if svItem == nil then
		Log.print("[^2API GetItem^7] ^1Error^7: Item [^3" .. tostring(itemName) .. "^7] does not exist in DB.")
		cb(nil)
		return
	end

	local item = SvUtils.FindItemByNameAndMetadata("default", identifier, itemName, nil)
	if item then
		cb(item)
	else
		cb(nil)
	end
end

InventoryAPI.getItemContainingMetadata = function(player, itemName, metadata, cb)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local svItem = svItems[itemName]

	if svItem == nil then
		Log.print("[^2API GetItem^7] ^1Error^7: Item [^3" .. tostring(itemName) .. "^7] does not exist in DB.")
		cb(nil)
		return
	end

	local item = SvUtils.FindItemByNameAndContainingMetadata("default", identifier, itemName, metadata)

	if item then
		cb(item)
	else
		cb(nil)
	end
end

InventoryAPI.getItemMatchingMetadata = function(player, itemName, metadata, cb)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local svItem = svItems[itemName]

	if svItem == nil then
		Log.print("[^2API GetItem^7] ^1Error^7: Item [^3" .. tostring(itemName) .. "^7] does not exist in DB.")
		cb(nil)
		return
	end

	metadata = SharedUtils.MergeTables(svItem.metadata or {}, metadata or {})
	local item = SvUtils.FindItemByNameAndMetadata("default", identifier, itemName, metadata)

	if item then
		cb(item)
	else
		cb(nil)
	end
end


InventoryAPI.addItem = function(player, name, amount, metadata, cb)
	local _source = player

	if not _source then
		return Log.error("InventoryAPI.addItem: specify a source")
	end

	local sourceUser = Core.getUser(_source)

	if not sourceUser then
		Log.error("InventoryAPI.addItem: User dont exist ")
		return cb(false)
	end

	if cb == nil then
		cb = function(result)
		end
	end

	local svItem = svItems[name]

	if svItem == nil then
		Log.Warning("[^2API AddItem^7] ^1Error^7: Item [^3" .. tostring(name) .. "^7] does not exist in DB.")
		return cb(false)
	end

	metadata = SharedUtils.MergeTables(svItem.metadata, metadata or {})

	local sourceCharacter = sourceUser.getUsedCharacter
	local identifier = sourceCharacter.identifier
	local charIdentifier = sourceCharacter.charIdentifier
	local userInventory = UsersInventories["default"][identifier]

	if userInventory == nil then
		UsersInventories["default"][identifier] = {}
		userInventory = UsersInventories["default"][identifier] -- create reference to actual table
	end

	if not userInventory or amount <= 0 then
		return cb(false)
	end

	local sourceItemLimit = svItem:getLimit()
	local itemLabel = svItem:getLabel()
	local itemType = svItem:getType()
	local itemCanRemove = svItem:getCanRemove()
	local itemDefaultMetadata = svItem:getMetadata()
	local ItemDesc = svItem:getDesc()
	InventoryAPI.canCarryItem(_source, name, amount, function(result)
		if result then
			local item = SvUtils.FindItemByNameAndMetadata("default", identifier, name, metadata)
			if item ~= nil then -- Item already exist in inventory
				item:addCount(amount)
				DbService.SetItemAmount(charIdentifier, item:getId(), item:getCount())
				TriggerClientEvent("vorpCoreClient:addItem", _source, item)
				return cb(true)
			else
				DbService.CreateItem(charIdentifier, svItem:getId(), amount, metadata, function(craftedItem)
					item = Item:New({
						id = craftedItem.id,
						count = amount,
						limit = sourceItemLimit,
						label = itemLabel,
						metadata = SharedUtils.MergeTables(itemDefaultMetadata, metadata),
						name = name,
						type = itemType,
						canUse = true,
						canRemove = itemCanRemove,
						owner = charIdentifier,
						desc = ItemDesc
					})
					userInventory[craftedItem.id] = item
					TriggerClientEvent("vorpCoreClient:addItem", _source, item)
				end)
				return cb(true)
			end
		else
			-- inventory is full
			TriggerClientEvent("vorp:Tip", _source, T.fullInventory, 2000)
			return cb(false)
		end
	end)
end

InventoryAPI.getItemByMainId = function(player, mainid, cb)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local userInventory = UsersInventories["default"][identifier]

	if userInventory then
		local itemRequested = {}
		for _, item in pairs(userInventory) do
			if mainid == item:getId() then
				itemRequested = {
					id = item:getId(),
					label = item:getLabel(),
					name = item:getName(),
					metadata = item:getMetadata(),
					type = item:getType(),
					count = item:getCount(),
					limit = item:getLimit(),
					canUse = item:getCanUse()
				}
				return cb(itemRequested) -- send table of the item requested
			end
		end
	end
	return cb(nil)
end


InventoryAPI.subItemID = function(player, id, cb)
	local _source = player
	local sourceUser = Core.getUser(_source)

	if cb == nil then
		cb = function(r)
		end
	end

	if not sourceUser then
		Log.error("InventoryAPI.subItemID: User dont exist ")
		return cb(false)
	end

	local sourceCharacter = sourceUser.getUsedCharacter
	local identifier = sourceCharacter.identifier
	local charIdentifier = sourceCharacter.charIdentifier
	local userInventory = UsersInventories["default"][identifier]

	if not userInventory then
		return cb(false)
	end
	local item = userInventory[id]

	if not item then
		return cb(false)
	end

	local sourceItemCount = item:getCount()

	if not sourceItemCount then
		return cb(false)
	end

	item:quitCount(1)

	TriggerClientEvent("vorpCoreClient:subItem", _source, item:getId(), item:getCount())

	if sourceItemCount == 1 then
		userInventory[item:getId()] = nil
		DbService.DeleteItem(charIdentifier, item:getId())
	else
		DbService.SetItemAmount(charIdentifier, item:getId(), item:getCount())
	end
	cb(true)
end

InventoryAPI.subItem = function(player, name, amount, metadata, cb)
	local _source = player

	if cb == nil then
		cb = function(r)
		end
	end

	if not _source then
		Log.error("InventoryAPI.subItem: specify a source")
		return cb(false)
	end

	local sourceUser = Core.getUser(_source)
	if (sourceUser) == nil then
		return cb(false)
	end

	local svItem = svItems[name]
	if svItem == nil then
		Log.print("[^2API SubItem^7] ^1Error^7: Item [^3" .. tostring(name) .. "^7] does not exist in DB.")
		return cb(false)
	end

	metadata = SharedUtils.MergeTables(svItem.metadata, metadata or {})

	local sourceCharacter = sourceUser.getUsedCharacter
	local identifier = sourceCharacter.identifier
	local charIdentifier = sourceCharacter.charIdentifier
	local userInventory = UsersInventories["default"][identifier]

	if userInventory then
		local item = SvUtils.FindItemByNameAndMetadata("default", identifier, name, metadata)
		if item == nil then
			item = SvUtils.FindItemByName("default", identifier, name)
		end
		if item then
			local sourceItemCount = item:getCount()

			if amount <= sourceItemCount then
				item:quitCount(amount)
			else
				return cb(false)
			end

			TriggerClientEvent("vorpCoreClient:subItem", _source, item:getId(), item:getCount())

			if item:getCount() == 0 then
				userInventory[item:getId()] = nil
				DbService.DeleteItem(charIdentifier, item:getId())
			else
				DbService.SetItemAmount(charIdentifier, item:getId(), item:getCount())
			end
			return cb(true)
		else
			return cb(false)
		end
	end
end

---comment
---@param player integer
---@param itemId integer
---@param metadata table
---@param amount integer an ammount if you require to remove this many or set this many
---@param cb any
---@return any
InventoryAPI.setItemMetadata = function(player, itemId, metadata, amount, cb)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local charId = sourceCharacter.charIdentifier
	local userInventory = UsersInventories["default"][identifier]
	local amountRemove = amount or 1

	if not userInventory then
		return cb(false)
	end

	local item = userInventory[itemId]

	if not item then
		return cb(false)
	end

	local count = item:getCount()

	if amountRemove >= count then -- if greater or equals we set meta data
		DbService.SetItemMetadata(charId, item.id, metadata)
		item:setMetadata(metadata)
		TriggerClientEvent("vorpCoreClient:SetItemMetadata", _source, itemId, metadata)
		return cb(true)
	else                                                                               -- we set meta data to only the amount we want
		item:quitCount(amountRemove)                                                   -- item remove
		DbService.SetItemAmount(charId, item.id, item:getCount())                      --
		TriggerClientEvent("vorpCoreClient:subItem", _source, item:getId(), item:getCount()) -- remove
		DbService.CreateItem(charId, item:getId(), amount or 1, metadata, function(craftedItem)
			item = Item:New(
				{
					id = craftedItem.id,
					count = amount or 1,
					limit = item:getLimit(),
					label = item:getLabel(),
					metadata = SharedUtils.MergeTables(item:getMetadata(), metadata),
					name = item:getName(),
					type = item:getType(),
					canUse = true,
					canRemove = item:getCanRemove(),
					owner = charId,
					desc = item:getDesc()
				})
			userInventory[craftedItem.id] = item
			TriggerClientEvent("vorpCoreClient:addItem", _source, item)
		end)
		return cb(true)
	end
end

InventoryAPI.canCarryAmountWeapons = function(player, amount, cb, weaponName)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local charId = sourceCharacter.charIdentifier
	local job = sourceCharacter.job
	local DefaultAmount = Config.MaxItemsInInventory.Weapons

	if weaponName then
		if SharedUtils.IsValueInArray(string.upper(weaponName), Config.notweapons) then
			return cb(true)
		end
	end

	if Config.JobsAllowed[job] then
		DefaultAmount = Config.JobsAllowed[job]
	end
	local sourceInventoryWeaponCount = InventoryAPI.getUserTotalCountWeapons(identifier, charId) + amount

	if Config.MaxItemsInInventory.Weapons ~= -1 then
		if sourceInventoryWeaponCount > DefaultAmount then
			return cb(false)
		else
			return cb(true)
		end
	else
		return cb(true)
	end
end

InventoryAPI.getItem = function(player, itemName, cb, metadata)
	local _source = player

	if not _source then
		Log.error("InventoryAPI.getItem: specify a source")
		return cb(false)
	end

	if not Core.getUser(_source) then
		Log.error("InventoryAPI.getItem: User dont exist ")
		return cb(false)
	end

	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local svItem = svItems[itemName]

	if not svItem then
		Log.print("[^2API GetItem^7] ^1Error^7: Item [^3" .. tostring(itemName) .. "^7] does not exist in DB.")
		return cb(nil)
	end

	metadata = SharedUtils.MergeTables(svItem.metadata or {}, metadata or {})
	local item = SvUtils.FindItemByNameAndMetadata("default", identifier, itemName, metadata)
	if item == nil then
		item = SvUtils.FindItemByNameAndMetadata("default", identifier, itemName, nil)
	end
	if item then
		cb(item)
	else
		cb(nil)
	end
end



InventoryAPI.getcomps = function(player, weaponid, cb)
	local _source = player
	MySQL.query('SELECT comps FROM loadout WHERE id = @id ', { ['id'] = weaponid }, function(result)
		if result[1] ~= nil then
			cb(json.decode(result[1].comps))
		else
			cb({})
		end
	end)
end



InventoryAPI.deletegun = function(player, weaponid, cb)
	local _source = player
	local userWeapons = UsersWeapons["default"]
	userWeapons[weaponid]:setPropietary('')
	MySQL.query("DELETE FROM loadout WHERE id=@id", { ['id'] = weaponid })
	if cb then
		return cb(true)
	end
end

InventoryAPI.registerWeapon = function(_target, wepname, ammos, components, comps, cb)
	local targetUser = Core.getUser(_target)
	local name = string.upper(wepname)
	local ammo = {}
	local component = {}
	local DefaultAmount = Config.MaxItemsInInventory.Weapons
	local canGive = false
	local notListed = false

	if cb == nil then
		cb = function(r)
		end
	end

	-- does weapon exist
	for _, weapons in pairs(Config.Weapons) do
		if weapons.HashName == name then
			canGive = true
			break
		end
	end
	-- does user exist
	if not targetUser then
		Log.error("InventoryAPI.registerWeapon: User dont exist ")
		return cb(false)
	end

	local targetCharacter = targetUser.getUsedCharacter
	local targetIdentifier = targetCharacter.identifier
	local targetCharId = targetCharacter.charIdentifier
	local job = targetCharacter.job

	-- whitelist jobs for custom amount
	if Config.JobsAllowed[job] then
		DefaultAmount = Config.JobsAllowed[job]
	end

	if DefaultAmount ~= 0 then
		if name then
			-- does weapon given matches the list of weapons that do not count as weapons
			if SharedUtils.IsValueInArray(name, Config.notweapons) then
				notListed = true
			end
		end

		if not notListed then
			local targetTotalWeaponCount = InventoryAPI.getUserTotalCountWeapons(targetIdentifier, targetCharId) + 1
			if targetTotalWeaponCount > DefaultAmount then
				TriggerClientEvent("vorp:TipRight", _target, T.cantweapons2, 2000)
				if Config.Debug then
					Log.Warning(targetCharacter.firstname ..
						" " .. targetCharacter.lastname .. " ^1Can't carry more weapons^7")
				end
				return cb(nil)
			end
		end
	end
	if ammos then
		for key, value in pairs(ammos) do
			ammo[key] = value
		end
	end
	if components then
		for key, _ in pairs(components) do
			component[#component + 1] = key
		end
	end


	if canGive then
		if not comps then
			MySQL.query(
				"INSERT INTO loadout (identifier, charidentifier, name, ammo, components) VALUES (@identifier, @charid, @name, @ammo, @components)",
				{
					['identifier'] = targetIdentifier,
					['charid'] = targetCharId,
					['name'] = name,
					['ammo'] = json.encode(ammo),
					['components'] = json.encode(component)
				}, function(result)
					local weaponId = result.insertId
					local newWeapon = Weapon:New({
						id = weaponId,
						propietary = targetIdentifier,
						name = name,
						ammo = ammo,
						used = false,
						used2 = false,
						charId = targetCharId,
						currInv = "default",
						dropped = 0,
					})
					UsersWeapons["default"][weaponId] = newWeapon
					TriggerEvent("syn_weapons:registerWeapon", weaponId)
					TriggerClientEvent("vorpInventory:receiveWeapon", _target, weaponId, targetIdentifier, name, ammo)
					return cb(true)
				end)
		else
			MySQL.query(
				"INSERT INTO loadout (identifier, charidentifier, name, ammo, components, comps) VALUES (@identifier, @charid, @name, @ammo, @components, @comps)",
				{
					['identifier'] = targetIdentifier,
					['charid'] = targetCharId,
					['name'] = name,
					['ammo'] = json.encode(ammo),
					['components'] = json.encode(component),
					['comps'] = json.encode(comps),
				},
				function(result)
					local weaponId = result.insertId
					local newWeapon = Weapon:New({
						id = weaponId,
						propietary = targetIdentifier,
						name = name,
						ammo = ammo,
						used = false,
						used2 = false,
						charId = targetCharId,
						currInv = "default",
						dropped = 0,
					})
					UsersWeapons["default"][weaponId] = newWeapon
					TriggerEvent("syn_weapons:registerWeapon", weaponId)
					TriggerClientEvent("vorpInventory:receiveWeapon", _target, weaponId, targetIdentifier, name, ammo)
					return cb(true)
				end)
		end
	else
		Log.Warning("Weapon: [^2" .. name .. "^7] ^1 do not exist on the config or its a WRONG HASH")
		return cb(nil)
	end
end

InventoryAPI.giveWeapon2 = function(player, weaponId, target)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local sourceIdentifier = sourceCharacter.identifier
	local sourceCharId = sourceCharacter.charIdentifier
	local job = sourceCharacter.job
	local _target = tonumber(target)
	local userWeapons = UsersWeapons["default"]
	userWeapons[weaponId]:setPropietary('')
	local DefaultAmount = Config.MaxItemsInInventory.Weapons
	local weaponName = userWeapons[weaponId]:getName()
	local notListed = false

	if Config.JobsAllowed[job] then
		DefaultAmount = Config.JobsAllowed[job]
	end

	if DefaultAmount ~= 0 then
		if weaponName then
			-- does weapon given matches the list of weapons that do not count as weapons
			if SharedUtils.IsValueInArray(string.upper(weaponName), Config.notweapons) then
				notListed = true
			end
		end

		if not notListed then
			local sourceTotalWeaponCount = InventoryAPI.getUserTotalCountWeapons(sourceIdentifier, sourceCharId) + 1

			if sourceTotalWeaponCount > DefaultAmount then
				TriggerClientEvent("vorp:TipRight", _source, T.cantweapons, 2000)
				if Config.Debug then
					Log.print(sourceCharacter.firstname ..
						" " .. sourceCharacter.lastname .. " ^1Can't carry more weapons^7")
				end
				return
			end
		end
	end

	local weaponcomps = {}
	local result = MySQL.single.await('SELECT comps FROM loadout WHERE id = @id ', { ['id'] = weaponId })
	if result then
		weaponcomps = json.decode(result.comps)
	end

	local weaponname = userWeapons[weaponId]:getName()
	local ammo = { ["nothing"] = 0 }
	local components = { ["nothing"] = 0 }
	InventoryAPI.registerWeapon(_source, weaponname, ammo, components, weaponcomps)
	InventoryAPI.deletegun(_source, weaponId)
	TriggerClientEvent("vorpinventory:updateinventorystuff", _target)
	TriggerClientEvent("vorpinventory:updateinventorystuff", _source)
	TriggerClientEvent("vorpCoreClient:subWeapon", _target, weaponId)
	-- notify
	TriggerClientEvent("vorp:TipRight", _target, T.youGaveWeapon, 2000)
	TriggerClientEvent("vorp:TipRight", _source, T.youReceivedWeapon, 2000)
end

InventoryAPI.giveWeapon = function(player, weaponId, target)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local sourceIdentifier = sourceCharacter.identifier
	local sourceCharId = sourceCharacter.charIdentifier
	local job = sourceCharacter.job
	local _target = tonumber(target)
	local targetisPlayer = false
	local userWeapons = UsersWeapons["default"]
	local DefaultAmount = Config.MaxItemsInInventory.Weapons
	local weapon = userWeapons[weaponId]
	local weaponName = weapon:getName()
	local notListed = false

	for _, pl in pairs(GetPlayers()) do
		if tonumber(pl) == _target then
			targetisPlayer = true
			break
		end
	end

	if Config.JobsAllowed[job] then
		DefaultAmount = Config.JobsAllowed[job]
	end

	if DefaultAmount ~= 0 then
		if weaponName then
			-- does weapon given matches the list of weapons that do not count as weapons
			if SharedUtils.IsValueInArray(string.upper(weaponName), Config.notweapons) then
				notListed = true
			end
		end
		if not notListed then
			local sourceTotalWeaponCount = InventoryAPI.getUserTotalCountWeapons(sourceIdentifier, sourceCharId) + 1

			if sourceTotalWeaponCount > DefaultAmount then
				TriggerClientEvent("vorp:TipRight", _source, T.cantweapons, 2000)
				if Config.Debug then
					Log.print(sourceCharacter.firstname ..
						" " .. sourceCharacter.lastname .. " ^1Can't carry more weapons^7")
				end
				return
			end
		end
	end

	if userWeapons[weaponId] then
		userWeapons[weaponId]:setPropietary(sourceIdentifier)
		userWeapons[weaponId]:setCharId(sourceCharId)
		local weaponPropietary = userWeapons[weaponId]:getPropietary()
		local weaponName = userWeapons[weaponId]:getName()
		local weaponAmmo = userWeapons[weaponId]:getAllAmmo()
		MySQL.update("UPDATE loadout SET identifier = @identifier, charidentifier = @charid WHERE id = @id",
			{
				['identifier'] = sourceIdentifier,
				['charid'] = sourceCharId,
				['id'] = weaponId
			}, function()
			end)
		if targetisPlayer then
			TriggerClientEvent('vorp:ShowAdvancedRightNotification', _target, T.youGaveWeapon, "inventory_items",
				weaponName,
				"COLOR_PURE_WHITE", 4000)
			TriggerClientEvent("vorpCoreClient:subWeapon", _target, weaponId)
		end

		TriggerClientEvent('vorp:ShowAdvancedRightNotification', _source, T.youReceivedWeapon, "inventory_items",
			weaponName, "COLOR_PURE_WHITE", 4000)

		TriggerClientEvent("vorpInventory:receiveWeapon", _source, weaponId, weaponPropietary, weaponName, weaponAmmo)
	end
end

InventoryAPI.subWeapon = function(player, weaponId)
	local _source = player

	if not _source then
		Log.error("InventoryAPI.subWeapon: specify a source")
		return
	end

	local User = Core.getUser(_source)

	if not User then
		Log.error("InventoryAPI.subWeapon: User dont exist ")
		return
	end

	local charId = User.getUsedCharacter.charIdentifier
	local userWeapons = UsersWeapons["default"]

	if (userWeapons[weaponId]) then
		userWeapons[weaponId]:setPropietary('')

		MySQL.update("UPDATE loadout SET identifier = @identifier, charidentifier = @charid WHERE id = @id",
			{
				['identifier'] = '',
				['charid'] = charId,
				['id'] = weaponId
			}, function()
			end)
	end

	TriggerClientEvent("vorpCoreClient:subWeapon", _source, weaponId)
end

-- inventory total items count
InventoryAPI.getUserTotalCount = function(identifier, charid)
	local userTotalItemCount = 0
	local userInventory = UsersInventories["default"][identifier]
	for _, item in pairs(userInventory) do
		if item:getCount() == nil then
			userInventory[item:getId()] = nil
			DbService.DeleteItem(charid, item:getId())
		else
			userTotalItemCount = userTotalItemCount + item:getCount()
		end
	end
	return userTotalItemCount
end

InventoryAPI.getUserTotalCountWeapons = function(identifier, charId)
	local userTotalWeaponCount = 0
	for _, weapon in pairs(UsersWeapons["default"]) do
		if weapon:getPropietary() == identifier and weapon:getCharId() == charId then
			if not contains(Config.notweapons, string.upper(weapon:getName())) then
				userTotalWeaponCount = userTotalWeaponCount + 1
			end
		end
	end
	return userTotalWeaponCount
end

InventoryAPI.onNewCharacter = function(playerId)
	Wait(5000)
	local player = Core.getUser(playerId)

	if not player then
		if Config.Debug then
			Log.print("Player [^2" .. playerId .. "^7] ^1 was not found^7")
		end
		return
	end

	for key, value in pairs(Config.startItems) do
		TriggerEvent("vorpCore:addItem", playerId, tostring(key), tonumber(value), {})
	end

	for key, value in pairs(Config.startWeapons) do
		local auxBullets = {}
		local receivedBullets = {}
		local weaponConfig = nil

		for _, wpc in pairs(Config.Weapons) do
			if wpc.HashName == key then
				weaponConfig = wpc
				break
			end
		end

		if weaponConfig then
			local ammoHash = weaponConfig["AmmoHash"]

			if ammoHash then
				for ammohashKey, ammohashValue in pairs(ammoHash) do
					auxBullets[ammohashKey] = ammohashValue
				end
			end
		end

		for bulletKey, bulletValue in pairs(value) do
			if auxBullets[bulletKey] then
				receivedBullets[bulletKey] = tonumber(bulletValue)
			end
		end

		TriggerEvent("vorpCore:registerWeapon", playerId, key, receivedBullets)
	end
end

InventoryAPI.registerInventory = function(id, name, limit, acceptWeapons, shared, ignoreItemStackLimit, whitelistItems,
										  UsePermissions, UseBlackList, whitelistWeapons)
	limit = limit and limit or -1
	ignoreItemStackLimit = ignoreItemStackLimit and ignoreItemStackLimit or false
	acceptWeapons = acceptWeapons == nil and true or acceptWeapons
	whitelistItems = whitelistItems and whitelistItems or false
	shared = shared and shared or false
	UsePermissions = UsePermissions and UsePermissions or false
	UseBlackList = UseBlackList and UseBlackList or false
	whitelistWeapons = whitelistWeapons and whitelistWeapons or false

	if CustomInventoryInfos[id] then
		return
	end

	CustomInventoryInfos[id] = {
		name = name,
		limit = limit,
		acceptWeapons = acceptWeapons,
		shared = shared,
		ignoreItemStackLimit = ignoreItemStackLimit,
		whitelistItems = whitelistItems,
		limitedItems = {},
		PermissionTakeFrom = {},   -- for permissions
		PermissionMoveTo = {},     -- for permissions
		UsePermissions = UsePermissions, -- allow or not
		UseBlackList = UseBlackList,
		BlackListItems = {},
		whitelistWeapons = whitelistWeapons,
		limitedWeapons = {},
	}
	UsersInventories[id] = {}
	if UsersWeapons[id] == nil then
		UsersWeapons[id] = {}
	end

	if Config.Debug then
		Wait(9000) -- so it doesn't print everywhere in the console
		Log.print("Custom inventory[^3" .. id .. "^7] ^2Registered!^7")
	end
end



InventoryAPI.AddPermissionMoveToCustom = function(id, jobName, grade)
	if not CustomInventoryInfos[id] then
		return -- dont add
	end

	if not jobName and not grade then
		return -- dont add
	end
	if Config.Debug then
		Log.print("AdPermsMoveTo  for [^3" .. jobName .. "^7] and grade [^3" .. grade .. "^7]")
	end

	CustomInventoryInfos[id].PermissionMoveTo[jobName] = grade -- create table with item name and count
end

InventoryAPI.AddPermissionTakeFromCustom = function(id, jobName, grade)
	if not CustomInventoryInfos[id] then
		return -- dont add
	end

	if not jobName and not grade then
		return -- dont add
	end
	if Config.Debug then
		Log.print("AdPermsTakeFrom  for [^3" .. jobName .. "^7] and grade [^3" .. grade .. "^7]")
	end
	CustomInventoryInfos[id].PermissionTakeFrom[jobName] = grade -- create table with item name and count
end

InventoryAPI.BlackListCustom = function(id, name)
	if not CustomInventoryInfos[id] then
		return -- dont add
	end

	if not name then
		return -- dont add
	end
	if Config.Debug then
		Log.print("Blacklisted [^3" .. name .. "^7]")
	end
	CustomInventoryInfos[id].BlackListItems[name] = name
end



InventoryAPI.removeInventory = function(id, name)
	if CustomInventoryInfos[id] == nil then
		return
	end

	CustomInventoryInfos[id] = nil
	UsersInventories[id] = nil
	UsersWeapons[id] = nil

	if Config.Debug then
		Wait(9000) -- so it doesn't print everywhere in the console
		Log.print("Custom inventory[^3" .. id .. "^7] ^2Removed!^7")
	end
end

InventoryAPI.setCustomInventoryItemLimit = function(id, itemName, limit)
	if CustomInventoryInfos[id] == nil or itemName == nil or limit == nil then
		return
	end

	CustomInventoryInfos[id].limitedItems[string.lower(itemName)] = limit -- create table with item name and count

	if Config.Debug then
		Wait(9000) -- so it doesn't print everywhere in the console
		Log.print("Custom inventory[^3" .. id .. "^7] set item[^3" .. itemName .. "^7] limit to ^2" .. limit .. "^7")
	end
end

InventoryAPI.setCustomInventoryWeaponLimit = function(id, wepName, limit)
	if CustomInventoryInfos[id] == nil or wepName == nil or limit == nil then
		return
	end

	CustomInventoryInfos[id].limitedWeapons[string.lower(wepName)] = limit -- create table with item name and count

	if Config.Debug then
		Wait(9000) -- so it doesn't print everywhere in the console
		Log.print("Custom inventory[^3" .. id .. "^7] set item[^3" .. wepName .. "^7] limit to ^2" .. limit .. "^7")
	end
end

InventoryAPI.reloadInventory = function(player, id)
	local _source = player

	local invData = CustomInventoryInfos[id]
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local sourceIdentifier = sourceCharacter.identifier
	local sourceCharIdentifier = sourceCharacter.charIdentifier

	local userInventory = {}
	local itemList = {}

	if invData.shared then
		userInventory = UsersInventories[id]
	else
		userInventory = UsersInventories[id][sourceIdentifier]
	end

	-- arrange userInventory as a list
	for _, value in pairs(userInventory) do
		itemList[#itemList + 1] = value
	end

	-- Add weapons as Item to inventory
	for weaponId, weapon in pairs(UsersWeapons[id]) do
		if invData.shared or weapon.charId == sourceCharIdentifier then
			itemList[#itemList + 1] = Item:New({
				id = weaponId,
				count = 1,
				name = weapon.name,
				label = weapon.name,
				limit = 1,
				type = "item_weapon",
				desc = weapon.desc
			})
		end
	end

	local payload = {
		itemList = itemList,
		action = "setSecondInventoryItems"
	}

	TriggerClientEvent("vorp_inventory:ReloadCustomInventory", _source, json.encode(payload))
end

InventoryAPI.openCustomInventory = function(player, id)
	local _source = player
	if CustomInventoryInfos[id] == nil or UsersInventories[id] == nil then
		return
	end

	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local charIdentifier = sourceCharacter.charIdentifier
	local capacity = CustomInventoryInfos[id].limit > 0 and tostring(CustomInventoryInfos[id].limit) or 'oo'

	if CustomInventoryInfos[id].shared then
		if UsersInventories[id] and #UsersInventories[id] > 0 then
			TriggerClientEvent("vorp_inventory:OpenCustomInv", _source, CustomInventoryInfos[id].name, id, capacity)
			InventoryAPI.reloadInventory(_source, id)
		else
			DbService.GetSharedInventory(id, function(inventory)
				local characterInventory = {}

				for _, item in pairs(inventory) do
					if svItems[item.item] ~= nil then
						local dbItem = svItems[item.item]
						characterInventory[item.id] = Item:New({
							count = tonumber(item.amount),
							id = item.id,
							limit = dbItem.limit,
							label = dbItem.label,
							metadata = SharedUtils.MergeTables(dbItem.metadata, item.metadata),
							name = dbItem.item,
							type = dbItem.type,
							canUse = dbItem.usable,
							canRemove = dbItem.can_remove,
							createdAt = item.created_at,
							owner = item.character_id,
							desc = dbItem.desc
						})
					end
				end

				UsersInventories[id] = characterInventory
				TriggerClientEvent("vorp_inventory:OpenCustomInv", _source, CustomInventoryInfos[id].name, id, capacity)
				InventoryAPI.reloadInventory(_source, id)
			end)
		end
	else
		if UsersInventories[id][identifier] then
			TriggerClientEvent("vorp_inventory:OpenCustomInv", _source, CustomInventoryInfos[id].name, id, capacity)
			InventoryAPI.reloadInventory(_source, id)
		else
			DbService.GetInventory(charIdentifier, id, function(inventory)
				local characterInventory = {}
				for _, item in pairs(inventory) do
					if svItems[item.item] ~= nil then
						local dbItem = svItems[item.item]
						characterInventory[item.id] = Item:New({
							count = tonumber(item.amount),
							id = item.id,
							limit = dbItem.limit,
							label = dbItem.label,
							metadata = SharedUtils.MergeTables(dbItem.metadata, item.metadata),
							name = dbItem.item,
							type = dbItem.type,
							canUse = dbItem.usable,
							canRemove = dbItem.can_remove,
							createdAt = item.created_at,
							owner = charIdentifier,
							desc = dbItem.desc
						})
					end
				end

				UsersInventories[id][identifier] = characterInventory
				TriggerClientEvent("vorp_inventory:OpenCustomInv", _source, CustomInventoryInfos[id].name, id, capacity)
				InventoryAPI.reloadInventory(_source, id)
			end)
		end
	end
end

InventoryAPI.closeCustomInventory = function(player, id)
	local _source = player
	if CustomInventoryInfos[id] == nil then
		return
	end
	TriggerClientEvent("vorp_inventory:CloseCustomInv", _source)
end
