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

---====== Sounds ======---

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
	local RunService = game:GetService("RunService")
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
			originalCameraSubject = camera.CameraSubject
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

	local deathStarted = false

	task.spawn(function()
		DamagePlayer(entity)
		deathStarted = true
	end)

	while not deathStarted do
		RunService.Heartbeat:Wait()

		if not model.Parent then
			return
		end

		local character = LocalPlayer and LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		if humanoid and humanoid.Health <= 0 then
			deathStarted = true
		end
	end

	model:SetAttribute("Despawning", true)

	local fallSpeed = entity.Config.Movement.Speed
	local targetCFrame = model:GetPivot() - Vector3.new(0, 300, 0)
	local reached = false

	if controls then
		controls:Enable()
		controls = nil
	end

	fadeOut:Play()

	local connection
	connection = RunService.Stepped:Connect(function(_, step)
		if not model.Parent then
			connection:Disconnect()
			reached = true
			return
		end

		local pivot = model:GetPivot()
		local difference = targetCFrame.Position - pivot.Position
		local magnitude = difference.Magnitude

		if magnitude > 0.1 then
			local unit = difference.Unit

			model:PivotTo(
				pivot + unit * math.min(step * fallSpeed, magnitude)
			)
		else
			connection:Disconnect()
			reached = true
		end
	end)

	repeat
		RunService.Stepped:Wait()
	until reached

	if model.Parent then
		entity:Despawn()
	end

	while model.Parent do
		RunService.Heartbeat:Wait()
	end

	staticSound.Volume = 0
	jumpscareFace.RotSpeed = originalRotSpeed

	if LocalPlayer then
		local camera = workspace.CurrentCamera

		if camera then
			camera.CameraType = originalCameraType or Enum.CameraType.Custom
			camera.CameraSubject = originalCameraSubject
		end
	end

	RestoreSounds()
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
