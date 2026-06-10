local _, ns = ...
local L = ns.L

local PANEL_NAME = "GearUpgradeCostTabFrame"
local PANEL_WIDTH = 400 -- matches the Reputation and Currency tabs

------------------------------------------------------------------------------
-- Accordion section headers (mirrors Blizzard's TokenHeaderMixin)
------------------------------------------------------------------------------

GearUpgradeCostTabHeaderMixin = {}

function GearUpgradeCostTabHeaderMixin:OnLoadHeader()
	self:SetClickHandler(function(_header, button)
		if button == "LeftButton" then
			self:ToggleCollapsed()
		end
	end)
	self:SetTitleColor(false, NORMAL_FONT_COLOR)
	self:SetTitleColor(true, NORMAL_FONT_COLOR)
end

function GearUpgradeCostTabHeaderMixin:Initialize(elementData)
	self.elementData = elementData
	self:GetTitleRegion():SetText(elementData.title or "")
	self:UpdateCollapsedState(self:IsCollapsed())
end

function GearUpgradeCostTabHeaderMixin:IsCollapsed()
	return GearUpgradeCostTabFrame.collapsed[self.elementData.key]
end

function GearUpgradeCostTabHeaderMixin:ToggleCollapsed()
	local collapsed = GearUpgradeCostTabFrame.collapsed
	collapsed[self.elementData.key] = not collapsed[self.elementData.key]
	GearUpgradeCostTabFrame:Rebuild()
end

------------------------------------------------------------------------------
-- Gear rows
------------------------------------------------------------------------------

GearUpgradeCostTabRowMixin = {}

function GearUpgradeCostTabRowMixin:Initialize(elementData)
	self.elementData = elementData
	self.SlotName:SetText(elementData.label)
	self.ItemLevel:SetText(elementData.itemLevel or "")

	if not (elementData.track and elementData.rank and elementData.maxRank) then
		-- No upgrade line on the tooltip (crafted, legacy, heirloom, ...)
		self.Track:SetText(GRAY_FONT_COLOR:WrapTextInColorCode(L.DASH))
		self.NextCost:SetText("")
		self.TotalCost:SetText("")
		return
	end

	local trackText = ("%s %d/%d"):format(elementData.track, elementData.rank, elementData.maxRank)
	local trackInfo = ns.GetTrackInfo(elementData.track)
	local costs = ns.GetCosts(trackInfo, elementData.rank, elementData.maxRank, elementData.mode, elementData.slotID, elementData.itemLevel)

	if costs and costs.maxed then
		-- Mute the whole row: this addon is about spotting remaining
		-- upgrades, so finished items should recede, not pop green.
		self.SlotName:SetText(GRAY_FONT_COLOR:WrapTextInColorCode(elementData.label))
		self.ItemLevel:SetText(GRAY_FONT_COLOR:WrapTextInColorCode(tostring(elementData.itemLevel or "")))
		self.Track:SetText(GRAY_FONT_COLOR:WrapTextInColorCode(trackText))
		self.NextCost:SetText(GRAY_FONT_COLOR:WrapTextInColorCode(L.DASH))
		self.TotalCost:SetText(GRAY_FONT_COLOR:WrapTextInColorCode(L.DASH))
	elseif costs then
		self.Track:SetText(trackText)
		if costs.nextIsFree then
			self.NextCost:SetText(GREEN_FONT_COLOR:WrapTextInColorCode(L.FREE))
		else
			self.NextCost:SetText(ns.FormatCost(costs.nextCost, trackInfo))
		end
		self.TotalCost:SetText(ns.FormatCost(costs.totalCost, trackInfo))
	else
		-- Track parsed from the tooltip but unknown to Data.lua
		self.Track:SetText(trackText)
		self.NextCost:SetText(L.UNKNOWN_COST)
		self.TotalCost:SetText(L.UNKNOWN_COST)
	end
end

function GearUpgradeCostTabRowMixin:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetInventoryItem("player", self.elementData.slotID)
	GameTooltip:Show()
end

function GearUpgradeCostTabRowMixin:OnLeave()
	GameTooltip:Hide()
end

------------------------------------------------------------------------------
-- Placeholder note rows ("In Bag" is empty in v1)
------------------------------------------------------------------------------

GearUpgradeCostTabNoteMixin = {}

function GearUpgradeCostTabNoteMixin:Initialize(elementData)
	self.Text:SetText(elementData.text or "")
end

------------------------------------------------------------------------------
-- The panel
------------------------------------------------------------------------------

GearUpgradeCostTabMixin = {}

local PANEL_EVENTS = {
	"PLAYER_EQUIPMENT_CHANGED",
}

-- Element heights; must match the template sizes in UI.xml.
local HEADER_HEIGHT, ROW_HEIGHT, NOTE_HEIGHT = 26, 22, 20
-- Section breathing room, on top of the view's 2px element spacing:
-- blank space below the "Equipped" header art doubles the gap to the first
-- row (2 → 4px), and a spacer above "In Bag" quadruples the gap after the
-- last row (2 → 2+4+2 = 8px).
local HEADER_TO_ROWS_EXTRA = 2
local ROWS_TO_HEADER_SPACER = 4

function GearUpgradeCostTabMixin:OnLoad()
	self.collapsed = { equipped = false, bags = true }

	local view = CreateScrollBoxListLinearView()

	local function Initializer(frame, elementData)
		frame:Initialize(elementData)
	end

	local function NoOpInitializer() end

	view:SetElementFactory(function(factory, elementData)
		if elementData.isHeader then
			factory("GearUpgradeCostTabHeaderTemplate", Initializer)
		elseif elementData.isNote then
			factory("GearUpgradeCostTabNoteTemplate", Initializer)
		elseif elementData.isSpacer then
			factory("GearUpgradeCostTabSpacerTemplate", NoOpInitializer)
		else
			factory("GearUpgradeCostTabRowTemplate", Initializer)
		end
	end)

	-- The header's extent can exceed its 26px art, leaving blank space
	-- below it; spacers are pure blank. This is how section gaps are tuned.
	view:SetElementExtentCalculator(function(_dataIndex, elementData)
		if elementData.isHeader then
			return HEADER_HEIGHT + (elementData.extraBottom or 0)
		elseif elementData.isSpacer then
			return elementData.height
		elseif elementData.isNote then
			return NOTE_HEIGHT
		end
		return ROW_HEIGHT
	end)

	local topPadding, bottomPadding, leftPadding, rightPadding = 8, 8, 4, 4
	local elementSpacing = 2
	view:SetPadding(topPadding, bottomPadding, leftPadding, rightPadding, elementSpacing)

	ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view)

	self.CostModeDropdown:SetWidth(130)

	self.ColSlot:SetText(L.COL_SLOT)
	self.ColItemLevel:SetText(L.COL_ILVL)
	self.ColUpgrade:SetText(L.COL_UPGRADE)
	self.ColNextCost:SetText(L.COL_NEXT)
	self.ColTotalCost:SetText(L.COL_MAX)
