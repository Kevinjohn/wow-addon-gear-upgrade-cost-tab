std = "lua51"
max_line_length = false
self = false

exclude_files = {
	".luacheckrc",
	"tests/*.lua", -- plain Lua run outside the WoW sandbox
}

-- Globals this addon defines (XML-referenced mixins and saved variables),
-- plus frames it deliberately mutates (numTabs, collapsed state).
globals = {
	"GearUpgradeCostTabDB",
	"GearUpgradeCostTabMixin",
	"GearUpgradeCostTabHeaderMixin",
	"GearUpgradeCostTabRowMixin",
	"GearUpgradeCostTabBagRowMixin",
	"GearUpgradeCostTabNoteMixin",
	"GearUpgradeCostTabFrame",
	"CharacterFrame",
}

read_globals = {
	-- WoW Lua extensions
	"strtrim", "wipe",

	-- Frames and frame APIs
	"CreateFrame",
	"CharacterFrameTab3",
	"GameTooltip",

	-- Blizzard FrameXML functions and tables
	"CHARACTERFRAME_SUBFRAMES",
	"ToggleCharacter",
	"UpdateUIPanelPositions",
	"PanelTemplates_TabResize",
	"hooksecurefunc",
	"FrameUtil",
	"GameTooltip_AddHighlightLine",
	"GetCurrencyString",
	"PlaySound",
	"SOUNDKIT",
	"CreateScrollBoxListLinearView",
	"ScrollUtil",
	"ScrollBoxConstants",
	"CreateDataProvider",
	"ContinuableContainer",
	"Item",
	"ItemLocation",

	-- C_* namespaces
	"C_Item",
	"C_Container",
	"C_TooltipInfo",
	"C_CurrencyInfo",
	"C_ItemUpgrade",
	"C_Timer",

	-- API functions
	"GetInventoryItemLink",
	"GetAchievementInfo",
	"GetLocale",

	-- Global strings and constants
	"EQUIPPED", "ITEM_LEVEL_ABBR",
	"ITEM_UPGRADE_TOOLTIP_FORMAT_STRING",
	"ITEM_ACCOUNTBOUND_UNTIL_EQUIP",
	"ITEM_BIND_TO_ACCOUNT_UNTIL_EQUIP",
	"NUM_TOTAL_EQUIPPED_BAG_SLOTS",
	"NORMAL_FONT_COLOR", "GREEN_FONT_COLOR", "GRAY_FONT_COLOR",
	"HEADSLOT", "NECKSLOT", "SHOULDERSLOT", "BACKSLOT", "CHESTSLOT",
	"WRISTSLOT", "HANDSSLOT", "WAISTSLOT", "LEGSSLOT", "FEETSLOT",
	"FINGER0SLOT", "TRINKET0SLOT", "MAINHANDSLOT",
	"INVTYPE_WEAPONOFFHAND",
	"INVSLOT_HEAD", "INVSLOT_NECK", "INVSLOT_SHOULDER", "INVSLOT_BACK",
	"INVSLOT_CHEST", "INVSLOT_WRIST", "INVSLOT_HAND", "INVSLOT_WAIST",
	"INVSLOT_LEGS", "INVSLOT_FEET", "INVSLOT_FINGER1", "INVSLOT_FINGER2",
	"INVSLOT_TRINKET1", "INVSLOT_TRINKET2", "INVSLOT_MAINHAND", "INVSLOT_OFFHAND",
}
