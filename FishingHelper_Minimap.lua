local addonName, addonTable = ...
local FH = addonTable[1]
FH.UI = FH.UI or {}

local minimapShapes = {
    ["ROUND"] = {true, true, true, true},
    ["SQUARE"] = {false, false, false, false},
    ["CORNER-TOPLEFT"] = {false, false, false, true},
    ["CORNER-TOPRIGHT"] = {false, false, true, false},
    ["CORNER-BOTTOMLEFT"] = {false, true, false, false},
    ["CORNER-BOTTOMRIGHT"] = {true, false, false, false},
    ["SIDE-LEFT"] = {false, true, false, true},
    ["SIDE-RIGHT"] = {true, false, true, false},
    ["SIDE-TOP"] = {false, false, true, true},
    ["SIDE-BOTTOM"] = {true, true, false, false},
    ["TRICORNER-TOPLEFT"] = {false, true, true, true},
    ["TRICORNER-TOPRIGHT"] = {true, false, true, true},
    ["TRICORNER-BOTTOMLEFT"] = {true, true, false, true},
    ["TRICORNER-BOTTOMRIGHT"] = {true, true, true, false},
}

local function OnButtonClick(button)
    if button == "RightButton" then
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
        if FH.UI.frame and FH.UI.frame:IsShown() then
            FH.UI.frame:Hide()
        elseif FH.UI.frame then
            FH.UI.frame:Show()
        end
    end
end

local function OnButtonTooltip(tooltip)
    tooltip:AddLine("Fishing Helper")
    tooltip:AddLine("Left-Click to toggle UI.", 1, 1, 1)
    tooltip:AddLine("Right-Click for Keybindings.", 1, 1, 1)
    tooltip:AddLine("Drag to move.", 1, 1, 1)
end

function FH.UI:CreateMinimapButton()
    FH.db = FH.db or {}
    FH.db.minimapPos = FH.db.minimapPos or 45

    -- Option 1: Use LibDBIcon if available (provides native compatibility with MinimapButtonButton, EllesmereUI, etc.)
    local LDB = _G.LibStub and _G.LibStub:GetLibrary("LibDataBroker-1.1", true)
    local LDBIcon = _G.LibStub and _G.LibStub:GetLibrary("LibDBIcon-1.0", true)

    if LDB and LDBIcon then
        if not LDBIcon:IsRegistered("FishingHelper") then
            local dataObject = LDB:NewDataObject("FishingHelper", {
                type = "launcher",
                text = "Fishing Helper",
                icon = "Interface\\AddOns\\FishingHelper\\logo.png",
                OnClick = function(self, button)
                    OnButtonClick(button)
                end,
                OnTooltipShow = function(tooltip)
                    OnButtonTooltip(tooltip)
                end,
            })
            LDBIcon:Register("FishingHelper", dataObject, FH.db)
        end
        self.minimapButton = LDBIcon:GetMinimapButton("FishingHelper")
        if self.minimapButton then
            self.minimapButton:Show()
            return
        end
    end

    -- Option 2: Standalone minimap button
    if self.minimapButton then
        self.minimapButton:Show()
        self:UpdateMinimapButton()
        return
    end
    if not Minimap then return end

    local btn = CreateFrame("Button", "FishingHelperMinimapButton", Minimap)
    self.minimapButton = btn
    btn:SetSize(32, 32)
    btn:SetFrameStrata("MEDIUM")
    if btn.SetFixedFrameStrata then btn:SetFixedFrameStrata(true) end
    btn:SetFrameLevel((Minimap:GetFrameLevel() or 5) + 5)
    if btn.SetFixedFrameLevel then btn:SetFixedFrameLevel(true) end
    btn:SetMovable(true)
    btn:EnableMouse(true)
    btn:SetClampedToScreen(true)
    btn.isMinimapButton = true
    btn:RegisterForDrag("LeftButton", "RightButton")
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    -- Circular background texture
    local background = btn:CreateTexture(nil, "BACKGROUND")
    background:SetSize(21, 21)
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetPoint("CENTER", btn, "CENTER", 0, 0)
    btn.background = background

    -- Main Icon (ARTWORK)
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
    icon:SetTexture("Interface\\AddOns\\FishingHelper\\logo.png")
    if not icon:GetTexture() then
        icon:SetTexture("Interface\\Icons\\Trade_Fishing")
    end
    btn.icon = icon

    -- Circular Tracking Border Overlay
    local overlay = btn:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    btn.overlay = overlay

    -- Circular Highlight
    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetBlendMode("ADD")
    highlight:SetAllPoints(btn)
    btn.highlight = highlight

    btn:SetScript("OnClick", function(self, button)
        OnButtonClick(button)
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        OnButtonTooltip(GameTooltip)
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
        if not mx or not my or not scale or scale == 0 then return end
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

    self:UpdateMinimapButton()
    btn:Show()
end

function FH.UI:UpdateMinimapButton()
    local LDBIcon = _G.LibStub and _G.LibStub:GetLibrary("LibDBIcon-1.0", true)
    if LDBIcon and LDBIcon:IsRegistered("FishingHelper") then
        LDBIcon:Refresh("FishingHelper", FH.db)
        local btn = LDBIcon:GetMinimapButton("FishingHelper")
        if btn then btn:Show() end
        return
    end

    if not self.minimapButton or not Minimap then return end

    local position = FH.db and FH.db.minimapPos or 45
    local angle = math.rad(position)
    local x, y, q = math.cos(angle), math.sin(angle), 1
    if x < 0 then q = q + 1 end
    if y > 0 then q = q + 2 end

    local mapWidth = Minimap:GetWidth()
    if not mapWidth or mapWidth < 20 then mapWidth = 140 end
    local mapHeight = Minimap:GetHeight()
    if not mapHeight or mapHeight < 20 then mapHeight = mapWidth end

    local w = (mapWidth / 2) + 10
    local h = (mapHeight / 2) + 10

    local minimapShape = GetMinimapShape and GetMinimapShape() or "ROUND"
    local quadTable = minimapShapes[minimapShape] or minimapShapes["ROUND"]

    if quadTable[q] then
        x, y = x * w, y * h
    else
        local diagRadiusW = math.sqrt(2 * (w ^ 2)) - 10
        local diagRadiusH = math.sqrt(2 * (h ^ 2)) - 10
        x = math.max(-w, math.min(x * diagRadiusW, w))
        y = math.max(-h, math.min(y * diagRadiusH, h))
    end

    self.minimapButton:ClearAllPoints()
    self.minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
    self.minimapButton:Show()
end
