-- UserExport.lua�ɏ��������Ă�������: 
--   dofile(lfs.writedir().."Scripts/UserExportBf109K4.lua")

local file -- �O���[�o���ϐ��Ƃ��Đ錾

-- DCS World�̃��f���r���[���� DCS World/bin-mt/ModelViewer2.exe
-- Bf109K4 �̃��f���� DCS World/CoreMods/WWII Units/Bf-109K-4/Shapes/Bf-109K-4.EDM
-- DOF�ԍ��̓��f���r���[����Args�ƑΉ�

-- DOF�ԍ��ƃ��x����Ή��������e�[�u��
local dofMap = {
    ["�E�G������"] = 11,
    ["���G������"] = 12,
    ["�E�G���x�[�^"] = 15,
    ["���G���x�[�^"] = 16,
    ["���_�["] = 17,
    ["�p�C���b�g�����E"] = 39,
    ["�p�C���b�g���㉺"] = 99,
    ["�E���W�G�[�^�㉺"] = 126,
    ["�E�t���b�v"] = 127,
    ["�����W�G�[�^�㉺"] = 128,
    ["���t���b�v"] = 129,
    ["�E�O���X���b�g"] = 130,
    ["���O���X���b�g"] = 132,
    ["�����W�G�[�^�J"] = 278,
    ["���E���W�G�[�^�J"] = 279,
    ["�v���y����]"] = 407,
    ["�v���y���s�b�`"] = 413,
    ["�p�C���b�g���r�O��"] = 459,
    ["�p�C���b�g�̏㉺"] = 459,
}

-- CSV�ɏ����o���������w�肷��z��
local dofOrder = {
    "�E�G������",
    "���G������",
    "�E�G���x�[�^",
    "���G���x�[�^",
    "���_�[",
    "�p�C���b�g�����E",
    "�p�C���b�g���㉺"
}

-- ��s�@��^��납�猩�āA�G��������G���x�[�^�͏オ���A���_�[�͍������A�p�C���b�g�̓��͎��v���ŋp�͏オ��

-- DOF�l���擾����֐�
local function getDOFValues()
    local values = {}
    for label, arg in pairs(dofMap) do
        values[label] = LoGetAircraftDrawArgumentValue(arg) or 0
    end
    return values
end

function LuaExportStart()
    -- �^�C���X�^���v�t���t�@�C����
    local timestamp = os.date("%Y%m%d%H%M%S")
    local filePath = lfs.writedir() .. "Logs/FlightData_" .. timestamp .. ".csv"
    file = io.open(filePath, "w")

    if file then
        -- UTF-8 BOM����������
        file:write("\239\187\191")  -- EF BB BF
        
        -- �w�b�_�s���쐬
        local headerLabels = {"����(�b)","X���W(m)","Y���W(m)","Z���W(m)","�p(�x)","�o���N�p(�x)","���ʊp(�x)",
                              "X�x�N�g��(m/s)","Y�x�N�g��(m/s)","Z�x�N�g��(m/s)"}
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

    -- DOF�l�擾
    local dofValues = getDOFValues()

    -- CSV�s�쐬
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
