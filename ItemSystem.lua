local Players = game:GetService("Players")

-- Create our main module that will integrate both systems
local ItemSystem = {}

-- Import the component systems
local EnchantmentSystem = require(script.Parent.EnchantmentSystem)
local InventoryManager = require(script.Parent.InventoryManager)

-- Core registries for our system
EnchantmentSystem.Components = {}
EnchantmentSystem.ItemTypes = {}
EnchantmentSystem.Enchantments = {}

-- Register a component type with its default properties
function EnchantmentSystem.RegisterComponent(componentName: string, defaultProperties: {[string]: any})
	EnchantmentSystem.Components[componentName] = defaultProperties
	print("Registered component: " .. componentName)
end

-- Register core components
EnchantmentSystem.RegisterComponent("Breakable", {
	Durability = 100,
	MaxDurability = 100,
	CanBreak = true
})

EnchantmentSystem.RegisterComponent("Enchantable", {
	Enchantments = {},
	MaxEnchantments = 3
})

EnchantmentSystem.RegisterComponent("Weapon", {
	Damage = 10,
	AttackSpeed = 1.0
})

EnchantmentSystem.RegisterComponent("Ranged", {
	Range = 50,
	ProjectileSpeed = 20
})

EnchantmentSystem.RegisterComponent("Magical", {
	MagicDamage = 8,
	ManaCost = 10,
	CooldownTime = 1.0
})

EnchantmentSystem.RegisterComponent("Defensive", {
	Defense = 5,
	Weight = 10
})

-- Create a component with custom properties
function EnchantmentSystem.CreateComponent(componentName: string, properties: {[string]: any})
	if not EnchantmentSystem.Components[componentName] then
		error("Unknown component: " .. componentName)
	end

	-- Start with the default properties
	local component = table.clone(EnchantmentSystem.Components[componentName])

	-- Override with any custom properties
	for key, value in pairs(properties or {}) do
		component[key] = value
	end

	return component
end

-- Register a new item type that's built from components
function EnchantmentSystem.RegisterItemType(typeName: string, components: {string}, defaultProperties: {[string]: any})
	local typeDefinition = {
		Components = components,
		DefaultProperties = defaultProperties or {}
	}

	EnchantmentSystem.ItemTypes[typeName] = typeDefinition
	print("Registered item type: " .. typeName)
end

-- Create a new item instance of a registered type
function EnchantmentSystem.CreateItem(typeName: string, properties: {[string]: any})
	if not EnchantmentSystem.ItemTypes[typeName] then
		error("Unknown item type: " .. typeName)
	end

	local typeDefinition = EnchantmentSystem.ItemTypes[typeName]
	local item = {
		Type = typeName,
		DisplayName = properties.DisplayName or typeName,
		Id = properties.Id or typeName .. "_" .. tostring(os.time() + math.random(1, 10000)),
		Rarity = properties.Rarity or "Common"
	}

	-- Set up base properties from the type definition
	for key, value in pairs(typeDefinition.DefaultProperties) do
		item[key] = value
	end

	-- Apply any custom properties passed in
	for key, value in pairs(properties or {}) do
		if key ~= "Components" then -- Don't override components directly
			item[key] = value
		end
	end

	-- Create and attach each component
	for _, componentName in ipairs(typeDefinition.Components) do
		local componentProperties = (properties and properties.Components and properties.Components[componentName]) or {}
		item[string.lower(componentName)] = EnchantmentSystem.CreateComponent(componentName, componentProperties)
	end

	return item
end

-- Register a new enchantment with its effects
function EnchantmentSystem.RegisterEnchantment(name: string, config: {
	MaxLevel: number,
	ValidTypes: {string},
	RequiredComponents: {string},
	Effects: {[string]: any}
	})
	EnchantmentSystem.Enchantments[name] = config
	print("Registered enchantment: " .. name)
end

-- Check if an item can receive a specific enchantment
function EnchantmentSystem.CanEnchantItemWith(item: any, enchantName: string): boolean
	local enchantData = EnchantmentSystem.Enchantments[enchantName]

	-- Basic validation checks
	if not enchantData then
		return false
	end

	if not item.enchantable then
		return false
	end

	-- Check if the item's type is allowed for this enchantment
	local validType = false
	for _, itemType in ipairs(enchantData.ValidTypes) do
		if item.Type == itemType then
			validType = true
			break
		end
	end

	if not validType then
		return false
	end

	-- Make sure the item has all required components
	for _, componentName in ipairs(enchantData.RequiredComponents or {}) do
		local lowerComponentName = string.lower(componentName)
		if not item[lowerComponentName] then
			return false
		end
	end

	return true
