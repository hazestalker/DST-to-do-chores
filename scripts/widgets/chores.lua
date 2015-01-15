local Widget = require "widgets/widget"
local BadgeWheel = require("chores-lib.badgewheel") 
local CountDown = require("chores-lib.countdown") 
local Inst = require "chores-lib.instance" 

CW = nil
local ChoresWheel = Class(Widget, function(self)
  Widget._ctor(self, "ChoresWheel") 


  self.root = self:AddChild(BadgeWheel())
  CW = self.root
  self.root:CreateBadges(4) 


  --[[
  To do chores list
  - 벌목꾼
  - 심기
  - 광부
  - 기초 생존품 챙기기
  - 농부

  ]]

  self.placerGap = 3
  self.placers = nil

  self:BtnLumberJack()
  self:BtnMiner()


  self:BtnPlanter()
  -- self:BtnDeploy()
  print('CHO.TEST', CountDown.TEST)
  end)


function ChoresWheel:BtnLumberJack()
  local img = nil
  local btn = self.root:GetBadge(1)  
  img = btn:InvIcon("axe") 
  btn:SetOnClick( function ()
    ThePlayer.components.auto_chores:SetTask("LumberJack")
    end)
end


function ChoresWheel:BtnMiner()
  local img = nil
  local btn = self.root:GetBadge(2)  
  img = btn:InvIcon("pickaxe") 
  btn:SetOnClick( function ()
    -- ThePlayer.components.auto_chores:ToBeMiner()
    end)
end



local function _IsTreeSeed(item)
  print('prefab', item, item.prefab)
  if item.prefab == "pinecone" then return true end 
  -- if item.prefab == "acorn" then return true end -- this is Birchnut
  return false
end


function ChoresWheel:BtnPlanter( )
  local img = nil
  local btn = self.root:GetBadge(3)  
  img = btn:InvIcon("pinecone") 
  btn:SetOnClick( function ()

    local info = { }

    for k, deployplacer in pairs(self.placers) do

      if deployplacer.components.placer.testfn(deployplacer:GetPosition()) then
        local data = {
          position = deployplacer:GetPosition()
        }
        print('deployplacer at', data.position.x, data.position.z)
        table.insert(info, data)
        -- deployplacer:Remove()
      end
    end  
    ThePlayer.components.auto_chores:SetTask("Planter", info)

    end)

  btn:SetOnFocus(function(gainFocus)

    if gainFocus then

      if self.placers ~= nil then return end 
      self.placers = {}
      -- local items = Inst(ThePlayer):inventory_GetAllItems()
      -- for k,v in pairs(items) do
      --   print(k,v)
      -- end 

      local items = Inst(ThePlayer):inventory_FindItems(_IsTreeSeed)
      -- print("items", items)
      local placer_item = items[1]
      -- print("placer_item", placer_item, items)
      if placer_item == nil then 
        -- 심을것 없음 에러 
        return
      end
      local placer_name = placer_item.replica.inventoryitem:GetDeployPlacerName()

      -- print("placer_name", placer_name)

      -- local placer_name = "pinecone_placer"
      -- self.deployplacer.components.placer:OnUpdate(0) --so that our position is accurate on the first frame


      for xOff = 0, 4, 1 do
        for zOff = 0, 3, 1 do

          local deployplacer = SpawnPrefab(placer_name)


          deployplacer.components.placer:SetBuilder(ThePlayer, nil, placer_item)

          local function _testfn(pt) 
            return placer_item:IsValid() and
            placer_item.replica.inventoryitem ~= nil and
            placer_item.replica.inventoryitem:CanDeploy(pt)
          end

          deployplacer.components.placer.testfn = _testfn

          -- deployplacer:RemoveComponent("placer")
          -- deployplacer:AddComponent("placer_orig")
          -- deployplacer.components.placer = deployplacer.components.placer_orig

          local function _replace(self, dt)

            self.can_build = self.testfn == nil or self.testfn(self.inst:GetPosition())
            local color = self.can_build and Vector3(.25,.75,.25) or Vector3(.75,.25,.25)
            self.inst.AnimState:SetAddColour(color.x, color.y, color.z ,0)

          end
          deployplacer.components.placer.OnUpdate = _replace


          local pos = Vector3(ThePlayer.Transform:GetWorldPosition())
          deployplacer.offset = Vector3( (xOff -2) * self.placerGap  , 0, (zOff-2) * self.placerGap)
          deployplacer.Transform:SetPosition((pos + deployplacer.offset ):Get())

          deployplacer.components.placer:OnUpdate(0)
          table.insert( self.placers, deployplacer)

        end
      end

    else 
      for k, v in pairs(self.placers) do
        v:Remove()
      end
      self.placers = nil

      return
    end
    end)