end

local function IsCostModeSelected(mode)
	return GearUpgradeCostTabDB.costMode == mode
end

local function SetCostModeSelected(mode)
	GearUpgradeCostTabDB.costMode = mode
	GearUpgradeCostTabFrame:Update()
end

function GearUpgradeCostTabMixin:OnShow()
	FrameUtil.RegisterFrameForEvents(self, PANEL_EVENTS)

	self:Update()

	self.CostModeDropdown:SetupMenu(function(_dropdown, rootDescription)
		rootDescription:SetTag("MENU_GEAR_UPGRADE_COST_TAB_MODE")
		rootDescription:CreateRadio(L.COST_MODE_BASE, IsCostModeSelected, SetCostModeSelected, "base")
		local discount = rootDescription:CreateRadio(L.COST_MODE_DISCOUNT, IsCostModeSelected, SetCostModeSelected, "discount")
		discount:SetTooltip(function(tooltip)
			GameTooltip_AddHighlightLine(tooltip, L.COST_MODE_DISCOUNT_TIP)
		end)
	end)
end

function GearUpgradeCostTabMixin:OnHide()
	FrameUtil.UnregisterFrameForEvents(self, PANEL_EVENTS)
end

function GearUpgradeCostTabMixin:OnEvent(event)
	if event == "PLAYER_EQUIPMENT_CHANGED" then
		self:QueueUpdate()
	end
end

-- PLAYER_EQUIPMENT_CHANGED fires once per slot, so an equipment-set swap
-- delivers ~16 events in one frame; coalesce them into a single Update.
function GearUpgradeCostTabMixin:QueueUpdate()
	if self.updateQueued then
		return
	end
	self.updateQueued = true
	C_Timer.After(0, function()
		self.updateQueued = false
		if self:IsShown() then
			self:Update()
		end
	end)
end

-- Waits for all equipped items' data to be cached, then rebuilds the list.
function GearUpgradeCostTabMixin:Update()
	if self.continuableContainer then
		self.continuableContainer:Cancel()
	end
	self.continuableContainer = ContinuableContainer:Create()
	for _, slotEntry in ipairs(ns.SLOTS) do
		local location = ItemLocation:CreateFromEquipmentSlot(slotEntry.inv)
		if C_Item.DoesItemExist(location) then
			self.continuableContainer:AddContinuable(Item:CreateFromEquipmentSlot(slotEntry.inv))
		end
	end
	self.continuableContainer:ContinueOnLoad(function()
		self:Rebuild()
	end)
end

