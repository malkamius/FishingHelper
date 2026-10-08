local addonName, addonTable = ...
local FH = {}
addonTable[1] = FH
_G["FishingHelper"] = FH

_G["BINDING_HEADER_FISHINGHELPER"] = "Fishing Helper"
_G["BINDING_NAME_CLICK FishingHelperMainButton:LeftButton"] = "Cast Fishing"
_G["BINDING_NAME_CLICK FishingHelperStopButton:LeftButton"] = "Stop Fishing"

-- Default database
local defaultDB = {
    framePosition = { point = "CENTER", relativePoint = "CENTER", xOfs = 0, yOfs = 0 },
    outfit = {
        [1] = nil,  -- Head (INVSLOT_HEAD)
        [10] = nil, -- Hands (INVSLOT_HANDS)
        [8] = nil,  -- Feet (INVSLOT_FEET)
        [16] = nil, -- Main Hand (INVSLOT_MAINHAND)
    },
    lureID = nil,
    savedGear = {}, -- Used to restore previous gear
    minimapPos = 45 -- Minimap button angle in degrees
}

-- Known Fishing Spell IDs across WoW versions (Classic, TBC, Retail, WoW Forever)
local FISHING_SPELL_IDS = {
    [7620] = true,
    [7731] = true,
    [7732] = true,
    [18248] = true,
    [33095] = true,
    [131474] = true,
    [131476] = true,
}

local function GetSpellDetails(spellIDOrName)
    if not spellIDOrName then return nil, nil end
    local name, icon

    if type(spellIDOrName) == "number" then
        if C_Spell and C_Spell.GetSpellInfo then
            local info = C_Spell.GetSpellInfo(spellIDOrName)
            if info then
                name = info.name
                icon = info.iconID or info.originalIconID
            end
        end
        if not name and _G.GetSpellInfo then
            local n, _, i = _G.GetSpellInfo(spellIDOrName)
            name = n
            icon = i
        end
    elseif type(spellIDOrName) == "string" then
        if _G.GetSpellInfo then
            local n, _, i = _G.GetSpellInfo(spellIDOrName)
            name = n or spellIDOrName
            icon = i
        else
            -- Modern client (WoW Forever / 11.0+) where GetSpellInfo requires numeric ID
            if spellIDOrName == "Fishing" then
                return GetSpellDetails(7620)
            end
            name = spellIDOrName
        end
    end

    return name, icon
end

-- Global shim for GetSpellInfo if nil on modern clients
if _G.GetSpellInfo == nil then
    _G.GetSpellInfo = function(spell)
        local name, icon = GetSpellDetails(spell)
        if name then
            return name, nil, icon
        end
        return nil
    end
end

local function IsFishingSpellCast(unit, ...)
    if unit ~= "player" then return false end
    for i = 1, select("#", ...) do
        local val = select(i, ...)
        if type(val) == "number" and FISHING_SPELL_IDS[val] then
            return true
        end
        if type(val) == "number" then
            local name = GetSpellDetails(val)
            if name and (name == "Fishing" or name:lower():find("fishing")) then
                return true
            end
        elseif type(val) == "string" and (val == "Fishing" or val:lower():find("fishing")) then
            return true
        end
    end
    return false
end

local function IsLureSpellCast(unit, ...)
    if unit ~= "player" or not FH.db or not FH.db.lureID then return false end
    local lureID = FH.db.lureID
    local lureName = C_Item and C_Item.GetItemInfo and C_Item.GetItemInfo(lureID)
    if not lureName and C_Item and C_Item.GetItemNameByID then
        lureName = C_Item.GetItemNameByID(lureID)
    end
    if not lureName then return false end

    for i = 1, select("#", ...) do
        local val = select(i, ...)
        if type(val) == "number" then
            local name = GetSpellDetails(val)
            if name and name == lureName then
                return true
            end
        elseif type(val) == "string" and val == lureName then
            return true
        end
    end
    return false
end

