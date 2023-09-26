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

local function AddBuff(spellID)
	local name = SpellName(spellID)
	table.insert(Healium_Buff.Name, name)
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
	if (class == "DRUID") then
		AddSpell(774)		-- Rejuvenation
		AddSpell(8936)		-- Regrowth
		AddSpell(33763)		-- Lifebloom
		AddSpell(5185)		-- Healing Touch
		AddSpell(5375)		-- Swiftmend
		AddSpell(50464)		-- Nourish
		AddSpell(53248)		-- Wild Growth
		AddSpell(29166)		-- Innervate
		AddSpell(20484)		-- Rebirth
		AddSpell(2782)		-- Remove Curse (Druid)
		AddSpell(8946)      -- Cure Poison
		AddSpell(2893)		-- Abolish Poison

		-- Druid  Remove Curse
		Cures[SpellName(2782)] = { CanCureCurse = true }

		-- Druid Abolish Poison
		Cures[SpellName(2893)] = { CanCurePoison = true }

		-- Druid Cure Poison
		Cures[SpellName(8946)] = { CanCurePoison = true }
	end

	if (class == "PRIEST") then
		AddSpell(139)		-- Renew
		AddSpell(2061)		-- Flash Heal
		AddSpell(2050)		-- Lesser Heal
		AddSpell(2054)		-- Heal
		AddSpell(2060)		-- Greater Heal
		AddSpell(32546)		-- Binding Heal
		AddSpell(596)		-- Prayer of Healing
		AddSpell(33076)		-- Prayer of Mending
		AddSpell(34861)		-- Circle of Healing
		AddSpell(17)		-- Power Word: Shield
		AddSpell(552)		-- Abolish Disease
		AddSpell(528)		-- Cure Disease
		AddSpell(527)		-- Dispel Magic
		AddSpell(47788)		-- Guardian Spirit
		AddSpell(47540)		-- Penance

		-- Priest Abolish Disease
		Cures[SpellName(552)] = { CanCureDisease = true }

		-- Priest Cure Disease
		Cures[SpellName(528)] = { CanCureDisease = true }

		-- Priest Dispel Magic
		Cures[SpellName(527)]  = { CanCureMagic = true }
	end

	if (class == "SHAMAN") then
		AddSpell(8004)		-- Lesser Healing Wave
		AddSpell(331)		-- Healing Wave
		AddSpell(1064)		-- Chain Heal
		AddSpell(974)		-- Earth Shield
		AddSpell(526)		-- Cure Toxins
		AddSpell(51886)		-- Cleanse Spirit
		AddSpell(61295)		-- Riptide


		-- Shaman Cure Toxins
		Cures[SpellName(526)] = { CanCurePoison = true, CanCureDisease = true }

		-- Shaman Cleanse Spirit
		Cures[SpellName(51886)] = { CanCurePoison = true, CanCureDisease = true, CanCureCurse = true }

	end

	if (class == "PALADIN") then
		AddSpell(19750) 	-- Flash of Light
		AddSpell(635) 		-- Holy Light
		AddSpell(20473) 	-- Holy Shock
		AddSpell(633) 		-- Lay on Hands
		AddSpell(1152) 		-- Purify
		AddSpell(4987) 		-- Cleanse
		AddSpell(1022)		-- Hand of Protection
		AddSpell(1038)		-- Hand of Salvation
		AddSpell(1044)		-- Hand of Freedom
		AddSpell(53563)		-- Beacon of Light
		AddSpell(53601)		-- Sacred Shield

		-- Paladin Purify
		Cures[SpellName(1152)] = {	CanCurePoison = true, CanCureDisease = true }

		-- Paladin Cleanse
		Cures[SpellName(4987)] = {	CanCurePoison = true, CanCureDisease = true, CanCureMagic = true }

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

