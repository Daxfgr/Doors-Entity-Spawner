entity:Pause()
local ripperNew = entity.model.RipperNew
local jumpscare = entity.model.Jumpscare
local static = entity.model.Static
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:FindFirstChild("HumanoidRootPart")
if root then
    local startCFrame = root.CFrame
    local targetCFrame = CFrame.lookAt(root.Position, ripperNew.Position)
    local startTime = os.clock()
    while true do
        local alpha = math.clamp((os.clock() - startTime) / 1, 0, 1)
        root.CFrame = startCFrame:Lerp(targetCFrame, alpha)
        if alpha >= 1 then
            break
        end
        task.wait()
    end
end
local attachment = ripperNew:FindFirstChild("Attachment")
if attachment then
    local ripper = attachment:FindFirstChild("Ripper")
    if ripper then
        local face = ripper:FindFirstChild("Face")
        if face and face:IsA("ParticleEmitter") then
            face.Enabled = false
        end
        local jumpscareFace = ripper:FindFirstChild("Jumpscare Face")
        if jumpscareFace and jumpscareFace:IsA("ParticleEmitter") then
            jumpscareFace.Enabled = true
            jumpscareFace.TimeScale = 0
        end
    end
    local staticParticle = attachment:FindFirstChild("Static")
    if staticParticle then
        local particleEmitter = staticParticle:FindFirstChildWhichIsA("ParticleEmitter")
        if particleEmitter then
            particleEmitter.TimeScale = 0
        end
    end
end
jumpscare:Play()
task.wait(1)
static.Volume = 0
static:Play()
local startTime = os.clock()
while true do
    local alpha = math.clamp((os.clock() - startTime) / 1, 0, 1)
    static.Volume = alpha * 10
    if alpha >= 1 then
        break
    end
    task.wait()
end
task.wait(2)
local startTime = os.clock()
while true do
    local alpha = math.clamp((os.clock() - startTime) / 1, 0, 1)
    static.Volume = 10 * (1 - alpha)
    if alpha >= 1 then
        break
    end
    task.wait()
end
static.Volume = 0
workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
entity:Fall()
DamagePlayer(entity)
