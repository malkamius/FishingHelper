local addonName, addonTable = ...
local FH = addonTable[1]
FH.UI = FH.UI or {}

local function CreateItemSlot(parent, name, size, labelText, dbKey, slotID)
    local btn = CreateFrame("Button", name, parent, "ItemButtonTemplate")
    btn:SetSize(size, size)

    -- Label
    btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.label:SetPoint("BOTTOM", btn, "TOP", 0, 2)
    btn.label:SetText(labelText)

    -- Function to update icon
    btn.UpdateIcon = function(self)
        local currentID
        if slotID then
            currentID = FH.db.outfit[slotID]
        else
            currentID = FH.db[dbKey]
        end

        if currentID then
            local icon = C_Item.GetItemIconByID(currentID)
            SetItemButtonTexture(self, icon)
        else
            SetItemButtonTexture(self, nil)
        end
    end

    -- Handle Clicks / Drops
    btn:SetScript("OnReceiveDrag", function(self)
        local infoType, itemID, itemLink = GetCursorInfo()
        if infoType == "item" then
            if slotID then
                FH.db.outfit[slotID] = itemID
            else
                FH.db[dbKey] = itemID
            end
            ClearCursor()
            self:UpdateIcon()
            if FH.UpdateMacro then FH:UpdateMacro() end
            if FH.UI and FH.UI.UpdateLureCount then FH.UI:UpdateLureCount() end
        end
    end)
    btn:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            if slotID then
                FH.db.outfit[slotID] = nil
            else
                FH.db[dbKey] = nil
            end
            self:UpdateIcon()
            if FH.UpdateMacro then FH:UpdateMacro() end
            if FH.UI and FH.UI.UpdateLureCount then FH.UI:UpdateLureCount() end
        else
            -- If cursor has item, act like receive drag
            local infoType = GetCursorInfo()
            if infoType == "item" then
                self:GetScript("OnReceiveDrag")(self)
            else
                -- Clicked without item, show popup
                if FH.UI and FH.UI.ShowItemPopup then
                    local filter
                    if slotID == 16 then
                        filter = function(itemID)
                            local validPoles = {
                                [19970] = true, -- Arcanite Fishing Pole
                                [25978] = true, -- Seth's Graphite Fishing Pole
                                [6367]  = true, -- Big Iron Fishing Pole
                                [19022] = true, -- Nat Pagle's Extreme Angler FC-5000
                                [4598]  = true, -- Goblin fishing pole
                                [6365]  = true, -- Strong Fishing Pole
                                [6366]  = true, -- Darkwood Fishing Pole
                                [6256]  = true, -- Fishing Pole
                                [12225] = true, -- Blump Family Fishing Pole
                            }
                            return validPoles[itemID] or false
                        end
                    elseif slotID == 1 then
                        filter = function(itemID)
                            local _, _, _, _, _, _, _, _, itemEquipLoc = C_Item.GetItemInfo(itemID)
                            return itemEquipLoc == "INVTYPE_HEAD"
                        end
                    elseif slotID == 10 then
                        filter = function(itemID)
                            local _, _, _, _, _, _, _, _, itemEquipLoc = C_Item.GetItemInfo(itemID)
                            return itemEquipLoc == "INVTYPE_HAND"
                        end
                    elseif slotID == 8 then
                        filter = function(itemID)
                            local _, _, _, _, _, _, _, _, itemEquipLoc = C_Item.GetItemInfo(itemID)
                            return itemEquipLoc == "INVTYPE_FEET"
                        end
                    elseif dbKey == "lureID" then
                        filter = function(itemID)
                            local validLures = {
                                [6533] = true,  -- Aquadynamic Fish Attractor
                                [34861] = true, -- Sharpened Fish Hook
                                [7307] = true,  -- Flesh Eating Worm
                                [6811] = true,  -- Aquadynamic Fish Lens
                                [6532] = true,  -- Bright Baubles
                                [6530] = true,  -- Nightcrawlers / Bright Baubles
                                [6529] = true,  -- Shiny Bauble / Nightcrawlers
                                [6522] = true,  -- Shiny Bauble
                            }
                            return validLures[itemID] or false
                        end
                    end

                    if filter then
                        FH.UI:ShowItemPopup(self, filter, slotID, dbKey)
                    end
                end
            end
        end
    end)
    btn:RegisterForClicks("LeftButtonDown", "RightButtonDown")

    -- Tooltip
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local currentID = slotID and FH.db.outfit[slotID] or FH.db[dbKey]
        if currentID then
            GameTooltip:SetItemByID(currentID)
        else
            GameTooltip:SetText("Drop " .. labelText .. " here.\nRight-click to clear.")
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    return btn
end

