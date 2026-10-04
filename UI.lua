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
    local frame = Panel("HCMapperEditor", 390, 340)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    frame.title = Text(frame, "Create Map Pin", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -18)
    frame.close=CreateFrame("Button",nil,frame,"UIPanelCloseButton");frame.close:SetWidth(32);frame.close:SetHeight(32);frame.close:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-8,-8)
    frame.close:SetScript("OnClick",function()HCM:ClosePinEditor()end)
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
    frame.iconIndex = 2
    frame.icon = Button(frame, "      Icon: Danger  (2/25)", 335, 30); frame.icon:SetPoint("TOPLEFT", frame.category, "BOTTOMLEFT", 0, -10)
    frame.icon:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    frame.iconPreview = frame.icon:CreateTexture(nil, "ARTWORK"); frame.iconPreview:SetWidth(22); frame.iconPreview:SetHeight(22); frame.iconPreview:SetPoint("LEFT", frame.icon, "LEFT", 10, 0)
    local function RefreshEditorIcon()
        local icon = HCM.PinIcons[frame.iconIndex]
        frame.iconPreview:SetTexture(icon[3]); frame.icon:SetText("      Icon: " .. icon[2] .. "  (" .. frame.iconIndex .. "/" .. table.getn(HCM.PinIcons) .. ")")
    end
    frame.iconPalette=CreateFrame("Frame",nil,frame);frame.iconPalette:SetWidth(190);frame.iconPalette:SetHeight(190);frame.iconPalette:SetPoint("LEFT",frame,"RIGHT",6,0)
    frame.iconPalette:SetFrameLevel(frame:GetFrameLevel()+5)
    frame.iconPalette:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=12,insets={left=4,right=4,top=4,bottom=4}});frame.iconPalette:SetBackdropColor(.02,.02,.02,.98)
    frame.iconChoices={}
    local iconChoiceIndex
    for iconChoiceIndex=1,table.getn(HCM.PinIcons)do
        local choice=CreateFrame("Button",nil,frame.iconPalette);choice:SetWidth(32);choice:SetHeight(32)
        local col=(iconChoiceIndex-1)-math.floor((iconChoiceIndex-1)/5)*5;local row=math.floor((iconChoiceIndex-1)/5)
        choice:SetPoint("TOPLEFT",frame.iconPalette,"TOPLEFT",10+col*35,-10-row*35);choice.iconIndex=iconChoiceIndex
        choice.texture=choice:CreateTexture(nil,"ARTWORK");choice.texture:SetAllPoints(choice);choice.texture:SetTexture(HCM.PinIcons[iconChoiceIndex][3])
        choice:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
        choice:SetScript("OnClick",function()frame.iconIndex=this.iconIndex;RefreshEditorIcon();frame.iconPalette:Hide()end)
        choice:SetScript("OnEnter",function()local icon=HCM.PinIcons[this.iconIndex];GameTooltip:SetOwner(this,"ANCHOR_RIGHT");GameTooltip:AddLine(icon[2]);GameTooltip:Show()end)
        choice:SetScript("OnLeave",function()GameTooltip:Hide()end)
        frame.iconChoices[iconChoiceIndex]=choice
    end
    frame.iconPalette:Hide()
    frame.icon:SetScript("OnClick", function()
        if arg1 == "RightButton" then
            frame.iconIndex=frame.iconIndex-1;if frame.iconIndex<1 then frame.iconIndex=table.getn(HCM.PinIcons)end;RefreshEditorIcon()
        elseif frame.iconPalette:IsShown()then frame.iconPalette:Hide()else frame.iconPalette:Show()end
    end)
    frame.RefreshIcon = RefreshEditorIcon
    frame.coords = Text(frame, "", "GameFontDisableSmall"); frame.coords:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 25, 55)
    frame.cancel = Button(frame, "Cancel", 100, 27); frame.cancel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -22, 14)
    frame.cancel:SetScript("OnClick", function() HCM:ClosePinEditor() end)
    frame.save = Button(frame, "Save Pin", 110, 27); frame.save:SetPoint("RIGHT", frame.cancel, "LEFT", -8, 0)
    frame.save:SetScript("OnClick", function()
        local data = frame.pending
        if not data then return end
        data.title = HCM:Trim(frame.name:GetText(), 32)
        data.note = HCM:Trim(frame.note:GetText(), 70)
        data.category = HCM.Categories[frame.categoryIndex]
        data.scope = frame.scopes[frame.scopeIndex]
        data.icon = HCM.PinIcons[frame.iconIndex][1]
        if data.title == "" then HCM:Print("enter a pin name"); frame.name:SetFocus(); return end
        HCM:CreatePin(data)
        HCM:ClosePinEditor()
    end)
    frame.name:SetScript("OnEscapePressed",function()HCM:ClosePinEditor()end)
    frame.note:SetScript("OnEscapePressed",function()HCM:ClosePinEditor()end)
    frame:SetScript("OnHide",function()
        frame.iconPalette:Hide();frame.pending=nil
        HCM.WorldAddMode=nil;if HCM.WorldAdd then HCM.WorldAdd:SetText("Add Pin")end
        if HCM.Manager then HCM.Manager.addMode=nil;HCM.Manager.newPin:SetText("+ New Pin")end
    end)
    if UISpecialFrames then table.insert(UISpecialFrames,"HCMapperEditor")end
    frame:Hide(); self.Editor = frame
    return frame
