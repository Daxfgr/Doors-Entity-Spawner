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
        local RunService = game:GetService("RunService")

        local model = entity.Model

        local target = model:WaitForChild("RipperNew")
        local attachment = target:WaitForChild("Attachment")
        local staticParticleEmitter = attachment.Static:WaitForChild("ParticleEmitter")
        local ripper = attachment:WaitForChild("Ripper")
        local face = ripper:WaitForChild("Face")
        local jumpscareFace = ripper:WaitForChild("Jumpscare Face")
        local jumpscareSound = model:WaitForChild("Jumpscare")
        local staticSound = model:WaitForChild("Static")

        local localAudioId = getcustomasset(
            "Assets/Ripper Jumpscare.mp3",
            true
        )

        jumpscareSound.SoundId = localAudioId
        jumpscareSound.Volume = 10
        jumpscareSound.Looped = false

        model.Missing:Stop()
        entity:Pause()

        staticParticleEmitter.TimeScale = 0

        face.Enabled = false
        jumpscareFace.Enabled = true
        jumpscareFace.TimeScale = 1

        RunService.Heartbeat:Wait()
        RunService.Heartbeat:Wait()

        jumpscareFace.Enabled = true
        jumpscareFace.TimeScale = 0

        jumpscareSound.TimePosition = 0
        jumpscareSound:Play()

        task.wait(1)

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

        task.wait(2)

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

        entity:Resume()

        local fallTarget = model:GetPivot()
            - Vector3.new(0, 300, 0)

        local reached = false
        local connection

        connection = RunService.Stepped:Connect(function(_, step)
            if not model.Parent then
                connection:Disconnect()
                reached = true
                return
            end

            if not model:GetAttribute("Paused") then
                local pivot = model:GetPivot()
                local difference = fallTarget.Position - pivot.Position
                local magnitude = difference.Magnitude

                if magnitude > 0.1 then
                    local direction = difference.Unit

                    model:PivotTo(
                        pivot + direction * math.min(
                            step * entity.Config.Movement.Speed,
                            magnitude
                        )
                    )
                else
                    model:PivotTo(fallTarget)
                    connection:Disconnect()
                    reached = true
                end
            end
        end)

        repeat
            RunService.Stepped:Wait()
        until reached or not model.Parent

        if connection then
            connection:Disconnect()
        end

        if model.Parent then
            entity:Despawn()
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
