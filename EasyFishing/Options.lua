-- Easy Fishing - its page in the game's options (Esc > Options > AddOns > Easy Fishing), and /easyfishing:
-- the fishing mode, the sound effects volume and two buttons: set the Fish / Reel in key, remove it
local _, ns = ...
local L = ns.L

---------------------------------------------------------------------------
-- The key binding: a button that waits for the next key or mouse button and binds it to
-- "Fish / Reel in" (replacing the former key); Esc cancels. Kept in the game's own saved bindings.
---------------------------------------------------------------------------
local ACTION = "CLICK EasyFishingButton:LeftButton" -- (Bindings.xml)
local TAG = "|cff7fbfffEasy Fishing|r: "
local MODIFIER = { LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true,
  LMETA = true, RMETA = true, UNKNOWN = true } -- (a modifier alone: the wait goes on, for the key it goes with)
local keyData -- the button's data: its text is read again each time the page is shown
local keyInit -- the button's initializer (the page's list knows its control by it)
local keyButton -- the button, as last clicked
local capture -- the full-screen frame that waits for the key, once made

local function KeyText()
  local texts = {}
  for _, key in ipairs({ GetBindingKey(ACTION) }) do
    local ok, text = pcall(GetBindingText, key)
    texts[#texts + 1] = ok and text or key
  end
  return #texts > 0 and table.concat(texts, ", ") or L.NOT_BOUND
end

-- The key button as shown now: found in the page's list; else the one last clicked, if it is still ours
local function KeyButton()
  local list = SettingsPanel and SettingsPanel.GetSettingsList and SettingsPanel:GetSettingsList()
  local box = list and list.ScrollBox
  if keyInit and box and box.ForEachFrame then
    local found
    pcall(box.ForEachFrame, box, function(frame, elementData)
      if elementData == keyInit and frame.Button then found = frame.Button end
    end)
    if found then return found end
  end
  if keyButton and keyButton.SetText then
    local element = keyButton.GetParent and keyButton:GetParent()
    -- (the page recycles its controls: only ours is touched)
    if not (element and element.data and keyData and element.data ~= keyData) then return keyButton end
  end
end

-- The button's text: the key now bound (or the wait)
local function ShowKey(text)
  text = text or KeyText()
  if keyData then keyData.buttonText = text end
  local button = KeyButton()
  if button then button:SetText(text) end
end

local function SaveKeys()
  if SaveBindings then SaveBindings(GetCurrentBindingSet and GetCurrentBindingSet() or 1) end
end

local function Chord(key)
  if CreateKeyChordString then return CreateKeyChordString(key) end
  local parts = {}
  if IsAltKeyDown() then parts[#parts + 1] = "ALT" end
  if IsControlKeyDown() then parts[#parts + 1] = "CTRL" end
  if IsShiftKeyDown() then parts[#parts + 1] = "SHIFT" end
  if IsMetaKeyDown and IsMetaKeyDown() then parts[#parts + 1] = "META" end
  parts[#parts + 1] = key
  return table.concat(parts, "-")
end

local function MouseKey(button)
  if button == "MiddleButton" then return "BUTTON3" end
  local n = tostring(button):match("^Button(%d+)$")
  return n and ("BUTTON" .. n) or nil
end

local function Bind(key)
  if not key then return end
  if InCombatLockdown() then print(TAG .. L.COMBAT) return end
  local was = GetBindingAction and GetBindingAction(key) or ""
  local former = { GetBindingKey(ACTION) }
  if not SetBinding(key, ACTION) then return end -- (the new key first: the old ones are kept if it fails)
  for _, old in ipairs(former) do
    if old ~= key then SetBinding(old) end
  end
  SaveKeys()
  local ok, shown = pcall(GetBindingText, key)
  print(TAG .. L.KEY_SET:format(ok and shown or key))
  if was ~= "" and was ~= ACTION then -- (that key did something else: it is told)
    local ok2, name = pcall(GetBindingName, was)
    print(TAG .. L.KEY_WAS:format(ok and shown or key, ok2 and name or was))
  end
end

local function Capture()
  if capture then return capture end
  local f = CreateFrame("Frame", nil, UIParent)
  f:SetFrameStrata("FULLSCREEN_DIALOG")
  f:SetAllPoints(UIParent)
  f:EnableMouse(true)
  f:EnableMouseWheel(true)
  f:EnableKeyboard(true)
  f:Hide()
  local shade = f:CreateTexture(nil, "BACKGROUND")
  shade:SetAllPoints()
  shade:SetColorTexture(0, 0, 0, .5)
  local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  text:SetPoint("CENTER", f, "CENTER", 0, 60)
  text:SetJustifyH("CENTER")
  f.text = text
  f:RegisterEvent("PLAYER_REGEN_DISABLED") -- (bindings can't be changed in combat)
  f:SetScript("OnEvent", function(self) self:Hide() end)
  f:SetScript("OnShow", function(self)
    self.text:SetText(L.CAPTURE)
    ShowKey(L.PRESS)
  end)
  f:SetScript("OnHide", function() ShowKey() end) -- (whatever the way out: the key now bound is shown)
  f:SetScript("OnKeyDown", function(self, key)
    self:SetPropagateKeyboardInput(false) -- (the key goes no further: Esc does not close the options)
    if key == "ESCAPE" then self:Hide() return end
    if MODIFIER[key] then return end
    Bind(Chord(key))
    self:Hide()
  end)
  f:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" or button == "RightButton" then
      print(TAG .. L.NO_CLICK) -- (the game's own list doesn't take them either: every click would fish)
      return
    end
    Bind(Chord(MouseKey(button)))
    self:Hide()
  end)
  f:SetScript("OnMouseWheel", function(self, delta)
    Bind(Chord(delta > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN"))
    self:Hide()
  end)
  capture = f
  return f
end

local function StartCapture(button)
  if InCombatLockdown() then print(TAG .. L.COMBAT) return end
  keyButton = button
  Capture():Show()
end

-- The key removed: nothing is bound to Fish / Reel in until one is set again
local function Unbind()
  if InCombatLockdown() then print(TAG .. L.COMBAT) return end
  local keys = { GetBindingKey(ACTION) }
  if #keys == 0 then print(TAG .. L.KEY_NONE) return end
  local shown = KeyText()
  for _, key in ipairs(keys) do SetBinding(key) end
  SaveKeys()
  ShowKey()
  print(TAG .. L.KEY_REMOVED:format(shown))
end

local function ButtonInitializer(name, text, click, tip)
  if CreateSettingsButtonInitializer then
    return CreateSettingsButtonInitializer(name, text, click, tip, true)
  elseif Settings.CreateElementInitializer then
    return Settings.CreateElementInitializer("SettingsButtonControlTemplate",
      { name = name, buttonText = text, buttonClick = click, tooltip = tip })
  end
end

local function AddKeyButton(category, layout)
  layout = layout or (SettingsPanel and SettingsPanel.GetLayout and SettingsPanel:GetLayout(category))
  if not (layout and layout.AddInitializer) then error("no layout for the key button") end
  local initializer = ButtonInitializer(L.KEY, KeyText(), StartCapture, L.KEY_TIP)
  if not initializer then error("no button template") end
  keyInit = initializer
  keyData = initializer.GetData and initializer:GetData() or initializer.data
  layout:AddInitializer(initializer)
  local remove = ButtonInitializer(L.KEY_CLEAR, L.KEY_CLEAR_BTN, Unbind, L.KEY_CLEAR_TIP)
  if remove then layout:AddInitializer(remove) end
  -- the options closed meanwhile: the wait ends
  if SettingsPanel and SettingsPanel.HookScript then
    SettingsPanel:HookScript("OnHide", function() if capture then capture:Hide() end end)
  end
end

local function Register()
  if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterProxySetting) then return end
  local VT = Settings.VarType or {}
  local category, layout = Settings.RegisterVerticalLayoutCategory(L.TITLE)
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
  local ok, err = pcall(AddKeyButton, category, layout)
  if not ok then print(TAG .. "options: key button: " .. tostring(err)) end
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
events:RegisterEvent("UPDATE_BINDINGS")
events:SetScript("OnEvent", function(self, event)
  if event == "UPDATE_BINDINGS" then -- (changed in the game's key bindings page too)
    if keyData and not (capture and capture:IsShown()) then ShowKey() end
    return
  end
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
