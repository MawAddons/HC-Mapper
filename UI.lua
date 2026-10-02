local HCM = HCMapper

local function Text(parent, value, font)
    local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
    label:SetText(value or "")
    return label
end
local function Button(parent, value, width, height)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetWidth(width or 110); button:SetHeight(height or 24); button:SetText(value or "")
    return button
end
local function Edit(parent, width, height, multiline)
    local edit = CreateFrame("EditBox", nil, parent)
    edit:SetWidth(width); edit:SetHeight(height)
    edit:SetAutoFocus(false); edit:SetFontObject(ChatFontNormal)
    edit:SetTextInsets(7, 7, 5, 5)
    if multiline then edit:SetMultiLine(true) end
    edit:SetBackdrop({ bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=12, insets={left=3,right=3,top=3,bottom=3} })
    edit:SetBackdropColor(0.02,0.02,0.02,0.95)
    edit:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    return edit
end
local function Panel(name, width, height)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:SetWidth(width); frame:SetHeight(height); frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    frame:SetBackdrop({ bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", tile=true, tileSize=32, edgeSize=24, insets={left=6,right=6,top=6,bottom=6} })
    frame:SetBackdropColor(0.03,0.025,0.015,0.98)
    return frame
end

function HCM:CreateEditor()
    if self.Editor then return self.Editor end
    local frame = Panel("HCMapperEditor", 390, 285)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    frame.title = Text(frame, "Create Map Pin", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -18)
    frame.close = Button(frame, "X", 26, 24); frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -11)
    frame.close:SetScript("OnClick", function() frame:Hide() end)
    local nameLabel = Text(frame, "Pin name", "GameFontHighlightSmall"); nameLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -57)
    frame.name = Edit(frame, 335, 28); frame.name:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -75)
    local noteLabel = Text(frame, "Note", "GameFontHighlightSmall"); noteLabel:SetPoint("TOPLEFT", frame.name, "BOTTOMLEFT", 0, -8)
    frame.note = Edit(frame, 335, 62, true); frame.note:SetPoint("TOPLEFT", noteLabel, "BOTTOMLEFT", 0, -3)
    frame.categoryIndex = 1
    frame.category = Button(frame, "Category: Danger", 160, 27); frame.category:SetPoint("TOPLEFT", frame.note, "BOTTOMLEFT", 0, -12)
    frame.category:SetScript("OnClick", function()
        frame.categoryIndex = frame.categoryIndex + 1
        if frame.categoryIndex > table.getn(HCM.Categories) then frame.categoryIndex = 1 end
        frame.category:SetText("Category: " .. HCM.Categories[frame.categoryIndex])
    end)
    frame.scopes = { "Peers", "Guild", "Private" }; frame.scopeIndex = 1
    frame.scope = Button(frame, "Share: Peers", 160, 27); frame.scope:SetPoint("LEFT", frame.category, "RIGHT", 15, 0)
    frame.scope:SetScript("OnClick", function()
        frame.scopeIndex = frame.scopeIndex + 1
        if frame.scopeIndex > table.getn(frame.scopes) then frame.scopeIndex = 1 end
        frame.scope:SetText("Share: " .. frame.scopes[frame.scopeIndex])
    end)
    frame.coords = Text(frame, "", "GameFontDisableSmall"); frame.coords:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 25, 22)
    frame.cancel = Button(frame, "Cancel", 100, 27); frame.cancel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -22, 14)
    frame.cancel:SetScript("OnClick", function() frame:Hide() end)
    frame.save = Button(frame, "Save Pin", 110, 27); frame.save:SetPoint("RIGHT", frame.cancel, "LEFT", -8, 0)
    frame.save:SetScript("OnClick", function()
        local data = frame.pending
        if not data then return end
        data.title = HCM:Trim(frame.name:GetText(), 32)
        data.note = HCM:Trim(frame.note:GetText(), 70)
        data.category = HCM.Categories[frame.categoryIndex]
        data.scope = frame.scopes[frame.scopeIndex]
        if data.title == "" then HCM:Print("enter a pin name"); frame.name:SetFocus(); return end
        HCM:CreatePin(data)
        frame:Hide()
    end)
    frame:Hide(); self.Editor = frame
    return frame
