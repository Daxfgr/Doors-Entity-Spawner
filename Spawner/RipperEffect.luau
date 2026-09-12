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

	return 1 - math.clamp(
		(Time - FadeIn) / FadeOut,
		0,
		1
	)
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
	local Time = os.clock() - Start

	for Object, Data in pairs(Objects) do

		if not Object.Parent then
			Objects[Object] = nil
			continue
		end

		if Data.Type == "Color" then

			local Target = Data.Neon and NeonRed or Red

			if Time <= FadeIn then

				Object.Color = Data.Color:Lerp(
					Target,
					Progress
				)

			else

				local TargetH, TargetS, TargetV = Target:ToHSV()
				local OriginalH, OriginalS, OriginalV = Data.Color:ToHSV()

				local Fade = 1 - Progress

				local S = TargetS + (OriginalS - TargetS) * Fade
				local V = TargetV + (OriginalV - TargetV) * Fade

				Object.Color = Color3.fromHSV(
					TargetH,
					S,
					V
				)
			end

		elseif Data.Type == "Sequence" then

			local Keypoints = {}

			for _, Point in ipairs(Data.Color.Keypoints) do

				local NewColor

				if Time <= FadeIn then

					NewColor = Point.Value:Lerp(
						Red,
						Progress
					)

				else

					local TargetH, TargetS, TargetV = Red:ToHSV()
					local OriginalH, OriginalS, OriginalV = Point.Value:ToHSV()

					local Fade = 1 - Progress

					local S = TargetS + (OriginalS - TargetS) * Fade
					local V = TargetV + (OriginalV - TargetV) * Fade

					NewColor = Color3.fromHSV(
						TargetH,
						S,
						V
					)
				end

				table.insert(
					Keypoints,
					ColorSequenceKeypoint.new(
						Point.Time,
						NewColor
					)
				)
			end

			Object.Color = ColorSequence.new(Keypoints)

		elseif Data.Type == "Highlight" then

			if Time <= FadeIn then

				Object.FillColor = Data.FillColor:Lerp(
					Red,
					Progress
				)

				Object.OutlineColor = Data.OutlineColor:Lerp(
					Red,
					Progress
				)

			else

				local TargetH, TargetS, TargetV = Red:ToHSV()

				local FillH, FillS, FillV = Data.FillColor:ToHSV()
				local OutlineH, OutlineS, OutlineV = Data.OutlineColor:ToHSV()

				local Fade = 1 - Progress

				Object.FillColor = Color3.fromHSV(
					TargetH,
					TargetS + (FillS - TargetS) * Fade,
					TargetV + (FillV - TargetV) * Fade
				)

				Object.OutlineColor = Color3.fromHSV(
					TargetH,
					TargetS + (OutlineS - TargetS) * Fade,
					TargetV + (OutlineV - TargetV) * Fade
				)
			end
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
