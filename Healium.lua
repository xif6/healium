-- Healium - Maintained by Engy of Area 52.  Based on FB Healbox by Dourd of Argent Dawn EU
--
-- Programming notes
-- WARNING In LUA all logical operators consider false and nil as false and anything else as true.  This means not 0 is false!!!!!!!!
-- Color control characters |CAARRGGBB  then |r resets to normal, where AA == Alpha, RR = Red, GG = Green, BB = blue

Healium_Debug = false
local AddonVersion = "|cFFFFFF00 1.3.0|r"

HealiumDropDown = {} -- the dropdown menus on the config panel

-- Constants
local LowHP = 0.6
local VeryLowHP = 0.3
local NamePlateWidth = 120
local _, HealiumClass = UnitClass("player")
local _, HealiumRace = UnitRace("player")
local MaxParty = 5 -- Max number of people in party
local MinRangeCheckPeriod = .2 -- .2 = 5Hz
local MaxRangeCheckPeriod = 2  -- 2 = .5Hz
local DefaultRangeCheckPeriod = .5
local DefaultButtonCount = 5

-- locale safe versions of spell names
local ActivatePrimarySpecSpellName = GetSpellInfo(63645)
local ActivateSecondarySpecSpellName = GetSpellInfo(63644)
local PWSName = GetSpellInfo(17) -- Power Word: Shield
local WeakendSoulName = GetSpellInfo(6788) -- Weakend Soul
local SwiftMendName = GetSpellInfo(18562) -- Swift Mend
local RejuvinationName = GetSpellInfo(774) -- Rejuvenation
local RegrowthName = GetSpellInfo(8936) -- Regrowth

-- Healium holds per character settings
Healium = {
  Scale = 1.0,									-- Scale of frames
  DoRangeChecks = true,							-- Whether or not to do range checks on buttons
  RangeCheckPeriod = .5,						-- Time period between range checks
  EnableCooldowns = true,						-- Whether or not to do cooldown animations on buttons
  ShowToolTips = true,							-- Whether or not to display a tooltip for the spell when hovering over buttons
  ShowPercentage = true,						-- Whether or not to display the health percentage
  UseClassColors = false,						-- Whether or not to color the healthbar the color of the class instead of green/yellow/red
  ShowDefaultPartyFrames = false,				-- Whether or not to show the default party frames
  ShowPartyFrame = true,						-- Whether or not to show the party frame
  ShowPetsFrame = true,							-- Whether or not to show the pets frame
  ShowMeFrame = false,  						-- Whether or not to show the me frame
  ShowFriendsFrame = false,						-- Whether or not to show the friends frame
  ShowGroupFrames = { },  						-- Whether or not to show individual group frame
  ShowTanks = false,							-- Whether or not to show the tanks frame
  ShowBuffs = true,								-- Whether or not to show your own buffs, that are configured in Healium to the left of the healthbar
  HideCloseButton = false,						-- Whether or not to hide the close (X) button, to prevent accidental closing of the Healium Frame
  HideCaptions = false,							-- Whether or not to hide the caption when the mouse leaves the caption area
  LockFrames = false,							-- Whether or not to prevent dragging of the frame
  EnableClique = false,							-- Whether or not to enable Clique support on the health bars
  EnableDebufs = true,							-- Whether or not to enable the debuf warning system
  EnableDebufAudio = true,						-- Whether or not to enable playing an audio file when a person has a debuf which the player can cure
  DebufAudioFile = nil,							-- The debuf audio file to play
  EnableDebufHealthbarHighlighting = true,		-- Whether or not to highlight the healthbar of a player when they have a debuf which you can cure
  EnableDebufButtonHighlighting = true,			-- Whether or not to highlight buttons which are assigned a spell that can cure a debuff on a player
  EnableDebufHealthbarColoring = false,			-- Whether or not to color the heatlhbar of a player when they have a debuf which you can cure
  ShowMana = true,								-- Whether or not to show mana
  ShowThreat = true,							-- Whether or not to show the threat warnings
  ShowRole = true,								-- Whether or not to show the role icon
  ShowIncomingHeals = true,						-- Whether or not to show incoming heals
}

-- HealiumGlobal is the variable that holds all Heliuam settings that are not character specific
HealiumGlobal = {
  Friends = { },								-- List of healium friends
}

--[[
Healium.Profiles is a table of tables with this signature
{
	ButtonCount -- Current button count (as set by slider)
	SpellNames -- Table of current spell names
	SpellIcons -- Table of current spell IDs
}
]]

