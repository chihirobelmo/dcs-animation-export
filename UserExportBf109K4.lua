-- UserExport.luaに書き加えてください: 
--   dofile(lfs.writedir().."Scripts/UserExportBf109K4.lua")

local file -- グローバル変数として宣言

-- DCS Worldのモデルビューワは DCS World/bin-mt/ModelViewer2.exe
-- Bf109K4 のモデルは DCS World/CoreMods/WWII Units/Bf-109K-4/Shapes/Bf-109K-4.EDM
-- DOF番号はモデルビューワのArgsと対応

-- DOF番号とラベルを対応させたテーブル
local dofMap = {
    ["右エルロン"] = 11,
    ["左エルロン"] = 12,
    ["右エレベータ"] = 15,
    ["左エレベータ"] = 16,
    ["ラダー"] = 17,
    ["パイロット頭左右"] = 39,
    ["パイロット頭上下"] = 99,
    ["右ラジエータ上下"] = 126,
    ["右フラップ"] = 127,
    ["左ラジエータ上下"] = 128,
    ["左フラップ"] = 129,
    ["右前翼スラット"] = 130,
    ["左前翼スラット"] = 132,
    ["下ラジエータ開"] = 278,
    ["左右ラジエータ開"] = 279,
    ["プロペラ回転"] = 407,
    ["プロペラピッチ"] = 413,
    ["パイロット左腕前後"] = 459,
    ["パイロット体上下"] = 459,
}

-- CSVに書き出す順序を指定する配列
local dofOrder = {
    "右エルロン",
    "左エルロン",
    "右エレベータ",
    "左エレベータ",
    "ラダー",
    "パイロット頭左右",
    "パイロット頭上下"
}

-- 飛行機を真後ろから見て、エルロンやエレベータは上が正、ラダーは左が正、パイロットの頭は時計回りで仰角は上が正

-- DOF値を取得する関数
local function getDOFValues()
    local values = {}
    for label, arg in pairs(dofMap) do
        values[label] = LoGetAircraftDrawArgumentValue(arg) or 0
    end
    return values
end

function LuaExportStart()
    -- タイムスタンプ付きファイル名
    local timestamp = os.date("%Y%m%d%H%M%S")
    local filePath = lfs.writedir() .. "Logs/FlightData_" .. timestamp .. ".csv"
    file = io.open(filePath, "w")

    if file then
        -- UTF-8 BOMを書き込む
        file:write("\239\187\191")  -- EF BB BF
        
        -- ヘッダ行を作成
        local headerLabels = {"時間(秒)","X座標(m)","Y座標(m)","Z座標(m)","仰角(度)","バンク角(度)","方位角(度)",
                              "Xベクトル(m/s)","Yベクトル(m/s)","Zベクトル(m/s)"}
        for _, label in ipairs(dofOrder) do
            table.insert(headerLabels, label)
        end
        file:write(table.concat(headerLabels, ",") .. "\n")
    end
end

function LuaExportAfterNextFrame()
    if not file then return end

    local selfData = LoGetSelfData()
    local velVec = LoGetVectorVelocity()
    if not selfData or not velVec then return end

    local t = LoGetModelTime()
    local pi = 3.1415926535898
    local pos = selfData.Position
    local pitch = selfData.Pitch * (180/pi)
    local bank  = selfData.Bank  * (180/pi)
    local heading = selfData.Heading * (180/pi)

    -- DOF値取得
    local dofValues = getDOFValues()

    -- CSV行作成
    local row = {
        string.format("%.3f", t),
        string.format("%.3f", pos.x),
        string.format("%.3f", pos.y),
        string.format("%.3f", pos.z),
        string.format("%.3f", pitch),
        string.format("%.3f", bank),
        string.format("%.3f", heading),
        string.format("%.3f", velVec.x),
        string.format("%.3f", velVec.y),
        string.format("%.3f", velVec.z)
    }

    for _, label in ipairs(dofOrder) do
        table.insert(row, string.format("%.3f", dofValues[label]))
    end

    file:write(table.concat(row, ",") .. "\n")
end

function LuaExportStop()
    if file then
        file:close()
        file = nil
    end
end
