-- Unit Frames Code

local PartyFrame = nil
local PetsFrame = nil
local MeFrame = nil
local TanksFrame = nil
local FriendsFrame = nil
local GroupFrames = { }
local TargetFrame = nil
local FocusFrame = nil

local PartyFrameWasShown = nil
local PetsFrameWasShown = nil
local MeFrameWasShown = nil
local TanksFrameWasShown = nil
local FriendsFrameWasShown = nil
local GroupFramesWasShown = { }
local TargetFrameWasShown = nil
local FocusFrameWasShown = nil

local MaxBuffs = 6
local xSpacing = 2
local NamePlateHeight = 28
local LastDebuffSoundTime = GetTime()

local UnitFrames = { } -- table of all unit frames

ClickCastFrames = ClickCastFrames or {} -- used by Clique and any other click cast frames
local DebuffSoundPath

Healium_Sounds = {
	{ ["Alliance Bell"] = "Sound\\Doodad\\BellTollAlliance.wav" },
	{ ["Bellow"] = "Sound\\Doodad\\BellowIn.wav" },
	{ ["Dwarf Horn"] = "Sound\\Doodad\\DwarfHorn.wav" },
	{ ["Gruntling Horn A"] = "Sound\\Events\\gruntling_horn_aa.wav" },
	{ ["Gruntling Horn B"] = "Sound\\Events\\gruntling_horn_bb.wav" },
	{ ["Horde Bell"] = "Sound\\Doodad\\BellTollHorde.wav" },
	{ ["Man Scream"] = "Sound\\Events\\EbonHold_ManScream1_02.wav" },
	{ ["Night Elf Bell"] = "Sound\\Doodad\\BellTollNightElf.wav" },
	{ ["Space Death"] = "Sound\\Effects\\DeathImpacts\\SpaceDeathUni.wav" },
	{ ["Tribal Bell"] = "Sound\\Doodad\\BellTollTribal.wav" },
	{ ["Wisp"] = "Sound\\Event Sounds\\Wisp\\WispPissed2.wav" },
	{ ["Woman Scream"] = "Sound\\Events\\EbonHold_WomanScream1_02.wav" },
}

function Healium_GetSoundPath(sound)
	for i,j in ipairs(Healium_Sounds) do
		if sound == next(j, nil) then
			return j[sound]
		end
	end

	return nil
end

function Healium_InitDebuffSound()
	DebuffSoundPath = Healium_GetSoundPath(Healium.DebufAudioFile)

	if DebuffSoundPath == nil then
		Healium.DebufAudioFile = "Horde Bell"
		DebuffSoundPath = Healium_GetSoundPath(Healium.DebufAudioFile)
	end
end

function Healium_PlayDebuffSound()
	PlaySoundFile(DebuffSoundPath)
end

--[[
local function initialConfigFunction(frame)
	-- The only thing you are especially allowed to do in the initialConfigFunction() is to change attributes.
	-- CreateFrame(), :Show(), :Hide() etc will taint in combat still

	Healium_DebugPrint("Inital Config")
	frame.buttons = { }
	frame:RegisterForClicks("AnyUp")

	table.insert(Healium_Frames, frame)

	if Healium.EnableClique then
		ClickCastFrames[frame] = true
	end

	-- configure buff frames
	frame.buffs = { }

	local framename = frame:GetName()
	for i=1, MaxBuffs, 1 do
		local buffFrame = _G[framename.."_Buff"..i]
		local name = buffFrame:GetName()
		buffFrame.icon = _G[name.."Icon"]
		buffFrame.cooldown = _G[name.."Cooldown"]
		buffFrame.count = _G[name.."Count"]
		buffFrame.border = _G[name.."Border"]
		buffFrame.id = i
		frame.buffs[i] = buffFrame
	end

	if InCombatLockdown() then
		frame.fixCreateButtons = true
		table.insert(Healium_FixNameplates, frame)
		Healium_DebugPrint("Unit Frame created during combat. Its buttons will not be available until combat ends.")
	else
		if (not Healium.ShowPercentage) then frame.HPText:Hide() end
		Healium_CreateButtonsForNameplate(frame)
	end
end
--]]


