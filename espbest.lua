local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TextService = game:GetService("TextService")
local JogadorLocal = game:GetService("Players").LocalPlayer

local espBestEnabled = false
local espBestGui = nil
local espBestUpdate = {}
local espBestAnimals = {}
local espBestCurrent = nil
local _AnimalsShared = nil
local _AnimalsData = nil
local _NumberUtils = nil
local _myPlotName = nil

local colors = {
    bg = Color3.fromRGB(12, 12, 12),
    separator = Color3.fromRGB(50, 50, 50),
    text = Color3.fromRGB(255, 255, 255),
    btn = Color3.fromRGB(22, 22, 22),
    btnHover = Color3.fromRGB(35, 35, 35),
    btnPress = Color3.fromRGB(50, 50, 50),
    pillOn = Color3.fromRGB(55, 55, 55),
    stroke = Color3.fromRGB(55, 55, 55),
}

local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 4)
    c.Parent = parent
end

local function stroke(parent, color, thick)
    local s = Instance.new("UIStroke")
    s.Color = color or colors.stroke
    s.Thickness = thick or 1
    s.Parent = parent
end

local function waveBorder(parent, thickness)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 60)),
        ColorSequenceKeypoint.new(0.25, Color3.fromRGB(100, 100, 100)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(160, 160, 160)),
        ColorSequenceKeypoint.new(0.75, Color3.fromRGB(100, 100, 100)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 60, 60))
    })
    
    local s = Instance.new("UIStroke")
    s.Thickness = thickness or 1.5
    s.Color = Color3.fromRGB(255, 255, 255)
    s.Parent = parent
    gradient.Parent = s
    
    local t = 0
    RunService.Heartbeat:Connect(function(delta)
        t = t + delta * 2
        local offset = (math.sin(t) + 1) / 2
        
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 50)),
            ColorSequenceKeypoint.new(offset * 0.5, Color3.fromRGB(120, 120, 120)),
            ColorSequenceKeypoint.new(offset, Color3.fromRGB(200, 200, 200)),
            ColorSequenceKeypoint.new(offset * 0.5 + 0.5, Color3.fromRGB(120, 120, 120)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 50, 50))
        })
        
        gradient.Rotation = t * 50 % 360
    end)
    
    return s
end

local function waveText(textLabel)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 200, 200)),
        ColorSequenceKeypoint.new(0.25, Color3.fromRGB(230, 230, 230)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.75, Color3.fromRGB(230, 230, 230)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
    })
    gradient.Parent = textLabel
    
    local t = 0
    RunService.Heartbeat:Connect(function(delta)
        t = t + delta * 1.5
        local offset = (math.sin(t) + 1) / 2
        
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 180, 180)),
            ColorSequenceKeypoint.new(offset * 0.5, Color3.fromRGB(220, 220, 220)),
            ColorSequenceKeypoint.new(offset, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(offset * 0.5 + 0.5, Color3.fromRGB(220, 220, 220)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 180, 180))
        })
        
        gradient.Rotation = t * 30 % 360
    end)
end

local function makeDraggable(gui, handle)
    local dragging, dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function _loadModules()
    if not _AnimalsShared then
        local ok, v = pcall(require, ReplicatedStorage.Shared:WaitForChild("Animals"))
        if ok then _AnimalsShared = v end
    end
    if not _AnimalsData then
        local ok, v = pcall(require, ReplicatedStorage.Datas:WaitForChild("Animals"))
        if ok then _AnimalsData = v end
    end
    if not _NumberUtils then
        local ok, v = pcall(require, ReplicatedStorage.Utils:WaitForChild("NumberUtils"))
        if ok then _NumberUtils = v end
    end
end

local BeamState = {
    beam        = nil,
    attOrigin   = nil,
    attTarget   = nil,
    currentUID  = nil,
}

local function removeBeam()
    if BeamState.beam      then BeamState.beam:Destroy();      BeamState.beam      = nil end
    if BeamState.attOrigin then BeamState.attOrigin:Destroy(); BeamState.attOrigin = nil end
    if BeamState.attTarget then BeamState.attTarget:Destroy(); BeamState.attTarget = nil end
    BeamState.currentUID = nil
end

