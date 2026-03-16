--shei.lua by Cannonballdex
-- Shei Vinitras in Umbral Plains

local mq = require('mq')

local START_ZONE_ID = 843
local SHEI_ZONE_ID = 845
local TASK_NAME = "Shei Vinitras"
local TASK_TIMER_THRESHOLD = 1000000
local CAMPFIRE_RADIUS = 50
local INSIGNIA_NAME = "Fellowship Registration Insignia"

local sessionEnded = false
local pullStarted = false

local function hasTask()
    return mq.TLO.Task(TASK_NAME).ID() ~= nil
end

local function getTaskTimer()
    local timer = mq.TLO.Task(TASK_NAME).Timer()
    return timer or 0
end

local function inZone(zoneID)
    return mq.TLO.Zone.ID() == zoneID
end

local function isHovering()
    return mq.TLO.Me.Hovering()
end

local function isSafeToAct()
    return not isHovering()
end

local function nearbyFellowshipCount()
    return mq.TLO.SpawnCount(('radius %d fellowship'):format(CAMPFIRE_RADIUS))() or 0
end

local function insigniaReady()
    local insignia = mq.TLO.FindItem(INSIGNIA_NAME)
    if not insignia() then
        return false
    end

    local ready = insignia.TimerReady()
    return ready == 0
end

local function cmdSelf(command)
    mq.cmd(command)
end

local function cmdGroup(command)
    mq.cmd('/noparse /dgge ' .. command)
end

local function cmdAll(command)
    mq.cmd('/noparse /dgga ' .. command)
end

local function rgPauseGroup()
    cmdSelf('/rgl pauseall')
end

local function rgUnpauseGroup()
    cmdSelf('/rgl unpauseall')
end

local function groupReadyAtCamp()
    if mq.TLO.Zone.ID() ~= SHEI_ZONE_ID then
        return false
    end

    return nearbyFellowshipCount() > 2
end

local function setGroupCamp()
    rgUnpauseGroup()
    mq.delay(1000)

    -- Camp only the rest of the group, not the tank running this script.
    cmdGroup('/rgl unpause')
    mq.delay(500)
    cmdGroup('/rgl campon')
    mq.delay(1000)

    -- Make sure the tank itself is camped and ready to pull.
    cmdSelf('/rgl unpause')
    mq.delay(500)
    cmdSelf('/rgl campon')
    mq.delay(500)
end

local function startTankPulling()
    cmdSelf('/rgl unpause')
    mq.delay(500)
    cmdSelf('/rgl pullstart')
end

local function stopTankPulling()
    cmdSelf('/rgl pullstop')
end

local function dropcampfire()
    if not inZone(SHEI_ZONE_ID) then return end
    if mq.TLO.Me.Fellowship.Campfire() then return end
    if not isSafeToAct() then return end
    if nearbyFellowshipCount() <= 2 then return end
    if not hasTask() then return end
    if getTaskTimer() <= TASK_TIMER_THRESHOLD then return end

    mq.delay(1000)
    rgUnpauseGroup()
    mq.delay(1000)

    print('\agPreparing group before dropping campfire')

    mq.cmd('/windowstate FellowshipWnd open')
    mq.delay(1000)
    mq.cmd('/nomodkey /notify FellowshipWnd FP_Subwindows tabselect 2')
    mq.delay(1000)
    mq.cmd('/nomodkey /notify FellowshipWnd FP_RefreshList leftmouseup')
    mq.delay(1000)
    mq.cmd('/nomodkey /notify FellowshipWnd FP_CampsiteKitList listselect 1')
    mq.delay(1000)
    mq.cmd('/nomodkey /notify FellowshipWnd FP_CreateCampsite leftmouseup')
    mq.delay(1000)
    mq.cmd('/windowstate FellowshipWnd close')
    mq.delay(1000)

    print('\agDropped a Campfire')

    mq.delay(5000)
    cmdGroup('/camphere on')
    mq.delay(1000)
    rgUnpauseGroup()
    mq.delay(3000)
