--!strict
local EnchantmentSystem = {}

-- Component registry
EnchantmentSystem.Components = {}

-- Item type registry
EnchantmentSystem.ItemTypes = {}

-- Enchantment registry
EnchantmentSystem.Enchantments = {}

-- Register a component type with its default properties
function EnchantmentSystem.RegisterComponent(componentName: string, defaultProperties: {[string]: any})
	EnchantmentSystem.Components[componentName] = defaultProperties
	print("Registered component: " .. componentName)
end

-- Register default components
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

-- Function to create a component
function EnchantmentSystem.CreateComponent(componentName: string, properties: {[string]: any})
	if not EnchantmentSystem.Components[componentName] then
		error("Unknown component: " .. componentName)
	end

	-- Create a new component based on default properties
	local component = table.clone(EnchantmentSystem.Components[componentName])

	-- Apply custom properties
	for key, value in pairs(properties or {}) do
		component[key] = value
	end

	return component
end

-- Function to register a new item type with its components
function EnchantmentSystem.RegisterItemType(typeName: string, components: {string}, defaultProperties: {[string]: any})
	local typeDefinition = {
		Components = components,
		DefaultProperties = defaultProperties or {}
	}

	EnchantmentSystem.ItemTypes[typeName] = typeDefinition
	print("Registered item type: " .. typeName)
end

-- Function to create a new item
function EnchantmentSystem.CreateItem(typeName: string, properties: {[string]: any})
	if not EnchantmentSystem.ItemTypes[typeName] then
		error("Unknown item type: " .. typeName)
	end

	local typeDefinition = EnchantmentSystem.ItemTypes[typeName]
	local item = {
		Type = typeName,
		DisplayName = properties.DisplayName or typeName
	}

	-- Add base properties
	for key, value in pairs(typeDefinition.DefaultProperties) do
		item[key] = value
	end

	-- Apply custom properties
	for key, value in pairs(properties or {}) do
		if key ~= "Components" then -- Avoid overriding components
			item[key] = value
		end
	end

	-- Create and attach components
	for _, componentName in ipairs(typeDefinition.Components) do
		local componentProperties = (properties and properties.Components and properties.Components[componentName]) or {}
		item[string.lower(componentName)] = EnchantmentSystem.CreateComponent(componentName, componentProperties)
	end

	return item
end

-- Function to register a new enchantment
function EnchantmentSystem.RegisterEnchantment(name: string, config: {
	MaxLevel: number,
	ValidTypes: {string},
	RequiredComponents: {string},
	Effects: {[string]: any}
	})
	EnchantmentSystem.Enchantments[name] = config
	print("Registered enchantment: " .. name)
end

-- Function to check if an item can have a specific enchantment
function EnchantmentSystem.CanEnchantItemWith(item: any, enchantName: string): boolean
	local enchantData = EnchantmentSystem.Enchantments[enchantName]

	-- Check if enchantment exists
	if not enchantData then
		return false
	end

	-- Check if item has enchantable component
	if not item.enchantable then
		return false
	end

	-- Check if item type is valid for this enchantment
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

	-- Check if item has all required components
	for _, componentName in ipairs(enchantData.RequiredComponents or {}) do
		local lowerComponentName = string.lower(componentName)
		if not item[lowerComponentName] then
			return false
		end
	end

	return true
end

-- Function to enchant an item
function EnchantmentSystem.EnchantItem(item: any, enchantName: string, level: number): boolean
	-- Check if we can enchant this item
	if not EnchantmentSystem.CanEnchantItemWith(item, enchantName) then
		warn("Cannot enchant " .. item.DisplayName .. " with " .. enchantName)
		return false
	end

	-- Check if level is valid
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

	-- Apply enchantment effects
	EnchantmentSystem.ApplyEnchantmentEffects(item)

	print("Successfully enchanted " .. item.DisplayName .. " with " .. enchantName .. " " .. level)
	return true
end

-- Function to remove an enchantment
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

