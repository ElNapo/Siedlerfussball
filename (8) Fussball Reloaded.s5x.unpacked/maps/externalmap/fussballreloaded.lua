
VERSION = "0.3.0"
TIME = "4. Juli 2021"

function GameCallback_OnGameStart()
 
	-- Include global tool script functions
	Script.Load(Folders.MapTools.."Ai\\Support.lua")
	Script.Load( "Data\\Script\\MapTools\\MultiPlayer\\MultiplayerTools.lua" )
	Script.Load( "Data\\Script\\MapTools\\Tools.lua" )
	Script.Load( "Data\\Script\\MapTools\\WeatherSets.lua" )
	

	InstallS5Hook()
	if S5Hook == nil then
		LuaDebugger.Log("Loading S5Hook failed!")
	end
	SW.SV.Init()
	
	
	IncludeGlobals("Comfort")
	-- Init  global MP stuff
	MultiplayerTools.SetMPGameMode = function() end
	MultiplayerTools.SetUpGameLogicOnMPGameConfig()
	
    if XNetwork.Manager_DoesExist() == 0 then
	-- Standardschleife f�r Multiplayersetup 8 Player
        for i=1,8 do
			MultiplayerTools.DeleteFastGameStuff(i)
		end
		local PlayerID = GUI.GetPlayerID()
        Logic.PlayerSetIsHumanFlag( PlayerID, 1 )
        Logic.PlayerSetGameStateToPlaying( PlayerID )
	end
	for i = 1,8 do
		Logic.SetEntityExplorationRange ( GetEntityId("Explore"..i), 10000 )
	end
	-- Alle Spieler auf Friendly stellen
	for i = 1,8 do
		for u = 1,8 do
			if not (i == u) then
				Logic.SetDiplomacyState( i, u, Diplomacy.Friendly )
			end 
		end
	end
	
	-- default coloring:
	--	blue for allies, red for enemies
	--	fallback for allies: lime
	--	fallback for hostile: 12, kerberos
	local localPlayer = GUI.GetPlayerID()
	local localTeam = GetTeamByPlayerId( localPlayer)
	local localColor = XNetwork.GameInformation_GetLogicPlayerColor(localPlayer)
	local enemyColor, allyColor = 2, 1
	if localColor == 1 then
		allyColor = 8
	elseif localColor == 2 then
		enemyColor = 12
	end
	for i = 1, 8 do
		if i ~= localPlayer then 
			if GetTeamByPlayerId(i) ~= localTeam then
				Display.SetPlayerColorMapping(i, enemyColor)
			else
				Display.SetPlayerColorMapping(i, allyColor)
			end
		end
	end
	LocalMusic.UseSet = HIGHLANDMUSIC
	SetupHighlandWeatherGfxSet()
	AddPeriodicSummer(10)
	
	-- Recreate corners
	local corners = {Logic.GetEntitiesInArea( Entities.XD_WallCorner, 0, 0, 50000, 4)}
	local pos
	Score.Player[0] = {
		battle = 0,
		buildings = 0,
		settlers = 0,
		all = 0,
		resources = 0,
		technology = 0
	}
	for i = 2, corners[1] do
		pos = GetPosition( corners[i])
		DestroyEntity ( corners[i] )
		Logic.CreateEntity( Entities.XD_WallCorner, pos.X, pos.Y, 0, 0)	
	end
	
	Settings = {
		Paranoia = false,
		HeroesPerTeam = 6,
		Time = 10,
		Boards = false
	}
	Camera.ZoomSetFactorMax(2)

	if not CNetwork then
		CNetwork = {}
		CNetwork.SetNetworkHandler = function() end
		CNetwork.SendCommand = function( _s, _arg) _G[_s](0, _arg) end
		CNetwork.IsAllowedToManipulatePlayer = function() return true end
	end
	LoadSetPosition()
	
	if LUALOADFAILED then
		S5Hook.LoadGUI("maps\\user\\siedlerfussball\\soccergui.xml")
	else
		S5Hook.LoadGUI("data/maps/externalmap/soccergui.xml")
	end
	StartSimpleJob("StartGUI")
	
end


SoccerGUI = {}
function StartGUI()

	--LuaDebugger.Break()
	XGUIEng.ShowWidget("SW", 1)
	XGUIEng.ShowWidget("SWStartMenu", 1)
	
	XGUIEng.ShowWidget("SoccerRule3Plus", 0)
	XGUIEng.ShowWidget("SoccerRule3Minus", 0)
	XGUIEng.ShowWidget("SoccerRule4Plus", 0)
	XGUIEng.ShowWidget("SoccerRule4Minus", 0)
	
	XGUIEng.ShowWidget("SWShowButtonContainer", 1)
	XGUIEng.ShowWidget("SWShowButton", 1)
	
	-- set default rules
	XGUIEng.SetText("SoccerRule1Button", "@center "..Settings.Time)
	XGUIEng.SetText("SoccerRule2Button", "@center "..Settings.HeroesPerTeam)
	if Settings.Paranoia then
		XGUIEng.SetText("SoccerRule3Button", "@center Ja")
	else
		XGUIEng.SetText("SoccerRule3Button", "@center Nein")
	end
	XGUIEng.SetText("SoccerRule4Button", "@center Nein")
	
	CNetwork.SetNetworkHandler("GUI_OnButton", GUI_OnButton)
	CNetwork.SetNetworkHandler("GUI_OnPlus", GUI_OnPlus)
	CNetwork.SetNetworkHandler("GUI_OnMinus", GUI_OnMinus)
	CNetwork.SetNetworkHandler("GUI_OnStart", GUI_OnStart)
	SoccerGUI.PrepVersionStuff()
	--LuaDebugger.Break()
	return true
end
function SoccerGUI.StartGame() -- the actual start button
	if GUI.GetPlayerID() ~= 1 then
		SoccerGUI.DenySound()
		return
	end
	CNetwork.SendCommand("GUI_OnStart")
end
function GUI_OnStart( _sender)
	if not CNetwork.IsAllowedToManipulatePlayer( _sender, 1) then
		return
	end
	if SoccerGUI.Started then
		return
	end
	SoccerGUI.Started = true
	StartSimpleJob("GUI_CountdownJob")
	XGUIEng.ShowAllSubWidgets("SW", 0)
	XGUIEng.ShowWidget("SWCounter", 1)
	SoccerGUI.Countdown = 6
end
function SoccerGUI.Open() -- called by the opengui button on top
	XGUIEng.ShowWidget("SWStartMenu", 1-XGUIEng.IsWidgetShown("SWStartMenu"))
end

function SoccerGUI.OnButton( _id)
	if GUI.GetPlayerID() ~= 1 then
		SoccerGUI.DenySound()
		return
	end
	CNetwork.SendCommand("GUI_OnButton", _id)
end
function GUI_OnButton( _sender, _id)
	if not CNetwork.IsAllowedToManipulatePlayer( _sender, 1) then
		return
	end
	if _id == 3 then
		Settings.Paranoia = not Settings.Paranoia
		if Settings.Paranoia then
			XGUIEng.SetText("SoccerRule3Button", "@center Ja")
		else
			XGUIEng.SetText("SoccerRule3Button", "@center Nein")
		end
	elseif _id == 4 then
		Settings.Boards = not Settings.Boards 
		if Settings.Boards then
			XGUIEng.SetText("SoccerRule4Button", "@center Ja")
		else
			XGUIEng.SetText("SoccerRule4Button", "@center Nein")
		end
	end
end
function SoccerGUI.OnPlus( _id)
	if GUI.GetPlayerID() ~= 1 then
		SoccerGUI.DenySound()
		return
	end
	CNetwork.SendCommand("GUI_OnPlus", _id)