end

local function checkcamp()
    local hasCampfire = mq.TLO.Me.Fellowship.Campfire()
    local campfireZone = mq.TLO.Me.Fellowship.CampfireZone.ID()
    local currentZone = mq.TLO.Zone.ID()

    if hasCampfire and campfireZone ~= currentZone and insigniaReady() then
        mq.cmd('/makemevisible')
        mq.cmdf('/useitem "%s"', INSIGNIA_NAME)
        mq.delay(5000)
        print('\ayClicking back to camp!')
    end

    if not pullStarted and groupReadyAtCamp() then
        setGroupCamp()
        mq.delay(2000)
        startTankPulling()
        pullStarted = true
        print('\agGroup is in zone and camped. Tank is starting pulls.')
    end
end

local function checktask()
    if hasTask() then
        sessionEnded = false
        return
    end

    if not inZone(START_ZONE_ID) then return end

    sessionEnded = false
    pullStarted = false

    mq.delay(1000)
    rgPauseGroup()
    mq.delay(1000)

    cmdAll('/nav spawn a worrisome shade')
    mq.delay(1000)
    cmdAll('/target a worrisome shade')
    mq.delay(1000)

    mq.cmd('/say small')

    for _ = 1, 30 do
        if isHovering() then
            return
        end
        mq.delay(1000)
    end

    cmdAll('/target a worrisome shade')
    mq.delay(1000)

    for i = 1, 5 do
        local member = mq.TLO.Group.Member(i).Name()
        if member then
            mq.cmdf('/dex %s /say ready', member)
            mq.delay(500)
        end
    end

    mq.delay(500)
    cmdAll('/say ready')

    mq.delay(1000)
    rgUnpauseGroup()
end

local function checkdone()
    if sessionEnded then return end
    if not inZone(SHEI_ZONE_ID) then return end
    if not hasTask() then return end
    if getTaskTimer() >= TASK_TIMER_THRESHOLD then return end
    if mq.TLO.Me.Combat() then return end
    if mq.TLO.Me.Hovering() then return end
    if mq.TLO.Me.Moving() then return end

    sessionEnded = true

    print('\agEnding Session!')
    mq.cmd('/nav stop')

    stopTankPulling()
    mq.delay(500)

    rgPauseGroup()
    mq.delay(1000)

    mq.cmd('/kickp task')
    mq.cmd('/dgga /end')
    mq.delay(1500)
    mq.cmd('/notify ConfirmationDialogBox CD_Yes_Button leftmouseup')
    mq.delay(1500)

    mq.cmd('/windowstate FellowshipWnd open')
    mq.delay(1500)
    mq.cmd('/nomodkey /notify FellowshipWnd FP_Subwindows tabselect 1')
    mq.delay(1500)
    mq.cmd('/nomodkey /notify FellowshipWnd FP_DestroyCampsite leftmouseup')
    mq.delay(1500)
    mq.cmd('/notify ConfirmationDialogBox CD_Yes_Button leftmouseup')
    mq.delay(2000)
    mq.cmd('/windowstate FellowshipWnd close')
    mq.delay(1000)

    print('\ayAborting Zone in 60 seconds. Please wait...')
    mq.delay(1000)
    mq.delay(60000)

    rgPauseGroup()
    mq.delay(2000)
end

local function dead()
    if not isHovering() then
        return
    end

    stopTankPulling()
    rgPauseGroup()

    while mq.TLO.Me.Hovering() do
        mq.delay(1000)
    end

    mq.delay(2000)
end

-- Exit immediately if the script was not started in the required zone.
if not inZone(START_ZONE_ID) then
    print(('\arNot in starting zone. Current zone ID: %s. Ending script.'):format(mq.TLO.Zone.ID() or 'unknown'))
    return
end

while true do
    dropcampfire()
    mq.delay(1000)

    checkcamp()
    mq.delay(1000)

    checktask()
    mq.delay(1000)

    checkdone()
    mq.delay(1000)

    dead()
    mq.delay(1000)
end