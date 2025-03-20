--!strict
local InventoryManager = require(script.Parent.InventoryManager)

-- Import base types from InventoryManager
type InventoryItem = InventoryManager.InventoryItem
type Enchantable = InventoryManager.Enchantable
type Breakable = InventoryManager.Breakable

-- Registry for item types
local ItemTypeRegistry = {}

-- Store type definitions and default values
ItemTypeRegistry.TypeDefinitions = {}
ItemTypeRegistry.DefaultValues = {}

-- Function to register a new item type
function ItemTypeRegistry.RegisterType(typeName: string, defaultValues: {[string]: any})
	if ItemTypeRegistry.TypeDefinitions[typeName] then
		warn("Item type " .. typeName .. " is already registered. Overwriting.")
	end

	-- Register the type
	ItemTypeRegistry.TypeDefinitions[typeName] = true

	-- Store default values
	ItemTypeRegistry.DefaultValues[typeName] = defaultValues

	-- Add to InventoryManager for easy access
	InventoryManager[typeName .. "DefaultValues"] = defaultValues

	print("Registered item type: " .. typeName)
end

-- Generic function to create an item of any registered type
function ItemTypeRegistry.CreateItem(typeName: string, itemData: {[string]: any})
	if not ItemTypeRegistry.TypeDefinitions[typeName] then
		error("Unknown item type: " .. typeName)
	end

	local newItem = table.clone(itemData)

	-- Apply default values for the type
	local defaultValues = ItemTypeRegistry.DefaultValues[typeName]
	for key, value in pairs(defaultValues) do
		if newItem[key] == nil then
			newItem[key] = value
		end
	end

	-- Set the type
	newItem.Type = typeName

	return newItem
end

-- Register built-in item types
ItemTypeRegistry.RegisterType("Sword", InventoryManager.SwordDefaultValues)
ItemTypeRegistry.RegisterType("Armor", InventoryManager.ArmorDefaultValues)

return ItemTypeRegistry