function Healium_InitBuffs()
	-- All buff
	AddBuff(59547) -- Gift of the Naaru
	AddBuff(64413) -- Protection of Ancient Kings
	AddBuff(71864) -- Fountain of Light


	-- druid buff
	AddBuff(33763) -- Lifebloom
	AddBuff(8936) -- Regrowth
	AddBuff(774) -- Rejuvenation
	AddBuff(48496) -- Living Seed
	AddBuff(740) -- Tranquility
	AddBuff(48438) -- Wild Growth
	AddBuff(2893) -- Abolish Poison
	AddBuff(22812) -- Barkskin
	AddBuff(61336) -- Survival Instincts
	AddBuff(22842) -- Frenzied Regeneration
	AddBuff(17116) -- Nature's Swiftness
	AddBuff(467) -- Thorns
	AddBuff(1126) -- Mark of the Wild
	AddBuff(21849) -- Gift of the Wild

	-- priest buff
	AddBuff(33076) -- Prayer of Mending
	AddBuff(139) -- Renew
	AddBuff(14751) -- Inner Focus
	AddBuff(63730) -- Serendipity
	AddBuff(552) -- Abolish Disease
	AddBuff(47788) -- Guardian Spirit
	AddBuff(6346) -- Fear Ward
	AddBuff(70772) -- Blessed Healing
	AddBuff(33206) -- Pain Suppression
	AddBuff(10060) -- Power Infusion
	AddBuff(17) -- Power Word:Shield
	AddBuff(47509) -- Divine Aegis
	AddBuff(47516) -- Grace
	AddBuff(7001) -- Lightwell Renew
	AddBuff(14892) -- Inspiration

	-- shaman buff
	AddBuff(29206) -- Healing Way
	AddBuff(16237) -- Ancestral Fortitude
	AddBuff(51730) -- Earthliving Weapon
	AddBuff(974) -- Earth Shield
	AddBuff(324) -- Lightning Shield
	AddBuff(52127) -- Water Shield
	AddBuff(71220) -- Energized
	AddBuff(70809) -- Chain Heal
	AddBuff(51562) -- Tidal Waves
	AddBuff(55198) -- Tidal Force
	AddBuff(61295) -- Riptide
	AddBuff(51730) -- Earthliving Weapon

	-- paladin buff
	AddBuff(27154) -- Lay on Hands | Improved didnt show icon - Aura has 'Lay On Hands' and id 27154 works.  Improved is GetSpellInfo(20234)
	AddBuff(1038) -- Hand of Salvation
	AddBuff(642) -- Divine Shield
	AddBuff(6940) -- Hand of Sacrifice
	AddBuff(71192) -- Blessed
	AddBuff(53569) -- Infusion of Light
	AddBuff(53563) -- Beacon of Light
	AddBuff(1022) -- Hand of Protection
	AddBuff(19750) -- Flash of Light
	AddBuff(53651) -- Light Beacon
	AddBuff(53601) -- Sacred Shield
	AddBuff(1044) -- Hand of Freedom
	AddBuff(53551) -- Sacred Cleansing
	AddBuff(33154) -- Surge of Light
	AddBuff(498) -- Divine Protection

	-- hunter buff
	AddBuff(136) -- Mend Pet

	-- warrior buff
	AddBuff(50720) -- Vigilance
	AddBuff(12975) -- Last Stand
	AddBuff(871) -- Shield Wall
	AddBuff(2565) -- Shield Block
	AddBuff(55694) -- Enraged Regeneration

	-- deathnight buff
	AddBuff(48792) -- Icebound Fortitude
	AddBuff(48707) -- Antimagic Shell
	AddBuff(42650) -- Army of the Dead
	AddBuff(49039) -- Lichborne
	AddBuff(51052) -- Antimagic Zone
	AddBuff(55233) -- Vampiric Blood
	AddBuff(51271) -- Unbreakable Armor
	AddBuff(49222) -- Bone Shield
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
				if cure.CanCureMagic then CanCureMagic = true end
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
				elseif debuffTypes["Magic"] and cure.CanCureMagic then
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
