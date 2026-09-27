local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

local localPlayer = Players.LocalPlayer

-- Переменные состояний функций
local pnvEnabled = false
local vhEnabled = false
local hitboxEnabled = false

-- Дефолтные настройки света игры
local defaultBrightness = Lighting.Brightness
local defaultClockTime = Lighting.ClockTime
local defaultFogEnd = Lighting.FogEnd
local defaultShadows = Lighting.GlobalShadows

-- Таблица для отслеживания оригинальных размеров голов
local originalHeadSizes = {}

-- ==========================================
-- 1. СИСТЕМА ПНВ
-- ==========================================
local function doFullbright()
    if pnvEnabled then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    end
end
Lighting.Changed:Connect(doFullbright)

-- ==========================================
-- 2. СИСТЕМА ВХ (HIGHLIGHT)
-- ==========================================
local function createHighlight(model, color)
    if not model:FindFirstChild("Active_ESP") then
        local highlight = Instance.new("Highlight")
        highlight.Name = "Active_ESP"
        highlight.Adornee = model
        highlight.FillColor = color
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0
        highlight.Enabled = vhEnabled
        highlight.Parent = model
    end
end

local function updateVHVisibility()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local esp = obj:FindFirstChild("Active_ESP")
        if esp then esp.Enabled = vhEnabled end
    end
end

-- ==========================================
-- 3. СИСТЕМА УВЕЛИЧЕНИЯ ХИТБОКСОВ
-- ==========================================
local function applyHitbox(model)
    local head = model:WaitForChild("Head", 5)
    if head and head:IsA("BasePart") then
        if not originalHeadSizes[head] then
            originalHeadSizes[head] = {Size = head.Size, Transparency = head.Transparency, Color = head.Color}
        end
        
        if hitboxEnabled then
            head.Size = Vector3.new(10, 10, 10)
            head.Transparency = 0.6
            head.Color = Color3.fromRGB(0, 255, 255)
            head.CanCollide = false
            local hum = model:FindFirstChildWhichIsA("Humanoid")
            if hum then head.Massless = true end
        else
            local orig = originalHeadSizes[head]
            if orig then
                head.Size = orig.Size
                head.Transparency = orig.Transparency
                head.Color = orig.Color
            end
        end
    end
end

local function updateAllHitboxes()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
            task.spawn(function() applyHitbox(obj) end)
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer and p.Character then
            task.spawn(function() applyHitbox(p.Character) end)
        end
    end
end

-- Мониторинг новых существ на карте
local function setupEntity(object)
    if object:IsA("Model") and object:FindFirstChild("Humanoid") then
        if not Players:GetPlayerFromCharacter(object) then
            local name = object.Name:lower()
            if name:find("chimera") or name:find("kayden") or name:find("troy") or name:find("boss") or name:find("vorax") then
                createHighlight(object, Color3.fromRGB(255, 0, 255))
            else
                createHighlight(object, Color3.fromRGB(255, 165, 0))
            end
            if hitboxEnabled then task.spawn(function() applyHitbox(object) end) end
        end
    end
end

Workspace.DescendantAdded:Connect(setupEntity)
for _, obj in ipairs(Workspace:GetDescendants()) do setupEntity(obj) end

local function applyPlayerESP(player)
    player.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart", 5)
        createHighlight(char, Color3.fromRGB(255, 0, 0))
        if hitboxEnabled then task.spawn(function() applyHitbox(char) end) end
    end)
end
for _, p in ipairs(Players:GetPlayers()) do if p ~= localPlayer then applyPlayerESP(p) end end
Players.PlayerAdded:Connect(applyPlayerESP)

