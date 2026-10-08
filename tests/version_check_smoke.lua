local sent = {}
local printed = {}
local now = 10

UIParent = {}
NUM_CHAT_WINDOWS = 1
HCMapper = { VERSION = "0.5.4" }

DEFAULT_CHAT_FRAME = {
    GetID = function() return 1 end,
    AddMessage = function(_, message) table.insert(printed, message) end,
}

function CreateFrame()
    local frame = { scripts = {} }
    function frame:RegisterEvent() end
    function frame:SetScript(name, callback) self.scripts[name] = callback end
    return frame
end

function GetTime() return now end
function GetChannelName() return 8 end
function JoinChannelByName() end
function ChatFrame_RemoveChannel() end
function getglobal() return DEFAULT_CHAT_FRAME end
function UnitName() return "VersionTester" end
function SendChatMessage(message, kind, language, channel)
    table.insert(sent, { message = message, kind = kind, channel = channel })
end

dofile("HC-Mapper/MawVersion.lua")

local checker = MawAddonVersionCheck
assert(checker.addons["HC-Mapper"], "HC Mapper was not registered")
assert(checker.addons["HC-Mapper"].url == "https://github.com/MawAddons/HC-Mapper", "repository URL is wrong")
assert(checker:CompareVersions("0.5.10", "0.5.9") == 1, "numeric version comparison failed")
assert(checker:CompareVersions("v1.2", "1.2.0") == 0, "version normalization failed")

checker:HandleManifest("MAV1~H~HC-Mapper=0.5.5")
assert(table.getn(printed) == 1, "newer peer did not produce exactly one notice")
assert(string.find(printed[1], "HC Mapper|r: New version is available%. Please keep up to date%."), "notice text is wrong")
assert(string.find(printed[1], "https://github.com/MawAddons/HC%-Mapper"), "notice URL is missing")
checker:HandleManifest("MAV1~H~HC-Mapper=0.5.5")
assert(table.getn(printed) == 1, "same newer version warned more than once")

checker:HandleManifest("MAV1~H~HC-Mapper=0.5.3")
assert(checker.replyAt, "an older peer did not schedule a version response")
checker:HandleManifest("MAV1~H~HC-Mapper=0.5.5")
assert(not checker.replyAt, "a newer peer manifest did not cancel the redundant response")

checker.started = 1
checker.nextJoin = 0
checker:OnUpdate(1)
assert(table.getn(sent) == 1, "shared manifest was not sent")
assert(sent[1].kind == "CHANNEL" and sent[1].channel == 8, "manifest used the wrong transport")
assert(string.find(sent[1].message, "HC%-Mapper=0%.5%.4"), "manifest omitted the local version")
assert(string.len(sent[1].message) <= 240, "manifest exceeds the Vanilla chat limit")

print("HC Mapper version-check smoke test passed")
