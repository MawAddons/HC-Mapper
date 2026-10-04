local HCM = HCMapper

local function Button(parent, value, width)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetWidth(width); button:SetHeight(24); button:SetText(value)
    return button
end
local function Text(parent,value,font)
    local label=parent:CreateFontString(nil,"OVERLAY",font or"GameFontNormal");label:SetText(value or"");return label
end
local function Edit(parent,width)
    local edit=CreateFrame("EditBox",nil,parent);edit:SetWidth(width);edit:SetHeight(26);edit:SetAutoFocus(false);edit:SetFontObject(ChatFontNormal);edit:SetTextInsets(7,7,4,4)
    edit:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=12,insets={left=3,right=3,top=3,bottom=3}});edit:SetBackdropColor(.02,.02,.02,.95)
    edit:SetScript("OnEscapePressed",function()this:ClearFocus()end);return edit
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
    if self.WorldPinsButton then self.WorldPinsButton:SetText("Pins ("..table.getn(visible)..")")end
    self:RefreshWorldPinPanel()
end

function HCM:RefreshWorldPinPanel()
    local frame=self.WorldPinPanel;if not frame or not frame:IsShown()then return end
    local visible={};local query=string.lower(self:Trim(frame.search:GetText(),40));query=string.gsub(query,"(%W)","%%%1")
    local category=frame.categoryValues[frame.categoryIndex];local scope=frame.scopeValues[frame.scopeIndex];local i
    for i=table.getn(self.DB.pins),1,-1 do
        local pin=self.DB.pins[i];local mine=self:NormalizeName(pin.owner)==self:NormalizeName(self:PlayerName())
        local categoryOK=category=="All categories"or pin.category==category
        local scopeOK=scope=="All pins"or(scope=="My pins"and mine)or(scope=="Guild pins"and not mine and pin.scope=="Guild")or(scope=="Peer pins"and not mine and pin.scope~="Guild")
        local haystack=string.lower((pin.title or"").." "..(pin.note or"").." "..(pin.owner or"").." "..(pin.zone or"").." "..(pin.instance or""))
        if self:VisiblePin(pin)and categoryOK and scopeOK and(query==""or string.find(haystack,query))then table.insert(visible,pin)end
    end
    local maxOffset=table.getn(visible)-frame.rowCount;if maxOffset<0 then maxOffset=0 end
    if frame.offset>maxOffset then frame.offset=maxOffset end
    for i=1,frame.rowCount do
        local row=frame.rows[i];local pin=visible[frame.offset+i]
        if pin then
            row.pin=pin;row.icon:SetTexture(self:PinTexture(pin));row.label:SetText(pin.title)
            local place=pin.instance~=""and self:DungeonName(pin.instance)or pin.zone
            row.detail:SetText(pin.category.." - "..pin.owner.." - "..place);row:Show()
        else row.pin=nil;row:Hide()end
    end
    local first=table.getn(visible)>0 and frame.offset+1 or 0;local last=math.min(frame.offset+frame.rowCount,table.getn(visible))
    frame.page:SetText(first.."-"..last.." / "..table.getn(visible))
end

