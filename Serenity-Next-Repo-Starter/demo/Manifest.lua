return {
    SerenityAPIVersion = 4,
    GameName = "UI Playground",

    Pages = {
        {
            Id = "Home",
            Title = "Home",
        },
        {
            Id = "Automation",
            Title = "Automation",
            Features = {
                {
                    Id = "Rolling",
                    Title = "Rolling",
                    Description = "Comfort-first rolling controls.",
                    Controls = {
                        {
                            Type = "Switch",
                            Id = "AutoRoll",
                            Title = "Auto Roll",
                            Description = "Continuously perform configured rolls.",
                            Default = true,
                        },
                        {
                            Type = "Select",
                            Id = "MinimumRarity",
                            Title = "Minimum Rarity",
                            Values = {"Common", "Rare", "Epic", "Legendary", "Mythic"},
                            Default = "Epic",
                        },
                    }
                }
            }
        }
    }
}