local function GetItemNameOrID(itemIDOrLink)
    if not itemIDOrLink then return nil end
    local name = C_Item and C_Item.GetItemInfo and C_Item.GetItemInfo(itemIDOrLink)
    if not name and C_Item and C_Item.GetItemNameByID and type(itemIDOrLink) == "number" then
        name = C_Item.GetItemNameByID(itemIDOrLink)
    end
    if not name and _G.GetItemInfo then
        name = _G.GetItemInfo(itemIDOrLink)
    end
    if not name and type(itemIDOrLink) == "number" then
        if C_Item and C_Item.RequestLoadItemDataByID then
            C_Item.RequestLoadItemDataByID(itemIDOrLink)
        end
        return "item:" .. itemIDOrLink
    end
    return name or itemIDOrLink
end

local function GetItemIconSafe(itemID)
    if not itemID then return nil end
    local icon
    if C_Item and C_Item.GetItemIconByID then
        icon = C_Item.GetItemIconByID(itemID)
    end
    if not icon and C_Item and C_Item.GetItemInfoInstant then
        local _, _, _, _, instantIcon = C_Item.GetItemInfoInstant(itemID)
        icon = instantIcon
    end
    if not icon and _G.GetItemIcon then
        icon = _G.GetItemIcon(itemID)
    end
    return icon
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("BAG_UPDATE")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UNIT_SPELLCAST_STOP")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("UNIT_SPELLCAST_FAILED")
frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")

-- Slash command
SLASH_FISHINGHELPER1 = "/fh"
SLASH_FISHINGHELPER2 = "/fishinghelper"
function SlashCmdList.FISHINGHELPER(msg, editbox)
    msg = (msg or ""):match("^%s*(.-)%s*$"):lower()
    if msg == "minimap" or msg == "reset" then
        if FH.db then FH.db.minimapPos = 45 end
        if FH.UI and FH.UI.CreateMinimapButton then
            FH.UI:CreateMinimapButton()
        end
        if FH.UI and FH.UI.UpdateMinimapButton then
            FH.UI:UpdateMinimapButton()
        end
        print("|cFF00FF00FishingHelper|r: Minimap button position reset to default (45°).")
    elseif msg == "bind" or msg == "keybind" or msg == "settings" then
        if FH.UI and FH.UI.CreateSettingsFrame then
            if not FH.UI.settingsFrame then FH.UI:CreateSettingsFrame() end
            if FH.UI.settingsFrame:IsShown() then
                FH.UI.settingsFrame:Hide()
            else
                FH.UI.settingsFrame:Show()
            end
        end
    else
        if FH.UI and FH.UI.frame then
            if FH.UI.frame:IsShown() then
                FH.UI.frame:Hide()
            else
                FH.UI.frame:Show()
            end
        end
    end
end

-- Addon Compartment Callbacks for WoW Forever
function FishingHelper_OnAddonCompartmentClick(addonName, buttonName)
    if buttonName == "RightButton" then
        if not FH.UI.CreateSettingsFrame then return end
        if not FH.UI.settingsFrame then
            FH.UI:CreateSettingsFrame()
        end
        if FH.UI.settingsFrame:IsShown() then
            FH.UI.settingsFrame:Hide()
        else
            if FH.UI.settingsFrame.castRow then
                FH.UI.settingsFrame.castRow:UpdateText()
            end
            if FH.UI.settingsFrame.stopRow then
                FH.UI.settingsFrame.stopRow:UpdateText()
            end
            FH.UI.settingsFrame:Show()
        end
    else
        if FH.UI and FH.UI.frame then
            if FH.UI.frame:IsShown() then
                FH.UI.frame:Hide()
            else
                FH.UI.frame:Show()
            end
        end
    end
end

function FishingHelper_OnAddonCompartmentEnter(addonName, button)
    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip:AddLine("Fishing Helper")
    GameTooltip:AddLine("Left-Click to toggle UI.", 1, 1, 1)
    GameTooltip:AddLine("Right-Click for Keybindings.", 1, 1, 1)
    GameTooltip:Show()
