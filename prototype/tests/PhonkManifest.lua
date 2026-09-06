local Manifest = {
    SerenityAPIVersion = 3,
    ConfigVersion = 1,
    RuntimeKey = "__SERENITY_PHONK_EVOLUTION_V3",
    GameName = "+1 Phonk Evolution",
    DesktopWidth = 920,
    DesktopHeight = 570,

    Pages = {
        {
            Id = "Dashboard",
            Title = "Dashboard",
            Description = "Serenity Hub automation for +1 Phonk Evolution.",
            Features = {
                {
                    Id = "Overview",
                    Title = "Automation",
                    Description = "Final Serenity Hub automation status.",
                    Accent = "purple",
                    Controls = {
                        {
                            Type = "Paragraph",
                            Title = "Status",
                            Text = "Official Serenity Hub V3 UI. Every automation switch starts OFF. There is no master Start button: enabling a switch immediately activates that feature.",
                        },
                        {
                            Type = "Paragraph",
                            Title = "Movement",
                            Text = "Auto Wins defaults to 500 speed and uses the validated MoveTo route. After every successful win it performs a clean respawn. Serenity permanently hides the revive countdown and immediately uses the game's free Respawn action, so there is no 5-second wait. Disabling Auto Wins restores the exact WalkSpeed you had before enabling it.",
                        },
                    },
                },
            },
        },

        {
            Id = "Automation",
            Title = "Automation",
            Description = "Main farming and progression automation.",
            Features = {
                {
                    Id = "Farm",
                    Title = "Farm",
                    Description = "Primary farming features.",
                    Accent = "cyan",
                    Controls = {
                        {
                            Type = "Switch",
                            Id = "AutoClick",
                            Title = "Auto Click",
                            Description = "Continuously earn Aura.",
                            Default = false,
                            Changed = function(v)
                                setBool("AutoClick", v)
                            end,
                        },
                        {
                            Type = "Switch",
                            Id = "AutoWins",
                            Title = "Auto Wins",
                            Description = "Walk every configured stage and claim Wins. After success, respawn cleanly and start the next run from the beginning.",
                            Default = false,
                            Changed = function(v)
                                if v then
                                    captureAutoWinsOriginalSpeed()
                                    setBool("AutoWins", true)
                                    cancelCharacterMovement()
                                    applyAutoWinsSpeed()
                                else
                                    setBool("AutoWins", false)
                                    setNoclip(false)
                                    cancelCharacterMovement()
                                    restoreAutoWinsOriginalSpeed()
                                end
                            end,
                        },
                        {
                            Type = "Switch",
                            Id = "AutoTreadmill",
                            Title = "Auto Treadmill",
                            Description = "Teleport to the best unlocked free treadmill.",
                            Default = false,
                            Changed = function(v)
                                setBool("AutoTreadmill", v)
                            end,
                        },
                    },
                },

                {
                    Id = "Progression",
                    Title = "Progression",
                    Description = "Automatic progression actions.",
                    Accent = "green",
                    Controls = {
                        {
                            Type = "Switch",
                            Id = "AutoEvolve",
                            Title = "Auto Evolve",
                            Description = "Evolve whenever CanEvolve is ready.",
                            Default = false,
                            Changed = function(v)
                                setBool("AutoEvolve", v)
                            end,
                        },
                        {
                            Type = "Switch",
                            Id = "AutoRebirth",
                            Title = "Auto Rebirth",
                            Description = "Rebirth whenever CanRebirth is ready.",
                            Default = false,
                            Changed = function(v)
                                setBool("AutoRebirth", v)
                            end,
                        },
                        {
                            Type = "Switch",
                            Id = "EquipBody",
                            Title = "Equip Best Body",
                            Description = "Equip the latest unlocked evolution body.",
                            Default = false,
                            Changed = function(v)
                                setBool("AutoEquipBody", v)
                            end,
                        },
                        {
                            Type = "Switch",
                            Id = "EquipAura",
                            Title = "Equip Best Aura",
                            Description = "Equip the highest owned Phonk/Aura tier.",
                            Default = false,
                            Changed = function(v)
                                setBool("AutoEquipAura", v)
                            end,
                        },
                        {
                            Type = "Switch",
                            Id = "BuyAura",
                            Title = "Auto Buy Aura / Phonk",
                            Description = "Sequentially teleport to affordable Wins pads; stops before Robux-only tiers.",
                            Default = false,
                            Changed = function(v)
                                setBool("AutoBuyAura", v)
                            end,
                        },
                    },
                },
            },
        },

        {
            Id = "PetsTrails",
            Title = "Pets & Trails",
            Description = "Pet hatching, pet equip and trails.",
            Features = {
                {
                    Id = "Pets",
                    Title = "Pets",
                    Description = "Wins egg automation.",
                    Accent = "purple",
                    Controls = {
                        {
                            Type = "Switch",
                            Id = "AutoHatch",
                            Title = "Auto Hatch",
                            Description = "Teleport within the egg proximity zone and hatch the best affordable Wins egg.",
                            Default = false,
                            Changed = function(v)
                                setBool("AutoHatch", v)
                            end,
                        },
                        {
                            Type = "Switch",
                            Id = "EquipPet",
                            Title = "Equip Best Pet",
                            Description = "Use the game's normal EquipBest action.",
                            Default = false,
                            Changed = function(v)
                                setBool("AutoEquipPet", v)
                            end,
                        },
                        {
                            Type = "Slider",
                            Id = "HatchDelay",
                            Title = "Hatch Delay",
                            Description = "Delay between successful hatches.",
                            Min = 1,
                            Max = 15,
                            Default = 3,
                            Suffix = "s",
                            Changed = function(v)
                                setNumber("HatchDelay", v, 3)
                            end,
                        },
                        {
                            Type = "Slider",
                            Id = "EggReserve",
                            Title = "Wins Reserve",
                            Description = "Wins to keep instead of spending on eggs.",
                            Min = 0,
                            Max = 1000000000,
                            Default = 0,
                            Suffix = "",
                            Changed = function(v)
                                setNumber("EggReserve", v, 0)
                            end,
                        },
                    },
                },

                {
                    Id = "Trails",
                    Title = "Trails",
                    Description = "Wins multiplier trails.",
                    Accent = "yellow",
                    Controls = {
                        {
                            Type = "Switch",
                            Id = "BuyTrail",
                            Title = "Auto Buy Trail",
                            Description = "Buy the best affordable normal Wins trail.",
                            Default = false,
                            Changed = function(v)
                                setBool("AutoBuyTrail", v)
                            end,
                        },
                        {
                            Type = "Switch",
                            Id = "EquipTrail",
                            Title = "Equip Best Trail",
                            Description = "Equip the highest multiplier owned trail.",
                            Default = false,
                            Changed = function(v)
                                setBool("AutoEquipTrail", v)
                            end,
                        },
                    },
                },
            },
        },

        {
            Id = "Rewards",
            Title = "Rewards",
            Description = "Free server-validated rewards.",
            Features = {
                {
                    Id = "Claims",
                    Title = "Claims",
                    Description = "Automatic reward claiming.",
                    Accent = "green",
                    Controls = {
                        {
                            Type = "Switch",
                            Id = "Daily",
                            Title = "Daily Reward",
                            Description = "Claim when the server says the daily reward is ready.",
                            Default = false,
                            Changed = function(v)
                                setBool("AutoDaily", v)
                            end,
                        },
                        {
                            Type = "Switch",
                            Id = "Offline",
                            Title = "Offline Reward",
                            Description = "Claim the normal free offline Aura offer.",
                            Default = false,
                            Changed = function(v)
                                setBool("AutoOffline", v)
                            end,
                        },
                        {
                            Type = "Switch",
                            Id = "Group",
                            Title = "Group Reward",
                            Description = "Claim only if already a valid group member and playtime requirement is met.",
                            Default = false,
                            Changed = function(v)
                                setBool("AutoGroup", v)
                            end,
                        },
                    },
                },
            },
        },

        {
            Id = "Performance",
            Title = "Performance",
            Description = "Aggressive client-side FPS and GPU optimizations.",
            Features = {
                {
                    Id = "Potato",
                    Title = "FPS Improver",
                    Description = "Maximum visual reduction for lower CPU/GPU usage.",
                    Accent = "green",
                    Controls = {
                        {
                            Type = "Switch",
                            Id = "VeryPotato",
                            Title = "Very Potato Mode",
                            Description = "Disables particles, trails, beams, lights, shadows, textures, post effects, water effects and forces lowest render quality. Reversible when disabled.",
                            Default = false,
                            Changed = function(v)
                                setVeryPotato(v)
                            end,
                        },
                        {
                            Type = "Switch",
                            Id = "Disable3D",
                            Title = "Disable 3D Rendering",
                            Description = "Maximum GPU reduction. The game simulation and Serenity automation continue while the 3D world is not rendered.",
                            Default = false,
                            Changed = function(v)
                                set3DDisabled(v)
                            end,
                        },
                        {
                            Type = "Paragraph",
                            Title = "Anti-Ragdoll",
                            Text = "Built in permanently: Serenity suppresses FallingDown/Ragdoll/Physics during local teleports and automatically gets the character back up.",
                        },
                    },
                },
            },
        },

        {
            Id = "Settings",
            Title = "Settings",
            Description = "Automation timing and movement settings.",
            Features = {
                {
                    Id = "Movement",
                    Title = "Auto Wins Movement",
                    Description = "Forward-only high-speed route settings.",
                    Accent = "cyan",
                    Controls = {
                        {
                            Type = "Slider",
                            Id = "WalkSpeed",
                            Title = "Walk Speed",
                            Description = "Auto Wins movement speed.",
                            Min = 16,
                            Max = 500,
                            Default = 500,
                            Suffix = "",
                            Changed = function(v)
                                setNumber("WalkSpeed", v, 500)

                                if State.AutoWins then
                                    applyAutoWinsSpeed()
                                end
                            end,
                        },
                        {
                            Type = "Slider",
                            Id = "ReachDistance",
                            Title = "Reach Distance",
                            Description = "Distance used to mark each route waypoint reached.",
                            Min = 2,
                            Max = 20,
                            Default = 8,
                            Suffix = " studs",
                            Changed = function(v)
                                setNumber("ReachDistance", v, 8)
                            end,
                        },
                    },
                },

                {
                    Id = "Timing",
                    Title = "Timing",
                    Description = "Automation timing.",
                    Accent = "purple",
                    Controls = {
                        {
                            Type = "Slider",
                            Id = "ClickDelay",
                            Title = "Click Delay",
                            Description = "Delay between Auto Click calls.",
                            Min = 0.03,
                            Max = 1,
                            Default = 0.10,
                            Suffix = "s",
                            Changed = function(v)
                                setNumber("ClickDelay", v, 0.10)
                            end,
                        },
                        {
                            Type = "Slider",
                            Id = "TreadmillSeconds",
                            Title = "Treadmill Duration",
                            Description = "Seconds spent on the treadmill per cycle.",
                            Min = 1,
                            Max = 10,
                            Default = 3,
                            Suffix = "s",
                            Changed = function(v)
                                setNumber("TreadmillSeconds", v, 3)
                            end,
                        },
                        {
                            Type = "Slider",
                            Id = "AuraRetries",
                            Title = "Aura Pad Retries",
                            Description = "Retries for delayed Aura/Phonk pad registration.",
                            Min = 1,
                            Max = 8,
                            Default = 4,
                            Suffix = "",
                            Changed = function(v)
                                setNumber("AuraRetries", v, 4)
                            end,
                        },
                    },
                },
            },
        },
    },
}

-- ============================================================

return Manifest
