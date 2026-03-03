local addonName, addonTable = ...
local FH = addonTable[1]
FH.UI = {}

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

function FH.UI:CreateItemPopup()
    if self.popup then return end

    self.popup = CreateFrame("Frame", "FishingHelperItemPopup", UIParent, "BackdropTemplate")
    self.popup:SetSize(200, 300)
    self.popup:SetFrameStrata("TOOLTIP")
    self.popup:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    self.popup:SetBackdropColor(0, 0, 0, 0.9)
    self.popup:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)

    local title = self.popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -10)
    title:SetText("Select Item")
    self.popup.title = title

    self.popup.scrollFrame = CreateFrame("ScrollFrame", "FishingHelperItemPopupScroll", self.popup,
        "UIPanelScrollFrameTemplate")
    self.popup.scrollFrame:SetPoint("TOPLEFT", 10, -30)
    self.popup.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    self.popup.scrollChild = CreateFrame("Frame", nil, self.popup.scrollFrame)
    self.popup.scrollChild:SetSize(150, 1)
    self.popup.scrollFrame:SetScrollChild(self.popup.scrollChild)

    self.popup.buttons = {}

    -- Invisible background button to catch clicks outside and close the popup
    self.popup.bgBlocker = CreateFrame("Button", nil, UIParent)
    self.popup.bgBlocker:SetAllPoints(UIParent)
    self.popup.bgBlocker:SetFrameStrata("DIALOG")
    self.popup.bgBlocker:Hide()
    self.popup.bgBlocker:SetScript("OnClick", function()
        self.popup:Hide()
        self.popup.bgBlocker:Hide()
    end)
    self.popup:SetScript("OnShow", function() self.popup.bgBlocker:Show() end)
    self.popup:SetScript("OnHide", function() self.popup.bgBlocker:Hide() end)

    self.popup:Hide()
end

function FH.UI:ShowItemPopup(slotBtn, filterFunc, slotID, dbKey)
    if not self.popup then self:CreateItemPopup() end

    -- Hide previous buttons
    for _, btn in ipairs(self.popup.buttons) do
        btn:Hide()
    end

    local items = {}
    local seenIDs = {}

    -- Scan bags
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID and not seenIDs[itemID] then
                if filterFunc(itemID) then
                    table.insert(items, itemID)
                    seenIDs[itemID] = true
                end
            end
        end
    end

    -- Sort by name
    table.sort(items, function(a, b)
        local nameA = C_Item.GetItemInfo(a) or ""
        local nameB = C_Item.GetItemInfo(b) or ""
        return nameA < nameB
    end)

    if #items == 0 then
        self.popup.title:SetText("No items found")
    else
        self.popup.title:SetText("Select Item")
    end

    local yOffset = -5
    local buttonHeight = 36

    for i, itemID in ipairs(items) do
        local btn = self.popup.buttons[i]
        if not btn then
            btn = CreateFrame("Button", nil, self.popup.scrollChild)
            btn:SetSize(150, buttonHeight)

            btn.icon = btn:CreateTexture(nil, "BORDER")
            btn.icon:SetSize(28, 28)
            btn.icon:SetPoint("LEFT", 5, 0)

            btn.name = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            btn.name:SetPoint("LEFT", btn.icon, "RIGHT", 5, 0)
            btn.name:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
            btn.name:SetJustifyH("LEFT")
            btn.name:SetWordWrap(false)

            btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

            btn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetItemByID(self.itemID)
                GameTooltip:Show()
            end)

            btn:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)

            table.insert(self.popup.buttons, btn)
        end

        btn.itemID = itemID

        btn:SetScript("OnClick", function(self)
            local id = self.itemID
            if slotID then
                FH.db.outfit[slotID] = id
            else
                FH.db[dbKey] = id
            end

            slotBtn:UpdateIcon()
            if FH.UpdateMacro then FH:UpdateMacro() end
            if FH.UI and FH.UI.UpdateLureCount then FH.UI:UpdateLureCount() end

            FH.UI.popup:Hide()
        end)

        local itemName, _, itemQuality, _, _, _, _, _, _, itemTexture = C_Item.GetItemInfo(itemID)
        btn.icon:SetTexture(itemTexture)

        local r, g, b = C_Item.GetItemQualityColor(itemQuality or 1)
        btn.name:SetText(itemName)

        btn.name:SetTextColor(r, g, b)

        btn:SetPoint("TOPLEFT", 0, yOffset)
        btn:Show()
        yOffset = yOffset - buttonHeight
    end

    self.popup.scrollChild:SetHeight(math.abs(yOffset))

    -- Smart position popup
    self.popup:ClearAllPoints()

    local screenWidth = UIParent:GetWidth()
    local screenHeight = UIParent:GetHeight()
    local btnX, btnY = slotBtn:GetCenter()

    if btnX and btnY then
        local isRight = btnX > (screenWidth / 2)
        local isTop = btnY > (screenHeight / 2)

        local pointY = isTop and "TOP" or "BOTTOM"
        local pointX = isRight and "RIGHT" or "LEFT"

        local relPointY = isTop and "BOTTOM" or "TOP"
        local relPointX = isRight and "LEFT" or "RIGHT"

        local xOfs = isRight and -5 or 5
        local yOfs = isTop and -5 or 5

        self.popup:SetPoint(pointY .. pointX, slotBtn, relPointY .. relPointX, xOfs, yOfs)
    else
        self.popup:SetPoint("TOPLEFT", slotBtn, "BOTTOMRIGHT", 5, -5)
    end

    self.popup:Show()
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
    self:CreateMinimapButton()

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
        local count = GetItemCount(lureID)
        if count > 0 then
            countStr = tostring(count)
        else
            countStr = "|cFFFF00000|r"
        end
    end
    self.slotLure.count:SetText(countStr)
