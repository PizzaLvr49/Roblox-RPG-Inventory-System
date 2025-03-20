local EnchantmentSystem = require(script.Parent.EnchantmentSystem)

-- Example 1: Register a new component
EnchantmentSystem.RegisterComponent("Throwable", {
	ThrowDistance = 20,
	ThrowDamage = 5,
	ReturnToOwner = false
})

-- Example 2: Register a new item type with composition
EnchantmentSystem.RegisterItemType("Crossbow", {
	"Breakable", 
	"Enchantable",
	"Weapon",
	"Ranged"
}, {
	DisplayName = "Crossbow",
	-- Default properties here
})

-- Example 3: Register a custom enchantment
EnchantmentSystem.RegisterEnchantment("Piercing", {
	MaxLevel = 4,
	ValidTypes = {"Crossbow", "Bow"},
	RequiredComponents = {"Ranged"},
	Effects = {
		Custom = {
			TargetsPierced = {1, 2, 3, 4}
		}
	}
})

EnchantmentSystem.RegisterEnchantment("QuickDraw", {
	MaxLevel = 3,
	ValidTypes = {"Bow", "Crossbow"},
	RequiredComponents = {"Ranged"},
	Effects = {
		Ranged = {
			ProjectileSpeed = {
				Multiplier = {1.2, 1.4, 1.6}
			}
		}
	}
})

-- Example 4: Creating a sword
local excalibur = EnchantmentSystem.CreateItem("Sword", {
	DisplayName = "Excalibur",
	-- Override component properties
	Components = {
		Weapon = {
			Damage = 15,
			AttackSpeed = 1.2
		},
		Breakable = {
			Durability = 200,
			MaxDurability = 200
		}
	}
})

-- Example 5: Creating a bow
local hunterBow = EnchantmentSystem.CreateItem("Bow", {
	DisplayName = "Hunter's Bow"
	-- Using default component values
})

-- Example 6: Creating a custom crossbow
local rapidCrossbow = EnchantmentSystem.CreateItem("Crossbow", {
	DisplayName = "Rapid Crossbow",
	Components = {
		Ranged = {
			ProjectileSpeed = 30
		}
	}
})

-- Example 7: Enchanting items
EnchantmentSystem.EnchantItem(excalibur, "Sharpness", 3)
EnchantmentSystem.EnchantItem(hunterBow, "Power", 2)
EnchantmentSystem.EnchantItem(hunterBow, "Infinity", 1)
EnchantmentSystem.EnchantItem(rapidCrossbow, "Piercing", 2)
EnchantmentSystem.EnchantItem(rapidCrossbow, "QuickDraw", 3)

-- Example 8: Accessing component properties with composition
print("Excalibur Damage: " .. excalibur.weapon.Damage)
print("Hunter's Bow Damage: " .. hunterBow.weapon.Damage)
print("Hunter's Bow Range: " .. hunterBow.ranged.Range)
print("Does Hunter's Bow have infinite ammo? " .. tostring(hunterBow.customEffects.InfiniteAmmo))
print("Excalibur Durability: " .. excalibur.breakable.Durability .. "/" .. excalibur.breakable.MaxDurability)
print("Rapid Crossbow Projectile Speed: " .. rapidCrossbow.ranged.ProjectileSpeed)
print("Rapid Crossbow Targets Pierced: " .. rapidCrossbow.customEffects.TargetsPierced)

-- Example 9: Getting possible enchantments
local possibleEnchants = EnchantmentSystem.GetPossibleEnchantments(rapidCrossbow)
print("Possible enchantments for Rapid Crossbow:")
for enchantName, maxLevel in pairs(possibleEnchants) do
	print("  - " .. enchantName .. " (Max Level: " .. maxLevel .. ")")
end

-- Example 10: Removing an enchantment
EnchantmentSystem.RemoveEnchantment(hunterBow, "Power")
print("Hunter's Bow Damage after removing Power: " .. hunterBow.weapon.Damage)

-- Example 11: Creating a completely new item type with custom components
EnchantmentSystem.RegisterComponent("TeleportEffect", {
	TeleportDistance = 10,
	TeleportCooldown = 5,
	TeleportSound = "whoosh"
})

EnchantmentSystem.RegisterItemType("MagicDagger", {
	"Breakable",
	"Enchantable",
	"Weapon",
	"Magical",
	"TeleportEffect",
	"Throwable"
}, {
	DisplayName = "Magic Dagger"
})

-- Creating a magic dagger with custom properties
local shadowBlade = EnchantmentSystem.CreateItem("MagicDagger", {
	DisplayName = "Shadow Blade",
	Components = {
		Weapon = {
			Damage = 8,
			AttackSpeed = 2.0
		},
		Magical = {
			MagicDamage = 5,
			ManaCost = 2
		},
		TeleportEffect = {
			TeleportDistance = 15
		},
		Throwable = {
			ReturnToOwner = true
		}
	}
})

-- Register a custom enchantment for the new item type
EnchantmentSystem.RegisterEnchantment("ShadowWalk", {
	MaxLevel = 3,
	ValidTypes = {"MagicDagger"},
	RequiredComponents = {"TeleportEffect", "Magical"},
	Effects = {
		TeleportEffect = {
			TeleportDistance = {
				Multiplier = {1.5, 2.0, 3.0}
			},
			TeleportCooldown = {
				Multiplier = {0.8, 0.6, 0.4}
			}
		},
		Magical = {
			ManaCost = {
				Multiplier = {1.2, 1.4, 1.6}
			}
		}
	}
})

-- Enchant the shadow blade
EnchantmentSystem.EnchantItem(shadowBlade, "ShadowWalk", 2)

-- Print shadow blade stats
print("Shadow Blade Teleport Distance: " .. shadowBlade.teleporteffect.TeleportDistance)
print("Shadow Blade Teleport Cooldown: " .. shadowBlade.teleporteffect.TeleportCooldown)
print("Shadow Blade Returns to Owner: " .. tostring(shadowBlade.throwable.ReturnToOwner))
