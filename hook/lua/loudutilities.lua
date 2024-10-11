--Destructively hook the spawnwave thread to turn it into a noop.
function SpawnWaveThread( aiBrain )
	LOG("*AI DEBUG "..aiBrain.Nickname.." Spawnwave disabled")
	aiBrain.WaveThread = nil
end

-- Dear Members of the Board, Morton Salt, Inc:

-- Many board members, former members, and people within your community are
-- hurting. Like the climate, the science of modeling the global salt
-- market is full of complex variables and relationships that mankind barely
-- grasps, but none can deny the direct correlation between my actions and the
-- disastrous flooding of the global salt market in October of 2024. Some would
-- point to Nassim Nicholas Taleb's famous risk analysis work "The Black Swan" as a
-- logical salve, claiming that the sheer improbability of an event absolves me of
-- guilt (e.g. "No one could have known, " "it wasn't your fault" "it could happen to
-- anyone.") As with any generational tragedy, I recognize that platitudes are
-- no comfort for you - the innocent victims and bystanders. All I can do here is
-- explain my actions and try to provide restitution to those immediately harmed. I
-- can only pray this provides some comfort to you, that the market recovers, and
-- that future generations will judge me with the compassion of hindsight.

-- Though we may not know the long term impact of this particular Black Swan event,
-- the immediate devastation is obvious. Dozens of hard working salt companies
-- (like yours), employing millions of dedicated salt miners, faced an
-- unprecedented financial crisis akin to the 2008 debacle with Mortgage Backed
-- Securities or the OPEC Oil Price Shock of 1973. Within the span of hours, the
-- market faced a sudden surge in the supply of mineral salt heretofore unseen in
-- the vital commodity market. Panic led to depressed prices, ultimately leading to
-- collapse and the continuing market turmoil. Although the exact cause is unknown,
-- both industry and academic researchers theorize that either a combination of
-- chemical compounds causing localized hallucinations in key figures , or a form
-- of mass formation psychosis may have "sparked the fire". I do know that - based
-- on proximity alone - my own selfishness and lack of foresight undoubtedly
-- "supplied the fuel."

-- Roughly three weeks prior to the Flood, I heard the unending anguish of my
-- community. They fell victim to a mysterious force that beguiled any artillery
-- projectile of the Aeon. Instead of landing on the head of the enemy, their shots
-- were invisibly deflected by an unseen hand and sent sailing toward the ether.
-- Not knowing that this anti-miracle existed, many losses were incurred - game
-- after game - for weeks as unfortunate Aeon player-victims continued to stumble
-- into inexplicable disaster. Feeling their pain in the emotional atria and
-- ventricles of my heart, empathy and a sense of duty moved me to try to
-- resolve this calamity.

-- Hours of careful inspection by our community of volunteers eventually led to an
-- innocuous change introduced upstream almost a month prior. With that change, the
-- typical rules governing the physics of all projectiles were intentionally
-- diverted for Aeon artillery when facing a specific enemy of the kind our players
-- regularly contested (the M28AI). Whether this was a drunken oversight,
-- intentional malfeasance, a benign experiment, or just bad craftsmanship is
-- unknowable (and frankly irrelevant). What is known is that bypassing this root
-- cause and reverting to the prior behavior alleviated a long-standing problem
-- that had plagued all virtuous players; where there was suffering, a trivial
-- patch brought great joy and relief. I completely acknowledge fixing the game by
-- bypassing the upstream code that was breaking all the games around me, and
-- improving the quality of life of our player base.

-- I also acknowledge that our temporary joy - the completely functional,
-- enjoyable, and invigorating games played over the next 11 days - ultimately led
-- to an irreversible impact on the global salt market. While we enjoyed over 33
-- error-free games for the first time in weeks, the natural barriers protecting
-- humanity from a once-in-a-century salt flood weakened and eroded.

-- I am profoundly sorry that anyone has been harmed. As a father of three dogs,
-- and a devoted follower who tries to live by a strong set of ethical values, I
-- hurt for the survivors, and I deeply regret the nearly Cthulhuian catastrophe we
-- now face. At each opportunity that I have to sit with my family, I am directly
-- reminded how fragile the balances are in our lives and how much our actions can
-- have a lasting impact on others. I live with the regret and sorrow for the
-- mistakes I personally made the precipitated the Great Salt Flood of 2024.

-- Unbiasedly Yours,

-- Chadwick Leopold Rasputin


-- The following is retained for posterity, so that future generations
-- may understand the untold damage of noble intentions.

--destructively hook TrackProj to eliminate broken projectiles
--that target M28 (e.g. miasma and others).
--this could be oversight and "should" be fixed upstream.
--for now we just make it behave identical to other AI
--personalities.
--function TrackProj(projectitem, self)
--end

--Another workaround for the prior TrackProj function

--This supposedly exists only to allow LOUD to track
--M28's units doing micro at the projectile level (dubious or not, IDGAF).

--It has the great side effect of entirely breaking miasma shells
--for reasons, making M28 immune to an entire faction's artillery.
--function TrackMicro(projectitem, self)
--end


