
function GameLoop()
	fDeltaFramesMs = 1/kFramerate * 1000 -- approximate time between frames, in ms
	
	print( "" )
	print( "" )

	if( AK_PLATFORM_PC or AK_PLATFORM_MAC ) then
		print("\t\tPress keys on your keyboard or buttons on your controller and they will be printed out")
	else
		print("\t\tPress buttons on your controller and they will be printed out")
	end
	
    if( AK_PLATFORM_PC or AK_PLATFORM_MAC ) then
	    print("\t\tPress escape to quit the game loop")
    elseif( AK_PLATFORM_XBOX360 ) then
	    print("\t\tPress Back to quit the game loop")
    elseif( AK_PLATFORM_PS3 or AK_PLATFORM_WII ) then
	    print("\t\tPress Start to quit the game loop")
    end
	
    while( not AkEscapeLoopCondition() ) do
		DisplayPressedKey()
		AK.SoundEngine.RenderAudio()
        AkLuaGameEngine.ExecuteBankCallbacks()
        AkLuaGameEngine.ExecuteEventCallbacks()
		AkButtonCleanUp()
		os.sleep( fDeltaFramesMs )
	end
end

function DisplayPressedKey()
    if( AK_PLATFORM_PC or AK_PLATFORM_MAC ) then
		if( AkIsButtonPressedThisFrame( VK_CLEAR ) ) then
			print( "VK_CLEAR" )
		end
		if( AkIsButtonPressedThisFrame( VK_RETURN ) ) then
			print( "VK_RETURN" )
		end
		if( AkIsButtonPressedThisFrame( VK_SHIFT ) ) then
			print( "VK_SHIFT" )
		end
		if( AkIsButtonPressedThisFrame( VK_CONTROL ) ) then
			print( "VK_CONTROL" )
		end
		if( AkIsButtonPressedThisFrame( VK_MENU ) ) then
			print( "VK_MENU" )
		end
		if( AkIsButtonPressedThisFrame( VK_CAPITAL ) ) then
			print( "VK_CAPITAL" )
		end
		if( AkIsButtonPressedThisFrame( VK_ESCAPE ) ) then
			print( "VK_ESCAPE" )
		end
		if( AkIsButtonPressedThisFrame( VK_SPACE ) ) then
			print( "VK_SPACE" )
		end
		if( AkIsButtonPressedThisFrame( VK_PRIOR ) ) then
			print( "VK_PRIOR" )
		end
		if( AkIsButtonPressedThisFrame( VK_NEXT ) ) then
			print( "VK_NEXT" )
		end
		if( AkIsButtonPressedThisFrame( VK_END ) ) then
			print( "VK_END" )
		end
		if( AkIsButtonPressedThisFrame( VK_HOME ) ) then
			print( "VK_HOME" )
		end
		if( AkIsButtonPressedThisFrame( VK_LEFT ) ) then
			print( "VK_LEFT" )
		end
		if( AkIsButtonPressedThisFrame( VK_UP ) ) then
			print( "VK_UP" )
		end
		if( AkIsButtonPressedThisFrame( VK_RIGHT ) ) then
			print( "VK_RIGHT" )
		end
		if( AkIsButtonPressedThisFrame( VK_DOWN ) ) then
			print( "VK_DOWN" )
		end
		if( AkIsButtonPressedThisFrame( VK_SNAPSHOT ) ) then
			print( "VK_SNAPSHOT" )
		end
		if( AkIsButtonPressedThisFrame( VK_INSERT ) ) then
			print( "VK_INSERT" )
		end
		if( AkIsButtonPressedThisFrame( VK_DELETE ) ) then
			print( "VK_DELETE" )
		end
		if( AkIsButtonPressedThisFrame( VK_LWIN ) ) then
			print( "VK_LWIN" )
		end
		if( AkIsButtonPressedThisFrame( VK_NUMPAD0 ) ) then
			print( "VK_NUMPAD0" )
		end
		if( AkIsButtonPressedThisFrame( VK_NUMPAD1 ) ) then
			print( "VK_NUMPAD1" )
		end
		if( AkIsButtonPressedThisFrame( VK_NUMPAD2 ) ) then
			print( "VK_NUMPAD2" )
		end
		if( AkIsButtonPressedThisFrame( VK_NUMPAD3 ) ) then
			print( "VK_NUMPAD3" )
		end
		if( AkIsButtonPressedThisFrame( VK_NUMPAD4 ) ) then
			print( "VK_NUMPAD4" )
		end
		if( AkIsButtonPressedThisFrame( VK_NUMPAD5 ) ) then
			print( "VK_NUMPAD5" )
		end
		if( AkIsButtonPressedThisFrame( VK_NUMPAD6 ) ) then
			print( "VK_NUMPAD6" )
		end
		if( AkIsButtonPressedThisFrame( VK_NUMPAD7 ) ) then
			print( "VK_NUMPAD7" )
		end
		if( AkIsButtonPressedThisFrame( VK_NUMPAD8 ) ) then
			print( "VK_NUMPAD8" )
		end
		if( AkIsButtonPressedThisFrame( VK_NUMPAD9 ) ) then
			print( "VK_NUMPAD9" )
		end
		if( AkIsButtonPressedThisFrame( VK_MULTIPLY ) ) then
			print( "VK_MULTIPLY" )
		end
		if( AkIsButtonPressedThisFrame( VK_ADD ) ) then
			print( "VK_ADD" )
		end
		if( AkIsButtonPressedThisFrame( VK_SUBTRACT ) ) then
			print( "VK_SUBTRACT" )
		end
		if( AkIsButtonPressedThisFrame( VK_DECIMAL ) ) then
			print( "VK_DECIMAL" )
		end
		if( AkIsButtonPressedThisFrame( VK_DIVIDE ) ) then
			print( "VK_DIVIDE" )
		end
		if( AkIsButtonPressedThisFrame( VK_F1 ) ) then
			print( "VK_F1" )
		end
		if( AkIsButtonPressedThisFrame( VK_F2 ) ) then
			print( "VK_F2" )
		end
		if( AkIsButtonPressedThisFrame( VK_F3 ) ) then
			print( "VK_F3" )
		end
		if( AkIsButtonPressedThisFrame( VK_F4 ) ) then
			print( "VK_F4" )
		end
		if( AkIsButtonPressedThisFrame( VK_F5 ) ) then
			print( "VK_F5" )
		end
		if( AkIsButtonPressedThisFrame( VK_F6 ) ) then
			print( "VK_F6" )
		end
		if( AkIsButtonPressedThisFrame( VK_F7 ) ) then
			print( "VK_F7" )
		end
		if( AkIsButtonPressedThisFrame( VK_F8 ) ) then
			print( "VK_F8" )
		end
		if( AkIsButtonPressedThisFrame( VK_F9 ) ) then
			print( "VK_F9" )
		end
		if( AkIsButtonPressedThisFrame( VK_F10 ) ) then
			print( "VK_F10" )
		end
		if( AkIsButtonPressedThisFrame( VK_F11 ) ) then
			print( "VK_F11" )
		end
		if( AkIsButtonPressedThisFrame( VK_F12 ) ) then
			print( "VK_F12" )
		end
		if( AkIsButtonPressedThisFrame( VK_NUMLOCK ) ) then
			print( "VK_NUMLOCK" )
		end
		if( AkIsButtonPressedThisFrame( VK_SCROLL ) ) then
			print( "VK_SCROLL" )
		end
		if( AkIsButtonPressedThisFrame( VK_LSHIFT ) ) then
			print( "VK_LSHIFT" )
		end
		if( AkIsButtonPressedThisFrame( VK_RSHIFT ) ) then
			print( "VK_RSHIFT" )
		end
		if( AkIsButtonPressedThisFrame( VK_LCONTROL ) ) then
			print( "VK_LCONTROL" )
		end
		if( AkIsButtonPressedThisFrame( VK_RCONTROL ) ) then
			print( "VK_RCONTROL" )
		end
		if( AkIsButtonPressedThisFrame( VK_LMENU ) ) then
			print( "VK_LMENU" )
		end
		if( AkIsButtonPressedThisFrame( VK_RMENU ) ) then
			print( "VK_RMENU" )
		end
		if( AkIsButtonPressedThisFrame( VK_OEM_PLUS ) ) then
			print( "VK_OEM_PLUS" )
		end
		if( AkIsButtonPressedThisFrame( VK_OEM_COMMA ) ) then
			print( "VK_OEM_COMMA" )
		end
		if( AkIsButtonPressedThisFrame( VK_OEM_MINUS ) ) then
			print( "VK_OEM_MINUS" )
		end
		if( AkIsButtonPressedThisFrame( VK_OEM_PERIOD ) ) then
			print( "VK_OEM_PERIOD" )
		end
		if( AkIsButtonPressedThisFrame( VK_OEM_1 ) ) then
			print( "VK_OEM_1" )
		end
		if( AkIsButtonPressedThisFrame( VK_OEM_2 ) ) then
			print( "VK_OEM_2" )
		end
		if( AkIsButtonPressedThisFrame( VK_OEM_3 ) ) then
			print( "VK_OEM_3" )
		end
		if( AkIsButtonPressedThisFrame( VK_OEM_4 ) ) then
			print( "VK_OEM_4" )
		end
		if( AkIsButtonPressedThisFrame( VK_OEM_5 ) ) then
			print( "VK_OEM_5" )
		end
		if( AkIsButtonPressedThisFrame( VK_OEM_6 ) ) then
			print( "VK_OEM_6" )
		end
		if( AkIsButtonPressedThisFrame( VK_OEM_7 ) ) then
			print( "VK_OEM_7" )
		end
		if( AkIsButtonPressedThisFrame( "0" ) ) then
			print( "Zero" )
		end
		if( AkIsButtonPressedThisFrame( "1" ) ) then
			print( "One" )
		end
		if( AkIsButtonPressedThisFrame( "2" ) ) then
			print( "Two" )
		end
		if( AkIsButtonPressedThisFrame( "3" ) ) then
			print( "Three" )
		end
		if( AkIsButtonPressedThisFrame( "4" ) ) then
			print( "Four" )
		end
		if( AkIsButtonPressedThisFrame( "5" ) ) then
			print( "Five" )
		end
		if( AkIsButtonPressedThisFrame( "6" ) ) then
			print( "Six" )
		end
		if( AkIsButtonPressedThisFrame( "7" ) ) then
			print( "Seven" )
		end
		if( AkIsButtonPressedThisFrame( "8" ) ) then
			print( "Eight" )
		end
		if( AkIsButtonPressedThisFrame( "9" ) ) then
			print( "Nine" )
		end
		if( AkIsButtonPressedThisFrame( "a" ) ) then
			print( "a" )
		end
    end
	if( ( AK_PLATFORM_PC and AkLuaGameEngine.IsGamepadConnected() ) or not AK_PLATFORM_PC ) then
		if( AkIsButtonPressedThisFrame( AK_GAMEPAD_BUTTON_01 ) ) then
			print( "AK_GAMEPAD_BUTTON_01" )
		end
		if( AkIsButtonPressedThisFrame( AK_GAMEPAD_BUTTON_02 ) ) then
			print( "AK_GAMEPAD_BUTTON_02" )
		end
		if( AkIsButtonPressedThisFrame( AK_GAMEPAD_BUTTON_03 ) ) then
			print( "AK_GAMEPAD_BUTTON_03" )
		end
		if( AkIsButtonPressedThisFrame( AK_GAMEPAD_BUTTON_04 ) ) then
			print( "AK_GAMEPAD_BUTTON_04" )
		end
		if( AkIsButtonPressedThisFrame( AK_GAMEPAD_BUTTON_05 ) ) then
			print( "AK_GAMEPAD_BUTTON_05" )
		end
		if( AkIsButtonPressedThisFrame( AK_GAMEPAD_BUTTON_06 ) ) then
			print( "AK_GAMEPAD_BUTTON_06" )
		end
		if( AkIsButtonPressedThisFrame( AK_GAMEPAD_BUTTON_07 ) ) then
			print( "AK_GAMEPAD_BUTTON_07" )
		end
		if( AkIsButtonPressedThisFrame( AK_GAMEPAD_BUTTON_08 ) ) then
			print( "AK_GAMEPAD_BUTTON_08" )
		end
		if( AkIsButtonPressedThisFrame( AK_GAMEPAD_BUTTON_09 ) ) then
			print( "AK_GAMEPAD_BUTTON_09" )
			print( "Displaying analog values:" )
			print( string.format( "AK_GAMEPAD_ANALOG_01: %f", AkLuaGameEngine.GetAnalogStickPosition( AK_GAMEPAD_ANALOG_01 ) ) )
			print( string.format( "AK_GAMEPAD_ANALOG_02: %f", AkLuaGameEngine.GetAnalogStickPosition( AK_GAMEPAD_ANALOG_02 ) ) )
			print( string.format( "AK_GAMEPAD_ANALOG_03: %f", AkLuaGameEngine.GetAnalogStickPosition( AK_GAMEPAD_ANALOG_03 ) ) )
			print( string.format( "AK_GAMEPAD_ANALOG_04: %f", AkLuaGameEngine.GetAnalogStickPosition( AK_GAMEPAD_ANALOG_04 ) ) )
			print( string.format( "AK_GAMEPAD_ANALOG_05: %f", AkLuaGameEngine.GetAnalogStickPosition( AK_GAMEPAD_ANALOG_05 ) ) )
			print( string.format( "AK_GAMEPAD_ANALOG_06: %f", AkLuaGameEngine.GetAnalogStickPosition( AK_GAMEPAD_ANALOG_06 ) ) )
			print( string.format( "AK_GAMEPAD_ANALOG_07: %f", AkLuaGameEngine.GetAnalogStickPosition( AK_GAMEPAD_ANALOG_07 ) ) )
			print( string.format( "AK_GAMEPAD_ANALOG_08: %f", AkLuaGameEngine.GetAnalogStickPosition( AK_GAMEPAD_ANALOG_08 ) ) )
			print( string.format( "AK_GAMEPAD_ANALOG_09: %f", AkLuaGameEngine.GetAnalogStickPosition( AK_GAMEPAD_ANALOG_09 ) ) )
		end
		if( AkIsButtonPressedThisFrame( AK_GAMEPAD_BUTTON_10 ) ) then
			print( "AK_GAMEPAD_BUTTON_10" )
		end
		if( AkIsButtonPressedThisFrame( AK_GAMEPAD_BUTTON_11 ) ) then
			print( "AK_GAMEPAD_BUTTON_11" )
		end
		if( AkIsButtonPressedThisFrame( AK_GAMEPAD_BUTTON_12 ) ) then
			print( "AK_GAMEPAD_BUTTON_12" )
		end
		if( AkIsButtonPressedThisFrame( AK_GAMEPAD_BUTTON_13 ) ) then
			print( "AK_GAMEPAD_BUTTON_13" )
		end
		if( AkIsButtonPressedThisFrame( AK_GAMEPAD_BUTTON_14 ) ) then
			print( "AK_GAMEPAD_BUTTON_14" )
		end
		if( AkIsButtonPressedThisFrame( AK_GAMEPAD_BUTTON_15 ) ) then
			print( "AK_GAMEPAD_BUTTON_15" )
		end
		if( AkIsButtonPressedThisFrame( AK_GAMEPAD_BUTTON_16 ) ) then
			print( "AK_GAMEPAD_BUTTON_16" )
		end
	end
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
	
	GameLoop()
	AkStop()
end

-- ****************
-- Executed commands
-- ****************
RunScript()