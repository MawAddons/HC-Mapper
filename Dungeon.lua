local HCM = HCMapper

HCM.DungeonMaps = {
 {"RagefireChasm","Ragefire Chasm"},{"WailingCaverns","Wailing Caverns"},{"WailingCavernsEnt","Wailing Caverns Entrance"},
 {"TheDeadmines","The Deadmines"},{"TheDeadminesEnt","The Deadmines Entrance"},{"ShadowfangKeep","Shadowfang Keep"},
 {"BlackfathomDeeps","Blackfathom Deeps"},{"BlackfathomDeepsEnt","Blackfathom Deeps Entrance"},{"TheStockade","The Stockade"},
 {"Gnomeregan","Gnomeregan"},{"GnomereganEnt","Gnomeregan Entrance"},{"RazorfenKraul","Razorfen Kraul"},
 {"ScarletMonasteryGraveyard","Scarlet Monastery: Graveyard"},{"ScarletMonasteryLibrary","Scarlet Monastery: Library"},
 {"ScarletMonasteryArmory","Scarlet Monastery: Armory"},{"ScarletMonasteryCathedral","Scarlet Monastery: Cathedral"},
 {"ScarletMonasteryEnt","Scarlet Monastery Entrance"},{"RazorfenDowns","Razorfen Downs"},{"Uldaman","Uldaman"},
 {"UldamanEnt","Uldaman Entrance"},{"ZulFarrak","Zul'Farrak"},{"Maraudon","Maraudon"},{"MaraudonEnt","Maraudon Entrance"},
 {"TheSunkenTemple","The Sunken Temple"},{"TheSunkenTempleEnt","The Sunken Temple Entrance"},{"BlackrockDepths","Blackrock Depths"},
 {"BlackrockMountainEnt","Blackrock Mountain Entrance"},{"BlackrockSpireLower","Lower Blackrock Spire"},
 {"BlackrockSpireUpper","Upper Blackrock Spire"},{"DireMaulEast","Dire Maul East"},{"DireMaulWest","Dire Maul West"},
 {"DireMaulNorth","Dire Maul North"},{"DireMaulEnt","Dire Maul Entrance"},{"Scholomance","Scholomance"},{"Stratholme","Stratholme"},
 {"MoltenCore","Molten Core"},{"OnyxiasLair","Onyxia's Lair"},{"BlackwingLair","Blackwing Lair"},{"ZulGurub","Zul'Gurub"},
 {"TheRuinsofAhnQiraj","Ruins of Ahn'Qiraj"},{"TheTempleofAhnQiraj","Temple of Ahn'Qiraj"},{"Naxxramas","Naxxramas"},
}

local function Text(parent,value,font)local t=parent:CreateFontString(nil,"OVERLAY",font or"GameFontNormal");t:SetText(value or"");return t end
local function Button(parent,value,width)local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate");b:SetWidth(width);b:SetHeight(24);b:SetText(value);return b end

function HCM:DungeonName(key)
    local i
    for i=1,table.getn(self.DungeonMaps)do if self.DungeonMaps[i][1]==key then return self.DungeonMaps[i][2] end end
    return key
end

