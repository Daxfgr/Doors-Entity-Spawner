local RunService = game:GetService("RunService")

local FadeIn = 2
local FadeOut = 60

local Red = Color3.fromRGB(255, 0, 0)
local NeonRed = Color3.fromRGB(255, 80, 80)

local EffectID = (workspace:GetAttribute("LightEffectID") or 0) + 1
workspace:SetAttribute("LightEffectID", EffectID)

local MyEffectID = EffectID

local Start = os.clock()
local Objects = {}

local function GetProgress()
	local Time = os.clock() - Start

	if Time <= FadeIn then
		return Time / FadeIn
	end

	local FadeTime = (Time - FadeIn) / FadeOut
	return 1 - math.clamp(FadeTime, 0, 1)
end

local function AddObject(Object)
	if Objects[Object] then
		return
	end

	if not Object:IsDescendantOf(workspace) then
		return
	end

	if Object:IsA("BasePart")
		or Object:IsA("PointLight")
		or Object:IsA("SpotLight")
		or Object:IsA("SurfaceLight") then

		Objects[Object] = {
			Type = "Color",
			Color = Object.Color,
			Neon = Object.Name == "Neon"
		}

	elseif Object:IsA("ParticleEmitter")
		or Object:IsA("Trail")
		or Object:IsA("Beam") then

		Objects[Object] = {
			Type = "Sequence",
			Color = Object.Color
		}

	elseif Object:IsA("Highlight") then

		Objects[Object] = {
			Type = "Highlight",
			FillColor = Object.FillColor,
			OutlineColor = Object.OutlineColor
		}
	end
end

local function ScanFixture(Fixture)
	for _, Object in ipairs(Fixture:GetDescendants()) do
		AddObject(Object)
	end
end

for _, Object in ipairs(workspace:GetDescendants()) do
	if Object.Name == "LightFixture" then
		ScanFixture(Object)
	end
end

workspace.DescendantAdded:Connect(function(Object)
	if Object.Name == "LightFixture" then
		task.defer(function()
			if Object.Parent then
				ScanFixture(Object)
			end
		end)

		return
	end

	local Fixture = Object:FindFirstAncestor("LightFixture")

	if Fixture then
		task.defer(function()
			if Object.Parent then
				AddObject(Object)
			end
		end)
	end
end)

while os.clock() - Start < FadeIn + FadeOut do

	if workspace:GetAttribute("LightEffectID") ~= MyEffectID then
		return
	end

	local Progress = GetProgress()

	for Object, Data in pairs(Objects) do

		if not Object.Parent then
			Objects[Object] = nil
			continue
		end

		if Data.Type == "Color" then

			local Target = Data.Neon and NeonRed or Red

			local OriginalR = Data.Color.R
			local OriginalG = Data.Color.G
			local OriginalB = Data.Color.B

			local TargetR = Target.R
			local TargetG = Target.G
			local TargetB = Target.B

			Object.Color = Color3.new(
				OriginalR + (TargetR - OriginalR) * Progress,
				OriginalG + (TargetG - OriginalG) * Progress,
				OriginalB + (TargetB - OriginalB) * Progress
			)

		elseif Data.Type == "Sequence" then

			local Keypoints = {}

			for _, Point in ipairs(Data.Color.Keypoints) do

				local Original = Point.Value

				table.insert(
					Keypoints,
					ColorSequenceKeypoint.new(
						Point.Time,
						Color3.new(
							Original.R + (Red.R - Original.R) * Progress,
							Original.G + (Red.G - Original.G) * Progress,
							Original.B + (Red.B - Original.B) * Progress
						)
					)
				)
			end

			Object.Color = ColorSequence.new(Keypoints)

		elseif Data.Type == "Highlight" then

			Object.FillColor = Color3.new(
				Data.FillColor.R + (Red.R - Data.FillColor.R) * Progress,
				Data.FillColor.G + (Red.G - Data.FillColor.G) * Progress,
				Data.FillColor.B + (Red.B - Data.FillColor.B) * Progress
			)

			Object.OutlineColor = Color3.new(
				Data.OutlineColor.R + (Red.R - Data.OutlineColor.R) * Progress,
				Data.OutlineColor.G + (Red.G - Data.OutlineColor.G) * Progress,
				Data.OutlineColor.B + (Red.B - Data.OutlineColor.B) * Progress
			)
		end
	end

	RunService.Heartbeat:Wait()
end

if workspace:GetAttribute("LightEffectID") == MyEffectID then

	for Object, Data in pairs(Objects) do

		if Object.Parent then

			if Data.Type == "Color" then
				Object.Color = Data.Color

			elseif Data.Type == "Sequence" then
				Object.Color = Data.Color

			elseif Data.Type == "Highlight" then
				Object.FillColor = Data.FillColor
				Object.OutlineColor = Data.OutlineColor
			end
		end
	end
end
