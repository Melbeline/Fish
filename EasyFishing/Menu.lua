-- Easy Fishing - the portrait's right-click menu: a Fishing section at its end: the Fishing mode box, then
-- one line: a speaker (click: every sound off, the slider to the left, a "forbidden" sign on it; click again
-- or move the slider right: the sound back) and the sound effects volume slider, 0 to 100. The line is as
-- narrow as the menu's own entries: the menu keeps its width.
-- At the end: the game lets an addon add only after its own entries (one put higher, or one of the game's
-- moved, rewrites the menu's own list from the addon's code: the game's entries moved are then refused what
-- they do). Not in combat: the menu's buttons made for an addon's entries are refused their frame level then,
-- and the game shows "Easy Fishing has been blocked"; the menu is the game's own until the fight ends.

local _, ns = ...
local L = ns.L
local W, H = 128, 24
local MEDIA = "Interface\\AddOns\\EasyFishing\\Media\\"
local line

local function Has(atlas) return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) ~= nil end
-- The speaker: the game's own chat-frame speaker button (its dark square, the speaker with its waves; its
-- speaker alone when muted, with a "forbidden" sign)
local function SpeakerIcon(tex, muted)
  local atlas = muted and "chatframe-button-icon-speaker-off" or "chatframe-button-icon-speaker-on"
  -- the texture's look is set again in full at each change (a tint, a fade or a desaturation left over from
  -- the previous state would otherwise stay: the icon came back dimmed after a mute then an unmute)
  tex:SetDesaturated(false)
  tex:SetVertexColor(1, 1, 1, 1)
  tex:SetAlpha(1)
  tex:SetBlendMode("BLEND")
  tex:SetTexCoord(0, 1, 0, 1)
  if Has(atlas) then tex:SetAtlas(atlas, false) else tex:SetTexture(MEDIA .. "Speaker") end
  tex:SetDesaturated(false)
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
  SpeakerIcon(f.icon, muted)
  f.forbidden:SetShown(muted)
  -- the button itself back to its resting look (a click leaves it in its pushed or disabled state)
  local speaker = f.speaker
  if speaker then
    if speaker.Enable and not speaker:IsEnabled() then speaker:Enable() end
    if not speaker:IsMouseOver() and speaker.SetButtonState then speaker:SetButtonState("NORMAL") end
    speaker:SetAlpha(1)
    f.icon:ClearAllPoints()
    f.icon:SetPoint("CENTER", speaker, "CENTER", 0, 0)
  end
  f.filling = nil
end

local function Line()
  if line then return line end
  -- one frame of this addon's, lent to the menu while it is open
  local f = CreateFrame("Frame", nil, UIParent)
  f:SetSize(W, H)
  f:Hide()
  local speaker = CreateFrame("Button", nil, f)
  speaker:SetSize(22, 21) -- (the chat's 27 x 26, smaller: the menu's line)
  speaker:SetPoint("LEFT", f, "LEFT", -2, 0) -- (a hair left: a gap before the slider's arrow)
  if Has("chatframe-button-up") then
    speaker:SetNormalAtlas("chatframe-button-up")
    speaker:SetPushedAtlas("chatframe-button-down")
    speaker:SetHighlightAtlas("chatframe-button-highlight", "ADD")
  end
  -- the icon above the button's own textures, as the game's speaker button has it (OVERLAY): the button
  -- draws its normal and pushed textures in ARTWORK, and an icon in that layer went under its dark square
  -- once clicked (the speaker shown dimmed after a mute then an unmute, until a reload)
  f.icon = speaker:CreateTexture(nil, "OVERLAY")
  f.icon:SetDrawLayer("OVERLAY", 0)
  f.icon:SetSize(12, 12)
  f.icon:SetPoint("CENTER", speaker, "CENTER", 0, 0)
  SpeakerIcon(f.icon, false)
  speaker:SetScript("OnMouseDown", function() f.icon:SetPoint("CENTER", speaker, "CENTER", -1, -1) end)
  speaker:SetScript("OnMouseUp", function() f.icon:SetPoint("CENTER", speaker, "CENTER", 0, 0) end)
  f.forbidden = speaker:CreateTexture(nil, "OVERLAY")
  f.forbidden:SetDrawLayer("OVERLAY", 2) -- (above the icon)
  f.forbidden:SetSize(11, 11)
  f.forbidden:SetPoint("CENTER", speaker, "BOTTOMRIGHT", -4, 5)
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
  slider:SetPoint("LEFT", f, "LEFT", 23, 0)
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
  if InCombatLockdown() then return end
  if not (ns.db and root.CreateTitle and root.CreateCheckbox) then return end
  Part(function() if root.CreateDivider then root:CreateDivider() end end)
  Part(function() root:CreateTitle(L.FISHING) end)
  Part(function()
    local box = root:CreateCheckbox(L.MODE, function() return ns:Mode() end, function() ns:SetMode(not ns:Mode()) end)
    if box and box.SetTooltip then
      box:SetTooltip(function(tooltip)
        GameTooltip_SetTitle(tooltip, L.MODE)
        GameTooltip_AddNormalLine(tooltip, ns:ModeTip())
      end)
    end
  end)
  if MinimalSliderWithSteppersMixin and root.CreateFrame then
    Part(function()
      local description = root:CreateFrame()
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
end

if Menu and Menu.ModifyMenu and MenuUtil then
  Menu.ModifyMenu("MENU_UNIT_SELF", AddEntries)
end