local function updateBeam(targetAnimal, petModel)
    local newUID = targetAnimal and targetAnimal.uid or nil
    if not newUID then removeBeam(); return end
    if newUID == BeamState.currentUID then return end
    removeBeam()
    local char = JogadorLocal.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local targetPart = petModel and (petModel.PrimaryPart or petModel:FindFirstChildWhichIsA("BasePart"))
    if not targetPart then return end
    local attA = Instance.new("Attachment"); attA.Name = "BeamOrigin"; attA.Parent = root
    local attB = Instance.new("Attachment"); attB.Name = "BeamTarget"; attB.Parent = targetPart
    local beam = Instance.new("Beam")
    beam.Name          = "MuzanBeam"
    beam.Attachment0   = attA
    beam.Attachment1   = attB
    beam.Color         = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200,200,200)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255)) })
    beam.Transparency  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.5, 0.4), NumberSequenceKeypoint.new(1, 0.1) })
    beam.Width0        = 0.12
    beam.Width1        = 0.12
    beam.Segments      = 20
    beam.CurveSize0    = 0
    beam.CurveSize1    = 0
    beam.FaceCamera    = true
    beam.LightEmission = 1
    beam.LightInfluence = 0
    beam.TextureLength  = 2
    beam.TextureSpeed   = 1
    beam.Parent        = root
    BeamState.beam      = beam
    BeamState.attOrigin = attA
    BeamState.attTarget = attB
    BeamState.currentUID = newUID
end

local function findAnimalModel(animal)
    if animal.spawnPart and animal.spawnPart.Parent then
        local sp = animal.spawnPart
        for _, child in ipairs(sp:GetChildren()) do
            if child:IsA("Model") then return child end
        end
        local base = sp.Parent
        if base then
            for _, child in ipairs(base:GetChildren()) do
                if child:IsA("Model") then return child end
            end
            local pod = base.Parent
            if pod then
                for _, child in ipairs(pod:GetChildren()) do
                    if child:IsA("Model") then return child end
                end
            end
        end
    end
    if animal.prompt then
        local obj = animal.prompt
        for _ = 1, 5 do
            obj = obj.Parent
            if not obj then break end
            if obj:IsA("Model") then return obj end
        end
    end
    return nil
end

local function getPetModel(animal)
    local model = findAnimalModel(animal)
    if model then return model end
    if not animal.plot or not animal.slot then return end
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return end
    local plot = plots:FindFirstChild(animal.plot)
    if not plot then return end
    local podiums = plot:FindFirstChild("AnimalPodiums")
    if not podiums then return end
    local podium = podiums:FindFirstChild(animal.slot)
    if not podium then return end
    local function findPetModel(parent, depth)
        depth = depth or 0
        if depth > 5 then return nil end
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("Model") then
                if child:FindFirstChild("Humanoid") or child:FindFirstChild("Head") then return child end
                local found = findPetModel(child, depth + 1)
                if found then return found end
            end
        end
    end
    local petModel = findPetModel(podium)
    if petModel then return petModel end
    for _, child in ipairs(podium:GetChildren()) do
        if child:IsA("Model") then return child end
    end
    local base = podium:FindFirstChild("Base")
    if base then
        local spawn = base:FindFirstChild("Spawn")
        if spawn then
            for _, child in ipairs(spawn:GetChildren()) do
                if child:IsA("Model") then return child end
            end
        end
        for _, child in ipairs(base:GetChildren()) do
            if child:IsA("Model") then return child end
        end
    end
    return plot
end

local function getAttachPart(petModel)
    if not petModel then return nil end
    if petModel:IsA("Model") then
        return petModel.PrimaryPart
            or petModel:FindFirstChild("Head")
            or petModel:FindFirstChild("HumanoidRootPart")
            or petModel:FindFirstChild("UpperTorso")
            or petModel:FindFirstChild("LowerTorso")
            or petModel:FindFirstChild("Torso")
            or petModel:FindFirstChildWhichIsA("BasePart")
    end
    return petModel
end

local function clearESP()
    if espBestCurrent then
        removeBeam()
        pcall(function() espBestCurrent.Billboard:Destroy() end)
        espBestCurrent = nil
    end
end