-- Function to apply all enchantment effects to an item
function EnchantmentSystem.ApplyEnchantmentEffects(item: any)
	-- Reset all components to their base values
	local typeDefinition = EnchantmentSystem.ItemTypes[item.Type]

	for _, componentName in ipairs(typeDefinition.Components) do
		local lowerComponentName = string.lower(componentName)
		local component = item[lowerComponentName]
		local baseComponent = EnchantmentSystem.Components[componentName]

		-- Keep track of base values for stats
		if not component.BaseValues then
			component.BaseValues = {}
			for key, value in pairs(component) do
				if type(value) == "number" then
					component.BaseValues[key] = value
				end
			end
		end

		-- Reset to base values
		for key, baseValue in pairs(component.BaseValues) do
			component[key] = baseValue
		end
	end

	-- If no enchantments, just return
	if not item.enchantable or not item.enchantable.Enchantments then
		return
	end

	-- Clear custom effects
	item.customEffects = {}

	-- For each enchantment on the item
	for enchantName, level in pairs(item.enchantable.Enchantments) do
		local enchantData = EnchantmentSystem.Enchantments[enchantName]

		-- Skip if enchantment data doesn't exist
		if not enchantData or not enchantData.Effects then
			continue
		end

		-- Apply effects to each component
		for componentName, effects in pairs(enchantData.Effects) do
			if componentName == "Custom" then
				-- Handle custom effects
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
						-- Skip if this stat doesn't exist on the component
						if component[statName] == nil then
							continue
						end

						-- Apply multiplier if it exists for this level
						if effect.Multiplier and effect.Multiplier[level] then
							component[statName] = component[statName] * effect.Multiplier[level]
						end

						-- Apply additive modifier if it exists for this level
						if effect.Modifier and effect.Modifier[level] then
							component[statName] = component[statName] + effect.Modifier[level]
						end
					end
				end
			end
		end
	end
end

-- Function to get all possible enchantments for an item
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

-- Register default item types
EnchantmentSystem.RegisterItemType("Sword", {
	"Breakable", 
	"Enchantable", 
	"Weapon"
}, {
	DisplayName = "Sword"
})

EnchantmentSystem.RegisterItemType("Bow", {
	"Breakable", 
	"Enchantable", 
	"Weapon", 
	"Ranged"
}, {
	DisplayName = "Bow"
})

EnchantmentSystem.RegisterItemType("Wand", {
	"Breakable", 
	"Enchantable", 
	"Magical"
}, {
	DisplayName = "Wand"
})

EnchantmentSystem.RegisterItemType("Armor", {
	"Breakable", 
	"Enchantable", 
	"Defensive"
}, {
	DisplayName = "Armor"
})

-- Register default enchantments
EnchantmentSystem.RegisterEnchantment("Sharpness", {
	MaxLevel = 5,
	ValidTypes = {"Sword"},
	RequiredComponents = {"Weapon"},
	Effects = {
		Weapon = {
			Damage = {
				Modifier = {2, 4, 6, 8, 10}
			}
		}
	}
})

EnchantmentSystem.RegisterEnchantment("Power", {
	MaxLevel = 5,
	ValidTypes = {"Bow"},
	RequiredComponents = {"Weapon", "Ranged"},
	Effects = {
		Weapon = {
			Damage = {
				Multiplier = {1.2, 1.4, 1.6, 1.8, 2.0}
			}
		}
	}
})

EnchantmentSystem.RegisterEnchantment("Infinity", {
	MaxLevel = 1,
	ValidTypes = {"Bow"},
	RequiredComponents = {"Ranged"},
	Effects = {
		Custom = {
			InfiniteAmmo = {true}
		}
	}
})

EnchantmentSystem.RegisterEnchantment("Protection", {
	MaxLevel = 4,
	ValidTypes = {"Armor"},
	RequiredComponents = {"Defensive"},
	Effects = {
		Defensive = {
			Defense = {
				Multiplier = {1.1, 1.2, 1.3, 1.4}
			}
		}
	}
})

EnchantmentSystem.RegisterEnchantment("ManaEfficiency", {
	MaxLevel = 3,
	ValidTypes = {"Wand"},
	RequiredComponents = {"Magical"},
	Effects = {
		Magical = {
			ManaCost = {
				Modifier = {-2, -4, -6}
			}
		}
	}
})

EnchantmentSystem.RegisterEnchantment("ElementalFocus", {
	MaxLevel = 5,
	ValidTypes = {"Wand"},
	RequiredComponents = {"Magical"},
	Effects = {
		Magical = {
			MagicDamage = {
				Multiplier = {1.1, 1.2, 1.3, 1.4, 1.5}
			}
		},
		Custom = {
			ElementalDamage = {2, 4, 6, 8, 10}
		}
	}
})

EnchantmentSystem.RegisterEnchantment("Unbreaking", {
	MaxLevel = 3,
	ValidTypes = {"Sword", "Bow", "Armor", "Wand"},
	RequiredComponents = {"Breakable"},
	Effects = {
		Breakable = {
			Durability = {
				Multiplier = {1.5, 2.0, 3.0}
			},
			MaxDurability = {
				Multiplier = {1.5, 2.0, 3.0}
			}
		}
	}
})

return EnchantmentSystem