local function CreateButton(ButtonName,ParentFrame,xoffset)
	local button = CreateFrame("Button", ButtonName, ParentFrame, "HealiumHealButtonTemplate")
	button:SetPoint("LEFT", ParentFrame, "RIGHT", xoffset, 0)
	return button
end

-- please make sure we are not in combat before calling this function
function Healium_CreateButtonsForNameplate(frame)
	local x = xSpacing
	local Profile = Healium_GetProfile()

	for i=1, Healium_MaxButtons, 1 do
		name = frame:GetName()
		button = CreateButton(name.."_Heal"..i, frame, x)
		x = x + xSpacing + NamePlateHeight

		button.index = i -- .index is used by drag operation
		frame.buttons[i] = button

		-- set spell attribute for button
		local spell = Profile.SpellNames[i]
		Healium_UpdateButtonSpell(button, spell, Healium_ButtonIDs[i], false)

		-- set icon for button
		local texture = Profile.SpellIcons[i]
		Healium_UpdateButtonIcon(button, texture)

		if (i > Profile.ButtonCount) then
			button:Hide()

			if button:IsShown() then
				Healium_Warn("Failed to hide heal button")
			end
		else
			button:Show()

			if not button:IsShown() then
				Healium_Warn("Failed to show heal button")
			end
		end
	end
end

local function SetHeaderAttributes(frame)
	--frame.initialConfigFunction = initialConfigFunction

	frame:SetAttribute("showPlayer", "true")
	frame:SetAttribute("maxColumns", 1)
	frame:SetAttribute("columnAnchorPoint", "LEFT")
	frame:SetAttribute("point", "TOP")
	frame:SetAttribute("template", "HealiumUnitFrames_ButtonTemplate")
	frame:SetAttribute("templateType", "Button")
	frame:SetAttribute("unitsPerColumn", 5)
end

local function CreateHeader(TemplateName, FrameName, ParentFrame)
	local f = CreateFrame("Frame", FrameName, ParentFrame, TemplateName)
	ParentFrame.hdr = f
	f:SetPoint("TOPLEFT", ParentFrame, "BOTTOMLEFT")
	SetHeaderAttributes(f)
	return f
end

local function UpdateCloseButton(frame)
	-- Hide close button if set to
	if not InCombatLockdown() then
		if Healium.HideCloseButton then
			frame.CaptionBar.CloseButton:Hide()
		else
			frame.CaptionBar.CloseButton:Show()
		end
	end
end

local function UpdateHideCaption(frame)
	if Healium.HideCaptions then
		frame.CaptionBar:SetAlpha(0)
	else
		frame.CaptionBar:SetAlpha(1)
	end
end

local function CreateUnitFrame(FrameName, Caption, IsPet, Group)
	local uf = CreateFrame("Frame", FrameName, UIParent, "HealiumUnitFrameTemplate")
	table.insert(UnitFrames, uf)
	uf.CaptionBar.Caption:SetText(Caption)
	UpdateCloseButton(uf)
	UpdateHideCaption(uf)
	return uf
end

local function CreatePetHeader(FrameName, ParentFrame)
	local h = CreateHeader("SecureGroupPetHeaderTemplate", FrameName, ParentFrame)
	h:SetAttribute("filterOnPet", "true")
	h:SetAttribute("unitsPerColumn", 40) -- allow pets frame to show more than 5
	h:SetAttribute("showSolo", "true")
	h:SetAttribute("showRaid", "true")
	h:SetAttribute("showParty", "true")
	h:Show()
	return h
end

local function CreateGroupHeader(FrameName, ParentFrame, Group)
	local h = CreateHeader("SecureGroupHeaderTemplate", FrameName, ParentFrame)
	h:SetAttribute("groupFilter", Group)
	h:SetAttribute("showRaid", "true")
	h:Show()
	return h
end

local function CreateTanksHeader(FrameName, ParentFrame)
	local h = CreateHeader("SecureGroupHeaderTemplate", FrameName, ParentFrame)
	h:SetAttribute("groupFilter", "MAINTANK")
	h:SetAttribute("showRaid", "true")
	h:Show()
	return h
end

local function CreatePartyHeader(FrameName, ParentFrame)
	local h = CreateHeader("SecureGroupHeaderTemplate", FrameName, ParentFrame)
	h:SetAttribute("showSolo", "true")
	h:Show()
	return h
