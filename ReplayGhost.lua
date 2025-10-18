-- ===============================
-- ReplayGhost.lua : ゴースト再生
-- ===============================

local csvFilePath = lfs.writedir() .. "Logs/FlightExport.csv"
local ghostGroupName = "GhostPlane"   -- Mission Editorで作っておくグループ名
local replayInterval = 1.0            -- 秒間隔（CSV出力間隔に合わせる）

-- CSV読み込み
local function loadCsv(path)
    local data = {}
    local file = io.open(path, "r")
    if not file then
        env.error("CSV not found: " .. path)
        return data
    end

    -- 1行ずつ読み込み
    local header = true
    for line in file:lines() do
        if not header then
            local t,x,y,z,heading,pitch,roll = line:match("([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
            if t then
                table.insert(data, {
                    t = tonumber(t),
                    x = tonumber(x),
                    y = tonumber(y),
                    z = tonumber(z),
                    heading = tonumber(heading),
                    pitch = tonumber(pitch),
                    roll = tonumber(roll)
                })
            end
        else
            header = false
        end
    end
    file:close()
    return data
end

local replayData = loadCsv(csvFilePath)
local ghostUnit = Group.getByName(ghostGroupName):getUnits()[1]
local index = 1

-- 補間なしでステップ移動（簡易版）
local function updateGhost()
    if index > #replayData then
        return nil
    end
    local p = replayData[index]
    local point = {x = p.x, y = p.y, z = p.z}
    local alt = p.y

    local yaw = p.heading
    local pitch = p.pitch
    local roll = p.roll

    ghostUnit:setPosition({
        p = point,
        x = {math.cos(yaw), 0, math.sin(yaw)},
        y = {0, 1, 0},
        z = {-math.sin(yaw), 0, math.cos(yaw)}
    })

    index = index + 1
    return timer.getTime() + replayInterval
end

timer.scheduleFunction(updateGhost, nil, timer.getTime() + replayInterval)
