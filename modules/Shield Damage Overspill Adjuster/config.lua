config = {
	{
		default = 0.0,
		label = 'Shield Overspill Damage in %',
		key = 'overspill_percent',
		help = "Shield overspill damage in %. 0 % disable damage overspill completely.",
		values = {
			{
				text = '0 % (Disabled)',
				key = '0',
			},
            {
				text = '25 %',
				key = '25',
			},
            {
				text = '50 %',
				key = '50',
			},
            {
				text = '75 %',
				key = '75',
			},
			{
				text = '100 % (QUIET-Default)',
				key = '100',
			},
		}
	},
}