end

local function CreateMeHeader(FrameName, ParentFrame)
	local h = CreateHeader("SecureGroupHeaderTemplate", FrameName, ParentFrame)
	h:SetAttribute("showSolo", "true")
	h:SetAttribute("nameList", UnitName("Player"))
	h:Show()
	return h
end

local function CreateFriendsHeader(FrameName, ParentFrame)
	local h = CreateHeader("SecureGroupHeaderTemplate", FrameName, ParentFrame)
	h:SetAttribute("showSolo", "true")
	h:SetAttribute("showRaid", "true")
	h:SetAttribute("showParty", "true")
	h:SetAttribute("unitsPerColumn", 20) -- allow friends frame to show more than 5
	h:Show()
	return h
end

local function CreateCustomHeader(FrameName, ParentFrame, Unit)
	local h = CreateFrame("Button", FrameName, ParentFrame, "HealiumUnitFrames_ButtonTemplate")
	h.isCustom = true
	ParentFrame.hdr = h
	h:SetAttribute("unit", Unit)
	h:SetPoint("TOPLEFT", ParentFrame, "BOTTOMLEFT")
	RegisterUnitWatch(h)
	h:Show()
	return h
end

local function CreateGroupUnitFrame(FrameName, Caption, Group)
	local uf = CreateUnitFrame(FrameName, Caption)
	local h = CreateGroupHeader(FrameName .. "_Header", uf, Group)
	return uf
end

local function CreateTanksUnitFrame(FrameName, Caption)
	local uf = CreateUnitFrame(FrameName, Caption)
	local h = CreateTanksHeader(FrameName .. "_Header", uf)
	return uf
end

local function CreatePetUnitFrame(FrameName, Caption)
	local uf = CreateUnitFrame(FrameName, Caption)
	local h = CreatePetHeader(FrameName .. "_Header", uf)
	return uf
end

local function CreateMeUnitFrame(FrameName, Caption)
	local uf = CreateUnitFrame(FrameName, Caption)
	local h = CreateMeHeader(FrameName .. "_Header", uf)
	return uf
end

local function CreateFriendsUnitFrame(FrameName, Caption)
	local uf = CreateUnitFrame(FrameName, Caption)
	local h = CreateFriendsHeader(FrameName .. "_Header", uf)
	return uf
end

local function CreatePartyUnitFrame(FrameName, Caption)
	local uf = CreateUnitFrame(FrameName, Caption)
	local h = CreatePartyHeader(FrameName .. "_Header", uf)
	return uf
end

local function CreateTargetUnitFrame(FrameName, Caption)
	local uf = CreateUnitFrame(FrameName, Caption)
	local h = CreateCustomHeader(FrameName .. "_Header", uf, "target")
	return uf
end

local function CreateFocusUnitFrame(FrameName, Caption)
	local uf = CreateUnitFrame(FrameName, Caption)
	local h = CreateCustomHeader(FrameName .. "_Header", uf, "focus")
	return uf
end

function Healium_UpdateCloseButtons()
	for _,j in pairs(UnitFrames) do
		UpdateCloseButton(j)
	end
end

function Healium_UpdateHideCaptions()
	for _,j in pairs(UnitFrames) do
		UpdateHideCaption(j)
	end
end

function HealiumUnitFrames_OnEnter(self)
	self:SetAlpha(1)
end

function HealiumUnitFrames_OnLeave(self)
	if Healium.HideCaptions then
		self:SetAlpha(0)
	end
end

function HealiumUnitFrames_OnMouseDown(self, button)
	if button == "LeftButton" and not Healium.LockFrames then
		self:StartMoving()
	end

	if button == "RightButton" then
		ToggleDropDownMenu(1, nil, HealiumMenu, self, 0, 0)
	end
end

function HealiumUnitFrames_OnMouseUp(self, button)
	if button == "LeftButton" then
		self:StopMovingOrSizing()
	end

	if button == "RightButton" then

	end
end

