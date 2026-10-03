table.getn=table.getn or function(v)return #v end
string.gfind=string.gfind or string.gmatch
local Frame={};local methods={}
local function object(kind,parent)return setmetatable({kind=kind,parent=parent,scripts={},shown=true,width=100,height=100,text=""},Frame)end
function methods:SetScript(k,v)self.scripts[k]=v end
function methods:GetScript(k)return self.scripts[k]end
function methods:RegisterEvent()end;function methods:RegisterForClicks()end;function methods:RegisterForDrag()end
function methods:SetWidth(v)self.width=v end;function methods:SetHeight(v)self.height=v end;function methods:GetWidth()return self.width end;function methods:GetHeight()return self.height end
function methods:SetPoint()end;function methods:SetAllPoints()end;function methods:ClearAllPoints()end;function methods:SetFrameStrata()end;function methods:SetFrameLevel(v)self.level=v end;function methods:GetFrameLevel()return self.level or 1 end
function methods:SetBackdrop()end;function methods:SetBackdropColor()end;function methods:SetTexture(v)self.texture=v end;function methods:SetVertexColor()end;function methods:SetBlendMode()end
function methods:SetText(v)self.text=v or"" end;function methods:GetText()return self.text end;function methods:SetFontObject()end;function methods:SetTextInsets()end;function methods:SetAutoFocus()end;function methods:SetMultiLine()end;function methods:SetFocus()end;function methods:ClearFocus()end
function methods:SetJustifyH()end;function methods:SetOwner()end;function methods:AddLine()end;function methods:EnableMouse()end;function methods:SetMovable()end;function methods:SetHighlightTexture()end
function methods:CreateTexture()return object("Texture",self)end;function methods:CreateFontString()return object("FontString",self)end
function methods:Show()self.shown=true end;function methods:Hide()self.shown=false end;function methods:IsShown()return self.shown end
function methods:GetLeft()return 100 end;function methods:GetTop()return 700 end;function methods:GetEffectiveScale()return 1 end;function methods:GetID()return 1 end
function methods:GetCenter()return 500,500 end
function methods:AddMessage()end;function methods:StartMoving()self.moving=true end;function methods:StopMovingOrSizing()self.moving=false end
Frame.__index=function(self,key)if methods[key]then return methods[key]end;if string.find(key,"^[A-Z]")then return function()end end end
function CreateFrame(kind,name,parent)local f=object(kind,parent);if name then _G[name]=f end;return f end
UIParent=CreateFrame("Frame","UIParent");Minimap=CreateFrame("Frame","Minimap",UIParent);GameTooltip=CreateFrame("Frame","GameTooltip",UIParent)
WorldMapFrame=CreateFrame("Frame","WorldMapFrame",UIParent);WorldMapFrame:SetWidth(1000);WorldMapFrame:SetHeight(700)
WorldMapButton=CreateFrame("Button","WorldMapButton",WorldMapFrame);WorldMapButton:SetWidth(800);WorldMapButton:SetHeight(600)
DEFAULT_CHAT_FRAME=CreateFrame("Frame","ChatFrame1",UIParent);ChatFontNormal={};SlashCmdList={}
function GetTime()return 1000 end;function time()return 2000001000 end;function UnitName()return"Tester"end;function GetGuildInfo()return"Guild"end
function GetCurrentMapContinent()return 2 end;function GetCurrentMapZone()return 1 end;function GetMapInfo()return"Elwynn"end
function GetCursorPosition()return 500,400 end;function GetChannelName()return 7 end;function JoinChannelByName()end;function getglobal()return nil end
function SendChatMessage()end;function SendAddonMessage()end;function RegisterAddonMessagePrefix()end;function IsShiftKeyDown()return nil end;function ToggleWorldMap()WorldMapFrame:Show()end

