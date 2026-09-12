local sound = Instance.new("Sound")
sound.Name = "RipperSpawm"
sound.Parent = workspace
sound.AcousticSimulationEnabled = true
sound.Looped = false
sound.PlayOnRemove = false
sound.PlaybackSpeed = 0.6
sound.PlaybackRegionsEnabled = false
sound.SoundId = "rbxassetid://9125713501"
sound.Volume = 6
sound.RollOffMaxDistance = 50
sound.RollOffMinDistance = 1
sound.RollOffMode = Enum.RollOffMode.InverseTapered

local pitchShift = Instance.new("PitchShiftSoundEffect")
pitchShift.Name = "RipperSpawn"
pitchShift.Octave = 0.875
pitchShift.Enabled = true
pitchShift.Priority = 0
pitchShift.Parent = sound

sound.Ended:Connect(function()
	sound:Destroy()
end)

sound:Play()