end

function FishingHelper_OnAddonCompartmentLeave(addonName, button)
    GameTooltip:Hide()
end

function FH:Initialize()
    if not FishingHelperDB then
        FishingHelperDB = CopyTable(defaultDB)
    end
    -- Ensure all keys exist
    for k, v in pairs(defaultDB) do
        if FishingHelperDB[k] == nil then
            FishingHelperDB[k] = type(v) == "table" and CopyTable(v) or v
        end
    end
    self.db = FishingHelperDB

    self.updateTimer = 0
    frame:SetScript("OnUpdate", function(self, elapsed)
        FH.updateTimer = FH.updateTimer + elapsed
        if FH.updateTimer > 0.2 then
            FH.updateTimer = 0
            if FH.UpdateMacro then
                FH:UpdateMacro()
            end
        end
    end)

    self.volumeSaved = false
    self.autoLootSaved = false

    print("|cFF00FF00Fishing Helper|r loaded! Type /fh to toggle the frame.")
end

function FH:EnhanceVolume()
    if self.volumeSaved then return end
    self.oldMasterVolume = GetCVar("Sound_MasterVolume")
    self.oldSFXVolume = GetCVar("Sound_SFXVolume")

    SetCVar("Sound_MasterVolume", "1.0")
    SetCVar("Sound_SFXVolume", "1.0")
    self.volumeSaved = true
end

function FH:RestoreVolume()
    if not self.volumeSaved then return end
    SetCVar("Sound_MasterVolume", self.oldMasterVolume or "1.0")
    SetCVar("Sound_SFXVolume", self.oldSFXVolume or "1.0")
    self.volumeSaved = false
end

function FH:EnableAutoLoot()
    if self.autoLootSaved then return end
    self.oldAutoLoot = GetCVar("autoLootDefault")
    if self.oldAutoLoot ~= "1" then
        SetCVar("autoLootDefault", "1")
        self.autoLootSaved = true
    end
end

function FH:RestoreAutoLoot()
    if not self.autoLootSaved then return end
    SetCVar("autoLootDefault", self.oldAutoLoot or "0")
    self.autoLootSaved = false
end

function FH:SaveCurrentGear()
    if InCombatLockdown() then return end
    local needEquip = false
    for slot, itemID in pairs(self.db.outfit) do
        if itemID and GetInventoryItemID("player", slot) ~= itemID then
            needEquip = true
            break
        end
    end

    if needEquip then
        wipe(self.db.savedGear)
        for slot, itemID in pairs(self.db.outfit) do
            if itemID then
                local link = GetInventoryItemLink("player", slot)
                self.db.savedGear[slot] = link
            end
        end
        if self.db.outfit[16] and not self.db.outfit[17] then
            self.db.savedGear[17] = GetInventoryItemLink("player", 17)
        end
        self:UpdateStopMacro()
        self:UpdateMacro()
    end
end

function FH:UpdateStopMacro()
    if InCombatLockdown() or not self.UI or not self.UI.stopButton then return end

    local lines = {}
    local sortedSlots = {}
    for slot, link in pairs(self.db.savedGear) do
        table.insert(sortedSlots, slot)
    end
    table.sort(sortedSlots)

    for _, slot in ipairs(sortedSlots) do
        local link = self.db.savedGear[slot]
        if link then
            local name = GetItemNameOrID(link)
            if name then
                table.insert(lines, "/equipslot " .. slot .. " " .. name)
            end
        end
    end

    self.UI.stopButton:SetAttribute("type", "macro")
    self.UI.stopButton:SetAttribute("type*", "macro")
    if #lines > 0 then
        local macrotext = table.concat(lines, "\n")
        self.UI.stopButton:SetAttribute("macrotext", macrotext)
        self.UI.stopButton:SetAttribute("macrotext*", macrotext)
    else
        self.UI.stopButton:SetAttribute("macrotext", "")
        self.UI.stopButton:SetAttribute("macrotext*", "")
    end