end
function GUI_OnPlus( _sender, _id)
	if not CNetwork.IsAllowedToManipulatePlayer( _sender, 1) then
		return
	end
	if _id == 1 then
		Settings.Time = Settings.Time + 1
		XGUIEng.SetText("SoccerRule1Button", "@center "..Settings.Time)
	elseif _id == 2 then
		Settings.HeroesPerTeam = Settings.HeroesPerTeam + 1
		XGUIEng.SetText("SoccerRule2Button", "@center "..Settings.HeroesPerTeam)
	end
end
function SoccerGUI.OnMinus( _id)
	if GUI.GetPlayerID() ~= 1 then
		SoccerGUI.DenySound()
		return
	end
	CNetwork.SendCommand("GUI_OnMinus", _id)
end
function GUI_OnMinus( _sender, _id)
	if not CNetwork.IsAllowedToManipulatePlayer( _sender, 1) then
		return
	end
	if _id == 1 then
		Settings.Time = math.max(Settings.Time - 1, 5)
		XGUIEng.SetText("SoccerRule1Button", "@center "..Settings.Time)
	elseif _id == 2 then
		Settings.HeroesPerTeam = math.max(Settings.HeroesPerTeam - 1, 1)
		XGUIEng.SetText("SoccerRule2Button", "@center "..Settings.HeroesPerTeam)
	end
end
SoccerGUI.Tooltips = {
	[1] = "Stellt die Spieldauer in Minuten ein.",
	[2] = "Stellt die Anzahl der Helden pro Team ein.",
	[3] = "Aktiviert oder deaktiviert den Paranoiamodus.",
	[4] = "Falls aktiv, wird der Ball an der Spielfeldbegrenzung abprallen es gibt keine Einwürfe, Ecken oder Abstöße!",
	["Start"] = "Startet das Spiel."
}
function SoccerGUI.HandleTooltip( _id)
	-- tooltip widget: SWSMTooltip, SWSMTText
	local txt = SoccerGUI.Tooltips[_id] or "Tooltip for "..tostring(_id).." undefined"
	XGUIEng.SetText( "SWSMTText", txt)
end
function SoccerGUI.DenySound()
	local sounds = {
		"AOVoicesHero10_HERO10_NO_rnd_01",
		"AOVoicesHero11_HERO11_NO_rnd_01",
		"AOVoicesHero12_HERO12_NO_rnd_01",
		"AOVoicesScout_Scout_NO_rnd_01",
		"AOVoicesThief_Thief_NO_rnd_01",
		"VoicesHero1_HERO1_NO_rnd_01",
		"VoicesHero2_HERO2_NO_rnd_01",
		"VoicesHero3_HERO3_NO_rnd_01",
		"VoicesHero4_HERO4_NO_rnd_01",
		"VoicesHero5_HERO5_NO_rnd_01",
		"VoicesHero6_HERO6_NO_rnd_01",
		"VoicesHero7_HERO7_NO_rnd_01",
		"VoicesHero8_HERO8_NO_rnd_01",
		"VoicesHero9_HERO9_NO_rnd_01",
		"VoicesLeader_LEADER_NO_rnd_01",
		"VoicesLeader_LEADER_Yes_rnd_20",
		"VoicesSerf_SERF_FunnyComment_rnd_04",
		"VoicesSerf_SERF_No_rnd_01",
		"VoicesWorker_WORKER_FunnyNo_rnd_01"
	}
	local nSounds = table.getn(sounds)
	Sound.PlayGUISound( Sounds[sounds[math.random(nSounds)]], 100)
end

function GUI_CountdownJob()
	SoccerGUI.Countdown = SoccerGUI.Countdown - 1
	XGUIEng.SetText( "SWCounter", "@center "..SoccerGUI.Countdown)
	if SoccerGUI.Countdown < 1 then
		PlayRefSound()
		XGUIEng.ShowWidget("SWCounter", 0)
		StartGame()
		return true
	end
end

function SoccerGUI.PrepVersionStuff()
	XGUIEng.ShowWidget("VCMP_Window", 1)
	XGUIEng.SetWidgetPosition("VCMP_Window", 0, 42)
	XGUIEng.ShowAllSubWidgets("VCMP_Window", 0)
	XGUIEng.ShowWidget("VCMP_Team1", 1)
	XGUIEng.ShowAllSubWidgets("VCMP_Team1", 0)
	
	XGUIEng.ShowWidget("VCMP_Team1PointGame", 1)
	XGUIEng.ShowWidget("VCMP_Team1PointBG", 0)
	XGUIEng.SetWidgetSize("VCMP_Team1Points", 128, 16)
	XGUIEng.SetWidgetPosition("VCMP_Team1Points", 0, 0)
	
	if LUALOADFAILED then
		XGUIEng.SetText("VCMP_Team1Points", "Version "..VERSION.." @cr "..TIME.." @cr @color:255,0,0 MAP NOT COMPLETE")
	else	
		XGUIEng.SetText("VCMP_Team1Points", "Version "..VERSION.." @cr "..TIME)
	end
end


-- Anarkis numbers: 130, 210
BALLTYPE = Entities.XD_RockTideland3
BALLMODEL = Models.XD_RockTideland3
SoccerConfig = {
	KickDistance = 350,
	StopDistance = 250,
	ShortKickVelo = 1200,
	LongKickVelo = 2400,
	AirResistanceCoeff = 10^(-4)/4,
	RollingResistanceCoeff = 25,
	Knockback = 1500,
	NearBallRadius = 300,
	CocktailDuration = 50,
	CocktailMS = 800,
	CocktailCost = 240,
	DefaultMS = 500
}

function StartGame()
	Framework.CloseGame_Orig = Framework.CloseGame;
	Framework.CloseGame = function()
		SW.ResetScriptingValueChanges();
		Framework.CloseGame_Orig();
	end
	if Settings.Paranoia then
		for i = 1, 8 do
			DestroyEntity("Explore"..i)
			Logic.SetShareExplorationWithPlayerFlag( GUI.GetPlayerID(), i, 0)
		end
		Logic.SetShareExplorationWithPlayerFlag( GUI.GetPlayerID(), GUI.GetPlayerID(), 1)
		local heroTable = {
			Entities.PU_Hero2,
			Entities.PU_Hero3,
			Entities.PU_Hero4,
			Entities.PU_Hero5,
			Entities.PU_Hero6,
			Entities.PU_Hero1c
		}
		for j = 1, table.getn(heroTable) do
			SW.SetSettlerExploration( heroTable[j], 10)
		end
	end
	if Settings.Boards then
		CreateBoards()
	end
	Trigger.RequestTrigger( Events.LOGIC_EVENT_ENTITY_CREATED, nil, "OnEntityCreated", 1)
	SpawnHeroes()
	InstallGUIHooks()
	CNetwork.SetNetworkHandler( "ShortKick", ShortKick)
	CNetwork.SetNetworkHandler( "LongKick", LongKick)
	CNetwork.SetNetworkHandler( "ActivateCocktail", ActivateCocktail)
	local bPos = GetPosition("Fussball")
	SoccerData = {
		BallPos = {bPos.X, bPos.Y},				-- where is the ball?
		BallId = GetEntityId("Fussball"),		-- what is the ball?
		BallRot = 0,							-- Rotation of ball, just visual stuff
		BallVelo = {0, 0},						-- how fast is it moving?
		KickDistanceSq = SoccerConfig.KickDistance^2,		-- range for kicks
		JobId = StartSimpleHiResJob("BallJob"),	-- job that handles ball movement
		GameRunning = true,						-- is the game currently running?
		LastTeam = 1,							-- how used the ball last?
		LastHero = 0,							-- which hero?
		LastHeroType = 0,
		LastPlayer = 0,
		GoalsSouth = 0,
		GoalsNorth = 0,
		TimeOfConflict = 0						-- how many of the past seconds there were 2 heroes near ball?
	}
	StartCountdown( 60 * Settings.Time, OnGameOver, true)
	CocktailData = {}
	StartSimpleJob("EnforceRules")
	StartSimpleHiResJob("CocktailJob")
	InitMovieLog()
	CreateSpectators()
	return true
