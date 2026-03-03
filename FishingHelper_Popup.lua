local addonName, addonTable = ...
local FH = addonTable[1]
FH.UI = FH.UI or {}

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
