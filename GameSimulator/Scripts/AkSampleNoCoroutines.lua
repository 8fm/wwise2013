
-- *********
-- Script
-- *********
function RunScript()
    print( string.format( "Input frames per second: %s", kFramerate ) )
    if( AK_LUA_RELEASE ) then
        print( "Not using communication" )
    else
        print( "Using communication" )
    end

    AkInitSE()
    AkRegisterPlugIns()
	
    if( not AK_LUA_RELEASE ) then
        AkInitComm()
        if( kConnectToWwise ) then
            print( string.format( "You have %s ms to connect to Wwise.", kTimeToConnect ) )
            AkRunGameLoopForPeriod( kTimeToConnect )
        end
    end
	
	langSpecific = "English(US)"
	-- Set the project's base and language-specific paths:
    if AK_PLATFORM_PC or AK_PLATFORM_MAC then
		local demoPath = "/SDK/samples/IntegrationDemo/WwiseProject/GeneratedSoundBanks/" .. AK_PLATFORM_NAME .. "/"		
		--Remove the script from the path, and go back 2 folders in the hierarchy (skipping GameSimulator\Windows)
		basePath = AkPathRemoveLastToken(AkPathRemoveLastToken(AkPathRemoveLastToken(LUA_SCRIPT)))	
		basePath = basePath .. demoPath		
    elseif( AK_PLATFORM_XBOX360 ) then
        basePath = "game:\\"
    elseif( AK_PLATFORM_PS3 ) then
        basePath = "/dev_hdd0/game/AKGS00000/USRDIR/akgamesim/"
	elseif( AK_PLATFORM_WII ) then
		basePath = "/"
   elseif( AK_PLATFORM_IOS ) then
		basePath = g_basepath 
		if ( os.getenv("GAMESIMULATOR_FLAT_HIERARCHY") == nil) then
			langSpecific = "English(US)"
		else -- When using iTunes file sharing you can't create folder hierachy
			langSpecific = ""
		end
    end
	
	result = g_lowLevelIO["Default"]:SetBasePath( basePath ) -- g_lowLevelIO is defined by audiokinetic\AkLuaFramework.lua
	assert( result == AK_Success, "Base path set error" )	
	result = AK.StreamMgr.SetCurrentLanguage( langSpecific ) 
	assert( result == AK_Success, "Current language set error" )
	
	-- Load banks:
	initBankID = 0
	carBankID = 0
	markerBankID = 0
	humanBankID = 0
    result, initBankID = AK.SoundEngine.LoadBank( "Init.bnk", AK_DEFAULT_POOL_ID, initBankID )
    assert( result == AK_Success, "Error loading bank Init.bnk" )
    result, carBankID = AK.SoundEngine.LoadBank( "Car.bnk", AK_DEFAULT_POOL_ID, carBankID )
    assert( result == AK_Success, "Error loading bank Car.bnk" )
	
	-- Register a game object and post an event:
    result = AK.SoundEngine.RegisterGameObj( 3, "LuaGameObject" )
    assert( result == AK_Success, "Register game object error" )
    result = AK.SoundEngine.SetActiveListeners( 3, 0x1 )
    assert( result == AK_Success, "Set active listeners error" )
    engineID = AK.SoundEngine.PostEvent( "Play_Engine", 3 )
    assert( engineID ~= AK_INVALID_PLAYING_ID, "Post event error" )
	
	print( "" )
	print( "" )
	print( "You should now hear an engine sound (event Play_Engine in the IntegrationDemo project)." )
	print( "" )
	print( "" )

    AkGameLoop() -- actual game loop
	AkStop()
end

-- ****************
-- Executed commands
-- ****************
RunScript()