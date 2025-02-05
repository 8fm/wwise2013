-- Global variables
g_bCarIsRunning = false
g_bEffectState = true
g_materialIndex = 1
g_materialTable = {"Gravel","Metal","Dirt"}

function IntegrationDemoGameLoop()
	fDeltaFramesMs = 1/kFramerate * 1000 -- approximate time between frames, in ms
    if( AK_PLATFORM_PC or AK_PLATFORM_MAC ) then
	    print("\t\tPress escape to quit the game loop")
    else
	    print("\t\tPress Start to quit the game loop")
    end
	
    while( not AkEscapeLoopCondition() ) do
		HandleInput()
		AK.SoundEngine.RenderAudio()
		AkLuaGameEngine.Render()
        AkLuaGameEngine.ExecuteBankCallbacks()
        AkLuaGameEngine.ExecuteEventCallbacks()
		AkButtonCleanUp()
		os.sleep( fDeltaFramesMs )
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

function HandleInput()
    if( AK_PLATFORM_PC or AK_PLATFORM_MAC ) then
		buttonToggleEngine = 'p'
		buttonPlayHello = 'h'
		buttonPlayMarkersTest = 'k'
		buttonPlayFootstep = 'f'
		buttonSwitchMaterial = 'm'
		buttonStateNormal = 'n'
		buttonStateBlasted = 't'
		buttonStopAll = VK_RETURN
		
		buttonIncreaseRPM = VK_SPACE
		buttonBypassEffect = 'b'
	elseif ( AK_PLATFORM_WII ) then
		buttonToggleEngine = AK_GAMEPAD_BUTTON_01
		buttonPlayHello = AK_GAMEPAD_BUTTON_03
		buttonPlayMarkersTest = AK_GAMEPAD_BUTTON_04
		buttonPlayFootstep = AK_GAMEPAD_BUTTON_06
		buttonSwitchMaterial = AK_GAMEPAD_BUTTON_14
		buttonStateNormal = AK_GAMEPAD_BUTTON_07
		buttonStateBlasted = AK_GAMEPAD_BUTTON_10
		buttonStopAll = AK_GAMEPAD_BUTTON_02
		
		buttonIncreaseRPM = AK_GAMEPAD_BUTTON_11
		buttonBypassEffect = AK_GAMEPAD_BUTTON_05
	else
		buttonToggleEngine = AK_GAMEPAD_BUTTON_01
		buttonPlayHello = AK_GAMEPAD_BUTTON_03
		buttonPlayMarkersTest = AK_GAMEPAD_BUTTON_04
		buttonPlayFootstep = AK_GAMEPAD_BUTTON_02
		buttonSwitchMaterial = AK_GAMEPAD_BUTTON_12
		buttonStateNormal = AK_GAMEPAD_BUTTON_11
		buttonStateBlasted = AK_GAMEPAD_BUTTON_13
		buttonStopAll = AK_GAMEPAD_BUTTON_09
		
		analogControlRPM = AK_GAMEPAD_ANALOG_04		
		buttonBypassEffect = AK_GAMEPAD_BUTTON_14
    end
	
	if( AkIsButtonPressedThisFrame( buttonToggleEngine ) ) then
		g_bCarIsRunning = not g_bCarIsRunning
		if(g_bCarIsRunning) then
			local enginePlayingID = AK.SoundEngine.PostEvent( "Play_Engine", MAIN_GAME_OBJECT )
			assert( enginePlayingID ~= AK_INVALID_PLAYING_ID, "Post event error" )
		else
			local stopEnginePlayingID = AK.SoundEngine.PostEvent( "Stop_Engine", MAIN_GAME_OBJECT )
			assert( stopEnginePlayingID ~= AK_INVALID_PLAYING_ID, "Post event error" )
		end
	elseif( AkIsButtonPressedThisFrame( buttonPlayHello ) ) then
		local helloPlayingID = AK.SoundEngine.PostEvent( "Play_Hello", MAIN_GAME_OBJECT )
		assert( helloPlayingID ~= AK_INVALID_PLAYING_ID, "Post event error" )
	elseif( AkIsButtonPressedThisFrame( buttonPlayMarkersTest ) ) then
		local markersPlayingID = AK.SoundEngine.PostEvent( "Play_Markers_Test", MAIN_GAME_OBJECT, AK_EndOfEvent + AK_Marker + AK_EnableGetSourcePlayPosition, "SpeechEventCallBackFunction", 0 )
		assert( markersPlayingID ~= AK_INVALID_PLAYING_ID, "Post event error" )
	elseif( AkIsButtonPressedThisFrame( buttonPlayFootstep ) ) then
		local footstepPlayingID = AK.SoundEngine.PostEvent( "Play_Footsteps", MAIN_GAME_OBJECT )
		assert( footstepPlayingID ~= AK_INVALID_PLAYING_ID, "Post event error" )
	elseif( AkIsButtonPressedThisFrame( buttonSwitchMaterial ) ) then
		g_materialIndex = ((g_materialIndex + 1) % #g_materialTable) + 1
		local result = AK.SoundEngine.SetSwitch( "Surface", g_materialTable[g_materialIndex], MAIN_GAME_OBJECT )
		assert( result == AK_Success, "Set switch error" )
	elseif( AkIsButtonPressedThisFrame( buttonStateNormal ) ) then
		local result = AK.SoundEngine.SetState( "PlayerHealth", "Normal" )
		assert( result == AK_Success, "Set state error" )
	elseif( AkIsButtonPressedThisFrame( buttonStateBlasted ) ) then
		local result = AK.SoundEngine.SetState( "PlayerHealth", "Blasted" )
		assert( result == AK_Success, "Set state error" )
	elseif( AkIsButtonPressedThisFrame( buttonStopAll ) ) then		
		nRTPC_Effect = RTPC_EFFECT_MIN
		local result = AK.SoundEngine.SetRTPCValue( "Enable_Effect", nRTPC_Effect, AK_INVALID_GAME_OBJECT )
		assert( result == AK_Success, "Set RTPC error" )
		nRTPC_RPM = RTPC_RPM_MIN
		g_bCarIsRunning = false
		g_bEffectState = true
		result = AK.SoundEngine.SetRTPCValue( "RPM", nRTPC_RPM, MAIN_GAME_OBJECT )
		assert( result == AK_Success, "Set RTPC error" )
		local result = AK.SoundEngine.SetState( "PlayerHealth", "Normal" )
		assert( result == AK_Success, "Set state error" )
		AK.SoundEngine.StopAll()
		DisplayButtons()
	end
	
	if( AkLuaGameEngine.IsButtonPressed( buttonBypassEffect ) ) then
		nRTPC_Effect = RTPC_EFFECT_MIN
	else
		nRTPC_Effect = RTPC_EFFECT_MAX
	end
    local result = AK.SoundEngine.SetRTPCValue( "Enable_Effect", nRTPC_Effect, AK_INVALID_GAME_OBJECT )
    assert( result == AK_Success, "Set RTPC error" )
	
    if( AK_PLATFORM_PC or AK_PLATFORM_MAC or AK_PLATFORM_WII) then
		if( AkLuaGameEngine.IsButtonPressed( buttonIncreaseRPM ) ) then
			nRTPC_RPM = nRTPC_RPM + 200
		else			
			nRTPC_RPM = nRTPC_RPM - 200
		end
	else
		lastRPM = nRTPC_RPM;
		nRTPC_RPM = RTPC_RPM_MIN + ( AkLuaGameEngine.GetAnalogStickPosition( analogControlRPM ) * (RTPC_RPM_MAX - RTPC_RPM_MIN))
		rpmDiff = lastRPM - nRTPC_RPM
		if( rpmDiff > 0 ) then
			nRTPC_RPM = lastRPM - 200
		elseif( rpmDiff < 0 ) then
			nRTPC_RPM = lastRPM + 400
		end
		
	end	
	if( nRTPC_RPM < RTPC_RPM_MIN ) then
		nRTPC_RPM = RTPC_RPM_MIN
	elseif( nRTPC_RPM > RTPC_RPM_MAX ) then
		nRTPC_RPM = RTPC_RPM_MAX
	end
	result = AK.SoundEngine.SetRTPCValue( "RPM", nRTPC_RPM, MAIN_GAME_OBJECT )
	assert( result == AK_Success, "Set RTPC error" )
end

function DisplayButtons()
	print( "--------------------------------------------------" )
	if( AK_PLATFORM_PC or AK_PLATFORM_MAC ) then
		print( "P: Post event Play_Engine/Stop_Engine" );
		print( "Space: Gas pedal" );
		print( "" )
		print( "H: Post event Play_Hello" );
		print( "B: Bypass bus effect when pressed down" );
		print( "" )
		print( "K: Post event Play_Markers_Test" );
		print( "" )
		print( "F: Post event Play_Footsteps" );
		print( "M: Change material Ground switch to Metal" );
		print( "" )
		print( "N: Set PlayerHealth state to Normal" );
		print( "T: Set PlayerHealth state to Blasted" );
		print( "" )
		print( "Enter: Stop all events, reset game syncs and clear the text" );
	elseif( AK_PLATFORM_XBOX360 ) then
		print( "A: Post event Play_Engine/Stop_Engine" );
		print( "Right thumb's Y axis: Change the value of the 'RPM' RTPC" );
		print( "" )
		print( "X: Post event Play_Hello" );
		print( "D left: Bypass bus effect when pressed down" );
		print( "" )
		print( "Y: Post event Play_Markers_Test" );
		print( "" )
		print( "B: Post event Play_Footsteps" );
		print( "D Right: Change Ground switch material" );
		print( "" )
		print( "D Up: Set PlayerHealth state to Normal" );
		print( "D down: Set PlayerHealth state to Blasted" );
		print( "" )
		print( "Back: Stop all events, reset game syncs and clear the text" );
	elseif( AK_PLATFORM_PS3 or AK_PLATFORM_VITA or AK_PLATFORM_PS4 ) then
		print( "Cross: Post event Play_Engine/Stop_Engine" );
		print( "Right thumb's Y axis: Change the value of the 'RPM' RTPC" );
		print( "" )
		print( "Square: Post event Play_Hello" );
		print( "D left: Bypass bus effect when pressed down" );
		print( "" )
		print( "Triangle: Post event Play_Markers_Test" );
		print( "" )
		print( "Circle: Post event Play_Footsteps" );
		print( "D Right: Change Ground switch material" );
		print( "" )
		print( "D Up: Set PlayerHealth state to Normal" );
		print( "D down: Set PlayerHealth state to Blasted" );
		print( "" )
		print( "Back: Stop all events, reset game syncs and clear the text" );
	elseif( AK_PLATFORM_WII ) then
		print( "A: Post event Play_Engine/Stop_Engine" );
		print( "Directional pad up: Gas Pedal" );
		print( "" )
		print( "X / C: Post event Play_Hello" );
		print( "L / -: Bypass bus effect when pressed down" );
		print( "" )
		print( "Y / Z: Post event Play_Markers_Test" );
		print( "" )
		print( "R / +: Post event Play_Footsteps" );
		print( "Directional pad right: Change Ground switch material" );
		print( "" )
		print( "2: Set PlayerHealth state to Normal" );
		print( "1: Set PlayerHealth state to Blasted" );
		print( "" )
		print( "B: Stop all events, reset game syncs and clear the text" );
	elseif( AK_PLATFORM_IOS ) then
		print( "A: Post event Play_Engine/Stop_Engine" );
		print( "Right thumb's Y axis: Change the value of the 'RPM' RTPC" );
		print( "" )
		print( "X: Post event Play_Hello" );
		print( "D Left: Bypass bus effect when pressed down" );
		print( "" )
		print( "Y: Post event Play_Markers_Test" );
		print( "" )
		print( "B: Post event Play_Footsteps" );
		print( "D Right: Change ground switch" );
		print( "" )
		print( "D Up: Set PlayerHealth state to Normal" );
		print( "D Down: Set PlayerHealth state to Blasted" );
		print( "" )
		print( "Select: Stop all events, reset game syncs and clear the text" );	

	end
	print( "--------------------------------------------------" )
	print( "" )
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
	elseif( AK_PLATFORM_VITA ) then
        basePath = "app0:\\"
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
	assert( result == AK_Success, "Language set error" )	
	
	-- Load banks:
	dummyBankID = 0 --Not used.
    result, dummyBankID = AK.SoundEngine.LoadBank( "Init.bnk", AK_DEFAULT_POOL_ID, dummyBankID )
    assert( result == AK_Success, "Error loading bank Init.bnk" )
    result, dummyBankID = AK.SoundEngine.LoadBank( "Car.bnk", AK_DEFAULT_POOL_ID, dummyBankID )
    assert( result == AK_Success, "Error loading bank Car.bnk" )
    result, dummyBankID = AK.SoundEngine.LoadBank( "MarkerTest.bnk", AK_DEFAULT_POOL_ID, dummyBankID )
    assert( result == AK_Success, "Error loading bank MarkerTest.bnk" )
    result, dummyBankID = AK.SoundEngine.LoadBank( "Human.bnk", AK_DEFAULT_POOL_ID, dummyBankID )
    assert( result == AK_Success, "Error loading bank Human.bnk" )
	result,dummyBankID = AK.SoundEngine.LoadBank( "Dirt.bnk", AK_DEFAULT_POOL_ID, dummyBankID )
    assert( result == AK_Success, "Error loading bank Dirt.bnk" )
	result,dummyBankID = AK.SoundEngine.LoadBank( "Metal.bnk", AK_DEFAULT_POOL_ID, dummyBankID )
    assert( result == AK_Success, "Error loading bank Metal.bnk" )
	result,dummyBankID = AK.SoundEngine.LoadBank( "Gravel.bnk", AK_DEFAULT_POOL_ID, dummyBankID )
    assert( result == AK_Success, "Error loading bankGravel.bnk" )
	
    result = AK.SoundEngine.RegisterGameObj( MAIN_GAME_OBJECT, "LuaGameObject" )
    assert( result == AK_Success, "Register game object error" )
	
	result = AK.SoundEngine.SetActiveListeners( MAIN_GAME_OBJECT, 0x1 );
    assert( result == AK_Success, "Error setting object's active listeners" )

	nRTPC_Effect = RTPC_EFFECT_MAX
    result = AK.SoundEngine.SetRTPCValue( "Enable_Effect", nRTPC_Effect, AK_INVALID_GAME_OBJECT )
    assert( result == AK_Success, "Set RTPC error" )
	
	nRTPC_RPM = RTPC_RPM_MIN
    result = AK.SoundEngine.SetRTPCValue( "RPM", nRTPC_RPM, MAIN_GAME_OBJECT )
    assert( result == AK_Success, "Set RTPC error" )

	result = AK.SoundEngine.SetSwitch( "Surface", "Gravel", MAIN_GAME_OBJECT )
	assert( result == AK_Success, "Set switch error" )
	
	DisplayButtons()
	
    IntegrationDemoGameLoop()
	AkStop()
end

-- ****************
-- Executed commands
-- ****************
MAIN_GAME_OBJECT = 3
RTPC_EFFECT_MIN = 0
RTPC_EFFECT_MAX = 100
RTPC_RPM_MIN = 1000
RTPC_RPM_MAX = 10000
RunScript()