-- Global Constants
Healium_MaxButtons = 15		-- Max Possible buttons
Healium_AddonName = "Healium"
Healium_AddonColor = "|cFF55AAFF"
Healium_AddonColoredName = Healium_AddonColor .. Healium_AddonName .. "|r"
Healium_MaxClassSpells = 20 -- For now this is manually set to the max number of class specific spells in Healium_Spell.Name which currently is priest


-- NEW FRAMES VARIABLES
Healium_Units = { { } } -- table of tables that maps unit names to their frame, used for efficient handling of UNIT_HEALTH so each button doesn't get a UNIT_HEALTH event for every unit.
Healium_Frames = { } -- table of all created "unit" frames.  Can access buttons from each of these.
Healium_ShownFrames = { } -- table of all shown "unit" frames.
Healium_ButtonIDs = { } -- table of IDs that correspond to the selected spells, not persisted
Healium_FixNameplates = { } -- nameplates that need various updates when out of combat

Healium_HackOnShow = { }
Healium_DoHackOnShow = nil

--[[
Healium_DefaultButtons = {
	1 = {}
	2 = {}
	3 = {}
	4 = {}
}
--]]

--[[
List of spells, icons for the spells, and IDs.
These only contain specifically selected spells in HealiumSpells.lua
The Name gets filled in in Healium_InitSpells(). Healium_UpdateSpells() will fill in the ID and Icon if
the player actually has the spell.
--]]
Healium_Spell = {
  Name = {},
  Icon = {},
  ID = {}
}

local HealiumFrame = nil

function Healium_Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage(Healium_AddonColor .. Healium_AddonName .. "|r " .. tostring(msg))
end

function Healium_DebugPrint(msg)
	if (Healium_Debug) then
		Healium_Print("Debug: " .. tostring(msg))
	end
end