end

function FH:UpdateMacro()
    if InCombatLockdown() then return end
    if not self.UI or not self.UI.mainButton then return end

    local needEquip = false
    local itemsToEquip = {}
    local anyOutfitConfigured = false
    local tooltipItem = nil

    -- Check outfit
    for slot, itemID in pairs(self.db.outfit) do
        if itemID then
            anyOutfitConfigured = true
            local equippedID = GetInventoryItemID("player", slot)
            if equippedID ~= itemID then
                needEquip = true
                local name = GetItemNameOrID(itemID)
                if name then
                    table.insert(itemsToEquip, "/equipslot " .. slot .. " " .. name)
                    if not tooltipItem then tooltipItem = name end
                end
            end
        end
    end

    local function ApplyMacro(macroStr, icon, tooltip)
        self.UI.mainButton:SetAttribute("type", "macro")
        self.UI.mainButton:SetAttribute("type*", "macro")
        self.UI.mainButton:SetAttribute("macrotext", macroStr)
        self.UI.mainButton:SetAttribute("macrotext*", macroStr)
        if self.UI.mainButton.icon then
            self.UI.mainButton.icon:SetTexture(icon)
        elseif self.UI.mainButton.SetItemButtonTexture then
            self.UI.mainButton:SetItemButtonTexture(icon)
        end

        local idx = GetMacroIndexByName("FishHelper")
        if idx > 0 then
            local mText = macroStr
            if tooltip then
                mText = "#showtooltip " .. tooltip .. "\n" .. macroStr
            else
                mText = "#showtooltip\n" .. macroStr
            end
            local name, icon, body = GetMacroInfo(idx)
            if body ~= mText then
                EditMacro(idx, "FishHelper", "INV_Misc_QuestionMark", mText)
            end
        end
        self.currentMacroText = macroStr
        self.currentMacroTooltip = tooltip
    end

    if needEquip then
        -- Add the script call to save gear right before we equip
        table.insert(itemsToEquip, 1, "/run FishingHelper:SaveCurrentGear()")
        local macroStr = table.concat(itemsToEquip, "\n")
        ApplyMacro(macroStr, "Interface\\Icons\\INV_Chest_Cloth_17", tooltipItem)
        return
    end

    -- We are equipped, so we enable auto loot.
    if anyOutfitConfigured then
        self:EnableAutoLoot()
    end

    -- Outfit is equipped. Check Lure.
    local lureID = self.db.lureID
    local recentlySucceeded = self.lastLureSuccess and (GetTime() - self.lastLureSuccess < 2.0)
    if lureID and anyOutfitConfigured and not self.isApplyingLure and not recentlySucceeded then
        local name = GetItemNameOrID(lureID)
        local itemCount = C_Item and C_Item.GetItemCount and C_Item.GetItemCount(lureID) or (GetItemCount and GetItemCount(lureID)) or 0
        if name and itemCount > 0 then
            local hasMainHandEnchant, mainHandExpiration
            if C_PaperDollInfo and C_PaperDollInfo.GetTemporaryEnchantmentInfo then
                local mh = C_PaperDollInfo.GetTemporaryEnchantmentInfo(INVSLOT_MAINHAND or 16)
                if mh then
                    hasMainHandEnchant = true
                    mainHandExpiration = mh.remainingTimeMs
                end
            elseif GetWeaponEnchantInfo then
                hasMainHandEnchant, mainHandExpiration = GetWeaponEnchantInfo()
            end

            if not hasMainHandEnchant or (mainHandExpiration and mainHandExpiration < 20000) then
                local macroStr = "/use " .. name .. "\n/use 16"
                local lureIcon = GetItemIconSafe(lureID) or "Interface\\Icons\\INV_Misc_QuestionMark"
                ApplyMacro(macroStr, lureIcon, name)
                return
            end
        end
    end

    -- Ready to fish
    local fishSpellName, icon = GetSpellDetails(7620)
    fishSpellName = fishSpellName or "Fishing"
    if not icon then icon = "Interface\\Icons\\Trade_Fishing" end
    ApplyMacro("/cast " .. fishSpellName, icon, fishSpellName)