function HealiumUnitFrames_ShowHideFrame(self, show)
	if self == PartyFrame then
		Healium.ShowPartyFrame = show
		Healium_ShowPartyCheck:SetChecked(Healium.ShowPartyFrame)
		return
	end

	if self == PetsFrame then
		Healium.ShowPetsFrame = show
		Healium_ShowPetsCheck:SetChecked(Healium.ShowPetsFrame)
		return
	end

	if self == MeFrame then
		Healium.ShowMeFrame = show
		Healium_ShowMeCheck:SetChecked(Healium.ShowMeFrame)
		return
	end

	if self == FriendsFrame then
		Healium.ShowFriendsFrame = show
		Healium_ShowFriendsCheck:SetChecked(Healium.ShowFriendsFrame)
		return
	end

	if self == TanksFrame then
		Healium.ShowTanksFrame = show
		Healium_ShowTanksCheck:SetChecked(Healium.ShowTanksFrame)
		return
	end

	if self == TargetFrame then
		Healium_DebugPrint("ShowHide Target Frame")
		Healium.ShowTargetFrame = show
		Healium_ShowTargetCheck:SetChecked(Healium.ShowTargetFrame)
		Healium_UpdateShowTargetFrame()
		Healium_UpdateTargetFrame()
		return
	end

	if self == FocusFrame then
		Healium_DebugPrint("ShowHide Focus Frame")
		Healium.ShowFocusFrame = show
		Healium_ShowFocusCheck:SetChecked(Healium.ShowFocusFrame)
		Healium_UpdateShowFocusFrame()
		Healium_UpdateFocusFrame()
		return
	end


	for i,j in ipairs(GroupFrames) do
		if self == j then
			Healium.ShowGroupFrames[i] = show
			Healium_ShowGroup1Check:SetChecked(Healium.ShowGroupFrames[1])
			Healium_ShowGroup2Check:SetChecked(Healium.ShowGroupFrames[2])
			Healium_ShowGroup3Check:SetChecked(Healium.ShowGroupFrames[3])
			Healium_ShowGroup4Check:SetChecked(Healium.ShowGroupFrames[4])
			Healium_ShowGroup5Check:SetChecked(Healium.ShowGroupFrames[5])
			Healium_ShowGroup6Check:SetChecked(Healium.ShowGroupFrames[6])
			Healium_ShowGroup7Check:SetChecked(Healium.ShowGroupFrames[7])
			Healium_ShowGroup8Check:SetChecked(Healium.ShowGroupFrames[8])
			return
		end
	end
end

function HealiumUnitFrames_Button_OnLoad(self)
	self.buttons = { }
	self:RegisterForClicks("AnyUp")

	table.insert(Healium_Frames, self)

	if Healium.EnableClique then
		ClickCastFrames[self] = true
	end

	-- configure buff frames
	self.buffs = { }

	local framename = self:GetName()
	for i=1, MaxBuffs, 1 do
		local buffframe = _G[framename.."_Buff"..i]
		local name = buffframe:GetName()
		buffframe.icon = _G[name.."Icon"]
		buffframe.cooldown = _G[name.."Cooldown"]
		buffframe.count = _G[name.."Count"]
		buffframe.border = _G[name.."Border"]
		buffframe.id = i
		self.buffs[i] = buffframe
	end

	if InCombatLockdown() then
		self.fixCreateButtons = true
		table.insert(Healium_FixNameplates, self)
		Healium_DebugPrint("Unit frame created during combat. Its buttons will not be available until combat ends.")
	else
		if (not Healium.ShowPercentage) then self.HPText:Hide() end
		Healium_CreateButtonsForNameplate(self)
	end

	self:RegisterForDrag("RightButton")
end

function HealiumUnitFrames_Button_OnEnter(self)
	local _, powerType = UnitPowerType(self.TargetUnit)
	GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
	GameTooltip:SetUnit(self.TargetUnit)
	GameTooltip:AddLine("Health: |cFF00FF00"..UnitHealth(self.TargetUnit).." / "..UnitHealthMax(self.TargetUnit),1,1,1)
	if (powerType == "MANA") then
		GameTooltip:AddLine("Mana: |cFF0000FF"..UnitPower(self.TargetUnit).." / "..UnitPowerMax(self.TargetUnit),1,1,1)
	elseif (powerType == "RAGE") then
		GameTooltip:AddLine("Rage: |cFFFF0000"..UnitPower(self.TargetUnit).." / "..UnitPowerMax(self.TargetUnit),1,1,1)
	elseif (powerType == "ENERGY") then
		GameTooltip:AddLine("Energy: |cFFFFFF00"..UnitPower(self.TargetUnit).." / "..UnitPowerMax(self.TargetUnit),1,1,1)
	elseif (powerType == "RUNIC_POWER") then
		GameTooltip:AddLine("Runic power: |cFF00D1FF"..UnitPower(self.TargetUnit).." / "..UnitPowerMax(self.TargetUnit),1,1,1)
	end
	GameTooltip:Show()
