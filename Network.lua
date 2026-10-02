local HCM = HCMapper
HCM.SEND_DELAY = 5
HCM.MAX_SENDS_PER_MINUTE = 6
HCM.MAX_MESSAGE = 240

local function Split(value, delimiter)
    local result = {}
    local part
    for part in string.gfind((value or "") .. delimiter, "(.-)" .. delimiter) do table.insert(result, part) end
    return result
end
local function Escape(value)
    value = tostring(value or "")
    value = string.gsub(value, "%%", "%%25")
    value = string.gsub(value, "|", "%%7C")
    value = string.gsub(value, "~", "%%7E")
    return value
end
local function Unescape(value)
    value = tostring(value or "")
    value = string.gsub(value, "%%7E", "~")
    value = string.gsub(value, "%%7C", "|")
    value = string.gsub(value, "%%25", "%%")
    return value
end

function HCM:InitializeNetwork()
    self.Network = { queue = {}, sent = {}, seen = {}, receive = {}, state = "OFFLINE", nextQuery = GetTime() + 8 }
    if RegisterAddonMessagePrefix then RegisterAddonMessagePrefix("HCMapper") end
end

function HCM:HideChannel()
    local i
    for i = 1, 7 do
        local frame = getglobal("ChatFrame" .. i)
        if frame and ChatFrame_RemoveChannel then ChatFrame_RemoveChannel(frame, self.CHANNEL) end
    end
end

function HCM:JoinNetwork()
    if not self.DB or self.DB.settings.sync ~= 1 then return end
    local id = GetChannelName(self.CHANNEL)
    if id and id > 0 then self.Network.state = "ONLINE"; self:HideChannel(); return end
    self.Network.state = "JOINING"
    JoinChannelByName(self.CHANNEL, nil, DEFAULT_CHAT_FRAME:GetID())
end

function HCM:NetworkStatus()
    if not self.DB or self.DB.settings.sync ~= 1 then return "Sync: OFF" end
    local peers = 0
    local _, at
    for _, at in pairs(self.Network and self.Network.seen or {}) do if GetTime() - at < 300 then peers = peers + 1 end end
    return "Sync: " .. (self.Network and self.Network.state or "OFFLINE") .. " / " .. peers .. " recent peer(s)"
end

function HCM:QueueNetwork(message, mode, key, due)
    if type(message) ~= "string" or string.len(message) > self.MAX_MESSAGE then return nil end
    local i
    for i = table.getn(self.Network.queue), 1, -1 do if key and self.Network.queue[i].key == key then table.remove(self.Network.queue, i) end end
    if table.getn(self.Network.queue) >= 80 then table.remove(self.Network.queue, 1) end
    table.insert(self.Network.queue, { message = message, mode = mode or "PEER", key = key, due = due or GetTime() })
    return 1
end

function HCM:PinMessage(pin)
    local age = math.max(0, math.min(self.PEER_TTL, self:Now() - (pin.updatedAt or self:Now())))
    local fields = { self.PROTOCOL, "P", Escape(pin.id), tostring(pin.revision or 1), Escape(pin.owner), pin.scope,
        tostring(pin.continent or 0), Escape(pin.zone), tostring(pin.x or 0), tostring(pin.y or 0), Escape(pin.instance),
        tostring(pin.ix or 0), tostring(pin.iy or 0), Escape(pin.category), Escape(pin.title), Escape(pin.note), tostring(age) }
    local message = table.concat(fields, "~")
    while string.len(message) > self.MAX_MESSAGE and string.len(fields[16]) > 0 do
        fields[16] = string.sub(fields[16], 1, string.len(fields[16]) - 1)
        message = table.concat(fields, "~")
    end
    if string.len(message) > self.MAX_MESSAGE then return nil end
    return message
end

function HCM:SharePin(pin, delay)
    if self.DB.settings.sync ~= 1 or pin.scope == "Private" then return end
    local message = self:PinMessage(pin)
    if message then self:QueueNetwork(message, pin.scope == "Guild" and "GUILD" or "PEER", "pin:" .. pin.id, GetTime() + (delay or 0)) end
end

function HCM:ShareDelete(id, revision, owner, scope)
    local message = table.concat({ self.PROTOCOL, "D", Escape(id), tostring(revision), Escape(owner) }, "~")
    self:QueueNetwork(message, scope == "Guild" and "GUILD" or "PEER", "delete:" .. id)
end

function HCM:RequestSync(silent)
    if self.DB.settings.sync ~= 1 then self:Print("sync is disabled"); return end
    local nonce = self:NewID()
    self:QueueNetwork(self.PROTOCOL .. "~Q~" .. Escape(nonce), "PEER", "query-peer")
    self:QueueNetwork(self.PROTOCOL .. "~Q~" .. Escape(nonce), "GUILD", "query-guild")
    if not silent then self:Print("peer refresh queued") end
end