end

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            FH:Initialize()
            if FH.UI and FH.UI.Initialize then
                FH.UI:Initialize()
            end
            self:UnregisterEvent("ADDON_LOADED")
            FH:UpdateMacro()
            FH:UpdateStopMacro()

            -- Hook Stop Button Click for AutoLoot Restore
            if FH.UI and FH.UI.stopButton then
                FH.UI.stopButton:HookScript("OnClick", function()
                    FH:RestoreAutoLoot()
                end)
            end
        end
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        if FH.UI and FH.UI.CreateMinimapButton then
            FH.UI:CreateMinimapButton()
        end
        if FH.UI and FH.UI.UpdateMinimapButton then
            FH.UI:UpdateMinimapButton()
        end
        if event == "PLAYER_LOGIN" then
            self:UnregisterEvent("PLAYER_LOGIN")
        end
    elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_EQUIPMENT_CHANGED" then
        if event == "PLAYER_EQUIPMENT_CHANGED" then
            local slotID = ...
            if slotID and FH.db.savedGear[slotID] then
                local currentItemID = GetInventoryItemID("player", slotID)
                local fishingItemID = FH.db.outfit[slotID]

                -- Check if the current item matches our configured fishing outfit
                if fishingItemID then
                    if currentItemID ~= fishingItemID then
                        -- User manually equipped something else in an outfit slot
                        FH.db.savedGear[slotID] = nil
                    end
                else
                    -- No fishing item configured for this slot, but we have something saved (e.g. slot 17)
                    if currentItemID and currentItemID ~= 0 then
                        FH.db.savedGear[slotID] = nil
                    end
                end
            end

            if slotID == 16 then
                local currentItemID = GetInventoryItemID("player", 16)
                if currentItemID ~= FH.db.outfit[16] then
                    FH:RestoreAutoLoot()
                end
            end
        end

        if FH.UpdateMacro then
            FH:UpdateMacro()
            FH:UpdateStopMacro()
        end
    elseif event == "BAG_UPDATE" or event == "BAG_UPDATE_DELAYED" then
        if FH.UI and FH.UI.UpdateLureCount then
            FH.UI:UpdateLureCount()
        end
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        local unitTarget = ...
        if unitTarget == "player" and IsFishingSpellCast(unitTarget, select(2, ...)) then
            FH.isChannelingFishing = true
            FH:EnhanceVolume()
        end
    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        local unitTarget = ...
        if unitTarget == "player" and (FH.isChannelingFishing or IsFishingSpellCast(unitTarget, select(2, ...))) then
            FH.isChannelingFishing = false
            C_Timer.After(1, function()
                if not FH.isChannelingFishing then
                    FH:RestoreVolume()
                end
            end)
        end
    elseif event == "UNIT_SPELLCAST_START" then
        local unitTarget = ...
        if unitTarget == "player" and IsLureSpellCast(unitTarget, select(2, ...)) then
            FH.isApplyingLure = true
            FH.lastLureSuccess = nil
            FH:UpdateMacro()
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unitTarget = ...
        if unitTarget == "player" and IsLureSpellCast(unitTarget, select(2, ...)) then
            FH.lastLureSuccess = GetTime()
        end
    elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        local unitTarget = ...
        if unitTarget == "player" and IsLureSpellCast(unitTarget, select(2, ...)) then
            FH.lastLureSuccess = nil
        end
    elseif event == "UNIT_SPELLCAST_STOP" then
        local unitTarget = ...
        if unitTarget == "player" then
            FH.isApplyingLure = false
            FH:UpdateMacro()
        end
    end
end)
