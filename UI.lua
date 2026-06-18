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
	-- Update, not Rebuild: expanding a section starts scanning items the
	-- collapsed rebuilds skipped, so this path needs the same item-data
	-- preload as every other one. When everything is already cached (the
	-- usual case) ContinueOnLoad fires synchronously, so the click still
	-- feels instant.
	GearUpgradeCostTabFrame:Update()
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
		self.TrackRank:SetText("")
		self.NextCost:SetText("")
		self.TotalCost:SetText("")
		return
	end

	-- Name and rank are separate regions: long localized track names
	-- truncate with an ellipsis while the rank stays visible.
	local rankText = ("%d/%d"):format(elementData.rank, elementData.maxRank)
	local trackInfo = ns.GetTrackInfo(elementData.track)
	local costs = ns.GetCosts(trackInfo, elementData.rank, elementData.maxRank, elementData.mode, elementData.itemLink, elementData.itemLevel)

	if costs and costs.maxed then
		-- Mute the whole row: this addon is about spotting remaining
		-- upgrades, so finished items should recede, not pop green.
		self.SlotName:SetText(GRAY_FONT_COLOR:WrapTextInColorCode(elementData.label))
		self.ItemLevel:SetText(GRAY_FONT_COLOR:WrapTextInColorCode(tostring(elementData.itemLevel or "")))
		self.Track:SetText(GRAY_FONT_COLOR:WrapTextInColorCode(elementData.track))
		self.TrackRank:SetText(GRAY_FONT_COLOR:WrapTextInColorCode(rankText))
		self.NextCost:SetText(GRAY_FONT_COLOR:WrapTextInColorCode(L.DASH))
		self.TotalCost:SetText(GRAY_FONT_COLOR:WrapTextInColorCode(L.DASH))
	elseif costs then
		self.Track:SetText(elementData.track)
		self.TrackRank:SetText(rankText)
		if costs.nextIsFree then
			self.NextCost:SetText(GREEN_FONT_COLOR:WrapTextInColorCode(L.FREE))
		else
			self.NextCost:SetText(ns.FormatCost(costs.nextCost, trackInfo))
		end
		self.TotalCost:SetText(ns.FormatCost(costs.totalCost, trackInfo))
	else
		-- Track parsed from the tooltip but unknown to Data.lua
		self.Track:SetText(elementData.track)
		self.TrackRank:SetText(rankText)
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
-- Free-upgrade bag rows
------------------------------------------------------------------------------

GearUpgradeCostTabBagRowMixin = {}

function GearUpgradeCostTabBagRowMixin:Initialize(elementData)
	self.elementData = elementData
	self.ItemLevel:SetText(elementData.itemLevel or "")
	self.SlotName:SetText(elementData.slotLabel or "")
	self.Name:SetText(elementData.name or "")

	-- nil costs mean the track was parsed but is unknown to Data.lua
	local trackInfo = ns.GetTrackInfo(elementData.track)
	if elementData.nextIsFree then
		self.NextCost:SetText(GREEN_FONT_COLOR:WrapTextInColorCode(L.FREE))
	elseif elementData.nextCost then
		self.NextCost:SetText(ns.FormatCost(elementData.nextCost, trackInfo))
	else
		self.NextCost:SetText(L.UNKNOWN_COST)
	end
	if elementData.crestTotal == nil then
		self.TotalCost:SetText(L.UNKNOWN_COST)
	elseif elementData.crestTotal == 0 then
		self.TotalCost:SetText(GREEN_FONT_COLOR:WrapTextInColorCode(L.FREE))
	else
		self.TotalCost:SetText(ns.FormatCost(elementData.crestTotal, trackInfo))
	end
end

function GearUpgradeCostTabBagRowMixin:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetBagItem(self.elementData.bag, self.elementData.slot)
	GameTooltip:Show()
end