-- ==========================================
-- 4. СОЗДАНИЕ GUI ИНТЕРФЕЙСА
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ExamGodMode_Menu"
screenGui.ResetOnSpawn = false
pcall(function() screenGui.Parent = CoreGui end)
if not screenGui.Parent then screenGui.Parent = localPlayer:WaitForChild("PlayerGui") end

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 360)
frame.Position = UDim2.new(0.1, 0, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
title.Text = "Examination Ultimate Menu"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 14
title.Font = Enum.Font.SourceSansBold
title.Parent = frame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

local function createButton(text, yPos, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 32)
    btn.Position = UDim2.new(0.05, 0, 0, yPos)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.SourceSansBold
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

-- Кнопки функционала
local btnPNV = createButton("ПНВ: ВЫКЛ", 45, Color3.fromRGB(100, 40, 40))
local btnVH = createButton("ВХ: ВЫКЛ", 85, Color3.fromRGB(100, 40, 40))
local btnHitbox = createButton("Большие головы: ВЫКЛ", 125, Color3.fromRGB(100, 40, 40))

-- Кнопки телепортации
local btnCrystal = createButton("ТП к Кристаллу", 170, Color3.fromRGB(0, 120, 200))
local btnNote = createButton("ТП к Блокноту", 210, Color3.fromRGB(0, 150, 100))
local btnSector3 = createButton("ТП в 3 Сектор", 250, Color3.fromRGB(150, 0, 200))

-- Кнопка скрытия меню
local btnToggle = createButton("Свернуть меню", 320, Color3.fromRGB(60, 60, 60))
btnToggle.Size = UDim2.new(0.9, 0, 0, 25)

-- Логика кнопок
btnPNV.MouseButton1Click:Connect(function()
    pnvEnabled = not pnvEnabled
    btnPNV.Text = pnvEnabled and "ПНВ: ВКЛ" or "ПНВ: ВЫКЛ"
    btnPNV.BackgroundColor3 = pnvEnabled and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(100, 40, 40)
    if pnvEnabled then doFullbright() else
        Lighting.Brightness = defaultBrightness; Lighting.ClockTime = defaultClockTime
        Lighting.FogEnd = defaultFogEnd; Lighting.GlobalShadows = defaultShadows
    end
end)

btnVH.MouseButton1Click:Connect(function()
    vhEnabled = not vhEnabled
    btnVH.Text = vhEnabled and "ВХ: ВКЛ" or "ВХ: ВЫКЛ"
    btnVH.BackgroundColor3 = vhEnabled and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(100, 40, 40)
    updateVHVisibility()
end)

btnHitbox.MouseButton1Click:Connect(function()
    hitboxEnabled = not hitboxEnabled
    btnHitbox.Text = hitboxEnabled and "Большие головы: ВКЛ" or "Большие головы: ВЫКЛ"
    btnHitbox.BackgroundColor3 = hitboxEnabled and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(100, 40, 40)
    updateAllHitboxes()
end)

-- Общая функция телепортации
local function teleportToTarget(checkType)
    local found = nil
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            if checkType == "crystal" and (name:find("xenon") or name:find("crystal")) and not (name:find("note") or name:find("paper") or name:find("book")) then
                found = obj; break
            elseif checkType == "note" and (name:find("note") or name:find("book") or name:find("paper") or name:find("yuri")) then
                found = obj; break
            elseif checkType == "sector3" and (name:find("sector3") or name:find("sector 3") or name:find("zone3") or name:find("gate3")) then
                found = obj; break
            end
        end
    end
    
    if found then
        local part = found:IsA("Model") and (found.PrimaryPart or found:FindFirstChildWhichIsA("BasePart")) or found
        if part and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
            localPlayer.Character.HumanoidRootPart.CFrame = part.CFrame + Vector3.new(0, 3, 0)
        end
    else
        warn("Цель для телепорта не найдена!")
    end
end

btnCrystal.MouseButton1Click:Connect(function() teleportToTarget("crystal") end)
btnNote.MouseButton1Click:Connect(function() teleportToTarget("note") end)
btnSector3.MouseButton1Click:Connect(function() teleportToTarget("sector3") end)

-- Логика скрытия интерфейса
local menuOpen = true
btnToggle.MouseButton1Click:Connect(function()
    menuOpen = not menuOpen
    frame.Size = menuOpen and UDim2.new(0, 250, 0, 360) or UDim2.new(0, 250, 0, 35)
    btnPNV.Visible = menuOpen; btnVH.Visible = menuOpen; btnHitbox.Visible = menuOpen
    btnCrystal.Visible = menuOpen; btnNote.Visible = menuOpen; btnSector3.Visible = menuOpen
    btnToggle.Text = menuOpen and "Свернуть меню" or "Развернуть"
end)
