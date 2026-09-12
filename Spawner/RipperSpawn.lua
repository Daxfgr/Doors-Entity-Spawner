local sound = Instance.new("Sound")
sound.Name = "Spawn"
sound.Parent = workspace

sound.AcousticSimulationEnabled = true
sound.Looped = false
sound.PlayOnRemove = false
sound.PlaybackSpeed = 1
sound.PlaybackRegionsEnabled = false
sound.SoundId = "rbxassetid://9125713501"
sound.TimePosition = 0
sound.Volume = 1
sound.RollOffMaxDistance = 150
sound.RollOffMinDistance = 0
sound.RollOffMode = Enum.RollOffMode.InverseTapered

local pitchShift = Instance.new("PitchShiftSoundEffect")
pitchShift.Name = "Spawn"
pitchShift.Octave = 1.5
pitchShift.Enabled = true
pitchShift.Priority = 0
pitchShift.Parent = sound

sound.Ended:Connect(function()
	if sound.Parent then
		sound:Destroy()
	end
end)

sound:Play()
