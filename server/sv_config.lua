return {
    Timer = 30, -- minutes.
    StealPlayersCash = true,
    AdditionalRewards = function(player, src)
        lib.print.warn('NO ADDITIONAL REWARDS DEFINED. See sv_config.lua')
        -- add additional rewards here.
    end,
}