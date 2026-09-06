-- All automation values below are demonstration state only.
return {
    SerenityAPIVersion=3, ConfigVersion=1, GameName='UI Playground',
    Pages={
        {Id='About',Title='About',Description='Welcome to Serenity',Icon='info',Features={}},
        {Id='Automation',Title='Automation',Description='Explore your farming controls',Icon='bot',Tabs={{Id='Farm',Icon='sprout'},{Id='Filters',Icon='funnel'},{Id='Advanced',Icon='sliders-horizontal'}},Features={
            {Id='Farming',Title='Farming',Tab='Farm',Expanded=true,Controls={
                {Id='AutoCollect',Type='Switch',Title='Auto Collect',Default=false},
                {Id='AutoSell',Type='Switch',Title='Auto Sell',Default=false},
                {Id='Notice',Type='Paragraph',Title='Preview controls',Text='Try the controls here. Farming actions are not connected.'},
                {Id='CollectDelay',Type='Slider',Title='Collect Delay',Min=1,Max=30,Step=1,Default=5,Suffix=' s'},
                {Id='Target',Type='Select',Title='Target',Options={'All eligible','Selected only','Nearest'},Default='All eligible'},
            }},
            {Id='AdvancedOptions',Title='Advanced options',Tab='Farm',Expanded=false,Controls={
                {Id='RetryDelay',Type='Slider',Title='Retry Delay',Min=1,Max=20,Default=3,Suffix=' s'},
            }},
            {Id='Selection',Title='Selection',Tab='Filters',Expanded=true,Controls={
                {Id='Mode',Type='Select',Title='Filter Mode',Options={'Only selected','Skip selected'},Default='Only selected'},
                {Id='Rarities',Type='MultiSelect',Title='Rarities',Options={'Common','Uncommon','Rare','Epic','Legendary','Mythic'},Default={'Rare','Epic'},EmptyMeansAll=false},
                {Id='Empty',Type='Paragraph',Title='Only selected',Text='An empty selection selects nothing. These are sample rarity names.'},
            }},
            {Id='Timing',Title='Timing',Tab='Advanced',Expanded=true,Controls={
                {Id='Cooldown',Type='Slider',Title='Action Cooldown',Min=0.5,Max=10,Step=0.5,Default=1,Suffix=' s'},
                {Id='Queue',Type='Live',Title='Preview Status',Default='Not connected'},
            }},
        }},
        {Id='Progression',Title='Progression',Description='Progress and status preview',Icon='trending-up',Features={
            {Id='Overview',Title='Overview',Expanded=true,Controls={
                {Id='Status',Type='Live',Title='Current Status',Default='Preview'},
                {Id='Example',Type='Progress',Title='Sample Progress',Min=0,Max=100,Default=40},
                {Id='Notice',Type='Paragraph',Title='Game integration comes later',Text='Progression will use verified game data when this UI is integrated.'},
            }},
        }},
        {Id='Shop',Title='Shop',Description='Selection controls preview',Icon='shopping-cart',Features={
            {Id='Selection',Title='Shop preferences',Expanded=true,Controls={
                {Id='Mode',Type='Select',Title='Purchase Filter',Options={'Only selected','Skip selected'},Default='Only selected'},
                {Id='Limit',Type='Slider',Title='Sample Quantity',Min=1,Max=50,Default=5},
                {Id='Notice',Type='Paragraph',Title='Preview only',Text='These controls do not make purchases.'},
            }},
        }},
        {Id='Server',Title='Server',Description='Session information',Icon='globe',Features={
            {Id='Session',Title='Session',Expanded=true,Controls={
                {Id='Place',Type='Live',Title='Place ID',Default='--'},
                {Id='Copy',Type='Action',Title='Copy Place ID',Action='CopyPlace',Icon='copy'},
            }},
        }},
        {Id='Webhook',Title='Webhook',Description='Notification form preview',Icon='bell',Features={
            {Id='Form',Title='Discord notification',Expanded=true,Controls={
                {Id='PreviewName',Type='Input',Title='Display Name',Default='Serenity Hub',Placeholder='Display name'},
                {Id='Notice',Type='Paragraph',Title='Form preview',Text='No webhook requests are sent by this UI demo.'},
            }},
        }},
        {Id='Misc',Title='Misc',Description='Useful shortcuts',Icon='menu',Features={
            {Id='Shortcuts',Title='Shortcuts',Expanded=true,Controls={
                {Id='Search',Type='Action',Title='Search Controls',Action='Search',Icon='search'},
                {Id='Minimize',Type='Action',Title='Minimize Interface',Action='Minimize',Icon='minus'},
                {Id='Info',Type='Paragraph',Title='Keyboard shortcuts',Text='Right Ctrl hides or shows the hub. Ctrl+K opens search. Escape closes a popup.'},
            }},
        }},
        {Id='Settings',Title='Settings',Description='Make it comfortable',Icon='settings',Tabs={{Id='Appearance',Icon='sliders-horizontal'},{Id='Interface',Icon='monitor'},{Id='Profiles',Icon='save'}},Features={
            {Id='Appearance',Title='Appearance',Tab='Appearance',Expanded=true,Controls={
                {Id='Accent',Type='Select',Title='Accent Color',Options={'Rose','Cyan','Lavender'},Default='Rose',Effect='Accent'},
                {Id='Scale',Type='Slider',Title='UI Scale',Min=75,Max=115,Step=5,Default=100,Suffix='%',Effect='Scale'},
                {Id='Transparency',Type='Slider',Title='Transparency',Min=0,Max=20,Step=1,Default=0,Suffix='%',Effect='Transparency'},
                {Id='LowEffects',Type='Switch',Title='Low Effects',Default=false,Effect='LowEffects'},
                {Id='ReducedMotion',Type='Switch',Title='Reduce Motion',Default=false,Effect='Motion'},
            }},
            {Id='Interface',Title='Interface',Tab='Interface',Expanded=true,Controls={
                {Id='Remember',Type='Paragraph',Title='Remember your layout',Text='Page, tab, section and control settings are saved when local file access is available.'},
                {Id='Center',Type='Action',Title='Center Window',Action='Center',Icon='focus'},
            }},
            {Id='Profiles',Title='Profiles',Tab='Profiles',Expanded=true,Controls={
                {Id='Save',Type='Action',Title='Save Preview Settings',Action='Save',Icon='save'},
                {Id='Reset',Type='Action',Title='Reset Preview Settings',Action='Reset',Icon='rotate-cw'},
                {Id='Close',Type='Action',Title='Close Preview',Action='Destroy',Icon='x'},
            }},
        }},
    },
}
