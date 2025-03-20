local Players = game:GetService("Players")
local ItemSystem = require(script.Parent.Inventory.ItemSystem) -- Path to the combined system
local Nexus = require(game:GetService("ReplicatedStorage"):WaitForChild("Nexus"))
-- Let's start by setting up some basic item types
print("\n===== REGISTERING BASIC ITEM TYPES =====")
-- Everyone needs a good sword!
ItemSystem.RegisterItemType("Sword", {
	"Breakable", 
	"Enchantable", 
	"Weapon"
}, {
	DisplayName = "Sword"
})
-- For the ranged attackers...
ItemSystem.RegisterItemType("Bow", {
	"Breakable", 
	"Enchantable", 
	"Weapon", 
	"Ranged"
}, {
	DisplayName = "Bow"
})
-- Something for the magic users
ItemSystem.RegisterItemType("Wand", {
	"Breakable", 
	"Enchantable", 
	"Magical"
}, {
	DisplayName = "Wand"
})
-- Gotta protect yourself!
ItemSystem.RegisterItemType("Armor", {
	"Breakable", 
	"Enchantable", 
	"Defensive"
}, {
	DisplayName = "Armor"
})
-- Let's create some enchantments for our items
print("\n===== REGISTERING ENCHANTMENTS =====")
-- Sword enchantments
ItemSystem.RegisterEnchantment("Sharpness", {
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
-- Bow enchantments
ItemSystem.RegisterEnchantment("Power", {
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
ItemSystem.RegisterEnchantment("Infinity", {
	MaxLevel = 1,
	ValidTypes = {"Bow"},
	RequiredComponents = {"Ranged"},
	Effects = {
		Custom = {
			InfiniteAmmo = {true}
		}
	}
})
-- Armor enchantments
ItemSystem.RegisterEnchantment("Protection", {
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
-- Wand enchantments
ItemSystem.RegisterEnchantment("ManaEfficiency", {
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
ItemSystem.RegisterEnchantment("ElementalFocus", {
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
-- Universal enchantment - works on everything!
ItemSystem.RegisterEnchantment("Unbreaking", {
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
print("\n===== REGISTERING DEFAULT ITEMS =====")
-- Register some default items that can be spawned in the game
ItemSystem.RegisterDefaultItem("wooden_sword", "Sword", {
	DisplayName = "Wooden Sword",
	Components = {
		Weapon = {
			Damage = 5
		}
	}
}, "Common")
ItemSystem.RegisterDefaultItem("iron_sword", "Sword", {
	DisplayName = "Iron Sword",
	Components = {
		Weapon = {
			Damage = 8
		}
	}
}, "Uncommon")
ItemSystem.RegisterDefaultItem("excalibur", "Sword", {
	DisplayName = "Excalibur",
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
}, "Legendary")
ItemSystem.RegisterDefaultItem("hunters_bow", "Bow", {
	DisplayName = "Hunter's Bow"
}, "Common")
ItemSystem.RegisterDefaultItem("arcane_wand", "Wand", {
	DisplayName = ""})
ItemSystem.RegisterDefaultItem("arcane_wand", "Wand", {
	DisplayName = "Arcane Wand",
	Components = {
		Magical = {
			MagicDamage = 12,
			ManaCost = 8
		}
	}
}, "Rare")

ItemSystem.RegisterDefaultItem("crystal_wand", "Wand", {
	DisplayName = "Crystal Wand",
	Components = {
		Magical = {
			MagicDamage = 18,
			ManaCost = 12,
			CooldownTime = 0.8
		}
	}
}, "Epic")

ItemSystem.RegisterDefaultItem("leather_armor", "Armor", {
	DisplayName = "Leather Armor",
	Components = {
		Defensive = {
			Defense = 3,
			Weight = 5
		}
	}
}, "Common")

ItemSystem.RegisterDefaultItem("steel_armor", "Armor", {
	DisplayName = "Steel Armor",
	Components = {
		Defensive = {
			Defense = 8,
			Weight = 15
		}
	}
}, "Rare")

print("\n===== DEMONSTRATION =====")

-- Create a player inventory for demo purposes
local demoPlayer = {
	Name = "DemoPlayer",
	UserId = 12345
}

local inventory = ItemSystem.GetPlayerInventory(demoPlayer)
print("Created inventory for:", inventory.Owner.Name)

-- Add some items to the inventory
print("\nAdding items to inventory...")
local success, item1 = ItemSystem.AddItemToInventory(inventory, ItemSystem.CreateItem("Sword", {
	DisplayName = "Fire Blade",
	Components = {
		Weapon = {
			Damage = 12
		}
	}
}))
print("Added:", item1.DisplayName)

local success, excalibur = ItemSystem.AddItemToInventory(inventory, ItemSystem.Inventory.DefaultItems["excalibur"])
print("Added:", excalibur.DisplayName)

local success, bow = ItemSystem.AddItemToInventory(inventory, ItemSystem.Inventory.DefaultItems["hunters_bow"])
print("Added:", bow.DisplayName)

local success, wand = ItemSystem.AddItemToInventory(inventory, ItemSystem.Inventory.DefaultItems["arcane_wand"])
print("Added:", wand.DisplayName)

-- Add some gold
ItemSystem.Inventory.AddGold(inventory, 500)
print("Added 500 gold. New balance:", inventory.Gold)

-- Enchant some items
print("\nEnchanting items...")
ItemSystem.EnchantItem(excalibur, "Sharpness", 3)
ItemSystem.EnchantItem(excalibur, "Unbreaking", 2)
print("Excalibur's new damage:", excalibur.weapon.Damage)
print("Excalibur's new durability:", excalibur.breakable.Durability)

ItemSystem.EnchantItem(bow, "Power", 2)
ItemSystem.EnchantItem(bow, "Infinity", 1)
print("Bow's new damage:", bow.weapon.Damage)
print("Bow has infinite ammo:", bow.customEffects.InfiniteAmmo)

ItemSystem.EnchantItem(wand, "ManaEfficiency", 2)
ItemSystem.EnchantItem(wand, "ElementalFocus", 3)
print("Wand's new mana cost:", wand.magical.ManaCost)
print("Wand's new damage:", wand.magical.MagicDamage)
print("Wand's elemental damage:", wand.customEffects.ElementalDamage)

-- Find items by criteria
print("\nSearching for weapons with damage > 10...")
local weapons = ItemSystem.FindItems(inventory, {
	weapon = {
		Damage = function(value) return value > 10 end
	}
})
for _, weaponData in ipairs(weapons) do
	print("Found:", weaponData.Item.DisplayName, "with damage", weaponData.Item.weapon.Damage)
end

-- Sort inventory by damage
print("\nSorting inventory by weapon damage...")
ItemSystem.SortInventory(inventory, {"weapon", "Damage"}, false)
print("Inventory order after sorting:")
for i, item in ipairs(inventory.Items) do
	if item.weapon then
		print(i, item.DisplayName, "- Damage:", item.weapon.Damage)
	else
		print(i, item.DisplayName, "- No weapon component")
	end
end

-- Create an event handler for when players join the game
local function onPlayerJoined(player: Player)
	print("Player joined:", player.Name)
	local playerInventory = ItemSystem.GetPlayerInventory(player)

	-- Give new players some starter items
	ItemSystem.AddItemToInventory(playerInventory, ItemSystem.Inventory.DefaultItems["wooden_sword"])
	ItemSystem.AddItemToInventory(playerInventory, ItemSystem.Inventory.DefaultItems["leather_armor"])
	ItemSystem.Inventory.AddGold(playerInventory, 100)

	print("Gave starter pack to:", player.Name)
	print(playerInventory)
	local channelName = player.UserId.."_Inventory"
	Nexus.WaitForChannel(channelName)
	task.wait(1)
	Nexus.Send(channelName, playerInventory)
end

-- Connect to PlayerAdded event

Players.PlayerAdded:Connect(onPlayerJoined)

print("\n===== DEMO COMPLETE =====")

-- Return the ItemSystem module so it can be used by other scripts
return ItemSystem
