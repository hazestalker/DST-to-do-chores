local Widget = require "widgets/widget"
local BadgeWheel = require("chores-lib.badgewheel") 
local CountDown = require("chores-lib.countdown") 

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


  self:BtnLumberJack()
  self:BtnMiner()
  -- self:BtnDeploy()
  print('CHO.TEST', CountDown.TEST)
  end)


function ChoresWheel:BtnLumberJack()
  local img = nil
  local btn = self.root:GetBadge(1)  
  img = btn:InvIcon("axe") 
  btn:SetOnClick( function ()
    ThePlayer.components.auto_chores:ToBeLumberJack()
    end)
end


function ChoresWheel:BtnMiner()
  local img = nil
  local btn = self.root:GetBadge(2)  
  img = btn:InvIcon("pickaxe") 
  btn:SetOnClick( function ()
    ThePlayer.components.auto_chores:ToBeMiner()
    end)
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

function ChoresWheel:OnUpdate(dt) 
  -- print("onUpdate", dt)
end


return ChoresWheel