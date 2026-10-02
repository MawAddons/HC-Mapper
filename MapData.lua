-- Zone sizes and offsets are derived from Astrolabe 0.2 by James Carrothers.
-- Astrolabe is LGPL-2.1-or-later; see ATTRIBUTION.md.
local HCM = HCMapper

HCM.MapSizes = {
    [0] = { width = 44531.82907938571, height = 29687.90575403711 },
    [1] = { width = 36799.810546875, height = 24533.2001953125, xOffset = -8310, yOffset = 1815, zones = {
        Ashenvale={5766.6664,3843.7499,15366.5997,8126.9839}, Aszhara={5070.8328,3381.2499,20343.6829,7458.2339},
        Barrens={10133.3330,6756.2499,14443.6831,11187.4005}, Darkshore={6549.9998,4366.6665,14124.9331,4466.5674},
        Darnassis={1058.3333,705.7295,14128.2368,2561.5840}, Desolace={4495.8330,2997.9166,12833.2666,12347.8171},
        Durotar={5287.4996,3524.9999,19029.0995,10991.5671}, Dustwallow={5250.0001,3499.9998,18041.5995,14833.2336},
        Felwood={5749.9996,3833.3333,15424.9330,5666.5674}, Feralas={6949.9998,4633.3330,11624.9331,15166.5669},
        Moonglade={2308.3333,1539.5830,18447.8496,4308.2344}, Mulgore={5137.4999,3424.9998,15018.6830,13072.8170},
        Ogrimmar={1402.6045,935.4166,20747.2007,10526.0232}, Silithus={3483.3340,2322.9160,14529.0996,18758.2344},
        StonetalonMountains={4883.3331,3256.2498,13820.7664,9883.2339}, Tanaris={6899.9995,4600,17285.3496,18674.9004},
        Teldrassil={5091.6665,3393.75,13252.0164,968.6504}, ThousandNeedles={4399.9997,2933.3330,17499.9329,16766.5669},
        ThunderBluff={1043.7499,695.8333,16549.9330,13649.9003}, UngoroCrater={3699.9998,2466.6665,16533.2663,18766.5669},
        Winterspring={7099.9998,4733.3333,17383.2663,4266.5674},
    }},
    [2] = { width = 35199.900390625, height = 23466.60009765625, xOffset = 16625, yOffset = 2470, zones = {
        Alterac={2799.9999,1866.6667,15216.6667,5966.6001}, Arathi={3599.9999,2399.9999,16866.6666,7599.9334},
        Badlands={2487.5,1658.3335,18079.1665,13356.1831}, BlastedLands={3349.9999,2233.3340,17241.6666,18033.2661},
        BurningSteppes={2929.1666,1952.0835,16266.6667,14497.8496}, DeadwindPass={2499.9999,1666.6670,16833.3333,17333.2661},
        DunMorogh={4924.9998,3283.3333,14197.9167,11343.6833}, Duskwood={2699.9999,1800,15166.6667,17183.2661},
        EasternPlaguelands={3870.8335,2581.2498,18185.4165,3666.6003}, Elwynn={3470.8333,2314.5830,14464.5834,15406.1831},
        Hilsbrad={3199.9999,2133.3333,14933.3334,7066.6001}, Hinterlands={3850,2566.6666,17575,5999.9335},
        Ironforge={790.6251,527.6045,16713.5914,12035.8413}, LochModan={2758.3331,1839.5830,17993.7499,11954.1001},
        Redridge={2170.8333,1447.9160,17570.8333,16041.6001}, SearingGorge={2231.2498,1487.4995,16322.9167,13566.6001},
        Silverpine={4199.9998,2799.9999,12550.0002,5799.9335}, Stormwind={1344.2708,896.3545,14619.0286,15745.4507},
        Stranglethorn={6381.2498,4254.1660,13779.1667,18635.3501}, SwampOfSorrows={2293.75,1529.1670,18222.9165,17087.4331},
        Tirisfal={4518.7499,3012.4998,12966.6667,3629.1003}, Undercity={959.3750,640.1041,15126.8074,5588.6548},
        WesternPlaguelands={4299.9999,2866.6665,15583.3333,4099.9336}, Westfall={3499.9998,2333.3330,12983.3335,16866.6001},
        Wetlands={4135.4167,2756.25,16389.5833,9614.5166},
    }},
}

function HCM:GetMapContext()
    local continent = GetCurrentMapContinent and GetCurrentMapContinent() or 0
    local zoneIndex = GetCurrentMapZone and GetCurrentMapZone() or 0
    local zone = zoneIndex > 0 and GetMapInfo and GetMapInfo() or ""
    return continent or 0, zone or "", zoneIndex or 0
end

function HCM:ProjectPosition(continent, zone, x, y, targetContinent, targetZone)
    local source = self.MapSizes[continent]
    if not source or not source.zones[zone] then return nil end
    local z = source.zones[zone]
    local cx = (z[3] + x * z[1]) / source.width
    local cy = (z[4] + y * z[2]) / source.height
    if targetZone and targetZone ~= "" then
        if targetContinent ~= continent or targetZone ~= zone then return nil end
        return x, y
    end
    if targetContinent and targetContinent > 0 then
        if targetContinent ~= continent then return nil end
        return cx, cy
    end
    local world = self.MapSizes[0]
    return (source.xOffset + cx * source.width) / world.width, (source.yOffset + cy * source.height) / world.height
end

function HCM:CursorPosition(frame)
    if not frame or not frame.GetLeft or not frame:GetLeft() then return nil end
    local scale = frame:GetEffectiveScale() or 1
    local x, y = GetCursorPosition()
    x = (x / scale - frame:GetLeft()) / frame:GetWidth()
    y = (frame:GetTop() - y / scale) / frame:GetHeight()
    if x < 0 or x > 1 or y < 0 or y > 1 then return nil end
    return x, y
end
