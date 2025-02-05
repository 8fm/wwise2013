
-- *********
-- The g_coroutineHandle handle uses CoroutineModule(), which executes two functions in sequence
-- *********
function CoroutineModule()
	-- add the functions to be executed to this table:
	g_functionTable = { Coroutine1 }
	
    for key,value in pairs( g_functionTable ) do
		currentTest = value
		value()
    end
end


-- *********
-- This Coroutine is your main function. It will post your events and trigger Lua callbacks.
-- *********
function Coroutine1()

	AK.SoundEngine.RegisterGameObj(2)

	--In a game with Motion support, each player must have its own Listener.  The game must assign a Listener explicitly.
	AK.MotionEngine.SetPlayerListener(0, 0)  --SetPlayerListener([Player port], [Listener ID])
	
	--The game needs to activate the proper Listeners bits for each game object.
	AK.SoundEngine.SetActiveListeners(2, 0x01)	--SetActiveListeners([Game Object ID], [Listener Mask])
	
	--The game needs to specify which data (Audio and/or Motion) to send to each Listener.
	AK.SoundEngine.SetListenerPipeline(0, true, true)  --SetListenerPipeline([Listener ID], [bool audio], [bool motion])
	
	PlayMotion()
	
end


-- *********
-- This function is very useful whenever you need a delay in a Coroutine, without blocking the flow of the GameLoop.
-- *********
function Wait(delayTime)  
	testStartTime = os.gettickcount()
	while( os.gettickcount() - testStartTime < delayTime ) do
		coroutine.yield()
	end
end


-- *********
-- This is the function that maps the game events to controller buttons.
-- *********
function PlayMotion()

	if not(AK_PLATFORM_MAC) then
		if( ( AK_PLATFORM_PC and AkLuaGameEngine.IsGamepadConnected() ) ) then
			play_SFX_Motion = AK_GAMEPAD_BUTTON_01
			play_SFX_Motion_String = "A" 		
			play_MotionFX = AK_GAMEPAD_BUTTON_02
			play_MotionFX_String = "B"
			stop_Button = AK_GAMEPAD_BUTTON_03
			stop_Button_String = "X"
			exit_Button = AK_GAMEPAD_BUTTON_07
			exit_Button_String = "Back"

		elseif (AK_PLATFORM_XBOX360) then
			play_SFX_Motion = AK_GAMEPAD_BUTTON_01
			play_SFX_Motion_String = "A" 		
			play_MotionFX = AK_GAMEPAD_BUTTON_02
			play_MotionFX_String = "B"
			stop_Button = AK_GAMEPAD_BUTTON_03
			stop_Button_String = "X"
			exit_Button = AK_GAMEPAD_BUTTON_09
			exit_Button_String = "Back"

		elseif (AK_PLATFORM_PS3) then
			play_SFX_Motion = AK_GAMEPAD_BUTTON_01
			play_SFX_Motion_String = "Cross" 		
			play_MotionFX = AK_GAMEPAD_BUTTON_02
			play_MotionFX_String = "Circle"
			stop_Button = AK_GAMEPAD_BUTTON_03
			stop_Button_String = "Square"
			exit_Button = AK_GAMEPAD_BUTTON_09
			exit_Button_String = "Select"
			
		elseif (AK_PLATFORM_WII) then
			play_SFX_Motion = AK_GAMEPAD_BUTTON_01
			play_SFX_Motion_String = "A" 		
			play_MotionFX = AK_GAMEPAD_BUTTON_02
			play_MotionFX_String = "B"
			stop_Button = AK_GAMEPAD_BUTTON_03
			stop_Button_String = "C"
			exit_Button = AK_GAMEPAD_BUTTON_10
			exit_Button_String = "1"
			
		else
			print (" " )
			print ("<Error>: The Controller is not plugged in.")
		end


		if( ( AK_PLATFORM_PC and AkLuaGameEngine.IsGamepadConnected() ) or not (AK_PLATFORM_PC) ) then
			print (" ")
			print ( "On your controller:" )
			print (" ")
			print ( "  Press '" .. play_SFX_Motion_String .. "' to playback the 'GunFire' routed through the Master Motion Bus.")
			print ( "  Press '" .. play_MotionFX_String .. "' to playback the 'DoorSliding' along with a 'MotionFX'.")
			print ( "  Press '" .. stop_Button_String .. "' to stop the Playback/Motion.")
			print (" ")
			print ( "  Press '" .. exit_Button_String .. "' to exit the current loop.")
			print (" ")
			coroutine.yield()
		
			while (not (AkLuaGameEngine.IsButtonPressed( exit_Button ) ) ) do
			
				if( AkIsButtonPressedThisFrame( play_SFX_Motion) ) then
					result = AK.SoundEngine.PostEvent("GunFire", 2)	
					assert( result ~= AK_INVALID_PLAYING_ID, "Post event error." )
					print( "Now playing the 'GunFire' routed through the Master Motion Bus." )
				
				elseif( AkIsButtonPressedThisFrame( play_MotionFX ) ) then
					result = AK.SoundEngine.PostEvent("DoorSliding", 2)	
					assert( result ~= AK_INVALID_PLAYING_ID, "Post event error." )
					print( "Now playing the 'DoorSliding' along with a 'MotionFX'." )

				elseif( AkIsButtonPressedThisFrame(stop_Button) ) then
					result = AK.SoundEngine.PostEvent("Stop_All", 2)	
					assert( result ~= AK_INVALID_PLAYING_ID, "Post event error." )
					print( "Playback stopped." )
				end
				coroutine.yield()
			end
		end
		

		if (AK_PLATFORM_PC) then
			quit_Button_String = "Esc"
		elseif (AK_PLATFORM_XBOX360) or (AK_PLATFORM_PS3) then	
			quit_Button_String = "Start"
		elseif (AK_PLATFORM_WII) then
			quit_Button_String = "Start' or '1"
		end

		print (" " )
		print( "Press '" .. quit_Button_String .. "' to quit the GameLoop." )
		print (" " )
		coroutine.yield()
		
		AK.SoundEngine.StopAll  ()

	else
		print ("<Error>: Motion is not supported on the Mac.")
	end