end

-- Apply an enchantment to an item
function EnchantmentSystem.EnchantItem(item: any, enchantName: string, level: number): boolean
	-- Check compatibility first
	if not EnchantmentSystem.CanEnchantItemWith(item, enchantName) then
		warn("Cannot enchant " .. item.DisplayName .. " with " .. enchantName)
		return false
	end

	-- Validate enchantment level
	local enchantData = EnchantmentSystem.Enchantments[enchantName]
	if level < 1 or level > enchantData.MaxLevel then
		warn("Invalid enchantment level: " .. level .. " (Max: " .. enchantData.MaxLevel .. ")")
		return false
	end

	-- Check max enchantments limit
	local currentCount = 0
	for _ in pairs(item.enchantable.Enchantments) do
		currentCount = currentCount + 1
	end

	if currentCount >= item.enchantable.MaxEnchantments and not item.enchantable.Enchantments[enchantName] then
		warn("Item has reached maximum number of enchantments: " .. item.enchantable.MaxEnchantments)
		return false
	end

	-- Add the enchantment
	item.enchantable.Enchantments[enchantName] = level

	-- Apply the effects
	EnchantmentSystem.ApplyEnchantmentEffects(item)

	print("Successfully enchanted " .. item.DisplayName .. " with " .. enchantName .. " " .. level)
	return true
end

-- Remove an enchantment from an item
function EnchantmentSystem.RemoveEnchantment(item: any, enchantName: string): boolean
	if not item.enchantable or not item.enchantable.Enchantments[enchantName] then
		return false
	end

	-- Remove the enchantment
	item.enchantable.Enchantments[enchantName] = nil

	-- Recalculate all effects
	EnchantmentSystem.ApplyEnchantmentEffects(item)

	print("Removed " .. enchantName .. " from " .. item.DisplayName)
	return true
end

-- Apply all enchantment effects to an item (recalculates everything)
function EnchantmentSystem.ApplyEnchantmentEffects(item: any)
	-- Reset all components to their base values
	local typeDefinition = EnchantmentSystem.ItemTypes[item.Type]

	for _, componentName in ipairs(typeDefinition.Components) do
		local lowerComponentName = string.lower(componentName)
		local component = item[lowerComponentName]
		local baseComponent = EnchantmentSystem.Components[componentName]

		-- Store base values first time if needed
		if not component.BaseValues then
			component.BaseValues = {}
			for key, value in pairs(component) do
				if type(value) == "number" then
					component.BaseValues[key] = value
				end
			end
		end

		-- Reset everything to base values
		for key, baseValue in pairs(component.BaseValues) do
			component[key] = baseValue
		end
	end

	-- If no enchantments, we're done
	if not item.enchantable or not item.enchantable.Enchantments then
		return
	end

	-- Clear custom effects
	item.customEffects = {}

	-- Apply each enchantment's effects
	for enchantName, level in pairs(item.enchantable.Enchantments) do
		local enchantData = EnchantmentSystem.Enchantments[enchantName]

		-- Skip if enchantment data is missing
		if not enchantData or not enchantData.Effects then
			continue
		end

		-- Apply effects to each affected component
		for componentName, effects in pairs(enchantData.Effects) do
			if componentName == "Custom" then
				-- Handle custom effects that don't map to components
				for effectName, valueLevels in pairs(effects) do
					if valueLevels[level] ~= nil then
						item.customEffects = item.customEffects or {}
						item.customEffects[effectName] = valueLevels[level]
					end
				end
			else
				-- Handle component effects
				local lowerComponentName = string.lower(componentName)
				local component = item[lowerComponentName]

				if component then
					for statName, effect in pairs(effects) do
						-- Skip if this stat doesn't exist
						if component[statName] == nil then
							continue
						end

						-- Apply multipliers first
						if effect.Multiplier and effect.Multiplier[level] then
							component[statName] = component[statName] * effect.Multiplier[level]
						end

						-- Then apply flat modifiers
						if effect.Modifier and effect.Modifier[level] then
							component[statName] = component[statName] + effect.Modifier[level]
						end
					end
				end
			end
		end
	end
end

