--!strict

local InventoryManager = {}

-- List of all enchants that can be applied and their max level

InventoryManager.DefaultItems = {} :: {[string]: InventoryItem}

InventoryManager.Enchants = {
	["Sharpness"] = {
		MaxLevel = 5,
		Types = {"Sword"}
	},
	["Protection"] = {
		MaxLevel = 5,
		Types = {"Armor"}
	}
} :: {[string]: {MaxLevel: number, Types: {string}}}

InventoryManager.Rarities = {
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Legendary",
}

-- Base type for items

export type InventoryItem = {
	DisplayName: string,
	Id: string,
	Image: string,
	Rarity: string,
	Type: string
}

export type Inventory = {
	Items: {InventoryItem},
	MaxItems: number
}

function InventoryManager.CreateInventory(maxItems: number, itemNames: {string}?, items: {InventoryItem}?)
	local inventory = {} :: Inventory
	inventory.MaxItems = maxItems
	local itemsFromNames = {}

	if itemNames then
		for _, name in pairs(itemNames) do
			local item = InventoryManager.DefaultItems[name]
			if item then
				-- Clone the item to avoid shared references
				local clonedItem = InventoryManager.CloneItem(item)
				table.insert(itemsFromNames, clonedItem)
			else
				warn("Item not found: " .. name)
			end
		end
	end

	inventory.Items = items or itemsFromNames
	return inventory
end

-- Helper function to clone an item - properly handles tables with string keys
function InventoryManager.CloneItem(item: any): any
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

function InventoryManager.AddItemToInventory(inventory: Inventory, itemName: string?, item: InventoryItem?): (boolean, string?)
	local itemToPut

	if itemName then
		itemToPut = InventoryManager.DefaultItems[itemName]
		if not itemToPut then
			return false, "Item with name '" .. itemName .. "' not found"
		end
		-- Clone the item
		itemToPut = InventoryManager.CloneItem(itemToPut)
	elseif item then
		itemToPut = InventoryManager.CloneItem(item)
	else
		return false, "You have to pass either itemName or item"
	end

	if #inventory.Items < inventory.MaxItems then
		table.insert(inventory.Items, itemToPut)
		return true
	else
		return false, "Inventory is full"
	end
end

-- Add function to remove items from inventory
function InventoryManager.RemoveItemFromInventory(inventory: Inventory, index: number): (boolean, string?)
	if index < 1 or index > #inventory.Items then
		return false, "Invalid index"
	end

	table.remove(inventory.Items, index)
	return true
end

-- Add function to search for items in inventory
function InventoryManager.FindItemsInInventory(inventory: Inventory, criteria: {[string]: any}): {InventoryItem}
	local results = {}

	for _, item in ipairs(inventory.Items) do
		local match = true
		for key, value in pairs(criteria) do
			if item[key] ~= value then
				match = false
				break
			end
		end

		if match then
			table.insert(results, item)
		end
	end

	return results
end

return InventoryManager