end

function HCM:ClosePinEditor()
    if not self.Editor then return end
    if self.Editor.iconPalette then self.Editor.iconPalette:Hide()end
    self.Editor.pending=nil;self.Editor:Hide()
end

function HCM:OpenPinEditor(data)
    local frame = self:CreateEditor()
    frame.pending = data
    frame.name:SetText(""); frame.note:SetText("")
    frame.categoryIndex = 1; frame.category:SetText("Category: Danger")
    frame.scopeIndex = 1; frame.scope:SetText("Share: Peers")
    frame.iconIndex = 2; frame.RefreshIcon()
    frame.iconPalette:Hide()
    if data.instance and data.instance ~= "" then frame.coords:SetText(data.instance .. "  " .. math.floor(data.ix*1000)/10 .. ", " .. math.floor(data.iy*1000)/10)
    else frame.coords:SetText(data.zone .. "  " .. math.floor(data.x*1000)/10 .. ", " .. math.floor(data.y*1000)/10) end
    if self.Manager then frame:SetFrameLevel(self.Manager:GetFrameLevel()+50) end
    frame.iconPalette:SetFrameLevel(frame:GetFrameLevel()+5)
    frame:Show(); if frame.Raise then frame:Raise() end; frame.name:SetFocus()
end

function HCM:CreateManager()
    if self.Manager then return self.Manager end
    local frame = Panel("HCMapperManager", 1000, 650)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    frame:SetScript("OnDragStart", nil); frame:SetScript("OnDragStop", nil)
    frame.titlebar = CreateFrame("Button", nil, frame)
    frame.titlebar:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -10); frame.titlebar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -76, -10); frame.titlebar:SetHeight(34)
    frame.titlebar:RegisterForDrag("LeftButton")
    frame.titlebar:SetScript("OnDragStart", function() frame:StartMoving() end)
    frame.titlebar:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
    frame.title = Text(frame.titlebar, "HC Mapper", "GameFontNormalLarge"); frame.title:SetPoint("CENTER", frame.titlebar, "CENTER", 25, 0)
    frame.version = Text(frame, "v" .. self.VERSION, "GameFontDisableSmall"); frame.version:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -21)
    frame.close = Button(frame, "X", 28, 26); frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -13); frame.close:SetScript("OnClick", function() frame:Hide() end)
    frame.minimize = Button(frame, "-", 28, 26); frame.minimize:SetPoint("RIGHT", frame.close, "LEFT", -4, 0)
    frame.content = CreateFrame("Frame", nil, frame); frame.content:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -48); frame.content:SetWidth(1000); frame.content:SetHeight(592)
    frame.minimize:SetScript("OnClick", function()
        if frame.minimized then frame.minimized=nil; frame:SetHeight(650); frame.content:Show(); frame.minimize:SetText("-")
        else frame.minimized=1; frame.content:Hide(); frame:SetHeight(56); frame.minimize:SetText("+") end
    end)

    frame.tabs = {}; local tabNames={"World","Continent","Zone","Dungeon"}; local i
    for i=1,4 do
        local tab=Button(frame.content,tabNames[i],135,30);tab:SetPoint("TOPLEFT",frame.content,"TOPLEFT",20+(i-1)*143,-2);tab.mode=tabNames[i]
        tab:SetScript("OnClick",function()HCM:SetDashboardMode(this.mode)end);frame.tabs[i]=tab
    end
    frame.search=Edit(frame.content,250,30);frame.search:SetPoint("TOPRIGHT",frame.content,"TOPRIGHT",-58,-2)
    frame.search:SetScript("OnTextChanged",function()HCM:RefreshManager()end)
    frame.searchHint=Text(frame.content,"Search pins...","GameFontDisableSmall");frame.searchHint:SetPoint("LEFT",frame.search,"LEFT",9,0)
    frame.search:SetScript("OnEditFocusGained",function()frame.searchHint:Hide()end)
    frame.search:SetScript("OnEditFocusLost",function()if frame.search:GetText()==""then frame.searchHint:Show()end end)
    frame.sync=Button(frame.content,"",48,30);frame.sync:SetPoint("LEFT",frame.search,"RIGHT",5,0)
    frame.syncIcon=frame.sync:CreateTexture(nil,"ARTWORK");frame.syncIcon:SetTexture("Interface\\Icons\\INV_Gizmo_02");frame.syncIcon:SetWidth(22);frame.syncIcon:SetHeight(22);frame.syncIcon:SetPoint("CENTER",frame.sync,"CENTER",0,0)
    frame.sync:SetScript("OnClick",function()HCM:Print("sync is automatic; every pin is stored locally")end)
    frame.sync:SetScript("OnEnter",function()GameTooltip:SetOwner(this,"ANCHOR_LEFT");GameTooltip:AddLine("Automatic sync");GameTooltip:AddLine("Pins are continuously replicated to local databases",1,1,1);GameTooltip:Show()end);frame.sync:SetScript("OnLeave",function()GameTooltip:Hide()end)

    frame.breadcrumb=Text(frame.content,"","GameFontNormal");frame.breadcrumb:SetPoint("TOPLEFT",frame.content,"TOPLEFT",26,-43)
    frame.nextDungeon=Button(frame.content,"Next Dungeon >",120,23);frame.nextDungeon:SetPoint("TOPRIGHT",frame.content,"TOPRIGHT",-302,-38);frame.nextDungeon:Hide()
    frame.nextDungeon:SetScript("OnClick",function()
        local index=1;local n;for n=1,table.getn(HCM.DungeonMaps or{})do if HCM.DungeonMaps[n][1]==frame.dungeonKey then index=n+1 end end
        if index>table.getn(HCM.DungeonMaps or{})then index=1 end
        if HCM.DungeonMaps and HCM.DungeonMaps[index]then frame.dungeonKey=HCM.DungeonMaps[index][1];HCM:RefreshDashboardMap()end
    end)
    frame.map=CreateFrame("Button",nil,frame.content);frame.map:SetWidth(680);frame.map:SetHeight(486);frame.map:SetPoint("TOPLEFT",frame.content,"TOPLEFT",18,-66);frame.map:RegisterForClicks("LeftButtonUp","RightButtonUp")
    frame.map:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
    frame.map:SetBackdropColor(.01,.01,.01,1)
    frame.tiles={}
    for i=1,12 do
        local tile=frame.map:CreateTexture(nil,"BACKGROUND");tile:SetWidth(170);tile:SetHeight(162)
        -- Lua 5.0 (WoW 1.12) has no modulo operator.
        local col=(i-1)-math.floor((i-1)/4)*4;local row=math.floor((i-1)/4);tile:SetPoint("TOPLEFT",frame.map,"TOPLEFT",col*170,-row*162);frame.tiles[i]=tile
    end
    frame.dungeonTexture=frame.map:CreateTexture(nil,"BACKGROUND");frame.dungeonTexture:SetAllPoints(frame.map);frame.dungeonTexture:Hide()
    frame.overlays={}
    frame.map:SetScript("OnClick",function()HCM:DashboardMapClick(arg1)end)
    frame.mapPins={};for i=1,120 do frame.mapPins[i]=self:CreateMapPin(frame.map);frame.mapPins[i].mapKind="dashboard";frame.mapPins[i]:SetFrameLevel(frame.map:GetFrameLevel()+4);frame.mapPins[i]:Hide()end
    frame.unitMarkers={}
    for i=1,41 do
        local marker=CreateFrame("Button",nil,frame.map);marker:SetWidth(i==1 and 22 or 18);marker:SetHeight(i==1 and 22 or 18);marker:SetFrameLevel(frame.map:GetFrameLevel()+6)
        marker.texture=marker:CreateTexture(nil,"ARTWORK");marker.texture:SetAllPoints(marker);marker.texture:SetTexture(i==1 and"Interface\\Minimap\\MinimapArrow"or"Interface\\WorldMap\\WorldMapPartyIcon")
        marker:SetScript("OnEnter",function()if this.unit then GameTooltip:SetOwner(this,"ANCHOR_RIGHT");GameTooltip:AddLine(UnitName(this.unit)or this.unit);GameTooltip:AddLine(this.unit=="player"and"You"or"Party / Raid member",1,1,1);GameTooltip:Show()end end)
        marker:SetScript("OnLeave",function()GameTooltip:Hide()end);marker:Hide();frame.unitMarkers[i]=marker
    end
    frame.unitTicker=CreateFrame("Frame",nil,frame);frame.unitTicker.elapsed=0
    frame.unitTicker:SetScript("OnUpdate",function()this.elapsed=this.elapsed+arg1;if this.elapsed>=.25 then this.elapsed=0;HCM:RefreshDashboardUnits()end end)

    frame.side=CreateFrame("Frame",nil,frame.content);frame.side:SetWidth(278);frame.side:SetHeight(486);frame.side:SetPoint("TOPRIGHT",frame.content,"TOPRIGHT",-18,-66)
    frame.side:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=12,insets={left=4,right=4,top=4,bottom=4}});frame.side:SetBackdropColor(.025,.02,.01,.96)
    frame.sideTitle=Text(frame.side,"Pin Manager","GameFontNormalLarge");frame.sideTitle:SetPoint("TOPLEFT",frame.side,"TOPLEFT",16,-14)
    frame.categoryIndex=1;frame.categoryValues={"All categories","Danger","Treasure","Vendor","Profession","Resource","Travel","Note"}
    frame.category=Button(frame.side,"All categories",246,26);frame.category:SetPoint("TOPLEFT",frame.side,"TOPLEFT",16,-43)
    frame.category:SetScript("OnClick",function()frame.categoryIndex=frame.categoryIndex+1;if frame.categoryIndex>table.getn(frame.categoryValues)then frame.categoryIndex=1 end;frame.category:SetText(frame.categoryValues[frame.categoryIndex]);HCM:RefreshManager()end)
    frame.scopeIndex=1;frame.scopeValues={"All pins","My pins","Peer pins","Guild pins"}
    frame.scope=Button(frame.side,"All pins",246,26);frame.scope:SetPoint("TOPLEFT",frame.side,"TOPLEFT",16,-73)
    frame.scope:SetScript("OnClick",function()frame.scopeIndex=frame.scopeIndex+1;if frame.scopeIndex>table.getn(frame.scopeValues)then frame.scopeIndex=1 end;frame.scope:SetText(frame.scopeValues[frame.scopeIndex]);HCM:RefreshManager()end)
    frame.rows = {}
    for i = 1, 6 do
        local row = CreateFrame("Button", nil, frame.side)
        row:SetWidth(246); row:SetHeight(37); row:SetPoint("TOPLEFT", frame.side, "TOPLEFT", 16, -108 - (i-1)*39)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        row.icon = row:CreateTexture(nil, "ARTWORK"); row.icon:SetWidth(30); row.icon:SetHeight(30); row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)
        row.label = Text(row, "", "GameFontHighlightSmall"); row.label:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 7, -2); row.label:SetWidth(200); row.label:SetJustifyH("LEFT")
        row.detail = Text(row, "", "GameFontDisableSmall"); row.detail:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 7, 2); row.detail:SetWidth(200); row.detail:SetJustifyH("LEFT")
        row:SetScript("OnEnter", function() if this.pin then HCM:ShowPinTooltip(this, this.pin) end end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        row:SetScript("OnClick", function()
            if not this.pin then return end
            if arg1 == "RightButton" and IsShiftKeyDown() then HCM:RequestDeletePin(this.pin.id)
            elseif arg1 == "LeftButton" then HCM:GoToPin(this.pin) end
        end)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        frame.rows[i] = row
    end
    frame.newPin=Button(frame.side,"+ New Pin",116,28);frame.newPin:SetPoint("BOTTOMLEFT",frame.side,"BOTTOMLEFT",16,78)
    frame.newPin:SetScript("OnClick",function()frame.addMode=not frame.addMode;if frame.addMode then frame.newPin:SetText("Click map...")else frame.newPin:SetText("+ New Pin")end end)
    frame.editPin=Button(frame.side,"Edit Pin",116,28);frame.editPin:SetPoint("LEFT",frame.newPin,"RIGHT",12,0)
    frame.editPin:SetScript("OnClick",function()HCM:Print("click and drag one of your pins to reposition it")end)
    frame.modeCards={}
    for i=1,4 do
        local card=CreateFrame("Button",nil,frame.side,"UIPanelButtonTemplate");card:SetWidth(58);card:SetHeight(56);card:SetPoint("BOTTOMLEFT",frame.side,"BOTTOMLEFT",16+(i-1)*61,14);card.mode=tabNames[i]
        card.icon=card:CreateTexture(nil,"ARTWORK");card.icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01");card.icon:SetWidth(28);card.icon:SetHeight(28);card.icon:SetPoint("TOP",card,"TOP",0,-4)
        card.label=Text(card,tabNames[i],"GameFontDisableSmall");card.label:SetPoint("BOTTOM",card,"BOTTOM",0,5)
        card:SetScript("OnClick",function()HCM:SetDashboardMode(this.mode)end);frame.modeCards[i]=card
    end
    frame.status = Text(frame.content, "", "GameFontHighlightSmall"); frame.status:SetPoint("BOTTOMLEFT", frame.content, "BOTTOMLEFT", 24, 10)
    frame.hint = Text(frame.content, "Left-click: zoom  Right-click: back  Drag pin: move", "GameFontDisableSmall"); frame.hint:SetPoint("BOTTOMRIGHT", frame.content, "BOTTOMRIGHT", -24, 10)
    frame.mode="Zone";frame.dungeonKey="TheDeadmines"
    frame.mapEvents=CreateFrame("Frame",nil,frame);frame.mapEvents:RegisterEvent("WORLD_MAP_UPDATE")
    frame.mapEvents:SetScript("OnEvent",function()if not HCM.ResolvingZone and frame:IsShown()and frame.mode~="Dungeon"then HCM:RefreshDashboardExploration()end end)
    frame:SetScript("OnHide",function()if SetMapToCurrentZone then SetMapToCurrentZone()end end)
    frame:Hide(); self.Manager = frame
    self:CreateMoveBar()
    return frame
end

function HCM:CreateMoveBar()
    if self.MoveBar or not self.Manager then return end
    local bar=CreateFrame("Frame",nil,UIParent);bar:SetWidth(300);bar:SetHeight(44);bar:SetPoint("BOTTOM",UIParent,"BOTTOM",0,82);bar:SetFrameStrata("TOOLTIP")
    bar:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=12,insets={left=3,right=3,top=3,bottom=3}});bar:SetBackdropColor(.02,.02,.02,.98)
    bar.label=Text(bar,"Pin moved","GameFontHighlightSmall");bar.label:SetPoint("LEFT",bar,"LEFT",12,0)
    bar.save=Button(bar,"Save",78,26);bar.save:SetPoint("RIGHT",bar,"RIGHT",-10,0)
    bar.undo=Button(bar,"Undo",78,26);bar.undo:SetPoint("RIGHT",bar.save,"LEFT",-7,0)
    bar.save:SetScript("OnClick",function()HCM:SavePendingMove()end);bar.undo:SetScript("OnClick",function()HCM:UndoPendingMove()end)
    bar:Hide();self.MoveBar=bar
