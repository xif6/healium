local CanCureMagic = false
local CanCureDisease = false
local CanCurePoison = false
local CanCureCurse = false

local Cures = { } 
local CuresCount = 0

local function SpellName(spellID)
	local name = GetSpellInfo(spellID)
	return name
end

local function AddSpell(spellID)
	local name = SpellName(spellID)
	table.insert(Healium_Spell.Name, name)
end

local function Count(tab)
	local cnt = 0
	
	for _, k in pairs(tab) do
		cnt = cnt + 1
	end
	
	return cnt
end

-- These spellIDs are from wowhead

function Healium_InitSpells(class, race)
	
	-- Init spell list
	-- DONE FOR CATA
	if (class == "DRUID") then 
		AddSpell(774)		-- Rejuvenation
		AddSpell(8936)		-- Regrowth
		AddSpell(33763)		-- Lifebloom
		AddSpell(5185)		-- Healing Touch
		AddSpell(18562)		-- Swiftmend
		AddSpell(50464)		-- Nourish
		AddSpell(48438)		-- Wild Growth
		AddSpell(29166)		-- Innervate
		AddSpell(20484)		-- Rebirth
		AddSpell(2782)		-- Remove Corruption
		
		-- Druid Remove Corruption
		Cures[SpellName(2782)] = { 
			CanCurePoison = true, 
			CanCureCurse = true,
			CanCureMagicFunc = function() 
				-- Druid Nature's Cure talent
				return select(5, GetTalentInfo(3,17)) > 0
			end
		}
	end

	-- DONE FOR CATA
	if (class == "PRIEST") then 
		AddSpell(139)		-- Renew
		AddSpell(2061)		-- Flash Heal
		AddSpell(2050)		-- Heal
		AddSpell(2060)		-- Greater Heal
		AddSpell(32546)		-- Binding Heal
		AddSpell(596)		-- Prayer of Healing
		AddSpell(33076)		-- Prayer of Mending
		AddSpell(34861)		-- Circle of Healing
		AddSpell(17)		-- Power Word: Shield
		AddSpell(528)		-- Cure Disease
		AddSpell(527)		-- Dispel Magic
		AddSpell(47788)		-- Guardian Spirit
		AddSpell(47540)		-- Penance
		AddSpell(88625)		-- Holy Word: Chastise
		
		-- Priest Cure Disease
		Cures[SpellName(528)] = { CanCureDisease = true }
			
		-- Priest Dispel Magic
		Cures[SpellName(527)]  = { CanCureMagic = true }
	end

	-- DONE FOR CATA
	if (class == "SHAMAN") then
		AddSpell(51886)		-- Cleanse Spirit	
		AddSpell(8004)		-- Healing Surge
		AddSpell(331)		-- Healing Wave
		AddSpell(77472)     -- Greater Healing Wave		
		AddSpell(1064)		-- Chain Heal		
		AddSpell(61295)		-- Riptide		
		AddSpell(974)		-- Earth Shield
		AddSpell(16188)		-- Nature's Swiftness
		AddSpell(73680)		-- Unleash Elements
			
		-- Shaman Cleanse Spirit
		Cures[SpellName(51886)] = { 
			CanCureCurse = true,
			CanCureMagicFunc = function() 
				-- Shaman Improved Cleanse Spirit talent
				return select(5, GetTalentInfo(3,12)) > 0
			end
		} 
	end

	if (class == "PALADIN") then
		AddSpell(19750) 	-- Flash of Light
		AddSpell(635) 		-- Holy Light
		AddSpell(20473) 	-- Holy Shock
		AddSpell(633) 		-- Lay on Hands
		AddSpell(4987) 		-- Cleanse
		AddSpell(1022)		-- Hand of Protection
		AddSpell(1038)		-- Hand of Salvation
		AddSpell(1044)		-- Hand of Freedom
		AddSpell(53563)		-- Beacon of Light
		AddSpell(53601)		-- Sacred Shield
		AddSpell(85673)		-- Word of Glory
		AddSpell(82326)     -- Divine Light
		AddSpell(85222)		-- Light of Dawn
		AddSpell(82327)		-- Holy Radiance
		
		-- Paladin Cleanse
		Cures[SpellName(4987)] = {	
			CanCurePoison = true, 
			CanCureDisease = true,
			CanCureMagicFunc = function() 
				-- Paladin Sacred Cleansing Talent
				return select(5, GetTalentInfo(1,14)) > 0
			end
		}
		
	end

	if (class == "MAGE") then
		AddSpell(475) 		-- Remove Curse (Mage)
		
		-- Mage  Remove Curse
		Cures[SpellName(475)] = { CanCureCurse = true }
		
	end
	
	if (race == "Draenei") then -- race isn't in all uppercase like class
		AddSpell(59547)		-- Gift of the Naaru
	end
	
	CuresCount = Count(Cures)
end

local function GetCanCureMagic(cure)
	local flag = nil
	
	if cure.CanCureMagic then 
		flag = true
	elseif cure.CanCureMagicFunc ~= nil then 	
		flag = cure.CanCureMagicFunc()
	end
	
	return flag
end

function Healium_UpdateCures()
	local Profile = Healium_GetProfile()
	
	-- Handle Cures
	CanCureMagic = false
	CanCureDisease = false
	CanCurePoison = false
	CanCureCurse = false	

	if CuresCount > 0 then
		for i=1, Profile.ButtonCount,1 do
			local spell = Profile.SpellNames[i]
			local cure = Cures[spell]
			if cure ~= nill then
				if GetCanCureMagic(cure) then CanCureMagic = true end
				if cure.CanCureDisease then CanCureDisease = true end
				if cure.CanCurePoison then CanCurePoison = true end
				if cure.CanCureCurse then CanCureCurse = true end
			end
		end
	end
	
end

--debuffType is expected to be a return value from the wow api UnitDebuff()
function Healium_CanCureDebuff(debuffType)
	if   ( (debuffType == "Curse") and CanCureCurse) or
	     ( (debuffType == "Disease") and CanCureDisease) or
		 ( (debuffType == "Magic") and CanCureMagic) or
		 ( (debuffType == "Poison") and CanCurePoison) then	
		 return true
	end
	
	return false
end

function Healium_ShowDebuffButtons(Profile, frame, debuffTypes)

	for i=1, Profile.ButtonCount,1 do
		local button = frame.buttons[i]	
		
		if button then 
			local spell = Profile.SpellNames[i]
			local cure = Cures[spell]
			local flag
			local debuffColor 
			
			if cure ~= nill then
				if debuffTypes["Curse"] and cure.CanCureCurse then
					flag = true
					debuffColor = DebuffTypeColor["Curse"] 
				elseif debuffTypes["Disease"] and cure.CanCureDisease then
					flag = true
					debuffColor = DebuffTypeColor["Disease"]
				elseif debuffTypes["Magic"] and GetCanCureMagic(cure) then
					flag = true
					debuffColor = DebuffTypeColor["Magic"]
				elseif debuffTypes["Poison"] and cure.CanCurePoison then
					flag = true
					debuffColor = DebuffTypeColor["Poison"]
				else 
					flag = false
				end
			end
			
			local curseBar = button.CurseBar
			
			if flag then
				curseBar:SetBackdropBorderColor(debuffColor.r, debuffColor.g, debuffColor.b)
				curseBar:SetAlpha(1)
				curseBar.hasDebuf = true
			else
				if curseBar.hasDebuf then
					curseBar:SetAlpha(0)
					curseBar.hasDebuf = nil
				end
			end
		end
	end
end