end

function HealiumUnitFames_CheckPowerType(UnitName, NamePlate)
	local _, powerType = UnitPowerType(UnitName)
	if  (Healium.ShowMana == false) or (UnitExists(UnitName) == nil) or (powerType ~= "MANA") then
--	if  UnitManaMax(UnitName) == nil then
		NamePlate.ManaBar:SetStatusBarColor( .5, .5, .5 )
		NamePlate.ManaBar:SetMinMaxValues(0,1)
		NamePlate.ManaBar:SetValue(1)
		NamePlate.showMana = nil
		return nil
	else
		local powerColor = PowerBarColor[powerType];
		NamePlate.ManaBar:SetStatusBarColor( powerColor.r, powerColor.g, powerColor.b )
		NamePlate.showMana = true
	end

	return true
end



function HealiumUnitFrames_Button_OnShow(self)
	table.insert(Healium_ShownFrames, self)
end

function HealiumUnitFrames_Button_OnHide(self)
	Healium_ShownFrames[self] = nil

	local parent = self:GetParent()

	if not self.isCustom then
		parent = parent:GetParent()
	end

	if parent.childismoving then
		parent:StopMovingOrSizing()
		parent.childismoving = nil
	end

end

function HealiumUnitFrames_Button_OnAttributeChanged(self, name, value)
	if name == "unit" or name == "unitsuffix" then
		local newUnit = SecureButton_GetUnit(self)
		local oldUnit = self.TargetUnit

		Healium_DebugPrint(newUnit)

--		if newUnit == oldUnit then
--			return
--		end

		if newUnit then
			for i=1, Healium_MaxButtons, 1 do
				local button = self.buttons[i]
				if not button then break end

				-- update cooldowns
				local id = Healium_ButtonIDs[i]

				if id then
					local start, duration, enable = GetSpellCooldown(Healium_ButtonIDs[i], BOOKTYPE_SPELL)
					CooldownFrame_SetTimer(button.cooldown, start, duration, enable)
				end
			end

			--if self:IsVisible() then
				local playerName= UnitName(newUnit)
				if playerName ~= nil then
					playerName = strupper(playerName)
				end
				self.name:SetText(playerName)
			--end

			if not Healium_Units[newUnit] then
				Healium_Units[newUnit] = { }
			end

			table.insert(Healium_Units[newUnit], self)

			for i =1, MaxBuffs, 1 do
				self.buffs[i].unit = newUnit
			end

			HealiumUnitFames_CheckPowerType(newUnit, self)

			Healium_UpdateUnitHealth(newUnit, self)
			Healium_UpdateUnitMana(newUnit, self)
			Healium_UpdateUnitBuffs(newUnit, self)
			Healium_UpdateUnitThreat(newUnit, self)
			Healium_UpdateUnitRole(newUnit, self)
			Healium_UpdateSpecialBuffs(newUnit)
			Healium_UpdateRaidTargetIcon(self)
		end

		if oldUnit then
			if Healium_Units[oldUnit] then
				for i,v in ipairs(Healium_Units[oldUnit]) do
					if v == self then
						table.remove(Healium_Units[oldUnit], i)
						break
					end
				end
			end
		end

		self.TargetUnit = newUnit
	end
end

function HealiumUnitFrames_Button_OnMouseDown(self, button)
	if button == "RightButton" and not Healium.LockFrames then
		local parent = self:GetParent()

		if not self.isCustom then
			parent = parent:GetParent()
		end

		parent.childismoving = true
		parent:StartMoving()
	end
end

function HealiumUnitFrames_Button_OnMouseUp(self, button)
	if button == "RightButton" then
		local parent = self:GetParent()

		if not self.isCustom then
			parent = parent:GetParent()
		end

		parent:StopMovingOrSizing()
		parent.childismoving = nil
	end