end

function HCM:SetDashboardMode(mode)
    local frame=self:CreateManager();local continent,zone,zoneIndex=self:GetMapContext()
    if zoneIndex>0 then frame.lastContinent=continent;frame.lastZoneIndex=zoneIndex;frame.lastZone=zone end
    frame.mode=mode or"Zone";frame.addMode=nil;frame.newPin:SetText("+ New Pin")
    self:RefreshDashboardMap()
end

function HCM:DashboardMapClick(mouseButton)
    local frame=self.Manager;if not frame then return end
    local x,y=self:CursorPosition(frame.map)
    if frame.addMode then
        if mouseButton=="RightButton"then frame.addMode=nil;frame.newPin:SetText("+ New Pin");return end
        frame.addMode=nil;frame.newPin:SetText("+ New Pin")
        if not x or not y then return end
        if frame.mode=="Dungeon"then self:OpenPinEditor({continent=0,zone="",x=0,y=0,instance=frame.dungeonKey,ix=x,iy=y})
        elseif frame.mode=="Zone"then self:OpenPinEditor({continent=frame.contextContinent,zone=frame.contextZone,x=x,y=y,instance=""})
        else self:Print("zoom to Zone before creating an outdoor pin")end
        return
    end
    if frame.mode=="Dungeon"or not x or not y then return end
    if mouseButton=="RightButton"then
        local continent,zone,zoneIndex=self:GetMapContext()
        if zoneIndex>0 and continent>0 then if SetMapZoom then SetMapZoom(continent)end;frame.mode="Continent"
        elseif continent>0 then if SetMapZoom then SetMapZoom(0)end;frame.mode="World" end
    elseif ProcessMapClick then
        ProcessMapClick(x,y)
        local continent,zone,zoneIndex=self:GetMapContext()
        if zoneIndex>0 then frame.mode="Zone";frame.lastContinent=continent;frame.lastZoneIndex=zoneIndex;frame.lastZone=zone
        elseif continent>0 then frame.mode="Continent";frame.lastContinent=continent
        else frame.mode="World"end
    end
    self:RefreshDashboardMap(1)
