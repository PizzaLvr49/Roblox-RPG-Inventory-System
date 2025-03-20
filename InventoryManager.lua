local EnchantmentSystem = require(script.Parent.EnchantmentSystem)

local InventoryManager = {}

-- Items come in different rarities, from basic to legendary
InventoryManager.Rarities = {
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Legendary"
}

-- The basic structure for player inventories
InventoryManager.DefaultInventory = {
	Items = {},
	MaxItems = 20,
	Owner = ""
}

-- Creates a fresh inventory for a player
function InventoryManager.CreateInventory(maxItems: number, owner: string?)
	local inventory = table.clone(InventoryManager.DefaultInventory)
	inventory.Items = {}
	inventory.MaxItems = maxItems or 20
	inventory.Owner = owner or ""

	return inventory
end

-- Makes a deep copy of an item to avoid reference problems
function InventoryManager.CloneItem(item)
	if type(item) ~= "table" then
		return item
	end

	local clone = {}
	for key, value in pairs(item) do
		if type(value) == "table" then
			clone[key] = InventoryManager.CloneItem(value)
		else
			clone[key] = value
		end
	end

	return clone
end

-- Adds an item to a player's inventory
function InventoryManager.AddItem(inventory, item)
	if #inventory.Items >= inventory.MaxItems then
		return false, "Inventory is full"
	end

	-- Make a copy so we don't mess with the original
	local itemClone = InventoryManager.CloneItem(item)

	-- Put it in the bag
	table.insert(inventory.Items, itemClone)
	return true
end

-- Takes an item out of the inventory
function InventoryManager.RemoveItem(inventory, index)
	if index < 1 or index > #inventory.Items then
		return false, "Invalid inventory index"
	end

	table.remove(inventory.Items, index)
	return true
end

-- Searches through inventory for items matching specific criteria
function InventoryManager.FindItems(inventory, criteria)
	local results = {}

	for i, item in ipairs(inventory.Items) do
		local matches = true

		for key, value in pairs(criteria) do
			-- Handle nested properties like weapon.Damage
			if type(value) == "table" then
				for componentName, componentProps in pairs(value) do
					if type(componentProps) == "table" and item[componentName] then
						for propName, propValue in pairs(componentProps) do
							if item[componentName][propName] ~= propValue then
								matches = false
								break
							end
						end
					else
						matches = false
					end

					if not matches then
						break
					end
				end
				-- Handle top-level properties like DisplayName
			elseif item[key] ~= value then
				matches = false
				break
			end
		end

		if matches then
			table.insert(results, {Index = i, Item = item})
		end
	end

	return results
end

-- Organizes inventory items however you want
function InventoryManager.SortItems(inventory, sortBy, ascending)
	ascending = ascending ~= false -- Default to ascending unless specified

	table.sort(inventory.Items, function(a, b)
		local valueA, valueB

		-- If we're sorting by a component property like weapon.Damage
		if type(sortBy) == "table" and #sortBy == 2 then
			local componentName, propertyName = sortBy[1], sortBy[2]

			if a[componentName] and b[componentName] then
				valueA = a[componentName][propertyName]
				valueB = b[componentName][propertyName]
			else
				return false
			end
			-- If we're sorting by a direct property like DisplayName
		else
			valueA = a[sortBy]
			valueB = b[sortBy]
		end

		-- Handle cases where properties might be missing
		if valueA == nil and valueB == nil then
			return false
		elseif valueA == nil then
			return not ascending
		elseif valueB == nil then
			return ascending
		end

		-- Put items in the right order
		if ascending then
			return valueA < valueB
		else
			return valueA > valueB
		end
	end)

	return true
end

-- Moves items between inventories (trading, storage, etc.)
function InventoryManager.TransferItem(fromInventory, toInventory, itemIndex)
	if itemIndex < 1 or itemIndex > #fromInventory.Items then
		return false, "Invalid source inventory index"
	end

	if #toInventory.Items >= toInventory.MaxItems then
		return false, "Destination inventory is full"
	end

	local item = fromInventory.Items[itemIndex]
	local success = InventoryManager.AddItem(toInventory, item)

	if success then
		InventoryManager.RemoveItem(fromInventory, itemIndex)
		return true
	else
		return false, "Failed to add item to destination inventory"
	end
end

-- Pre-designed items that can be spawned into the game
InventoryManager.DefaultItems = {}

-- Adds a new template item to our catalog
function InventoryManager.RegisterDefaultItem(itemId, itemType, properties, rarity)
	-- Create the item using the enchantment system
	local item = EnchantmentSystem.CreateItem(itemType, properties)

	-- Tag it with metadata
	item.Id = itemId
	item.Rarity = rarity or "Common"

	-- Add it to our available templates
	InventoryManager.DefaultItems[itemId] = item

	return item
end


-- Get an item by its ID
function InventoryManager.GetItemById(inventory, itemId)
	for i, item in ipairs(inventory.Items) do
		if item.Id == itemId then
			return item, i
		end
	end
	return nil, nil
end

-- Add gold to inventory
function InventoryManager.AddGold(inventory, amount)
	inventory.Gold = inventory.Gold + amount
	return inventory.Gold
end

-- Remove gold from inventory
function InventoryManager.RemoveGold(inventory, amount)
	if inventory.Gold < amount then
		return false, "Not enough gold"
	end

	inventory.Gold = inventory.Gold - amount
	return true, inventory.Gold
end

-- Calculate item value based on rarity and enchantments
function InventoryManager.CalculateItemValue(item)
	local rarityValues = {
		Common = 10,
		Uncommon = 25,
		Rare = 75,
		Epic = 200,
		Legendary = 500
	}

	local baseValue = rarityValues[item.Rarity] or 10

	-- Add value for enchantments
	local enchantmentValue = 0
	if item.enchantable and item.enchantable.Enchantments then
		for enchantName, level in pairs(item.enchantable.Enchantments) do
			enchantmentValue = enchantmentValue + (level * 20)
		end
	end

	return baseValue + enchantmentValue
end

return InventoryManager