function HCM:QueueSnapshot(mode)
    local delay = math.random(2, 10)
    local count = 0
    local i
    for i = table.getn(self.DB.pins), 1, -1 do
        local pin = self.DB.pins[i]
        local mine = self:NormalizeName(pin.owner) == self:NormalizeName(self:PlayerName())
        local eligible = mode == "GUILD" and pin.scope == "Guild" or mode == "PEER" and pin.scope == "Peers"
        if eligible and (mine or count < 10) then
            local message = self:PinMessage(pin)
            if message then self:QueueNetwork(message, mode, "snapshot:" .. mode .. ":" .. pin.id, GetTime() + delay); delay = delay + self.SEND_DELAY; count = count + 1 end
        end
        if count >= 20 then break end
    end
end

function HCM:AllowedSender(sender)
    sender = self:NormalizeName(sender)
    if sender == "" or sender == self:NormalizeName(self:PlayerName()) then return nil end
    local now = GetTime()
    local rate = self.Network.receive[sender]
    if not rate or now - rate.started > 10 then rate = { started = now, count = 0 }; self.Network.receive[sender] = rate end
    rate.count = rate.count + 1
    if rate.count > 15 then return nil end
    self.Network.seen[sender] = now
    return 1
end

function HCM:HandleNetwork(message, sender, mode)
    if type(message) ~= "string" or string.len(message) > self.MAX_MESSAGE or not self:AllowedSender(sender) then return end
    local fields = Split(message, "~")
    if fields[1] ~= self.PROTOCOL then return end
    if fields[2] == "Q" then self:QueueSnapshot(mode); return end
    if fields[2] == "D" then self:ApplyDelete(Unescape(fields[3]), tonumber(fields[4]), Unescape(fields[5])); return end
    if fields[2] ~= "P" or table.getn(fields) < 17 then return end
    local id = Unescape(fields[3])
    local revision = tonumber(fields[4])
    local tombstone = self.DB.tombstones[id]
    if tombstone and (tonumber(tombstone.revision) or 0) >= (revision or 0) then return end
    local pin = {
        id = id, revision = revision, owner = Unescape(fields[5]), scope = fields[6], continent = tonumber(fields[7]),
        zone = Unescape(fields[8]), x = tonumber(fields[9]), y = tonumber(fields[10]), instance = Unescape(fields[11]),
        ix = tonumber(fields[12]), iy = tonumber(fields[13]), category = Unescape(fields[14]), title = Unescape(fields[15]),
        note = Unescape(fields[16]), updatedAt = self:Now() - math.max(0, math.min(self.PEER_TTL, tonumber(fields[17]) or 0)),
    }
    if mode == "GUILD" then pin.scope = "Guild" elseif pin.scope ~= "Peers" then return end
    self:SavePin(pin, nil)
end

function HCM:CanSendNow()
    local now = GetTime()
    local i
    for i = table.getn(self.Network.sent), 1, -1 do if now - self.Network.sent[i] > 60 then table.remove(self.Network.sent, i) end end
    if table.getn(self.Network.sent) >= self.MAX_SENDS_PER_MINUTE then return nil end
    if self.Network.lastSend and now - self.Network.lastSend < self.SEND_DELAY then return nil end
    return 1
end

function HCM:NetworkUpdate()
    if not self.Network or not self.DB or self.DB.settings.sync ~= 1 then return end
    local now = GetTime()
    if now >= self.Network.nextQuery then self.Network.nextQuery = now + 600; self:RequestSync(1) end
    if table.getn(self.Network.queue) == 0 or not self:CanSendNow() then return end
    local entry = self.Network.queue[1]
    if entry.due > now then return end
    local sent
    if entry.mode == "GUILD" and SendAddonMessage and GetGuildInfo("player") then
        SendAddonMessage("HCMapper", entry.message, "GUILD")
        sent = 1
    else
        local channel = GetChannelName(self.CHANNEL)
        if channel and channel > 0 then SendChatMessage(entry.message, "CHANNEL", nil, channel); sent = 1
        elseif self.Network.state ~= "JOINING" then self:JoinNetwork() end
    end
    if sent then
        table.remove(self.Network.queue, 1)
        self.Network.lastSend = now
        table.insert(self.Network.sent, now)
        self.Network.state = "ONLINE"
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("CHAT_MSG_CHANNEL")
events:RegisterEvent("CHAT_MSG_ADDON")
events:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")
events:SetScript("OnEvent", function()
    if not HCM.DB or HCM.DB.settings.sync ~= 1 then return end
    if event == "CHAT_MSG_CHANNEL" then
        local channel = arg9 and arg9 ~= "" and arg9 or arg4
        if channel and string.upper(channel) == string.upper(HCM.CHANNEL) then HCM:HandleNetwork(arg1, arg2, "PEER") end
    elseif event == "CHAT_MSG_ADDON" and arg1 == "HCMapper" then HCM:HandleNetwork(arg2, arg4, "GUILD")
    elseif event == "CHAT_MSG_CHANNEL_NOTICE" then
        local channel = arg9 and arg9 ~= "" and arg9 or arg4
        if channel and string.upper(channel) == string.upper(HCM.CHANNEL) then
            if arg1 == "YOU_JOINED" then HCM.Network.state = "ONLINE"; HCM:HideChannel() elseif arg1 == "YOU_LEFT" then HCM.Network.state = "OFFLINE" end
        end
    end
end)
events:SetScript("OnUpdate", function() HCM:NetworkUpdate() end)