end

function HCM:RefreshDashboardMap()
    local frame=self.Manager;if not frame then return end
    local mode=frame.mode or"Zone";local key;local continent,zone,zoneIndex=self:GetMapContext()
    if mode=="World"then
        if SetMapZoom then SetMapZoom(0)end;key="World";frame.contextContinent=0;frame.contextZone="";frame.breadcrumb:SetText("Azeroth")
    elseif mode=="Continent"then
        if continent<1 then continent=frame.lastContinent or 0 end
        if continent<1 and SetMapToCurrentZone then SetMapToCurrentZone();continent,zone,zoneIndex=self:GetMapContext()end
        if continent<1 then continent=2 end;frame.lastContinent=continent;if SetMapZoom then SetMapZoom(continent)end
        key=continent==1 and"Kalimdor"or"Azeroth";frame.contextContinent=continent;frame.contextZone="";frame.breadcrumb:SetText("Azeroth  >  "..(continent==1 and"Kalimdor"or"Eastern Kingdoms"))
    elseif mode=="Dungeon"then
        key=frame.dungeonKey or"TheDeadmines";frame.contextContinent=0;frame.contextZone="";frame.breadcrumb:SetText("Dungeon  >  "..self:DungeonName(key))
    else
        if zoneIndex<1 and frame.lastContinent and frame.lastZoneIndex and SetMapZoom then
            SetMapZoom(frame.lastContinent,frame.lastZoneIndex);continent,zone,zoneIndex=self:GetMapContext()
        elseif continent<1 or zoneIndex<1 or zone==""then
            if SetMapToCurrentZone then SetMapToCurrentZone();continent,zone,zoneIndex=self:GetMapContext()end
        end
        if zoneIndex>0 then frame.lastContinent=continent;frame.lastZoneIndex=zoneIndex;frame.lastZone=zone end
        key=(GetMapInfo and GetMapInfo())or zone;frame.contextContinent=continent;frame.contextZone=zone;frame.breadcrumb:SetText("Azeroth  >  "..(continent==1 and"Kalimdor"or"Eastern Kingdoms").."  >  "..(zone~=""and zone or"Current zone"))
    end
    local i
    if mode=="Dungeon"then
        for i=1,12 do frame.tiles[i]:Hide()end;frame.dungeonTexture:SetTexture("Interface\\AddOns\\HC-Mapper\\Media\\Maps\\"..key);frame.dungeonTexture:Show();frame.nextDungeon:Show()
    else
        frame.dungeonTexture:Hide();frame.nextDungeon:Hide()
        for i=1,12 do frame.tiles[i]:SetTexture("Interface\\WorldMap\\"..key.."\\"..key..i);frame.tiles[i]:Show()end
    end
    self:RefreshDashboardExploration()
    for i=1,4 do local selected=frame.tabs[i].mode==mode;frame.tabs[i]:SetText(selected and("[ "..frame.tabs[i].mode.." ]")or frame.tabs[i].mode)end
    self:RefreshDashboardPins()
    self:RefreshDashboardUnits()