end

function HCM:OpenPinEditor(data)
    local frame = self:CreateEditor()
    frame.pending = data
    frame.name:SetText(""); frame.note:SetText("")
    frame.categoryIndex = 1; frame.category:SetText("Category: Danger")
    frame.scopeIndex = 1; frame.scope:SetText("Share: Peers")
    if data.instance and data.instance ~= "" then frame.coords:SetText(data.instance .. "  " .. math.floor(data.ix*1000)/10 .. ", " .. math.floor(data.iy*1000)/10)
    else frame.coords:SetText(data.zone .. "  " .. math.floor(data.x*1000)/10 .. ", " .. math.floor(data.y*1000)/10) end
    frame:Show(); frame.name:SetFocus()
end

function HCM:CreateManager()
    if self.Manager then return self.Manager end
    local frame = Panel("HCMapperManager", 475, 465)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
    frame.title = Text(frame, "HC Mapper", "GameFontNormalLarge"); frame.title:SetPoint("TOP", frame, "TOP", 0, -18)
    frame.version = Text(frame, "v" .. self.VERSION, "GameFontDisableSmall"); frame.version:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -20)
    frame.close = Button(frame, "X", 26, 24); frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -11); frame.close:SetScript("OnClick", function() frame:Hide() end)
    frame.status = Text(frame, "", "GameFontHighlightSmall"); frame.status:SetPoint("TOPLEFT", frame, "TOPLEFT", 23, -55)
    frame.world = Button(frame, "World Map", 125, 28); frame.world:SetPoint("TOPLEFT", frame, "TOPLEFT", 23, -79)
    frame.world:SetScript("OnClick", function() if ToggleWorldMap then ToggleWorldMap() end end)
    frame.dungeons = Button(frame, "Dungeon Maps", 125, 28); frame.dungeons:SetPoint("LEFT", frame.world, "RIGHT", 12, 0)
    frame.dungeons:SetScript("OnClick", function() HCM:OpenDungeonBrowser() end)
    frame.sync = Button(frame, "Request Sync", 125, 28); frame.sync:SetPoint("LEFT", frame.dungeons, "RIGHT", 12, 0)
    frame.sync:SetScript("OnClick", function() HCM:RequestSync() end)
    frame.rows = {}
    local i
    for i = 1, 10 do
        local row = CreateFrame("Button", nil, frame)
        row:SetWidth(425); row:SetHeight(29); row:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -125 - (i-1)*30)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        row.icon = row:CreateTexture(nil, "ARTWORK"); row.icon:SetWidth(22); row.icon:SetHeight(22); row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)
        row.label = Text(row, "", "GameFontHighlightSmall"); row.label:SetPoint("LEFT", row.icon, "RIGHT", 8, 0); row.label:SetWidth(365); row.label:SetJustifyH("LEFT")
        row:SetScript("OnEnter", function() if this.pin then HCM:ShowPinTooltip(this, this.pin) end end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        row:SetScript("OnClick", function() if this.pin and IsShiftKeyDown() and arg1 == "RightButton" then HCM:DeletePin(this.pin.id, 1) end end)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        frame.rows[i] = row
    end
    frame.hint = Text(frame, "Shift-right-click your own pin to delete it.", "GameFontDisableSmall"); frame.hint:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 24, 22)
    frame:Hide(); self.Manager = frame
    return frame
end