end
function InstallGUIHooks()
	GameCallback_GUI_SelectionChanged_Orig = GameCallback_GUI_SelectionChanged
	
	GameCallback_GUI_SelectionChanged = function()
		GameCallback_GUI_SelectionChanged_Orig()
		for i = 2, 6 do
			XGUIEng.ShowWidget("Selection_Hero"..i, 0)
		end
		XGUIEng.ShowWidget("Selection_Hero1", 1)

	end
	GUIAction_Hero1SendHawk = function()
		if GetDistanceSq( GetPos(GUI.GetSelectedEntity()), SoccerData.BallPos) <= SoccerData.KickDistanceSq then
			CNetwork.SendCommand( "ShortKick", GUI.GetSelectedEntity())
		end
	end
	GUIAction_Hero1ProtectUnits = function()
		if GetDistanceSq( GetPos(GUI.GetSelectedEntity()), SoccerData.BallPos) <= SoccerData.KickDistanceSq then
			CNetwork.SendCommand( "LongKick", GUI.GetSelectedEntity())
		end
	end
	GUIAction_Hero1LookAtHawk = function()
		if CocktailData[GUI.GetSelectedEntity()] ~= nil then
			if CocktailData[GUI.GetSelectedEntity()] < 1 then
				CNetwork.SendCommand( "ActivateCocktail", GUI.GetSelectedEntity())
				return
			end
			Message("Euer Held ist noch nicht soweit!")
			return
		end
		CNetwork.SendCommand( "ActivateCocktail", GUI.GetSelectedEntity())
	end
	GUITooltip_NormalButton_Orig = GUITooltip_NormalButton
	GUITooltip_NormalButton = function( _ttString, _shortcut)
		GUITooltip_NormalButton_Orig( _ttString, _shortcut)
		if _ttString == "MenuHero1/command_sendhawk" then
			XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomText, "@color:180,180,180,255 Kurzer Schuss @cr @color:255,255,255 Führt einen kurzen Schuss aus, der ideal ist, um zu nahen Mitspielern zu passen.")
		elseif _ttString == "MenuHero1/command_protectunits" then
			XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomText, "@color:180,180,180,255 Langer Schuss @cr @color:255,255,255 Führt einen kräftigen Schuss aus, der ideal ist, um den Ball nach vorne zu bringen.")
		elseif _ttString == "MenuHero1/command_lookathawk" then
			XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomText, "@color:180,180,180,255 Wilder Mix @cr @color:255,255,255 Euer Held konsumiert einen Chemie-Cocktail, um kurzfristig die Leistungsfähigkeit massiv zu steigern.")
			XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomCosts, SoccerConfig.CocktailCost.." HP")
		end
	end
	XGUIEng.TransferMaterials( "Hero8_Poison", "Hero1_LookAtHawk") -- steroids
	XGUIEng.TransferMaterials( "Hero10_SniperAttack", "Hero1_ProtectUnits") -- long kick
	XGUIEng.TransferMaterials( "Formation03", "Hero1_SendHawk") -- short kick
	
	XGUIEng.SetWidgetPosition( "Hero1_RechargeSendHawk", 76, 40)
	GUIUpdate_HeroAbility_Orig = GUIUpdate_HeroAbility
	GUIUpdate_HeroAbility = function( _ability, _widgetId)
		if Abilities.AbilitySendHawk ~= _ability then
			GUIUpdate_HeroAbility_Orig( _ability, _widgetId)
			return
		end
		local timeTotal = SoccerConfig.CocktailDuration
		local timeRemaining = CocktailData[GUI.GetSelectedEntity()] or 0
		local currWidget = XGUIEng.GetCurrentWidgetID()
		if timeRemaining == 0 then
			XGUIEng.SetMaterialColor( currWidget, 1, 214, 44, 24, 189)
			XGUIEng.DisableButton( "Hero1_LookAtHawk", 0)
		else
			XGUIEng.SetMaterialColor( currWidget, 1, 214, 44, 24, 189)	
			XGUIEng.DisableButton( "Hero1_LookAtHawk", 1)
		end
		XGUIEng.SetProgressBarValues( currWidget, timeRemaining, timeTotal)
	end
end

function SpawnHeroes()
	activePlayers = {}
	for i = 1, 8 do
		activePlayers[i] = (XNetwork.GameInformation_IsHumanPlayerAttachedToPlayerID(i) == 1)
	end
	local isTeam2Set = false
	for j = 5, 8 do
		if activePlayers[j] then
			isTeam2Set = true
		end
	end
	if not isTeam2Set then
		activePlayers[5] = true
	end
	local posCounterA, posCounterB = 1, 1
	local pos
	local heroCounter = 1
	local heroTable = {
		Entities.PU_Hero2,
		Entities.PU_Hero3,
		Entities.PU_Hero4,
		Entities.PU_Hero5,
		Entities.PU_Hero6,
		Entities.PU_Hero1c
	}
	local numHeroes = 0
	while numHeroes < Settings.HeroesPerTeam do
		for j = 1, 4 do
			if activePlayers[j] then
				if numHeroes < Settings.HeroesPerTeam then
					pos = GetPosition("T2_"..posCounterA)
					Logic.CreateEntity( heroTable[heroCounter], pos.X, pos.Y, 0, j)
					posCounterA = posCounterA + 1
					if posCounterA > 11 then
						posCounterA = 1
					end
					numHeroes = numHeroes + 1
				end
			end
		end
		heroCounter = math.mod(heroCounter,6)+1
	end
	
	heroCounter = 1
	numHeroes = 0
	while numHeroes < Settings.HeroesPerTeam do
		for j = 5, 8 do
			if activePlayers[j] then
				if numHeroes < Settings.HeroesPerTeam then
					pos = GetPosition("T1_"..posCounterB)
					Logic.CreateEntity( heroTable[heroCounter], pos.X, pos.Y, 0, j)
					posCounterB = posCounterB + 1
					if posCounterB > 11 then
						posCounterB = 1
					end
					numHeroes = numHeroes + 1
				end
			end
		end
		heroCounter = math.mod(heroCounter,6)+1
	end
end
function OnEntityCreated()
	local eId = Event.GetEntityID()
	if Logic.IsHero( eId) == 1 then
		SetMovementspeed( eId, SoccerConfig.DefaultMS)
	end
end

