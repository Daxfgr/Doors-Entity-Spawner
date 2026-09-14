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
                entity.Model.Missing:Stop()
                entity:Pause()

                local model = entity.Model
                local target = model.RipperNew
                local attachment = target.Attachment
                local static = attachment.Static.ParticleEmmiter
                local ripper = attachment.Ripper
                local face = ripper.Face
                local jumpscareFace = ripper["Jumpscare Face"]
                local jumpscareSound = model.Jumpscare
                local staticSound = model.Static

                static.TimeScale = 0
                jumpscareFace.TimeScale = 0
                face.Enabled = false
                jumpscareFace.Enabled = true

                local players = game:GetService("Players")
                local runService = game:GetService("RunService")
                local player = players.LocalPlayer
                local camera = workspace.CurrentCamera
                local targetPosition = target:IsA("BasePart") and target.Position or target:GetPivot().Position

                if camera then
                    local startCFrame = camera.CFrame
                    local targetCFrame = CFrame.lookAt(camera.CFrame.Position, targetPosition)
                    local startTime = os.clock()

                    while true do
                        local alpha = math.clamp((os.clock() - startTime) / 1, 0, 1)
                        camera.CFrame = startCFrame:Lerp(targetCFrame, alpha)

                        if alpha >= 1 then
                            break
                        end

                        runService.RenderStepped:Wait()
                    end
                end

                jumpscareSound:Play()
                task.wait(1)

                staticSound.Volume = 0
                staticSound:Play()

                local fadeInStart = os.clock()
                while true do
                    local alpha = math.clamp((os.clock() - fadeInStart) / 1, 0, 1)
                    staticSound.Volume = 10 * alpha

                    if alpha >= 1 then
                        break
                    end

                    runService.Heartbeat:Wait()
                end

                task.wait(2)

                local fadeOutStart = os.clock()
                while true do
                    local alpha = math.clamp((os.clock() - fadeOutStart) / 1, 0, 1)
                    staticSound.Volume = 10 * (1 - alpha)

                    if alpha >= 1 then
                        break
                    end

                    runService.Heartbeat:Wait()
                end

                staticSound.Volume = 0
                entity:Fall()
                DamagePlayer(entity)
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