end

function HCM:RefreshDashboardExploration()
    local frame=self.Manager;if not frame then return end
    local used=0;local i
    if frame.mode~="Dungeon"and GetNumMapOverlays and GetMapOverlayInfo then
        for i=1,GetNumMapOverlays()do
            local textureName,textureWidth,textureHeight,offsetX,offsetY=GetMapOverlayInfo(i)
            if textureName and textureName~=""and textureWidth and textureHeight then
                local wide=math.ceil(textureWidth/256);local tall=math.ceil(textureHeight/256);local row,col
                for row=1,tall do
                    local pixelHeight=row<tall and 256 or(textureHeight-math.floor((textureHeight-1)/256)*256)
                    local fileHeight=16;while fileHeight<pixelHeight do fileHeight=fileHeight*2 end
                    for col=1,wide do
                        local pixelWidth=col<wide and 256 or(textureWidth-math.floor((textureWidth-1)/256)*256)
                        local fileWidth=16;while fileWidth<pixelWidth do fileWidth=fileWidth*2 end
                        used=used+1
                        if not frame.overlays[used]then frame.overlays[used]=frame.map:CreateTexture(nil,"ARTWORK")end
                        local overlay=frame.overlays[used];overlay:ClearAllPoints()
                        overlay:SetWidth(pixelWidth/1002*frame.map:GetWidth());overlay:SetHeight(pixelHeight/668*frame.map:GetHeight())
                        overlay:SetTexCoord(0,pixelWidth/fileWidth,0,pixelHeight/fileHeight)
                        overlay:SetPoint("TOPLEFT",frame.map,"TOPLEFT",(offsetX+256*(col-1))/1002*frame.map:GetWidth(),-(offsetY+256*(row-1))/668*frame.map:GetHeight())
                        overlay:SetTexture(textureName..((row-1)*wide+col));overlay:Show()
                    end
                end
            end
        end
    end
    for i=used+1,table.getn(frame.overlays)do frame.overlays[i]:Hide()end
    frame.explorationCount=used
