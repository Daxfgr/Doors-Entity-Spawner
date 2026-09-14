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
                local players = game:GetService("Players")
                local runService = game:GetService("RunService")
                local player = players.LocalPlayer
                local camera = workspace.CurrentCamera
                local pausedSounds = {}

                for _, object in ipairs(game:GetDescendants()) do
                    if object:IsA("Sound") and object.Playing then
                        table.insert(pausedSounds, object)
                        object:Pause()
                    end
                end

                local function resumePausedSounds()
                    for _, sound in ipairs(pausedSounds) do
                        if sound.Parent then
                            sound:Resume()
                        end
                    end
                end

                entity.Model.Missing:Stop()
                entity:Pause()

                local model = entity.Model
                local target = model.RipperNew
                local attachment = target.Attachment
                local staticParticleEmitter = attachment.Static.ParticleEmitter
                local ripper = attachment.Ripper
                local face = ripper.Face
                local jumpscareFace = ripper["Jumpscare Face"]
                local jumpscareSound = model.Jumpscare
                local staticSound = model.Static

                staticParticleEmitter.TimeScale = 0
                face.Enabled = false
                jumpscareFace.Enabled = true

                local targetPosition

                if target:IsA("BasePart") then
                    targetPosition = target.Position
                else
                    targetPosition = target:GetPivot().Position
                end

                local cameraLockName = "RipperJumpscareCamera"

                if camera then
                    local startCFrame = camera.CFrame
                    local startTime = os.clock()
                    local directionToTarget = (
                        targetPosition - camera.CFrame.Position
                    ).Unit

                    local facingDot = camera.CFrame.LookVector:Dot(
                        directionToTarget
                    )

                    local duration = facingDot < 0 and 0.35 or 1

                    camera.CameraType = Enum.CameraType.Scriptable

                    runService:BindToRenderStep(
                        cameraLockName,
                        Enum.RenderPriority.Camera.Value + 1,
                        function()
                            if not camera then
                                return
                            end

                            local alpha = math.clamp(
                                (os.clock() - startTime) / duration,
                                0,
                                1
                            )

                            local position = camera.CFrame.Position
                            local lookCFrame = CFrame.lookAt(
                                position,
                                targetPosition
                            )

                            camera.CFrame = startCFrame:Lerp(
                                lookCFrame,
                                alpha
                            )
                        end
                    )

                    task.wait(duration)

                    camera.CFrame = CFrame.lookAt(
                        camera.CFrame.Position,
                        targetPosition
                    )
                end

                task.wait(0.2)

                jumpscareFace.TimeScale = 0

                jumpscareSound:Play()

                task.wait(1)

                staticSound.Volume = 0
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

                    runService.Heartbeat:Wait()
                end

                task.wait(2)

                local fadeOutStart = os.clock()

                while true do
                    local alpha = math.clamp(
                        (os.clock() - fadeOutStart) / 1,
                        0,
                        1
                    )

                    staticSound.Volume = 10 * (1 - alpha)

                    if alpha >= 1 then
                        break
                    end

                    runService.Heartbeat:Wait()
                end

                staticSound.Volume = 0

                local fallStart = model:GetPivot()
                local fallStartTime = os.clock()
                local fallDuration = 0.5

                while model.Parent do
                    local alpha = math.clamp(
                        (os.clock() - fallStartTime) / fallDuration,
                        0,
                        1
                    )

                    model:PivotTo(
                        fallStart:Lerp(
                            fallStart - Vector3.new(0, 300, 0),
                            alpha
                        )
                    )

                    if alpha >= 1 then
                        break
                    end

                    runService.RenderStepped:Wait()
                end

                local humanoid = player.Character
                    and player.Character:FindFirstChildOfClass("Humanoid")

                if humanoid then
                    local deathConnection

                    deathConnection = humanoid.Died:Connect(function()
                        resumePausedSounds()

                        if deathConnection then
                            deathConnection:Disconnect()
                            deathConnection = nil
                        end
                    end)

                    DamagePlayer(entity)

                    if humanoid.Health <= 0 then
                        resumePausedSounds()

                        if deathConnection then
                            deathConnection:Disconnect()
                            deathConnection = nil
                        end
                    end
                else
                    DamagePlayer(entity)
                    resumePausedSounds()
                end

                if camera then
                    runService:UnbindFromRenderStep(cameraLockName)
                    camera.CameraType = Enum.CameraType.Custom
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