end


-- ****************
-- Global variables: 
-- ****************

-- Desired framerate (frames/s)
kFramerate = 30
-- Desired amount of time to connect to Wwise at the beginning of your script.
kTimeToConnect = 3000 -- milliseconds


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

	if not(AK_PLATFORM_MAC) then
		--The game must register the MotionGenerator in order to use it.
		AK.SoundEngine.RegisterPlugin(AkPluginTypeMotionSource, AKCOMPANYID_AUDIOKINETIC, AKSOURCEID_MOTIONGENERATOR, AkCreateMotionGenerator, AkCreateMotionGeneratorParams)  
		
		--The game must register the Device (Controller, D-BOX™, etc.) to the Motion Engine in order to use it. 
		AK.MotionEngine.RegisterMotionDevice(AKCOMPANYID_AUDIOKINETIC, AKMOTIONDEVICEID_RUMBLE, AkCreateRumblePlugin)  --RegisterMotionDevice(AKCOMPANYID_AUDIOKINETIC, [ID], [Callback])
		
		--The game must register a Player to receive motion through a given Device. 
		AK.MotionEngine.AddPlayerMotionDevice(0, AKCOMPANYID_AUDIOKINETIC, AKMOTIONDEVICEID_RUMBLE) --AddPlayerMotionDevice( [Player port], AKCOMPANYID_AUDIOKINETIC, [Device ID])

		--If you want to enable Motion on D-BOX™, un-comment the 2 lines below:
		--AK.MotionEngine.AddPlayerMotionDevice(0, AKCOMPANYID_AUDIOKINETIC, AKMOTIONDEVICEID_DBOX)
		--AK.MotionEngine.RegisterMotionDevice(AKCOMPANYID_AUDIOKINETIC, AKMOTIONDEVICEID_DBOX, AkCreateDBox)
	end
	
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
    end
	
	result = g_lowLevelIO["Default"]:SetBasePath( basePath ) -- g_lowLevelIO is defined by audiokinetic\AkLuaFramework.lua
	assert( result == AK_Success, "Base path set error" )	
	result = AK.StreamMgr.SetCurrentLanguage( langSpecific ) 
	assert( result == AK_Success, "Current language set error" )

	--Load the SoundBanks using the AkLoadBank function found in the AkLuaFramework.
	AkLoadBank("Init.bnk")
	AkLoadBank("Motion.bnk")
	
    AkGameLoop()

	if not(AK_PLATFORM_MAC) then
		--We are exiting the game. Un-registering the Player Motion Device (This step is optional.).
		AK.MotionEngine.RemovePlayerMotionDevice(0, AKCOMPANYID_AUDIOKINETIC, AKMOTIONDEVICEID_RUMBLE) --RemovePlayerMotionDevice( [Player port], AKCOMPANYID_AUDIOKINETIC, [Device ID])
	end
	
	AkStop()
end


-- ****************
-- Executed commands
-- ****************
-- *********
-- In order to plug coroutines in the AkGameLoop, your script must define the g_coroutineHandle coroutine handle.
-- *********
g_coroutineHandle = coroutine.create( CoroutineModule )

RunScript()
