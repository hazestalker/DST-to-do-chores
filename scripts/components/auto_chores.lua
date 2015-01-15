

local Inst = require "chores-lib.instance" 
local PrefabLibary = require("chores-lib.prefablibrary")  



local ChoreLib = PrefabLibary(function (proto)
  local stat = {} 
  if proto.components.tool ~= nil then
    stat.tool = {}
    stat.tool.CHOP = proto.components.tool:CanDoAction(ACTIONS.CHOP)
    stat.tool.DIG = proto.components.tool:CanDoAction(ACTIONS.DIG)
  end
  return stat
  end)

local function _isChopper(item)
  if item == nil then return false end
  local stat = ChoreLib:Get(item)
  if stat == nil then return false end
  if stat.tool == nil then return false end
  return stat.tool.CHOP
end

local function _isDigger(item)
  if item == nil then return false end
  local stat = ChoreLib:Get(item)
  if stat == nil then return false end
  if stat.tool == nil then return false end
  return stat.tool.DIG
end

local function _IsTree(item)
  return item ~= nil and item:HasTag("tree") and not item:HasTag("stump") and not item:HasTag("burnt")
end

local function _IsStump(item)
  return item ~= nil and item:HasTag("stump") 
end

local function _IsTreeLoot(item)
  if item.prefab == "log" then return true end 
  if item.prefab == "charcoal" then return true end 
  if item.prefab == "pinecone" and item.issapling:value() == false then return true end 
  -- if item.prefab == "acorn" then return true end -- this is Birchnut
  return false
end
local function _IsTreeSeed(item)
  if item.prefab == "pinecone" and item.issapling:value() == false then return true end 
  -- if item.prefab == "acorn" then return true end -- this is Birchnut
  return false
end


local AutoChores = Class(function(self, inst)
  self.inst = inst
  self.INST = Inst(inst)  

  print("AutoChores") 
  self.inst:ListenForEvent("actionfailed", function(inst) inst.components.auto_chores:StopLoop() end)

  
  self.ActionButtonDown = true
  self:OverridePC()
  self:OverrideInput()

  end,
  nil,
  { })

function AutoChores:SetTask(task)   
  self.task = task -- "LumberJack"
  -- print("ToBeLumberJack", self.task) 
end 

function AutoChores:StopLoop() 
  print("StopLoop")
  if self.task ~= nil then  
    self.task = nil 
  end
end
function AutoChores:GetAction()
  if self.task == "LumberJack" then
    return self:GetLumberJackAction() 
  elseif self.task == "Planter" then
    return self:GetPlanterAction() 
  end
end

function AutoChores:OverrideInput()
  local auto_chores = self
  local _fnOrig = TheInput.IsControlPressed
  local function _fnOver(self, control)
    if auto_chores.task ~= nil then
      if control == CONTROL_ACTION then return auto_chores.ActionButtonDown end
    end
    return _fnOrig(self, control)
  end
  TheInput.IsControlPressed = _fnOver
end

function AutoChores:OverridePC()
  local auto_chores = self
  local PLAYER = Inst(self.inst)
  local pc = self.inst.components.playercontroller



  local _fnOrig =  pc.GetActionButtonAction
  local function _fnOver(self, force_target)

    if auto_chores.task == nil then return _fnOrig(self, force_target) end

    --Don't want to spam the action button before the server actually starts the buffered action
    if not self.ismastersim and (self.remote_controls[CONTROL_ACTION] or 0) > 0 then
      return
    end
    if not self:IsEnabled() then
      return
    end


    local isdoing, isworking
    if self.inst.sg == nil then
      isdoing = self.inst:HasTag("doing")
      isworking = self.inst:HasTag("working")
    elseif not self.ismastersim and self.inst:HasTag("autopredict") then
      isdoing = self.inst.sg:HasStateTag("doing")
      isworking = self.inst.sg:HasStateTag("working")
    else
      isdoing = self.inst.sg:HasStateTag("doing") or self.inst:HasTag("doing")
      isworking = self.inst.sg:HasStateTag("working") or self.inst:HasTag("working")
    end

    if (isdoing or isworking) then return end 

    if self.passtime ~= nil and self.passtime > 0 then
      self.passtime = self.passtime - 1
      return
    end

    local bufaction = auto_chores:GetAction()

    print("auto_chores", bufaction)
    if bufaction == nil then
      auto_chores.task = nil
    else
      if bufaction.action == ACTIONS.BUILD  then
        if not PLAYER:builder_IsBusy() then
          self.passtime = 20 -- 20 * 0.03초 => 0.6초
          PLAYER:builder_MakeRecipeBy(bufaction.recipe)
        end 
      elseif bufaction.action == ACTIONS.EQUIP then
        PLAYER:inventory_UseItemFromInvTile(bufaction.invobject)
          self.passtime = 10 -- 10 * 0.03초 => 0.3초
          return
        elseif bufaction.action == ACTIONS.DEPLOY then 
        -- TODO 디플로이 기능 구현 하기
        -- local act = BufferedAction(self.builder, nil, ACTIONS.DEPLOY, act.invobject, Vector3(self.inst.Transform:GetWorldPosition()))  
        local act = bufaction
        if not self.ismastersim then 
          local position = TheInput:GetWorldPosition()
          -- local position = bufaction.pos
          local mouseover = TheInput:GetWorldEntityUnderMouse()
          local controlmods = self:EncodeControlMods()
          if self.locomotor == nil then
            self.remote_controls[CONTROL_SECONDARY] = 0
            SendRPCToServer(RPC.RightClick, act.action.code, position.x, position.z, mouseover, nil, controlmods, act.action.canforce, act.action.mod_name)
          elseif act.action ~= ACTIONS.WALKTO and self:CanLocomote() then

            function _cb() 
              self.remote_controls[CONTROL_SECONDARY] = 0
              local isreleased = not TheInput:IsControlPressed(CONTROL_SECONDARY)
              SendRPCToServer(RPC.RightClick, act.action.code, position.x, position.z, mouseover, isreleased, controlmods, nil, act.action.mod_name)
              -- print("PLAYER:inventory_ReturnActiveItem()")
              -- PLAYER:inventory_ReturnActiveItem()              
            end
            act.preview_cb = _cb
          end
        end

        self:DoAction(act)
        return
      end
    end
    return bufaction 
  end

  pc.GetActionButtonAction = _fnOver