function BallJob()
	-- do nothing if game is not running
	if not SoccerData.GameRunning then
		return
	end
	
	-- move ball
	local velo = SoccerData.BallVelo
	local veloSq = velo[1]^2 + velo[2]^2
	local veloAbs = math.sqrt(veloSq)
	if veloSq ~= 0 then
		local ballPos = SoccerData.BallPos
		local colHero, colTime = CheckForHeroCollisions()
		SoccerData.BallPos = { ballPos[1] + velo[1]*colTime, ballPos[2] + velo[2]*colTime}
		DestroyEntity( SoccerData.BallId)
		SoccerData.BallRot = SoccerData.BallRot + 0.001*veloAbs
		SoccerData.BallId = Logic.CreateEntity( BALLTYPE, SoccerData.BallPos[1], SoccerData.BallPos[2], 0, SoccerData.BallRot)
		Logic.SetModelAndAnimSet( SoccerData.BallId, BALLMODEL)
		if colHero ~= 0 then 
			SoccerData.BallVelo = {0,0}
			veloAbs = 0
		end
	
		-- create neat effects
		if veloAbs > 2000 then
			Logic.CreateEffect( GGL_Effects.FXBuildingSmokeLarge, SoccerData.BallPos[1], SoccerData.BallPos[2], 0)
		elseif veloAbs > 1250 then
			Logic.CreateEffect( GGL_Effects.FXBuildingSmokeMedium, SoccerData.BallPos[1], SoccerData.BallPos[2], 0)
		elseif veloAbs > 500 then
			Logic.CreateEffect( GGL_Effects.FXBuildingSmoke, SoccerData.BallPos[1], SoccerData.BallPos[2], 0)
		else
			--Logic.CreateEffect( GGL_Effects.FXBuildingSmoke, SoccerData.BallPos[1], SoccerData.BallPos[2], 0)
		end
	end

	-- apply resistences
	local res = SoccerConfig.AirResistanceCoeff * veloSq + SoccerConfig.RollingResistanceCoeff
	local newVelo = math.max( 0, veloAbs - res)
	-- update velocity vector
	if veloAbs ~= 0 then
		local veloChange = newVelo / veloAbs
		SoccerData.BallVelo = { velo[1]*veloChange, velo[2]*veloChange}
	end
	
	-- check for special events like goals / outside of field
	-- Field:
	-- Y \in [6100, 13300]
	-- X \in [3400, 16700]
	-- Goals:
	-- Y \in [8800, 10500]
	-- THROW-INs
	if SoccerData.BallPos[2] > 13300 or SoccerData.BallPos[2] < 6100 then
		--default behavior, calculate throw-in stuff
		if not Settings.Boards then
			if SoccerData.LastTeam == 1 then
				Message("Einwurf für das Nordteam!")
			else
				Message("Einwurf für das Südteam!")
			end
			SetBallPos( {SoccerData.BallPos[1], ClipValue( SoccerData.BallPos[2], 6100, 13300)})
			local myHero = GetNearestHeroFromTeam( 3 - SoccerData.LastTeam, SoccerData.BallPos)
			-- apply knock back to all heroes nearby
			PushHeroesBack( SoccerData.BallPos, myHero)
			PlayRefSound()
			-- where exactly is the throw-in?
			if SoccerData.BallPos[2] == 13300 then
				SetPosition( myHero, {SoccerData.BallPos[1], 13400}, true)
			else
				SetPosition( myHero, {SoccerData.BallPos[1], 6000}, true)
			end
			return
		else -- just bounce :D
			--LuaDebugger.Log(SoccerData.BallPos)
			--LuaDebugger.Log(SoccerData.BallVelo)
			
			if SoccerData.BallPos[2] > 13300 then
				SoccerData.BallPos[2] = 2*13300 - SoccerData.BallPos[2]
			else
				SoccerData.BallPos[2] = 2*6100 - SoccerData.BallPos[2] 
			end
			SoccerData.BallVelo[2] = -SoccerData.BallVelo[2]
			SetBallPos(SoccerData.BallPos, true)
			--LuaDebugger.Log(SoccerData.BallPos)
			--LuaDebugger.Log(SoccerData.BallVelo)
		end
	end
	
	-- GOAL / CORNER KICK
	-- Check south goal
	if SoccerData.BallPos[1] < 3400 then
		-- goal?
		if SoccerData.BallPos[2] >= 8800 and SoccerData.BallPos[2] <= 10500 then
			SoccerData.GoalsNorth = SoccerData.GoalsNorth + 1
			AnnounceGoal( 2)
			SetBallPos({10050, 9650})
			TorSoundTimer = 0
			StartSimpleHiResJob("GoalSoundJob")
			SoccerData.GameRunning = false
			DoGoalReset()
			ResumeCounter = 8
			StartSimpleJob("ResumeGameJob")
		else -- or corner kick/goal keeper job?
			if not Settings.Boards then 
				if SoccerData.LastTeam == 1 then -- corner kick
					Message("Ecke für das Nordteam!")
					PlayRefSound()
					if SoccerData.BallPos[2] > 10500 then
						SetBallPos( {3500, 13200})
					else
						SetBallPos( {3500, 6200})
					end
					local myHero = GetNearestHeroFromTeam( 2, SoccerData.BallPos)
					PushHeroesBack( SoccerData.BallPos, myHero)
					SetPosition( myHero, {3400, SoccerData.BallPos[2]}, true)
				else -- goal keeper job
					Message("Der Ball geht an den Keeper des Südteams!")
					PlayRefSound()
					SetBallPos( {3500, 9650})
					local myHero = GetNearestHeroFromTeam( 1, SoccerData.BallPos)
					PushHeroesBack( SoccerData.BallPos, myHero)
					SetPosition( myHero, {3400, 9650}, true)
				end
			else -- here just bounce
				SoccerData.BallPos[1] = 2*3400 - SoccerData.BallPos[1]
				SetBallPos(SoccerData.BallPos, true)
				SoccerData.BallVelo[1] = -SoccerData.BallVelo[1]
			end
		end
		return
	end
	
	-- North goal
	if SoccerData.BallPos[1] > 16700 then
		-- goal?
		if SoccerData.BallPos[2] >= 8800 and SoccerData.BallPos[2] <= 10500 then
			SoccerData.GoalsSouth = SoccerData.GoalsSouth + 1
			AnnounceGoal( 1)
			TorSoundTimer = 0
			StartSimpleHiResJob("GoalSoundJob")
			SetBallPos({10050, 9650})
			SoccerData.GameRunning = false
			DoGoalReset()
			ResumeCounter = 8
			StartSimpleJob("ResumeGameJob")
		else -- or corner kick/goal keeper job?
			if not Settings.Boards then 
				if SoccerData.LastTeam == 2 then -- corner kick
					Message("Ecke für das Südteam!")
					PlayRefSound()
					if SoccerData.BallPos[2] > 10500 then
						SetBallPos( {16600, 13200})
					else
						SetBallPos( {16600, 6200})
					end
					local myHero = GetNearestHeroFromTeam( 1, SoccerData.BallPos)
					PushHeroesBack( SoccerData.BallPos, myHero)
					SetPosition( myHero, {16700, SoccerData.BallPos[2]}, true)
				else -- goal keeper job
					Message("Der Ball geht an den Keeper des Nordteams!")
					PlayRefSound()
					SetBallPos( {16600, 9650})
					local myHero = GetNearestHeroFromTeam( 2, SoccerData.BallPos)
					PushHeroesBack( SoccerData.BallPos, myHero)
					SetPosition( myHero, {16800, 9650}, true)
				end
			else
				SoccerData.BallPos[1] = 2*16700 - SoccerData.BallPos[1]
				SoccerData.BallVelo[1] = -SoccerData.BallVelo[1]
				SetBallPos(SoccerData.BallPos, true)
			end
		end
		return
	end
	
