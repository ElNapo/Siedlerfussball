--[[   //  S5Hook  //  by yoq  // v2.2.noHurt.noChangeString.noRuntimeStore
    
    S5Hook.Version                                              string, the currently loaded version of S5Hook
                                                                 
    S5Hook.Log(string textToLog)                                Writes the string textToLog into the Settlers5 logfile
                                                                 - In MyDocuments/DIE SIEDLER - DEdK/Temp/Logs/Game/XXXX.log
    
    S5Hook.ReloadCutscenes()                                    Reload the cutscenes in a usermap after a savegame load, the map archive must be loaded!
    
    S5Hook.LoadGUI(string pathToXML)                            Load a GUI definition from a .xml file.
                                                                 - call after AddArchive() for files inside the s5x archive
                                                                 - Completely replaces the old GUI --> Make sure all callbacks exist in the Lua script
                                                                 - Do NOT call this function in a GUI callback (button, chatinput, etc...)
                                                                 
    S5Hook.Eval(string luaCode)                                    Parses luaCode and returns a function, can be used to build a internal debugger
                                                                 - ex: myFunc = S5Hook.Eval("Message('Hello world')")
                                                                       myFunc()
                                                                       
    S5Hook.ReloadEntities()                                        Reloads all entity definitions, not the entities list -> only modifications are possible
                                                                 - In general: DO NOT USE, this can easily crash the game and requires extensive testing to get it right
                                                                 - Requires the map to be added with precedence
                                                                 - Only affects new entities -> reload map / reload savegame
                                                                 - To keep savegames working, it is only possible to make entities more complex (behaviour, props..)
                                                                   do not try to remove props/behaviours (ex: remove darios hawk), this breaks simple savegame loading
    
    S5Hook.SetSettlerMotivation(eID, motivation)                Set the motivation for a single settler (and only settlers, crashes otherwise ;)
                                                                 - motivation 1 = 100%, 0.2 = 20% settlers leaves
                                                                 
    S5Hook.GetSettlerMaxWorktime(eID)                           Gets the maximum worktime for a worker. (Although Farm+Residence regenerates more than this amount)
                                                                 
    S5Hook.GetWidgetPosition(widget)                            Gets the widget position relative to its parent
                                                                - return1: X
                                                                - return2: Y
                                                                
    S5Hook.GetWidgetSize(widget)                                Gets the size of the widget
                                                                - return1: width
                                                                - return2: height
                                                                
    S5Hook.IsValidEffect(effectID)                              Checks whether this effectID is a valid effect, returns a bool
    
    S5Hook.SetPreciseFPU()                                      Sets 53Bit precision on the FPU, allows accurate calculation in Lua with numbers exceeding 16Mil,
                                                                however most calls to engine functions will undo this. Therefore call directly before doing a calculation 
                                                                in Lua and don't call anything else until you're done.

    S5Hook.CreateProjectile(                                    Creates a projectile effect, returns an effectID, which can be used with Logic.DestroyEffect()
                            int effectType,         -- from the GGL_Effects table
                            float startX, 
                            float startY, 
                            float targetX, 
                            float targetY, 
                            int damage,             -- set to 0 if not needed
                            float radius,           -- set to -1 if not needed
                            int targetId,           -- set to 0 if not needed
                            int attackerId,         -- set to 0 if not needed
                            fn hitCallback)         -- fires once the projectile reaches the target (function or something with metamethod, set explicit nil if not needed)
                            
                                                                Single-Hit Projectiles:
                                                                    FXArrow, FXCrossBowArrow, FXCavalryArrow, FXCrossBowCavalryArrow, FXBulletRifleman, FXYukiShuriken, FXKalaArrow

                                                                Area-Hit Projectiles:
                                                                    FXCannonBall, FXCannonTowerBall, FXBalistaTowerArrow, FXCannonBallShrapnel, FXShotRifleman
    
    
    S5Hook.GetTerrainInfo(x, y)                                 Fetches info from the HiRes terrain grid
                                                                 - return1: height (Z)
                                                                 - return2: blocking value, bitfield
                                                                 - return3: sector nr
                                                                 - return4: terrain type
                                                                 
    S5Hook.GetFontConfig(fontId)                                Returns the current font configuration (fontSize, zOffset, letterSpacing), or nil
    S5Hook.SetFontConfig(fontId, size, zOffset, spacing)        Store new configuration for this font

    Internal Filesystem: S5 uses an internal filesystem - whenever a file is needed it searches for the file in the first archive from the top, then the one below...
            | Map File (s5x)      |                             The Map File is only on top of the list during loading / savegame loading, and gets removed after            
            | extra2\bba\data.bba |                                GameCallback_OnGameStart (FirstMapAction) & Mission_OnSaveGameLoaded (OnSaveGameLoaded)
            | base\data.bba       |                             ( <= the list is longer than 3 entries, only for illustration)
            
            S5Hook.AddArchive([string filename])                Add a archive to the top of the filesystem, no argument needed to load current s5x
            S5Hook.RemoveArchive()                              Removes the top-most entry from the filesystem (only removes s5x archives, no bbas).
                                                                 - ex: S5Hook.AddArchive(); S5Hook.LoadGUI("maps/externalmap/mygui.xml"); S5Hook.RemoveArchive()
            S5Hook.GetTopArchive()                              Returns the path to the top archive (bba or s5x)
            
    MusicFix: allows Music.Start() to use the internal file system
            S5Hook.PatchMusicFix()                                      Activate
            S5Hook.UnpatchMusicFix()                                    Deactivate
                                                                         - ex: crickets as background music on full volume in an endless loop
                                                                               S5Hook.PatchMusicFix()
                                                                               Music.Start("sounds/ambientsounds/crickets_rnd_1.wav", 127, true)
                       
    CustomNames: individual names for entities
            S5Hook.SetCustomNames(table nameMapping)                    Activates the function
            S5Hook.RemoveCustomNames()                                  Stop displaying the names from the table
                                                                         - ex: cnTable = { ["dario"] = "Darios new Name", ["erec"] = "Erecs new Name" }
                                                                               S5Hook.SetCustomNames(cnTable)
                                                                               cnTable["thief1"] = "Pete"        -- works since cnTable is a reference
    KeyTrigger: Callback for ALL keys with KeyUp / KeyDown
            S5Hook.SetKeyTrigger(func callbackFn)                       Sets callbackFn as the callback for key events
            S5Hook.RemoveKeyTrigger()                                   Stop delivering events
                                                                         - ex: S5Hook.SetKeyTrigger(function (keyCode, keyIsUp)
                                                                                    Message(keyCode .. " is up: " .. tostring(keyIsUp))
                                                                               end)

    CharTrigger: Callback for pressed characters on keyboard
            S5Hook.SetCharTrigger(func callbackFn)                      Sets callbackFn as the callback for char events
            S5Hook.RemoveCharTrigger()                                  Stop delivering events
                                                                         - ex: S5Hook.SetCharTrigger(function (charAsNum)
                                                                                    Message("Pressed: " .. string.char(charAsNum))
                                                                               end)

    MemoryAccess: Direct access to game objects                         !!!DO NOT USE IF YOU DON'T KNOW WHAT YOU'RE DOING!!!
            S5Hook.GetEntityMem(int eID)                                Gets the address of a entity object
            S5Hook.GetEffectMem(int effectID)                           Gets the adress of an effect object
            S5Hook.GetRawMem(int ptr)                                   Gets a raw pointer
            val = obj[n]                                                Dereferences obj and returns a new address: *obj+4n
            shifted = obj:Offset(n)                                     Returns a new pointer, shifted by n: obj+4n
            val:GetInt(), val:GetFloat(), val:GetString()               Returns the value at the address
            val:SetInt(int newValue), val:SetFloat(float newValue)      Write the value at the address
            val:GetByte(offset), val:SetByte(offset, newValue)          Read or Write a single byte relative to val
            S5Hook.ReAllocMem(ptr, newSize)                             realloc(ptr, newSize), call with ptr==0 to use like malloc()
            S5Hook.FreeMem(ptr)                                         free(ptr)
                                                                         - ex: eObj = S5Hook.GetEntityMem(65537)
                                                                               speedFactor = eObj[31][1][7]:GetFloat()
                                                                               name = eObj[51]:GetString()
                                                                               
   EntityIterator: Fast iterator over all entities                      
            S5Hook.EntityIterator(...)                                  Takes 0 or more Predicate objects, returns an iterator over all matching eIDs
            S5Hook.EntityIteratorTableize(...)                          Takes 0 or more Predicate objects, returns a table with all matching eIDs
                Predicate.InCircle(x, y, r)                             Matches entities in the the circle at (x,y) with radius r (the same condition as Logic.GetEntitiesInArea, just not ordered by distance)
                Predicate.InRect(x0, y0, x1, y1)                        Matches entities with x between x0 and x1, and y between y0 and y1, no need to swap if x0 > x1
                Predicate.IsBuilding()                                  Matches buildings
                Predicate.IsSettler()                                   Matches settlers
                Predicate.InSector(sectorID)
                Predicate.OfPlayer(playerID)
                Predicate.OfType(entityTypeID)
                Predicate.OfCategory(entityCategoryID)
                Predicate.OfUpgradeCategory(upgradeCategoryID)          Matches buildings of the building upgradeCategory (does not work with settler upgradeCategory)
                Predicate.NotOfPlayer0()                                Matches entities with a playerId other than 0
                Predicate.OfAnyPlayer(player1, player2, ...)            Matches entities of any of the specified players
                Predicate.OfAnyType(etyp1, etyp2, ...)                  Matches entities with any of the specified entity types
                Predicate.IsNotSoldier()                                Matches entities that are not soldiers (checked by their leader id)
                Predicate.IsSettlerOrBuilding()                         Matches entities that are settlers or buildings (filters out trees and stones and similar stuff)
                Predicate.ProvidesResource(resourceType)                Matches entities, where serfs can extract the specified resource. Use ResourceType.XXXRaw
                                                                        Notes: Use the iterator version if possible, it's usually faster for doing operations on every match.
                                                                               The Tableize version is just faster if you want to create a table and save it for later.
                                                                               Place the faster / more unlikely predicates in front for better performance!
                                                                        ex: Heal all military units of Player 1
                                                                            for eID in S5Hook.EntityIterator(Predicate.OfPlayer(1), Predicate.OfCategory(EntityCategories.Military)) do
                                                                                AddHealth(eID, 100);
                                                                            end
    
    CNetEvents: Access to the Settlers NetEvents, where Player input is handeled.
            S5Hook.SetNetEventTrigger(func)                             Sets a Trigger function, called every time a CNetEvent is created. Parameters are (memoryAccesToObject, eventId).
            S5Hook.RemoveNetEventTrigger()                              Removes the previously set NetEventTrigger.
            PostEvent                                                   Provides access to many Entity Orders, previously unavaialble in Lua.
    
	
    Global Projectile hit callback:
            S5Hook.SetGlobalProjectileHitCallback(func)                 Sets a function to be called every time a projectile effect hits its target position.
                                                                            Parameters are (effectType, startPosX, startPosY, targetPosX, targetPosY, attackerId, targetId, damage, aoeRange, effectId).
                                                                            aoeRange is -1 for GGL::CArrowEffect class projectiles and targetid is 0 for GGL::CCannonBallEffect class projectiles
                                                                            (because they are invalid/not used for this particular effect class).
                                                                            Any HurtEntityTrigger calls caused by the projectile are executed after the GlobalProjectileHitCallback.
                                                                            For Projectiles fired by S5Hook.CreateProjectile: The projectile specific callback is called first,
                                                                            the global callback will be called after that with its parameters filled from the S5Hook.CreateProjectile call.
            S5Hook.RemoveGlobalProjectileHitCallback()                  Removes the projectile hit callback.
    
    Effect created callback:
            S5Hook.SetEffectCreatedCallback(func)                       Sets a function to be called every time an effect gets created (Projectiles and normal effects).
                                                                            Parameters are (effectType, playerId, startPosX, startPosY, targetPosX, targetPosY, attackerId, targetId, damage, radius, creatorType, effectId, isHookCreated).
                                                                            For GGL::CArrowEffect class effects playerId and radius are invalid.
                                                                            For GGL::CCannonBallEffect class effects playerId and targetId are invalid.
                                                                            For all other effets only effectType, playerId, startPosX, startPosY, creatorType and effectId are valid.
                                                                            isHookCreated is 1 if this effect is a projectile created by S5Hook.CreateProjectile, 0 otherwise.
                                                                            creatorType can determine, what type of effect will be created: 7790912 -> normal effect, 7816856 -> projectile effect
                                                                            (The content of an invalid parameter is undefined (means I don't know if and for what they are good for, but someone might)).
                                                                            Do not call Logic.GetEntityDamage from the callback, this can lead to crashes!
            S5Hook.RemoveEffectCreatedCallback()                        Removes the effect created callback.
    
    S5Hook.GetAnimIdFromName(animName)                                  Returns an animation ID for use with mem funcs from an animation name (string) which can be copied from the xmls.
    
    
    S5Hook.TeleportSettler(id, px, py)                                  Teleports a settler (crashes with buildings) to a target position (by Kimichura).
    
    
    Added Lua 5.1 like bit32 functions:
            bit32.band(...)                                             Returns the bitwise and of all arguments.
            bit32.bor(...)                                              Returns the bitwise or of all arguments.
            bit32.bxor(...)                                             Returns the bitwise xor of all arguments.
            bit32.bnot(i)                                               Returns the bitwise not of an argument (Note: bit32.bnot(0)==-1 , unlike in Lua 5.1).
            bit32.lshift(i, disp)                                       Returns i shifted left by disp, vacant bits are filled by 0, disp<0 shifts right (Note: disp>=32 results in 0, because all bits are shiftet out).
            bit32.rshift(i, disp)                                       Returns i shifted right by disp, vacant bits are filled by 0, disp<0 shifts left (Note: disp>=32 results in 0, because all bits are shiftet out).
            bit32.arshift(i, disp)                                      Returns i shifted right by disp, vacant bits are filled by 0 or 1 preserving the sign, 4, disp<0 shifts left (Note: disp>=32 results in 0 or -1, because all bits are shiftet out).
            bit32.lrotate(i, disp)                                      Returns i rotated left by disp, disp<0 rotates right (Note: the result is the same if you take math.mod(disp,32) ).
            bit32.rrotate(i, disp)                                      Returns i rotated right by disp, disp<0 rotates left (Note: the result is the same if you take math.mod(disp,32) ).
            (Note alshift is the same as lshift, so there is no extra function for it).
    
    
    OnScreenInformation (OSI): 
        Draw additional info near entities into the 3D-View (like healthbar, etc).
        You have to set a trigger function, which will be responsible for drawing 
        all info EVERY frame, so try to write efficient code ;)
        
            S5Hook.OSILoadImage(string path)                            Loads a image and returns an image object
                                                                         - Images have to be reloaded after a savegame load
                                                                         - ex: imgObj = S5Hook.OSILoadImage("graphics\\textures\\gui\\onscreen_emotion_good")

            S5Hook.OSIGetImageSize(imgObj)                              Returns sizeX and sizeY of the given image
                                                                         - ex: sizeX, sizeY = S5Hook.OSIGetImageSize(imgObj)

            S5Hook.OSISetDrawTrigger(func callbackFn)                   callbackFn(eID, bool active, posX, posY) will be called EVERY frame for every 
                                                                           currently visible entity with overhead display, the active parameter become true
                                                                           
            S5Hook.OSIRemoveDrawTrigger()                               Stop delivering events

        Only call from the DrawTrigger callback:
            S5Hook.OSIDrawImage(imgObj, posX, posY, sizeX, sizeY)       Draw the image on the screen. Stretching is allowed.
            
            S5Hook.OSIDrawText(text, font, posX, posY, r, g, b, a)      Draw the string on the screen. Valid values for font range from 1-10.
                                                                        The color is specified by the r,g,b,a values (0-255).
                                                                        a = 255 is maximum visibility
                                                                        Standard S5 modifiers are allowed inside text (@center, etc...)
        Example:
        function SetupOSI()
            myImg = S5Hook.OSILoadImage("graphics\\textures\\gui\\onscreen_emotion_good")
            myImgW, myImgH = S5Hook.OSIGetImageSize(myImg)
            S5Hook.OSISetDrawTrigger(cbFn)
        end

        function cbFn(eID, active, x, y)
            if active then
                S5Hook.OSIDrawImage(myImg, x-myImgW/2, y-myImgH/2 - 40, myImgW, myImgH)
            else
                S5Hook.OSIDrawText("eID: " .. eID, 3, x+25, y, 255, 255, 128, 255)
            end
        end                                                        
    
    Set up with InstallS5Hook(), this needs to be called again after loading a savegame.
    S5Hook only works with the newest patch version of Settlers5, 1.06 and not with the History Edition!
    S5Hook is available immediately, but check the return value, in case the player has a old patchversion.
]]

function InstallHook(installedCallback) -- for compatability with v0.10 or older 
    if InstallS5Hook() then installedCallback() end
end


function InstallS5Hook()
    if nil == string.find(Framework.GetProgramVersion(), "1.06.0217") then
        Message("Error: S5Hook requires version patch 1.06!")
        return false
    end
    if XNetwork.Manager_IsNATReady then
        Message("Error: S5Hook does not work with the History Edition!")
        return false
    end
    
    if not __mem then __mem = {}; end
    __mem.__index = function(t, k) return __mem[k] or __mem.cr(t, k); end
    
    if not __effectcbs then
        __effectcbs = {}
    end
    
    local loader     = { 4202752, 4258997, 0, 5809871, 6111252, 1, 4203043, 4199467, 4383103, 4203359, 4203043, 7737432, 4785748, 4203043, 4761371, 4737232, 4203043, 4198400, 4809160, 4203043, 6598656, 4738141, 4203043, 64, 4738262, 4203043, 8743464, 4224013, 6519628, 4208040, 5855298, 1, 6004378, 6519628, 1, 4952773, 4203043, 7517305, 4494293, 7517305, 1, 4203043, 8731292, 7273523, 4199467, 5881260, 6246939, 6519628, 0, 3, 4203648, 6045570, 6037040, 4375289, 6519628, 6268672, 4199467, 6098484, 6281915, 6282334, 4659101, 10616832, 0, 0 }
    
    local shrink = function(cc)
        local o, i = {}, 1
        for n = 1, string.len(cc) do
            local b = string.byte(cc, n)
            if b >= 97 then n=n+1; b=16*(b-97)+string.byte(cc, n)-97; else b=b-65; end
            o[i] = string.char(b); i = i + 1
        end
        return table.concat(o)
    end
    
    Mouse.CursorHide()
    for i = 1, 37 do Mouse.CursorSet(i); end
    Mouse.CursorSet(10)
    Mouse.CursorShow() 
    
    local eID = Logic.CreateEntity(Entities.XD_Plant1, 0, 0, 0, 0)
    local d, w, r = {}, Logic.SetEntityScriptingValue, Logic.GetEntityScriptingValue
    if (r(eID, -58) ~= 7880308) then
        Message("Error: vtable not at expected offset!")
        return false
    end
    for o, v in loader do 
        d[o] = r(eID, -59+o)
        if v ~= 0 then w(eID, -59+o, v); end
    end
    Logic.HeroSetActionPoints(eID, 7517305, shrink(table.concat(S5HookData)))
    for o, v in d do w(eID, -59+o, v); end
    Logic.DestroyEntity(eID)
    
    if S5Hook ~= nil then 
        S5HookEventSetup();
        S5HookBitSetup()
        return true;
    end
end

function S5HookEventSetup()
    PostEvent = {}
    function PostEvent.SerfExtractResource(eID, resourceType, posX, posY)   __event.xr(eID, resourceType, posX, posY); end
    function PostEvent.SerfConstructBuilding(serf_eID, building_eID)        __event.e2(69655, serf_eID, building_eID); end
    function PostEvent.SerfRepairBuilding(serf_eID, building_eID)           __event.e2(69656, serf_eID, building_eID); end
    function PostEvent.HeroSniperAbility(heroId, targetId)                  __event.e2(69705, heroId, targetId); end
    function PostEvent.HeroShurikenAbility(heroId, targetId)                __event.e2(69708, heroId, targetId); end
    function PostEvent.HeroConvertSettlerAbility(heroId, targetId)          __event.e2(69695, heroId, targetId); end
    function PostEvent.ThiefStealFrom(thiefId, buildingId)                  __event.e2(69699, thiefId, buildingId); end
    function PostEvent.ThiefCarryStolenStuffToHQ(thiefId, buildingId)       __event.e2(69700, thiefId, buildingId); end
    function PostEvent.ThiefSabotage(thiefId, buildingId)                   __event.e2(69701, thiefId, buildingId); end
    function PostEvent.ThiefDefuse(thiefId, kegId)                          __event.e2(69702, thiefId, kegId); end
    function PostEvent.ScoutBinocular(scoutId, posX, posY)                  __event.ep(69704, scoutId, posX, posY); end
    function PostEvent.ScoutPlaceTorch(scoutId, posX, posY)                 __event.ep(69706, scoutId, posX, posY); end
    function PostEvent.HeroPlaceBombAbility(heroId, posX, posY)             __event.ep(69668, heroId, posX, posY); end
    function PostEvent.LeaderBuySoldier(leaderId)                           __event.e(69644, leaderId); end
    function PostEvent.UpgradeBuilding(buildingId)                          __event.e(69640, buildingId); end
    function PostEvent.CancelBuildingUpgrade(buildingId)                    __event.e(69662, buildingId); end
    function PostEvent.ExpellSettler(entityId)                              __event.e(69647, entityId); end
    function PostEvent.BuySerf(buildingId)                                  __event.epl(69636, GetPlayer(buildingId), buildingId); end
    function PostEvent.SellBuilding(buildingId)                             __event.epl(69638, GetPlayer(buildingId), buildingId); end
    function PostEvent.FoundryConstructCannon(buildingId, entityType)       __event.ei(69684, buildingId, entityType); end
    function PostEvent.HeroPlaceCannonAbility(heroId, bottomType, topType, posX, posY)  __event.cp(heroId, bottomType, topType, posX, posY); end
    
end

function S5HookBitSetup()
    bit32 = {}
    function bit32.band(...)
        local r = nil
        for _,a in ipairs(arg) do
            r = r and S5Hook.BitAnd(r, a) or a
        end
        return r
    end
    function bit32.bor(...)
        local r = nil
        for _,a in ipairs(arg) do
            r = r and S5Hook.BitOr(r, a) or a
        end
        return r
    end
    function bit32.bxor(...)
        local r = nil
        for _,a in ipairs(arg) do
            r = r and S5Hook.BitXor(r, a) or a
        end
        return r
    end
    bit32.bnot = S5Hook.BitNot
    function bit32.arshift(i, disp)
        if disp<0 then
            return bit32.lshift(i, -disp)
        end
        return S5Hook.BitAShR(i, math.max(disp, 32))
    end
    function bit32.lrotate(i, disp)
        if disp<0 then
            return bit32.rrotate(i, -disp)
        end
        return S5Hook.BitRoL(i, math.mod(disp, 32))
    end
    function bit32.rrotate(i, disp)
        if disp<0 then
            return bit32.lrotate(i, -disp)
        end
        return S5Hook.BitRoR(i, math.mod(disp, 32))
    end
    function bit32.lshift(i, disp)
        if disp<0 then
            return bit32.rshift(i, -disp)
        end
        if disp > 31 then
            return 0
        end
        return S5Hook.BitShL(i, disp)
    end
    function bit32.rshift(i, disp)
        if disp<0 then
            return bit32.lshift(i, -disp)
        end
        if disp > 31 then
            return 0
        end
        return S5Hook.BitShR(i, disp)
    end
end

S5HookHurtEntitySources = {
    MeleeAttack = 5294698,
    ArrowProjectile = 5313484,
    CannonProjectile = 4848073,
    CircularAttackAbility = 5236524,
    SniperAttackAbility = 5092867,
    ScriptAttack = 0, -- gets filled in from loader
}

local s5h = "ejFkcAbpcfAAfddfeigpgpglAfggfhchdgjgpgoAdccodccogogpeihfhchecogogpedgigbgoghgffdhehcgjgoghcogogpfchfgohegjgngffdhegphcgfAcfhdKAcfhdfmcfhdcohddfhiAkccekcAHffgogmgpgbgeAjocekcAGechcgfgbglAfiGkcAOfagbhegdgienhfhdgjgdeggjhiAckGkcAQffgohagbhegdgienhfhdgjgdeggjhiAdoHkcANepfdejemgpgbgeejgngbghgfAioHkcAQepfdejehgfheejgngbghgffdgjhkgfAmeHkcANepfdejeehcgbhhejgngbghgfAblIkcAMepfdejeehcgbhhfegfhiheAhhIkcASepfdejfdgfheeehcgbhhfehcgjghghgfhcAjnIkcAVepfdejfcgfgngphggfeehcgbhhfehcgjghghgfhcAeeJkcAEemgpghAgbJkcALebgegeebhcgdgigjhggfAmpJkcAOfcgfgngphggfebhcgdgigjhggfAppJkcAOehgfhefegphaebhcgdgigjhggfAbmKkcAQfcgfgmgpgbgeedhfhehdgdgfgogfhdAedKkcAIemgpgbgeehffejAgdKkcAFefhggbgmAikKkcAPfdgfheedhfhdhegpgneogbgngfhdAleKkcASfcgfgngphggfedhfhdhegpgneogbgngfhdAicLkcAPfdgfheedgigbhcfehcgjghghgfhcAfcLkcASfcgfgngphggfedgigbhcfehcgjghghgfhcAboMkcAOfdgfheelgfhjfehcgjghghgfhcAooLkcARfcgfgngphggfelgfhjfehcgjghghgfhcAngMkcAUfdgfheengphfhdgfeegphhgofehcgjghghgfhcAjmMkcAXfcgfgngphggfengphfhdgfeegphhgofehcgjghghgfhcAepNkcAVfdgfhefdgfhehegmgfhcengphegjhggbhegjgpgoAmhNkcAWehgfhefdgfhehegmgfhcengbhifhgphcglhegjgngfADOkcAPfcgfgmgpgbgeefgohegjhegjgfhdAefOkcASehgfhefhgjgeghgfhefagphdgjhegjgpgoAgkOkcAOehgfhefhgjgeghgfhefdgjhkgfAnnOkcARedhcgfgbhegffahcgpgkgfgdhegjgmgfAohPkcAOejhdfggbgmgjgeefgggggfgdheAhmSkcAbpfdgfheehgmgpgcgbgmfahcgpgkgfgdhegjgmgfeigjheedgbgmgmgcgbgdglAlcSkcAccfcgfgngphggfehgmgpgcgbgmfahcgpgkgfgdhegjgmgfeigjheedgbgmgmgcgbgdglAnhTkcAbjfdgfheefgggggfgdheedhcgfgbhegfgeedgbgmgmgcgbgdglAQUkcAbmfcgfgngphggfefgggggfgdheedhcgfgbhegfgeedgbgmgmgcgbgdglAVQkcANehgfheefgggggfgdheengfgnAieUkcAPehgfhefegfhchcgbgjgoejgogggpAgkWkcANehgfheefgohegjhehjengfgnAjcWkcAKehgfhefcgbhhengfgnAddYkcALfcgfebgmgmgpgdengfgnAfpYkcAIeghcgfgfengfgnAclYkcAOfdgfhefahcgfgdgjhdgfegfaffAhhYkcATehgfheedhfhchcgfgohefegihcgfgbgeejeeAkjbjkcAPefgohegjhehjejhegfhcgbhegphcAjebkkcAXefgohegjhehjejhegfhcgbhegphcfegbgcgmgfgjhkgfAkmbokcATebgegeechfgjgmgegjgoghffhaghhcgbgegfAedcbkcATfdgfheeogfheefhggfgohefehcgjghghgfhcAhlcbkcAWfcgfgngphggfeogfheefhggfgohefehcgjghghgfhcAbncckcAOehgfheeggpgoheedgpgogggjghAeicckcAOfdgfheeggpgoheedgpgogggjghAhjcckcAHecgjheebgogeAkacckcAGecgjheephcAmhcckcAHecgjhefigphcAoocckcAHecgjheeogpheALcdkcAIecgjheebfdgifcAdccdkcAHecgjhefdgifcAfjcdkcAHecgjhefdgiemAiacdkcAHecgjhefcgpfcAkhcdkcAHecgjhefcgpemAmocdkcASehgfheebgogjgnejgeeghcgpgneogbgngfApbcdkcAQfegfgmgfhagphchefdgfhehegmgfhcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAinimceMppppppilgbMidmeMgakapenpkbAiemahfSppVieShgAkdpanpkbAmgFpenpkbABilbnjmdkifAgiIAkcAgieoAkcAoigjAAAoihebpAAgiIAkcAfdoiiglilhppgiopnippppfdppViaShgAgiPAkcAfdoigplilhppgiXAkcAfdoigelilhppgkpnfdppVfeShgAgkpofdppVlaShgAidmeYlibpkkeaAmgAojmheaBelhkgbAlihgkkeaAmgAojmheaBMhkgbAgbmcEAfgfhilheceMilhmceQgkAppdgidmgFfgPlgegppBmgfhfdoibmkmlhppiddoAhfogfpfomcIAppheceEfdppVcaShgAidmeImcEAkbVFkcAifmahecckdkeUhgAmhFVFkcAAAAAmhFjoggejAilpaifpgggmhFkcggejAhehgdbmamdiddnVFkcAAhfchkbkeUhgAkdVFkcAmhFkeUhgAcbHkcAlijoggejAmgAojeamhAoijpfiAmgeaEjadbmamdijmgifpgPifPgakhppilheceIgaibomcmBAAijofilNiipaiiAilBffinfnEfdfgppfaUifmahefofgoipgldjoppflfapphfApphfEgiAnghgAgiABAAinhfIfgoioahflcppidmeYgkAfgkbMjpifApphaMppViiUhgAijmgifpghebmpphfEgkCfgppVUVhgAibmecmBAAijheceEgbojjgfpkhppfaoinioclcppfiibmecmBAAgbojpjfpkhppgkCppheceIppVcaVhgAifmaheHfaoilfoclcppfippcfVFkcAloppAAAfgfgfgfgidomQnjoinjfmceMnjoinjfmceInjoonjfmceEnjoonjbmcegkBfdppVmmShgAidmeIfagkcioiMdklkppfjijmboiplkbldppfafdppVmaShgAidmeIijnodbmaeamdidomIijofgkBfdppVnaShgAidmeIijmbffidmfEffoikhkcldppnjefpmnjefAoihnGAAoihiGAAidmeIliCAAAmdidomQijofgkCfdppVcaShgAgkDfdppVcaShgAgkEfdppVcaShgAgkFfdppVcaShgAnjfnMnjfnInjfnEnjfnAffgkAgkBfdppVnaShgAidmeIfaoienghldppijmboifcgjldppidmedadbmamdidomQijofgkCfdppVcaShgAppeeceEidhmceEJhfopidmeInlfnMnlfnInlfnEnlfnAgkAgkAffgkAfanjbmcefanjbmcegkAfanlbmcegkBfdppVmmShgAidmeIfaoipbggldppijmboihagpldppidmeQdbmamdgipanippppfdppVdeShgAkdbjFkcAidmeIlihlWfeAmgAojeamhAfhpcenAdbmamdkbbjFkcAifmahecofagipanippppfdppVdmShgAidmeMmhFhlWfeAffilomfgmhFhpWfeAfhilhnMmhFbjFkcAAAAAdbmamdffijoffgfhgailbnjmdkifAppdfbjFkcAgipanippppfdppVdiShgAilefMnleaeeoiddFAAdbmadiifHCAAPjfmafafdppVkiShgAilefInjeaEnjAoiTFAAoiOFAAgkAgkAgkEfdppVmiShgAgkAfdppVlaShgAidmecmgbojdmNlcppgkBfdppVmmShgAidmeIfagieaAkcAoiNhjlcppidmeIdbmamdgailfmceceibomABAAijofgkBfdoidglelhppifmahfdnilNgaopieAidhjcmQhcFilejYolDidmbYfbgiiijphhAgieeAkcAffoihccdlkppidmeQffinkniaAAAffilNiipaiiAilRppfcdaijoigkBfailNiipaiiAilRppfcYibmeABAAgbdbmamdgailfmceceildfiipaiiAilegIilAileaMgifidahgAfaoipdcglkppidmeIifmaheHijpbilRppfccigbdbmamdgaildfiipaiiAilegIilAileaMfafdoiIlelhppgbliBAAAmdgkBfdppVmmShgAidmeIifmaheDfaolFgipmjphhAkbemdekaAilIilBppfaMdbmamdgagkAgkBfdppVmmShgAidmeIfaoihefjldppijmboiFfkldppgbdbmamdgkAgkBfdppVmmShgAidmeIfafaoiciTlkppijeeceEfdppVkeShgAidmeQdbmaeamdliRpjfdAmgAojmheaBnhReoAmgeaonolgipanippppfdppVdeShgAkdbnFkcAidmeIdbmamdkbbnFkcAifmahecnfagipanippppfdppVdmShgAidmeMliRpjfdAmgAoimheaBGpfpoppmgeaonhemhFbnFkcAAAAAdbmamdiliamiAAAifmaheelfhijmhilbnjmdkifAgkAfdppVlaShgAppdfbnFkcAgipanippppfdppVdiShgAfhfdppVfmShgAgkpofdppVliShgAgkppfdppVmmShgAidmecmfpllAAAAdjnihfKoiiioelappojnbonlbppfjojmlonlbppkbcbFkcAifmahecefagipanippppfdppVdmShgAidmeMmhFenhfeaApihaUAmhFcbFkcAAAAAdbmamdgipanippppfdppVdeShgAkdcbFkcAidmeIlienhfeaAmhAfdjggbAdbmamdgailbnjmdkifAppdfcbFkcAgipanippppfdppVdiShgAnleeceMnnfmcepiidomIfdppVmeShgAgkAgkAgkBfdppVmiShgAgkAfdppVlaShgAidmedagbojflnklcppkbcfFkcAifmahecefagipanippppfdppVdmShgAidmeMmhFhohfeaAknhcUAmhFcfFkcAAAAAdbmamdgipanippppfdppVdeShgAkdcfFkcAidmeIlihohfeaAmhAlojggbAdbmamdgaijmpilbnjmdkifAppdfcfFkcAgipanippppfdppVdiShgAnleeceMnnfmcepiidomIfdppVmeShgAijpilbCpgpbiioafafdppVkiShgAgkAgkAgkCfdppVmiShgAgkAfdppVlaShgAidmedigbojjdnllcppkbcjFkcAifmahecofagipanippppfdppVdmShgAidmeMmhFiokfffAmhegECmhFjckfffAAAAolmhFcjFkcAAAAAdbmamdgipanippppfdppVdeShgAkdcjFkcAidmeIliiokfffAmgAojeamhAgjghemAdbmamdmhegECAAAgailbnjmdkifAppdfcjFkcAgipanippppfdppVdiShgAilefQnleaQnnfmcepiidomIfdppVmeShgAgkAgkAgkBfdppVmiShgAgkAfdppVlaShgAidmedagbojegjildppgagkBfdoicjlalhppfaoifgYlgppifmahecoiniileAAAllHdaBAfdfdijodfdidmdEfdoimddclgppilhjQilhpEgkCfgppVcaShgAnjfpYidmeQgbdbmamdileeceEfdfbfcilfjhmilijiaAAAdjnjhoUilTidpkAheIdjChfEijnaolKidmdEoloiliAAAAfkfjflmcEAgagkBfdoilbkplhppfaoinoXlgppifmahecfijmbgidaclhhAoikoppppppifmaheVijmboihfnkkkppfafdoipdkplhppgbliBAAAmdgbdbmamdkbgaopieAiliafiCAAileaMfaoiiaimljppdbmamdgkBfdoipajpldppfaoielhgldppijmboidhhlldppidmeImdnnfmcepiidomIfdppVmeShgAidmeMmdgailfmceceoimlppppppifmahedmnjeaYnjeaUoinfppppppoinappppppgbliCAAAmdgailfmceceoikgppppppifmaheXnjeacanjeabmoilappppppoiklppppppgbliCAAAmdgbdbmamdideaBYggmheaFolEmdlikhXfgAiahiFolhecdoiofppppppidmaRoinnppppppidmaRoinfppppppidmaRoimnppppppggmheaLifpgmdfpfpgfgggggfgdhegdgchdAAAAAgamhFdjFkcABAAAilfmceceidomeiijofdbmaljeiAAAiieeNppejhfpjmhefAjieghhAgkBfdoihdkolhppijefEgkCfgppVcaShgAidmeInjffYnjfnQgkDfgppVcaShgAidmeInjffbmnjfnUgkEfgppVcaShgAnjfncaidmeIgkFfgppVcaShgAnjfnceidmeIgkGfdoicgkolhppijefdegkHfgppVcaShgAnjfndiidmeIgkIfdoiMkolhppijefdagkJfdoiBkolhppijefcmffilNkmfnijAilBppfafmfagimnOkcAfdoiickolhppgiopnippppfdppViaShgAidmeIfifafafdoidikolhppgkKfdppVhmShgAidmeIgkpnfdppVfeShgAidmeIfifafdoiYkolhppidmeeimhFdjFkcAAAAAgbliBAAAmdgailfmcecegkBfdoiinknlhppfailNeeibijAoilnjkknppPlgmafafdppVkiShgAidmeIgbliBAAAmdgailfmcecegkBfdoifpknlhppfailNeeibijAoilfjkknppifmahfEgbdbmamdfaoihaGAAgbliBAAAmdfbgimnOkcAfdoimoknlhppgiopnippppfdppViaShgAidmeIfjfbfbfdoiieknlhppgkpofdppViaShgAidmeIfjfbfbfdoigpknlhppfdppVhaShgAidmeEgkpmfdppVfeShgAidmeIgkppfdppVleShgAidmeIidpiAhebjfjfbfbfdoidpknlhppgkAgkAgkBfdppVmiShgAidmeQfjmdgailbnjmdkifAfbilEceileifmoihcppppppkbcnFkcAidpiAPiekmAAAppdfcnFkcAgipanippppfdppVdiShgAidmeMilEcepphafafdoiolkmlhppilEcenjiaiiAAAoicfpnppppilEcenjiaimAAAoiXpnppppilEcenjiajiAAAoiJpnppppilEcenjiajmAAAoiplpmppppilEcepplalmAAAfdoikekmlhppilEcepplamaAAAfdoijfkmlhppilEcepplameAAAfdoiigkmlhppgkppfdoihokmlhppilEcepphafmfdoihckmlhppgkAgkAgkKfdppVmiShgAidmeUolBfigbgidgTfbAmdgailbnjmdkifAfbilEceileifmoijnpoppppkbcnFkcAidpiAPieklAAAppdfcnFkcAgipanippppfdppVdiShgAidmeMilEcepphafafdoiWkmlhppilEcenjiaiiAAAoifapmppppilEcenjiaimAAAoiecpmppppilEcenjiajiAAAoidepmppppilEcenjiajmAAAoicgpmppppilEcepplalmAAAfdoimpkllhppgkAfdoimhkllhppilEcepplamiAAAfdoilikllhppilEcenjiammAAAoipcplppppilEcepphafmfdoijokllhppgkAgkAgkKfdppVmiShgAidmeUolBfigbgihgpeepAmdmhFeiiohhAloQkcAmhFlehghhAjdRkcAmdgaoidaAAAgipanippppfdppVdeShgAkdcnFkcAidmeIgbliAAAAmdmhFeiiohhAdgTfbAmhFlehghhAhgpeepAmdgakbcnFkcAifmahebkfagipanippppfdppVdmShgAidmeMmhFcnFkcAAAAAgbliAAAAmdfdfbilbnjmdkifAgkOfdppViiShgAidmeIppdfdbFkcAgipanippppfdppVdiShgAidmeMileeceMpphaEfdoinikklhppileeceMpphaMfdoimlkklhppileeceMfdnjeaYoiGplppppidmeEileeceMfdnjeabmoipgpkppppidmeEileeceMfdnjeacaoiogpkppppidmeEileeceMfdnjeaceoingpkppppidmeEileeceMpphacmfdoihokklhppileeceMpphadafdoihbkklhppileeceMpphadefdoigekklhppileeceMfdnjeadioijppkppppidmeEileeceMppdafdoieikklhppfjppheceIppVdfFkcAfafafdoidfkklhppppdfdjFkcAfdoicjkklhppgkAgkAgkNfdppVmiShgAidmeQfiflmcEAgaoiddAAAgipanippppfdppVdeShgAkddbFkcAidmeIilNkmfnijAilBileifmijNdfFkcAmheafmnnSkcAgbliAAAAmdgakbdbFkcAifmaheclfagipanippppfdppVdmShgAidmeMmhFdbFkcAAAAAilNkmfnijAilBilNdfFkcAijeifmgbliAAAAmdkbkmfnijAilhacegkBfdoidnkjlhppnjfnAgkCfdoidckjlhppnjfnEinenIffoikoehlgpppphfMpphfIileoEoinbiikcppifmamdgailfmceceidomQijofoiljppppppPiejmAAAileobmilefMeaPkpebbmDefIilfbIineeecCPlhAfafdoiddkjlhppkbomibifAileaYileiEilefMPkpFheilijADefIPlgEBfafdoiQkjlhpppphfMpphfIoihlfplfppfafdoipokilhppfgkbkmfnijAileaceilhacaljEAAAilefIjjphpjfailefMjjphpjijmcecPkpfgcmfiBmcglncEileoIidmbEBnbPlgBfafdoimbkilhppfoidmeQgbliEAAAmdidmeQgbdbmamdhddfgmhfgbdfAgmhfgbfphdgfhegngfhegbhegbgcgmgfAgmhfgbfpgogfhhhfhdgfhcgegbhegbAgmhfgbemfpgfhchcgphcAgidmVkcAppVniQhgAgigeVkcAfagifeVkcAfagiedVkcAfappVniRhgAkdAnlkbAppVniRhgAkdEnlkbAppVniRhgAkdInlkbAmdklXkcAHehgfheejgoheAjbXkcAJehgfheeggmgpgbheAmgXkcAIehgfheechjhegfAheXkcAHfdgfheejgoheAfhXkcAJfdgfheeggmgpgbheAomXkcAIfdgfheechjhegfAQYkcAKehgfhefdhehcgjgoghALXkcADgdhcAdbXkcAHepgggghdgfheAAAAAfpfpgngfgnAhfhdgfcadkAgicdWkcAgikoVkcAoilcopppppgicdWkcAfdoinekhlhppgiopnippppfdppViaShgAgipanippppfdppVdeShgAkddnFkcAidmeQmdgailfmcecegkBfdoiKkhlhppfaoidhPlgppifmahfEgbdbmamdfaoicbAAAgbliBAAAmdgailfmcecegkBfdoiockglhppfaoiHAAAgbliBAAAmdilheceEgkIfdppVEnlkbAinfaEijQijdcolPilheceEgkEfdppVEnlkbAijdappdfdnFkcAgipanippppfdppVdiShgAgkpofdppVAnlkbAidmebmmcEAgkBfdoimfkglhppifmaheBmdgicjWkcAfdppVInlkbAgailfmceceoinnppppppildaildggkCfdoigakglhppinEigfaoijippppppgbliBAAAmdgailfmceceoilhppppppildaildggkCfdoidkkglhppinEigfaoifmppppppgbliBAAAmdgailfmceceoijbppppppildagkCfdoicokglhppnjbogbliAAAAmdgailfmceceoiheppppppildagkCfdoipjkflhppijGgbliAAAAmdgailfmceceoifhppppppilAnjAoiippgppppgbliBAAAmdgailfmceceoidnppppppilAppdafdoicmkglhppgbliBAAAmdgailfmceceoiccppppppildagkCfdoikhkflhppPlgEdafafdoiGkglhppgbliBAAAmdgailfmceceoipmpoppppildagkCfdoiibkflhppBmggkDfdoihhkflhppiiGgbdbmamdgailfmceceoinipoppppilAppdafdoipjkflhppgbliBAAAmdoicbgmlkppdbmamdgailfmcecegkCfdoiebkflhppfagkBfdoidikflhppfaoieecjlkppfjfjfafdoijdkflhppgbliBAAAmdgailfmcecegkBfdoiVkflhppfaoillVlkppfjgbdbmamdgappVcaRhgAilfmcecefafdoigckflhppgbliBAAAmdndbkkcAJejgoedgjhcgdgmgfAblblkcAHejgofcgfgdheAhiblkcAJepggfagmgbhjgfhcAjpblkcAHepggfehjhagfAoablkcALepggedgbhegfghgphchjAHbmkcASepggffhaghhcgbgegfedgbhegfghgphchjAmgblkcALejhdechfgjgmgegjgoghAffbmkcAJejgofdgfgdhegphcAhmbmkcANeogpheepggfagmgbhjgfhcdaAlkbmkcAMepggebgohjfagmgbhjgfhcAdnbnkcAKepggebgohjfehjhagfAcobmkcARfahcgphggjgegfhdfcgfhdgphfhcgdgfAmabnkcAKejhdfdgfhehegmgfhcAGbokcANejhdeogphefdgpgmgegjgfhcAfnbokcAUejhdfdgfhehegmgfhcephcechfgjgmgegjgoghAAAAAfahcgfgegjgdgbhegfAgiipbjkcAgijaYkcAoieiomppppmdgafdppVlmShgAfjfappEceijmhinEifIAAAfafdppVEnlkbAijmgidmeImhGAAAAmheeloEAAAAifppheTfhfdppVhmShgAoinekdlhppijEloepolojgigmbkkcAfdppVfiShgAidmeMijheceYgbliBAAAmdfgfhffilheceQildnfihfijAilgpEidmhYincmopDdodjophnckilehEifmaheboinfgEilKifmjhebofcilRfappfcEiemaileecepmfkheFidmcEolofidmhIolncdbmaolGilehEileaIidopQcldnfihfijAijdofnfpfomcEAgagioonippppfdoiehkdlhppfaoiinppppppifmaheOfafdoigckdlhppgbliBAAAmdgbdbmamdgaoiPppppppijmolpBAAAfdppVgiShgAidmeEfgoifkppppppifmaheXfafdoicpkdlhppfhgkpofdppVgeShgAidmeMeholnpgbliBAAAmdgagkBoidoolppppgkCoidholppppgkDoidaolppppidomMijofnjfnAnjfnInjfnEgkQfdppVEnlkbAijmbidmeIpphfAinefEfaoiijielfppidmeMgbliBAAAmdgagkBoipgokppppgkDoiopokppppgkCoioiokppppgkEoiobokppppidomQijofnlpbhcCnjmjnjfnEnjfnMnlpbhcCnjmjnjfnAnjfnIgkUfdppVEnlkbAijmbidmeIffidEceIffoiikidlfppidmeQgbliBAAAmdgagkIfdppVEnlkbAijmgidmeImhGAljhhAgkBfdoiomkblhppijegEgbliBAAAmdgagkIfdppVEnlkbAijmgidmeImhGkagmhgAgkBfdoimfkblhppijegEgbliBAAAmdgagkEfdppVEnlkbAidmeImhAgmEhhAgbliBAAAmdgagkIfdppVEnlkbAijmgidmeImhGieeohhAgkBfdoiiekblhppijegEgbliBAAAmdgagkIfdppVEnlkbAijmgidmeImhGgehjhhAgkBfdoifnkblhppijegEgbliBAAAmdgagkIfdppVEnlkbAijmgidmeImhGeepphgAgkBfdoidgkblhppijegEgbliBAAAmdgagkIfdppVEnlkbAijmgidmeImhGceclhhAgkBfdoiPkblhppijegEgbliBAAAmdgagkIfdppVEnlkbAijmgidmeIijdgmhegEjlbmkcAgbliBAAAmdgailfmceceilelYidpjAhfJgbliAAAAmcEAgbliBAAAmcEAgafdppVlmShgAflijmbfbglmaEidmaMfafdppVEnlkbAijmgidmeIfjijdgmhegEKbnkcAijeoIlkAAAAdjmkheUidmcBfcfbfcfdoiigkalhppfjfkijeejgIoloigbliBAAAmdgailfmceceilflYliAAAAilfbIdjmcheNilfeibMdjndheOidmaBolomgbliAAAAmcEAgbliBAAAmcEAgafdppVlmShgAflijmbfbglmaEidmaMfafdppVEnlkbAijmgidmeIfjijdgmhegEinbnkcAijeoIlkAAAAdjmkheUidmcBfcfbfcfdoiDkalhppfjfkijeejgIoloigbliBAAAmdgailfmceceilflQliAAAAilfbIdjmcheNilfeibMdjndheOidmaBolomgbliAAAAmcEAgbliBAAAmcEAgagkIfdppVEnlkbAijmgidmeIijdgmhegEnpbnkcAgbliBAAAmdgailfmcecefdoihiNkippifmahfMidmeEgbliAAAAmcEAidmeEgbliBAAAmcEAgagkIfdppVEnlkbAijmgidmeIijdgmhegEcfbokcAgbliBAAAmdgailfmcecefdoidcNkippifmahebnilidpmBAAifmaheHilflIdjniheMidmeEgbliAAAAmcEAidmeEgbliBAAAmcEAgagkIfdppVEnlkbAijmgidmeIijdgmhegEhmbokcAgbliBAAAmdgailfmcecefdoinlMkippifmahfVoikchfkcppifmahfMidmeEgbliAAAAmcEAidmeEgbliBAAAmcEAgagkCfdoimmjolhppfagkBfdoimdjolhppfaijmgilNkakdifAilejcigkBoiolhckippiliiYDAAijmpoigebokjppinepcafgfeoilkigkkppmhABAAAmheaEAAAAfigbdbmamdeobpkcADhihcAjnbpkcADgfdcAnmbpkcADgfhaAcecakcACgfAficakcAEgfhagmAjhcakcADgfgjAngcakcADgdhaAAAAAfpfpgfhggfgoheAgidgbpkcAgipkbokcAoikdogppppmdgailfmceceidomYijofmhefAbmGhhAmhefEbjQBAgkBfdoiTjolhppijefIgkCfdoiIjolhppijefMgkDoijgogppppnjfnQgkEoiimogppppnjfnUffoiobdnlappidmebmgbdbmamdgailfmceceidomQijofmhefAgannhgAgkBfdoimljnlhppijefEgkCfdoimajnlhppijefIgkDfdoilfjnlhppijefMffoikcdnlappidmeUgbdbmamdgailfmceceidomUijofmhefAfannhgAgkBfdoiimjnlhppijefEgkCfdoiibjnlhppijefIgkDoiPogppppnjfnMgkEoiFogppppnjfnQffoifkdnlappidmeYgbdbmamdgailfmceceidomMijofmhefAcigmhgAgkBfdoieejnlhppijefEgkCfdoidjjnlhppijefIffoicgdnlappidmeQgbdbmamdgailfmceceidomQijofmhefAdigmhgAgkBfdoiQjnlhppijefEgkCfdoiFjnlhppijefIgkDfdoipkjmlhppijefMffoiohdmlappidmeUgbdbmamdgailfmceceidomQijofmhefAeigmhgAgkBfdoinbjmlhppijefEgkCfdoimgjmlhppijefIgkDfdoilljmlhppijefMffoikidmlappidmeUgbdbmamdgailfmceceidomciijofmhefAomFhhAmhefEcpQBAgkBfdoiiljmlhppijefIgkCfdoiiajmlhppijefMgkDfdoihfjmlhppijefQgkEoiDofppppnjfnUilefUijefcagkFoipdoeppppnjfnYilefYijefcemhefbmAAAAffoidldmlappidmecmgbdbmamdgaoidcAAAgipanippppfdppVdeShgAkdebFkcAidmeIoimadelappileaciilIilBkdefFkcAmhBlmcbkcAgbliAAAAmdgaiddnebFkcAAhedaoijidelappileaciilIkbefFkcAijBppdfebFkcAgipanippppfdppVdmShgAidmeMmhFebFkcAAAAAgbliAAAAmdgailbnjmdkifAppdfebFkcAgipanippppfdppVdiShgAidmeMpphececioimlpeppppileececipphaEfdoipnjllhppgkAgkAgkCfdppVmiShgAidmeQgbppcfefFkcAgkBfdoihejllhppfaoijkhbldppijmboiknhfldppifmamdgailfmceceoinoppppppheemnjeaMnjeaInjeaEoipmolppppoipholppppoipcolppppgbliDAAAmdgailfmcecegkCfdoieejllhppgkDfdoidmjllhppgkEfdoidejllhppoijlppppppheJnjfiMnjfiInjfiEgbdbmamdgailfmcecegkCfdoipljklhppfagkBfdoipcjklhppfjcbmifafdoifcjllhppgbliBAAAmdgailfmcecegkCfdoinejklhppfagkBfdoimljklhppfjJmifafdoicljllhppgbliBAAAmdgailfmcecegkCfdoiknjklhppfagkBfdoikejklhppfjdbmifafdoiEjllhppgbliBAAAmdgailfmcecegkBfdoiigjklhppphnafafdoiohjklhppgbliBAAAmdgailfmcecegkCfdoigjjklhppfagkBfdoigajklhppfjndpifafdoimajklhppgbliBAAAmdgailfmcecegkCfdoiecjklhppfagkBfdoidjjklhppfjndoifafdoijjjklhppgbliBAAAmdgailfmcecegkCfdoibljklhppfagkBfdoiSjklhppfjndoafafdoihcjklhppgbliBAAAmdgailfmcecegkCfdoipejjlhppfagkBfdoioljjlhppfjndmifafdoieljklhppgbliBAAAmdgailfmcecegkCfdoimnjjlhppfagkBfdoimejjlhppfjndmafafdoicejklhppgbliBAAAmdgagkppfdoinfjjlhppilNdimikaAfaoillmnlcppfafdoiBjklhppgbliBAAAmdgailfmcecegkBfdoiidjjlhppfaoilaBlgppifmahegafaidomIgkCfdppVcaShgAidmeInjbmcegkDfdppVcaShgAidmeInjfmceEilemceIinEcefaoieajilfppidmeMgkAgiBilenAfdppVfiShgAidmeMgkBfdppVgaShgAidmeIgkAgkAgkDfdppVmiShgAidmeQgbliAAAAmdinlokeCAAgailbnjmdkifAoiemAAAgbojjoifjopplimakchcAgailbnjmdkifAoidfAAAgbojnnifjopppbdbmamdgaoicfAAAgiIAkcAfdoigkjjlhppfdppVhaShgAgiopnippppfdppVfeShgAidmeMgbdbmamdoifiobppppoimgodppppoiniofppppoihbogppppoiIohppppoilbohppppoimconppppoiblopppppoikdonppppoihmpmppppmdoijjojppppoifnonppppoigapappppoiblpbppppoiiapeppppoicapkppppmd"

S5HookData = {}
local len = string.len(s5h)
local left = len
while left > 0 do
    local chunk = left > 10000 and 10000 or left
    table.insert(S5HookData, string.sub(s5h, len - left + 1, len - left + chunk))
    left = left - chunk
end