function Healium_HealButton_OnLoad(self)
	self.TimeSinceLastUpdate = 0
	self:RegisterEvent("SPELL_UPDATE_USABLE")
	self:RegisterForDrag("LeftButton")
	self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
end

function Healium_HealButton_OnUpdate(self, elapsed)
	if ( not Healium.DoRangeChecks ) then return 0 end
	self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed

	if (self.TimeSinceLastUpdate > Healium.RangeCheckPeriod) then
		Healium_RangeCheckButton(self)
		self.TimeSinceLastUpdate = 0
	end
end

function Healium_HealButton_OnEnter(frame, motion)
		if (not Healium.ShowToolTips) then return end
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT", -30, 5)
	local stype = frame:GetAttribute("type")

    if frame.id and (stype == "spell") then
		GameTooltip_SetDefaultAnchor(GameTooltip, frame)
		GameTooltip:SetSpell(frame.id, SpellBookFrame.bookType)
		local unit = frame:GetParent().TargetUnit
		if not UnitExists(unit) then return end
		local Name = UnitName(unit)
		if (not Name) then Name = "-" end
        GameTooltip:AddLine("Target: |cFF00FF00"..Name,1,1,1)
	elseif frame.id and (stype == "item") then
		GameTooltip_SetDefaultAnchor(GameTooltip, frame)
		GameTooltip:SetHyperlink("item:"..frame.id)
		local unit = frame:GetParent().TargetUnit
		if not UnitExists(unit) then return end
		local Name = UnitName(unit)
		if (not Name) then Name = "-" end
        GameTooltip:AddLine("Target: |cFF00FF00"..Name,1,1,1)
	elseif (stype == "macro") then
		local spellID
		local index = GetMacroIndexByName(frame:GetAttribute("macro"));
		if (index) then
			spellname = GetMacroSpell(index);
			spellID = GetSpellID(spellname)
		end
		GameTooltip_SetDefaultAnchor(GameTooltip, frame)
		GameTooltip:SetSpell(spellID, SpellBookFrame.bookType)
		GameTooltip:AddLine("|cFFFFFFFFMacro: |cFF00FF00" .. frame:GetAttribute("macro"))
		local unit = frame:GetParent().TargetUnit
		if not UnitExists(unit) then return end
		local Name = UnitName(unit)
		if (not Name) then Name = "-" end
        GameTooltip:AddLine("Target: |cFF00FF00"..Name,1,1,1)
	else
		-- Safely Handle Empty Buttons
		GameTooltip:SetText("|cFFFFFFFFNo Spell|n|cFF00FF00You may drag-and-drop a spell from your|nspellbook onto this button, or you may go|nto Interface, Addons, " ..Healium_AddonName .. " and|nselect your spells from the list.")
    end

		GameTooltip:Show()
    end

function Healium_HealButton_OnLeave()
	GameTooltip:Hide()
end

function Healium_HealButton_OnEvent(self, event)
	if (not self.id) then return 0 end

	if event == "SPELL_UPDATE_USABLE" then
		Healium_RangeCheckButton(self)
	end
end

local function PickupOldSpell(old)
	-- if shift is held down put old spell on cursor
	if IsShiftKeyDown() and (old.name ~= nil) then

		if old.type == Healium_Type_Spell then
			PickupSpell(old.name)
			return
		end

		if old.type == Healium_Type_Macro then
			PickupMacro(old.name)
			return
		end

		if old.type == Healium_Type_Item then
			PickupItem(old.ID)
			return
		end
	end
end

local function FinishDrag(self,old)
	Healium_UpdateButtonAttributes()
	Healium_UpdateButtonIcons()
	Healium_UpdateButtonCooldownsByColumn(self.index)

	ClearCursor()
	Healium_Update_ConfigPanel()

	PickupOldSpell(old)
end

local function GetOldSpell(Index, Profile)
	local old = {}

	old.name = Profile.SpellNames[Index]
	old.icon = Profile.SpellIcons[Index]
	old.type = Profile.SpellTypes[Index]
	old.ID = Profile.IDs[Index]

	return old
end

local function Drag(self)
			if InCombatLockdown() then
				Healium_Warn("Can't update button while in combat")
				return
			end

	if (self.index < 0) or (self.index > Healium_MaxButtons) then
		return
	end

	local Profile = Healium_GetProfile()
	local infoType, info1, info2 = GetCursorInfo()
	local old = GetOldSpell(self.index, Profile)

	-- Handle spell drag
	if infoType == "spell" then
		-- info1 holds spellid
		local spellName = GetSpellName(info1, BOOKTYPE_SPELL )
		if IsPassiveSpell(info1, BOOKTYPE_SPELL) then
			local link = GetSpellLink(info1, BOOKTYPE_SPELL)
			Healium_Warn(link .. " is a passive spell and cannot be used in " .. Healium_AddonName)
			return
		end

		local name, rank, icon = GetSpellInfo(spellName)
		Healium_SetProfileSpell(Profile, self.index, name, info1, icon)
		FinishDrag(self, old)
		return
	end

	-- Handle macro drag
	if infoType == "macro" then
		-- info1 holds macro index
		local name, icon, body, isLocal = GetMacroInfo(info1);
		Healium_SetProfileMacro(Profile, self.index, name, info1, icon)
		FinishDrag(self, old)
		return
	end

	-- Handle item drag
	if infoType == "item" then
		-- info1 = itemId: Number - The itemId.
		-- info2 = itemLink : String (ItemLink) - The item's link.
		local name, sLink, iRarity, iLevel, iMinLevel, sType, sSubType, iStackCount, iEquipLoc, icon, iSellPrice =  GetItemInfo(info1);
		Healium_SetProfileItem(Profile, self.index, name, info1, icon)
		FinishDrag(self, old)
		return
	end

end

-- drag stop
function Healium_HealButton_OnReceiveDrag(self)
	Healium_DebugPrint("Healium_HealButton_OnReceiveDrag() called")
	Drag(self, nil)
end

-- drag start
function Healium_HealButton_OnDragStart(self)
	Healium_DebugPrint("Healium_HealButton_OnDragStart() called")
	-- starting drag requires shift to be pressed
	if IsShiftKeyDown() == nil then return end

	local Profile = Healium_GetProfile()
	local old = GetOldSpell(self.index, Profile)

	PickupOldSpell(old)
end

function Healium_HealButton_PreClick(self)
--[[
	Healium_DebugPrint("Healium_HealButton_PreClick() called")

	local typ, id = GetCursorInfo()

	if (typ == "spell") or (typ == "item") or (typ == "macro") then
		self.DragType = typ
		self.DragID = id
	else
		self.DragType = nil
		self.DragID = nil
	end
]]
end

function Healium_HealButton_PostClick(self)
--[[
	Healium_DebugPrint("Healium_HealButton_PostClick() called")

	if self.dragspellid then
		PickupSpell(self.dragspellid, BOOKTYPE_SPELL)
		Drag(self)
	elseif self.DragType == "macro" then
		PickupMacro(self.DragID)
		Drag(self)
	elseif self.DragType == "item" then
		PickupItem(self.DragID)
		Drag(self)
	end

	self.DragType = nil
	self.DragID = nil
]]
end