end
function CheckForHeroCollisions()
	local b = SoccerData.BallPos
	local v = SoccerData.BallVelo
	local listOfHeros = S5Hook.EntityIteratorTableize(Predicate.OfCategory(EntityCategories.Hero))
	local h
	local normV = v[1]^2 + v[2]^2
	local d = SoccerConfig.StopDistance^2
	local dotP, c, mySol
	
	local minColTime = 0.1
	local minColHero = 0
	for i = 1, table.getn(listOfHeros) do
		if listOfHeros[i] ~= SoccerData.LastHero then
			h = GetPos(listOfHeros[i])
			-- to solve
			-- norm(v)^2 t^2 + 2t dotP(b-h, v) + norm(b-h)^2 = StopDistance^2
			dotP = (b[1] - h[1])*v[1] + (b[2] - h[2])*v[2]
			c = Norm({b[1] - h[1], b[2] - h[2]})
			
			-- dont bother if ball is moving away from hero
			if dotP < 0 then
				solutions = {SolveQuadEq( normV, 2*dotP, c, d)}
				
				if c < d then
					return listOfHeros[i], 0
				end
				if table.getn(solutions) > 0 then
					mySol = solutions[1]
				else
					mySol = 1
				end
				if mySol <= minColTime and mySol > 0 then
					minColTime = mySol
					minColHero = listOfHeros[i]
				end
			end
		end
	end
	return minColHero, minColTime
end

function CreateSpectators()
	--[[
		-- Field:
	-- Y \in [6100, 13300]
	-- X \in [3400, 16700]
	-- Goals:
	-- Y \in [8800, 10500]
	]]
	local y = 13500
	local off = 5
	local eId
	local listOfModels = {
		Models.CU_BanditLeaderBow1,
		Models.CU_BishopOfCrawford,
		Models.CU_Evil_Queen,
		Models.CU_Leonardo,
		Models.CU_RegentDovbar,
		Models.CU_Princess
	}
	local listOfSpectators = {
		Entities.PV_Cannon1,
		Entities.PV_Cannon2,
		Entities.PU_LeaderSword3,
		Entities.PU_LeaderRifle1,
		Entities.PU_Serf,
		Entities.PU_LeaderBow4,
		Entities.CU_AlchemistIdle,
		Entities.CU_MasterBuilder,
		Entities.CU_Merchant,
		Entities.CU_Wanderer,
		Entities.CU_MinerIdle
	}
	local specCount = table.getn(listOfSpectators)
	local modelCount = table.getn(listOfModels)
	ListOfSpectators = {}
	for x = 3800, 16300, 50 do
		off = math.mod(off*5, 17)
		if math.mod(off, 4) == 1 then
			eId = Logic.CreateEntity(Entities.XA_Deer, x, y + off*25, 270, 0)
			Logic.SuspendEntity(eId)
			Logic.SetModelAndAnimSet( eId, listOfModels[math.random(modelCount)])
		else
			eId = Logic.CreateEntity(listOfSpectators[math.random(specCount)], x, y + off*25, 270, 0)
			Logic.SuspendEntity(eId)
			table.insert( ListOfSpectators, eId)
			--S5Hook.GetEntityMem(eId)[130]:SetInt(4)
		end
	end
	y = 5000
	for x = 3800, 16300, 50 do
		off = math.mod(off*5, 17)
		if math.mod(off, 4) == 1 then
			eId = Logic.CreateEntity(Entities.XA_Deer, x, y + off*25, 90, 0)
			Logic.SuspendEntity(eId)
			Logic.SetModelAndAnimSet( eId, listOfModels[math.random(modelCount)])
		else
			eId = Logic.CreateEntity(listOfSpectators[math.random(specCount)], x, y + off*25, 90, 0)
			Logic.SuspendEntity(eId)
			table.insert( ListOfSpectators, eId)
			--S5Hook.GetEntityMem(eId)[130]:SetInt(4)
		end
	end
	StartSimpleJob("RemoveOverheadWidgets")
end
function RemoveOverheadWidgets()
	for i = 1, table.getn(ListOfSpectators) do
		S5Hook.GetEntityMem(ListOfSpectators[i])[130]:SetInt(4)
	end
	return true
end
function CreateBoards()
	-- Field:
	-- Y \in [6100, 13300]
	-- X \in [3400, 16700]
	-- Goals:
	-- Y \in [8800, 10500]
	local eId, x, y
	for j = 1, 34 do
		x = 13300/34 *(j-1) + 3600
		eId = Logic.CreateEntity(Entities.XD_Rock1, x, 6100, 0, 0)
		Logic.SetModelAndAnimSet( eId, Models.XD_IronGrid4)
		eId = Logic.CreateEntity(Entities.XD_Rock1, x, 13300, 0, 0)
		Logic.SetModelAndAnimSet( eId, Models.XD_IronGrid4)
	end
	for j = 1, 7 do
		y = 2700/7*(j-1) + 6300
		eId = Logic.CreateEntity(Entities.XD_Rock1, 3400, y, 90, 0)
		Logic.SetModelAndAnimSet( eId, Models.XD_IronGrid1)
		eId = Logic.CreateEntity(Entities.XD_Rock1, 16700, y, 90, 0)
		Logic.SetModelAndAnimSet( eId, Models.XD_IronGrid1)
	end
	for y = 10700, 13100, 400 do
		eId = Logic.CreateEntity(Entities.XD_Rock1, 3400, y, 90, 0)
		Logic.SetModelAndAnimSet( eId, Models.XD_IronGrid1)
		eId = Logic.CreateEntity(Entities.XD_Rock1, 16700, y, 90, 0)
		Logic.SetModelAndAnimSet( eId, Models.XD_IronGrid1)
	end
end

function CocktailJob()
	local pos
	for k,v in pairs(CocktailData) do
		print(k)
		print(v)
		CocktailData[k] = v-1
		if not IsExisting(k) then
			CocktailData[k] = nil
		end
		pos = GetPosition(k)
		Logic.CreateEffect( GGL_Effects.FXSalimHeal, pos.X, pos.Y, 0) 
		if CocktailData[k] == 0 then
			SetMovementspeed( k, SoccerConfig.DefaultMS)
			CocktailData[k] = nil
		end
	end
end

function InitMovieLog()
	MovieLog = {}
	AddToMovieLog("Anpfiff")
	StartSimpleHiResJob("WatchForAltKey")
	MovieWindowShown = false
end
function AddToMovieLog( _msg)
	local timee = Counter["counter1"].TickCount 
	local seconds = math.mod( timee, 60)
	local tenSeconds = math.floor( seconds/10)
	local oneSeconds = seconds - tenSeconds*10
	local minutes = math.floor( timee/60)
	local timeString = "@color:204,204,0: "..minutes..":"..tenSeconds..oneSeconds..": @color:255,255,255 "
	table.insert( MovieLog, timeString.._msg)
end
function WatchForAltKey()
	if XGUIEng.IsModifierPressed(Keys.ModifierAlt) == 1 and not MovieWindowShown then
		MovieWindowShown = true
		MovieWindowText = ""
		local entryCount = table.getn(MovieLog)
		for i = math.max(1, entryCount - 10), entryCount do
			MovieWindowText = MovieWindowText..MovieLog[i].." @cr "
		end
		MovieWindowTitle = "@color:180,180,180: "..SoccerData.GoalsSouth.." : "..SoccerData.GoalsNorth.." @color:255,255,255"
		MovieWindowShow()
	elseif XGUIEng.IsModifierPressed(Keys.ModifierAlt) == 0 and MovieWindowShown then
		MovieWindowShown = false
		MovieWindowHide()
	end
end
function MovieWindowShow()
	XGUIEng.ShowWidget( "Movie", 1 );
	XGUIEng.ShowWidget( "Cinematic_Text", 0 );
	XGUIEng.ShowWidget( "MovieBarTop", 0 );
	XGUIEng.ShowWidget( "MovieBarBottom", 0 );
	XGUIEng.ShowWidget( "MovieInvisibleClickCatcher", 0 );
	XGUIEng.ShowWidget( "CreditsWindowLogo", 0 );
	XGUIEng.SetText( "CreditsWindowTextTitle", MovieWindowTitle );
	XGUIEng.SetText( "CreditsWindowText", MovieWindowText );