end

function HCM:RefreshDashboardPins()
    local frame=self.Manager;if not frame or not frame:IsShown()then return end
    local visible={};local i
    for i=1,table.getn(self.DB.pins)do
        local pin=self.DB.pins[i]
        if self:VisiblePin(pin)then
            if frame.mode=="Dungeon"and pin.instance==frame.dungeonKey then table.insert(visible,{pin=pin,x=pin.ix,y=pin.iy})
            elseif frame.mode~="Dungeon"and pin.instance==""then
                local x,y=self:ProjectPosition(pin.continent,pin.zone,pin.x,pin.y,frame.contextContinent,frame.contextZone)
                if x and y and x>=0 and x<=1 and y>=0 and y<=1 then table.insert(visible,{pin=pin,x=x,y=y})end
            end
        end
    end
    for i=1,120 do
        local button,data=frame.mapPins[i],visible[i]
        if data then
            local x,y=data.x,data.y
            if self.PendingMove and self.PendingMove.pin.id==data.pin.id then
                if frame.mode=="Dungeon"then x,y=self.PendingMove.ix,self.PendingMove.iy
                elseif frame.mode=="Zone"then x,y=self.PendingMove.x,self.PendingMove.y end
            end
            button.pin=data.pin;button.icon:SetTexture(self:PinTexture(data.pin))
            local color=self.CategoryColors[data.pin.category]or{1,1,1};button.ring:SetVertexColor(color[1],color[2],color[3])
            button:ClearAllPoints();button:SetPoint("CENTER",frame.map,"TOPLEFT",x*frame.map:GetWidth(),-y*frame.map:GetHeight());button:Show()
        else button.pin=nil;button:Hide()end
    end