function GearUpgradeCostTabMixin:Rebuild()
	local mode = GearUpgradeCostTabDB.costMode or "base"
	if mode == "discount" then
		ns.ClearDiscountCache()
	end

	local elements = {}
	local equippedExpanded = not self.collapsed.equipped
	elements[#elements + 1] = {
		isHeader = true, key = "equipped", title = L.EQUIPPED,
		extraBottom = equippedExpanded and HEADER_TO_ROWS_EXTRA or nil,
	}
	if equippedExpanded then
		for _, row in ipairs(ns.BuildEquippedRows()) do
			row.mode = mode
			elements[#elements + 1] = row
		end
		elements[#elements + 1] = { isSpacer = true, height = ROWS_TO_HEADER_SPACER }
	end
	elements[#elements + 1] = { isHeader = true, key = "bags", title = L.IN_BAG }
	if not self.collapsed.bags then
		elements[#elements + 1] = { isNote = true, text = L.IN_BAG_PLACEHOLDER }
	end

	self.ScrollBox:SetDataProvider(CreateDataProvider(elements), ScrollBoxConstants.RetainScrollPosition)
end

------------------------------------------------------------------------------
-- Character frame integration
------------------------------------------------------------------------------

local function SetupCharacterFrameTab()
	-- Addon-prefixed name: PanelTemplates finds the button through the
	-- CharacterFrame.Tabs array (parentArray on the template), so the global
	-- name is only for debugging, and "CharacterFrameTab4" would collide if
	-- Blizzard or another addon ever creates a 4th native tab.
	local tab = CreateFrame("Button", "GearUpgradeCostTabButton", CharacterFrame, "CharacterFrameTabTemplate")
	tab:SetID(4)
	tab:SetText(L.TAB_TITLE)
	tab:SetPoint("TOPLEFT", CharacterFrameTab3, "TOPRIGHT", 1, 0)
	-- Replace the template's name-based OnClick routing with our own. The
	-- sound matches native tabs, which play it on every click; ToggleCharacter
	-- only plays it on the open-subframe-switch branch.
	tab:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
		ToggleCharacter(PANEL_NAME)
	end)
	PanelTemplates_TabResize(tab, 0)

	-- Taint trade-off: these writes from insecure code taint values that
	-- ToggleCharacter reads when invoked from the secure C/U key bindings.
	-- CharacterFrame is not a protected frame, and this is the established
	-- pattern for character-frame tabs, but in combat edge cases it could
	-- surface as "Interface action failed because of an AddOn".
	table.insert(CHARACTERFRAME_SUBFRAMES, PANEL_NAME)
	-- Not PanelTemplates_SetNumTabs: that would re-anchor Blizzard's tabs
	-- with different spacing than their XML uses.
	CharacterFrame.numTabs = 4

	-- CharacterFrame's title/width lookup table is a file-local keyed by
	-- activeSubframe; unknown subframes fall back to the paper-doll defaults
	-- (player name title, 338px width), so correct both after the fact.
	hooksecurefunc(CharacterFrame, "UpdateTitle", function(frame)
		if frame.activeSubframe == PANEL_NAME then
			frame:SetTitleColor(NORMAL_FONT_COLOR)
			frame:SetTitle(L.TAB_TITLE)
		end
	end)

	hooksecurefunc(CharacterFrame, "UpdateSize", function(frame)
		if frame.activeSubframe == PANEL_NAME and frame:GetWidth() ~= PANEL_WIDTH then
			frame:SetWidth(PANEL_WIDTH)
			UpdateUIPanelPositions(frame)
		end
	end)

	-- Blizzard's overflow check only measures up to Tab3; extend it to ours.
	-- Unlike Blizzard's version, sort a COPY of frame.Tabs: PanelTemplates
	-- selects tab highlights by array position (frame.Tabs[selectedTab]), so
	-- an in-place sort by width makes the wrong tab light up.
	hooksecurefunc(CharacterFrame, "UpdateTabBounds", function(frame)
		if not tab:IsShown() then
			return
		end
		local diff = (tab:GetRight() or 0) - (frame:GetRight() or 0)
		if diff > 0 then
			local widestFirst = {}
			for index, frameTab in ipairs(frame.Tabs) do
				widestFirst[index] = frameTab
			end
			table.sort(widestFirst, function(a, b)
				return a:GetWidth() > b:GetWidth()
			end)
			for _, frameTab in ipairs(widestFirst) do
				local change = math.min(10, diff)
				diff = diff - change
				frameTab.Text:SetWidth(0)
				PanelTemplates_TabResize(frameTab, -change, nil, 36 - change, 88)
				if diff <= 0 then
					break
				end
			end
		end
	end)
end

local bootstrap = CreateFrame("Frame")
bootstrap:RegisterEvent("PLAYER_LOGIN")
bootstrap:SetScript("OnEvent", function()
	GearUpgradeCostTabDB = GearUpgradeCostTabDB or {}
	if GearUpgradeCostTabDB.costMode == nil then
		GearUpgradeCostTabDB.costMode = "base"
	end
	SetupCharacterFrameTab()
end)