dofile("HC-Mapper/Core.lua");assert(HCMapper.ShowPinTooltip,"pin tooltip must be available from Core");dofile("HC-Mapper/MapData.lua");dofile("HC-Mapper/Network.lua");dofile("HC-Mapper/UI.lua");dofile("HC-Mapper/WorldMap.lua");dofile("HC-Mapper/Dungeon.lua")
local HCM=HCMapper;HCM:InitializeDB();HCM:InitializeNetwork();HCM:InitializeUI();HCM:InitializeWorldMap()
assert(HCM.Manager and HCM.Editor and HCM.MinimapButton,"main UI did not initialize")
assert(HCM.WorldAdd and table.getn(HCM.WorldPins)==120,"World Map controls did not initialize")
HCM:OpenPinEditor({continent=2,zone="Elwynn",x=.4,y=.5,instance=""});HCM.Editor.name:SetText("Road patrol")
this=HCM.Editor.save;HCM.Editor.save.scripts.OnClick();assert(table.getn(HCM.DB.pins)==1,"editor did not save outdoor pin")
HCM:RefreshWorldPins();assert(HCM.WorldPins[1].pin and HCM.WorldPins[1].pin.title=="Road patrol","outdoor pin was not drawn")
HCM:OpenDungeonBrowser("TheDeadmines");assert(HCM.DungeonFrame and HCM.DungeonFrame.map.texture.texture=="Interface\\AddOns\\HC-Mapper\\Media\\Maps\\TheDeadmines","dungeon texture was not selected")
HCM:OpenPinEditor({continent=0,zone="",x=0,y=0,instance="TheDeadmines",ix=.3,iy=.4});HCM.Editor.name:SetText("Boss corner");this=HCM.Editor.save;HCM.Editor.save.scripts.OnClick()
HCM:RefreshDungeonPins();assert(HCM.DungeonFrame.pins[1].pin and HCM.DungeonFrame.pins[1].pin.instance=="TheDeadmines","dungeon pin was not drawn")
HCM:RefreshManager();assert(HCM.Manager.rows[1].pin,"manager did not list pins")
HCM.Manager:Show();HCM:SetDashboardMode("Zone");HCM:RefreshManager()
assert(HCM.Manager.mode=="Zone" and HCM.Manager.mapPins[1].pin,"dashboard zone tab did not render pins")
this=HCM.Manager.mapPins[1];HCM.Manager.mapPins[1].scripts.OnEnter();HCM.Manager.mapPins[1].scripts.OnLeave()
this=HCM.Manager.titlebar;HCM.Manager.titlebar.scripts.OnDragStart();assert(HCM.Manager.moving,"titlebar did not start window drag");HCM.Manager.titlebar.scripts.OnDragStop();assert(not HCM.Manager.moving,"titlebar did not stop window drag")
this=HCM.Manager.minimize;HCM.Manager.minimize.scripts.OnClick();assert(HCM.Manager.minimized and not HCM.Manager.content:IsShown(),"minimize button did not collapse dashboard");HCM.Manager.minimize.scripts.OnClick();assert(not HCM.Manager.minimized and HCM.Manager.content:IsShown(),"minimize button did not restore dashboard")
local outdoor=HCM:GetPin(HCM.Manager.mapPins[1].pin.id);local oldX,oldY,oldRevision=outdoor.x,outdoor.y,outdoor.revision;local drag=HCM.Manager.mapPins[1]
this=drag;drag.scripts.OnDragStart();drag.scripts.OnUpdate();drag.scripts.OnDragStop();assert(HCM.PendingMove and outdoor.x==oldX and outdoor.y==oldY,"drag changed saved coordinates before Save")
this=HCM.MoveBar.undo;HCM.MoveBar.undo.scripts.OnClick();assert(not HCM.PendingMove and outdoor.x==oldX and outdoor.y==oldY,"Undo did not restore pin")
this=drag;drag.scripts.OnDragStart();drag.scripts.OnUpdate();drag.scripts.OnDragStop();this=HCM.MoveBar.save;HCM.MoveBar.save.scripts.OnClick();assert(not HCM.PendingMove and outdoor.revision==oldRevision+1 and(outdoor.x~=oldX or outdoor.y~=oldY),"Save did not commit dragged pin")
print("HC Mapper UI smoke test passed")
