-- Easy Fishing - its page in the game's options (Esc > Options > AddOns > Easy Fishing), and /easyfishing
local _, ns = ...
local L = ns.L

local function Register()
  if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterProxySetting) then return end
  local VT = Settings.VarType or {}
  local category = Settings.RegisterVerticalLayoutCategory(L.TITLE)
  local mode = Settings.RegisterProxySetting(category, "EASYFISHING_MODE", VT.Boolean or "boolean", L.MODE, false,
    function() return ns:Mode() end, function(value) ns:SetMode(value) end)
  Settings.CreateCheckbox(category, mode, ns:ModeTip())
  local volume = Settings.RegisterProxySetting(category, "EASYFISHING_VOLUME", VT.Number or "number", L.SFX, 100,
    function() return ns:Muted() and 0 or ns:Volume() end, function(value) ns:SetVolume(value) end)
  local options = Settings.CreateSliderOptions(0, 100, 5)
  if options.SetLabelFormatter and MinimalSliderWithSteppersMixin then
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value) return ("%d%%"):format(value) end)
  end
  Settings.CreateSlider(category, volume, options)
  Settings.RegisterAddOnCategory(category)
  ns.category = category
  ns.settings = { mode, volume }
end

-- Changed elsewhere (the portrait's menu, the game's audio options, Ctrl+S): the page follows
local notifying
table.insert(ns.refresh, function()
  if notifying or not ns.settings then return end
  notifying = true -- (the page's controls set the value back: once)
  for _, setting in ipairs(ns.settings) do
    if setting.NotifyUpdate then pcall(setting.NotifyUpdate, setting) end
  end
  notifying = false
end)

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self)
  self:UnregisterEvent("PLAYER_LOGIN")
  local ok, err = pcall(Register)
  if not ok then print("|cff7fbfffEasy Fishing|r: options: " .. tostring(err)) end
end)

SLASH_EASYFISHING1 = "/easyfishing"
SLASH_EASYFISHING2 = "/ef"
SlashCmdList.EASYFISHING = function()
  if ns.category and Settings and Settings.OpenToCategory then Settings.OpenToCategory(ns.category:GetID()) end
end

-- /rl: the interface reloaded (as /reload)
SLASH_EASYFISHINGRELOAD1 = "/rl"
SlashCmdList.EASYFISHINGRELOAD = function()
  if C_UI and C_UI.Reload then C_UI.Reload() else ReloadUI() end
end
