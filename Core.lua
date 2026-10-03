HCMapper = {}

local HCM = HCMapper
HCM.VERSION = "0.2.2"
HCM.PROTOCOL = "HCM1"
HCM.CHANNEL = "HCMapper"
HCM.MAX_PINS = 500
HCM.PEER_TTL = 2592000
HCM.TOMBSTONE_TTL = 604800
HCM.counter = 0
HCM.Categories = { "Danger", "Treasure", "Vendor", "Profession", "Resource", "Travel", "Note" }
HCM.CategoryIcons = {
    Danger = "Interface\\Icons\\Ability_Creature_Cursed_02",
    Treasure = "Interface\\Icons\\INV_Misc_Bag_10_Black",
    Vendor = "Interface\\Icons\\INV_Misc_Bag_10",
    Profession = "Interface\\Icons\\Trade_BlackSmithing",
    Resource = "Interface\\Icons\\INV_Misc_Herb_07",
    Travel = "Interface\\Icons\\Spell_Arcane_TeleportStormWind",
    Note = "Interface\\Icons\\INV_Misc_Note_01",
}
HCM.CategoryColors = {
    Danger = { 1.00, 0.15, 0.10 }, Treasure = { 1.00, 0.82, 0.10 },
    Vendor = { 0.20, 1.00, 0.25 }, Profession = { 0.20, 0.65, 1.00 },
    Resource = { 0.45, 0.90, 0.35 }, Travel = { 0.75, 0.30, 1.00 }, Note = { 0.95, 0.85, 0.60 },
}

local function Trim(value, limit)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    value = string.gsub(value, "[|~\r\n]", " ")
    value = string.gsub(value, "%s+", " ")
    if limit and string.len(value) > limit then value = string.sub(value, 1, limit) end
    return value
end

function HCM:Trim(value, limit) return Trim(value, limit) end
function HCM:Now()
    if type(time) == "function" then local value = tonumber(time()); if value and value > 0 then return value end end
    return math.floor(GetTime())
end
function HCM:PlayerName() return UnitName("player") or "Unknown" end
function HCM:NormalizeName(value)
    value = string.lower(Trim(value, 64))
    local _, _, short = string.find(value, "^([^%-]+)")
    return short or value