function HCM:CreateDungeonBrowser()
    if self.DungeonFrame then return self.DungeonFrame end
    local frame=CreateFrame("Frame","HCMapperDungeonFrame",UIParent)
    frame:SetWidth(850);frame:SetHeight(620);frame:SetPoint("CENTER",UIParent,"CENTER",0,15);frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true);frame:EnableMouse(true);frame:RegisterForDrag("LeftButton");frame:SetScript("OnDragStart",function()this:StartMoving()end);frame:SetScript("OnDragStop",function()this:StopMovingOrSizing()end)
    frame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=24,insets={left=6,right=6,top=6,bottom=6}});frame:SetBackdropColor(.025,.02,.01,.99)
    frame.title=Text(frame,"HC Mapper - Dungeon Maps","GameFontNormalLarge");frame.title:SetPoint("TOP",frame,"TOP",0,-17)
    frame.close=Button(frame,"X",26);frame.close:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-12,-10);frame.close:SetScript("OnClick",function()frame:Hide()end)
    frame.map=CreateFrame("Button",nil,frame);frame.map:SetWidth(520);frame.map:SetHeight(520);frame.map:SetPoint("TOPLEFT",frame,"TOPLEFT",24,-60);frame.map:RegisterForClicks("LeftButtonUp")
    frame.map:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
    frame.map.texture=frame.map:CreateTexture(nil,"BACKGROUND");frame.map.texture:SetPoint("TOPLEFT",frame.map,"TOPLEFT",4,-4);frame.map.texture:SetPoint("BOTTOMRIGHT",frame.map,"BOTTOMRIGHT",-4,4)
    frame.map:SetScript("OnClick",function()
        if not frame.addMode then return end
        local x,y=HCM:CursorPosition(frame.map);frame.addMode=nil;frame.add:SetText("Add Pin")
        if x and y then HCM:OpenPinEditor({continent=0,zone="",x=0,y=0,instance=frame.selected,ix=x,iy=y})end
    end)
    frame.caption=Text(frame,"","GameFontHighlight");frame.caption:SetPoint("BOTTOMLEFT",frame.map,"TOPLEFT",4,7)
    frame.add=Button(frame,"Add Pin",120);frame.add:SetPoint("TOPLEFT",frame,"TOPLEFT",574,-61)
    frame.add:SetScript("OnClick",function()
        if frame.addMode then frame.addMode=nil;frame.add:SetText("Add Pin")else frame.addMode=1;frame.add:SetText("Click map...");HCM:Print("click a position on the dungeon map")end
    end)
    frame.manager=Button(frame,"Pin Manager",120);frame.manager:SetPoint("LEFT",frame.add,"RIGHT",10,0);frame.manager:SetScript("OnClick",function()HCM:ToggleManager()end)
    frame.listTitle=Text(frame,"All Vanilla maps","GameFontNormal");frame.listTitle:SetPoint("TOPLEFT",frame,"TOPLEFT",574,-103)
    frame.rows={};local i
    for i=1,12 do
        local row=Button(frame,"",250);row:SetPoint("TOPLEFT",frame,"TOPLEFT",574,-123-(i-1)*31);row:SetScript("OnClick",function()if this.mapKey then HCM:SelectDungeon(this.mapKey)end end);frame.rows[i]=row
    end
    frame.previous=Button(frame,"<",36);frame.previous:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",574,27);frame.previous:SetScript("OnClick",function()frame.page=math.max(1,(frame.page or 1)-1);HCM:RefreshDungeonList()end)
    frame.pageLabel=Text(frame,"","GameFontHighlightSmall");frame.pageLabel:SetPoint("LEFT",frame.previous,"RIGHT",12,0)
    frame.next=Button(frame,">",36);frame.next:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-25,27);frame.next:SetScript("OnClick",function()frame.page=math.min(4,(frame.page or 1)+1);HCM:RefreshDungeonList()end)
    frame.pins={};for i=1,80 do frame.pins[i]=self:CreateMapPin(frame.map);frame.pins[i]:SetFrameLevel(frame.map:GetFrameLevel()+4);frame.pins[i]:Hide()end
    frame.page=1;frame.selected="TheDeadmines";frame:Hide();self.DungeonFrame=frame
    return frame
end

function HCM:RefreshDungeonList()
    local frame=self.DungeonFrame;if not frame then return end
    local start=(frame.page-1)*12;local i
    for i=1,12 do
        local data=self.DungeonMaps[start+i];local row=frame.rows[i]
        if data then row.mapKey=data[1];row:SetText((data[1]==frame.selected and "> "or"")..data[2]);row:Show()else row.mapKey=nil;row:Hide()end
    end
    frame.pageLabel:SetText("Page "..frame.page.." / 4")
end

function HCM:SelectDungeon(key)
    local frame=self:CreateDungeonBrowser();frame.selected=key;frame.map.texture:SetTexture("Interface\\AddOns\\HC-Mapper\\Media\\Maps\\"..key)
    frame.caption:SetText(self:DungeonName(key));frame.addMode=nil;frame.add:SetText("Add Pin");self:RefreshDungeonList();self:RefreshDungeonPins()
end

function HCM:RefreshDungeonPins()
    local frame=self.DungeonFrame;if not frame or not frame:IsShown()then return end
    local visible={};local i
    for i=1,table.getn(self.DB.pins)do local pin=self.DB.pins[i];if pin.instance==frame.selected and self:VisiblePin(pin)then table.insert(visible,pin)end end
    for i=1,80 do local button,pin=frame.pins[i],visible[i];if pin then button.pin=pin;button.icon:SetTexture(self.CategoryIcons[pin.category]or self.CategoryIcons.Note);local c=self.CategoryColors[pin.category]or{1,1,1};button.ring:SetVertexColor(c[1],c[2],c[3]);button:ClearAllPoints();button:SetPoint("CENTER",frame.map,"TOPLEFT",pin.ix*frame.map:GetWidth(),-pin.iy*frame.map:GetHeight());button:Show()else button.pin=nil;button:Hide()end end
    frame.caption:SetText(self:DungeonName(frame.selected).." - "..table.getn(visible).." pin(s)")
end

function HCM:OpenDungeonBrowser(key)
    local frame=self:CreateDungeonBrowser();frame:Show();self:SelectDungeon(key or frame.selected or"TheDeadmines")
end