function GearUpgradeCostTabBagRowMixin:OnLeave()
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
	"BAG_UPDATE_DELAYED",
	"CURRENCY_DISPLAY_UPDATE",
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
	self.collapsed = { equipped = false, freebies = false, bags = true }

	local view = CreateScrollBoxListLinearView()

	local function Initializer(frame, elementData)
		frame:Initialize(elementData)
	end

	local function NoOpInitializer() end

	view:SetElementFactory(function(factory, elementData)
		if elementData.isHeader then
			factory("GearUpgradeCostTabHeaderTemplate", Initializer)
		elseif elementData.isBagRow then
			factory("GearUpgradeCostTabBagRowTemplate", Initializer)
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

	-- Width is a locale value: "Discount aware" fits in 130px but e.g.
	-- ruRU's "Базовая стоимость" needs more before it ellipsizes.
	self.CostModeDropdown:SetWidth(L.COST_MODE_WIDTH)

	self.ColSlot:SetText(L.COL_SLOT)
	self.ColItemLevel:SetText(L.COL_ILVL)
	self.ColUpgrade:SetText(L.COL_UPGRADE)
	self.ColNextCost:SetText(L.COL_NEXT)
	self.ColTotalCost:SetText(L.COL_MAX)

	self:InitializeCrestFooter()
end

------------------------------------------------------------------------------
-- Crest footer (always-visible crest totals under the list)
------------------------------------------------------------------------------

local function CrestCellOnEnter(cell)
	if not cell.valid then
		return
	end
	GameTooltip:SetOwner(cell, "ANCHOR_RIGHT")
	GameTooltip:SetCurrencyByID(cell.currencyID)
	GameTooltip:Show()
end

local function CrestCellOnLeave()
	GameTooltip:Hide()
end

-- One cell per crest, ns.CREST_ORDER left to right. Creation only wires
-- content and tooltips; positions come from LayoutCrestFooter, which needs
-- the footer's anchor-driven width and so can't run until layout resolves.
function GearUpgradeCostTabMixin:InitializeCrestFooter()
	local footer = self.CrestFooter
	footer.cells = {}
	for index, trackKey in ipairs(ns.CREST_ORDER) do
		local cell = CreateFrame("Frame", nil, footer)
		cell.currencyID = ns.TRACKS[trackKey].crestCurrencyID
		cell:EnableMouse(true)
		cell:SetScript("OnEnter", CrestCellOnEnter)
		cell:SetScript("OnLeave", CrestCellOnLeave)
		cell.Text = cell:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		cell.Text:SetPoint("CENTER")
		footer.cells[index] = cell
	end
	footer:SetScript("OnSizeChanged", function()
		self:LayoutCrestFooter()
	end)
end

-- Equal fifths of the footer's current width. Also called from OnShow:
-- the footer's size can resolve during XML load, before OnLoad installs
-- the OnSizeChanged script, in which case the script alone never fires.
function GearUpgradeCostTabMixin:LayoutCrestFooter()
	local footer = self.CrestFooter
	local cellWidth = footer:GetWidth() / #footer.cells
	for index, cell in ipairs(footer.cells) do
		cell:SetSize(cellWidth, footer:GetHeight())
		cell:SetPoint("LEFT", (index - 1) * cellWidth, 0)
	end
end

-- Owned totals straight from the currency API, rendered with the same
-- Blizzard formatter the cost columns use (GetCurrencyString), so the
-- footer's icons match the rows'. An unverified currency ID (the formatter
-- returns "") shows a muted dash instead of a phantom zero, and the cell's
-- tooltip is disabled along with it.
function GearUpgradeCostTabMixin:UpdateCrestFooter()
	for _, cell in ipairs(self.CrestFooter.cells) do
		local info = C_CurrencyInfo.GetCurrencyInfo(cell.currencyID)
		local text = info and GetCurrencyString(cell.currencyID, info.quantity) or ""
		cell.valid = text ~= ""
		cell.Text:SetText(cell.valid and text or GRAY_FONT_COLOR:WrapTextInColorCode(L.DASH))
	end
end

-- The ScrollBox's bottom offsets relative to the Inset, mirroring UI.xml:
-- with the footer, 4px inset margin + 22px footer + 2px gap; without it,
-- the footer's whole strip returns to the list.
local SCROLLBOX_BOTTOM_WITH_FOOTER, SCROLLBOX_BOTTOM_NO_FOOTER = 28, 2

-- Applies the "Show my crests" option: shows/hides the footer and moves
-- the ScrollBox's bottom edge (the ScrollBar follows it). Re-showing also
-- refreshes layout and totals, which covers currency changes that arrived
-- while the footer was hidden and its event handler skipped them.
function GearUpgradeCostTabMixin:ApplyCrestFooterVisibility()
	local show = GearUpgradeCostTabDB.showCrests == true
	self.CrestFooter:SetShown(show)
	self.ScrollBox:SetPoint("BOTTOMRIGHT", self:GetParent().Inset, "BOTTOMRIGHT",
		-22, show and SCROLLBOX_BOTTOM_WITH_FOOTER or SCROLLBOX_BOTTOM_NO_FOOTER)
	if show then
		self:LayoutCrestFooter()
		self:UpdateCrestFooter()
	end
end

local function IsCostModeSelected(mode)
	return GearUpgradeCostTabDB.costMode == mode
end

local function SetCostModeSelected(mode)
	GearUpgradeCostTabDB.costMode = mode
	GearUpgradeCostTabFrame:Update()
end

local function IsOptionEnabled(key)
	return GearUpgradeCostTabDB[key] == true
end

-- Checkbox setters toggle their own state; the menu system only reports
-- the click (same contract as Blizzard's Reputation filter menu).
local function ToggleOption(key)
	GearUpgradeCostTabDB[key] = not GearUpgradeCostTabDB[key]
	GearUpgradeCostTabFrame:Update()
end

-- Unlike the bag filters, "Show my crests" changes the panel chrome, not
-- the list contents, so it re-anchors instead of rebuilding.
local function ToggleShowCrests(key)
	GearUpgradeCostTabDB[key] = not GearUpgradeCostTabDB[key]
	GearUpgradeCostTabFrame:ApplyCrestFooterVisibility()
end

-- "Include Uncommon items": the quality name comes from Blizzard's
-- ITEM_QUALITYn_DESC globals (localized for free, always matching the
-- client's own naming), wrapped in the quality's color.
local function IncludeQualityText(quality)
	local name = _G[("ITEM_QUALITY%d_DESC"):format(quality)] or tostring(quality)
	local colorData = ColorManager.GetColorDataForItemQuality(quality)
	if colorData and colorData.color then
		name = colorData.color:WrapTextInColorCode(name)
	end
	return L.INCLUDE_QUALITY_FMT:format(name)
end

function GearUpgradeCostTabMixin:OnShow()
	FrameUtil.RegisterFrameForEvents(self, PANEL_EVENTS)

	self:Update()
	self:ApplyCrestFooterVisibility()

	self.CostModeDropdown:SetupMenu(function(_dropdown, rootDescription)
		rootDescription:SetTag("MENU_GEAR_UPGRADE_COST_TAB_MODE")
		rootDescription:CreateRadio(L.COST_MODE_BASE, IsCostModeSelected, SetCostModeSelected, "base")
		local discount = rootDescription:CreateRadio(L.COST_MODE_DISCOUNT, IsCostModeSelected, SetCostModeSelected, "discount")
		discount:SetTooltip(function(tooltip)
			GameTooltip_AddHighlightLine(tooltip, L.COST_MODE_DISCOUNT_TIP)
		end)

		-- Bag-section filters, mirroring the Reputation tab's
		-- radios-divider-checkboxes dropdown. Checkboxes keep the menu open
		-- (CreateCheckbox sets MenuResponse.Refresh, verified live
		-- 2026-06-10), and SetSelectionIgnored keeps their state out of the
		-- dropdown's collapsed label, which should only name the cost mode.
		rootDescription:CreateDivider()
		local uncommon = rootDescription:CreateCheckbox(IncludeQualityText(Enum.ItemQuality.Uncommon), IsOptionEnabled, ToggleOption, "includeUncommon")
		uncommon:SetSelectionIgnored()
		local rare = rootDescription:CreateCheckbox(IncludeQualityText(Enum.ItemQuality.Rare), IsOptionEnabled, ToggleOption, "includeRare")
		rare:SetSelectionIgnored()
		-- "Include Warbound items" carries its own locale string rather
		-- than reusing INCLUDE_QUALITY_FMT: several locales' frames say
		-- "items of quality %s", which reads as nonsense around a bind
		-- type. Each translation embeds the locale's own Warbound term
		-- (ITEM_ACCOUNTBOUND, verified live GlobalStrings 2026-06-11).
		local warbound = rootDescription:CreateCheckbox(L.INCLUDE_WARBOUND, IsOptionEnabled, ToggleOption, "includeWarbound")
		warbound:SetSelectionIgnored()
		warbound:SetTooltip(function(tooltip)
			GameTooltip_AddHighlightLine(tooltip, L.INCLUDE_WARBOUND_TIP)
		end)
		local tier = rootDescription:CreateCheckbox(L.PRIORITISE_TIER, IsOptionEnabled, ToggleOption, "prioritiseTier")
		tier:SetSelectionIgnored()
		tier:SetTooltip(function(tooltip)
			GameTooltip_AddHighlightLine(tooltip, L.PRIORITISE_TIER_TIP)
		end)

		-- Display options, separated from the bag filters above.
		rootDescription:CreateDivider()
		local crests = rootDescription:CreateCheckbox(L.SHOW_CRESTS, IsOptionEnabled, ToggleShowCrests, "showCrests")
		crests:SetSelectionIgnored()
	end)
end

function GearUpgradeCostTabMixin:OnHide()
	FrameUtil.UnregisterFrameForEvents(self, PANEL_EVENTS)
end

function GearUpgradeCostTabMixin:OnEvent(event)
	if event == "CURRENCY_DISPLAY_UPDATE" then
		-- Crest totals only; the lists don't price off owned currency. A
		-- hidden footer skips the refresh — ApplyCrestFooterVisibility
		-- re-reads the totals whenever it is shown again.
		if self.CrestFooter:IsShown() then
			self:UpdateCrestFooter()
		end
	elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "BAG_UPDATE_DELAYED" then
		self:QueueUpdate()
	end
end

-- PLAYER_EQUIPMENT_CHANGED fires once per slot, so an equipment-set swap
-- delivers ~16 events in one frame (often alongside BAG_UPDATE_DELAYED);
-- coalesce them into a single Update.
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

-- Waits for all equipped and bag items' data to be cached, then rebuilds.
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
	ns.AddBagContinuables(self.continuableContainer)
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
	local freebiesExpanded = not self.collapsed.freebies
	local bagsExpanded = not self.collapsed.bags
	local freeRows, crestRows, hiddenRows
	if freebiesExpanded or bagsExpanded then
		freeRows, crestRows, hiddenRows = ns.BuildBagRows(mode, GearUpgradeCostTabDB)
	end

	elements[#elements + 1] = {
		isHeader = true, key = "freebies", title = L.FREE_UPGRADES,
		extraBottom = freebiesExpanded and HEADER_TO_ROWS_EXTRA or nil,
	}
	if freebiesExpanded then
		if #freeRows == 0 then
			-- "Nothing to upgrade" would be false when the filters (not the
			-- bags) are why the section is empty, so say which it is.
			elements[#elements + 1] = { isNote = true,
				text = hiddenRows.free > 0 and L.FILTERED_EMPTY or L.FREE_UPGRADES_EMPTY }
		else
			for _, row in ipairs(freeRows) do
				elements[#elements + 1] = row
			end
		end
		elements[#elements + 1] = { isSpacer = true, height = ROWS_TO_HEADER_SPACER }
	end

	elements[#elements + 1] = {
		isHeader = true, key = "bags", title = L.IN_BAG,
		extraBottom = bagsExpanded and HEADER_TO_ROWS_EXTRA or nil,
	}
	if bagsExpanded then
		if #crestRows == 0 then
			elements[#elements + 1] = { isNote = true,
				text = hiddenRows.crest > 0 and L.FILTERED_EMPTY or L.IN_BAG_EMPTY }
		else
			for _, row in ipairs(crestRows) do
				elements[#elements + 1] = row
			end
		end
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
	-- Bag filters: uncommon and rare hidden, tier slots protected. The
	-- false defaults are written out explicitly so every option is visible
	-- in the SavedVariables file.
	if GearUpgradeCostTabDB.includeUncommon == nil then
		GearUpgradeCostTabDB.includeUncommon = false
	end
	if GearUpgradeCostTabDB.includeRare == nil then
		GearUpgradeCostTabDB.includeRare = false
	end
	if GearUpgradeCostTabDB.includeWarbound == nil then
		GearUpgradeCostTabDB.includeWarbound = false
	end
	if GearUpgradeCostTabDB.prioritiseTier == nil then
		GearUpgradeCostTabDB.prioritiseTier = true
	end
	if GearUpgradeCostTabDB.showCrests == nil then
		GearUpgradeCostTabDB.showCrests = false
	end
	SetupCharacterFrameTab()
end)
