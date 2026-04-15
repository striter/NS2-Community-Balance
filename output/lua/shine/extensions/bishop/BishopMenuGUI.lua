-- NOTE: Credit to the Shine developers: Most of this is an adaptation of their
-- configuration UI.

Script.Load("lua/shine/extensions/bishop/BishopMenuData.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local SGUI = Shine.GUI
local Units = SGUI.Layout.Units
local Auto = Units.Auto
local HighResScaled = Units.HighResScaled
local Percentage = Units.Percentage
local Spacing = Units.Spacing
local UnitVector = Units.UnitVector

local Log = Bishop.debug.UILog

--------------------------------------------------------------------------------
-- Technical values.
--------------------------------------------------------------------------------

local kMenuWidth = 800
local kMenuHeight = 600
local kTabHeight = 40
local kTabHeightHorizontal = 28 -- 36
local kTitleHeight = 24
local kTitleMargin = 7

local kEasingTime = 0.25

local kBlurOpacity = 0.75
local kBlurRadius = 16

local kPadding = HighResScaled(8)
local kScrollbarPadding = HighResScaled(8)

-- Checkbox.
local kCheckboxSize = 18 -- 24

-- Slider.
local kSliderRightPadding = 64
local kSliderHeight = 24 -- 32

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

BishopS.MenuGUI.size = UnitVector(
  Units.Integer(HighResScaled(kMenuWidth)),
  Units.Integer(HighResScaled(kMenuHeight)))
local consoleCommand = "bishop_set"
local kDebug = Bishop.debug.userInterface -- UI debugging flag.

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

local function NeedsToScale()
	local w, h = SGUI.GetScreenSize()
	return h > 1080
end

local function GetSmallFont()
	if NeedsToScale() then
		return SGUI.FontManager.GetFont("kAgencyFB", 27)
	end
	--return Fonts.kAgencyFB_Small
  return SGUI.FontManager.GetFont("kAgencyFB", 24)
end

local function GetSmallFontAlt()
  if NeedsToScale() then
    return SGUI.FontManager.GetFont("kAgencyFB", 24)
  end
  return SGUI.FontManager.GetFont("kAgencyFB", 20)
end

local function GetMediumFont()
  if NeedsToScale() then
    return SGUI.FontManager.GetFont("kAgencyFB", 32)
  end
  --return Fonts.kAgencyFB_Medium
  return SGUI.FontManager.GetFont("kAgencyFB", 28)
end

local function SetSetting(data, value)
  if not Bishop.SettingUpdater.noBroadcast then
    BishopS.Plugin:SendNetworkMessage("Bishop_SetSetting",
      {
        Container = data.container,
        Setting = data.variable,
        Value = tostring(value)
      }, true)
  end
end

local function GetSetting(data)
  return Bishop.settings[data.container][data.variable]
end

local function GetSettingFromServer(data)
  BishopS.Plugin:SendNetworkMessage("Bishop_GetSetting",
    {
      Container = data.container,
      Setting = data.variable
    }, true)
end

local function GetEnabled(data)
  if not data.requires then
    return true
  end

  for _, setting in ipairs(data.requires) do
    if not Bishop.settings[data.container][setting] then
      return false
    end
  end
  return true
end

local function CreatePanelHooks(elements)
  Shine.Hook.Add("OnBishopSettingsChanged", "BishopPanelUpdate",
    function()
      Bishop.SettingUpdater.noBroadcast = true

      -- It's unnecessary to update every single element for a single setting
      -- change, but it certainly makes the logic simpler.
      for _, element in ipairs(elements) do
        element.Update(element.element)
      end

      Bishop.SettingUpdater.noBroadcast = false
    end)
end

local function DestroyPanelHooks()
  Shine.Hook.Remove("OnBishopSettingsChanged", "BishopPanelUpdate")
end

--------------------------------------------------------------------------------
-- Menu visibility.
--------------------------------------------------------------------------------

SGUI:AddMixin(BishopS.MenuGUI, "Visibility")

function BishopS.MenuGUI:SetIsVisible(visible, ignoreAnim)
  if kDebug then Log("MenuGUI:SetVisibility(%s)", visible) end

  if self.visible == visible then
    if visible then
      SGUI:SetWindowFocus(self.menu)
    end
    return
  end

  if not self.menu then
    self:Create()
  end

  Shine.AdminMenu.AnimateVisibility(self.menu, visible, self.visible,
    kEasingTime, self.pos, ignoreAnim)
  self.visible = visible
end

--------------------------------------------------------------------------------
-- Menu creation and destruction.
--------------------------------------------------------------------------------

function BishopS.MenuGUI:Create()
  if kDebug then Log("MenuGUI:Create()") end
  if self.menu then
    return
  end

  -- Window creation.
  self.menu = SGUI:Create("TabPanel")
  local menu = self.menu
  menu:SetDebugName("BishopConfigMenuWindow")

  -- Window positioning.
  menu:SetAnchor("CentreMiddle")
  menu:SetAutoSize(self.size, true)
  self.pos = menu:GetSize() * -0.5
  menu:SetPos(self.pos)

  -- TabPanel specifics.
  menu:SetVerticalLayoutMode(menu.VerticalLayoutModeType.COMPACT)
	menu:UseAutoTabWidth()
	menu:SetTabHeight(Units.Integer(HighResScaled(kTabHeight)):GetValue())
	menu:SetFontScale(GetSmallFont())
  menu:AddCloseButton()
  menu.TitleBarHeight = HighResScaled(kTitleHeight):GetValue()
  menu:SetExpanded(false) -- TODO: Remember and save.
  self:PopulateTabs(menu)

  menu:SetBoxShadow({
		BlurRadius = HighResScaled(kBlurRadius):GetValue(),
		Colour = Colour(0, 0, 0, kBlurOpacity)
	})

  menu:CallOnRemove(function()
    if kDebug then Log("Menu - CallOnRemove()") end
    if self.ignoreMove then
      return
    end

    if self.visible then
      SGUI:EnableMouse(false)
      self.visible = false
    end

    self.menu = nil
  end)

  menu.OnClose = function()
    if kDebug then Log("Menu - OnClose()") end
    self:SetIsVisible(false)
    return true
  end

  menu.OnPreTabChange = function(panel)
    if not panel.ActiveTab then
      return
    end

    local tab = self.tabs[panel.ActiveTab]
    if tab and tab.OnCleanup then
      tab.Data = tab.OnCleanup(panel.ContentPanel)
    end
  end
end

function BishopS.MenuGUI:PopulateTabs(menu)
  local tabs = self.tabs
  for i = 1, #tabs do
    local tab = tabs[i]
    local tabEntry = menu:AddTab(
      tab.name,
      function(panel)
        tab.OnInit(panel, tab.data)
      end,
      tab.icon)
  end
end

function BishopS.MenuGUI:AddTab(name, tab)
  if not self.tabs[name] then
    tab.name = name
    self.tabs[name] = tab
    self.tabs[#self.tabs + 1] = tab
  end
end

--------------------------------------------------------------------------------
-- Type helpers.
--------------------------------------------------------------------------------

local function CreateLabelContainer(panel, data, Create)
  local subPanel = panel:Add("Panel")
  local layout = SGUI.Layout:CreateLayout("Vertical")
  subPanel:SetStyleName("RadioBackground")
  subPanel:SetAutoSize(UnitVector(Percentage.ONE_HUNDRED, Units.Auto.INSTANCE))

  local label = subPanel:Add("Label")
  label:SetFontScale(GetSmallFont())
  label:SetText(data.text)
  label:SetAutoSize(UnitVector(Percentage.ONE_HUNDRED, Units.Auto.INSTANCE))
  label:SetMargin(Spacing(0, 0, 0, kPadding))
  layout:AddElement(label)

  local element = Create(subPanel, data)
  layout:AddElement(element)
  subPanel:SetLayout(layout, true)

  return subPanel, element
end

local kElementTypes = {
  button = {
    Create = function(panel, data)
      local button = panel:Add("Button")
      button.settingData = data
      button:SetFontScale(GetSmallFont())
      button:SetText(data.text)
      button:SetAutoSize(UnitVector(HighResScaled(200), HighResScaled(50)))

      button:SetEnabled(GetEnabled(data))

      return button, button
    end,
    Update = function(button)
      button:SetEnabled(GetEnabled(button.settingData))
    end
  },
  checkbox = {
    Create = function(panel, data)
      local checkbox = panel:Add("CheckBox")
      checkbox.settingData = data
      checkbox:SetFontScale(GetSmallFont())
      checkbox:AddLabel(data.text)
      checkbox:SetAutoSize(UnitVector(HighResScaled(kCheckboxSize),
        HighResScaled(kCheckboxSize)))

      checkbox:SetChecked(GetSetting(data))
      checkbox:SetEnabled(GetEnabled(data))

      checkbox.OnChecked = function(checkbox, value)
        SetSetting(checkbox.settingData, value)
        GetSettingFromServer(checkbox.settingData)
      end

      return checkbox, checkbox
    end,
    Update = function(checkbox)
      checkbox:SetChecked(GetSetting(checkbox.settingData))
      checkbox:SetEnabled(GetEnabled(checkbox.settingData))
    end
  },
  dynamiclabel = {
    Create = function(panel, data)
      local label = panel:Add("Label")
      label.settingData = data
      label:SetFontScale(GetSmallFontAlt())
      label:SetText(data.text)
      label:SetAutoSize(UnitVector(Percentage.ONE_HUNDRED, Units.Auto.INSTANCE))
      label:SetMargin(Spacing(0, 0, 0, kPadding))

      return label, label
    end,
    Update = function(label)
      local text = label.settingData.text .. Bishop.settings
        [label.settingData.container][label.settingData.variable]
      label:SetText(text)
    end
  },
  hint = {
    Create = function(panel, data)
      local hint = panel:Add("Hint")
      hint:SetStyleName("Info")
      hint:SetMargin(Spacing(0, kPadding, 0, data.last and 0 or kPadding))
      hint:SetText(data.description)
      hint:SetFontScale(GetSmallFont())
      hint:SetAutoSize(UnitVector(Percentage.ONE_HUNDRED, Units.Auto.INSTANCE))

      return hint
    end
  },
  label = {
    Create = function(panel, data)
      local label = panel:Add("Label")
      label:SetFontScale(GetSmallFont())
      label:SetText(data.text)
      label:SetAutoSize(UnitVector(Percentage.ONE_HUNDRED, Units.Auto.INSTANCE))
      label:SetMargin(Spacing(0, 0, 0, kPadding))

      return label
    end
  },
  slider = {
    Create = function(panel, data)
      return CreateLabelContainer(panel, data, function(panel, data)
        local slider = panel:Add("Slider")
        slider.settingData = data
        slider:SetFontScale(GetSmallFont())
        slider:SetBounds(data.min, data.max)
        slider:SetDecimals(not data.integersOnly)
        slider:SetAutoSize(UnitVector(
          Percentage.ONE_HUNDRED - HighResScaled(kSliderRightPadding),
          HighResScaled(kSliderHeight)))
        slider:SetMargin(Spacing(HighResScaled(kSliderRightPadding / 2), 0, 0,
          0))

        slider:SetValue(Bishop.settings[data.container][data.variable])

        function slider:OnValueChanged(value)
          SetSetting(slider.settingData, value)
          GetSettingFromServer(slider.settingData)
        end

        return slider
      end)
    end,
    Update = function(slider)
      slider:SetValue(GetSetting(slider.settingData))
      slider:SetEnabled(GetEnabled(slider.settingData))
    end
  }
}

--------------------------------------------------------------------------------
-- Generate tabs.
--------------------------------------------------------------------------------

do
  BishopS.MenuGUI.tabs = {}
  for _, vtab in ipairs(BishopS.MenuGUI.Data) do
    BishopS.MenuGUI:AddTab(vtab.name, {
      icon = vtab.icon,
      OnInit = function(panel, data)
        local layout = SGUI.Layout:CreateLayout("Vertical", {
          Padding = Spacing(kPadding, kPadding, kPadding, kPadding)
        })

        -- Title text.
        local title = panel:Add("Label")
        title:SetFontScale(GetMediumFont())
        title:SetText(vtab.longName)
        title:SetMargin(Spacing(0, 0, 0, HighResScaled(kTitleMargin)))
        layout:AddElement(title)

        -- Settings tabs.
        local tabs = panel:Add("TabPanel")
        local tabWidth = Units.Max()
        tabs:SetFill(true)
        tabs:SetTabWidth(tabWidth)
        tabs:SetTabHeight(HighResScaled(kTabHeightHorizontal):GetValue())
        tabs:SetFontScale(GetSmallFont())
        tabs:SetHorizontal(true)
        panel.settingsTabs = tabs
        BishopS.MenuGUI.settingsTabs = tabs

        -- Array to hold elements that need updating.
        panel.updateElements = {}

        -- Populate the horizontal tabs.
        for _, data in ipairs(vtab.data) do
          -- Create the tab.
          local settingTab = tabs:AddTab(data.name,
            -- This is an implicit OnInit function and isn't actually called
            -- until the tab has been clicked.
            function(settingPanel)
              -- Initializing a new tab means the old one was destroyed.
              table.clear(panel.updateElements)

              settingPanel:SetScrollable()
              settingPanel:SetScrollbarWidth(kScrollbarPadding:GetValue())
              settingPanel:SetScrollbarPos(Vector2(
                -kScrollbarPadding:GetValue(), 0))
              settingPanel:SetScrollbarHeightOffset(0)
              settingPanel:SetResizeLayoutForScrollbar(true)
              local settingLayout = SGUI.Layout:CreateLayout("Vertical", {
                Padding = Spacing(kPadding, kPadding, kPadding, kPadding) 
              })

              for i, setting in ipairs(data.settings) do
                local element, update = kElementTypes[setting.type].Create(
                  settingPanel, setting)
                settingLayout:AddElement(element)

                if update then
                  local updatePackage = {
                    element = update,
                    Update = kElementTypes[setting.type].Update
                  }
                  if kDebug then Log("Add element to panel.updateElements.") end
                  panel.updateElements[#panel.updateElements + 1] =
                    updatePackage
                end

                if setting.description then
                  local hint = kElementTypes["hint"].Create(settingPanel,
                    setting)
                  settingLayout:AddElement(hint)
                elseif i ~= #data.settings then
                  element:SetMargin(Spacing(0, 0, 0, kPadding))
                end
              end

              settingPanel:SetLayout(settingLayout, true)
            end, data.icon)

          tabWidth:AddValue(Units.Auto(settingTab.TabButton)
            + HighResScaled(16))
        end

        layout:AddElement(tabs)
        panel:SetLayout(layout)

        CreatePanelHooks(panel.updateElements)
      end,
      OnCleanup = function(panel)
        table.clear(panel.updateElements)
        DestroyPanelHooks()
      end
    })
  end
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