function Healium_Warn(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|CFFFF0000Warning|r: " .. tostring(msg))
end

function Healium_GetProfile()
	return Healium.Profiles[GetActiveTalentGroup()] -- this has been debugged and works fine
end

function Healium_OnLoad(self)
	HealiumFrame = self
 	Healium_Print(AddonVersion.." |cFF00FF00Loaded |rClick The MiniMap button for options.")
	Healium_Print("Type " .. Healium_Slash .. " for a list of slash commands." )

	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("SPELLS_CHANGED")
	self:RegisterEvent("UNIT_HEALTH")
--	self:RegisterEvent("VARIABLES_LOADED")
	self:RegisterEvent("UNIT_SPELLCAST_SENT")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("PLAYER_TALENT_UPDATE")
	self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
--	self:RegisterEvent("PLAYER_ALIVE")
	self:RegisterEvent("RAID_TARGET_UPDATE")
	self:RegisterEvent("UNIT_NAME_UPDATE")
	self:RegisterEvent("UNIT_AURA")
	HealComm = LibStub("LibHealComm-4.0", true)
	if HealComm then
		HealComm.RegisterCallback(self, "HealComm_HealStarted", function(event, casterGUID, spellID, spellType, endTime, ...) HealComm_HealEvent(event, casterGUID, spellID, spellType, endTime, ...) end)
		HealComm.RegisterCallback(self, "HealComm_HealUpdated", function(event, casterGUID, spellID, spellType, endTime, ...) HealComm_HealEvent(event, casterGUID, spellID, spellType, endTime, ...) end)
		HealComm.RegisterCallback(self, "HealComm_HealDelayed", function(event, casterGUID, spellID, spellType, endTime, ...) HealComm_HealEvent(event, casterGUID, spellID, spellType, endTime, ...) end)
		HealComm.RegisterCallback(self, "HealComm_HealStopped", function(event, casterGUID, spellID, spellType, interrupted, ...) HealComm_HealEvent(event, casterGUID, spellID, spellType, interrupted, ...) end)
		HealComm.RegisterCallback(self, "HealComm_ModifierChanged", function(event, guid) HealComm_ModifierChanged(event, guid) end)
	end
end

local function Healium_ShowHidePercentage(frame)
	if Healium.ShowPercentage and (frame.HasRole == nil) then
		frame.HPText:Show()
	else
		frame.HPText:Hide()
	end
end

function HealComm_HealEvent(event, casterGUID, spellID, spellType, endTime, ...)

	for i=1, select("#", ...) do
		local targetGUID = select(i, ...)
		Healium_UpdateIncomingHealth(targetGUID)
	end
end

function HealComm_ModifierChanged(event, guid)
	Healium_UpdateIncomingHealth(guid)
end

function Healium_UpdateIncomingHealth(targetGUID)
	for unit, j in pairs(Healium_Units) do
		if targetGUID == UnitGUID(unit) then
			for _,NamePlate in pairs(Healium_Units[unit]) do
				local Health = UnitHealth(unit)
				local MaxHealth = UnitHealthMax(unit)
				IncomingHealth = HealComm:GetHealAmount(targetGUID, HealComm.ALL_HEALS)
				if IncomingHealth then
					Health = Health + IncomingHealth
				else
					Health = 0
				end
				NamePlate.PredictBar:SetMinMaxValues(0, MaxHealth)
				NamePlate.PredictBar:SetValue(Health)
			end
		end
	end
end

function Healium_UpdatePercentageVisibility()
	for _, k in ipairs(Healium_Frames) do
		Healium_ShowHidePercentage(k)
	end
end

-- Sets the health bar color based on the unit's health ONLY
local function UpdateHealthBar(HPPercent, frame)
	if (HPPercent > LowHP) then
		frame.HealthBar:SetStatusBarColor(0,1,0,1)
	end
	if (HPPercent < LowHP) then
		frame.HealthBar:SetStatusBarColor(1,0.9,0,1)
	end
	if (HPPercent < VeryLowHP) then
		frame.HealthBar:SetStatusBarColor(1,0,0,1)
	end
end

function Healium_UpdateClassColors()
	for _, k in ipairs(Healium_Frames) do
		if (k.TargetUnit) then
			if not UnitExists(k.TargetUnit) then return end
			if Healium.UseClassColors then
				local class = select(2, UnitClass(k.TargetUnit)) or "WARRIOR"
				local color = RAID_CLASS_COLORS[class]
				k.HealthBar:SetStatusBarColor(color.r, color.g, color.b)
			else
				local Health = UnitHealth(k.TargetUnit)
				local MaxHealth = UnitHealthMax(k.TargetUnit)
				HPPercent =  Health / MaxHealth
				UpdateHealthBar(HPPercent, k)
			end
		end
	end
end

function Healium_UpdateUnitHealth(UnitName, NamePlate)
	if not NamePlate then return end
	if not UnitExists(UnitName) then return end

	local Health = UnitHealth(UnitName)
	local MaxHealth = UnitHealthMax(UnitName)
	local isDead

	if UnitIsDeadOrGhost(UnitName) then
		Health = 0
		isDead = 1
	end

	local HPPercent =  Health / MaxHealth

	if HPPercent > 1 then
		HPPercent = 1
	end

	if HPPercent < 0 then
		HPPercent = 0
	end

	if isDead then
		NamePlate.HPText:SetText( "dead" )
	else
		NamePlate.HPText:SetText( format("%.1i%%", HPPercent*100))
	end

	NamePlate.HealthBar:SetMinMaxValues(0,MaxHealth)
	NamePlate.HealthBar:SetValue(Health)

	if Healium.EnableDebufs and Healium.EnableDebufHealthbarColoring and NamePlate.hasDebuf then
		NamePlate.HealthBar:SetStatusBarColor(NamePlate.debuffColor.r, NamePlate.debuffColor.g, NamePlate.debuffColor.b)
	elseif Healium.UseClassColors then
		local class = select(2, UnitClass(UnitName)) or "WARRIOR"
		local color = RAID_CLASS_COLORS[class]
		NamePlate.HealthBar:SetStatusBarColor(color.r, color.g, color.b)
	else
		UpdateHealthBar(HPPercent, NamePlate)
	end

end

function Healium_UpdateUnitMana(UnitName, NamePlate)
	if not NamePlate then return end
	if not UnitExists(UnitName) then return end

	if NamePlate.showMana == nil then return end

	local Mana = UnitPower(UnitName, SPELL_POWER_MANA)
	local MaxMana = UnitPowerMax(UnitName, SPELL_POWER_MANA)

	if UnitIsDeadOrGhost(UnitName) then
		Mana = 0
	end

	NamePlate.ManaBar:SetMinMaxValues(0,MaxMana)
	NamePlate.ManaBar:SetValue(Mana)
end

function Healium_UpdateShowMana()
	if Healium.ShowMana then
		HealiumFrame:RegisterEvent("UNIT_MANA")
		HealiumFrame:RegisterEvent("UNIT_DISPLAYPOWER")
	else
		HealiumFrame:UnregisterEvent("UNIT_MANA")
		HealiumFrame:UnregisterEvent("UNIT_DISPLAYPOWER")
	end

	for _, k in ipairs(Healium_Frames) do
		if (k.TargetUnit) then
			HealiumUnitFames_CheckPowerType(k.TargetUnit, k)
			Healium_UpdateUnitMana(k.TargetUnit, k)
		end

		if InCombatLockdown() then
			k.fixShowMana = true
		else
			Healium_UpdateManaBarVisibility(k)
		end
	end
end

function Healium_UpdateManaBarVisibility(frame)
	if Healium.ShowMana then
		frame.ManaBar:Show()
		frame.HealthBar:SetWidth(111)
		frame.HealthBar:SetPoint("TOPLEFT", 7, -2)
		frame.PredictBar:SetWidth(111)
		frame.PredictBar:SetPoint("TOPLEFT", 7, -2)
	else
		frame.ManaBar:Hide()
		frame.HealthBar:SetWidth(116)
		frame.HealthBar:SetPoint("TOPLEFT", 2, -2)
		frame.PredictBar:SetWidth(116)
		frame.PredictBar:SetPoint("TOPLEFT", 2, -2)

	end

	Healium_UpdateUnitHealth(frame.TargetUnit, frame)
end

function Healium_UpdateShowBuffs()
--	if Healium.ShowBuffs then
--		HealiumFrame:RegisterEvent("UNIT_AURA")
--	else
--		HealiumFrame:UnregisterEvent("UNIT_AURA")
--	end

	for _, k in ipairs(Healium_ShownFrames) do
		if (k.TargetUnit) then
			Healium_UpdateUnitBuffs(k.TargetUnit, k)
		end
	end
end

function Healium_UpdateUnitThreat(UnitName, NamePlate)
	if not NamePlate then return end
	if not UnitExists(UnitName) then return end

	if Healium.ShowThreat == nil then
		NamePlate.AggroBar:SetAlpha(0)
		return
	end

	local status = UnitThreatSituation(UnitName)

	if status and status > 1 then
		local r, g, b = GetThreatStatusColor(status)
		NamePlate.AggroBar:SetBackdropBorderColor(r,g,b,1)
		NamePlate.AggroBar:SetAlpha(1)
	else
		NamePlate.AggroBar:SetAlpha(0)
	end
end

function Healium_UpdateShowThreat()
	if Healium.ShowThreat then
		HealiumFrame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
	else
		HealiumFrame:UnregisterEvent("UNIT_THREAT_SITUATION_UPDATE")
	end

	for _, k in ipairs(Healium_Frames) do
		if (k.TargetUnit) then
			if Healium.ShowThreat then
				Healium_UpdateUnitThreat(k.TargetUnit, k)
			else
				k.AggroBar:SetAlpha(0)
			end
		end
	end
end

function Healium_UpdateUnitRole(UnitName, NamePlate)
	if not NamePlate then return end
	if not UnitExists(UnitName) then return end

	local icon = NamePlate.HealthBar.RoleIcon

	if not Healium.ShowRole then
		icon:Hide()
		NamePlate.HasRole = nil
		Healium_ShowHidePercentage(NamePlate)
		return
	end

	local role = UnitGroupRolesAssigned(UnitName);

	if ( role == "TANK" or role == "HEALER" or role == "DAMAGER") then
		NamePlate.HasRole = true
		icon:SetTexCoord(GetTexCoordsForRoleSmallCircle(role))
		icon:Show()
	else
--		icon:SetTexCoord(GetTexCoordsForRoleSmallCircle("TANK"))
--		icon:Show()
		NamePlate.HasRole = nil
		icon:Hide()
	end

	Healium_ShowHidePercentage(NamePlate)
end

local function Healium_UpdateRoles()

	for _, k in ipairs(Healium_Frames) do
		if (k.TargetUnit) then
			Healium_UpdateUnitRole(k.TargetUnit, k)
		end
	end
end

function Healium_UpdateShowRole()
	if Healium.ShowRole then
		HealiumFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
	else
		HealiumFrame:UnregisterEvent("PARTY_MEMBERS_CHANGED")
	end

	Healium_UpdateRoles()
end

function Healium_UpdateShowIncomingHeals()
	if Healium.ShowIncomingHeals then
		HealiumFrame:RegisterEvent("UNIT_HEAL_PREDICTION")
	else
		HealiumFrame:UnregisterEvent("UNIT_HEAL_PREDICTION")
	end

	for _, k in ipairs(Healium_Frames) do
		if Healium.ShowIncomingHeals then
			k.PredictBar:Show()
		else
			k.PredictBar:Hide()
		end
	end
end

local function GetSpellID(spell)
	local i = 1
	local spellID
	local highestRank
	while true do
		local spellName = GetSpellName(i, SpellBookFrame.bookType)
		if (not spellName) then
			break
		end
		if (spellName == spell) then
			spellID = i
			highestRank = spellRank
		end
		i = i + 1
		if (i > 300) then
			break
		end
	end
	return spellID, highestRank
end

-- Loops through Healium_Spell.Name[] and updates it's corresponding .ID[] and .Icon[]
-- Warning UpdateSpells() is a global function from Blizzard.
local function Healium_UpdateSpells()
	for k, v in ipairs (Healium_Spell.Name) do
		Healium_Spell.ID[k] = GetSpellID(Healium_Spell.Name[k])
		if (Healium_Spell.ID[k]) then
			Healium_Spell.Icon[k] = GetSpellTexture(Healium_Spell.ID[k], BOOKTYPE_SPELL)
		else
			Healium_Spell.Icon[k] = nil
		end
	end

	Healium_UpdateButtonSpells()
end

-- does special checks for specific buffs/debuffs
function Healium_UpdateSpecialBuffs(unit)

	if HealiumClass == "PRIEST" then
		local Profile = Healium_GetProfile()

		for i=1, Profile.ButtonCount, 1 do

			-- special check for Power Word: Shield
			if Profile.SpellNames[i] == PWSName then
				local units = Healium_Units[unit]

				if units then
					local name, _, _, _, _, weakendSoulduration, expirationTime, _, _, _, spellID = UnitDebuff(unit, WeakendSoulName)

					if name then
						local startTime = expirationTime - weakendSoulduration

						for _, frame in pairs(units) do
							local button = frame.buttons[i]
							if button and button:IsShown() then
								button.cooldown:SetCooldown(startTime, weakendSoulduration)
							end
						end
					end
				end
			end
		end
		return
	end

	if HealiumClass == "DRUID" then
		local Profile = Healium_GetProfile()

		for i=1, Profile.ButtonCount, 1 do

			-- special check for Swift Mend
			if Profile.SpellNames[i] == SwiftMendName then
				local units = Healium_Units[unit]

				if units then
--					local start, duration, enable = GetSpellCooldown(Healium_ButtonIDs[i], SpellBookFrame.bookType)
					local rejuvName, _, _, _, _, rejuvDuration, rejuvExpirationTime = UnitBuff(unit, RejuvinationName)
					local regrowthName, _, _, _, _, regrowthDuration, regrowthExpirationTime = UnitBuff(unit, RegrowthName)

					local enabled = rejuvName or regrowthName

					for _, frame in pairs(units) do
						local button = frame.buttons[i]
						if button then
							if enabled then
								button.icon.disabled = nil
								button.icon:SetVertexColor(1.0, 1.0, 1.0)
							else
								button.icon.disabled = true
								button.icon:SetVertexColor(0.4, 0.4, 0.4)
							end
						end
					end


				end
			end
		end
		return

	end
end

-- Efficient cooldowns
function Healium_UpdateButtonCooldownsByColumn(column)

	if Healium_ButtonIDs[column] then
		local start, duration, enable = GetSpellCooldown(Healium_ButtonIDs[column], SpellBookFrame.bookType)

		for unit, j in pairs(Healium_Units) do
			for x,y in pairs(j) do
				local button = y.buttons[column]
				if button then
					if button:IsShown() then
						CooldownFrame_SetTimer(button.cooldown, start, duration, enable)
					end
				end
			end
			Healium_UpdateSpecialBuffs(unit)
		end
	end
end

local function Healium_UpdateButtonCooldowns()
	local count = Healium_GetProfile().ButtonCount

	for i=1, count, 1 do
		Healium_UpdateButtonCooldownsByColumn(i)
	end
end

function Healium_UpdateButtonIcon(button, texture)
	button.icon.disabled = nil

	if InCombatLockdown() then
		return
	end

	if (texture) then
		button.icon:SetTexture(texture)
	else
		button.icon:SetTexture("Interface/Icons/INV_Misc_QuestionMark")
	end
end

function Healium_UpdateButtonIcons()
	if InCombatLockdown() then
		return
	end

	local Profile = Healium_GetProfile()
	for i=1, Healium_MaxButtons, 1 do
		local texture = Profile.SpellIcons[i]

		for _, k in ipairs(Healium_Frames) do
			local button = k.buttons[i]
			if button then
				Healium_UpdateButtonIcon(button, texture)
			end
		end
   end
end

function Healium_UpdateButtonSpell(button, spell, id, checkforCombat)

	local oldspell = button:GetAttribute("spell")
	local oldid = button.id

	if (oldspell == spell) and (oldid == id) then
		return
	end

	if checkforCombat then
		if InCombatLockdown() then
			return
		end
	end

	button.id = id
	button:SetAttribute("spell", spell)
end

function Healium_UpdateButtonSpells()
	local Profile = Healium_GetProfile()

	for i=1, Healium_MaxButtons, 1 do
		local spell = Profile.SpellNames[i]
		local id

		-- try existing ID first as an optimization
		-- This code section caused an issue when a user trained a new spell with the same name, it would prevent it from showing the tooltip of the newer version.
--		if Healium_ButtonIDs[i] then
--			local spellName = GetSpellName(Healium_ButtonIDs[i], BOOKTYPE_SPELL )
--			if spellName == spell then
--				id = Healium_ButtonIDs[i]
--			end
--		end

		-- look up in healing spells list
		if not id then
			for k=1, Healium_MaxClassSpells, 1 do
				if (spell == Healium_Spell.Name[k]) then
					id = Healium_Spell.ID[k]
					break
				end
			end
		end

		if not id then
			id = GetSpellID(spell) -- slow method
		end

		Healium_ButtonIDs[i] = id

		for _,k in ipairs(Healium_Frames) do
			local button = k.buttons[i]
			if button then
				Healium_UpdateButtonSpell(button, spell, id, true)
			end
		end
	end

	Healium_UpdateCures()

end

local function UpdateButtonVisibility(frame)
	if InCombatLockdown() then
		return
	end

	-- Hide all buttons
	for i=1, Healium_MaxButtons, 1 do
		local button = frame.buttons[i]
		if button then
			button:Hide()
		end
	end

	-- Show buttons.  The buttons will not actually show up unless their nameplate are visible so it's fine to show them like this.
	local count = Healium_GetProfile().ButtonCount

	for i=1, count, 1 do
		local button = frame.buttons[i]
		if button then
			button:Show()
		end
	end
end

function Healium_UpdateButtonVisibility()
	if InCombatLockdown() then
		return
	end

	for _,k in ipairs(Healium_Frames) do
		UpdateButtonVisibility(k)
	end
end

function Healium_UpdateButtons()
	Healium_UpdateButtonVisibility()
	Healium_UpdateButtonSpells()
	Healium_UpdateButtonIcons()
end

function Healium_RangeCheckButton(button)
    if (button.id) then
        local isUsable, noMana = IsUsableSpell(button.id, BOOKTYPE_SPELL)

		if noMana then
			button.icon:SetVertexColor(0.5, 0.5, 1.0)
		else
			if not button.icon.disabled then
				button.icon:SetVertexColor(1.0, 1.0, 1.0)
			end
		end


--[[
        if isUsable then
      	 button.icon:SetVertexColor(1.0, 1.0, 1.0)
      	elseif noMana then
      	 button.icon:SetVertexColor(0.5, 0.5, 1.0)
      	else
      	  button.icon:SetVertexColor(0.3, 0.3, 0.3)
      	end
--]]
       	local inRange = IsSpellInRange(button.id, BOOKTYPE_SPELL, button:GetParent().TargetUnit)

		if SpellHasRange(button.id, BOOKTYPE_SPELL)  then
			if (inRange == 0) or (inRange == nil) then
				button.icon:SetVertexColor(1.0, 0.3, 0.3)
			end
		end
	end
end

function Healium_DeepCopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end


-- Sets persisted variables to their default, if they do not exist.
local function InitVariables()
	if (not Healium.RaidScale) then
		Healium.RaidScale = 1.0
	end

	if (not Healium.RangeCheckPeriod) then
		Healium.RangeCheckPeriod = DefaultRangeCheckPeriod
	end

	if (Healium.RangeCheckPeriod > MaxRangeCheckPeriod or Healium.RangeCheckPeriod < MinRangeCheckPeriod) then
		Healium.RangeCheckPeriod = DefaultRangeCheckPeriod
	end

	if Healium.ShowGroupFrames == nil then
		Healium.ShowGroupFrames = { }
	end

	if Healium.ShowToolTips == nil then
		Healium.ShowToolTips = true
	end

	if Healium.ShowMana == nil then
		Healium.ShowMana = true
	end

	if Healium.ShowThreat == nil then
		Healium.ShowThreat = true
	end

	if Healium.ShowRole == nil then
		Healium.ShowRole = true
	end

	if Healium.ShowIncomingHeals == nil then
		Healium.ShowIncomingHeals = true
	end

	if Healium.ShowPercentage == nil then
		Healium.ShowPercentage = true
	end

	if Healium.UseClassColors == nil then
		Healium.UseClassColors = false
	end

	if Healium.ShowBuffs == nil then
		Healium.ShowBuffs = true
	end

	if Healium.ShowDefaultPartyFrames == nil then
		Healium.ShowDefaultPartyFrames = false
	end

	if Healium.ShowPartyFrame == nil then
		Healium.ShowPartyFrame = true
	end

	if Healium.ShowPetsFrame == nil then
		Healium.ShowPetsFrame = true
	end

	if Healium.ShowMeFrame == nil then
		Healium.ShowMeFrame = false
	end

	if Healium.ShowTanksFrame == nil then
		Healium.ShowTanksFrame = false
	end

	if Healium.ShowFriendsFrame == nil then
		Healium.ShowFriendsFrame = false
	end

	if Healium.HideCloseButton == nil then
		Healium.HideCloseButton = false
	end

	if Healium.HideCaptions == nil then
		Healium.HideCaptions = false
	end

	if Healium.LockFrames == nil then
		Healium.LockFrames = false
	end

	if Healium.EnableDebufs == nil then
		Healium.EnableDebufs = true
	end

	if Healium.EnableClique == nil then
		Healium.EnableClique = false
	end

	if Healium.EnableDebufAudio == nil then
		Healium.EnableDebufAudio = true
	end

	if Healium.EnableDebufHealthbarHighlighting == nil then
		Healium.EnableDebufHealthbarHighlighting = true
	end

	if Healium.EnableDebufButtonHighlighting == nil then
		Healium.EnableDebufButtonHighlighting = true
	end

	if Healium.EnableDebufHealthbarColoring == nil then
		Healium.EnableDebufHealthbarColoring = false
	end

	if HealiumGlobal.Friends == nil then
		HealiumGlobal.Friends = { }
	end

	if Healium.Profiles == nil then
		if (HealiumDropDownButton ~= nil) and (HealiumDropDownButtonIcon ~= nil) and (Healium.ButtonCount ~= nil) then
		-- Import profiles from the old HealiumDropDownButton HealiumDropDownButtonIcon saved variables
			Healium_Print("Importing button profiles.")
			Healium_Print(Healium_AddonColor .. Healium_AddonName .. "|r now has seperate button configurations for each talent specialization.")
			Healium_Print("Both " .. Healium_AddonColor .. Healium_AddonName .. "|r button configurations will be set to your current button configuration.")
			Healium_Print("Any button changes you make will now only be applied to the configuration specific to the talent specialization you are in at the time of the change.")
			local config = {
				ButtonCount = Healium.ButtonCount,
				SpellNames = Healium_DeepCopy(HealiumDropDownButton),
				SpellIcons = Healium_DeepCopy(HealiumDropDownButtonIcon),
			}
			Healium.Profiles = {
				[1] = Healium_DeepCopy(config),
				[2] = Healium_DeepCopy(config)
			}
		else
			Healium.Profiles = { }
		end
	end

	-- Healium.Profiles may exist at this point, but may not be fully inited
	local DefaultProfile = {
		ButtonCount = DefaultButtonCount,
		SpellNames = { },
		SpellIcons = { }
	}

	if Healium.Profiles[1] == nil then
		Healium.Profiles[1] = Healium_DeepCopy(DefaultProfile)
	end

	if Healium.Profiles[2] == nil then
		Healium.Profiles[2] = Healium_DeepCopy(DefaultProfile)
	end

	-- remove old saved variables
	HealiumDropDownButton = nil
	HealiumDropDownButtonIcon = nil
end

function Healium_OnEvent(self, event, ...)
	local arg1 = select(1, ...)
	local arg2 = select(2, ...)

	-------------------------------------------------------------
	-- [[ Update Unit Health Display Whenever Their HP Changes ]]
	-------------------------------------------------------------
    if (event == "UNIT_HEALTH") or (event == "UNIT_HEAL_PREDICTION") then
--		if (not HealiumActive) then return 0 end

		if Healium_Units[arg1] then
			for _,v  in pairs(Healium_Units[arg1]) do
				Healium_UpdateUnitHealth(arg1, v)
			end
		end
		return
	end

    if event == "UNIT_POWER" then
		if Healium_Units[arg1] then
			for _,v  in pairs(Healium_Units[arg1]) do
				Healium_UpdateUnitMana(arg1, v)
			end
		end
		return
	end

	if event == "UNIT_AURA" then
		if Healium_Units[arg1] then
			for _,v  in pairs(Healium_Units[arg1]) do
				if Healium.ShowBuffs then
					Healium_UpdateUnitBuffs(arg1, v)
				end
				Healium_UpdateSpecialBuffs(arg1)
			end
		end
		return
	end

	if event == "UNIT_THREAT_SITUATION_UPDATE" and Healium.ShowThreat then
		if Healium_Units[arg1] then
			for _,v  in pairs(Healium_Units[arg1]) do
				Healium_UpdateUnitThreat(arg1, v)
			end
		end
		return
	end

	if event == "SPELL_UPDATE_COOLDOWN" and Healium.EnableCooldowns then
		Healium_UpdateButtonCooldowns()
		return
	end

	if event == "PLAYER_REGEN_ENABLED" then
		for _,v in ipairs(Healium_FixNameplates) do
			Healium_ShowHidePercentage(v)

			if v.fixCreateButtons then
				Healium_CreateButtonsForNameplate(v)
				UpdateButtonVisibility(v)
				v.fixCreateButtons = nil
			end

			if v.fixShowMana then
				Healium_UpdateManaBarVisibility(v)
				v.fixShowMana = nil
			end
		end

		Healium_FixNameplates = {}
		return
	end

	-- Use this ADDON_LOADED event instead of VARIABLES_LOADED.
	-- ADDON_LOADED will not be called until the variables are loaded.
	-- VARIABLES_LOADED's order can no longer be relied upon. (it kind of seems random to me)
	if ((event == "ADDON_LOADED") and (string.lower(arg1) == string.lower(Healium_AddonName))) then
		Healium_DebugPrint("ADDON_LOADED")

		InitVariables()
		Healium_InitSpells(HealiumClass, HealiumRace)
		Healium_InitDebuffSound()
		Healium_CreateMiniMapButton()
		Healium_CreateConfigPanel(HealiumClass, AddonVersion)
		Healium_InitSlashCommands()
		Healium_InitMenu()
		Healium_CreateUnitFrames()
		Healium_SetScale()
		Healium_UpdatePercentageVisibility()
		Healium_UpdateClassColors()
		Healium_ShowHidePartyFrame()
		Healium_ShowHidePetsFrame()
		Healium_ShowHideMeFrame()
		Healium_ShowHideTanksFrame()
		Healium_ShowHideFriendsFrame()
		Healium_UpdateShowMana()
		Healium_UpdateShowBuffs()
		Healium_UpdateFriends()
		Healium_UpdateShowThreat()
		Healium_UpdateShowRole()
		Healium_UpdateShowIncomingHeals()

		for i=1, 8, 1 do
			Healium_ShowHideGroupFrame(i)
		end

		Healium_UpdateButtons()

		return
	end

	if ((event == "UNIT_SPELLCAST_SENT") and ( (arg2 == ActivatePrimarySpecSpellName) or (arg2 == ActivateSecondarySpecSpellName))  ) then
--		DEFAULT_CHAT_FRAME:AddMessage("Healium Debug: Respecing Start")
		self.Respecing = true
		return
	end

	if ( ((event == "UNIT_SPELLCAST_INTERRUPTED") or (event == "UNIT_SPELLCAST_SUCCEEDED")) and (arg1 == "player") and ( (arg2 == ActivatePrimarySpecSpellName) or (arg2 == ActivateSecondarySpecSpellName))  ) then
--		DEFAULT_CHAT_FRAME:AddMessage("Healium Debug: Respecing Interrupt or succeeded")
		self.Respecing = nil
	end

	-- This is not sent during initialization during a reload
	if (event == "PLAYER_TALENT_UPDATE") then
		Healium_DebugPrint("PLAYER_TALENT_UPDATE")
		self.Respecing = nil

		Healium_UpdateSpells()
		Healium_UpdateButtons()
		Healium_Update_ConfigPanel()
		return
	end


	if ((event == "SPELLS_CHANGED") and (not self.Respecing)) then
		Healium_DebugPrint("SPELLS_CHANGED")
		-- Populate the Healium_Spell Table with ID and Icon data.
		Healium_UpdateSpells()
	end

	if ((event == "PLAYER_ENTERING_WORLD") and (not self.Respecing)) then
		Healium_DebugPrint("PLAYER_ENTERING_WORLD")
		-- Populate the Healium_Spell Table with ID and Icon data.
		Healium_UpdateSpells()
	end

		-- Do not use this event for anything meaningful (see comment above ADDON_LOADED for reason)
--[[
	if (event == "VARIABLES_LOADED") then
		Healium_DebugPrint("VARIABLES_LOADED")
		return
	end

	if (event == "PLAYER_ALIVE") then
		Healium_DebugPrint("PLAYER_ALIVE")
		return
	end
--]]

	if event == "UNIT_DISPLAYPOWER" then
		if Healium_Units[arg1] then
			for i,v  in pairs(Healium_Units[arg1]) do
				HealiumUnitFames_CheckPowerType(arg1, v)
			end
		end

		return
	end

	if event == "RAID_TARGET_UPDATE" then
		for _, k in ipairs(Healium_Frames) do
			if (k.TargetUnit) then
				if not UnitExists(k.TargetUnit) then return end
				local index = GetRaidTargetIndex(k.TargetUnit);
				if ( index ) then
					SetRaidTargetIconTexture(k.raidTargetIcon, index);
					k.raidTargetIcon:Show();
				else
					k.raidTargetIcon:Hide();
				end
			end
		end

		return
	end

	if event == "UNIT_NAME_UPDATE" then
		if Healium_Units[arg1] then
			local name = strupper(UnitName(arg1))
			for _,v  in pairs(Healium_Units[arg1]) do
					v.name:SetText(name)
			end
		end
		return
	end

	if event == "PARTY_MEMBERS_CHANGED" and Healium.ShowRole then
		Healium_UpdateRoles()
		return
	end
end

