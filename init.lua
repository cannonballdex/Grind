--Grind by Cannonballdex
--Missions: The Call, The Crusaders, Shei Vinitras

local mq = require('mq')
local ImGui = require('ImGui')

local showWindow = true

-- Mission definitions
local missions = {
    { name = "The Call", file = "grind/thecall.lua" },
    { name = "The Crusaders", file = "grind/thecrusaders.lua" },
    { name = "Shei Vinitras", file = "grind/shei.lua" },
}

local function RunScript(script)
    mq.cmdf('/lua run %s', script)
end

local function StopScript(script)
    mq.cmdf('/lua stop %s', script)
end

local function GrindGUI()

    if not showWindow then
        return
    end

    ImGui.SetNextWindowSize(350, 200, ImGuiCond.FirstUseEver)

    local shouldDraw
    showWindow, shouldDraw = ImGui.Begin("Grind Mission Launcher", showWindow)

    if shouldDraw then

        ImGui.Text("Select a Mission Script")
        ImGui.Separator()

        for _, mission in ipairs(missions) do

            if ImGui.Button("Run " .. mission.name, 150, 30) then
                RunScript(mission.file)
            end

            ImGui.SameLine()

            if ImGui.Button("Stop " .. mission.name, 150, 30) then
                StopScript(mission.file)
            end

        end

        ImGui.Separator()

        if ImGui.Button("Close Window", 310, 30) then
            showWindow = false
        end

    end

    ImGui.End()
end

mq.imgui.init('GrindLauncher', GrindGUI)

while showWindow do
    mq.delay(1000)
end