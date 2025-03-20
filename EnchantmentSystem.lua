--!strict
local EnchantmentSystem = {}

-- Store all registered enchantments
EnchantmentSystem.Enchantments = {}

-- Store all registered item types
EnchantmentSystem.ItemTypes = {}

-- Function to register a new item type
function EnchantmentSystem.RegisterItemType(typeName: string, defaultProperties: {[string]: any})
	EnchantmentSystem.ItemTypes[typeName] = defaultProperties
	print("Registered item type: " .. typeName)
end

-- Function to create a new item
function EnchantmentSystem.CreateItem(typeName: string, properties: {[string]: any})
	if not EnchantmentSystem.ItemTypes[typeName] then
		error("Unknown item type: " .. typeName)
	end

	-- Start with default properties for this type
	local newItem = table.clone(EnchantmentSystem.ItemTypes[typeName])

	-- Apply custom properties
	for key, value in pairs(properties) do
		newItem[key] = value
	end

	-- Ensure type is set
	newItem.Type = typeName

	-- Initialize enchantments if enchantable
	if newItem.Enchantable then
		newItem.Enchantments = {}
	end

	return newItem
end

-- Function to register a new enchantment
function EnchantmentSystem.RegisterEnchantment(name: string, config: {
	MaxLevel: number,
	ValidTypes: {string},
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

	-- Check if item is enchantable
	if not item.Enchantable then
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

	return validType
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

	-- Add the enchantment
	item.Enchantments[enchantName] = level

	-- Apply enchantment effects
	EnchantmentSystem.ApplyEnchantmentEffects(item)

	print("Successfully enchanted " .. item.DisplayName .. " with " .. enchantName .. " " .. level)
	return true
end

-- Function to remove an enchantment
function EnchantmentSystem.RemoveEnchantment(item: any, enchantName: string): boolean
	if not item.Enchantments or not item.Enchantments[enchantName] then
		return false
	end

	-- Remove the enchantment
	item.Enchantments[enchantName] = nil

	-- Recalculate all effects
	EnchantmentSystem.ApplyEnchantmentEffects(item)

	print("Removed " .. enchantName .. " from " .. item.DisplayName)
	return true
end

-- Function to apply all enchantment effects to an item
function EnchantmentSystem.ApplyEnchantmentEffects(item: any)
	-- Reset calculated stats to base values
	if item.BaseStats then
		for stat, baseValue in pairs(item.BaseStats) do
			item[stat] = baseValue
		end
	end

	-- If no enchantments, just return
	if not item.Enchantments then
		return
	end

	-- For each enchantment on the item
	for enchantName, level in pairs(item.Enchantments) do
		local enchantData = EnchantmentSystem.Enchantments[enchantName]

		-- Skip if enchantment data doesn't exist
		if not enchantData or not enchantData.Effects then
			continue
		end

		-- Apply effects
		for statName, effect in pairs(enchantData.Effects) do
			-- Skip if this stat doesn't exist on the item
			if item[statName] == nil then
				continue
			end

			-- Apply multiplier if it exists for this level
			if effect.Multiplier and effect.Multiplier[level] then
				item[statName] = item[statName] * effect.Multiplier[level]
			end

			-- Apply additive modifier if it exists for this level
			if effect.Modifier and effect.Modifier[level] then
				item[statName] = item[statName] + effect.Modifier[level]
			end
		end

		-- Apply custom effects
		if enchantData.Effects.Custom then
			for customEffect, value in pairs(enchantData.Effects.Custom) do
				if value[level] then
					if not item.CustomEffects then
						item.CustomEffects = {}
					end
					item.CustomEffects[customEffect] = value[level]
				end
			end
		end
	end
end

-- Function to get all possible enchantments for an item
function EnchantmentSystem.GetPossibleEnchantments(item: any): {[string]: number}
	local result = {}

	if not item.Enchantable then
		return result
	end

	for enchantName, enchantData in pairs(EnchantmentSystem.Enchantments) do
		for _, itemType in ipairs(enchantData.ValidTypes) do
			if item.Type == itemType then
				result[enchantName] = enchantData.MaxLevel
				break
			end
		end
	end

	return result
end

-- Register default item types
EnchantmentSystem.RegisterItemType("Sword", {
	DisplayName = "Sword",
	Type = "Sword",
	Damage = 10,
	AttackSpeed = 1.0,
	Durability = 100,
	Enchantable = true,
	BaseStats = {
		Damage = 10,
		AttackSpeed = 1.0
	}
})

EnchantmentSystem.RegisterItemType("Bow", {
	DisplayName = "Bow",
	Type = "Bow",
	Damage = 5,
	DrawTime = 1.5,
	Range = 50,
	Durability = 100,
	Enchantable = true,
	BaseStats = {
		Damage = 5,
		DrawTime = 1.5,
		Range = 50
	}
})

EnchantmentSystem.RegisterItemType("Wand", {
	DisplayName = "Wand",
	Type = "Wand",
	MagicDamage = 8,
	ManaCost = 10,
	CooldownTime = 1.0,
	Enchantable = true,
	BaseStats = {
		MagicDamage = 8,
		ManaCost = 10,
		CooldownTime = 1.0
	}
})

EnchantmentSystem.RegisterItemType("Armor", {
	DisplayName = "Armor",
	Type = "Armor",
	Defense = 5,
	Weight = 10,
	Durability = 100,
	Enchantable = true,
	BaseStats = {
		Defense = 5,
		Weight = 10
	}
})

-- Register default enchantments
EnchantmentSystem.RegisterEnchantment("Sharpness", {
	MaxLevel = 5,
	ValidTypes = {"Sword"},
	Effects = {
		Damage = {
			Modifier = {
				2, 4, 6, 8, 10
			}
		}
	}
})

EnchantmentSystem.RegisterEnchantment("Power", {
	MaxLevel = 5,
	ValidTypes = {"Bow"},
	Effects = {
		Damage = {
			Multiplier = {
				1.2, 1.4, 1.6, 1.8, 2.0
			}
		}
	}
})

EnchantmentSystem.RegisterEnchantment("Infinity", {
	MaxLevel = 1,
	ValidTypes = {"Bow"},
	Effects = {
		Custom = {
			InfiniteAmmo = {
				true
			}
		}
	}
})

EnchantmentSystem.RegisterEnchantment("Protection", {
	MaxLevel = 4,
	ValidTypes = {"Armor"},
	Effects = {
		Defense = {
			Multiplier = {
				1.1, 1.2, 1.3, 1.4
			}
		}
	}
})

EnchantmentSystem.RegisterEnchantment("ManaEfficiency", {
	MaxLevel = 3,
	ValidTypes = {"Wand"},
	Effects = {
		ManaCost = {
			Modifier = {
				-2, -4, -6
			}
		}
	}
})

EnchantmentSystem.RegisterEnchantment("ElementalFocus", {
	MaxLevel = 5,
	ValidTypes = {"Wand"},
	Effects = {
		MagicDamage = {
			Multiplier = {
				1.1, 1.2, 1.3, 1.4, 1.5
			}
		},
		Custom = {
			ElementalDamage = {
				2, 4, 6, 8, 10
			}
		}
	}
})

EnchantmentSystem.RegisterEnchantment("Unbreaking", {
	MaxLevel = 3,
	ValidTypes = {"Sword", "Bow", "Armor", "Wand"},
	Effects = {
		Durability = {
			Multiplier = {
				1.5, 2.0, 3.0
			}
		}
	}
})

return EnchantmentSystem