end

local function IsAnyUnitFrameVisible()
	local visible

	for _,j in pairs(UnitFrames) do
		if j:IsShown() then
			return true
		end
	end

	return nil
end

function Healium_ToggleAllFrames()
	if InCombatLockdown() then
		Healium_Warn("Can't toggle frames while in combat.")
		return
	end

	local hide = false

	if PartyFrame:IsShown() then hide = true end
	if PetsFrame:IsShown() then hide = true end
	if MeFrame:IsShown() then hide = true end
	if FriendsFrame:IsShown() then hide = true end
	if TanksFrame:IsShown() then hide = true end
	if TargetFrame:IsShown() then hide = true end
	if FocusFrame:IsShown() then hide = true end

	for i,j in ipairs(GroupFrames) do
		if j:IsShown() then
			hide = true
			break
		end
	end

	if hide then
		PartyFrameWasShown = PartyFrame:IsShown()
		PetsFrameWasShown = PetsFrame:IsShown()
		MeFrameWasShown = MeFrame:IsShown()
		FriendsFrameWasShown = FriendsFrame:IsShown()
		TanksFrameWasShown = TanksFrame:IsShown()
		TargetFrameWasShown = TargetFrame:IsShown()
		FocusFrameWasShown = FocusFrame:IsShown()

		PartyFrame:Hide()
		PetsFrame:Hide()
		MeFrame:Hide()
		FriendsFrame:Hide()
		TanksFrame:Hide()
		TargetFrame:Hide()
		FocusFrame:Hide()

		for i,j in ipairs(GroupFrames) do
			GroupFramesWasShown[i] = j:IsShown()
			j:Hide()
		end

		return
	end

	-- after this point, we know we are showing frames

	if PartyFrameWasShown then PartyFrame:Show() end
	if PetsFrameWasShown then PetsFrame:Show() end
	if MeFrameWasShown then MeFrame:Show() end
	if FriendsFrameWasShown then FriendsFrame:Show() end
	if TanksFrameWasShown then TanksFrame:Show() end
	if TargetFrameWasShown then TargetFrame:Show() end
	if FocusFrameWasShown then FocusFrame:Show() end

	for i,j in ipairs(GroupFramesWasShown) do
		if j then
			GroupFrames[i]:Show()
		end
	end

	if IsAnyUnitFrameVisible() == nil then
		PartyFrame:Show()
		PetsFrame:Show()
	end
end

function Healium_ShowHidePartyFrame(show)
	if InCombatLockdown() then return end
	if (show ~= nil) then Healium.ShowPartyFrame = show end

	if Healium.ShowPartyFrame then
		PartyFrame:Show()
	else
		PartyFrame:Hide()
	end
end

function Healium_ShowHidePetsFrame(show)
	if InCombatLockdown() then return end
	if (show ~= nil) then Healium.ShowPetsFrame = show end

	if Healium.ShowPetsFrame then
		PetsFrame:Show()
	else
		PetsFrame:Hide()
	end
end

function Healium_ShowHideMeFrame(show)
	if InCombatLockdown() then return end
	if (show ~= nil) then Healium.ShowMeFrame = show end

	if Healium.ShowMeFrame then
		MeFrame:Show()
	else
		MeFrame:Hide()
	end
end

function Healium_ShowHideFriendsFrame(show)
	if InCombatLockdown() then return end
	if (show ~= nil) then Healium.ShowFriendsFrame = show end

	if Healium.ShowFriendsFrame then
		FriendsFrame:Show()
	else
		FriendsFrame:Hide()
	end
end

function Healium_ShowHideTanksFrame(show)
	if InCombatLockdown() then return end
	if (show ~= nil) then Healium.ShowTanksFrame = show end

	if Healium.ShowTanksFrame then
		TanksFrame:Show()
	else
		TanksFrame:Hide()
	end
end

function Healium_ShowHideTargetFrame(show)
	if InCombatLockdown() then return end
	if (show ~= nil) then Healium.ShowTargetFrame = show end

	if Healium.ShowTargetFrame then
		TargetFrame:Show()
	else
		TargetFrame:Hide()
	end

	Healium_UpdateShowTargetFrame()
end

