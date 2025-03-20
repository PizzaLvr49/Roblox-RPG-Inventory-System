local EnchantmentSystem = require(script.Parent.EnchantmentSystem)

local InventoryManager = {}

-- Store rarity definitions
InventoryManager.Rarities = {
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Legendary"
}

-- Define inventory object structure
InventoryManager.DefaultInventory = {
	Items = {},
	MaxItems = 20,
	Owner = ""
}

-- Function to create a new inventory
function InventoryManager.CreateInventory(maxItems: number, owner: string?)
	local inventory = table.clone(InventoryManager.DefaultInventory)
	inventory.Items = {}
	inventory.MaxItems = maxItems or 20
	inventory.Owner = owner or ""

	return inventory
end

-- Helper function to clone an item with all components
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

-- Function to add an item to inventory
function InventoryManager.AddItem(inventory, item)
	if #inventory.Items >= inventory.MaxItems then
		return false, "Inventory is full"
	end

	-- Clone the item to avoid reference issues
	local itemClone = InventoryManager.CloneItem(item)

	-- Add to inventory
	table.insert(inventory.Items, itemClone)
	return true
end

-- Function to remove an item from inventory
function InventoryManager.RemoveItem(inventory, index)
	if index < 1 or index > #inventory.Items then
		return false, "Invalid inventory index"
	end

	table.remove(inventory.Items, index)
	return true
end

-- Function to find items in inventory based on criteria
function InventoryManager.FindItems(inventory, criteria)
	local results = {}

	for i, item in ipairs(inventory.Items) do
		local matches = true

		for key, value in pairs(criteria) do
			-- Handle nested component properties
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
				-- Handle direct properties
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

-- Function to sort inventory items by criteria
function InventoryManager.SortItems(inventory, sortBy, ascending)
	ascending = ascending ~= false -- Default to ascending if not specified

	table.sort(inventory.Items, function(a, b)
		local valueA, valueB

		-- Handle component property sorting
		if type(sortBy) == "table" and #sortBy == 2 then
			local componentName, propertyName = sortBy[1], sortBy[2]

			if a[componentName] and b[componentName] then
				valueA = a[componentName][propertyName]
				valueB = b[componentName][propertyName]
			else
				return false
			end
			-- Handle direct property sorting
		else
			valueA = a[sortBy]
			valueB = b[sortBy]
		end

		-- Handle nil values
		if valueA == nil and valueB == nil then
			return false
		elseif valueA == nil then
			return not ascending
		elseif valueB == nil then
			return ascending
		end

		-- Compare based on sort direction
		if ascending then
			return valueA < valueB
		else
			return valueA > valueB
		end
	end)

	return true
end

-- Function to transfer items between inventories
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

-- Generate a table of default items with rarities
InventoryManager.DefaultItems = {}

-- Function to register a default item template
function InventoryManager.RegisterDefaultItem(itemId, itemType, properties, rarity)
	-- Create the item using EnchantmentSystem
	local item = EnchantmentSystem.CreateItem(itemType, properties)

	-- Add metadata
	item.Id = itemId
	item.Rarity = rarity or "Common"

	-- Store in default items
	InventoryManager.DefaultItems[itemId] = item

	return item
end

-- Example default items
InventoryManager.RegisterDefaultItem("basic_sword", "Sword", {
	DisplayName = "Basic Sword"
}, "Common")

InventoryManager.RegisterDefaultItem("hunters_bow", "Bow", {
	DisplayName = "Hunter's Bow",
	Components = {
		Ranged = {
			Range = 60
		}
	}
}, "Uncommon")

InventoryManager.RegisterDefaultItem("enchanted_armor", "Armor", {
	DisplayName = "Enchanted Armor",
	Components = {
		Defensive = {
			Defense = 8
		},
		Enchantable = {
			MaxEnchantments = 5
		}
	}
}, "Rare")

return InventoryManager
