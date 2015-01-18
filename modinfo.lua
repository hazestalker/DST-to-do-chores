name = "To Do Chores"
description = "To do chores, it is painful works but imperatively necessary for surviving."
author = "js.seth.h"
version = "0.1-alpha"

forumthread = ""

-- This lets other players know if your mod is out of date, update it to match the current version in the game
api_version = 10

-- Can specify a custom icon for this mod!
-- icon_atlas = "ExtendedIndicators.xml"
-- icon = "ExtendedIndicators.tex"

-- Specify compatibility with the game!
dont_starve_compatible = true
reign_of_giants_compatible = true
dst_compatible = true

all_clients_require_mod = false
clients_only_mod = false

server_filter_tags = {"chores"}


icon_atlas = "modicon.xml"
icon = "to-do-chores.tex"

local alpha = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"}
local KEY_A = 97
local keyslist = {} 
local Default_Key =  "V" 
for i = 1,#alpha do 
  keyslist[i] = {description = alpha[i],data = i + KEY_A - 1}
  if alpha[i] == Default_Key then
    Default_Key = keyslist[i].data
  end
end


configuration_options =
{
  {
    name = "togglekey",
    label = "Open Chores Wheel",
    options = keyslist,
    default = Default_Key

  } 
}

