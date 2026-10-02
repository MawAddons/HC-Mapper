table.getn = table.getn or function(value) return #value end
string.gfind = string.gfind or string.gmatch
local now = 1000
local frames = {}
local Frame = {}
Frame.__index = function(self,key)
    local methods = {
        RegisterEvent=function()end, SetScript=function(object,eventName,callback)object.scripts[eventName]=callback end,
        AddMessage=function()end, GetID=function()return 1 end,
    }
    if methods[key] then return methods[key] end
    if string.find(key,"^[A-Z]") then return function()end end
end
function CreateFrame() local frame=setmetatable({scripts={}},Frame);table.insert(frames,frame);return frame end
function GetTime() return now end
function time() return 2000000000+now end
function UnitName() return "Tester" end
function GetGuildInfo() return "Test Guild" end
function GetChannelName() return 7 end
function JoinChannelByName() end
function getglobal() return nil end
function SendChatMessage() end
function SendAddonMessage() end
function RegisterAddonMessagePrefix() end
function GetCurrentMapContinent() return 2 end
function GetCurrentMapZone() return 1 end
function GetMapInfo() return "Elwynn" end
DEFAULT_CHAT_FRAME=setmetatable({scripts={}},Frame)
SlashCmdList={}

dofile("HC-Mapper/Core.lua")
dofile("HC-Mapper/MapData.lua")
dofile("HC-Mapper/Network.lua")
local HCM=HCMapper
HCM:InitializeDB();HCM:InitializeNetwork()
HCM.RefreshAll=function()end

local zx,zy=HCM:ProjectPosition(2,"Elwynn",.5,.5,2,"Elwynn")
assert(zx==.5 and zy==.5,"zone projection changed local coordinates")
local cx,cy=HCM:ProjectPosition(2,"Elwynn",.5,.5,2,"")
assert(cx>0 and cx<1 and cy>0 and cy<1,"continent projection is outside map")
local wx,wy=HCM:ProjectPosition(2,"Elwynn",.5,.5,0,"")
assert(wx>0 and wx<1 and wy>0 and wy<1,"world projection is outside map")
assert(not HCM:ProjectPosition(2,"Elwynn",.5,.5,1,""),"pin projected onto wrong continent")
local continent,data,zone
for continent,data in pairs(HCM.MapSizes) do
    if continent>0 then for zone in pairs(data.zones) do
        local tx,ty=HCM:ProjectPosition(continent,zone,.5,.5,continent,"")
        local twx,twy=HCM:ProjectPosition(continent,zone,.5,.5,0,"")
        assert(tx and tx>=0 and tx<=1 and ty>=0 and ty<=1,"zone center misses continent: "..zone)
        assert(twx and twx>=0 and twx<=1 and twy>=0 and twy<=1,"zone center misses world: "..zone)
    end end
end

local mine=HCM:CreatePin({title="Elite patrol",note="Road after dusk",scope="Peers",category="Danger",continent=2,zone="Elwynn",x=.5,y=.5,instance=""})
assert(mine and mine.owner=="Tester" and table.getn(HCM.DB.pins)==1,"local pin was not created")
assert(table.getn(HCM.Network.queue)==1,"shared pin was not queued")
local message=HCM:PinMessage(mine)
assert(message and string.len(message)<=240,"pin message exceeds Vanilla chat limit")
assert(not string.find(message,"|"),"pin message contains a raw chat escape character")

local private=HCM:CreatePin({title="Private note",scope="Private",category="Note",continent=1,zone="Durotar",x=.2,y=.3,instance=""})
assert(private and table.getn(HCM.Network.queue)==1,"private pin entered sync queue")
local dungeon=HCM:CreatePin({title="Boss safe spot",scope="Peers",category="Danger",continent=0,zone="",x=0,y=0,instance="TheDeadmines",ix=.3,iy=.7})
assert(dungeon and dungeon.instance=="TheDeadmines","dungeon pin was rejected")

local remote={id="peer-1",revision=1,owner="Svenne",scope="Peers",continent=2,zone="Westfall",x=.4,y=.6,instance="",ix=0,iy=0,category="Treasure",title="Chest",note="Behind house",updatedAt=HCM:Now()}
HCM:HandleNetwork(HCM:PinMessage(remote),"OtherPlayer","PEER")
assert(HCM:GetPin("peer-1"),"peer pin was not accepted")
remote.revision=2;remote.note="Moved";HCM:HandleNetwork(HCM:PinMessage(remote),"OtherPlayer","PEER")
assert(HCM:GetPin("peer-1").note=="Moved","newer peer revision did not replace pin")
HCM:ApplyDelete("peer-1",3,"Svenne")
assert(not HCM:GetPin("peer-1") and HCM.DB.tombstones["peer-1"].revision==3,"peer deletion was not applied")
remote.revision=2;HCM:HandleNetwork(HCM:PinMessage(remote),"OtherPlayer","PEER")
assert(not HCM:GetPin("peer-1"),"tombstone allowed stale pin resurrection")

assert(HCM:DeletePin(mine.id,1),"owner could not delete local pin")
local foreign={id="peer-2",revision=1,owner="Another",scope="Peers",continent=2,zone="Westfall",x=.2,y=.2,instance="",category="Note",title="Foreign",note="",updatedAt=HCM:Now()}
HCM:SavePin(foreign,nil)
assert(not HCM:DeletePin("peer-2",1),"a player could delete another author's pin")
print("HC Mapper smoke test passed")
