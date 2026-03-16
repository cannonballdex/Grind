--thecrusaders.lua by Cannonballdex
-- Watcher Sprin in Cobalt Scar

local mq = require('mq')

local START_ZONE_ID = 833
local TASK_ZONE_ID = 835
local TASK_NAME = "The Crusaders"
local TASK_TIMER_THRESHOLD = 19000000
local CAMPFIRE_RADIUS = 50
local INSIGNIA_NAME = "Fellowship Registration Insignia"
local GROUP_STEP_RADIUS = 100
local GROUP_WAIT_TIMEOUT_MS = 60000

local sessionEnded = false
local pullStarted = false

local function inZone(zoneID)
    return mq.TLO.Zone.ID() == zoneID
end

local function hasTask()
    return mq.TLO.Task(TASK_NAME).ID() ~= nil
end

local function getTaskTimer()
    local timer = mq.TLO.Task(TASK_NAME).Timer()
    return timer or 0
end

local function isHovering()
    return mq.TLO.Me.Hovering()
end

local function nearbyFellowshipCount()
    return mq.TLO.SpawnCount(('radius %d fellowship'):format(CAMPFIRE_RADIUS))() or 0
end

local function insigniaReady()
    local insignia = mq.TLO.FindItem(INSIGNIA_NAME)
    if not insignia() then
        return false
    end

    return insignia.TimerReady() == 0
end

local function rgPauseAll()
    mq.cmd('/rgl pauseall')
end

local function rgUnpauseAll()
    mq.cmd('/rgl unpauseall')
end

local function startTankPulling()
    mq.cmd('/rgl unpause')
    mq.delay(500)
    mq.cmd('/rgl set PullMode 3')
    mq.delay(500)
    mq.cmd('/rgl setmode hunt')
    mq.delay(500)
    mq.cmd('/rgl pullstart')
    mq.delay(500)
    print('\agTank switched to hunt mode and pulling started.')
end

local function stopTankPulling()
    mq.cmd('/rgl pullstop')
end

local function allGroupMembersWithin(distance)
    local members = mq.TLO.Group.Members() or 0

    for i = 1, members do
        local member = mq.TLO.Group.Member(i)
        if member and member.Name() and member.Present() then
            local memberName = member.Name() or ('group member %d'):format(i)
            local memberDistance = tonumber(member.Distance()) or 999999

            if memberDistance > distance then
                return false, memberName, memberDistance
            end
        end
    end

    return true, nil, 0
end

local function waitForGroupWithin(distance, timeoutMs, stepName)
    local waited = 0
    local interval = 1000

    while waited < timeoutMs do
        if isHovering() then
            return false
        end

        local ready, memberName, memberDistance = allGroupMembersWithin(distance)
        if ready then
            print(('\agAll present group members are within %d for %s.'):format(distance, stepName))
            return true
        end

        local safeMemberName = memberName or 'unknown'
        local safeMemberDistance = tonumber(memberDistance) or 999999

        print(('\ayWaiting for %s to get within %d (%d away) before %s.'):format(
            safeMemberName,
            distance,
            math.floor(safeMemberDistance),
            stepName
        ))

        mq.delay(interval)
        waited = waited + interval
    end

    print(('\arTimed out waiting for group to get within %d before %s.'):format(distance, stepName))
    return false
end

local function groupReadyAtCamp()
    return inZone(TASK_ZONE_ID) and nearbyFellowshipCount() > 2
end

local function setGroupChase()
    mq.cmd('/noparse /dgge /rgl chaseon')
    mq.delay(1000)

    mq.cmd('/rgl campoff')
    mq.delay(500)
end

local function groupSayBreakingInvis(text)
    mq.cmd('/rgl set_all BreakInvisForSay 1')
    mq.delay(500)
    mq.cmdf('/rgl say %s', text)
    mq.delay(1500)
    mq.cmd('/rgl set_all BreakInvisForSay 0')
    mq.delay(500)
end

local function dropcampfire()
    if inZone(TASK_ZONE_ID)
        and mq.TLO.Me.Fellowship.Campfire() == false
        and not isHovering()
        and nearbyFellowshipCount() > 2
        and getTaskTimer() > TASK_TIMER_THRESHOLD then

        print('\agPreparing to drop campfire while group remains paused')

        mq.delay(1000)
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
    end