end

function HCM:RefreshDashboardUnits()
    local frame=self.Manager;if not frame or not frame.unitMarkers then return end
    local units={"player"};local i
    if frame:IsShown()and frame.mode~="Dungeon"and GetPlayerMapPosition then
        local raidCount=GetNumRaidMembers and GetNumRaidMembers()or 0
        local partyCount=GetNumPartyMembers and GetNumPartyMembers()or 0
        if raidCount>0 then for i=1,raidCount do local unit="raid"..i;if not UnitIsUnit or not UnitIsUnit(unit,"player")then table.insert(units,unit)end end
        else for i=1,partyCount do table.insert(units,"party"..i)end end
    else units={}end
    for i=1,41 do
        local marker=frame.unitMarkers[i];local unit=units[i]
        if unit then
            local x,y=GetPlayerMapPosition(unit);x=tonumber(x);y=tonumber(y)
            if x and y and(x>0 or y>0)and x<=1 and y<=1 then marker.unit=unit;marker:ClearAllPoints();marker:SetPoint("CENTER",frame.map,"TOPLEFT",x*frame.map:GetWidth(),-y*frame.map:GetHeight());marker:Show()
            else marker.unit=nil;marker:Hide()end
        else marker.unit=nil;marker:Hide()end
    end
end

function HCM:PinDragMap(button)
    if button.mapKind=="dashboard"and self.Manager then
        if self.Manager.mode=="Dungeon"then return self.Manager.map,"dungeon"end
        if self.Manager.mode=="Zone"then return self.Manager.map,"zone"end
    elseif button.mapKind=="dungeon"and self.DungeonFrame then return self.DungeonFrame.map,"dungeon"
    elseif button.mapKind=="world"then
        local continent,zone,zoneIndex=self:GetMapContext()
        if zoneIndex>0 and button.pin and button.pin.continent==continent and button.pin.zone==zone then return WorldMapButton,"zone"end
    end
    return nil
end

function HCM:BeginPinDrag(button)
    local pin=button and button.pin;if not pin then return end
    if self:NormalizeName(pin.owner)~=self:NormalizeName(self:PlayerName())then self:Print("only your own pins can be moved");return end
    local map,kind=self:PinDragMap(button);if not map then self:Print("open the pin's Zone or Dungeon map to move it");return end
    if self.PendingMove and self.PendingMove.pin.id~=pin.id then self:UndoPendingMove()end
    self.PendingMove={pin=pin,map=map,kind=kind,x=pin.x,y=pin.y,ix=pin.ix,iy=pin.iy}
    button.dragging=1;button.wasDragged=1;button.dragMap=map;button.dragKind=kind
    if self.MoveBar then self.MoveBar.label:SetText("Moving "..pin.title);self.MoveBar:Show()end
end

function HCM:UpdatePinDrag(button)
    if not button.dragging or not self.PendingMove then return end
    local x,y=self:CursorPosition(button.dragMap);if not x or not y then return end
    if button.dragKind=="dungeon"then self.PendingMove.ix,self.PendingMove.iy=x,y else self.PendingMove.x,self.PendingMove.y=x,y end
    button:ClearAllPoints();button:SetPoint("CENTER",button.dragMap,"TOPLEFT",x*button.dragMap:GetWidth(),-y*button.dragMap:GetHeight())
end

function HCM:EndPinDrag(button)
    if button then button.dragging=nil end
    if self.PendingMove and self.MoveBar then self.MoveBar.label:SetText("Save new position?");self.MoveBar:Show()end
end

function HCM:SavePendingMove()
    local move=self.PendingMove;if not move then return end
    self.PendingMove=nil;if self.MoveBar then self.MoveBar:Hide()end
    if move.kind=="dungeon"then self:CommitPinMove(move.pin.id,{ix=move.ix,iy=move.iy})else self:CommitPinMove(move.pin.id,{x=move.x,y=move.y})end
end

function HCM:UndoPendingMove()
    self.PendingMove=nil;if self.MoveBar then self.MoveBar:Hide()end;self:RefreshAll();self:RefreshDashboardPins()
end