end

function ChoresWheel:UpdateLocation(dt) 
  -- print("onUpdate", dt)

  for k, deployplacer in pairs(self.placers) do
    local pos = Vector3(ThePlayer.Transform:GetWorldPosition())
    -- deployplacer.offset = Vector3( (xOff -2) * self.placerGap  , 0, (zOff-2) * self.placerGap)
    deployplacer.Transform:SetPosition((pos + deployplacer.offset ):Get())
    deployplacer.components.placer:OnUpdate(dt)
  end
end



-- local Widget = Class(Widget, function(self, controls)
-- 	Widget._ctor(self, "MachineWidget") 

--     -- self:SetScaleMode(SCALEMODE_PROPORTIONAL)
--     self:SetHAnchor(ANCHOR_MIDDLE)
--     self:SetVAnchor(ANCHOR_MIDDLE)
--     -- self:SetMaxPropUpscale(MAX_HUD_SCALE)    



--  --    local screenwidth, screenheight = TheSim:GetScreenSize()
--  --    self.root:SetPosition( screenwidth / 2 - 100 ,0,0)
-- 	-- local screenwidth, screenheight = TheSim:GetScreenSize()
-- 	-- self.root:SetPosition(screenwidth/2,screenheight/2,0)

--     self.root = self:AddChild(Widget("root"))



--     self.badge = {}
--     self.chores = {"LUMBERJACK" }

--     local count = 0
--     for k,v in pairs(chores) do count = count + 1 end
--     local dist = (65*count)/(math.pi)
--     local delta = 2*math.pi/count
--     local theta = 0

--     for k,v in pairs(chores) do
--         self.badge[k] = self.root:AddChild(ChoreBadge(v))
--         -- print(k)
--         -- print("Positioning:", dist*math.cos(theta),0,dist*math.sin(theta))
--         self.gestures[k]:SetPosition(dist*math.cos(theta),dist*math.sin(theta), 0)
--         theta = theta + delta
--     end




    -- self.bg = self.root:AddChild(Image("images/hud.xml", "map.tex"))
    -- self:SetPosition(0,0,0)
    -- self.icon:SetScale(1) 

    -- local shield = self.root:AddChild( Image("images/fepanels_dst.xml", "tall_panel.tex"))
    -- shield:SetPosition(100, 0,0)
    -- shield:SetSize(screenwidth*.7,screenheight*.3)


    -- shield:SetScaleMode(SCALEMODE_FILLSCREEN)
    -- shield:SetScale(.7, .7, .7)

    -- self.root:AddChild(Image("images/ui.xml", "blank.tex"))


    -- self.togglebutton = self.root:AddChild(ImageButton())
    -- self.togglebutton:SetScale(.7, 1,.7) 
    -- self.togglebutton:SetText("To Be LumberJack")
    -- self.togglebutton:SetPosition(150, -0,0)
    -- self.togglebutton:SetOnClick( function() ThePlayer.components.auto_chores:ToBeLumberJack()   end)

    --  gap = gap  + 1 
       --  self.togglebutton:SetPosition(0  ,0+ gap,0) 
       --  print(self.togglebutton:GetPosition()    )
    --  end )


    -- self.togglebutton:SetOnClick( function()  print("clicked")

    -- 	gap = gap  + 1 
	   --  self.togglebutton:SetPosition(0  ,0+ gap,0) 
	   --  print(self.togglebutton:GetPosition()	)
    --  end )

    -- self.togglebutton2 = self.root:AddChild(ImageButton())
    -- self.togglebutton2:SetScale(.7,.7,.7) 
    -- self.togglebutton2:SetText("2")
    -- self.togglebutton2:SetPosition(1,1,0)
    
    -- local gap = 0 
    -- local function _loop() 
    -- end	

    -- _fn = _loop
    -- self:DoTaskInTime(1, function(inst) _fn() end )




    -- end)


return ChoresWheel