local function updateESPValue()
    if not espBestCurrent or not espBestCurrent.Billboard then return end
    local animal = espBestCurrent.animal
    if not animal then return end
    local nameLabel = espBestCurrent.Billboard:FindFirstChild("Name")
    if nameLabel then nameLabel.Text = animal.name or "Desconhecido" end
    local valueLabel = espBestCurrent.Billboard:FindFirstChild("Value")
    if valueLabel and _NumberUtils then
        valueLabel.Text = "$" .. _NumberUtils:ToString(animal.gen) .. "/s"
    end
end

local function createESP(animal)
    clearESP()
    local petModel = getPetModel(animal)
    if not petModel then return end
    local esp = { animal = animal }
    local attachPart = getAttachPart(petModel) or petModel
    updateBeam(animal, petModel)
    
    local realName     = animal.name or "Desconhecido"
    local formattedVal = _NumberUtils and ("$" .. _NumberUtils:ToString(animal.gen) .. "/s") or tostring(animal.gen)
    
    local ok, bb = pcall(function()
        local billboard = Instance.new("BillboardGui")
        billboard.Adornee = attachPart
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(0, 200, 0, 30)
        billboard.StudsOffset = Vector3.new(0, 2.0, 0)
        billboard.Parent = espBestGui
        return billboard
    end)
    if not ok then return end
    esp.Billboard = bb
    
    pcall(function()
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "Name"
        nameLabel.Size = UDim2.new(1, 0, 0, 14)
        nameLabel.Position = UDim2.new(0, 0, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = realName
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 11
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextStrokeTransparency = 0.5
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLabel.TextXAlignment = Enum.TextXAlignment.Center
        nameLabel.Parent = bb
        
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Name = "Value"
        valueLabel.Size = UDim2.new(1, 0, 0, 14)
        valueLabel.Position = UDim2.new(0, 0, 0, 15)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = formattedVal
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.TextSize = 12
        valueLabel.TextColor3 = Color3.fromRGB(60, 255, 100)
        valueLabel.TextStrokeTransparency = 0.5
        valueLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        valueLabel.TextXAlignment = Enum.TextXAlignment.Center
        valueLabel.Parent = bb
    end)
    espBestCurrent = esp
end

local function setupBeamReconnect()
    JogadorLocal.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if espBestEnabled and espBestCurrent and espBestCurrent.animal then
            local petModel = getPetModel(espBestCurrent.animal)
            if petModel then
                removeBeam()
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    local targetPart = petModel.PrimaryPart or petModel:FindFirstChildWhichIsA("BasePart")
                    if targetPart then
                        local attA = Instance.new("Attachment")
                        attA.Name = "BeamOrigin"
                        attA.Parent = root
                        
                        local attB = Instance.new("Attachment")
                        attB.Name = "BeamTarget"
                        attB.Parent = targetPart
                        
                        local beam = Instance.new("Beam")
                        beam.Name = "MuzanBeam"
                        beam.Attachment0 = attA
                        beam.Attachment1 = attB
                        beam.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200,200,200)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255)) })
                        beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.5, 0.4), NumberSequenceKeypoint.new(1, 0.1) })
                        beam.Width0 = 0.12
                        beam.Width1 = 0.12
                        beam.Segments = 20
                        beam.CurveSize0 = 0
                        beam.CurveSize1 = 0
                        beam.FaceCamera = true
                        beam.LightEmission = 1
                        beam.LightInfluence = 0
                        beam.TextureLength = 2
                        beam.TextureSpeed = 1
                        beam.Parent = root
                        
                        BeamState.beam = beam
                        BeamState.attOrigin = attA
                        BeamState.attTarget = attB
                        BeamState.currentUID = espBestCurrent.animal.uid
                    end
                end
            end
        end
    end)
end

local function getInternalTable()
    local Packages = ReplicatedStorage:FindFirstChild("Packages")
    if not Packages then return nil end
    
    local SynchronizerModule = Packages:FindFirstChild("Synchronizer")
    if not SynchronizerModule then return nil end
    
    local success, synchronizer = pcall(require, SynchronizerModule)
    if not success or not synchronizer then return nil end
    
    local GetMethod = synchronizer.Get
    if type(GetMethod) ~= "function" then return nil end
    
    for i = 1, 5 do
        local success, upvalue = pcall(getupvalue, GetMethod, i)
        if success and type(upvalue) == "table" then
            if upvalue.___private or upvalue.___channels or upvalue.___data then
                return upvalue
            end
            for k, v in pairs(upvalue) do
                if type(k) == "string" and k:match("^Plot_") or type(v) == "table" then
                    return upvalue
                end
            end
        end
    end
    
    local success, env = pcall(getfenv, GetMethod)
    if success and env and env.self then
        return env.self
    end
    
    return nil
