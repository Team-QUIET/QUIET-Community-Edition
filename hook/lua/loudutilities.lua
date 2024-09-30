--Destructively hook the spawnwave thread to turn it into a noop.
function SpawnWaveThread( aiBrain )
	LOG("*AI DEBUG "..aiBrain.Nickname.." Spawnwave disabled")
	aiBrain.WaveThread = nil
end


--destructively hook TrackProj to eliminate broken projectiles
--that target M28 (e.g. miasma and others).
--this could be oversight and "should" be fixed upstream.
--for now we just make it behave identical to other AI
--personalities.

function TrackProj(projectitem, self)

end
