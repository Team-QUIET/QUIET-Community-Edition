--Destructively hook the spawnwave thread to turn it into a noop.
function SpawnWaveThread( aiBrain )
	LOG("*AI DEBUG "..aiBrain.Nickname.." Spawnwave disabled")
	aiBrain.WaveThread = nil
end