function Healium_ShowHideFocusFrame(show)
	if InCombatLockdown() then return end
	if (show ~= nil) then Healium.ShowFocusFrame = show end

	if Healium.ShowFocusFrame then
		FocusFrame:Show()
	else
		FocusFrame:Hide()
	end

	Healium_UpdateShowFocusFrame()
end

function Healium_ShowHideGroupFrame(group, show)
	if InCombatLockdown() then return end
	if (show ~= nil) then Healium.ShowGroupFrames[group] = show end

	if Healium.ShowGroupFrames[group] then
		GroupFrames[group]:Show()
	else
		GroupFrames[group]:Hide()
	end
end

function Healium_HideAllRaidFrames()
	if InCombatLockdown() then return end
	TanksFrame:Hide()
	for i,j in ipairs(GroupFrames) do
		j:Hide()
	end
end

function Healium_ShowAllRaidFramesWithMembers()
end

function Healium_Show10ManRaidFrames()
	if InCombatLockdown() then return end
	GroupFrames[1]:Show()
	GroupFrames[2]:Show()
end

function Healium_Show25ManRaidFrames()
	if InCombatLockdown() then return end
	for i=1, 5, 1 do
		GroupFrames[i]:Show()
	end
end

function Healium_Show40ManRaidFrames()
	if InCombatLockdown() then return end
	for i=1, 8, 1 do
		GroupFrames[i]:Show()
	end
end

function Healium_CreateUnitFrames()
	PartyFrame = CreatePartyUnitFrame("HealiumPartyFrame", "Party")

	if Healium.ShowPartyFrame then
		PartyFrame:Show()
	end

	PetsFrame = CreatePetUnitFrame("HealiumPetFrame", "Pets")
	if Healium.ShowPetsFrame then
		PetsFrame:Show()
	end

	MeFrame = CreateMeUnitFrame("HealiumMeFrame", "Me")
	if Healium.ShowMeFrame then
		MeFrame:Show()
	end

	FriendsFrame = CreateFriendsUnitFrame("HealiumFriendsFrame", "Friends")
	if Healium.ShowFriendsFrame then
		FriendsFrame:Show()
	end

	TanksFrame = CreateTanksUnitFrame("HealiumTanksFrame", "Tanks")
	if Healium.ShowTanksFrame then
		TanksFrame:Show()
	end

	TargetFrame = CreateTargetUnitFrame("HealiumTargetFrame", "Target")
	if Healium.ShowTargetFrame then
		TargetFrame:Show()
	end

	FocusFrame = CreateFocusUnitFrame("HealiumFocusFrame", "Focus")
	if Healium.ShowFocusFrame then
		FocusFrame:Show()
	end

	for i=1, 8, 1 do
		GroupFrames[i] = CreateGroupUnitFrame("HealiumGroup" .. i .. "Frame", "Group " .. i, tostring(i))
		GroupFramesWasShown[i]  = false
	end

end


function Healium_SetScale()
	local Scale = Healium.Scale

	PartyFrame:SetScale(Scale)
	PetsFrame:SetScale(Scale)
	MeFrame:SetScale(Scale)
	FriendsFrame:SetScale(Scale)
	TanksFrame:SetScale(Scale)
	TargetFrame:SetScale(Scale)
	FocusFrame:SetScale(Scale)

	for i,j in ipairs(GroupFrames) do
		j:SetScale(Scale)
	end
end

