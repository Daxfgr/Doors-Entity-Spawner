---====== Load spawner ======

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
    'entity:RunCallback("CrucifixionOverwrite")',
    'entity:RunCallback("CrucifixionOverwrite")\nCrucifixEntity(entity)'
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
		HeightOffset = 1
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
		Delay = 6,
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
    staticParticle.LockedToPart = true
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

	--====== RipperStatic ======--

	task.spawn(function()
		local gui = Instance.new("ScreenGui")
		gui.Name = "RipperStatic"
		gui.IgnoreGuiInset = true
		gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

		local image = Instance.new("ImageLabel")
		image.Name = "Static"
		image.Size = UDim2.fromScale(1, 1)
		image.Position = UDim2.fromScale(0, 0)
		image.BackgroundTransparency = 1
		image.ImageTransparency = 1
		image.BorderSizePixel = 0
		image.ScaleType = Enum.ScaleType.Stretch
		image.Parent = gui

		local images = {
			"rbxassetid://8482795900",
			"rbxassetid://236542974",
			"rbxassetid://184251462",
			"rbxassetid://236777652"
		}

		local running = true

		task.spawn(function()
			while running do
				for _, id in ipairs(images) do
					if not running then
						break
					end

					image.Image = id
					task.wait(0.03)
				end
			end
		end)

		local imageFadeIn = TweenService:Create(
			image,
			TweenInfo.new(1, Enum.EasingStyle.Linear),
			{ImageTransparency = 0}
		)

		imageFadeIn:Play()
		imageFadeIn.Completed:Wait()

		task.wait(1)

		running = false

		local imageFadeOut = TweenService:Create(
			image,
			TweenInfo.new(1, Enum.EasingStyle.Linear),
			{ImageTransparency = 1}
		)

		imageFadeOut:Play()
		imageFadeOut.Completed:Wait()

		gui:Destroy()
	end)

	fadeIn.Completed:Wait()

	task.wait(1)

	local fadeOut = TweenService:Create(
		staticSound,
		TweenInfo.new(1, Enum.EasingStyle.Linear),
		{Volume = 0}
	)

	fadeOut:Play()

	local falling = false

	task.spawn(function()
		DamagePlayer(entity)
	end)

	task.spawn(function()
		while model.Parent and not falling do
			local character = LocalPlayer and LocalPlayer.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")

			if humanoid and humanoid.Health <= 0 then
				falling = true
				model:SetAttribute("Despawning", true)

				local speed = entity.Config.Movement.Speed
				local targetCFrame = model:GetPivot() - Vector3.new(0, 300, 0)
				local reached = false

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
							pivot + unit * math.min(step * speed, magnitude)
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

				break
			end

			RunService.Heartbeat:Wait()
		end
	end)

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

	while model.Parent do
		RunService.Heartbeat:Wait()
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

entity.Debug.CrucifixionOverwrite = function()
	print("Custom crucifixion callback")

	local model = entity.Model
	local attachment = model.RipperNew.Attachment

	local face = attachment.Ripper.Face
	local jumpscareFace = attachment.Ripper["Jumpscare Face"]

	face.Enabled = false
	jumpscareFace.Enabled = true

	local repent = model.RipperNew:FindFirstChild("Repent")

	if repent then
		repent:Play()
	end
end

---====== Run entity ======---

entity:Run(true)
