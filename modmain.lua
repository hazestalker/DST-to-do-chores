local _G = GLOBAL
local TUNING = _G.TUNING

local is_dst
function IsDST()
  if is_dst == nil then
    is_dst = GLOBAL.kleifileexists("scripts/networking.lua") and true or false
  end
  return is_dst
end
_G.IsDST = IsDST

function SetTheWorld()
  if IsDST() == false then
    local TheWorld = _G.GetWorld()
    _G.rawset(_G, "TheWorld", TheWorld)
  end
end
function SetThePlayer(player)
  if IsDST() == false then
    _G.rawset(_G, "ThePlayer", player)
  end
end

local ToggleButton = GetModConfigData("togglekey")

function OnActivated(player)
  _G.ThePlayer:AddComponent("auto_chores")
end

function SimPostInit(player)

  print("SimPostInit")
  if IsDST() then
    _G.TheWorld:ListenForEvent("playeractivated", OnActivated)

  else
    SetTheWorld()
    SetThePlayer(player)
    OnActivated(player)
  end

end

AddSimPostInit(SimPostInit)

local function IsDefaultScreen()
  return GLOBAL.TheFrontEnd:GetActiveScreen().name:find("HUD") ~= nil
end

local function AddWidget(parent)

  local ControlWidget = _G.require "widgets/chores"

  local widget = parent:AddChild(ControlWidget())
  widget:Hide()

  GLOBAL.TheInput:AddKeyUpHandler(ToggleButton, function()
    if not IsDefaultScreen() then return end
    widget:Toggle()
  end)
end

Assets = {
  Asset("ATLAS", "images/fepanels.xml"),
  Asset("IMAGE", "images/fepanels.tex"),
}

if IsDST() then
  AddClassPostConstruct( "widgets/controls", function (controls)
    AddWidget(controls)
  end  )
else
  table.insert(Assets, Asset("ATLAS", "images/avatars.xml"))

  table.insert(Assets, Asset("IMAGE", "images/avatars.tex"))

  AddSimPostInit(function()
    local controls = _G.ThePlayer.HUD
    AddWidget(controls)
  end)

end