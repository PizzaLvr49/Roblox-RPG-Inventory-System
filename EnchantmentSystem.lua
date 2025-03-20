--!strict
local EnchantmentSystem = {}

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
		DisplayName = properties.DisplayName or typeName
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

return EnchantmentSystem
