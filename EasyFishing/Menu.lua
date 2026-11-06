-- Easy Fishing - the portrait's right-click menu: a Fishing section just above the game's "Other Options":
-- the Fishing mode box, then one line: a speaker (click: every sound off, the slider to the left, a
-- "forbidden" sign on it; click again or move the slider right: the sound back) and the sound effects
-- volume slider, 0 to 100. The line is as narrow as the menu's own entries: the menu keeps its width.

local _, ns = ...
local L = ns.L
local W, H = 128, 24
local MEDIA = "Interface\\AddOns\\EasyFishing\\Media\\"
local line

local function Speaker(tex)
  if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("voicechat-icon-speaker") then
    tex:SetAtlas("voicechat-icon-speaker")
  else
    tex:SetTexture(MEDIA .. "Speaker")
  end
end

local function Tip(self)
  if not GameTooltip then return end
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetText(self.tip())
  GameTooltip:Show()
end
local function Untip() if GameTooltip then GameTooltip:Hide() end end

local function Fill(f)
  f.filling = true
  local muted = ns:Muted()
  local value = muted and 0 or ns:Volume()
  f.slider:SetValue(value)
  f.value:SetText(("%d%%"):format(value))
  f.icon:SetDesaturated(muted)
  f.icon:SetAlpha(muted and .7 or 1)
  f.forbidden:SetShown(muted)
  f.filling = nil
end

local function Line()
  if line then return line end
  -- one frame of this addon's, lent to the menu while it is open
  local f = CreateFrame("Frame", nil, UIParent)
  f:SetSize(W, H)
  f:Hide()
  local speaker = CreateFrame("Button", nil, f)
  speaker:SetSize(16, 16)
  speaker:SetPoint("LEFT", f, "LEFT", 0, 0)
  f.icon = speaker:CreateTexture(nil, "ARTWORK")
  f.icon:SetAllPoints()
  Speaker(f.icon)
  local glow = speaker:CreateTexture(nil, "HIGHLIGHT")
  glow:SetAllPoints()
  Speaker(glow)
  glow:SetBlendMode("ADD")
  glow:SetAlpha(.5)
  f.forbidden = speaker:CreateTexture(nil, "OVERLAY")
  f.forbidden:SetSize(12, 12)
  f.forbidden:SetPoint("CENTER", speaker, "BOTTOMRIGHT", -1, 3)
  f.forbidden:SetTexture(MEDIA .. "Forbidden")
  f.forbidden:Hide()
  speaker.tip = function() return ns:Muted() and L.UNMUTE or L.MUTE end
  speaker:SetScript("OnClick", function(self)
    ns:SetMuted(not ns:Muted())
    Fill(f)
    if GameTooltip and GameTooltip:IsOwned(self) then Tip(self) end
  end)
  speaker:SetScript("OnEnter", Tip)
  speaker:SetScript("OnLeave", Untip)
  f.speaker = speaker
  f.value = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  f.value:SetPoint("RIGHT", f, "RIGHT", 0, 0)
  f.value:SetWidth(30)
  f.value:SetJustifyH("RIGHT")
  local slider = CreateFrame("Frame", nil, f, "MinimalSliderWithSteppersTemplate")
  slider:SetPoint("LEFT", speaker, "RIGHT", 1, 0)
  slider:SetPoint("RIGHT", f.value, "LEFT", 0, 0)
  slider:SetHeight(H) -- (the template's 40 would reach over the entry below)
  if slider.Slider then -- the arrows closer in, for a longer track
    slider.Slider:ClearAllPoints()
    slider.Slider:SetPoint("TOPLEFT", 13, 0)
    slider.Slider:SetPoint("BOTTOMRIGHT", -13, 0)
  end
  slider:Init(100, 0, 100, 20) -- 5 % a step
  slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
    if f.filling then return end
    value = math.floor(value + .5)
    if ns:Muted() and value == 0 then return end -- (muted: left at the left end)
    ns:SetVolume(value)
    Fill(f)
  end, f)
  if slider.Slider and slider.Slider.HookScript then
    slider.Slider:HookScript("OnEnter", function(self)
      if not GameTooltip then return end
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(L.SFX)
      GameTooltip:Show()
    end)
    slider.Slider:HookScript("OnLeave", Untip)
  end
  f.slider = slider
  line = f
  return f
end

table.insert(ns.refresh, function() if line and line:IsVisible() then Fill(line) end end)

local failed
local function Part(fn)
  local ok, err = pcall(fn)
  if ok or failed then return end
  failed = true
  print("|cff7fbfffEasy Fishing|r: portrait menu: " .. tostring(err))
end

local function AddEntries(_, root)
  if not (ns.db and root.CreateTitle and root.CreateCheckbox) then return end
  local made = {}
  local function Keep(description) if description then made[#made + 1] = description end return description end
  Part(function() if root.CreateDivider then Keep(root:CreateDivider()) end end)
  Part(function() Keep(root:CreateTitle(L.FISHING)) end)
  Part(function()
    local box = Keep(root:CreateCheckbox(L.MODE, function() return ns:Mode() end, function() ns:SetMode(not ns:Mode()) end))
    if box and box.SetTooltip then
      box:SetTooltip(function(tooltip)
        GameTooltip_SetTitle(tooltip, L.MODE)
        GameTooltip_AddNormalLine(tooltip, ns:ModeTip())
      end)
    end
  end)
  if MinimalSliderWithSteppersMixin and root.CreateFrame then
    Part(function()
      local description = Keep(root:CreateFrame())
      description:AddInitializer(function(frame)
        local f = Line()
        f:SetParent(frame)
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        f:SetFrameLevel(frame:GetFrameLevel() + 2)
        Fill(f)
        f:Show()
        return W, H
      end)
      description:AddResetter(function(frame)
        if not line or line:GetParent() ~= frame then return end -- (already lent again)
        line:Hide()
        line:ClearAllPoints()
        line:SetParent(UIParent)
      end)
    end)
  end
  -- above Other Options (its divider first): the menu's own list, reordered; else left at the end
  Part(function()
    local list = rawget(root, "elementDescriptions") or rawget(root, "elements")
    if type(list) ~= "table" or #made == 0 then return end
    local mine = {}
    for _, d in ipairs(made) do mine[d] = true end
    local rest = {}
    for _, d in ipairs(list) do if not mine[d] then rest[#rest + 1] = d end end
    local at
    local other = UNIT_FRAME_DROPDOWN_SUBSECTION_TITLE_OTHER
    for index, d in ipairs(rest) do
      if other and MenuUtil.GetElementText(d) == other then
        local previous = rest[index - 1]
        at = (previous and MenuUtil.GetElementText(previous) == nil) and index - 1 or index
        break
      end
    end
    if not at then return end
    for i = #list, 1, -1 do list[i] = nil end
    for i = 1, at - 1 do list[#list + 1] = rest[i] end
    for _, d in ipairs(made) do list[#list + 1] = d end
    for i = at, #rest do list[#list + 1] = rest[i] end
  end)
end

if Menu and Menu.ModifyMenu and MenuUtil then
  Menu.ModifyMenu("MENU_UNIT_SELF", AddEntries)
end
