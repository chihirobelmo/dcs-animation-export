-- ===============================
-- ReplayGhost.lua : ゴースト再生
-- ===============================

local csvFilePath = lfs.writedir() .. "Logs/FlightExport.csv"
local ghostGroupName = "GhostPlane"   -- Mission Editorで作っておくグループ名
local replayInterval = 1.0            -- 秒間隔（CSV出力間隔に合わせる）

local function loadCsv(path)
    local data = {}
    local file = io.open(path, "r")
    if not file then
        env.error("CSV not found: " .. path)
        return data
    end
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

-- Euler (yaw, pitch, roll) -> body-axis vectors in world coords
-- Using rotation order: R = Rz(yaw) * Ry(pitch) * Rx(roll)
local function eulerToAxes(yaw, pitch, roll)
    local cy = math.cos(yaw)
    local sy = math.sin(yaw)
    local cp = math.cos(pitch)
    local sp = math.sin(pitch)
    local cr = math.cos(roll)
    local sr = math.sin(roll)

    -- Rotation matrix R = Rz * Ry * Rx
    -- matrix entries (row-major):
    -- r11 r12 r13
    -- r21 r22 r23
    -- r31 r32 r33
    local r11 = cy * cp
    local r12 = cy * (sp * sr) - sy * cr
    local r13 = cy * (sp * cr) + sy * sr

    local r21 = sy * cp
    local r22 = sy * (sp * sr) + cy * cr
    local r23 = sy * (sp * cr) - cy * sr

    local r31 = -sp
    local r32 = cp * sr
    local r33 = cp * cr

    -- columns of R are body axes expressed in world coordinates:
    local x_axis = {r11, r21, r31} -- body X (forward) in world coords
    local y_axis = {r12, r22, r32} -- body Y (right/up depending on convention)
    local z_axis = {r13, r23, r33} -- body Z (down/right)

    return x_axis, y_axis, z_axis
end

local replayData = loadCsv(csvFilePath)
if #replayData == 0 then
    env.error("No replay data loaded.")
end

local group = Group.getByName(ghostGroupName)
if not group then
    env.error("Ghost group not found: " .. tostring(ghostGroupName))
end

local units = group:getUnits()
if not units or #units == 0 then
    env.error("No units in ghost group.")
end

local ghostUnit = units[1]
local index = 1

local function updateGhost()
    if index > #replayData then
        return nil
    end

    local p = replayData[index]
    -- DCS uses (x,z,y) sometimes in different APIs — here we assume CSV wrote pos.x,pos.y(pos altitude),pos.z
    local point = { x = p.x, y = p.z, z = p.y } -- if your CSV uses different axes, adjust here
    -- NOTE: adjust mapping above if your exported coordinates differ (common source of mismatch)

    local yaw = p.heading or 0.0
    local pitch = p.pitch or 0.0
    local roll = p.roll or 0.0

    local xAxis, yAxis, zAxis = eulerToAxes(yaw, pitch, roll)

    -- setPosition expects table {p = {x,y,z}, x = {...}, y = {...}, z = {...}}
    ghostUnit:setPosition({
        p = { x = point.x, y = point.y, z = point.z },
        x = xAxis,
        y = yAxis,
        z = zAxis
    })

    index = index + 1
    return timer.getTime() + replayInterval
end

timer.scheduleFunction(updateGhost, nil, timer.getTime() + replayInterval)

--[[

Mission Editorでの準備
    適当なAI機（例：Su-25T）を配置。
    グループ名を "GhostPlane" に設定。
    「Late Activation」にチェック。
    トリガーを追加：
        Condition: MISSION START
        Action: DO SCRIPT FILE → ReplayGhost.lua

結果
    ミッションを開始すると、AI機（GhostPlane）が
    FlightExport.csv の座標に従って1秒ごとに移動します。
    自分の機体を操作して、その「過去の自分」と一緒に飛行できます。

注意点・補足
    座標軸のマッピング
        CSV の pos.x,pos.y,pos.z がどの座標系で書かれているか（DCS の内部 API と出力の順序）によって point = { x=..., y=..., z=... } の割当を変える必要があります。上のコードでは一例として p.x -> x, p.z -> y(高度), p.y -> z としています。もし前の CSV で問題なければそのままで大丈夫ですが、もし機体が地面に潜ったり位置がおかしければここを調整してください。
    角度の単位
        CSV の heading/pitch/roll がラジアンで出力されている前提です。もし度（°）で出ているなら math.rad( value ) で変換してください。Export.lua 側でラジアンで出すのが一般的です。
    回転順・慣例
        本コードは R = Rz(yaw) * Ry(pitch) * Rx(roll)（ yaw→pitch→roll ）の順で回転を適用しています。一般的な航空機表現（heading/pitch/bank）に合うはずですが、もし見た目が反転する・左右逆になる等があれば回転順や符号（±）を調整してください。
    補間
        この実装はステップで移動します（CSV のサンプリング間隔に依存）。よりスムーズにするには、前後フレームを線形補間して毎フレーム位置を更新する実装にするのが良いです。
]]