end
function MovieWindowHide()
	XGUIEng.ShowWidget( "Movie", 0 )
end

function PlayRefSound()
	RefSoundCounter = 0
	StartSimpleHiResJob("RefSoundJob")
end
function RefSoundJob()
	if RefSoundCounter == 0 then
		Sound.PlayGUISound( Sounds.Misc_SO_WorkMetal_rnd_1, 100 )
	end
	if RefSoundCounter == 1 then
		Sound.PlayGUISound( Sounds.Misc_so_signalhorn, 100 )
	end
	if math.mod(RefSoundCounter, 2) == 0 then
		Sound.PlayGUISound( Sounds.Misc_Countdown1, 50 )
	end
	if RefSoundCounter > 10 then
		return true
	end
	RefSoundCounter = RefSoundCounter + 1
end
function EnforceRules()
	-- first get all heroes near ball
	local b = SoccerData.BallPos
	local heroList = S5Hook.EntityIteratorTableize(Predicate.OfCategory(EntityCategories.Hero), Predicate.InCircle( b[1], b[2], SoccerConfig.NearBallRadius))
	local nHeroesA, nHeroesB = 0,0
	for i = 1, table.getn(heroList) do
		if GetTeamByPlayerId(GetPlayer(heroList[i])) == 1 then
			nHeroesA = nHeroesA + 1
		else
			nHeroesB = nHeroesB + 1
		end
	end
	if nHeroesA > 1 then
		PushTeamHeroesBack( b, 1)
		Message("Nicht alle zum Ball! Seid ihr Bambinis?")
		PlayRefSound()
		return
	end
	if nHeroesB > 1 then
		PushTeamHeroesBack( b, 2)
		Message("Nicht alle zum Ball! Seid ihr Bambinis?")
		PlayRefSound()
		return
	end
	if table.getn(heroList) > 1 then
		SoccerData.TimeOfConflict = SoccerData.TimeOfConflict + 1
	else
		SoccerData.TimeOfConflict = 0
	end
	if SoccerData.TimeOfConflict > 8 then
		PushHeroesBack( b)
		Message("Das Duell wird nichts, ich löse das auf.")
		PlayRefSound()
		return
	end
	
	-- Enforce at max one team player in goal area
	-- GOAL SOUTH
	local goal = {3400, 9650}
	heroList = S5Hook.EntityIteratorTableize(Predicate.OfCategory(EntityCategories.Hero), Predicate.InCircle( goal[1], goal[2], 850))
	local nHeroes = 0
	for i = 1, table.getn(heroList) do
		if GetTeamByPlayerId(GetPlayer(heroList[i])) == 1 then
			nHeroes = nHeroes + 1
		end
	end
	if nHeroes > 1 then
		PushTeamHeroesBack( goal, 1)
		Message("Nicht das Tor zumauern!")
		PlayRefSound()
	end
	
	-- GOAL NORTH
	goal = {16700, 9650}
	heroList = S5Hook.EntityIteratorTableize(Predicate.OfCategory(EntityCategories.Hero), Predicate.InCircle( goal[1], goal[2], 850))
	nHeroes = 0
	for i = 1, table.getn(heroList) do
		if GetTeamByPlayerId(GetPlayer(heroList[i])) == 2 then
			nHeroes = nHeroes + 1
		end
	end
	if nHeroes > 1 then
		PushTeamHeroesBack( goal, 2)
		Message("Nicht das Tor zumauern!")
		PlayRefSound()
	end
end

function AnnounceGoal( _benefitTeam)
	SoccerData.BenefitTeam = _benefitTeam
	if SoccerData.LastTeam == _benefitTeam then
		SoccerData.OwnGoalFlag = false
	else
		SoccerData.OwnGoalFlag = true
	end
	
	if _benefitTeam == 1 then
		Message(" @color:255,255,0 T @color:255,0,255 O @color:0,255,255 R  @color:255,128,128 FÜR DAS SÜDTEAM")
	else
		Message(" @color:255,255,0 T @color:255,0,255 O @color:0,255,255 R  @color:255,128,128 FÜR DAS NORDTEAM")
	end
	local playerName = XNetwork.GameInformation_GetLogicPlayerUserName( SoccerData.LastPlayer)
	local heroName = GetHeroNameByType( SoccerData.LastHeroType)
	local r,g,b = GUI.GetPlayerColor( SoccerData.LastPlayer)
	local colorString = "@color:"..r..","..g..","..b.." "
	
	local messagePool
	if not SoccerData.OwnGoalFlag then
		messagePool = {
			{" @color:255,255,255 hat mit @color:255,128,128 ", " @color:255,255,255 eingelocht!"},
			{" @color:255,255,255 hats gedreht! Wasn Schuss von @color:255,128,128 ", " @color:255,255,255 !"},
			{" @color:255,255,255 rockt ab! @color:255,128,128 ", " @color:255,255,255 geht ab!"},
			{" @color:255,255,255 zielsicher! @color:255,128,128 ", " @color:255,255,255 macht ihn rein!"},
			{" @color:255,255,255 juche! OLE OLE @color:255,128,128 ", " @color:255,255,255 macht ihn rein!"}
		}
	else
		messagePool = {
			{" @color:255,255,255 hat versagt! Da schoss @color:255,128,128 ", " @color:255,255,255 ins eigene Tor!"},
			{" @color:255,255,255 ist von gestern! @color:255,128,128 ", " @color:255,255,255 spielt wohl fuer den Gegner!"},
			{" @color:255,255,255 WAS WAR DAS? @color:255,128,128 ", " @color:255,255,255 wollte das wohl nicht!"},
			{" @color:255,255,255 hat @color:255,128,128 ", " @color:255,255,255 nicht unter Kontrolle!"},
			{" @color:255,255,255 SCHIESST EIN EIGENTOR! Was hat @color:255,128,128 ", " @color:255,255,255 da gemacht?"}
		}
	end
	local message = messagePool[math.random(5)]
	Message(colorString..playerName..message[1]..heroName..message[2])
	AddToMovieLog(colorString..playerName..message[1]..heroName..message[2])
	Message(" ")
	
	Message("Es steht "..SoccerData.GoalsSouth..":"..SoccerData.GoalsNorth)
end
function DoGoalReset()
	local heroTable = S5Hook.EntityIteratorTableize( Predicate.OfCategory(EntityCategories.Hero))
	local countA, countB = 1,1
	local newId
	for i = 1, table.getn(heroTable) do
		if GetTeamByPlayerId(GetPlayer(heroTable[i])) == 1 then
			newId = SetPosition( heroTable[i], GetPos("T2_"..countA))
			countA = math.mod(countA, 11) + 1
		else
			newId = SetPosition( heroTable[i], GetPos("T1_"..countB))
			countB = math.mod(countB, 11) + 1
		end
		Logic.SetEntitySelectableFlag( newId, 0)
		GUI.DeselectEntity( newId)
		DestroyEntity( heroTable[i])
	end
end
function GoalSoundJob()
	if TorSoundTimer == 0 or TorSoundTimer == 8 or TorSoundTimer == 16 or TorSoundTimer == 20 or TorSoundTimer == 24 or TorSoundTimer == 32 or TorSoundTimer == 36 or TorSoundTimer == 40 or TorSoundTimer == 44  or TorSoundTimer == 52 or TorSoundTimer == 56  then
		id = Sound.PlayGUISound( Sounds.Buildings_SO_StonemineCraneUp , 100 )
	elseif TorSoundTimer > 70 then
		return true
	end
	TorSoundTimer = TorSoundTimer + 1
	if TorSoundTimer == 70 then
		if SoccerData.OwnGoalFlag and SoccerData.BenefitTeam ~= GetTeamByPlayerId(GUI.GetPlayerID()) then
			Sound.PlayGUISound( Sounds.VoicesMentor_COMMENT_BadPlay_rnd_01, 100)
		end
		if not SoccerData.OwnGoalFlag and SoccerData.BenefitTeam == GetTeamByPlayerId(GUI.GetPlayerID())then
			Sound.PlayGUISound( Sounds.VoicesMentor_COMMENT_GoodPlay_rnd_01, 100)
		end
	end
