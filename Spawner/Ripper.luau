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

source = replaceOnce(
    source,
    [[Despawn = function(self)
            if self:IsAlive() then
                self.Model:Destroy()
                local i = table.find(Module.ActiveEntities, self)
                if i then
                    table.remove(Module.ActiveEntities, i)
                end
                task.spawn(self.RunCallback, self, "OnDespawned")
            end
        end]],
    [[Despawn = function(self)
            if self:IsAlive() then
                self.Model:Destroy()
                local i = table.find(Module.ActiveEntities, self)
                if i then
                    table.remove(Module.ActiveEntities, i)
                end
                task.spawn(self.RunCallback, self, "OnDespawned")
            end
        end,
        JumpscareDespawn = function(self)
            if not self:IsAlive() then
                return
            end

            local model = self.Model
            local config = self.Config

            model:SetAttribute("Despawning", true)
            model:SetAttribute("Paused", false)

            task.spawn(self.RunCallback, self, "OnDespawning")

            EntityMoveTo(
                model,
                model:GetPivot() - Vector3.new(0, 300, 0),
                config.Movement.Speed
            )

            self:Despawn()
        end]]
)

local Spawner = loadstring(source)()

local TweenService = game:GetService("TweenService")
local originalVolumes = {}
local soundsMuted = false

local function MuteSounds()
    if soundsMuted then
        return
    end

    soundsMuted = true
    originalVolumes = {}

    for _, object in ipairs(game:GetDescendants()) do
        if object:IsA("Sound") and object.IsPlaying then
            originalVolumes[object] = object.Volume
            object.Volume = 0
        end
    end
end

local function RestoreSounds()
    for sound, volume in pairs(originalVolumes) do
        if sound and sound.Parent then
            sound.Volume = volume
        end
    end

    originalVolumes = {}
    soundsMuted = false
end

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
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer
	local model = entity.Model
	local attachment = model.RipperNew.Attachment

	entity:Pause()
	MuteSounds()

	local staticParticle = attachment.Static.ParticleEmitter
	local face = attachment.Ripper.Face
	local jumpscareFace = attachment.Ripper["Jumpscare Face"]

	local originalRotSpeed = jumpscareFace.RotSpeed
	local missingSound = model:FindFirstChild("Missing")

	if missingSound then
		missingSound.Volume = 0
	end

	local controls
	local originalCameraType
	local originalCameraSubject
	local blockGui
	local deathConnection

	if LocalPlayer then
		local PlayerModule = LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")

		if PlayerModule then
			controls = require(PlayerModule):GetControls()
			controls:Disable()
		end

		local camera = workspace.CurrentCamera

		if camera then
			originalCameraType = camera.CameraType
			originalCameraSubject = camera.CameraSubject
			camera.CameraType = Enum.CameraType.Scriptable
		end

		local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")

		if playerGui then
			blockGui = Instance.new("ScreenGui")
			blockGui.Name = "RipperJumpscareBlock"
			blockGui.IgnoreGuiInset = true
			blockGui.DisplayOrder = 1000000
			blockGui.ResetOnSpawn = false

			local block = Instance.new("TextButton")
			block.Size = UDim2.fromScale(1, 1)
			block.BackgroundTransparency = 1
			block.Text = ""
			block.AutoButtonColor = false
			block.Active = true
			block.Modal = true
			block.Parent = blockGui

			blockGui.Parent = playerGui
		end

		local character = LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			deathConnection = humanoid.Died:Connect(function()
				if deathConnection then
					deathConnection:Disconnect()
					deathConnection = nil
				end

				if blockGui then
					blockGui:Destroy()
					blockGui = nil
				end

				if controls then
					controls:Enable()
					controls = nil
				end
			end)
		end
	end

	staticParticle.TimeScale = 0
	face.Enabled = false
	jumpscareFace.Enabled = true
	jumpscareFace.TimeScale = 1
	jumpscareFace.RotSpeed = NumberRange.new(0)

	local amount = math.max(1, math.ceil(jumpscareFace.Rate * jumpscareFace.Lifetime.Max))
	jumpscareFace:Emit(amount)

	task.wait(0.1)

	jumpscareFace.TimeScale = 0

	local jumpscareAsset = getcustomasset("Assets/Ripper Jumpscare.mp3", true)
	local jumpscareSound = model.Jumpscare
	jumpscareSound.SoundId = jumpscareAsset
	jumpscareSound:Play()

	task.wait(1)

	local staticSound = model.Static
	staticSound.Volume = 0
	staticSound:Play()

	local fadeIn = TweenService:Create(
		staticSound,
		TweenInfo.new(1, Enum.EasingStyle.Linear),
		{Volume = 10}
	)

	fadeIn:Play()
	fadeIn.Completed:Wait()

	task.wait(1)

	local fadeOut = TweenService:Create(
		staticSound,
		TweenInfo.new(0.5, Enum.EasingStyle.Linear),
		{Volume = 0}
	)

	fadeOut:Play()
	DamagePlayer(entity)
	fadeOut.Completed:Wait()

	staticSound.Volume = 0

	jumpscareFace.RotSpeed = originalRotSpeed

	if controls then
		controls:Enable()
		controls = nil
	end

	if LocalPlayer then
		local camera = workspace.CurrentCamera

		if camera then
			camera.CameraType = originalCameraType or Enum.CameraType.Custom
			camera.CameraSubject = originalCameraSubject
		end
	end

	RestoreSounds()

	if entity:IsAlive() then
		entity:JumpscareDespawn()
	end
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
    RestoreSounds()
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