function HCM:RefreshManager()
    if not self.Manager then return end
    local frame=self.Manager
    frame.status:SetText(self:NetworkStatus() .. "  -  " .. table.getn(self.DB.pins) .. " pins stored locally")
    local visible = {}; local i
    local query=string.lower(self:Trim(frame.search:GetText(),40));query=string.gsub(query,"(%W)","%%%1")
    local category=frame.categoryValues[frame.categoryIndex];local scope=frame.scopeValues[frame.scopeIndex]
    for i = table.getn(self.DB.pins), 1, -1 do
        local pin=self.DB.pins[i];local mine=self:NormalizeName(pin.owner)==self:NormalizeName(self:PlayerName())
        local categoryOK=category=="All categories"or pin.category==category
        local scopeOK=scope=="All pins"or(scope=="My pins"and mine)or(scope=="Guild pins"and not mine and pin.scope=="Guild")or(scope=="Peer pins"and not mine and pin.scope~="Guild")
        local haystack=string.lower((pin.title or"").." "..(pin.note or"").." "..(pin.owner or"").." "..(pin.zone or"").." "..(pin.instance or""))
        if self:VisiblePin(pin)and categoryOK and scopeOK and(query==""or string.find(haystack,query))then table.insert(visible,pin)end
    end
    for i = 1, 6 do
        local row, pin = frame.rows[i], visible[i]
        if pin then
            row.pin = pin; row.icon:SetTexture(self:PinTexture(pin))
            local place = pin.instance ~= "" and pin.instance or pin.zone
            local color=self.CategoryColors[pin.category]or{1,1,1};local hex=string.format("%02x%02x%02x",math.floor(color[1]*255),math.floor(color[2]*255),math.floor(color[3]*255))
            row.label:SetText("|cff"..hex..pin.title.."|r");row.detail:SetText(pin.category.." - "..pin.owner.." - "..place); row:Show()
        else row.pin = nil; row:Hide() end
    end
    self:RefreshDashboardPins()
end

function HCM:ToggleManager()
    local frame = self:CreateManager()
    if frame:IsShown() then frame:Hide()
    else
        if WorldMapFrame and WorldMapFrame:IsShown()and ToggleWorldMap then ToggleWorldMap()end
        frame:Show();self:RefreshDashboardMap();self:RefreshManager()
    end
end

function HCM:OpenDashboard(mode)
    if WorldMapFrame and WorldMapFrame:IsShown()and ToggleWorldMap then ToggleWorldMap()end
    local frame=self:CreateManager();frame:Show();self:SetDashboardMode(mode or frame.mode or"Zone");self:RefreshManager()
end

function HCM:FindZoneIndex(continent, zoneKey)
    self.ZoneIndexCache=self.ZoneIndexCache or{};local cacheKey=tostring(continent)..":"..tostring(zoneKey)
    if self.ZoneIndexCache[cacheKey]then return self.ZoneIndexCache[cacheKey]end
    if not GetMapZones or not SetMapZoom or not GetMapInfo then return nil end
    local zones={GetMapZones(continent)};local i;self.ResolvingZone=1
    for i=1,table.getn(zones)do
        SetMapZoom(continent,i)
        if GetMapInfo()==zoneKey then self.ZoneIndexCache[cacheKey]=i;self.ResolvingZone=nil;return i end
    end
    self.ResolvingZone=nil;return nil
end

function HCM:GoToPin(pin)
    if not pin then return end
    if pin.instance and pin.instance~=""then
        if WorldMapFrame and WorldMapFrame:IsShown()and ToggleWorldMap then ToggleWorldMap()end
        local frame=self:CreateManager();frame:Show()
        frame.dungeonKey=pin.instance;frame.mode="Dungeon";self:RefreshDashboardMap();self:RefreshManager();return
    end
    if self.OpenNativePin then self:OpenNativePin(pin);return end
    local frame=self:CreateManager();frame:Show()
    local zoneIndex=self:FindZoneIndex(pin.continent,pin.zone)
    frame.lastContinent=pin.continent;frame.lastZoneIndex=zoneIndex;frame.lastZone=pin.zone
    if zoneIndex and SetMapZoom then SetMapZoom(pin.continent,zoneIndex);frame.mode="Zone"
    else if SetMapZoom then SetMapZoom(pin.continent)end;frame.mode="Continent";self:Print("zone map not found; showing its continent")end
    self:RefreshDashboardMap();self:RefreshManager()
end

function HCM:CreateMinimapButton()
    local button = CreateFrame("Button", "HCMapperMinimapButton", Minimap)
    button:SetWidth(31); button:SetHeight(31)
    button:SetFrameStrata("MEDIUM"); button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local icon = button:CreateTexture(nil, "BACKGROUND"); icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01"); icon:SetWidth(20); icon:SetHeight(20); icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    local border = button:CreateTexture(nil, "OVERLAY"); border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder"); border:SetWidth(53); border:SetHeight(53); border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnClick", function() if arg1 == "RightButton" then HCM:ToggleNativePinManager() else HCM:ToggleNativeMap() end end)
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
    button:SetScript("OnEnter", function() GameTooltip:SetOwner(this,"ANCHOR_LEFT"); GameTooltip:AddLine("HC Mapper"); GameTooltip:AddLine("Left-click: standard World Map",1,1,1);GameTooltip:AddLine("Right-click: World Map with pin list",1,1,1); GameTooltip:Show() end)
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
    self:CreateEditor(); self:CreateMinimapButton()
end
