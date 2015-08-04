local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local Image = require "widgets/image"
local BadgeWheel = require("chores-lib.badgewheel")
local CountDown = require("chores-lib.countdown")
local Inst = require "chores-lib.instance"

CW = nil

local PLACER_GAP = { -- плотность саженцев
  pinecone = 2,
  acorn = 2,
  dug_grass = 1,
  dug_berrybush = 2,
  dug_sapling = 1
}

local ATLASINV = "images/inventoryimages.xml"
local MAX_HUD_SCALE = 1.00 --[[1.25]] -- масштабирование интерфейса мода
local ChoresWheel = Class(Widget, function(self)
  Widget._ctor(self, "Chores")

  self:SetHAnchor(ANCHOR_LEFT)
  self:SetVAnchor(ANCHOR_BOTTOM)
  self:SetScaleMode(SCALEMODE_PROPORTIONAL)
  self:SetMaxPropUpscale(MAX_HUD_SCALE)

  self.root = self:AddChild(Image("images/fepanels.xml","panel_controls.tex")) --panel_mod1.tex

  self.root:SetPosition(400,330) -- позиция центра полотна слева снизу
  self.root:SetTint(1,1,1,0.5) -- ?? (1,1,1,0.5)

  CW = self.root

  self.flag ={
    axe = {pinecone = false, charcoal = false},
    pickaxe = {nitre = false, goldnugget = true, moonrocknugget = false, ice = false},
    backpack = {cutgrass = true, twigs = true, berries = true, flint = true, rocks = true, red_cap = true},
    shovel = {dug_grass = true, dug_berrybush = true, dug_sapling = true},
    book_gardening = {dug_grass = true, dug_berrybush = false, dug_sapling = false, pinecone = false, acorn = false}
  }

  self.layout ={
    {"axe", "pinecone", "charcoal"},
    {"pickaxe", "nitre", "goldnugget", "moonrocknugget", "ice"},
    {"backpack", "cutgrass", "twigs", "berries", "flint", "rocks", "red_cap"},
    {"shovel", "dug_grass", "dug_berrybush", "dug_sapling"},
    {"book_gardening", "dug_grass", "dug_berrybush", "dug_sapling", "pinecone", "acorn"}
  }

  self.root.btns = {}

  -- local x,y = -125, 120
  local d_x,d_y,d_m = 60, 70, 65 -- смещения для иконок по x и по y
  local i_x,i_y = 0, #self.layout

  for i, row in pairs(self.layout) do
    if i_x<#row then i_x=#row
    end
  end

  -- правее и ниже с d_m в x,y

  local k = 1 -- коэффициент рамки
  local m_x, m_y = (i_x+k) * d_x+d_m, (i_y+k) * d_y+d_m -- полотно
  local x, y = (-(i_x-k/2) * d_x+d_m/2)/2, ((i_y-k/2) * d_y-d_m/2)/2 -- смещение кнопок -m_x/2+d_x, m_y/2-d_y
  local tx = x -- сохранение x

  self.root:SetSize(m_x,m_y) -- размер полотна: ширина, высота (500,450)

  for i, row in pairs(self.layout) do
    local task = row[1]
    self.root.btns[task] = {}
    for inx, icon in pairs(row) do
      local btn = self:MakeBtn(task, icon)
      btn:SetPosition( x, y)
      x = x + d_x
    end
    y = y - d_y
    x = tx
  end

end)

function ChoresWheel:Toggle()
  if self.shown then
    self:Hide()

    ThePlayer.components.auto_chores:ForceStop()
  else
    self:Show()
  end
end

function ChoresWheel:MakeBtn(task, icon)
  local btn = self.root:AddChild(ImageButton(ATLASINV, icon .. ".tex"))
  btn.image:SetSize(50,50)

  self.root.btns[task][icon] = btn
  local function updateTint()
    print("updateTint", self.flag[task][icon])
    if self.flag[task][icon] == false then
      btn.image:SetTint(.2,.2,.2,1)
    else
      btn.image:SetTint(1,1,1,1)
    end
  end

  print("ti ", task, icon)
  if task ~= icon then updateTint() end

  btn.updateTint = updateTint
  btn:SetOnClick(function() self:BtnClick(task, icon) end)

  local widget = self
  local _OnGainFocus = btn.OnGainFocus
  btn.OnGainFocus = function (self )
    _OnGainFocus(self)
    widget:BtnGainFocus(task,icon)
  end

  local _OnLoseFocus = btn.OnLoseFocus
  btn.OnLoseFocus = function (self )
    _OnLoseFocus(self)
    widget:BtnLoseFocus(task,icon)
  end

  return btn
