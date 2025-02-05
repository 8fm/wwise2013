
g_MyGameObjectID = 3

--[[ ********************************
The g_coroutineHandle handle uses CoroutineModule(), which executes two functions in sequence
******************************** ]]
function CoroutineModule()
	-- add the functions to be executed to this table:
	g_functionTable = { Coroutine1, Coroutine2, Coroutine3 }
	
    for key,value in pairs( g_functionTable ) do
		currentTest = value
		value()
    end
end

function SpeechEventCallBackFunction( in_callbackType, in_data )
	-- See AkPostEventCallBackFunction() in audiokinetic/AkLuaFramework.lua for more details
	
	if ( in_callbackType == AK_Marker ) then
		strCueArray = {
			"In this tutorial...                               ",
			"...we will look at creating...                    ",
			"...actor-mixers...                                ",
			"...and control buses.                             ",
			"We will also look at the...                       ",
			"...actor-mixer and master-mixer structures...     ",
			"...and how to manage these structures efficiently."
		}
		
		if ( in_data.uIdentifier > 0 and in_data.uIdentifier <= 7 ) then
			if ( in_data.uIdentifier == 1 ) then
				print( "" )
				print( "+-------------- Start of Markers Test ---------------+" )
			end
			print( "| " .. strCueArray[in_data.uIdentifier] .. " |" )
		end
	elseif ( in_callbackType == AK_EndOfEvent ) then
		print( "+--------------- End of Markers Test ----------------+" )
		print( "" )
	end
end

-- *********
-- This function will post an event that will trigger Lua callbacks
-- *********
function Coroutine1()
    markersID = AK.SoundEngine.PostEvent( "Play_Markers_Test", g_MyGameObjectID, AK_EndOfEvent+AK_Marker, "SpeechEventCallBackFunction", 0 )
    assert( markersID ~= AK_INVALID_PLAYING_ID, "Post event error" )
end

-- *********
-- This function will post 100 steps spaced by pseudo-random ms values
-- *********
function Coroutine2()
	nNumberOfSteps = 0

	print( "Setting the Surface switch to Gravel" )
    result = AK.SoundEngine.SetSwitch( "Surface", "Gravel", g_MyGameObjectID )
    assert( result == AK_Success, "Set switch error" )
	bankID = 0
    result, bankID = AK.SoundEngine.LoadBank( "Gravel.bnk", AK_DEFAULT_POOL_ID, bankID )
    assert( result == AK_Success, "Error loading bank Gravel.bnk" )

	print( "Starting to walk..." )

	while( nNumberOfSteps < 66 ) do
		stepsID = AK.SoundEngine.PostEvent( "Play_Footsteps", g_MyGameObjectID )
		assert( stepsID ~= AK_INVALID_PLAYING_ID, "Post event error" )
		nNumberOfSteps = nNumberOfSteps + 1
		
		if( nNumberOfSteps == 22 ) then
			print( "Setting the Surface switch to Dirt" )
			result = AK.SoundEngine.SetSwitch( "Surface", "Dirt", g_MyGameObjectID )
		    assert( result == AK_Success, "Set switch error" )
			result, bankID = AK.SoundEngine.LoadBank( "Dirt.bnk", AK_DEFAULT_POOL_ID, bankID )
			assert( result == AK_Success, "Error loading bank Dirt.bnk" )
		elseif( nNumberOfSteps == 23 ) then	
			AkUnloadBank( "Gravel.bnk" )
		elseif( nNumberOfSteps == 44 ) then
			print( "Setting the Surface switch to Metal" )
		    result = AK.SoundEngine.SetSwitch( "Surface", "Metal", g_MyGameObjectID )
			assert( result == AK_Success, "Set switch error" )
			result, bankID = AK.SoundEngine.LoadBank( "Metal.bnk", AK_DEFAULT_POOL_ID, bankID )
			assert( result == AK_Success, "Error loading bank Metal.bnk" )
		elseif( nNumberOfSteps == 45 ) then
			AkUnloadBank( "Dirt.bnk" )
		end
		
		os.sleep( math.random( 400 ) ) -- sleep up to 400 ms
		coroutine.yield() -- Need to yield so that audio is rendered in the game loop
	end
	print( "Stopped walking!" )