end

function AutoChores:GetItem(fn)
  local hands = self.INST:inventory_GetEquippedItem(EQUIPSLOTS.HANDS)
  if fn(hands) then
    return hands
  end 
  local items = self.INST:inventory_FindItems(fn)
  return items[1]
end 

function AutoChores:TestHandAction(fn)
  local hands = self.INST:inventory_GetEquippedItem(EQUIPSLOTS.HANDS) 
  return fn(hands) 
end 

function AutoChores:TryActiveItem(fn)
  local activeItem = self.INST:inventory_GetActiveItem()
  if activeItem ~= nil and  fn(activeItem) then
    return activeItem
  end
  local item = self:GetItem(fn) 
  if item ~=nil then
    self.INST:inventory_TakeActiveItemFromAllOfSlot(fn)
    return item
  end
end


SEE_TREE_DIST = 25



function AutoChores:GetLumberJackAction()
  -- print('GetLumberJackAction')

  local item = nil
  -- item = self:TryActiveItem(_IsTreeSeed) 
  -- if item ~= nil then
  --   return BufferedAction(self.inst, nil, ACTIONS.DEPLOY, item, Vector3(self.inst.Transform:GetWorldPosition()))
  -- end


  item = self:GetItem(_isChopper)
  if item == nil then
    local target = FindEntity(self.inst, SEE_TREE_DIST, _isChopper)
    if target then
      return BufferedAction(self.inst, target, ACTIONS.PICKUP )
    end 
    
    local recipe = "axe"
    if self.INST:builder_KnowsRecipe(recipe) and self.INST:builder_CanBuild(recipe) then
      return BufferedAction(self.inst, nil, ACTIONS.BUILD, nil, nil, recipe, 1)
    end
    return nil
  end
  local chopper = item 



  item = self:GetItem(_isDigger)

  -- print("finded digger = ", item)

  if item == nil then 
    local target = FindEntity(self.inst, SEE_TREE_DIST, _isDigger)
    if target then
      return BufferedAction(self.inst, target, ACTIONS.PICKUP )
    end 

    local recipe = "shovel"
    if self.INST:builder_KnowsRecipe(recipe) and self.INST:builder_CanBuild(recipe) then
      return BufferedAction(self.inst, nil, ACTIONS.BUILD, nil, nil, recipe, 1)
    end
  end

  local digger = item 
  local target = FindEntity(self.inst, SEE_TREE_DIST, _IsTreeLoot)
  if target then
    return BufferedAction(self.inst, target, ACTIONS.PICKUP )
  end 


  if digger then
    local target = FindEntity(self.inst, SEE_TREE_DIST, _IsStump)
    if target then
      if self:TestHandAction(_isDigger) == false then
        -- print("do Equip digger", digger)
        return BufferedAction(self.inst, nil, ACTIONS.EQUIP, digger)
      end
      return BufferedAction(self.inst, target, ACTIONS.DIG, digger )
    end 
  end 
  local target = FindEntity(self.inst, SEE_TREE_DIST, _IsTree)
  if target then
    if self:TestHandAction(_isChopper) == false then
      -- print("do Equip chopper", chopper)
      return BufferedAction(self.inst, nil, ACTIONS.EQUIP, chopper)
    end
    return BufferedAction(self.inst, target, ACTIONS.CHOP, chopper )
  end 

  -- -- print("target = ",  target)
  -- if target then
  --   local bufaction = BufferedAction(inst, target, ACTIONS.CHOP) 

end 




function AutoChores:ToBeMiner( )
  -- body
end

function AutoChores:GetPlanterAction()

  local item = nil
  item = self:TryActiveItem(_IsTreeSeed) 
  if item ~= nil then
    local pos = Vector3(self.inst.Transform:GetWorldPosition())
    pos.x = pos.x + 2
    return BufferedAction(self.inst, nil, ACTIONS.DEPLOY, item, pos)
  end


end



return AutoChores