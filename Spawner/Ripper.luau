---====== Load spawner ======---

local source = game:HttpGet(
    "https://raw.githubusercontent.com/Daxfgr/Doors-Entity-Spawner/refs/heads/main/Spawner/init.luau"
)

local function replaceOnce(text, oldText, newText)
    local startPosition, endPosition = string.find(text, oldText, 1, true)

    if not startPosition then
        error("Target code was not found")
    end

    return string.sub(text, 1, startPosition - 1)
        .. newText
        .. string.sub(text, endPosition + 1)
end

source = replaceOnce(
    source,
    "Modules.Module_Events.flicker(currentRoom, config.Lights.Flicker.Duration)",
    [[task.delay(1, function()
            Modules.Module_Events.flicker(currentRoom, config.Lights.Flicker.Duration)
        end)]]
)

source = replaceOnce(
    source,
    "task.spawn(Earthquake)",
    [[task.delay(1, function()
                task.spawn(Earthquake)
            end)]]
)

local Spawner = loadstring(source)()

---====== Create entity ======---

task.spawn(function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/Daxfgr/Doors-Entity-Spawner/refs/heads/main/Spawner/RipperEffect.luau"))()
end)

local entity = Spawner:Create({
	Entity = {
		Name = "Ripper",
        Asset = getcustomasset("Assets/Ripper.rbxm", true),
		HeightOffset = 2
	},
	Lights = {
		Flicker = {
			Enabled = true, -- "true" -- "false"
			Duration = 3
		},
		Shatter = false, -- "true" -- "false"
		Repair = false -- "true" -- "false"
	},
	Earthquake = {
		Enabled = true -- "true" -- "false"
	},
	CameraShake = {
		Enabled =true, -- "true" -- "false"
		Range = 54,
		Values = {1.5, 20, 0.1, 1} -- Magnitude, Roughness, FadeIn, FadeOut
	},
	Movement = {
		Speed = 125,
		Delay = 8,
		Reversed = false -- "true" -- "false"
	},
	Rebounding = {
		Enabled = false, -- "true" -- "false"
		Type = "Ambush", -- "Ambush" -- "Blitz"
		Min = 0,
		Max = 0,
		Delay = 0
	},
	Jumpscare = {
		Enabled = true,

		Damage = {
			Range = 54,
			Amount = 125,
			IgnoreHiding = false -- "true" -- "false"
		},

		Action = function(entity, DamagePlayer)
    task.spawn(function()
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        local player = Players.LocalPlayer
        local camera = workspace.CurrentCamera
        local model = entity.Model
        local pausedSounds = {}
        local cameraLockName = "RipperJumpscareCamera"
        local cameraReleased = false
        local deathHandled = false
        local deathConnection

        for _, object in ipairs(game:GetDescendants()) do
            if object:IsA("Sound") and object.Playing then
                table.insert(pausedSounds, object)
                object:Pause()
            end
        end

        local function resumeSounds()
            for _, sound in ipairs(pausedSounds) do
                if sound.Parent then
                    sound:Resume()
                end
            end
        end

        local function releaseCamera()
            if cameraReleased then
                return
            end

            cameraReleased = true

            if camera then
                local currentCFrame = camera.CFrame

                RunService:UnbindFromRenderStep(cameraLockName)

                camera.CameraType = Enum.CameraType.Scriptable
                camera.CFrame = currentCFrame
            end
        end

        local function fallAndDespawn()
            if not model or not model.Parent then
                return
            end

            local startCFrame = model:GetPivot()
            local startTime = os.clock()
            local fallDuration = 0.5

            while model.Parent do
                local alpha = math.clamp(
                    (os.clock() - startTime) / fallDuration,
                    0,
                    1
                )

                model:PivotTo(
                    startCFrame - Vector3.new(0, 300, 0) * alpha
                )

                if alpha >= 1 then
                    break
                end

                RunService.RenderStepped:Wait()
            end

            if model.Parent then
                entity:Despawn()
            end
        end

        local function handleDeath()
            if deathHandled then
                return
            end

            deathHandled = true

            releaseCamera()
            resumeSounds()

            task.spawn(fallAndDespawn)

            if deathConnection then
                deathConnection:Disconnect()
                deathConnection = nil
            end
        end

        entity.Model.Missing:Stop()
        entity:Pause()

        local target = model:WaitForChild("RipperNew")
        local attachment = target:WaitForChild("Attachment")
        local staticParticleEmitter = attachment.Static:WaitForChild("ParticleEmitter")
        local ripper = attachment:WaitForChild("Ripper")
        local face = ripper:WaitForChild("Face")
        local jumpscareFace = ripper:WaitForChild("Jumpscare Face")
        local jumpscareSound = model:WaitForChild("Jumpscare")
        local staticSound = model:WaitForChild("Static")

        local localAudioPath = "Assets/Ripper Jumpscare.mp3"
        local localAudioId = getcustomasset(localAudioPath, true)

        jumpscareSound.SoundId = localAudioId
        jumpscareSound.Volume = 10
        jumpscareSound.Looped = false

        local humanoid = player.Character
            and player.Character:FindFirstChildOfClass("Humanoid")

        if humanoid then
            deathConnection = humanoid.Died:Connect(handleDeath)
        end

        staticParticleEmitter.TimeScale = 0
        face.Enabled = false
        jumpscareFace.Enabled = true
        jumpscareFace.TimeScale = 1

        task.wait(0.1)

        if jumpscareFace.Parent then
            jumpscareFace.TimeScale = 0
        end

        local targetPosition

        if target:IsA("BasePart") then
            targetPosition = target.Position
        else
            targetPosition = target:GetPivot().Position
        end

        if camera then
            local startCFrame = camera.CFrame
            local startTime = os.clock()
            local cameraDuration = 0.1

            camera.CameraType = Enum.CameraType.Scriptable

            RunService:BindToRenderStep(
                cameraLockName,
                Enum.RenderPriority.Camera.Value + 1,
                function()
                    if cameraReleased or not camera or not target.Parent then
                        return
                    end

                    local currentTargetPosition

                    if target:IsA("BasePart") then
                        currentTargetPosition = target.Position
                    else
                        currentTargetPosition = target:GetPivot().Position
                    end

                    local alpha = math.clamp(
                        (os.clock() - startTime) / cameraDuration,
                        0,
                        1
                    )

                    local currentPosition = camera.CFrame.Position
                    local targetCFrame = CFrame.lookAt(
                        currentPosition,
                        currentTargetPosition
                    )

                    if alpha < 1 then
                        camera.CFrame = startCFrame:Lerp(
                            targetCFrame,
                            alpha
                        )
                    else
                        camera.CFrame = targetCFrame
                    end
                end
            )

            task.wait(cameraDuration)

            if not cameraReleased and target.Parent then
                camera.CFrame = CFrame.lookAt(
                    camera.CFrame.Position,
                    targetPosition
                )
            end
        end

        jumpscareSound:Stop()
        jumpscareSound.TimePosition = 0
        jumpscareSound:Play()

        task.wait(1)

        staticSound:Stop()
        staticSound.Volume = 0
        staticSound.TimePosition = 0
        staticSound:Play()

        local fadeInStart = os.clock()

        while true do
            local alpha = math.clamp(
                (os.clock() - fadeInStart) / 1,
                0,
                1
            )

            staticSound.Volume = 10 * alpha

            if alpha >= 1 then
                break
            end

            RunService.Heartbeat:Wait()
        end

        task.wait(1)

        DamagePlayer(entity)

        local fadeOutStart = os.clock()
        local fadeOutDuration = 0.5

        while true do
            local alpha = math.clamp(
                (os.clock() - fadeOutStart) / fadeOutDuration,
                0,
                1
            )

            staticSound.Volume = 10 * (1 - alpha)

            if alpha >= 1 then
                break
            end

            RunService.Heartbeat:Wait()
        end

        staticSound.Volume = 0

        if humanoid then
            if humanoid.Health > 0 then
                humanoid.Died:Wait()
            end

            handleDeath()
        else
            handleDeath()
        end
    end)
end

	},
	Crucifixion = {
		Type = "Guiding", -- "Guiding"
		Enabled = true, -- "true" -- "false"
		Range = 54,
		Resist = false, -- "true" -- "false"
		Break = true -- "true" -- "false"
	},
	Death = {
		Type = "Guiding", -- "Guiding" -- "Curious"
		Hints = {"You died to who call Ripper.", "You can tell its presence by the lights and its scream.", "Hide when he comes by!", "Pay close attention next time."},
		Cause = "Ripper"
	}
})

