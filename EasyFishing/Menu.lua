-- Easy Fishing - the portrait's right-click menu: at its end, a Fishing section with the Fishing mode box (its
-- tooltip: what it does), while Fishing is learned or the mode is on. Only game menu entries (no frame of its own in
-- the menu), out of combat: the game lets an addon add to this menu only after its own entries, and refuses them in
-- combat.

local _, ns = ...
local L = ns.L

local failed
local function Part(fn)
  local ok, err = pcall(fn)
  if ok or failed then return end
  failed = true
  print("|cff7fbfffEasy Fishing|r: portrait menu: " .. tostring(err))
end

local function AddEntries(_, root)
  if InCombatLockdown() then return end
  if not (ns.sv and root.CreateTitle and root.CreateCheckbox) then return end
  if not (ns.FishingModeOffered and ns:FishingModeOffered()) then return end
  Part(function() if root.CreateDivider then root:CreateDivider() end end)
  Part(function() root:CreateTitle(L.FISHING) end)
  Part(function()
    local box = root:CreateCheckbox(L.MENU_FISHING_MODE, function() return ns:FishingMode() end,
      function() ns:SetFishingMode(not ns:FishingMode()) end)
    if box and box.SetTooltip then
      box:SetTooltip(function(tooltip)
        GameTooltip_SetTitle(tooltip, L.MENU_FISHING_MODE)
        GameTooltip_AddNormalLine(tooltip, L.FISHING_MODE_TIP:format(ns:FishingBoost()))
      end)
    end
  end)
end
ns.MenuEntries = AddEntries -- (for its test)

if Menu and Menu.ModifyMenu then
  Menu.ModifyMenu("MENU_UNIT_SELF", AddEntries)
end