function FH.UI:Initialize()
    -- Main Frame
    self.frame = CreateFrame("Frame", "FishingHelperFrame", UIParent, "BasicFrameTemplateWithInset")
    self.frame:SetSize(280, 200)

    local pos = FH.db.framePosition or { point = "CENTER", relativePoint = "CENTER", xOfs = 0, yOfs = 0 }
    self.frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)

    self.frame.title = self.frame:CreateFontString(nil, "OVERLAY")
    self.frame.title:SetFontObject("GameFontHighlight")
    self.frame.title:SetPoint("LEFT", self.frame.TitleBg, "LEFT", 5, 0)
    self.frame.title:SetText("Fishing Helper")

    self.frame:SetMovable(true)
    self.frame:EnableMouse(true)
    self.frame:RegisterForDrag("LeftButton")
    self.frame:SetScript("OnDragStart", self.frame.StartMoving)
    self.frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
        FH.db.framePosition = { point = point, relativePoint = relativePoint, xOfs = xOfs, yOfs = yOfs }
    end)

    -- Main Action Button (Secure)
    self.mainButton = CreateFrame("Button", "FishingHelperMainButton", self.frame,
        "ItemButtonTemplate, SecureActionButtonTemplate")
    self.mainButton:SetSize(40, 40)
    self.mainButton:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 15, -35)
    self.mainButton:RegisterForClicks("AnyDown")
    self.mainButton:SetAttribute("type", "macro")

    self.mainButton.icon = _G["FishingHelperMainButtonIconTexture"]
    if not self.mainButton.icon then
        self.mainButton.icon = self.mainButton:CreateTexture(nil, "BACKGROUND")
        self.mainButton.icon:SetAllPoints()
    end
    self.mainButton.icon:SetTexture("Interface\\Icons\\Trade_Fishing")

    self.mainButton:RegisterForDrag("LeftButton")
    self.mainButton:SetScript("OnDragStart", function(self)
        if InCombatLockdown() then
            print("|cFFFF0000Fishing Helper:|r Cannot create macro in combat. Try again when out of combat.")
            return
        end
        local macroName = "FishHelper"
        local macroIndex = GetMacroIndexByName(macroName)

        local macroText = FH.currentMacroText or "/cast Fishing"
        local tooltip = FH.currentMacroTooltip or "Fishing"
        local fullText = "#showtooltip " .. tooltip .. "\n" .. macroText

        if macroIndex == 0 then
            macroIndex = CreateMacro(macroName, "INV_Misc_QuestionMark", fullText, true)    -- 1 for character specific
            if not macroIndex or macroIndex == 0 then
                macroIndex = CreateMacro(macroName, "INV_Misc_QuestionMark", fullText, nil) -- try global
            end
            if not macroIndex or macroIndex == 0 then
                print("|cFFFF0000Fishing Helper:|r You have no free macro slots!")
                return
            end
        else
            EditMacro(macroIndex, macroName, "INV_Misc_QuestionMark", fullText)
        end
        PickupMacro(macroName)
    end)

    -- Main Button Label
    local mbLabel = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    mbLabel:SetPoint("LEFT", self.mainButton, "RIGHT", 10, 0)
    mbLabel:SetText("Drag this spell or\nbind a key to fish.")

    -- Stop Fishing Button
    self.stopButton = CreateFrame("Button", "FishingHelperStopButton", self.frame, "SecureActionButtonTemplate")
    self.stopButton:SetSize(100, 22)
    self.stopButton:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 10)
    self.stopButton:RegisterForClicks("AnyDown")

    -- Manually set up visual elements for stopButton
    self.stopButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
    self.stopButton:GetNormalTexture():SetTexCoord(0, 0.625, 0, 0.6875)
    self.stopButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
    self.stopButton:GetPushedTexture():SetTexCoord(0, 0.625, 0, 0.6875)
    self.stopButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight", "ADD")
    self.stopButton:GetHighlightTexture():SetTexCoord(0, 0.625, 0, 0.6875)

    local stopText = self.stopButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    stopText:SetPoint("CENTER", 0, 1)
    self.stopButton:SetFontString(stopText)
    self.stopButton:SetText("Stop Fishing")

    -- Grid of configuration slots
    -- Slots: Pole(16), Hat(1), Gloves(10), Boots(8), Lure(custom db key)
    local startX = 15
    local startY = -115
    local spacing = 48

    self.slotPole = CreateItemSlot(self.frame, "FHSlotPole", 37, "Pole", nil, 16)
    self.slotPole:SetPoint("TOPLEFT", self.frame, "TOPLEFT", startX, startY)

    self.slotHat = CreateItemSlot(self.frame, "FHSlotHat", 37, "Hat", nil, 1)
    self.slotHat:SetPoint("TOPLEFT", self.frame, "TOPLEFT", startX + spacing, startY)

    self.slotGloves = CreateItemSlot(self.frame, "FHSlotGloves", 37, "Gloves", nil, 10)
    self.slotGloves:SetPoint("TOPLEFT", self.frame, "TOPLEFT", startX + spacing * 2, startY)

    self.slotBoots = CreateItemSlot(self.frame, "FHSlotBoots", 37, "Boots", nil, 8)
    self.slotBoots:SetPoint("TOPLEFT", self.frame, "TOPLEFT", startX + spacing * 3, startY)

    self.slotLure = CreateItemSlot(self.frame, "FHSlotLure", 37, "Lure", "lureID", nil)
    self.slotLure:SetPoint("TOPLEFT", self.frame, "TOPLEFT", startX + spacing * 4, startY)

    -- Lure count text overlay
    self.slotLure.count = self.slotLure:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    self.slotLure.count:SetPoint("BOTTOMRIGHT", self.slotLure, "BOTTOMRIGHT", -2, 2)

    -- Minimap Button
    if self.CreateMinimapButton then
        self:CreateMinimapButton()
    end

    -- Hide by default
    self.frame:Hide()

    -- Initialize icons
    self:UpdateAllIcons()