---====== Debug entity ======---

entity:SetCallback("OnSpawned", function()
	print("Entity has spawned")
    entity.Model.RipperSpawn:Play()
end)

entity:SetCallback("OnStartMoving", function()
	print("Entity has started moving")
end)

entity:SetCallback("OnEnterRoom", function(room: Model, firstTime: boolean)
	if firstTime == true then
		print("Entity has entered room: " .. room.Name .. " for the first time")
	else
		print("Entity has entered room: " .. room.Name .. " again")
	end
end)

entity:SetCallback("OnLookAt", function(lineOfSight: boolean)
	if lineOfSight == true then
		print("Player is looking at entity")
	else
		print("Player view is obstructed by something")
	end
end)

entity:SetCallback("OnRebounding", function(startOfRebound: boolean)
	if startOfRebound == true then
		print("Entity has started rebounding")
	else
		print("Entity has finished rebounding")
	end
end)

entity:SetCallback("OnDespawning", function()
	print("Entity is despawning")
    entity.Model.Missing:Play()
end)

entity:SetCallback("OnDespawned", function()
	print("Entity has despawned")
end)

entity:SetCallback("OnDamagePlayer", function(newHealth: number)
	if newHealth <= 0 then
		print("Entity has killed the player")
	else
		print("Entity has damaged the player")
	end
end)

--[[

DEVELOPER NOTE:
By overwriting 'CrucifixionOverwrite' the default crucifixion callback will be replaced with your custom callback.

entity:SetCallback("CrucifixionOverwrite", function()
	print("Custom crucifixion callback")
end)

]]--

---====== Run entity ======---

entity:Run(true)