end

local SynchronizerInternal = {
    _cache = {},
    _dataTable = nil
}

task.spawn(function()
    local attempts = 0
    while attempts < 10 and not SynchronizerInternal._dataTable do
        SynchronizerInternal._dataTable = getInternalTable()
        if not SynchronizerInternal._dataTable then
            task.wait(1)
            attempts = attempts + 1
        end
    end
end)

local function stealthGet(plotName)
    if not plotName or type(plotName) ~= "string" then return nil end
    if SynchronizerInternal._cache[plotName] == false then return nil end
    
    if SynchronizerInternal._dataTable then
        local keys = {
            plotName,
            "Plot_" .. plotName,
            "Plot" .. plotName,
            plotName .. "_Channel",
            "Channel_" .. plotName
        }
        
        for _, key in ipairs(keys) do
            if SynchronizerInternal._dataTable[key] then
                SynchronizerInternal._cache[plotName] = SynchronizerInternal._dataTable[key]
                return SynchronizerInternal._dataTable[key]
            end
        end
        
        for k, v in pairs(SynchronizerInternal._dataTable) do
            if type(k) == "string" and (k == plotName or k:find(plotName, 1, true)) then
                if type(v) == "table" then
                    SynchronizerInternal._cache[plotName] = v
                    return v
                end
            end
        end
    end
    
    SynchronizerInternal._cache[plotName] = false
    return nil
end

local function stealthGetFromChannel(channel, key)
    if not channel then return nil end
    
    local success, value = pcall(function()
        return channel:Get(key)
    end)
    
    if success then return value end
    
    success, value = pcall(function()
        if channel.Get and type(channel.Get) == "function" then
            return channel:Get(key)
        elseif channel.get and type(channel.get) == "function" then
            return channel:get(key)
        elseif rawget(channel, key) then
            return rawget(channel, key)
        end
    end)
    
    if success then return value end
    return nil
end

local function stealthGetProperty(channel, key)
    if not channel then return nil end
    
    local success, value = pcall(function()
        return channel[key]
    end)
    
    if success then return value end    
    return stealthGetFromChannel(channel, key)
end

local function isMyBaseAnimal(animalData)
    if not animalData or not animalData.plot then
        return false
    end
    
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then
        return false
    end
    
    local plot = plots:FindFirstChild(animalData.plot)
    if not plot then
        return false
    end
    
    local channel = stealthGet(plot.Name)
    if channel then
        local owner = stealthGetProperty(channel, "Owner")
        if owner then
            if typeof(owner) == "Instance" and owner:IsA("Player") then
                return owner.UserId == JogadorLocal.UserId
            elseif typeof(owner) == "table" and owner.UserId then
                return owner.UserId == JogadorLocal.UserId
            elseif typeof(owner) == "Instance" then
                return owner == JogadorLocal
            end
        end
    end
    
    local sign = plot:FindFirstChild("PlotSign")
    if sign then
        local yourBase = sign:FindFirstChild("YourBase")
        if yourBase and yourBase:IsA("BillboardGui") then
            return yourBase.Enabled == true
        end
    end
    
    return false
end

local _plotWatchers = {}

local function _clearPlotAnimals(plotName)
    for uid, animal in pairs(espBestAnimals) do
        if animal.plot == plotName then
            espBestAnimals[uid] = nil
        end
    end
end

