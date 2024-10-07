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

--Another workaround for the prior TrackProj function

--This supposedly exists only to allow LOUD to track
--M28's units doing micro at the projectile level (dubious or not, IDGAF).

--It has the great side effect of entirely breaking miasma shells
--for reasons, making M28 immune to an entire faction's artillery.
function TrackMicro(projectitem, self)
end
