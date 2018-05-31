-- APIS
    os.loadAPI("SkyNet/MWP/lib/waypoint")
    os.loadAPI("SkyNet/MWP/lib/gps2")
    os.loadAPI("SkyNet/MWP/lib/act")
    os.loadAPI("SkyNet/MWP/lib/quarry_api")



local function startPath()
    local quarryCorner = vector.new(-114,91,359)

    point1 = waypoint.waypoint:new('point1',quarryCorner)

    path = waypoint.path:new('potato')
    path:append(point1)
    path:start(1,false)
end

local function refuelMonitorP()
    act.refuelMonitor:listenPerpetually()
end

parallel.waitForAny(startPath, refuelMonitorP)

--Now let's start making that quarry

local function quarry()       -- This naming is terrifying -BREVAN
    quarry_api.makeQuarry(10,5,5)
end

local function storageMonitorP()
    act.storageMonitor:listenPerpetually()
end

parallel.waitForAny(quarry,refuelMonitorP,storageMonitorP)