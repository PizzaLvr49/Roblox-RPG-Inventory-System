local EnchantmentSystem = require(script.Parent.EnchantmentSystem)

-- Example: Creating custom item types
EnchantmentSystem.RegisterItemType("Crossbow", {
	DisplayName = "Crossbow",
	Type = "Crossbow",
	Damage = 8,
	ReloadTime = 2.0,
	Range = 60,
	Durability = 80,
	Enchantable = true,
	BaseStats = {
		Damage = 8,
		ReloadTime = 2.0,
		Range = 60
	}
})

-- Example: Creating custom enchantments
EnchantmentSystem.RegisterEnchantment("Piercing", {
	MaxLevel = 4,
	ValidTypes = {"Crossbow", "Bow"},
	Effects = {
		Custom = {
			TargetsPierced = {
				1, 2, 3, 4
			}
		}
	}
})

EnchantmentSystem.RegisterEnchantment("QuickDraw", {
	MaxLevel = 3,
	ValidTypes = {"Bow", "Crossbow"},
	Effects = {
		DrawTime = {
			Multiplier = {
				0.8, 0.6, 0.4
			}
		},
		ReloadTime = {
			Multiplier = {
				0.8, 0.6, 0.4
			}
		}
	}
})

-- Creating and enchanting items
local function Example()
	-- Create a sword
	local excalibur = EnchantmentSystem.CreateItem("Sword", {
		DisplayName = "Excalibur",
		Damage = 15,  -- Override default damage
		BaseStats = {
			Damage = 15,
			AttackSpeed = 1.2
		}
	})

	-- Create a bow
	local hunterBow = EnchantmentSystem.CreateItem("Bow", {
		DisplayName = "Hunter's Bow",
		-- Using default values for other properties
	})

	-- Create a custom crossbow
	local rapidCrossbow = EnchantmentSystem.CreateItem("Crossbow", {
		DisplayName = "Rapid Crossbow",
		ReloadTime = 1.5,  -- Override default reload time
		BaseStats = {
			Damage = 8,
			ReloadTime = 1.5,
			Range = 60
		}
	})

	-- Enchant the sword with Sharpness III
	EnchantmentSystem.EnchantItem(excalibur, "Sharpness", 3)

	-- Enchant the bow with Power II and Infinity I
	EnchantmentSystem.EnchantItem(hunterBow, "Power", 2)
	EnchantmentSystem.EnchantItem(hunterBow, "Infinity", 1)

	-- Enchant the crossbow with Piercing II and QuickDraw III
	EnchantmentSystem.EnchantItem(rapidCrossbow, "Piercing", 2)
	EnchantmentSystem.EnchantItem(rapidCrossbow, "QuickDraw", 3)

	-- Print item stats to see enchantment effects
	print("Excalibur Damage: " .. excalibur.Damage)  -- Should be increased by Sharpness III
	print("Hunter's Bow Damage: " .. hunterBow.Damage)  -- Should be increased by Power II
	print("Does Hunter's Bow have infinite ammo? " .. tostring(hunterBow.CustomEffects.InfiniteAmmo))
	print("Rapid Crossbow Reload Time: " .. rapidCrossbow.ReloadTime)  -- Should be decreased by QuickDraw III
	print("Rapid Crossbow Targets Pierced: " .. rapidCrossbow.CustomEffects.TargetsPierced)

	-- Get all possible enchantments for the crossbow
	local possibleEnchants = EnchantmentSystem.GetPossibleEnchantments(rapidCrossbow)
	print("Possible enchantments for Rapid Crossbow:")
	for enchantName, maxLevel in pairs(possibleEnchants) do
		print("  - " .. enchantName .. " (Max Level: " .. maxLevel .. ")")
	end

	-- Remove an enchantment
	EnchantmentSystem.RemoveEnchantment(hunterBow, "Power")
	print("Hunter's Bow Damage after removing Power: " .. hunterBow.Damage)  -- Should be back to default
end

-- Run the example
Example()