function HCM:CreateWorldPinPanel()
    if self.WorldPinPanel then return self.WorldPinPanel end
    local panelHeight=WorldMapButton:GetHeight()-174;if panelHeight>535 then panelHeight=535 elseif panelHeight<390 then panelHeight=390 end
    local frame=CreateFrame("Frame","HCMapperWorldPinPanel",WorldMapFrame);frame:SetWidth(278);frame:SetHeight(panelHeight);frame:SetPoint("TOPRIGHT",WorldMapButton,"TOPRIGHT",-12,-122);frame:SetFrameLevel(WorldMapButton:GetFrameLevel()+20)
    frame.rowCount=panelHeight>=500 and 8 or 6
    frame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=20,insets={left=6,right=6,top=6,bottom=6}});frame:SetBackdropColor(.02,.02,.02,.97)
    frame.title=Text(frame,"HC Mapper Pins","GameFontNormalLarge");frame.title:SetPoint("TOPLEFT",frame,"TOPLEFT",16,-15)
    frame.close=CreateFrame("Button",nil,frame,"UIPanelCloseButton");frame.close:SetWidth(28);frame.close:SetHeight(28);frame.close:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-7,-7);frame.close:SetScript("OnClick",function()frame:Hide()end)
    frame.search=Edit(frame,246);frame.search:SetPoint("TOPLEFT",frame,"TOPLEFT",16,-43);frame.search:SetScript("OnTextChanged",function()frame.offset=0;HCM:RefreshWorldPinPanel()end)
    frame.categoryValues={"All categories","Danger","Treasure","Vendor","Profession","Resource","Travel","Note"};frame.categoryIndex=1
    frame.category=Button(frame,"All categories",119);frame.category:SetPoint("TOPLEFT",frame.search,"BOTTOMLEFT",0,-6)
    frame.category:SetScript("OnClick",function()frame.categoryIndex=frame.categoryIndex+1;if frame.categoryIndex>table.getn(frame.categoryValues)then frame.categoryIndex=1 end;frame.category:SetText(frame.categoryValues[frame.categoryIndex]);frame.offset=0;HCM:RefreshWorldPinPanel()end)
    frame.scopeValues={"All pins","My pins","Peer pins","Guild pins"};frame.scopeIndex=1
    frame.scope=Button(frame,"All pins",119);frame.scope:SetPoint("LEFT",frame.category,"RIGHT",8,0)
    frame.scope:SetScript("OnClick",function()frame.scopeIndex=frame.scopeIndex+1;if frame.scopeIndex>table.getn(frame.scopeValues)then frame.scopeIndex=1 end;frame.scope:SetText(frame.scopeValues[frame.scopeIndex]);frame.offset=0;HCM:RefreshWorldPinPanel()end)
    frame.rows={};local i
    for i=1,frame.rowCount do
        local row=CreateFrame("Button",nil,frame);row:SetWidth(246);row:SetHeight(39);row:SetPoint("TOPLEFT",frame,"TOPLEFT",16,-108-(i-1)*40);row:RegisterForClicks("LeftButtonUp","RightButtonUp");row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        row.icon=row:CreateTexture(nil,"ARTWORK");row.icon:SetWidth(30);row.icon:SetHeight(30);row.icon:SetPoint("LEFT",row,"LEFT",2,0)
        row.label=Text(row,"","GameFontHighlightSmall");row.label:SetPoint("TOPLEFT",row.icon,"TOPRIGHT",7,-2);row.label:SetWidth(200);row.label:SetJustifyH("LEFT")
        row.detail=Text(row,"","GameFontDisableSmall");row.detail:SetPoint("BOTTOMLEFT",row.icon,"BOTTOMRIGHT",7,2);row.detail:SetWidth(200);row.detail:SetJustifyH("LEFT")
        row:SetScript("OnEnter",function()if this.pin then HCM:ShowPinTooltip(this,this.pin)end end);row:SetScript("OnLeave",function()GameTooltip:Hide()end)
        row:SetScript("OnClick",function()if not this.pin then return end;if arg1=="RightButton"and IsShiftKeyDown()then HCM:RequestDeletePin(this.pin.id)elseif arg1=="LeftButton"then HCM:GoToPin(this.pin)end end)
        row:Hide();frame.rows[i]=row
    end
    frame.offset=0;frame.prev=Button(frame,"<",34);frame.prev:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",16,48);frame.prev:SetScript("OnClick",function()frame.offset=math.max(0,frame.offset-frame.rowCount);HCM:RefreshWorldPinPanel()end)
    frame.next=Button(frame,">",34);frame.next:SetPoint("LEFT",frame.prev,"RIGHT",6,0);frame.next:SetScript("OnClick",function()frame.offset=frame.offset+frame.rowCount;HCM:RefreshWorldPinPanel()end)
    frame.page=Text(frame,"0-0 / 0","GameFontDisableSmall");frame.page:SetPoint("LEFT",frame.next,"RIGHT",10,0)
    frame.add=Button(frame,"Add Pin",100);frame.add:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-16,48);frame.add:SetScript("OnClick",function()frame:Hide();HCM:BeginWorldPin()end)
    frame.hint=Text(frame,"Click: open location   Shift-right: delete own pin","GameFontDisableSmall");frame.hint:SetPoint("BOTTOM",frame,"BOTTOM",0,18)
    frame:SetScript("OnShow",function()HCM:RefreshWorldPinPanel()end);frame:Hide();self.WorldPinPanel=frame;return frame
end

function HCM:ToggleNativePinManager()
    if not WorldMapFrame or not ToggleWorldMap then return end
    if self.Manager and self.Manager:IsShown()then self.Manager:Hide()end
    local wasHidden=not WorldMapFrame:IsShown();if wasHidden then ToggleWorldMap()end
    local panel=self:CreateWorldPinPanel()
    if wasHidden then panel:Show();self:RefreshWorldPinPanel()
    elseif panel:IsShown()then panel:Hide()else panel:Show();self:RefreshWorldPinPanel()end
end

function HCM:ToggleNativeMap()
    if not WorldMapFrame or not ToggleWorldMap then return end
    if self.Manager and self.Manager:IsShown()then self.Manager:Hide()end
    ToggleWorldMap()
    if WorldMapFrame:IsShown()then self:RefreshWorldPins()end
end

function HCM:OpenNativePin(pin)
    if not pin or not WorldMapFrame or not ToggleWorldMap then return end
    if self.Manager and self.Manager:IsShown()then self.Manager:Hide()end
    if not WorldMapFrame:IsShown()then ToggleWorldMap()end
    local zoneIndex=self:FindZoneIndex(pin.continent,pin.zone)
    if zoneIndex and SetMapZoom then SetMapZoom(pin.continent,zoneIndex)
    elseif SetMapZoom then SetMapZoom(pin.continent);self:Print("zone map not found; showing its continent")end
    self:RefreshWorldPins()
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
    self.WorldAdd:SetWidth(116)
    self.WorldAdd:SetPoint("BOTTOMRIGHT", WorldMapButton, "BOTTOMRIGHT", -18, 18)
    self.WorldAdd:SetScript("OnClick", function()
        if HCM.WorldAddMode then HCM.WorldAddMode=nil; HCM.WorldAdd:SetText("Add Pin") else HCM:BeginWorldPin() end
    end)
    self.WorldDungeon = Button(WorldMapFrame, "Dungeons", 90)
    self.WorldDungeon:SetWidth(116)
    self.WorldDungeon:SetPoint("RIGHT", self.WorldAdd, "LEFT", -6, 0)
    self.WorldDungeon:SetScript("OnClick", function() if WorldMapFrame:IsShown()and ToggleWorldMap then ToggleWorldMap()end;HCM:OpenDungeonBrowser() end)
    self.WorldPinsButton = Button(WorldMapFrame, "Pins", 90)
    self.WorldPinsButton:SetWidth(116)
    self.WorldPinsButton:SetPoint("RIGHT", self.WorldDungeon, "LEFT", -6, 0)
    self.WorldPinsButton:SetScript("OnClick",function()HCM:ToggleNativePinManager()end)
    self:CreateWorldPinPanel()
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
