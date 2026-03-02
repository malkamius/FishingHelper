local addonName, addonTable = ...
local FH = {}
addonTable[1] = FH
_G["FishingHelper"] = FH

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
    savedGear = {} -- Used to restore previous gear
}

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("BAG_UPDATE")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")

-- Slash command
SLASH_FISHINGHELPER1 = "/fh"
function SlashCmdList.FISHINGHELPER(msg, editbox)
    if FishingHelperFrame then
        if FishingHelperFrame:IsShown() then
            FishingHelperFrame:Hide()
        else
            FishingHelperFrame:Show()
        end
    end
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
        if FH.updateTimer > 1.0 then
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
    end
end

function FH:UpdateStopMacro()
    if InCombatLockdown() or not self.UI or not self.UI.stopButton then return end
    
    local lines = {}
    -- Restore offhand AFTER mainhand, so sort it (16 comes before 17)
    local sortedSlots = {}
    for slot, link in pairs(self.db.savedGear) do
        table.insert(sortedSlots, slot)
    end
    table.sort(sortedSlots)

    for _, slot in ipairs(sortedSlots) do
        local link = self.db.savedGear[slot]
        if link then
            local name = GetItemInfo(link)
            if name then
                table.insert(lines, "/equipslot " .. slot .. " " .. name)
            end
        end
    end
    
    -- When stopping fishing, run a macro to equip old gear, AND a secure snippet or lua to restore AutoLoot.
    -- We can just hook the "OnClick" of stopButton securely, no, insecurely to restore autoloot, since we aren't in combat.
    
    self.UI.stopButton:SetAttribute("type", "macro")
    if #lines > 0 then
        self.UI.stopButton:SetAttribute("macrotext", table.concat(lines, "\n"))
    else
        self.UI.stopButton:SetAttribute("macrotext", "")
    end
end

function FH:UpdateMacro()
    if InCombatLockdown() then return end
    if not self.UI or not self.UI.mainButton then return end

    local needEquip = false
    local itemsToEquip = {}
    local anyOutfitConfigured = false

    -- Check outfit
    for slot, itemID in pairs(self.db.outfit) do
        if itemID then
            anyOutfitConfigured = true
            local equippedID = GetInventoryItemID("player", slot)
            if equippedID ~= itemID then
                needEquip = true
                local name = GetItemInfo(itemID)
                if name then
                    table.insert(itemsToEquip, "/equipslot " .. slot .. " " .. name)
                end
            end
        end
    end

    if needEquip then
        local macroStr = table.concat(itemsToEquip, "\n")
        -- print("FH Debug: Equipping - " .. macroStr:gsub("\n", " ; "))
        self.UI.mainButton:SetAttribute("type1", "macro")
        self.UI.mainButton:SetAttribute("macrotext1", macroStr)
        
        if self.UI.mainButton.icon then
            self.UI.mainButton.icon:SetTexture("Interface\\Icons\\INV_Chest_Cloth_17")
        end
        return
    end

    -- We are equipped, so we enable auto loot.
    if anyOutfitConfigured then
        self:EnableAutoLoot()
    end

    -- Outfit is equipped. Check Lure.
    local needLure = false
    local lureID = self.db.lureID
    if lureID and anyOutfitConfigured then
        local name = GetItemInfo(lureID)
        if name and GetItemCount(lureID) > 0 then
            local hasMainHandEnchant, mainHandExpiration = GetWeaponEnchantInfo()
            if not hasMainHandEnchant or (mainHandExpiration and mainHandExpiration < 20000) then
                local macroStr = "/use " .. name .. "\n/use 16"
                -- print("FH Debug: Luring - " .. macroStr:gsub("\n", " ; "))
                needLure = true
                self.UI.mainButton:SetAttribute("type1", "macro")
                self.UI.mainButton:SetAttribute("macrotext1", macroStr)
                
                if self.UI.mainButton.icon then
                    self.UI.mainButton.icon:SetTexture(GetItemIcon(lureID))
                end
                return
            end
        end
    end

    -- Ready to fish
    -- print("FH Debug: Fishing!")
    self.UI.mainButton:SetAttribute("type1", "macro")
    self.UI.mainButton:SetAttribute("macrotext1", "/cast Fishing")
    if self.UI.mainButton.icon then
        local _, _, icon = GetSpellInfo("Fishing")
        if not icon then icon = "Interface\\Icons\\Trade_Fishing" end
        self.UI.mainButton.icon:SetTexture(icon)
    end
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
    elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_EQUIPMENT_CHANGED" then
        if FH.UpdateMacro then
            FH:UpdateMacro()
            FH:UpdateStopMacro()
        end
    elseif event == "BAG_UPDATE" then
        if FH.UI and FH.UI.UpdateLureCount then
            FH.UI:UpdateLureCount()
        end
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        local unit, target, castID, spellID = ...
        if unit == "player" then
            local name = GetSpellInfo(spellID)
            if name == "Fishing" then
                FH:EnhanceVolume()
            end
        end
    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        local unit, target, castID, spellID = ...
        if unit == "player" then
            local name = GetSpellInfo(spellID)
            if name == "Fishing" then
                -- Add a slight delay to restore volume in case they catch back to back
                C_Timer.After(1, function()
                    FH:RestoreVolume()
                end)
            end
        end
    end
end)