end
function ChoresWheel:BtnClick(task, icon)
  if task == icon then
    self:DoTask(icon)
  elseif task == "book_gardening" then
    for k,v in pairs(self.flag[task]) do self.flag[task][k] = false end
    self.flag[task][icon] = true
    for k,v in pairs(self.root.btns[task]) do self.root.btns[task][k].updateTint() end
  else
    self.flag[task][icon] = not self.flag[task][icon]
    self.root.btns[task][icon].updateTint()
  end
end

function ChoresWheel:BtnGainFocus(task, icon)
  if task == "book_gardening" and icon == "book_gardening" then

    if self.placers ~= nil then return end
    self.placers = {}

    local prefab_name = nil
    for prefab, flag in pairs(self.flag[task]) do
      if flag then prefab_name = prefab end
    end
    if prefab_name == nil then return end

      local placerGap = PLACER_GAP[prefab_name]

    local function _find_placer (item)
      if item == nil then return false end
      if prefab_name == "dug_berrybush" and item.prefab == "dug_berrybush2" then
        return true
      end
      return item.prefab == prefab_name
    end

    local placer_item = Inst(ThePlayer):inventory_FindItems(_find_placer)[1]

    print(placer_item)
    if placer_item == nil then
      return
    end

    if Inst(placer_item):inventoryitem() == nil then
      return
    end

    local placer_name = Inst(placer_item):inventoryitem_GetDeployPlacerName()

    self:StartUpdating()

    for xOff = 0, 4, 1 do
      for zOff = 0, 3, 1 do
        local deployplacer = SpawnPrefab(placer_name)
        table.insert( self.placers, deployplacer)
        deployplacer.components.placer:SetBuilder(ThePlayer, nil, placer_item)

        local function _testfn(pt)
          local test_item = Inst(ThePlayer):inventory_GetActiveItem()

          if _find_placer(test_item) == false then
            test_item = Inst(ThePlayer):inventory_FindItems(_find_placer)[1]
          end
          return test_item ~= nil and Inst(test_item):inventoryitem_CanDeploy(pt)
        end

        deployplacer.components.placer.testfn = _testfn

        local function _replace(self, dt)

          self.can_build = self.testfn == nil or self.testfn(self.inst:GetPosition())
          local color = self.can_build and Vector3(.25,.75,.25) or Vector3(.75,.25,.25)
          self.inst.AnimState:SetAddColour(color.x, color.y, color.z,0)

        end
        deployplacer.components.placer.OnUpdate = _replace

        local function _reposition(self)
          local pos = Vector3(ThePlayer.Transform:GetWorldPosition())
          pos = Vector3( math.floor(pos.x), math.floor(pos.y), math.floor(pos.z))
          self.Transform:SetPosition((pos + self.offset ):Get())
        end
        deployplacer.offset = Vector3( (xOff -1) * placerGap, 0, (zOff-1) * placerGap)
        deployplacer.reposition = _reposition
        deployplacer:reposition()
        deployplacer.components.placer:OnUpdate(0)

      end
    end

  end
end

function ChoresWheel:BtnLoseFocus(task, icon)
  if task == "book_gardening" and icon == "book_gardening" then
    if self.placers == nil then return end
    for k, v in pairs(self.placers) do
      v:Remove()
    end
    self:StopUpdating()
    self.placers = nil
  end
end

function ChoresWheel:DoTask(task)
  local flags = {}
  for key, flag in pairs(self.flag[task]) do
    flags[key] = flag
  end

  ThePlayer.components.auto_chores:SetTask(task, flags, self.placers)
  self.placers = nil
end

function ChoresWheel:OnUpdate(dt )
  if self.placers == nil then return end
  for k, v in pairs(self.placers) do
    v:reposition()
    v.components.placer:OnUpdate(dt)
  end
end

return ChoresWheel