end

function FH.UI:CreateMinimapButton()
    local btn = CreateFrame("Button", "FishingHelperMinimapButton", Minimap)
    btn:SetSize(32, 32)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)

    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\AddOns\\FishingHelper\\logo.png")
    icon:SetSize(21, 21)
    icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 6, -5)

    local overlay = btn:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)

    btn:EnableMouse(true)
    btn:RegisterForDrag("LeftButton", "RightButton")
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    btn:SetScript("OnClick", function(self, button)
        if FishingHelperFrame:IsShown() then
            FishingHelperFrame:Hide()
        else
            FishingHelperFrame:Show()
        end
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Fishing Helper")
        GameTooltip:AddLine("Left-Click to toggle UI.", 1, 1, 1)
        GameTooltip:AddLine("Drag to move.", 1, 1, 1)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    btn.isDragging = false
    local function UpdatePosition()
        local xpos, ypos = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        local mx, my = Minimap:GetCenter()
        xpos, ypos = xpos / scale, ypos / scale
        local angle = math.deg(math.atan2(ypos - my, xpos - mx))
        if angle < 0 then
            angle = angle + 360
        end
        FH.db.minimapPos = angle
        FH.UI:UpdateMinimapButton()
    end

    btn:SetScript("OnDragStart", function(self)
        self.isDragging = true
        self:LockHighlight()
        self:SetScript("OnUpdate", UpdatePosition)
    end)

    btn:SetScript("OnDragStop", function(self)
        self.isDragging = false
        self:UnlockHighlight()
        self:SetScript("OnUpdate", nil)
    end)

    self.minimapButton = btn

    self:UpdateMinimapButton()
end

function FH.UI:UpdateMinimapButton()
    local angle = math.rad(FH.db.minimapPos or 45)
    local x = math.cos(angle)
    local y = math.sin(angle)

    local minimapShape = GetMinimapShape and GetMinimapShape() or "ROUND"

    local radius = 80
    if minimapShape == "ROUND" then
        x = x * radius
        y = y * radius
    else
        radius = radius * 0.82
        x = math.max(-radius, math.min(x * radius, radius))
        y = math.max(-radius, math.min(y * radius, radius))
    end

    self.minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end