end

function FH.UI:UpdateAllIcons()
    if self.slotPole then self.slotPole:UpdateIcon() end
    if self.slotHat then self.slotHat:UpdateIcon() end
    if self.slotGloves then self.slotGloves:UpdateIcon() end
    if self.slotBoots then self.slotBoots:UpdateIcon() end
    if self.slotLure then self.slotLure:UpdateIcon() end
    self:UpdateLureCount()
end

function FH.UI:UpdateLureCount()
    if not self.slotLure then return end
    local countStr = ""
    local lureID = FH.db.lureID
    if lureID then
        local count = C_Item.GetItemCount(lureID)
        if count > 0 then
            countStr = tostring(count)
        else
            countStr = "|cFFFF00000|r"
        end
    end
    self.slotLure.count:SetText(countStr)
end

function FH.UI:CreateSettingsFrame()
    if self.settingsFrame then return end

    self.settingsFrame = CreateFrame("Frame", "FishingHelperSettingsFrame", UIParent, "BasicFrameTemplateWithInset")
    self.settingsFrame:SetSize(320, 130)
    self.settingsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    self.settingsFrame.title = self.settingsFrame:CreateFontString(nil, "OVERLAY")
    self.settingsFrame.title:SetFontObject("GameFontHighlight")
    self.settingsFrame.title:SetPoint("LEFT", self.settingsFrame.TitleBg, "LEFT", 5, 0)
    self.settingsFrame.title:SetText("Fishing Helper Settings")

    self.settingsFrame:SetMovable(true)
    self.settingsFrame:EnableMouse(true)
    self.settingsFrame:RegisterForDrag("LeftButton")
    self.settingsFrame:SetScript("OnDragStart", self.settingsFrame.StartMoving)
    self.settingsFrame:SetScript("OnDragStop", self.settingsFrame.StopMovingOrSizing)

    -- Explicitly prevent settings frame from intercepting and consuming keyboard events
    self.settingsFrame:EnableKeyboard(false)
    self.settingsFrame:SetPropagateKeyboardInput(true)

    if self.settingsFrame.CloseButton then
        self.settingsFrame.CloseButton:SetScript("OnClick", function()
            self.settingsFrame:Hide()
        end)
    end

    -- Screen blocker to cancel binding mode when clicking outside the settings window
    local blocker = CreateFrame("Button", "FishingHelperSettingsBlocker", UIParent)
    blocker:SetAllPoints(UIParent)
    blocker:SetFrameStrata("HIGH")
    blocker:SetFrameLevel(1)
    blocker:Hide()

    self.settingsFrame:SetFrameStrata("HIGH")
    self.settingsFrame:SetFrameLevel(2) -- Sits on top of the blocker

    blocker:SetScript("OnClick", function(blockerSelf)
        if self.settingsFrame.castRow and self.settingsFrame.castRow.isBinding then
            self.settingsFrame.castRow.isBinding = false
            self.settingsFrame.castRow:EnableKeyboard(false)
            self.settingsFrame.castRow:UpdateText()
        end
        if self.settingsFrame.stopRow and self.settingsFrame.stopRow.isBinding then
            self.settingsFrame.stopRow.isBinding = false
            self.settingsFrame.stopRow:EnableKeyboard(false)
            self.settingsFrame.stopRow:UpdateText()
        end
        blockerSelf:Hide()
    end)
    self.settingsFrame.blocker = blocker

    self.settingsFrame:HookScript("OnHide", function()
        if blocker then
            blocker:Hide()
        end
    end)

    -- Helper function to create a row
    local function CreateKeybindRow(parent, labelText, command, yOffset)
        local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
        label:SetText(labelText)

        local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        btn:SetSize(140, 22)
        btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -20, yOffset)
        btn:RegisterForClicks("AnyUp")
        btn:EnableMouseWheel(true)

        -- Explicitly default keyboard settings to false
        btn:EnableKeyboard(false)
        btn:SetPropagateKeyboardInput(true)

        function btn:UpdateText()
            local key = GetBindingKey(command)
            if key then
                self:SetText(key)
            else
                self:SetText("|cff888888Not Bound|r")
            end
        end

        btn:UpdateText()
        btn.isBinding = false

        btn:SetScript("OnClick", function(self, button)
            if self.isBinding then
                if button == "LeftButton" then
                    self.isBinding = false
                    self:EnableKeyboard(false)
                    self:UpdateText()
                    if parent.blocker then parent.blocker:Hide() end
                else
                    self.isBinding = false
                    self:EnableKeyboard(false)

                    local mouseMap = {
                        RightButton = "BUTTON2",
                        MiddleButton = "BUTTON3",
                    }
                    local keyName = mouseMap[button] or string.upper(button)

                    local modifier = ""
                    if IsShiftKeyDown() then modifier = modifier .. "SHIFT-" end
                    if IsControlKeyDown() then modifier = modifier .. "CTRL-" end
                    if IsAltKeyDown() then modifier = modifier .. "ALT-" end

                    local finalKey = modifier .. keyName

                    local key1, key2 = GetBindingKey(command)
                    if key1 then SetBinding(key1, nil) end
                    if key2 then SetBinding(key2, nil) end

                    SetBinding(finalKey, command)
                    SaveBindings(GetCurrentBindingSet())

                    self:UpdateText()
                    if parent.blocker then parent.blocker:Hide() end
                end
            else
                -- Cancel any other row's binding mode
                if parent.castRow and parent.castRow ~= self and parent.castRow.isBinding then
                    parent.castRow.isBinding = false
                    parent.castRow:EnableKeyboard(false)
                    parent.castRow:UpdateText()
                end
                if parent.stopRow and parent.stopRow ~= self and parent.stopRow.isBinding then
                    parent.stopRow.isBinding = false
                    parent.stopRow:EnableKeyboard(false)
                    parent.stopRow:UpdateText()
                end

                self.isBinding = true
                self:SetText("|cFF00FF00Press Key...|r")
                self:EnableKeyboard(true)
                if parent.blocker then parent.blocker:Show() end
            end
        end)

        btn:SetScript("OnKeyDown", function(self, key)
            if not self.isBinding then return end

            if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL" or key == "LALT" or key == "RALT" then
                return
            end

            self.isBinding = false
            self:EnableKeyboard(false)

            if key == "ESCAPE" then
                local key1, key2 = GetBindingKey(command)
                if key1 then SetBinding(key1, nil) end
                if key2 then SetBinding(key2, nil) end
                SaveBindings(GetCurrentBindingSet())
                self:UpdateText()
                if parent.blocker then parent.blocker:Hide() end
                return
            end

            local modifier = ""
            if IsShiftKeyDown() then modifier = modifier .. "SHIFT-" end
            if IsControlKeyDown() then modifier = modifier .. "CTRL-" end
            if IsAltKeyDown() then modifier = modifier .. "ALT-" end

            local finalKey = modifier .. key

            -- Clear this command's existing keys
            local key1, key2 = GetBindingKey(command)
            if key1 then SetBinding(key1, nil) end
            if key2 then SetBinding(key2, nil) end

            SetBinding(finalKey, command)
            SaveBindings(GetCurrentBindingSet())

            self:UpdateText()
            if parent.blocker then parent.blocker:Hide() end
        end)

        btn:SetScript("OnMouseWheel", function(self, delta)
            if not self.isBinding then return end

            self.isBinding = false
            self:EnableKeyboard(false)

            local keyName = delta > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN"

            local modifier = ""
            if IsShiftKeyDown() then modifier = modifier .. "SHIFT-" end
            if IsControlKeyDown() then modifier = modifier .. "CTRL-" end
            if IsAltKeyDown() then modifier = modifier .. "ALT-" end

            local finalKey = modifier .. keyName

            local key1, key2 = GetBindingKey(command)
            if key1 then SetBinding(key1, nil) end
            if key2 then SetBinding(key2, nil) end

            SetBinding(finalKey, command)
            SaveBindings(GetCurrentBindingSet())

            self:UpdateText()
            if parent.blocker then parent.blocker:Hide() end
        end)

        btn:SetScript("OnHide", function(self)
            if self.isBinding then
                self.isBinding = false
                self:EnableKeyboard(false)
                self:UpdateText()
                if parent.blocker then parent.blocker:Hide() end
            end
        end)

        return btn
    end

    self.settingsFrame.castRow = CreateKeybindRow(self.settingsFrame, "Cast Fishing Key:", "CLICK FishingHelperMainButton:LeftButton", -40)
    self.settingsFrame.stopRow = CreateKeybindRow(self.settingsFrame, "Stop Fishing Key:", "CLICK FishingHelperStopButton:LeftButton", -70)

    -- Instruction text
    local note = self.settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    note:SetPoint("BOTTOM", self.settingsFrame, "BOTTOM", 0, 15)
    note:SetText("Press ESC to clear keybind. Close when finished.")

    -- Hide by default upon creation
    self.settingsFrame:Hide()
end
