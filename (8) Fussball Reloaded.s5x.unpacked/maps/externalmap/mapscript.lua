

--Script.Load("data/maps/externalmap/FussballReloaded.lua")
Script.LoadFolder("data/maps/externalmap/tools")
Script.Load("data/maps/externalmap/fussballreloaded.lua")
--Script.Load(Folders.Map.."fussballreloaded.lua")
if VERSION == nil then
	LUALOADFAILED = true
    EXTERNALGUINOTLOADED = true
	Script.Load("maps\\user\\EMS\\tools\\S5Hook.lua")
	Script.Load("maps\\user\\speedwar\\tools\\SVFuncs.lua")
    Script.Load("maps\\user\\Siedlerfussball\\(8) Fussball Reloaded.s5x.unpacked\\maps\\externalmap\\FussballReloaded.lua")
end


 