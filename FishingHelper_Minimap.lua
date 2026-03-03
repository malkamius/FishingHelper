local addonName, addonTable = ...
local FH = addonTable[1]
FH.UI = FH.UI or {}

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
        if FH.UI.frame and FH.UI.frame:IsShown() then
            FH.UI.frame:Hide()
        elseif FH.UI.frame then
            FH.UI.frame:Show()
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