function Healium_UpdateUnitBuffs(unit, frame)

	local buffIndex = 1
	local Profile = Healium_GetProfile()

	if Healium.ShowBuffs then
		for i=1, 100, 1 do
			local name, rank, icon, count, debuffType, duration, expirationTime, source, isStealable = UnitBuff(unit, i)
			if name  then
				if (duration > 0) and (source == "player") then

					local armed = false

					for j=1, Profile.ButtonCount, 1 do
						if Profile.SpellNames[j] == name then
							armed = true
							break
						end
					end

					if armed == true then
						local buffFrame = frame.buffs[buffIndex]

						buffFrame:SetID(i)
						buffFrame.icon:SetTexture(icon)

						if count > 1 then
							buffFrame.count:SetText(count)
							buffFrame.count:Show()
						else
							buffFrame.count:Hide()
						end

						if duration and duration > 0 then
							local startTime = expirationTime - duration
							buffFrame.cooldown:SetCooldown(startTime, duration)
							buffFrame.cooldown:Show()
						else
							buffFrame.cooldown:Hide()
						end

						buffFrame:Show()
						buffIndex = buffIndex + 1
						if buffIndex > MaxBuffs then
							break
						end

					end
				end
			else
				break
			end
		end
	end

	-- hide remainder frames
	for i = buffIndex, MaxBuffs, 1 do
		frame.buffs[i]:Hide()
	end

	-- Handle affliction notification
	if Healium.EnableDebufs then

		local foundDebuff = false
		local debuffTypes = { }

		for i = 1, 40, 1 do
			local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitDebuff(unit, i)

			if name == nil then
				break
			end

			if debuffType ~= nil then
				if Healium_CanCureDebuff(debuffType) then
					foundDebuff = true
					debuffTypes[debuffType] = true
					local debuffColor = DebuffTypeColor[debuffType] or DebuffTypeColor["none"];
					frame.hasDebuf = true
					frame.debuffColor = debuffColor

					if Healium.EnableDebufHealthbarHighlighting then
						frame.CurseBar:SetBackdropBorderColor(debuffColor.r, debuffColor.g, debuffColor.b)
						frame.CurseBar:SetAlpha(1)
					end

					if Healium.EnableDebufAudio then
						local now = GetTime()

						if UnitInRange(unit) then
							if now > (LastDebuffSoundTime + 7) then
								Healium_PlayDebuffSound()
								LastDebuffSoundTime = now
							end
						end
					end
				end
			end
		end

		if (not foundDebuff) and frame.hasDebuf then
			frame.CurseBar:SetAlpha(0)
			frame.hasDebuf = nil
		end

		if Healium.EnableDebufButtonHighlighting then
			Healium_ShowDebuffButtons(Profile, frame, debuffTypes)
		end

		Healium_UpdateUnitHealth(unit, frame)
	end
end

function Healium_UpdateEnableDebuffs()
	for _,j in pairs(UnitFrames) do
		if j.hasDebuf then
			frame.CurseBar:SetAlpha(0)
			frame.hasDebuf = nil

			for i=1, Healium_MaxButtons, 1 do
				local button = frame.button[i]
				if button then
					button.curseBar:SetAlpha(0)
					button.curseBar.hasDebuf = nil
				end
			end
		end
	end
end

function Healium_HealthStatusBar_OnLoad(self)
	-- This is done to ensure the status bar doesn't block
	-- the name text
	self:SetFrameLevel(self:GetFrameLevel() - 1)

end

function Healium_ManaStatusBar_OnLoad(self)
--    self:SetStatusBarColor(PowerBarColor["MANA"])
	self:SetRotatesTexture(true)
	self:SetOrientation("VERTICAL")
	self:SetFrameLevel(self:GetFrameLevel() - 1)
--	self:SetBackdropColor(1.0, 0.0, 0.0)
end

function Healium_UpdateEnableClique()
	for _,k in ipairs(Healium_Frames) do
		if Healium.EnableClique then
			ClickCastFrames[k] = true
		else
			ClickCastFrames[k] = nil
			k:SetAttribute("type1", "target")
		end
	end
end

function Healium_ResetAllFramePositions()
	for _,k in ipairs(UnitFrames) do
		k:SetUserPlaced(false)
		k:ClearAllPoints()
		k:SetPoint("Center", UIParent, 0,0)
	end
	Healium_Print("Reset frame positions complete.")
end

function Healium_UpdateFriends()
	local names = ""
	for k, v in pairs(HealiumGlobal.Friends) do
		if names:len() > 0 then
			names = names .. "," .. v
		else
			names = v
		end
	end
	Healium_DebugPrint("namesListFriends: " ..names)
	FriendsFrame.hdr:SetAttribute("nameList", names)
--	Healium_DebugPrint("Friends header is shown: " .. FriendsFrame.hdr:IsShown())
end

function Healium_UpdateTargetFrame()
	HealiumUnitFrames_Button_OnAttributeChanged(TargetFrame.hdr, "unit")
end

function Healium_UpdateFocusFrame()
	HealiumUnitFrames_Button_OnAttributeChanged(FocusFrame.hdr, "unit")
end