end
function ResumeGameJob()
	if ResumeCounter > 0 then
		if ResumeCounter < 4 then
			Message("Das Spiel wird in "..ResumeCounter.. " Sekunden fortgesetzt.")
		end
		ResumeCounter = ResumeCounter - 1
	else
		Message("HAJIME!")
		local heroTable = S5Hook.EntityIteratorTableize( Predicate.OfCategory(EntityCategories.Hero))
		for i = 1, table.getn(heroTable) do 
			Logic.SetEntitySelectableFlag( heroTable[i], 1)
		end
		SoccerData.GameRunning = true
		Sound.PlayGUISound( Sounds.fanfare , 100 )
		return true
	end
end


function PushHeroesBack( _pos, _ignoreId)
	local heroTable = S5Hook.EntityIteratorTableize( Predicate.OfCategory(EntityCategories.Hero), Predicate.InCircle(_pos[1], _pos[2], SoccerConfig.Knockback))
	local hId, hPos, dX, dY, dis
	for i = 1, table.getn(heroTable) do
		hId = heroTable[i]
		if hId ~= _ignoreId then
			hPos = GetPosition( hId)
			dX, dY = hPos.X - _pos[1], hPos.Y - _pos[2]
			dis = math.sqrt(dX^2 + dY^2)
			if dis < SoccerConfig.Knockback then
				SetPosition( hId, {_pos[1] + SoccerConfig.Knockback/dis*dX, _pos[2] + SoccerConfig.Knockback/dis*dY})
			end
		end
	end
end
function PushTeamHeroesBack( _pos, _team)
	local heroTable = S5Hook.EntityIteratorTableize( Predicate.OfCategory(EntityCategories.Hero), Predicate.InCircle(_pos[1], _pos[2], SoccerConfig.Knockback))
	local hId, hPos, dX, dY, dis
	for i = 1, table.getn(heroTable) do
		hId = heroTable[i]
		if GetTeamByPlayerId(GetPlayer(hId)) == _team then
			hPos = GetPosition( hId)
			dX, dY = hPos.X - _pos[1], hPos.Y - _pos[2]
			dis = math.sqrt(dX^2 + dY^2)
			if dis < SoccerConfig.Knockback then
				SetPosition( hId, {_pos[1] + SoccerConfig.Knockback/dis*dX, _pos[2] + SoccerConfig.Knockback/dis*dY})
			end
		end
	end
end
function SetBallPos( _pos, _keepVelo)
	if not _keepVelo then
		SoccerData.BallVelo = {0,0}
	end
	SoccerData.BallPos = _pos
	DestroyEntity( SoccerData.BallId)
	SoccerData.BallId = Logic.CreateEntity( BALLTYPE, _pos[1], _pos[2], 0, SoccerData.BallRot)
	Logic.SetModelAndAnimSet( SoccerData.BallId, BALLMODEL)
end

-- Common checks for the kick logic
function IsKickValid( _sender, _heroId)
	if not CNetwork.IsAllowedToManipulatePlayer( _sender, Logic.EntityGetPlayer( _heroId)) then
		return false
	end
	local distanceSq = GetDistanceSq( SoccerData.BallPos, GetPos( _heroId))
	if distanceSq > SoccerData.KickDistanceSq then
		return false
	end
	return SoccerData.GameRunning
end
function DoKick( _heroId, _velo)
	local hPos = GetPos( _heroId)
	local dX, dY = SoccerData.BallPos[1] - hPos[1], SoccerData.BallPos[2] - hPos[2]
	local totalDis = math.sqrt(dX^2 + dY^2)
	SoccerData.BallVelo = { _velo*dX / totalDis, _velo*dY / totalDis}
	SoccerData.LastTeam = GetTeamByPlayerId(GetPlayer(_heroId))
	SoccerData.LastHero = _heroId
	SoccerData.LastHeroType = Logic.GetEntityType(_heroId)
	SoccerData.LastPlayer = GetPlayer(_heroId)
	PlayKickSound()
end
function PlayKickSound()
	local x,y = Camera.ScrollGetLookAt();
	local posBall = SoccerData.BallPos
	local xDistance = (posBall[1] - x);
	local yDistance = (posBall[2] - y);
	local _distance = math.sqrt((xDistance^2) + (yDistance^2));
	if _distance < 3400 then
		Sound.PlayGUISound( Sounds.Military_SO_Cannon_rnd_1 , 100 - _distance/35)
	end
end
-- Actual callbacks
function ShortKick( _sender, _heroId)
	if not IsKickValid( _sender, _heroId) then
		return
	end
	DoKick( _heroId, SoccerConfig.ShortKickVelo)
end
function LongKick( _sender, _heroId)
	if not IsKickValid( _sender, _heroId) then
		return
	end
	local kickVelo = SoccerConfig.LongKickVelo
	DoKick( _heroId, SoccerConfig.LongKickVelo)
end
function ActivateCocktail( _sender, _heroId)
	if not CNetwork.IsAllowedToManipulatePlayer( _sender, Logic.EntityGetPlayer( _heroId)) then
		return false
	end
	-- check if cd is ready
	if CocktailData[_heroId] ~= nil then
		if CocktailData[_heroId] > 0 then
			return
		end
	end	
	Logic.HurtEntity( _heroId, SoccerConfig.CocktailCost)
	CocktailData[_heroId] = SoccerConfig.CocktailDuration
	SetMovementspeed( _heroId, SoccerConfig.CocktailMS)
	StartSimpleHiResJob("CocktailSoundJob")
	CocktailSoundCounter = 0
	Sound.PlayGUISound( Sounds.Military_so_serfFist_rnd_1, 100)
end

function CocktailSoundJob()
	CocktailSoundCounter = CocktailSoundCounter + 1
	if CocktailSoundCounter == 2 then
		Sound.PlayGUISound( Sounds.Buildings_SO_AlchemistBlubber_rnd_1, 100)
	end
	if CocktailSoundCounter == 6 then
		Sound.PlayGUISound( Sounds.OnKlick_PB_Alchemist2, 100)
	end
	if CocktailSoundCounter > 6 then
		return true
	end
end

