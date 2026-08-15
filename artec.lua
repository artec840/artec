-- Настройки полета
local FLY_SPEED = 200 -- Твоя финальная скорость (200)
local FLY_KEY = Enum.KeyCode.M -- Включение/выключение на M

-- Переменные состояния
local flying = false
local flyConnection = nil
local lockedPosition = nil -- Позиция мертвой фиксации

-- Сервисы игры
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

-- Функция для моментальных уведомлений
local function sendNotification(title, text)
    StarterGui:SetCore("SendNotification", {
        Title = title;
        Text = text;
        Duration = 1.5;
    })
end

-- Основной поток скоростного полета
local function startFlying()
    if flyConnection then flyConnection:Disconnect() end
    lockedPosition = nil
    
    -- Используем Stepped — он перехватывает управление ДО просчета физики сервера
    flyConnection = RunService.Stepped:Connect(function()
        if not flying then 
            if flyConnection then flyConnection:Disconnect() end
            return 
        end
        
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        
        if root and humanoid then
            -- 1. СТАБИЛИЗАЦИЯ: Включаем режим платформы, чтобы анимации не уносили тело назад
            humanoid.PlatformStand = true
            
            -- Сбрасываем инерцию, чтобы не было микро-движений
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            
            -- 2. NOCLIP: Свободно летим сквозь стены, чтобы игра не тепала при ударах
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            
            local cameraCFrame = workspace.CurrentCamera.CFrame
            local moveVector = Vector3.new(0, 0, 0)
            
            -- Собираем зажатые клавиши WASD
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + cameraCFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - cameraCFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + cameraCFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - cameraCFrame.RightVector end
            
            if moveVector.Magnitude > 0 then
                -- В ДВИЖЕНИИ: Перемещаем напрямую через чистый CFrame
                local velocity = moveVector.Unit * (FLY_SPEED / 50)
                root.CFrame = CFrame.new(root.Position + velocity, root.Position + velocity + cameraCFrame.LookVector)
                lockedPosition = nil -- Сбрасываем якорь остановки
            else
                -- НА МЕСТЕ: Если кнопки отпущены, жестко стопоримся в сохраненной точке
                if not lockedPosition then
                    lockedPosition = root.Position -- Запоминаем точную координату остановки
                end
                -- Магнитная фиксация: тело застывает, крутится только камера
                root.CFrame = CFrame.new(lockedPosition) * cameraCFrame.Rotation
            end
        end
    end)
end

-- Отслеживание кнопки M
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end -- Игнорируем чат
    
    if input.KeyCode == FLY_KEY then
        flying = not flying
        
        if flying then
            sendNotification("Fly Script", "Идеальный полет 120 активирован! [M]")
            startFlying()
        else
            sendNotification("Fly Script", "Полет полностью отключен.")
            lockedPosition = nil
            
            -- Возвращаем управление персонажу при отключении чита
            local char = LocalPlayer.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.PlatformStand = false
            end
        end
    end
end)