end

local function checkmode()
    if pullStarted then
        return
    end

    if hasTask()
        and getTaskTimer() > TASK_TIMER_THRESHOLD
        and groupReadyAtCamp()
        and mq.TLO.Me.Fellowship.Campfire() then

        print('\agCampfire detected. Switching group to chase and tank to hunt mode.')

        setGroupChase()
        mq.delay(2000)

        rgUnpauseAll()
        mq.delay(2000)

        startTankPulling()
        pullStarted = true

        print('\agGroup is in chase mode and tank is starting pulls.')
    end
end

local function checkcamp()
    if mq.TLO.Me.Fellowship.CampfireZone.ID() ~= mq.TLO.Zone.ID()
        and mq.TLO.Me.Fellowship.Campfire()
        and insigniaReady() then

        mq.cmd('/makemevisible')
        mq.cmd('/useitem Fellowship Registration Insignia')
        mq.delay(2000)
        print('\ayClicking back to camp!')
    end
end

local function checktask()
    if hasTask() then
        sessionEnded = false
        return
    end

    if not inZone(START_ZONE_ID) then
        return
    end

    sessionEnded = false
    pullStarted = false

    mq.delay(1000)
    rgPauseAll()
    mq.delay(1000)

    mq.cmd('/dgga /nav spawn Sprin')
    mq.delay(1000)
    mq.cmd('/dgga /target Sprin')
    mq.delay(1000)

    mq.cmd('/say small')
    mq.delay(60000)

    if not waitForGroupWithin(GROUP_STEP_RADIUS, GROUP_WAIT_TIMEOUT_MS, 'saying ready') then
        return
    end

    groupSayBreakingInvis('ready')

    print('\agMission requested. Group remains paused until campfire is set and chase mode is ready.')
end

local function checkdone()
    if sessionEnded then return end
    if not inZone(TASK_ZONE_ID) then return end
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

    mq.cmd('/noparse /dgga /rgl chaseoff')
    mq.delay(500)
    mq.cmd('/noparse /dgga /rgl campoff')
    mq.delay(1000)

    mq.cmd('/kickp task')
    mq.delay(1500)
    mq.cmd('/notify ConfirmationDialogBox CD_Yes_Button leftmouseup')
    mq.delay(1500)

    mq.cmd('/windowstate FellowshipWnd open')
    mq.delay(1500)
    mq.cmd('/nomodkey /notify FellowshipWnd FP_Subwindows tabselect 2')
    mq.delay(1500)
    mq.cmd('/nomodkey /notify FellowshipWnd FP_DestroyCampsite leftmouseup')
    mq.delay(1500)
    mq.cmd('/notify ConfirmationDialogBox CD_Yes_Button leftmouseup')
    mq.delay(2000)
    mq.cmd('/windowstate FellowshipWnd close')
    mq.delay(1000)

    print('\ayAborting Zone in 60 seconds. Please wait...')

    mq.delay(1000)
    mq.cmd('/rgl chaseoff')
    mq.delay(500)
    mq.cmd('/rgl campoff')
    mq.delay(60000)

    rgPauseAll()
    mq.delay(15000)
end

local function checkgroup()
    for i = 1, mq.TLO.Group.Members() do
        local member = mq.TLO.Group.Member(i)
        if member and member.Present() and not isHovering() then
            local memberDistance = tonumber(member.Distance()) or 999999
            if memberDistance > 75 then
                mq.cmdf('/dex %s /nav spawn %s', member.Name(), mq.TLO.Me.CleanName())
                print('\ag-----TheCrusaders.lua running----')
            end
        end
    end
end

local function dead()
    if not isHovering() then
        return
    end

    stopTankPulling()
    mq.cmd('/noparse /dgga /rgl chaseoff')
    mq.delay(500)
    mq.cmd('/noparse /dgga /rgl campoff')

    while mq.TLO.Me.Hovering() do
        mq.delay(1000)
    end

    mq.delay(2000)
    mq.cmd('/noparse /dgga /rgl chaseon')
end

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

    checkmode()
    mq.delay(1000)

    checkgroup()
    mq.delay(1000)

    dead()
    mq.delay(1000)
end