function HCM:ShowPinTooltip(anchor, pin)
    GameTooltip:SetOwner(anchor, "ANCHOR_LEFT")
    GameTooltip:AddLine(pin.title, 1, .82, .2)
    GameTooltip:AddLine(pin.category .. " - " .. (pin.scope or "Peers"), unpack(self.CategoryColors[pin.category] or {1,1,1}))
    GameTooltip:AddLine("Shared by " .. pin.owner, .7, .7, .7)
    if pin.note and pin.note ~= "" then GameTooltip:AddLine(pin.note, 1, 1, 1, 1) end
    if self:NormalizeName(pin.owner) == self:NormalizeName(self:PlayerName()) then GameTooltip:AddLine("Shift-right-click to delete", .9, .35, .25) end
    GameTooltip:Show()
end

function HCM:RefreshManager()
    if not self.Manager then return end
    self.Manager.status:SetText(self:NetworkStatus() .. "  /  " .. table.getn(self.DB.pins) .. " pin(s)")
    local visible = {}; local i
    for i = table.getn(self.DB.pins), 1, -1 do if self:VisiblePin(self.DB.pins[i]) then table.insert(visible, self.DB.pins[i]) end end
    for i = 1, 10 do
        local row, pin = self.Manager.rows[i], visible[i]
        if pin then
            row.pin = pin; row.icon:SetTexture(self.CategoryIcons[pin.category] or self.CategoryIcons.Note)
            local place = pin.instance ~= "" and pin.instance or pin.zone
            row.label:SetText(pin.title .. "  |cff888888" .. place .. " - " .. pin.owner .. "|r"); row:Show()
        else row.pin = nil; row:Hide() end
    end
end

function HCM:ToggleManager()
    local frame = self:CreateManager()
    if frame:IsShown() then frame:Hide() else self:RefreshManager(); frame:Show() end
end

function HCM:CreateMinimapButton()
    local button = CreateFrame("Button", "HCMapperMinimapButton", Minimap)
    button:SetWidth(31); button:SetHeight(31)
    button:SetFrameStrata("MEDIUM"); button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local icon = button:CreateTexture(nil, "BACKGROUND"); icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01"); icon:SetWidth(20); icon:SetHeight(20); icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    local border = button:CreateTexture(nil, "OVERLAY"); border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder"); border:SetWidth(53); border:SetHeight(53); border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnClick", function() if arg1 == "RightButton" then HCM:OpenDungeonBrowser() else HCM:ToggleManager() end end)
    button:SetScript("OnDragStart", function() this.dragging = 1 end)
    button:SetScript("OnDragStop", function() this.dragging = nil end)
    button:SetScript("OnUpdate", function()
        if not this.dragging then return end
        local scale = Minimap:GetEffectiveScale() or 1
        local cursorX, cursorY = GetCursorPosition()
        local centerX, centerY = Minimap:GetCenter()
        local dx, dy = cursorX / scale - centerX, cursorY / scale - centerY
        local angle
        if math.atan2 then angle = math.atan2(dy, dx)
        elseif dx == 0 then angle = dy >= 0 and math.pi / 2 or -math.pi / 2
        else angle = math.atan(dy / dx); if dx < 0 then angle = angle + math.pi end end
        HCMapperDB.minimapAngle = angle
        HCM:PositionMinimapButton()
    end)
    button:SetScript("OnEnter", function() GameTooltip:SetOwner(this,"ANCHOR_LEFT"); GameTooltip:AddLine("HC Mapper"); GameTooltip:AddLine("Click to manage map pins",1,1,1); GameTooltip:Show() end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.MinimapButton = button
    self:PositionMinimapButton()
end

function HCM:PositionMinimapButton()
    if not self.MinimapButton then return end
    HCMapperDB.minimapAngle = tonumber(HCMapperDB.minimapAngle) or 3.75
    local radius = 82
    self.MinimapButton:ClearAllPoints()
    self.MinimapButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(HCMapperDB.minimapAngle) * radius, math.sin(HCMapperDB.minimapAngle) * radius)
end

function HCM:InitializeUI()
    self:CreateEditor(); self:CreateManager(); self:CreateMinimapButton(); self:RefreshManager()
end