-- Get all enchantments that can be applied to an item
function EnchantmentSystem.GetPossibleEnchantments(item: any): {[string]: number}
	local result = {}

	if not item.enchantable then
		return result
	end

	for enchantName, enchantData in pairs(EnchantmentSystem.Enchantments) do
		if EnchantmentSystem.CanEnchantItemWith(item, enchantName) then
			result[enchantName] = enchantData.MaxLevel
		end
	end

	return result
end

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
	Owner = nil, -- Changed from string to nil (will hold player object)
	Gold = 0
}

-- Creates a fresh inventory for a player
function InventoryManager.CreateInventory(maxItems: number, owner: any)
	local inventory = table.clone(InventoryManager.DefaultInventory)
	inventory.Items = {}
	inventory.MaxItems = maxItems or 20
	inventory.Owner = owner or nil -- Store the player object directly
	inventory.Gold = 0

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
	return true, itemClone
end

-- Takes an item out of the inventory
function InventoryManager.RemoveItem(inventory, index)
	if index < 1 or index > #inventory.Items then
		return false, "Invalid inventory index"
	end

	local removedItem = inventory.Items[index]
	table.remove(inventory.Items, index)
	return true, removedItem
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
							if type(propValue) == "function" then
								-- Support for callback functions to do custom checks
								if not propValue(item[componentName][propName]) then
									matches = false
									break
								end
							elseif item[componentName][propName] ~= propValue then
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
	local success, itemClone = InventoryManager.AddItem(toInventory, item)

	if success then
		InventoryManager.RemoveItem(fromInventory, itemIndex)
		return true, itemClone
	else
		return false, "Failed to add item to destination inventory"
	end
end

-- Pre-designed items that can be spawned into the game
InventoryManager.DefaultItems = {}

-- Adds a new template item to our catalog
function InventoryManager.RegisterDefaultItem(itemId, itemType, properties, rarity)
	-- Create the item using the enchantment system
	local itemProperties = properties or {}
	itemProperties.Id = itemId
	itemProperties.Rarity = rarity or "Common"

	local item = EnchantmentSystem.CreateItem(itemType, itemProperties)

	-- Add it to our available templates
	InventoryManager.DefaultItems[itemId] = item

	return item
end

-- Add gold to inventory
function InventoryManager.AddGold(inventory, amount)
	inventory.Gold = (inventory.Gold or 0) + amount
	return inventory.Gold
end

-- Remove gold from inventory
function InventoryManager.RemoveGold(inventory, amount)
	if (inventory.Gold or 0) < amount then
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

-- Combines both systems into a unified API
ItemSystem.Enchantment = EnchantmentSystem
ItemSystem.Inventory = InventoryManager

-- Registration functions combined for easier access
ItemSystem.RegisterItemType = EnchantmentSystem.RegisterItemType
ItemSystem.RegisterComponent = EnchantmentSystem.RegisterComponent
ItemSystem.RegisterEnchantment = EnchantmentSystem.RegisterEnchantment
ItemSystem.RegisterDefaultItem = InventoryManager.RegisterDefaultItem

-- Item creation and manipulation
ItemSystem.CreateItem = EnchantmentSystem.CreateItem
ItemSystem.EnchantItem = EnchantmentSystem.EnchantItem
ItemSystem.RemoveEnchantment = EnchantmentSystem.RemoveEnchantment

-- Inventory management
ItemSystem.CreateInventory = InventoryManager.CreateInventory
ItemSystem.AddItemToInventory = InventoryManager.AddItem
ItemSystem.RemoveItemFromInventory = InventoryManager.RemoveItem
ItemSystem.FindItems = InventoryManager.FindItems
ItemSystem.SortInventory = InventoryManager.SortItems
ItemSystem.TransferItem = InventoryManager.TransferItem

-- Player-based inventory management
ItemSystem.PlayerInventories = {}

function ItemSystem.GetPlayerInventory(player)
	local userId = nil

	-- Handle both Player objects and custom player tables with UserId
	if typeof(player) == "Instance" and player:IsA("Player") then
		userId = player.UserId
	elseif type(player) == "table" and player.UserId then
		userId = player.UserId
	else
		userId = player -- Fallback to using the passed value directly
	end

	if not ItemSystem.PlayerInventories[userId] then
		-- Store the player object (or table) directly
		ItemSystem.PlayerInventories[userId] = InventoryManager.CreateInventory(100, player)
	end

	return ItemSystem.PlayerInventories[userId]
end

return ItemSystem