function OnGameOver()
	Message("ES IST AUS!")
	PlayRefSound()
	EndJob(SoccerData.JobId)
	SoccerData.GameRunning = false
	local winner
	if SoccerData.GoalsNorth > SoccerData.GoalsSouth then
		winner = 2
		local diff = SoccerData.GoalsNorth - SoccerData.GoalsSouth
		if diff < 2 then
			GUI.AddStaticNote("Das Nordteam konnte sich knapp durchsetzen! Gut gespielt!")
		elseif diff < 3 then
			GUI.AddStaticNote("Das Nordteam konnte sich souverän durchsetzen. Schön!")
		else
			GUI.AddStaticNote("Die Spieler des Südteams sollten einen Karrierewechsel anstreben.")
		end
	elseif SoccerData.GoalsNorth < SoccerData.GoalsSouth then
		winner = 1
		local diff = -SoccerData.GoalsNorth + SoccerData.GoalsSouth
		if diff < 2 then
			GUI.AddStaticNote("Das Südteam konnte sich knapp durchsetzen! Gut gespielt!")
		elseif diff < 3 then
			GUI.AddStaticNote("Das Südteam konnte sich souverän durchsetzen. Schön!")
		else
			GUI.AddStaticNote("Die Spieler des Nordteams sollten einen Karrierewechsel anstreben.")
		end
	else
		winner = 0
		local totalGoals = SoccerData.GoalsNorth + SoccerData.GoalsSouth
		if totalGoals < 3 then
			GUI.AddStaticNote("Das Spiel endet in einem Unentschieden!")
		elseif totalGoals < 7 then
			GUI.AddStaticNote("Beide Teams haben alles gegeben, aber kein Team konnte sich den Sieg heute sichern.")
		else
			GUI.AddStaticNote("Beide Teams haben ihren Keeper zuhause vergessen. Heute hat niemand gewonnen.")
		end
	end
	GUI.AddStaticNote(" ")
	GUI.AddStaticNote("Das Endergebnis: "..SoccerData.GoalsSouth.." zu "..SoccerData.GoalsNorth)
	GUI.AddStaticNote(" ")
	GUI.AddStaticNote("Wir danken allen Zuschauern für Ihre Aufmerksamkeit. Schalten Sie auch nächstes Mal wieder ein.")
	local listOfSponsors = {
		"@color:178,34,34 RAID SHADOW LEGENDS",
		"@color:255,69,0 RAYCON",
		"@color:255,255,255 KORO DROGERIE",
		"@color:178,34,34 DRECKS MOBILE CASH GRAB GAME #52341",
		"@color:255,0,255 NAPO! @color:255,255,255 HULDIGT IHM!",
		"@color:0,206,209 EUCH AUF ONLYFANS!",
		"@color:0,206,209 EUCH AUF PATREON!"
	}
	local sponsor = listOfSponsors[math.random(table.getn(listOfSponsors))]
	GUI.AddStaticNote("Dieses Spiel wurde Ihnen präsentiert von "..sponsor)
	if winner == GetTeamByPlayerId(GUI.GetPlayerID()) then
		Sound.PlayGUISound( Sounds.VoicesMentor_VC_YourTeamHasWon_rnd_01, 100 )
	else
		Sound.PlayGUISound( Sounds.VoicesMentor_VC_YourTeamHasLost_rnd_02, 100 )
	end
end
-- Comforts
function LoadSetPosition()
	SetPosition = function ( _id, _pos, _forceCam) 
		local player = GetPlayer(_id)
		local type = Logic.GetEntityType(_id)
		local selected = (_id == GUI.GetSelectedEntity())
		local health = Logic.GetEntityHealth( _id)
		DestroyEntity( _id)
		local newId = Logic.CreateEntity( type, _pos[1], _pos[2], 0, player)
		Logic.HurtEntity( newId, 600 - health)
		if _forceCam and player == GUI.GetPlayerID() then
			Camera.ScrollSetLookAt( _pos[1], _pos[2])
		end
		if selected then
			GUI.SelectEntity( newId)
		end
		return newId
	end
end
function GetPos( _id)
	if type(_id) == "string" then
		_id = GetEntityId(_id)
	end
	return {Logic.GetEntityPosition(_id)}
end
function GetNearestHeroFromTeam( _teamId, _pos)
	local heroTable = S5Hook.EntityIteratorTableize( Predicate.OfCategory(EntityCategories.Hero))
	local nearestHero = 0
	local dis = 10^10
	local disSq
	for i = 1, table.getn(heroTable) do
		if GetTeamByPlayerId(GetPlayer(heroTable[i])) == _teamId then
			disSq = GetDistanceSq( _pos, GetPos(heroTable[i]))
			if disSq < dis then
				dis = disSq
				nearestHero = heroTable[i]
			end
		end
	end
	return nearestHero
end
function GetTeamByPlayerId( _pId)
	if _pId < 5 then
		return 1
	else
		return 2
	end
end
function GetDistance( _p1, _p2)
	return math.sqrt( GetDistanceSq( _p1, _p2))
end
function GetDistanceSq( _p1, _p2)
	return (_p1[1]-_p2[1])^2 + (_p1[2]-_p2[2])^2
end
function ClipValue( _val, _min, _max)
	if _val > _max then
		return _max
	elseif _val < _min then
		return _min
	else
		return _val
	end
end
function GetHeroNameByType(_ID)
   if _ID == Entities.PU_Hero1c then return "Dario"; end
   if _ID == Entities.PU_Hero2 then return "Pilgrim"; end
   if _ID == Entities.PU_Hero3 then return "Salim"; end
   if _ID == Entities.PU_Hero4 then return "Erec"; end
   if _ID == Entities.PU_Hero5 then return "Ari"; end
   if _ID == Entities.PU_Hero6 then return "Helias"; end
   return "Anon"
end
function SetMovementspeed( _eId, _ms)
	S5Hook.GetEntityMem( _eId)[31][1][5]:SetFloat( _ms)
end
function GetMovementspeed( _eId)
	return S5Hook.GetEntityMem( _eId)[31][1][5]:GetFloat()
end
-- Solves a x^2 + bx + c = d
-- Always assumes that a is positive
function SolveQuadEq( a, b, c, d)
	-- get rid of a
	b = b/a
	c = c/a
	d = d/a
	det = d - c + b^2/4
	if det < 0 then
		return
	elseif det == 0 then
		return -b/2
	else
		rootDet = math.sqrt(det)
		return -b/2 + rootDet, -b/2 - rootDet
	end
end
function Norm(v)
	return v[1]^2 + v[2]^2
end

--Countdown Comfort Funktionen
 
function StartCountdown(_Limit, _Callback, _Show)
    assert(type(_Limit) == "number")
 
    Counter.Index = (Counter.Index or 0) + 1
 
    if _Show and CountdownIsVisisble() then
        assert(false, "StartCountdown: A countdown is already visible")
    end
 
    Counter["counter" .. Counter.Index] = {Limit = _Limit, TickCount = 0, Callback = _Callback, Show = _Show, Finished = false}
 
    if _Show then
        MapLocal_StartCountDown(_Limit)
    end
 
    if Counter.JobId == nil then
        Counter.JobId = StartSimpleJob("CountdownTick")
    end
 
    return Counter.Index
end
 
function StopCountdown(_Id)
    if Counter.Index == nil then
        return
    end
 
    if _Id == nil then
        for i = 1, Counter.Index do
            if Counter.IsValid("counter" .. i) then
                if Counter["counter" .. i].Show then
                    MapLocal_StopCountDown()
                end
                Counter["counter" .. i] = nil
            end
        end
    else
        if Counter.IsValid("counter" .. _Id) then
            if Counter["counter" .. _Id].Show then
                MapLocal_StopCountDown()
            end
            Counter["counter" .. _Id] = nil
        end
    end
end
 
function CountdownTick()
    local empty = true
    for i = 1, Counter.Index do
        if Counter.IsValid("counter" .. i) then
            if Counter.Tick("counter" .. i) then
                Counter["counter" .. i].Finished = true
            end
 
            if Counter["counter" .. i].Finished and not IsBriefingActive() then
                if Counter["counter" .. i].Show then
                    MapLocal_StopCountDown()
                end
 
                -- callback function
                if type(Counter["counter" .. i].Callback) == "function" then
                    Counter["counter" .. i].Callback()
                end
 
                Counter["counter" .. i] = nil
            end
 
            empty = false
        end
    end
 
    if empty then
        Counter.JobId = nil
        Counter.Index = nil
        return true
    end
end

function CountdownIsVisisble()
    for i = 1, Counter.Index do
        if Counter.IsValid("counter" .. i) and Counter["counter" .. i].Show then
            return true
        end
    end
 
    return false
end
 