end

-- *********
-- This function will modify an RTPC value based on user input
-- *********
function Coroutine3()
	print( "Use the keyboard left-right arrows/analog sticks to modify the 'RPM' RTPC's value" )
	print( "You have 10 secs" )
	
	initial_time = os.gettickcount()
	while( os.gettickcount() - initial_time < 10000 ) do
		local fIncrement = 0
	    if( AK_PLATFORM_PC or AK_PLATFORM_MAC) then
	        if( AkIsButtonPressedThisFrame( VK_LEFT ) ) then
				fIncrement = -50
			end
			if( AkIsButtonPressedThisFrame( VK_RIGHT ) ) then
				fIncrement = 50
			end
	    end
		if( not (AK_PLATFORM_PC or AK_PLATFORM_MAC)) then
			fIncrement = AkLuaGameEngine.GetAnalogStickPosition( AK_GAMEPAD_ANALOG_01 ) * 50
	    end
		
		RPM_RTPC_VALUE = RPM_RTPC_VALUE + fIncrement
		if( RPM_RTPC_VALUE < 1000 ) then
			RPM_RTPC_VALUE = 1000
		end
		if( RPM_RTPC_VALUE > 10000 ) then
			RPM_RTPC_VALUE = 10000
		end
		
		result = AK.SoundEngine.SetRTPCValue( "RPM", RPM_RTPC_VALUE )
		assert( result == AK_Success, "Set RTPC error" )
		
		coroutine.yield() -- Need to yield so that audio is rendered in the game loop
	end
	print( string.format( "Final RPM value: %f", RPM_RTPC_VALUE ) )
end

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
	
	-- Set the project's base and language-specific paths:
	langSpecific = "English(US)"
    if AK_PLATFORM_PC or AK_PLATFORM_MAC then
		local demoPath = "/SDK/samples/IntegrationDemo/WwiseProject/GeneratedSoundBanks/" .. AK_PLATFORM_NAME .. "/"		
		basePath =  LUA_EXECUTABLE_DIR .. "/../../"
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
		else -- When using iTunes file sharing you can create folder hierachy
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
    result, markerBankID = AK.SoundEngine.LoadBank( "MarkerTest.bnk", AK_DEFAULT_POOL_ID, markerBankID )
    assert( result == AK_Success, "Error loading bank MarkerTest.bnk" )
    result, humanBankID = AK.SoundEngine.LoadBank( "Human.bnk", AK_DEFAULT_POOL_ID, humanBankID )
    assert( result == AK_Success, "Error loading bank Human.bnk" )
	
	RPM_RTPC_VALUE = 1000
    result = AK.SoundEngine.SetRTPCValue( "RPM", RPM_RTPC_VALUE )
    assert( result == AK_Success, "Set RTPC error" )
	
	-- Register a game object and post an event:
    result = AK.SoundEngine.RegisterGameObj( g_MyGameObjectID, "LuaGameObject" )
    assert( result == AK_Success, "Register game object error" )
    result = AK.SoundEngine.SetActiveListeners( g_MyGameObjectID, 0x1 )
    assert( result == AK_Success, "Set active listeners error" )
	print( "Starting engine sound" )
    event1PlayingID = AK.SoundEngine.PostEvent( "Play_Engine", g_MyGameObjectID )
    assert( event1PlayingID ~= AK_INVALID_PLAYING_ID, "Post event error" )
	
    AkGameLoop()
	AkStop()
end

-- ****************
-- Executed commands
-- ****************
--[[ ********************************
In order to plug coroutines in the AkGameLoop, your script must define the g_coroutineHandle coroutine handle.
******************************** ]]
g_coroutineHandle = coroutine.create( CoroutineModule )
RunScript()