local function _processPlotData(plot)
    if not _AnimalsShared or not _AnimalsData then return end
    local plotName = plot.Name

    if _myPlotName == nil then
        local sign = plot:FindFirstChild("PlotSign")
        if sign then
            local yourBase = sign:FindFirstChild("YourBase")
            if yourBase and yourBase:IsA("BillboardGui") and yourBase.Enabled then
                _myPlotName = plotName
            end
        end
        if _myPlotName == nil then
            local tempAnimal = {plot = plotName}
            if isMyBaseAnimal(tempAnimal) then
                _myPlotName = plotName
            end
        end
    end

    if plotName == _myPlotName then
        _clearPlotAnimals(plotName)
        return
    end

    local channel = stealthGet(plotName)
    if not channel then _clearPlotAnimals(plotName) return end

    local list = stealthGetFromChannel(channel, "AnimalList")
    if not list then _clearPlotAnimals(plotName) return end

    local currentAnimals = {}

    for slot, data in pairs(list) do
        if type(data) ~= "table" then continue end
        local uid = plotName .. "_" .. slot
        currentAnimals[uid] = true

        local existing = espBestAnimals[uid]
        if existing then
            local ok, newGen = pcall(function()
                return _AnimalsShared:GetGeneration(data.Index, data.Mutation, data.Traits, nil)
            end)
            if ok and newGen then
                existing.gen = newGen
            end
        else
            local info = _AnimalsData[data.Index]
            if not info then continue end
            local ok, gen = pcall(function()
                return _AnimalsShared:GetGeneration(data.Index, data.Mutation, data.Traits, nil)
            end)
            if not ok or not gen then continue end
            local animalName = tostring(info.DisplayName or data.Index)
            animalName = animalName:gsub("_", " "):gsub("%s+", " "):gsub("^%l", string.upper)
            local spawnPart = nil
            local prompt = nil
            local podiums = plot:FindFirstChild("AnimalPodiums")
            if podiums then
                local pod = podiums:FindFirstChild(tostring(slot))
                if pod then
                    local base = pod:FindFirstChild("Base")
                    local sp = base and base:FindFirstChild("Spawn")
                    if sp then
                        spawnPart = sp
                        local att = sp:FindFirstChild("PromptAttachment")
                        if att then
                            for _, child in ipairs(att:GetChildren()) do
                                if child:IsA("ProximityPrompt") then prompt = child; break end
                            end
                        end
                    end
                end
            end
            espBestAnimals[uid] = {
                uid          = uid,
                name         = animalName,
                gen          = gen,
                plot         = plotName,
                slot         = tostring(slot),
                spawnPart    = spawnPart,
                prompt       = prompt,
                isNotMyPlot  = true,
                index        = data.Index,
            }
        end
    end

    for uid, animal in pairs(espBestAnimals) do
        if animal.plot == plotName and not currentAnimals[uid] then
            espBestAnimals[uid] = nil
        end
    end
end

local function findBestAnimal()
    local best, bestVal = nil, 0
    for _, animal in pairs(espBestAnimals) do
        local g = tonumber(animal.gen) or 0
        if g > bestVal then bestVal = g; best = animal end
    end
    return best
end

local function recompute()
    local best = findBestAnimal()
    if not best then
        if espBestCurrent then clearESP() end
        return
    end
    if not espBestCurrent or best.uid ~= espBestCurrent.animal.uid then
        createESP(best)
    elseif best.gen ~= espBestCurrent.animal.gen then
        espBestCurrent.animal.gen = best.gen
        updateESPValue()
    end
end

local function _watchPlot(plot)
    local plotName = plot.Name
    if _plotWatchers[plotName] then return end

    _processPlotData(plot)
    recompute()

    local podiums = plot:FindFirstChild("AnimalPodiums")
    if not podiums then return end

    local conn = podiums.ChildAdded:Connect(function(child)
        if child:IsA("Model") and not child.PrimaryPart then
            child:GetPropertyChangedSignal("PrimaryPart"):Wait()
        end
        _processPlotData(plot)
        recompute()
    end)
    local conn2 = podiums.ChildRemoved:Connect(function()
        _processPlotData(plot)
        recompute()
    end)

    _plotWatchers[plotName] = { conn, conn2 }
end

local function _unwatchPlot(plotName)
    local watchers = _plotWatchers[plotName]
    if watchers then
        for _, c in ipairs(watchers) do pcall(function() c:Disconnect() end) end
        _plotWatchers[plotName] = nil
    end
    _clearPlotAnimals(plotName)
end