end
function HCM:Print(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffa335eeHC Mapper:|r " .. tostring(message or "")) end
end
function HCM:IsCategory(value)
    local i
    for i = 1, table.getn(self.Categories) do if self.Categories[i] == value then return 1 end end
    return nil
end

-- Kept in Core so map pins always have a tooltip, even if a later UI module fails to load.
function HCM:ShowPinTooltip(anchor, pin)
    if not GameTooltip or not pin then return end
    GameTooltip:SetOwner(anchor, "ANCHOR_LEFT")
    GameTooltip:AddLine(pin.title or "Map Pin", 1, .82, .2)
    local color = self.CategoryColors[pin.category] or { 1, 1, 1 }
    GameTooltip:AddLine((pin.category or "Note") .. " - " .. (pin.scope or "Peers"), color[1], color[2], color[3])
    GameTooltip:AddLine("Shared by " .. (pin.owner or "Unknown"), .7, .7, .7)
    if pin.note and pin.note ~= "" then GameTooltip:AddLine(pin.note, 1, 1, 1, 1) end
    if self:NormalizeName(pin.owner) == self:NormalizeName(self:PlayerName()) then
        GameTooltip:AddLine("Drag to move - Shift-right-click to delete", .9, .35, .25)
    end
    GameTooltip:Show()
end

function HCM:InitializeDB()
    HCMapperDB = HCMapperDB or {}
    HCMapperDB.pins = HCMapperDB.pins or {}
    HCMapperDB.tombstones = HCMapperDB.tombstones or {}
    HCMapperDB.settings = HCMapperDB.settings or {}
    -- Peer replication is an always-on core function; visibility scopes still control what is shared.
    HCMapperDB.settings.sync = 1
    if HCMapperDB.settings.showPeer == nil then HCMapperDB.settings.showPeer = 1 end
    if HCMapperDB.settings.showGuild == nil then HCMapperDB.settings.showGuild = 1 end
    if HCMapperDB.settings.showMine == nil then HCMapperDB.settings.showMine = 1 end
    self.DB = HCMapperDB
    self:Prune()
end

function HCM:NewID()
    self.counter = self.counter + 1
    return self:NormalizeName(self:PlayerName()) .. "-" .. tostring(self:Now()) .. "-" .. tostring(self.counter)
end

function HCM:SanitizePin(pin)
    if type(pin) ~= "table" then return nil end
    pin.id = Trim(pin.id, 72)
    pin.owner = Trim(pin.owner, 64)
    pin.title = Trim(pin.title, 32)
    pin.note = Trim(pin.note, 70)
    pin.scope = pin.scope == "Guild" and "Guild" or (pin.scope == "Private" and "Private" or "Peers")
    pin.category = self:IsCategory(pin.category) and pin.category or "Note"
    pin.continent = tonumber(pin.continent) or 0
    pin.zone = Trim(pin.zone, 48)
    pin.x = tonumber(pin.x)
    pin.y = tonumber(pin.y)
    pin.instance = Trim(pin.instance, 48)
    pin.ix = tonumber(pin.ix)
    pin.iy = tonumber(pin.iy)
    pin.revision = math.floor(tonumber(pin.revision) or 1)
    pin.updatedAt = tonumber(pin.updatedAt) or self:Now()
    if pin.id == "" or pin.owner == "" or pin.title == "" then return nil end
    if pin.revision < 1 or pin.revision > 1000000 then return nil end
    if pin.instance ~= "" then
        if not pin.ix or not pin.iy or pin.ix < 0 or pin.ix > 1 or pin.iy < 0 or pin.iy > 1 then return nil end
    else
        if pin.continent < 1 or pin.continent > 2 or pin.zone == "" then return nil end
        if not pin.x or not pin.y or pin.x < 0 or pin.x > 1 or pin.y < 0 or pin.y > 1 then return nil end
    end
    return pin
end

function HCM:GetPin(id)
    local i
    for i = 1, table.getn(self.DB.pins) do if self.DB.pins[i].id == id then return self.DB.pins[i], i end end
    return nil
end

function HCM:SavePin(pin, broadcast)
    pin = self:SanitizePin(pin)
    if not pin then return nil end
    local old, index = self:GetPin(pin.id)
    if old and (tonumber(old.revision) or 0) >= pin.revision then return old end
    if index then self.DB.pins[index] = pin else table.insert(self.DB.pins, pin) end
    while table.getn(self.DB.pins) > self.MAX_PINS do table.remove(self.DB.pins, 1) end
    if broadcast and pin.scope ~= "Private" and self.SharePin then self:SharePin(pin) end
    self:RefreshAll()
    return pin
end

function HCM:CreatePin(data)
    data = data or {}
    data.id = self:NewID()
    data.owner = self:PlayerName()
    data.revision = 1
    data.updatedAt = self:Now()
    data.localPin = 1
    return self:SavePin(data, 1)
end

function HCM:CommitPinMove(id, position)
    local pin = self:GetPin(id)
    if not pin or self:NormalizeName(pin.owner) ~= self:NormalizeName(self:PlayerName()) then return nil end
    position = position or {}
    if pin.instance ~= "" then
        local x, y = tonumber(position.ix), tonumber(position.iy)
        if not x or not y or x < 0 or x > 1 or y < 0 or y > 1 then return nil end
        pin.ix, pin.iy = x, y
    else
        local x, y = tonumber(position.x), tonumber(position.y)
        if not x or not y or x < 0 or x > 1 or y < 0 or y > 1 then return nil end
        pin.x, pin.y = x, y
    end
    pin.revision = (tonumber(pin.revision) or 1) + 1
    pin.updatedAt = self:Now()
    if pin.scope ~= "Private" and self.SharePin then self:SharePin(pin) end
    self:RefreshAll()
    return pin
end

function HCM:DeletePin(id, broadcast)
    local pin, index = self:GetPin(id)
    if not pin or self:NormalizeName(pin.owner) ~= self:NormalizeName(self:PlayerName()) then return nil end
    table.remove(self.DB.pins, index)
    local revision = (tonumber(pin.revision) or 1) + 1
    self.DB.tombstones[id] = { revision = revision, owner = pin.owner, at = self:Now(), scope = pin.scope }
    if broadcast and pin.scope ~= "Private" and self.ShareDelete then self:ShareDelete(id, revision, pin.owner, pin.scope) end
    self:RefreshAll()
    return 1
end

function HCM:RequestDeletePin(id)
    local pin = self:GetPin(id)
    if not pin then return nil end
    if self:NormalizeName(pin.owner) ~= self:NormalizeName(self:PlayerName()) then
        self:Print("only " .. pin.owner .. " can delete this shared pin")
        return nil
    end
    self.PendingDeleteID = id
    if StaticPopup_Show then StaticPopup_Show("HC_MAPPER_CONFIRM_DELETE", pin.title or "this pin") end
    return 1
end

function HCM:ConfirmDeletePin()
    local id = self.PendingDeleteID
    self.PendingDeleteID = nil
    if not id then return nil end
    return self:DeletePin(id, 1)
end

function HCM:ApplyDelete(id, revision, owner, scope)
    id, owner, revision = Trim(id, 72), Trim(owner, 64), tonumber(revision)
    if id == "" or owner == "" or not revision then return nil end
    local pin, index = self:GetPin(id)
    if pin and self:NormalizeName(pin.owner) ~= self:NormalizeName(owner) then return nil end
    if pin and self:NormalizeName(pin.owner) == self:NormalizeName(owner) and revision > (tonumber(pin.revision) or 0) then table.remove(self.DB.pins, index) end
    local old = self.DB.tombstones[id]
    if not old or revision > (tonumber(old.revision) or 0) then self.DB.tombstones[id] = { revision = revision, owner = owner, at = self:Now(), scope = scope or (old and old.scope) or "Peers" } end
    self:RefreshAll()
    return 1
end

StaticPopupDialogs = StaticPopupDialogs or {}
StaticPopupDialogs["HC_MAPPER_CONFIRM_DELETE"] = {
    text = "Delete map pin '%s'?\nThis removes it from every synced local database.",
    button1 = YES or "Yes", button2 = NO or "No", timeout = 0, whileDead = 1, hideOnEscape = 1,
    OnAccept = function() HCM:ConfirmDeletePin() end,
    OnCancel = function() HCM.PendingDeleteID = nil end,
}

function HCM:VisiblePin(pin)
    local mine = self:NormalizeName(pin.owner) == self:NormalizeName(self:PlayerName())
    if mine then return self.DB.settings.showMine == 1 end
    if pin.scope == "Guild" then return self.DB.settings.showGuild == 1 end
    return self.DB.settings.showPeer == 1
end

function HCM:Prune()
    local now = self:Now()
    local i
    for i = table.getn(self.DB.pins), 1, -1 do
        local pin = self.DB.pins[i]
        local mine = self:NormalizeName(pin.owner) == self:NormalizeName(self:PlayerName())
        if not mine and now - (tonumber(pin.updatedAt) or 0) > self.PEER_TTL then table.remove(self.DB.pins, i) end
    end
    local id, tombstone
    for id, tombstone in pairs(self.DB.tombstones) do if now - (tonumber(tombstone.at) or 0) > self.TOMBSTONE_TTL then self.DB.tombstones[id] = nil end end
end

function HCM:RefreshAll()
    if self.RefreshWorldPins then self:RefreshWorldPins() end
    if self.RefreshDungeonPins then self:RefreshDungeonPins() end
    if self.RefreshManager then self:RefreshManager() end
end

function HCM:OnLogin()
    self:InitializeDB()
    if self.InitializeNetwork then self:InitializeNetwork() end
    if self.InitializeUI then self:InitializeUI() end
    if self.InitializeWorldMap then self:InitializeWorldMap() end
    if self.DB.settings.sync == 1 and self.JoinNetwork then self:JoinNetwork() end
    self:Print("v" .. self.VERSION .. " loaded. Right-click Add Pin on the World Map or type /hcm.")
end

SLASH_HCMAPPER1 = "/hcm"
SLASH_HCMAPPER2 = "/hcmapper"
SlashCmdList.HCMAPPER = function(message)
    message = string.lower(Trim(message, 30))
    if message == "map" and ToggleWorldMap then ToggleWorldMap()
    elseif message == "dungeon" and HCM.OpenDashboard then HCM:OpenDashboard("Dungeon")
    elseif message == "reset" then HCMapperDB.window = nil; HCMapperDB.dungeonWindow = nil; HCM:Print("window positions reset")
    elseif HCM.ToggleManager then HCM:ToggleManager() end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function() if event == "PLAYER_LOGIN" then HCM:OnLogin() end end)
