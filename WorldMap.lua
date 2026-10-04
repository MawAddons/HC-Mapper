local HCM = HCMapper

local function Button(parent, value, width)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetWidth(width); button:SetHeight(24); button:SetText(value)
    return button
end

function HCM:CreateMapPin(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(24); button:SetHeight(24); button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button.icon = button:CreateTexture(nil, "ARTWORK"); button.icon:SetAllPoints(button)
    button.ring = button:CreateTexture(nil, "OVERLAY"); button.ring:SetTexture("Interface\\Buttons\\UI-ActionButton-Border"); button.ring:SetBlendMode("ADD"); button.ring:SetWidth(40); button.ring:SetHeight(40); button.ring:SetPoint("CENTER", button, "CENTER", 0, 0)
    button:SetScript("OnEnter", function() if this.pin then HCM:ShowPinTooltip(this, this.pin) end end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetScript("OnClick", function()
        if this.wasDragged then this.wasDragged=nil;return end
        if this.pin and arg1 == "RightButton" and IsShiftKeyDown() then HCM:RequestDeletePin(this.pin.id)
        elseif this.pin and arg1 == "LeftButton" then HCM:GoToPin(this.pin) end
    end)
    button:SetScript("OnDragStart", function() if HCM.BeginPinDrag then HCM:BeginPinDrag(this) end end)
    button:SetScript("OnDragStop", function() if HCM.EndPinDrag then HCM:EndPinDrag(this) end end)
    button:SetScript("OnUpdate", function() if this.dragging and HCM.UpdatePinDrag then HCM:UpdatePinDrag(this) end end)
    return button
end

function HCM:RefreshWorldPins()
    if not self.WorldOverlay or not WorldMapFrame or not WorldMapFrame:IsShown() then return end
    local continent, zone = self:GetMapContext()
    local targetContinent = continent > 0 and continent or 0
    local targetZone = zone or ""
    local visible = {}
    local i
    for i = 1, table.getn(self.DB.pins) do
        local pin = self.DB.pins[i]
        if pin.instance == "" and self:VisiblePin(pin) then
            local px,py=pin.x,pin.y
            if self.PendingMove and self.PendingMove.pin.id==pin.id then px,py=self.PendingMove.x,self.PendingMove.y end
            local x, y = self:ProjectPosition(pin.continent, pin.zone, px, py, targetContinent, targetZone)
            if x and y and x >= 0 and x <= 1 and y >= 0 and y <= 1 then table.insert(visible, { pin=pin, x=x, y=y }) end
        end
    end
    for i = 1, 120 do
        local button, data = self.WorldPins[i], visible[i]
        if data then
            button.pin = data.pin; button.icon:SetTexture(self:PinTexture(data.pin))
            local color = self.CategoryColors[data.pin.category] or {1,1,1}; button.ring:SetVertexColor(color[1],color[2],color[3])
            button:ClearAllPoints(); button:SetPoint("CENTER", WorldMapButton, "TOPLEFT", data.x*WorldMapButton:GetWidth(), -data.y*WorldMapButton:GetHeight()); button:Show()
        else button.pin=nil; button:Hide() end
    end
    if self.WorldStatus then
        local level = targetZone ~= "" and targetZone or (targetContinent > 0 and (targetContinent == 1 and "Kalimdor" or "Eastern Kingdoms") or "Azeroth")
        self.WorldStatus:SetText("HC Mapper - " .. level .. " - " .. table.getn(visible) .. " pin(s)")
    end
end

function HCM:BeginWorldPin()
    local continent, zone, zoneIndex = self:GetMapContext()
    if continent < 1 or zoneIndex < 1 or zone == "" then self:Print("zoom into a zone before creating an outdoor pin"); return end
    self.WorldAddMode = 1
    self.WorldAdd:SetText("Click map...")
    self:Print("click a position on the zone map; press Add Pin again to cancel")
end

function HCM:WorldMapClick()
    if not self.WorldAddMode then return nil end
    local continent, zone, zoneIndex = self:GetMapContext()
    if continent < 1 or zoneIndex < 1 or zone == "" then self.WorldAddMode=nil; self.WorldAdd:SetText("Add Pin"); return 1 end
    local x, y = self:CursorPosition(WorldMapButton)
    if x and y then self:OpenPinEditor({ continent=continent, zone=zone, x=x, y=y, instance="" }) end
    self.WorldAddMode=nil; self.WorldAdd:SetText("Add Pin")
    return 1
end

function HCM:InitializeWorldMap()
    if self.WorldOverlay or not WorldMapFrame or not WorldMapButton then return end
    self.WorldOverlay = CreateFrame("Frame", "HCMapperWorldOverlay", WorldMapButton)
    self.WorldOverlay:SetAllPoints(WorldMapButton)
    self.WorldOverlay:SetFrameLevel(WorldMapButton:GetFrameLevel()+5)
    self.WorldPins = {}
    local i
    for i=1,120 do self.WorldPins[i]=self:CreateMapPin(self.WorldOverlay); self.WorldPins[i].mapKind="world"; self.WorldPins[i]:Hide() end
    self.WorldAdd = Button(WorldMapFrame, "Add Pin", 90)
    self.WorldAdd:SetPoint("TOPRIGHT", WorldMapFrame, "TOPRIGHT", -145, -6)
    self.WorldAdd:SetScript("OnClick", function()
        if HCM.WorldAddMode then HCM.WorldAddMode=nil; HCM.WorldAdd:SetText("Add Pin") else HCM:BeginWorldPin() end
    end)
    self.WorldDungeon = Button(WorldMapFrame, "Dungeons", 90)
    self.WorldDungeon:SetPoint("RIGHT", self.WorldAdd, "LEFT", -6, 0)
    self.WorldDungeon:SetScript("OnClick", function() HCM:OpenDungeonBrowser() end)
    self.WorldStatus = WorldMapFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    self.WorldStatus:SetPoint("BOTTOM",WorldMapFrame,"BOTTOM",0,12)
    local originalClick = WorldMapButton:GetScript("OnClick")
    WorldMapButton:SetScript("OnClick", function()
        if HCM.WorldAddMode then HCM:WorldMapClick() elseif originalClick then originalClick() end
    end)
    local ticker = CreateFrame("Frame",nil,WorldMapFrame); ticker.elapsed=0; ticker.signature=""
    ticker:SetScript("OnUpdate",function()
        this.elapsed=this.elapsed+(arg1 or 0)
        if this.elapsed<0.25 then return end
        this.elapsed=0
        local c,z,zi=HCM:GetMapContext(); local signature=tostring(c)..":"..tostring(zi)..":"..tostring(z)..":"..tostring(table.getn(HCM.DB.pins))
        if signature~=this.signature then this.signature=signature; HCM:RefreshWorldPins() end
    end)
    local originalShow = WorldMapFrame:GetScript("OnShow")
    WorldMapFrame:SetScript("OnShow",function() if originalShow then originalShow() end; HCM:RefreshWorldPins() end)
end