local function toggleESPBest(estado)
    espBestEnabled = estado

    if not estado then
        for name, _ in pairs(_plotWatchers) do
            _unwatchPlot(name)
        end
        if espBestGui then
            pcall(function() espBestGui:Destroy() end)
            espBestGui = nil
        end
        for _, conn in ipairs(espBestUpdate) do
            pcall(function() conn:Disconnect() end)
        end
        espBestUpdate = {}
        clearESP()
        for k in pairs(espBestAnimals) do espBestAnimals[k] = nil end
        _myPlotName = nil
        return
    end

    espBestGui = Instance.new("ScreenGui")
    espBestGui.Name = "StealthHighestESP"
    espBestGui.ResetOnSpawn = false
    espBestGui.DisplayOrder = 999999
    espBestGui.Parent = JogadorLocal:WaitForChild("PlayerGui")

    setupBeamReconnect()

    espBestUpdate = {}

    task.spawn(function()
        _loadModules()

        local plots = Workspace:WaitForChild("Plots")
        if not plots then return end

        for _, plot in ipairs(plots:GetChildren()) do
            if plot:IsA("Model") then
                _watchPlot(plot)
            end
        end

        local addedConn = plots.ChildAdded:Connect(function(plot)
            if not espBestEnabled then return end
            if plot:IsA("Model") then
                _watchPlot(plot)
                recompute()
            end
        end)
        table.insert(espBestUpdate, addedConn)

        local removedConn = plots.ChildRemoved:Connect(function(plot)
            _unwatchPlot(plot.Name)
            recompute()
        end)
        table.insert(espBestUpdate, removedConn)

        local lastGenRefresh = 0
        local genRefreshConn = RunService.Heartbeat:Connect(function()
            if not espBestEnabled then return end
            local now = tick()
            if now - lastGenRefresh < 0.3 then return end
            lastGenRefresh = now
            for _, plot in ipairs(plots:GetChildren()) do
                if plot:IsA("Model") then
                    _processPlotData(plot)
                end
            end
            recompute()
        end)
        table.insert(espBestUpdate, genRefreshConn)
    end)
end

local uiGui = Instance.new("ScreenGui")
uiGui.Name = "MuzanBestUI"
uiGui.ResetOnSpawn = false
uiGui.Parent = JogadorLocal:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 100, 0, 50)
main.Position = UDim2.new(0, 10, 0, 10)
main.BackgroundColor3 = colors.bg
main.BackgroundTransparency = 0.3
main.BorderSizePixel = 0
main.Parent = uiGui
corner(main, 6)
stroke(main, colors.stroke, 1)
waveBorder(main, 1.5)

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 18)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Flow esp brain"
title.Font = Enum.Font.GothamBold
title.TextSize = 11
title.TextColor3 = colors.text
title.Parent = main
waveText(title)

local separator = Instance.new("Frame")
separator.Name = "Separator"
separator.Size = UDim2.new(1, -10, 0, 1)
separator.Position = UDim2.new(0, 5, 0, 18)
separator.BackgroundColor3 = colors.separator
separator.BorderSizePixel = 0
separator.Parent = main

local toggleContainer = Instance.new("Frame")
toggleContainer.Name = "ToggleContainer"
toggleContainer.Size = UDim2.new(1, 0, 1, -19)
toggleContainer.Position = UDim2.new(0, 0, 0, 19)
toggleContainer.BackgroundTransparency = 1
toggleContainer.Parent = main

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleBtn"
toggleBtn.Size = UDim2.new(0, 70, 0, 20)
toggleBtn.Position = UDim2.new(0.5, -35, 0.5, -10)
toggleBtn.BackgroundColor3 = colors.btn
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "OFF"
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 10
toggleBtn.TextColor3 = colors.text
toggleBtn.Parent = toggleContainer
corner(toggleBtn, 4)
stroke(toggleBtn, colors.stroke, 1)

local isEnabled = false

toggleBtn.MouseEnter:Connect(function()
    if not isEnabled then
        toggleBtn.BackgroundColor3 = colors.btnHover
    end
end)

toggleBtn.MouseLeave:Connect(function()
    if not isEnabled then
        toggleBtn.BackgroundColor3 = colors.btn
    else
        toggleBtn.BackgroundColor3 = colors.pillOn
    end
end)

toggleBtn.MouseButton1Down:Connect(function()
    toggleBtn.BackgroundColor3 = colors.btnPress
end)

toggleBtn.MouseButton1Click:Connect(function()
    isEnabled = not isEnabled
    if isEnabled then
        toggleBtn.Text = "ON"
        toggleBtn.BackgroundColor3 = colors.pillOn
        toggleESPBest(true)
    else
        toggleBtn.Text = "OFF"
        toggleBtn.BackgroundColor3 = colors.btn
        toggleESPBest(false)
    end
end)

makeDraggable(main, title)