--[[ ***********************
Escape condition used in the game loop
***********************]]
function AkEscapeLoopCondition()
	local checkButton
    if( AK_PLATFORM_PC or AK_PLATFORM_MAC ) then
        checkButton = VK_ESCAPE
    else
        checkButton = AK_GAMEPAD_BUTTON_10
    end
    return AkIsButtonPressedThisFrame( checkButton ) or kEndOfTests
end

--[[ ***********************
Returns true if and only if the button is being pressed in the current game frame.
***********************]]
function AkIsButtonPressedThisFrame( in_nButton )	
	if( kButtonsCurrentlyDown[ in_nButton ] ) then -- button already pressed
		return false
	else
		if( AkLuaGameEngine.IsButtonPressed( in_nButton ) ) then
			kButtonsCurrentlyDown[ in_nButton ] = true
			return true
		end
	end
end

--[[ ***********************
This method is used to avoid recognizing a button being pressed twice in the same game frame.
***********************]]
function AkButtonCleanUp()
	for key,bIsKeyDown in pairs( kButtonsCurrentlyDown ) do
		if( not AkLuaGameEngine.IsButtonPressed( key ) ) then
			kButtonsCurrentlyDown[ key ] = false
		end
	end
end

--[[ ***********************
This method contains the calls necessary for one game tick for the sound engine
***********************]]
function AkGameTick()		
	if ( not AK.SoundEngine.IsInitialized() ) then
		return
	end
	
	--Execute all user-registered per-tick calls
	for key,funcInfo in pairs(g_GameTickCalls) do		
		funcInfo._Func(funcInfo)	
	end
		
	AkLuaGameEngine.ExecuteHBMCallbacks()
	AK.SoundEngine.RenderAudio()
	AkLuaGameEngine.Render()
	AkLuaGameEngine.ExecuteEventCallbacks()
	AkLuaGameEngine.ExecuteBankCallbacks()
	AkButtonCleanUp()
end

--[[ ***********************
Game loop that renders audio (and communication) until the escape condition is valid
***********************]]
function AkGameLoop()	
	local fDeltaFramesMs = 1/kFramerate * 1000 -- approximate time between frames, in ms
    if( AK_PLATFORM_PC or AK_PLATFORM_MAC ) then
	    print("\t\tPress escape to quit the game loop")
	else
	     AutoLogTestMsg( "****** "..kButtonNameMapping.AK_GAMEPAD_BUTTON_10.." to quit the game loop ******",0,1 )
    end	
	
	kEndOfTests = false;
    while( not AkEscapeLoopCondition() ) do
		
		if( AK_PLATFORM_WII or AK_PLATFORM_WIIU) then
			-- Ensure game engine listens to HOME button.
			AkIsButtonPressedThisFrame( AK_HOME_BUTTON )
		end
		
		AkHandleCoroutines()		
		
		AkGameTick()		
		
		os.sleep( fDeltaFramesMs )
	end	
end

--[[ ***********************
This function runs the game loop for in_ms at a frame rate of kFramerate frames/s, with communication if AK_LUA_RELEASE is not defined
***********************]]
function AkRunGameLoopForPeriod( in_ms )
	local fDeltaFramesMs = 1/kFramerate * 1000 -- approximate time between frames, in ms
	
	local initial_time = os.gettickcount()
	
	if( AK_PLATFORM_PC or AK_PLATFORM_MAC ) then
	    print("\t\tPress escape to quit this loop")
    elseif( AK_PLATFORM_WII or AK_PLATFORM_WIIU ) then
	    print("\t\tPress Start (classic pad) or 1 (Wii remote) to quit this loop")
	else
	    print("\t\tPress Start to quit this loop")
    end
    kEndOfTests = false;
	while( ( os.gettickcount() - initial_time < in_ms ) and ( not AkEscapeLoopCondition() ) ) do		
		AkGameTick()		
		os.sleep( fDeltaFramesMs )
	end	
end

--[[ ***********************
This method will start the coroutines from the game loop.
***********************]]
function AkHandleCoroutines()
	if( g_coroutineHandle ) then
		if( coroutine.status( g_coroutineHandle ) ~= 'dead' ) then
			success, errMsg = coroutine.resume( g_coroutineHandle )
			if success == false then
				print(errMsg)
			end
		end
    end
end

--[[ ***********************
Sample, Wii-specific Home button menu callback.
***********************]]
function OnHBMCallback( in_iReason )
	print( string.format( "OnHBMCallback: %i\n", in_iReason ) )
	if( in_iReason==HOME_MENU_OPEN ) then
		-- TODO Post a Mute Bus event here.
	elseif( in_iReason==HOME_MENU_BEFORE_INIT_SOUND ) then
		AK.SoundEngine.Wii.DeactivateRemoteSpeakers(false)
	elseif( in_iReason==HOME_MENU_END ) then
		AK.SoundEngine.Wii.ActivateRemoteSpeakers()
		-- TODO Post an Unmute Bus event here.
	end
end

--[[ ***********************
Here we define the SoundEngine DefaultInitSettings
***********************]]
function GetDefaultInitSettings( out_initSettings )

	AK.SoundEngine.GetDefaultInitSettings( out_initSettings )
	
	if( AK_PLATFORM_WII or AK_PLATFORM_3DS) then		
		out_initSettings.uDefaultPoolSize = 1024*1024
	elseif( AK_PLATFORM_IOS or AK_PLATFORM_ANDROID ) then
		out_initSettings.uDefaultPoolSize = 8*1024*1024
	end	
end

--[[ ***********************
Here we define the SoundEngine DefaultPlatformInitSettings
***********************]]
function GetDefaultPlatformInitSettings( out_platformInitSettings )

	AK.SoundEngine.GetDefaultPlatformInitSettings( out_platformInitSettings )

	if( AK_PLATFORM_WII or AK_PLATFORM_3DS) then
		out_platformInitSettings.uLEngineDefaultPoolSize = 1024*1024
	elseif( AK_PLATFORM_IOS or AK_PLATFORM_ANDROID ) then
		out_platformInitSettings.uLEngineDefaultPoolSize = 8*1024*1024
	end	
end

--[[ ***********************
Here we define the SoundEngine DefaultDeviceSettings
***********************]]
function GetDefaultDeviceSettings( out_deviceSettings )

	AK.StreamMgr.GetDefaultDeviceSettings( out_deviceSettings )
	
	-- Default  is 2 MB, Use less on the greedy Wii.
    if( AK_PLATFORM_WII ) then
    	out_deviceSettings.uIOMemorySize = 512*1024 -- 512 Kb of memory for I/O -- WII
    end
	
	out_deviceSettings.fMaxCacheRatio = 2
    
end

--[[ ***********************
Here we define the SoundEngine DefaultStreamSettings
***********************]]
function GetDefaultStreamSettings( out_stmSettings )

	AK.StreamMgr.GetDefaultSettings( out_stmSettings )

end

--[[ ***********************
Here we define the SoundEngine DefaultMemSettings
***********************]]
function GetDefaultMemSettings( out_memSettings )

	out_memSettings.uMaxNumPools = 20

end		

--[[ ***********************
Initialize the Sound Engine.

<<< NOTE: >>>
To override the Default Sound Engine Settings in your script: >>>
1) Copy the current function in your script under a different name. (i.e. LocalAkInitSE() ).
2) Add your custom Sound Engine settings in the section below (i.e. initSettings.uDefaultPoolSize = 1024*1024).
3) Make sure to use your custom function (i.e. "LocalAkInitSE()")  instead of the default ("AkInitSE") at the bottom of your script.
***********************]]
function AkInitSE()

	--Create the various parameter structures required to initialize the SoundEngine.
	local initSettings = AkInitSettings:new_local()
	local platformInitSettings = AkPlatformInitSettings:new_local()
	local deviceSettings = AkDeviceSettings:new_local()
	local stmSettings = AkStreamMgrSettings:new_local()
	local memSettings = AkMemSettings:new_local()
	
	--Get the default Sound Engine settings.
	GetDefaultInitSettings( initSettings )
	GetDefaultPlatformInitSettings( platformInitSettings )
	GetDefaultStreamSettings( stmSettings )
	GetDefaultDeviceSettings( deviceSettings )
	GetDefaultMemSettings( memSettings )

	--Background Music support is disabled by default in the Sound Engine for every Platform except for the XBox360.
	--Here, we enable it for the PS3 as well.	
	if( AK_PLATFORM_PS3 ) then
		platformInitSettings.bBGMEnable = true
		platformInitSettings.uBGMSysutilCallbackSlot = 1
	end

	--Uncomment the following line if you want to change the Init Memory Settings for PrepareEvent/PrepareBank.
	--AkInitMemoryManager(memSettings)
	
	-- <<< Add your Custom Sound Engine settings here: >>>

	if g_OverrideSESettings ~= nil then
		g_OverrideSESettings(initSettings, platformInitSettings, deviceSettings, stmSettings, memSettings);
	end
	
	--Comment out the following line if you changed the Init Memory Settings for PrepareEvent/PrepareBank.
	AkInitSEParam( initSettings, platformInitSettings, deviceSettings, stmSettings, memSettings )
	
	--Uncomment the following lines if you changed the Init Memory Settings for PrepareEvent/PrepareBank.
	--AkInitDefaultIOSystem( stmSettings, deviceSettings ) 	-- If you wish to use the RSX device (PS3), call this instead: AkInitMultiIOSystem_Default_RSX(stmSettings,deviceSettings)
	--AkInitParamsPrivate( initSettings, platformInitSettings )
	
	if( AK_PLATFORM_VITA ) then
		result = AK.ATRAC9.Init()
		assert( result == AK_Success, "Failed to initialize ATRAC9 with AK.ATRAC9.Init()" )
	end
end

--[[ ***********************
Initialize Sound Engine Memory Manager.
***********************]]
function AkInitMemoryManager(in_memSettings) 
	local result = AK.MemoryMgr.Init( in_memSettings )
	assert( result == AK_Success, "Could not create the memory manager." )
	
end

--[[ ***********************
Initialize IO system.
***********************]]
g_lowLevelIO = {}
-- Default one-device system.
function AkInitDefaultIOSystem( in_deviceSettings ) 
	
	-- Create a device BLOCKING or DEFERRED, according to setting's scheduler flag.
	local result = AK_Fail
	if ( in_deviceSettings.uSchedulerTypeFlags == AK_SCHEDULER_BLOCKING ) then
		
		-- Initialize our instance of the default File System/LowLevelIO hook BLOCKING.
		g_lowLevelIO["Default"] = CAkFilePackageLowLevelIOBlocking:new() -- global variable
		result = g_lowLevelIO["Default"]:Init( in_deviceSettings, true )
		
	elseif ( in_deviceSettings.uSchedulerTypeFlags == AK_SCHEDULER_DEFERRED_LINED_UP ) then
		
		-- Initialize our instance of the default File System/LowLevelIO hook DEFERRED.
		g_lowLevelIO["Default"] = CAkFilePackageLowLevelIODeferred:new() -- global variable
		if( AK_PLATFORM_PS3 ) then
    		result = g_lowLevelIO["Default"]:Init( in_deviceSettings, true, g_PS3Drive )
	    else
	    	result = g_lowLevelIO["Default"]:Init( in_deviceSettings, true )
	    end
		
	end
	assert( result == AK_Success, "Could not create the Low-Level I/O system." )
end

-- Multi-device system with a default and a RAM device.
-- Params:
-- - in_deviceSettingsDefault: device settings for default device.
-- - in_deviceSettingsRAM: device settings for RAM device.
-- - in_bRAMShuffleOrder: stress-testing feature. RAM device will complete low-level IO requests out of order.
-- - in_uRAMDelay: stress-testing feature. RAM device waits in_uRAMDelay ms before completing requests. This lets the device push many requests before they are completed.
function AkInitMultiIOSystem_Default_RAM(in_deviceSettingsDefault, in_deviceSettingsRAM, in_bRAMShuffleOrder, in_uRAMDelay)
	
	print( "Initializing multi-device I/O system: Default + RAM" )
	
	-- Create the Low-Level IO device dispatcher and register to the Stream Manager.
	local dispatcher = CAkDefaultLowLevelIODispatcher:new() -- global variable
	AK.StreamMgr.SetFileLocationResolver( dispatcher )
	
	-- Create a RAM device first and register it to the dispatcher (the dispatcher should ask this one first).
	g_lowLevelIO["RAM"] = RAMLowLevelIOHook:new()
	assert( g_lowLevelIO["RAM"] ~= nil )
	assert( in_deviceSettingsRAM.uSchedulerTypeFlags == AK_SCHEDULER_DEFERRED_LINED_UP )
	local result = g_lowLevelIO["RAM"]:Init( in_deviceSettingsRAM, in_bRAMShuffleOrder, in_uRAMDelay )
	assert( result == AK_Success, "Could not create the Low-Level I/O system." )
	dispatcher:AddDevice( g_lowLevelIO["RAM"] )
	
	-- Create the default device.
	AkInitDefaultIOSystem( in_deviceSettingsDefault )
	
	-- Register it to the dispatcher.
	dispatcher:AddDevice( g_lowLevelIO["Default"] )
	
end

-- Multi-device system with a default and an RSX device.
-- Notes: 
--	- RSX devices need to be loaded with a file package. It is accessed with global variable g_rsxDevice. Use AkLoadPackageInVRAM() service.
--	- You cannot load banks synchronously with the RSX device: AkGameLoop needs to run for this device to work.
--	- The recommended way is to use a streamed-files-only package with the RSX device.
--	- After the RSX device is initialized, no more video output will appear on screen,
function AkInitMultiIOSystem_Default_RSX(in_deviceSettingsDefault, in_deviceSettingsRSX) 
	
	if( AK_PLATFORM_PS3 ) then

		-- Create the Low-Level IO device dispatcher and register to the Stream Manager.
		local dispatcher = CAkMultiDeviceDispatcherPS3:new() -- global variable
		AK.StreamMgr.SetFileLocationResolver( dispatcher )
		
		-- Create a VRAM device first and register it to the dispatcher (the dispatcher should ask this one first).
		g_lowLevelIO["RSX"] = CAkRSXIOHook:new()
		assert( g_lowLevelIO["RSX"] ~= nil )
		assert( in_deviceSettingsRSX.uSchedulerTypeFlags == AK_SCHEDULER_DEFERRED_LINED_UP )
		local result = g_lowLevelIO["RSX"]:Init( in_deviceSettingsRSX )
		assert( result == AK_Success, "Could not create the Low-Level I/O system." )
		dispatcher:AddDeviceRSX( g_lowLevelIO["RSX"] )
		
		-- Create the default device.
		AkInitDefaultIOSystem( in_deviceSettingsDefault )
		-- Register it to the dispatcher.
		dispatcher:AddDevice( g_lowLevelIO["Default"] )

		
    else
		-- Other platforms: create single default device.
		AkInitDefaultIOSystem(in_deviceSettings) 
    end
end

-- Default override function to setup a RAM device. 
-- Usage: assign g_OverrideLowLevelIOInit = AkDefaultLowLevelIOOverrideRAM prior to calling the default main.
function AkDefaultLowLevelIOOverrideRAM(in_deviceSettingsDefault)

	-- Prepare device settings for the RAM device.
	local deviceSettingsRAM = AkDeviceSettings:new_local()
	GetDefaultDeviceSettings( deviceSettingsRAM )
	-- Need to specify a deferred scheduler. Additionnally, here are a few standard parameters.
	deviceSettingsRAM.uIOMemorySize = 1 * 1024 * 1024
	deviceSettingsRAM.uGranularity = 4 * 1024
	deviceSettingsRAM.uSchedulerTypeFlags = AK_SCHEDULER_DEFERRED_LINED_UP
	deviceSettingsRAM.fTargetAutoStmBufferLength = 100
	deviceSettingsRAM.uMaxConcurrentIO = 128
	deviceSettingsRAM.fMaxCacheRatio = 2

	-- Init multi device system.
	AkInitMultiIOSystem_Default_RAM(in_deviceSettingsDefault, deviceSettingsRAM, false, 0)
end

-- Default override function to setup an RSX device. 
-- Usage: assign g_OverrideLowLevelIOInit = AkDefaultLowLevelIOOverrideRSX prior to calling the default main.
function AkDefaultLowLevelIOOverrideRSX(in_deviceSettingsDefault)

	-- Prepare device settings for the RSX device.
	local deviceSettingsRSX = AkDeviceSettings:new_local()
	GetDefaultDeviceSettings( deviceSettingsRSX )
	-- Need to specify a deferred scheduler. Additionnally, here are a few standard parameters.
	deviceSettingsRSX.uIOMemorySize = 1 * 1024 * 1024
	deviceSettingsRSX.uGranularity = 4 * 1024
	deviceSettingsRSX.uSchedulerTypeFlags = AK_SCHEDULER_DEFERRED_LINED_UP
	deviceSettingsRSX.fTargetAutoStmBufferLength = 100
	deviceSettingsRSX.uMaxConcurrentIO = 128
	deviceSettingsRSX.fMaxCacheRatio = 2

	-- Init multi device system.
	AkInitMultiIOSystem_Default_RSX(in_deviceSettingsDefault, deviceSettingsRSX, false, 0)
end

--[[ ***********************
Initialize the Sound Engine Platform
***********************]]
function AkInitParamsPrivate( in_initSettings, in_platformInitSettings)

	result = AK.SoundEngine.Init( in_initSettings, in_platformInitSettings )
	assert( result == AK_Success, "Sound engine initialization error" )
	
	result = AK.MusicEngine.Init( nil )
	assert( result == AK_Success, "Music engine initialization error" )
    
	result = AK.SoundEngine.IsInitialized()
	assert( result == true, "Error: the sound engine is not initialized" )
	
	if( AK_PLATFORM_WII or AK_PLATFORM_WIIU) then
	
		while( AK.SoundEngine.Wii.ActivateRemoteSpeakers() == AK_Busy ) do
		end

		AkLuaGameEngine.RegisterHBMCallbackFunction( "OnHBMCallback" )
	end
	
end

--[[ ***********************
Last phase of the Sound Engine initialization: 
Here we apply the Sound Engine Settings.
***********************]]
-- You can define g_OverrideLowLevelIOInit in order to override the low-level IO initialization.
-- g_OverrideLowLevelIOInit receives the default device settings that were setup (and possibly overridden) in AkInitSE.
-- Typically, you would call AkInitDefaultIOSystem() or one of the multi-device init services. 
function AkInitSEParam( in_initSettings, in_platformInitSettings, in_deviceSettings, in_stmSettings, in_memSettings )
	
	AkInitMemoryManager(in_memSettings)
	
	-- Create the stream manager and the one and only default low-level device
	streamMgr = AK.StreamMgr.Create( in_stmSettings )
	if streamMgr == nil then 
		assert( false, "Failed creating Stream Manager" )
		return
	end
	
	if g_OverrideLowLevelIOInit ~= nil then
		g_OverrideLowLevelIOInit(in_deviceSettings)
	else
		AkInitDefaultIOSystem(in_deviceSettings) 
	end
	
	AkInitParamsPrivate(in_initSettings, in_platformInitSettings)
	
end

--[[ ***********************
Terminate the sound engine.
***********************]]
function AkTermSE()
	if( AK_PLATFORM_VITA ) then
		AK.ATRAC9.Term()
	end

	-- Terminate the music engine
	AK.MusicEngine.Term()
    
	-- Terminate the sound engine
	AK.SoundEngine.Term()
	
	-- Term and delete all low-level devices
	for k,device in pairs(g_lowLevelIO) do 
		device:Term()
		device:delete()
	end
	
    -- Terminate the streaming manager
    if( AK.IAkStreamMgr:Get() ~= NULL ) then
		AK.IAkStreamMgr:Get():Destroy()
    end
	
	-- Terminate the memory manager
    assert( AK.MemoryMgr.IsInitialized() == true, "Error: memory manager not initialized" )
	AK.MemoryMgr.Term()
end

--[[ ***********************
Initialize communications.
***********************]]
function AkInitComm()

	local settingsComm = AkCommSettings:new_local()
	
	AK.Comm.GetDefaultInitSettings( settingsComm )
	
	result = AK.Comm.Init( settingsComm )
	assert( result == AK_Success, "Failed creating communication services" )

end

--[[ ***********************
Terminate communications.
***********************]]
function AkTermComm()

	AK.Comm.Term()

end

--[[ ***********************
Register all plug-ins.
***********************]]
function AkRegisterPlugIns()
	AK.SoundEngine.RegisterAllPlugins()
end

--[[ ***********************
Lua callback for the LoadBank method
***********************]]
function AkLoadBankCallBackFunction( in_bankID, in_eLoadStatus, in_memPoolId, in_cookie )
    print( "************ LoadBank callback ************" )
    print( string.format( "in_bankID: %s, in_eLoadStatus: %d, in_memPoolId: %d, in_cookie: %d", in_bankID, in_eLoadStatus, in_memPoolId, in_cookie ) )
    if( not AK_LUA_RELEASE ) then
    	if( in_eLoadStatus == AK_Success ) then
			AK.SoundEngine.PostMsgMonitor( string.format( "Loaded bank with ID: %d", in_bankID ) )
		else
			AK.SoundEngine.PostMsgMonitor( string.format( "Failed to load bank with ID: %d", in_bankID ) )
    	end
    end 
    print( "***************************************" )
end

--[[ ***********************
Lua callback for the UnloadBank method
***********************]]
function AkUnloadBankCallBackFunction( in_bankID, in_eLoadStatus, in_memPoolId, in_cookie )
    print( "************ UnloadBank callback ************" )
    print( string.format( "in_bankID: %d, in_eLoadStatus: %d, in_memPoolId: %d, in_cookie: %d", in_bankID, in_eLoadStatus, in_memPoolId, in_cookie ) )
    
    print( "***************************************" )
end

--[[ ***********************
Lua callback for the PostEvent method
***********************]]
function AkPostEventCallBackFunction( in_callbackType, in_data )
    print( "************ Event callback ************" )
    -- This shows callback use
    if( in_callbackType == AK_Marker ) then
        print( string.format( "Identifier: %s, position: %s, label: %s", in_data.uIdentifier, in_data.uPosition, in_data.strLabel ) )
    elseif( in_callbackType == AK_Duration ) then
        print( string.format( "Duration is: %f, Estimated Duration is: %f", in_data.fDuration , in_data.fEstimatedDuration ) )
	else 
        assert( in_callbackType == AK_EndOfEvent )
        print( "End of event!" )
    end
	sourcePosition = 0
	result, sourcePosition = AK.SoundEngine.GetSourcePlayPosition( in_data.playingID, sourcePosition )
	if( result == AK_Success ) then
		print( string.format( "Source position: %s", sourcePosition ) )
	end
    print( "****************************************" )
end

--[[ ***********************
Interactive Music Timer Lua callback for the PostEvent method.
-- Available Flags: AK_MusicSyncBeat, AK_MusicSyncBar, AK_MusicSyncEntry, AK_MusicSyncExit, AK_MusicSyncAll
-- Usage sample in Game Simulator: AK.SoundEngine.PostEvent( "Play", MyGameObjectID, AK_MusicSyncAll, "AkMusicCallbackFunction", 0 )
***********************]]
function AkMusicCallbackFunction( in_callbackType, in_callbackInfo )

	print(string.format( "BarDuration: %f", in_callbackInfo.fBarDuration) )
	print(string.format( "BeatDuration: %f", in_callbackInfo.fBeatDuration) )
	print(string.format( "GridDuration: %f", in_callbackInfo.fGridDuration) )
	print(string.format( "GridOffset: %f", in_callbackInfo.fGridOffset) )
	
	if( in_callbackType == AK_MusicSyncBeat ) then
		print("Music Timer callback > Beat")
	end
	if( in_callbackType == AK_MusicSyncBar ) then
		print("Music Timer callback >> Bar")
	end
	if( in_callbackType == AK_MusicSyncEntry ) then
		print("Music Timer callback >>> Entry Cue")
	end
	if( in_callbackType == AK_MusicSyncExit ) then
		print("Music Timer callback >>>> Exit Cue")
	end
	
	if( in_callbackType == AK_MusicSyncGrid ) then
		print("Music Timer callback >>>> Grid Cue")
	end
	if( in_callbackType == AK_MusicSyncUserCue ) then
		print("Music Timer callback >>>> User Cue")
	end
	if( in_callbackType == AK_MusicSyncPoint ) then
		print("Music Timer callback >>>> Sync Point")
	end
	
end

--[[ ***********************
Stop all playing sounds, the sound engine and all communications
***********************]]
function AkStop()
	if( AK.SoundEngine.IsInitialized() ) then
		result = AK.SoundEngine.UnregisterAllGameObj()
	    assert( result == AK_Success, "Error unregistering all game objects" )
	    
	    AK.SoundEngine.StopAllObsolete()
		AK.SoundEngine.ClearBanks()
	end
	
	if( not AK_LUA_RELEASE ) then
		AkTermComm()
	end
	AkTermSE()
end

--[[ ***********************
Load a bank synchronously, per name.
***********************]]
function AkLoadBank( in_strBankName )
	local bankID = 0
	local result = 0
		
	result, bankID = AK.SoundEngine.LoadBank( in_strBankName, AK_DEFAULT_POOL_ID, bankID )
	if (result ~= AK_BankAlreadyLoaded and result ~= AK_Success) then
		print( string.format( "Error(%d) loading bank [%s]", result, in_strBankName ) )
	end
	return result
end

--[[ ***********************
Load a File Package, per name.
***********************]]
-- Default package loading/unloading in Low-Level IO.
function AkLoadPackage( in_strPackageName )	-- Returns result, packageID
	return AkLoadPackageFromDevice( g_lowLevelIO["Default"], in_strPackageName )
end
-- in_uPackage can be either the string that was used to load it, or the ID returned by AkLoadPackageFromDevice
function AkUnloadPackage( in_uPackage )
	return AkUnloadPackageFromDevice( g_lowLevelIO["Default"], in_uPackage )
end

-- Internal: Wrappers for device::LoadFilePackage() and device::UnloadFilePackage()
function AkLoadPackageFromDevice( device, in_strPackageName )
	local result = 0
	local packageID = 0
	print( string.format( "Loading package [%s]...", in_strPackageName ) )
	result, packageID = device:LoadFilePackage( in_strPackageName )
	
	if (result == AK_Success or result == AK_InvalidLanguage) then
		print( string.format( "Successful. Returned ID=[%u]", packageID ) )
		if (result == AK_InvalidLanguage) then
			print( "Warning: Invalid language set with file package" )
		end
	else
		print( string.format( "Error loading file package [%s]", in_strPackageName ) )
	end		
	
	return result, packageID
end
-- in_uPackage can be either the string that was used to load it, or the ID returned by AkLoadPackageFromDevice
function AkUnloadPackageFromDevice( device, in_uPackage )
	device:UnloadFilePackage( in_uPackage )
end

--[[ ***********************
Unload a bank synchronously, per name.
***********************]]
function AkUnloadBank( in_strBankName )
	local bankID = 0
	local result = 0	
	
	result = AK.SoundEngine.UnloadBank( in_strBankName )
	if ( result ~= AK_Success ) then
		print( string.format( "Error unloading bank [%s]", in_strBankName ) )
	end
	return result
end

--[[ ***********************
Registers game objects in_nGameObjectStart to in_nGameObjectEnd
***********************]]
function AkRegisterGameObject( in_nGameObjectStart, in_nGameObjectEnd )
	for GO = in_nGameObjectStart, in_nGameObjectEnd do
		local result = AK.SoundEngine.RegisterGameObj( GO )
		if ( result ~= AK_Success) then
			print( string.format( "Error registering game object [%d]", GO ) )
		end
	end
end

--[[ ***********************
Unregisters game objects in_nGameObjectStart to in_nGameObjectEnd
***********************]]
function AkUnregisterGameObject( in_nGameObjectStart, in_nGameObjectEnd)
	for GO = in_nGameObjectStart, in_nGameObjectEnd do
		local result = AK.SoundEngine.UnregisterGameObj( GO )
		if ( result ~= AK_Success) then
			print( string.format( "Error unregistering game object [%d]", GO ) )
		end
	end
end

--[[**************************
New Soundbanks helpers "Asynchronous" variable: g_GlobalUnloadIdentifier
****************************]]
-- 1073741824 is the decimal nomination for 0x40000000 or 0b01000000000000000000000000000000
g_GlobalUnloadIdentifier = 10000 --1073741824

--[[**************************
New Soundbanks helpers "Asynchronous": GetCookie
****************************]]
function GetCookie( in_IsLoad, in_EventID )
	if( in_IsLoad == true ) then
		return in_EventID + g_GlobalUnloadIdentifier
	else
		return in_EventID
	end
end

--[[**************************
New Soundbanks helpers "Asynchronous": GetEventIDFromCookie
****************************]]
function GetEventIDFromCookie( in_Cookie )

	if( in_Cookie >= g_GlobalUnloadIdentifier ) then
		return in_Cookie - g_GlobalUnloadIdentifier
	else
		return in_Cookie
	end
end

--[[**************************
New Soundbanks helpers "Asynchronous": GetIsLoadFromCookie
****************************]]
function GetIsLoadFromCookie( in_Cookie )
	if( in_Cookie >= g_GlobalUnloadIdentifier ) then
		return true
	else
		return false
	end
end

--[[ ***********************
Lua callback for the PrepareEventAsync method
****************************]]
function PrepareEventCallBackFunction( in_EventID, in_eLoadStatus, in_cookie )
    
    local PreparedID = GetEventIDFromCookie( in_cookie )
    local ActionString
    local FailureString
    
    if( GetIsLoadFromCookie( in_cookie ) == true ) then
		ActionString = "prepared"
		FailureString = "prepare"
	else
		ActionString = "unprepared"
		FailureString = "unprepare"
	end
    
    if( in_eLoadStatus == AK_Success ) then
		print( string.format( "Successfully %s the Event identified as # %s", ActionString, PreparedID ) )
		if( GetIsLoadFromCookie(in_cookie) ) then
			g_PreparedEventMemory[PreparedID] = g_PreparedEventMemory[PreparedID] + 1
		else
			g_PreparedEventMemory[PreparedID] = g_PreparedEventMemory[PreparedID] - 1
		end
		
    else
		print( string.format( "Failed to %s the Event identified as # %s", FailureString, PreparedID ) )
    end
end

--[[ ***********************
Lua callback for the AkLoadBankAsync method
****************************]]
function AsyncLoadBankCallBackFunction ( in_bankID, in_MemoryPtr, in_eLoadStatus, in_memPoolId, in_cookie )
		
    local PreparedID = GetEventIDFromCookie( in_cookie )
    local ActionString
    local FailureString
    
    if( GetIsLoadFromCookie( in_cookie ) == true ) then
		ActionString = "loaded bank"
		FailureString = "loading bank"
	else
		ActionString = "unloaded bank"
		FailureString = "unloading bank"
	end

    if( in_eLoadStatus == AK_Success or in_eLoadStatus == AK_BankAlreadyLoaded) then
		print( string.format( "Successfully %s identified as # %s", ActionString, PreparedID ) )
		if( GetIsLoadFromCookie(in_cookie) ) then
			g_LoadBankMemory[PreparedID] = g_LoadBankMemory[PreparedID] + 1
		else
			g_LoadBankMemory[PreparedID] = g_LoadBankMemory[PreparedID] - 1
		end
		
    else
		print( string.format( "Error %s identified as # %s", FailureString, PreparedID ) )
    end
end


--[[ ***********************
Lua callback for the AkPrepareBankAsync method
****************************]]
function AkAsyncPrepareBankCallBackFunction ( in_bankID, in_MemoryPtr, in_eLoadStatus, in_memPoolId, in_cookie )

    local PreparedID = GetEventIDFromCookie( in_cookie )
    local ActionString
    local FailureString
    
    if( GetIsLoadFromCookie( in_cookie ) == true ) then
		ActionString = "prepared bank"
		FailureString = "preparing bank"
	else
		ActionString = "unprepared bank"
		FailureString = "unpreparing bank"
	end

    if( in_eLoadStatus == AK_Success ) then
		print( string.format( "Successfully %s identified as # %s", ActionString, PreparedID ) )
		if( GetIsLoadFromCookie(in_cookie) ) then
			g_PrepareBankMemory[PreparedID] = g_PrepareBankMemory[PreparedID] + 1
		else
			g_PrepareBankMemory[PreparedID] = g_PrepareBankMemory[PreparedID] - 1
		end
		
    else
		print( string.format( "Error %s identified as # %s", FailureString, PreparedID ) )
    end
end


--[[ ***********************
Lua callback for the PrepareGameSyncAsync method
****************************]]
function PrepareGameSyncCallBackFunction( in_eLoadStatus, in_cookie )

    local PreparedID = GetEventIDFromCookie( in_cookie )
    local ActionString
    local FailureString
    
    if( GetIsLoadFromCookie( in_cookie ) == true ) then
		ActionString = "prepared"
		FailureString = "prepare"
	else
		ActionString = "unprepared"
		FailureString = "unprepare"
	end
    
    if( in_eLoadStatus == AK_Success ) then
		print( string.format( "Successfully %s the Game Sync identified as # %s", ActionString, PreparedID ) )
		if( GetIsLoadFromCookie(in_cookie) ) then
			g_PreparedGameSyncEventMemory[PreparedID] = g_PreparedGameSyncEventMemory[PreparedID] + 1
		else
			g_PreparedGameSyncEventMemory[PreparedID] = g_PreparedGameSyncEventMemory[PreparedID] - 1
		end
		
    else
		print( string.format( "Failed to %s the Game Sync identified as # %s", FailureString, PreparedID ) )
    end
end

--[[ ***********************
Lua callback for the AkLoadPackageAsync method
Users must declare a g_PackageBankMemory table in their scripts.
****************************]]
function AsyncLoadPackageCallBackFunction( in_packageID, in_eLoadStatus, in_memPoolId, in_cookie )

    local PreparedID = GetEventIDFromCookie( in_cookie )
    local ActionString
    local FailureString
    
    if( GetIsLoadFromCookie( in_cookie ) == true ) then
		ActionString = "loaded package"
		FailureString = "loading package"
	else
		ActionString = "unloaded package"
		FailureString = "unloading package"
	end

    if( in_eLoadStatus == AK_Success or in_eLoadStatus == AK_InvalidLanguage ) then
		print( string.format( "Successfully %s identified as # %s", ActionString, PreparedID ) )
		if( GetIsLoadFromCookie(in_cookie) ) then
			g_PackageBankMemory[PreparedID] = g_PackageBankMemory[PreparedID] + 1
		else
			g_PackageBankMemory[PreparedID] = g_PackageBankMemory[PreparedID] - 1
		end
		
    else
		print( string.format( "Error %s identified as # %s", FailureString, PreparedID ) )
    end
end

--[[ ***********************
Prepare an Event asynchronously
****************************]]
function PrepareEventAsync( in_IsLoad, in_EventStringArray, in_NumStringInArray, in_UniqueIdentifier )
	local l_cookie = GetCookie( in_IsLoad, in_UniqueIdentifier )
	
	if( AkLuaGameEngine.IsOffline() ) then
		--When in offline mode, asynchronous preparation is indeed a problem...
		--Make it synchroneous,
		if( in_IsLoad ) then
			result = AK.SoundEngine.PrepareEvent (Preparation_Load, in_EventStringArray, in_NumStringInArray, in_NumStringInArray )
		else
			result = AK.SoundEngine.PrepareEvent (Preparation_Unload, in_EventStringArray, in_NumStringInArray, in_NumStringInArray )
		end
		
		-- Fake the callback, because the callback will not arrive by itself.
		PrepareEventCallBackFunction( DummyUnusedEventIT, result, l_cookie )
		
	else

		if( in_IsLoad ) then
			print( "Preparing the Event Async" )
			result = AK.SoundEngine.PrepareEvent( Preparation_Load, in_EventStringArray, in_NumStringInArray, "PrepareEventCallBackFunction", l_cookie )
		else
			print( "Unpreparing the Event Async" )
			result = AK.SoundEngine.PrepareEvent( Preparation_Unload, in_EventStringArray, in_NumStringInArray, "PrepareEventCallBackFunction", l_cookie )
		end
		
		if( result ~= AK_Success ) then
			print( "PrepareEvent failed. You may not have enough memory." )
		end
	
	end
end

--[[ ***********************
Load a bank asynchronously, per name.
****************************]]
function AkLoadBankAsync( in_IsLoad, in_BankName, in_UniqueIdentifier )
	local l_cookie = GetCookie( in_IsLoad, in_UniqueIdentifier )

	local resultLoad
	local bankIDLoad = 0
	if( in_IsLoad ) then
		print( "Loading the Bank Async" )
		resultLoad, bankIDLoad = AK.SoundEngine.LoadBank( in_BankName, "AsyncLoadBankCallBackFunction", l_cookie, AK_DEFAULT_POOL_ID, bankIDLoad )
	else
		print( "Unloading the Bank Async" )
		resultLoad = AK.SoundEngine.UnloadBank( in_BankName, "AsyncLoadBankCallBackFunction", l_cookie )
	end
	
	if( result ~= AK_Success ) then
		print( string.format( "Error loading bank [%s] Async. You may not have enough memory.",in_BankName ))
	end
end

--[[ ***********************
Prepare a Game Sync asynchronously, per name.
****************************]]
function PrepareGameSyncAsync( in_IsLoad, in_type, in_GroupName, in_GameSyncStringArray, in_NumStringInArray, in_UniqueIdentifier )

	if( AkLuaGameEngine.IsOffline() ) then
		--When in offline mode, asynchronous preparation is indeed a problem...
		--Make it synchroneous,
		if( in_IsLoad ) then
			result = AK.SoundEngine.PrepareGameSyncs (Preparation_Load, in_type, in_GroupName, in_GameSyncStringArray, in_NumStringInArray )
		else
			result = AK.SoundEngine.PrepareGameSyncs (Preparation_Unload, in_type, in_GroupName, in_GameSyncStringArray, in_NumStringInArray )
		end
		
		-- Fake the callback, because the callback will not arrive by itself.
		PrepareGameSyncCallBackFunction( result, GetCookie( in_IsLoad, in_UniqueIdentifier ) )
		
	else
		if( in_IsLoad ) then
			print( "Preparing the GameSync Async" )
			result = AK.SoundEngine.PrepareGameSyncs( Preparation_Load, in_type, in_GroupName ,in_GameSyncStringArray, in_NumStringInArray,"PrepareGameSyncCallBackFunction", GetCookie( in_IsLoad, in_UniqueIdentifier ) )
		else
			print( "Unpreparing the GameSync Async" )
			result = AK.SoundEngine.PrepareGameSyncs( Preparation_Unload, in_type, in_GroupName ,in_GameSyncStringArray, in_NumStringInArray,"PrepareGameSyncCallBackFunction", GetCookie( in_IsLoad, in_UniqueIdentifier ) )
		end

		if( result ~= AK_Success ) then
			print( "PrepareGameSync Async failed. You may not have enough memory." )
		end
	end
end


--[[ ***********************
Prepare a Bank asynchronously, per name.
****************************]]
function AkPrepareBankAsync( in_IsLoad,  in_BankName, in_AllOrStructureOnly, in_UniqueIdentifier )

AkCheckParameters (4, (debug.getinfo(1,"n").name), in_IsLoad,  in_BankName, in_AllOrStructureOnly, in_UniqueIdentifier)
	
		if( in_IsLoad ) then
			print( "Preparing the Bank Async" )
			result = AK.SoundEngine.PrepareBank( Preparation_Load,  in_BankName, "AkAsyncPrepareBankCallBackFunction", GetCookie( in_IsLoad, in_UniqueIdentifier ), in_AllOrStructureOnly  )
		else
			print( "Unpreparing the Bank Async" )
			result = AK.SoundEngine.PrepareBank( Preparation_Unload, in_BankName, "AkAsyncPrepareBankCallBackFunction", GetCookie( in_IsLoad, in_UniqueIdentifier ), in_AllOrStructureOnly )
		end

		if( result ~= AK_Success ) then
			print( "Prepare Bank Async failed. You may not have enough memory." )
		end

end

--[[ ***********************
Load/unload a file package asynchronously, per name.
NOTE: Only a specific set of devices (like g_lowLevelIO["RSX"]) support asynchronous loading.
****************************]]
function AkLoadPackageAsync( device, in_IsLoad, in_PckName, in_UniqueIdentifier )
	local l_cookie = GetCookie( in_IsLoad, in_UniqueIdentifier )

	local resultLoad
	local pckIDLoad = 0
	if( in_IsLoad ) then
		print( "Loading the Package Async" )
		resultLoad, pckIDLoad = device:LoadFilePackage( in_PckName, "AsyncLoadPackageCallBackFunction", l_cookie, AK_DEFAULT_POOL_ID, false, pckIDLoad )
	else
		print( "Unloading the Bank Async" )
		resultLoad = device:UnloadFilePackage( in_PckName, "AsyncLoadPackageCallBackFunction", l_cookie )
	end
	
	if( result ~= AK_Success ) then
		print( string.format( "Error loading package [%s] Async. You may not have enough memory.",in_PckName ))
	end
end

--[[ ***********************
The method will verify that the correct amount of parameters is assigned to the function.
****************************]]
function AkCheckParameters(in_NumberOfParameters, in_FunctionName, in_Param1, in_Param2, in_Param3, in_Param4, in_Param5, in_Param6, in_Param7, in_Param8, in_Param9, in_Param10)

	if(in_NumberOfParameters > 0) then
		if (in_Param1 == nil) then
			print (">>> ERROR in " .. in_FunctionName)
			print (">>> Missing or Invalid Parameter.")
		end
	end

	if(in_NumberOfParameters > 1) then
		if (in_Param2 == nil) then
			print (">>> ERROR in " .. in_FunctionName)
			print (">>> Missing or Invalid Parameter.")
		end
	end

	if(in_NumberOfParameters > 2) then
		if (in_Param3 == nil) then
			print (">>> ERROR in " .. in_FunctionName)
			print (">>> Missing or Invalid Parameter.")
		end
	end
	
	if(in_NumberOfParameters > 3) then
		if (in_Param4 == nil) then
			print (">>> ERROR in " .. in_FunctionName)
			print (">>> Missing or Invalid Parameter.")
		end
	end
	
	if(in_NumberOfParameters > 4) then
		if (in_Param5 == nil) then
			print (">>> ERROR in " .. in_FunctionName)
			print (">>> Missing or Invalid Parameter.")
		end
	end
	
	if(in_NumberOfParameters > 5) then
		if (in_Param6 == nil) then
			print (">>> ERROR in " .. in_FunctionName)
			print (">>> Missing or Invalid Parameter.")
		end
	end

	if(in_NumberOfParameters > 6) then
		if (in_Param7 == nil) then
			print (">>> ERROR in " .. in_FunctionName)
			print (">>> Missing or Invalid Parameter.")
		end
	end

	if(in_NumberOfParameters > 7) then
		if (in_Param8 == nil) then
			print (">>> ERROR in " .. in_FunctionName)
			print (">>> Missing or Invalid Parameter.")
		end
	end
	
	if(in_NumberOfParameters > 8) then
		if (in_Param9 == nil) then
			print (">>> ERROR in " .. in_FunctionName)
			print (">>> Missing or Invalid Parameter.")
		end
	end
	
	if(in_NumberOfParameters > 9) then
		if (in_Param10 == nil) then
			print (">>> ERROR in " .. in_FunctionName)
			print (">>> Missing or Invalid Parameter.")
		end
	end
	
end

--This is a table of tables.  It will contain the parameters for each function as well as the function
g_GameTickCalls = {}

-- Use this function to add a call that should be made each tick
-- The routine can receive parameters.  The parameters must be defined in pairs: a string name and the actual value of the parameter
-- This returns the index of the routine in the call order.
-- See the example with AkRampRTPC below
function AkRegisterGameTickCall(in_routine, ...)
	local index = #g_GameTickCalls + 1
	local newCallTable = {}
	newCallTable._Func = in_routine
	newCallTable._Index = index
	
	--Iterate over the extra arguments (the parameters of the target function)
	for n=1,select('#',...),2 do
		local paramName = select(n,...)
		local paramValue = select(n+1,...)
		newCallTable[paramName] = paramValue
	end	
	
	g_GameTickCalls[index] = newCallTable	
	return index
end

-- Unregisters a game tick call
-- See example in AkRampRTPCTick
function AkUnregisterGameTickCall(index)
	table.remove(g_GameTickCalls, index)
end

-- Removes all tick calls
function AkClearAllGameTickCalls()
	g_GameTickCalls = {}
end

-- This is the function that does the actual work of setting the RTPC for the AkRampRTPC functionality
-- It is called at each tick.  Do not call this function directly.  
function AkRampRTPCTick(params)	
	AK.SoundEngine.SetRTPCValue(params.Name, params.Value, params.Object)
	
	--Increment the value for the next call
	params.Value = params.Value + params.Inc
	
	--If we finished ramping, remove the call
	if ( params.Inc > 0 ) then
    	if (params.Value > params.Stop) then				
	   	   AkUnregisterGameTickCall(params._Index)
	   end		
	else
		if ( params.Value < params.Stop ) then
			AkUnregisterGameTickCall(params._Index)
		end
	end		
end

-- Use this function to start a ramp of a RTPC.  
-- Parameters: 
-- RTPC_Name: the name of the RTPC as defined in the Wwise project
-- StartValue: the initial value of the RTPC
-- StopValue : the target value of the RTPC
-- Time: the time over which the value will change.
-- GameObj: the gameobject id.  (Optional. Default is g_AkDefaultGameObject)
function AkRampRTPC(in_RTPC_Name, in_StartValue, in_StopValue, in_Time, in_GameObj)
	--Compute the increment we will need for each tick
	local increment = 1
	if AkLuaGameEngine.IsOffline() then
		increment = (in_StopValue - in_StartValue)/(in_Time/AK_AUDIOBUFFERMS)
	else
		increment = (in_StopValue - in_StartValue)/(in_Time *kFramerate /1000)	
	end
	
	if(in_GameObj == nil) then
		in_GameObj = g_AkDefaultGameObject
	end
	
	AkRegisterGameTickCall(AkRampRTPCTick, 
		"Name", in_RTPC_Name, 		
		"Value", in_StartValue, 
		"Stop", in_StopValue, 
		"Inc", increment,
		"Object", in_GameObj)
end



function AkSetListenerPosition(ListenerID, x, y)
	local listenerPos = AkListenerPosition:new_local() 
	listenerPos.OrientationFront.X = 0
	listenerPos.OrientationFront.Y = 0
	listenerPos.OrientationFront.Z = 1

	listenerPos.OrientationTop.X = 0 
	listenerPos.OrientationTop.Y = 1 -- head is up
	listenerPos.OrientationTop.Z = 0 

	--Set starting position
	listenerPos.Position.X = x
	listenerPos.Position.Y = 0 
	listenerPos.Position.Z = y
	AK.SoundEngine.SetListenerPosition(listenerPos, ListenerID)
end

function AkSetGameObjectPosition(ObjID, x, y, ox, oy)
	local soundPos = AkSoundPosition:new_local() 
 
	soundPos.Position.X = x
	soundPos.Position.Y = 0
	soundPos.Position.Z = y

	if (ox ~= nil and oy ~= nil) then
		soundPos.Orientation.X = ox
		soundPos.Orientation.Y = 0
		soundPos.Orientation.Z = oy
	else
		--Pointing toward the Y axis (in 2D)
		soundPos.Orientation.X = 0 
		soundPos.Orientation.Y = 0
		soundPos.Orientation.Z = 1
	end
		
	AK.SoundEngine.SetPosition( ObjID, soundPos )
end

function AkMoveListenerOnPathTick(params)	
	
	function GetX(in_params)			
		return in_params.Path[(in_params.Target-1) *3 + 1]
	end
	function GetY(in_params)
		return in_params.Path[(in_params.Target-1) *3 + 2]
	end
	function GetTime(in_params)
		return in_params.Path[(in_params.Target-1) *3 + 3] * kFramerate /1000		
	end	
	
	if (math.abs(params.Pos.Position.X - GetX(params, params.Target)) < 0.01) then
		--Make sure we're on the target point
		params.Pos.Position.X = GetX(params)
		params.Pos.Position.Z = GetY(params)
		AK.SoundEngine.SetListenerPosition(params.Pos, params.Listener)
		
		--We have finished this segment of the path.  Compute the next segment		
		params.Target = params.Target + 1
		if (params.Target > table.maxn(params.Path) / 3) then
			--This is the end of the path.  
			AkUnregisterGameTickCall(params._Index)
			return
		end
		
		params.xInc = (GetX(params) - params.Pos.Position.X) / GetTime(params)
		params.yInc = (GetY(params) - params.Pos.Position.Y) / GetTime(params)
	else
		AK.SoundEngine.SetListenerPosition(params.Pos, params.Listener)
	end
	
	
	--Compute next position
	params.Pos.Position.X = params.Pos.Position.X + params.xInc
	params.Pos.Position.Z = params.Pos.Position.Z + params.yInc
end

-- Moves a listener object along the given path
-- Params:
-- ListenerID: the listener to move
-- PathArray: Array of points and timing in the form of {x, y, time}.  You must have a multiple of 3 entries in the array
-- See AkMoveListenerOnLine for an example
function AkMoveListenerOnPath(ListenerID, PathArray)		
	assert(#PathArray % 3 == 0, "PathArray must have 3 numbers per point: x, y, time")
	local listenerPos = AkListenerPosition:new_local() 
	listenerPos.OrientationFront.X = 0
	listenerPos.OrientationFront.Y = 0
	listenerPos.OrientationFront.Z = 1

	listenerPos.OrientationTop.X = 0 
	listenerPos.OrientationTop.Y = 1 -- head is up
	listenerPos.OrientationTop.Z = 0 

	--Set starting position	
	listenerPos.Position.X = PathArray[1]
	listenerPos.Position.Y = 0 
	listenerPos.Position.Z = PathArray[2] 	
	AkRegisterGameTickCall(AkMoveListenerOnPathTick,
		"Listener", ListenerID,
		"Pos", listenerPos,
		"Path", PathArray,
		"Target", 1)
end

function AkMoveListenerOnLine(ListenerID, x1, y1, x2, y2, Time)
	 local path ={
		x1,y1,0,
		x2,y2,Time}	
	AkMoveListenerOnPath(ListenerID, path)	
end

function AkMoveListenerOnArcTick(params)
	
	if (math.abs(params.Angle - params.Stop) < 0.001) then
		--Make sure we're on the target point
		params.Pos.Position.X = params.Radius * math.cos(params.Stop)
		params.Pos.Position.Z = params.Radius * math.sin(params.Stop)
		AK.SoundEngine.SetListenerPosition(params.Pos, params.Listener)
				
		--This is the end of the arc
		AkUnregisterGameTickCall(params._Index)
		return
		
	else
		params.Pos.Position.X = params.Radius * math.cos(params.Angle)
		params.Pos.Position.Z = params.Radius * math.sin(params.Angle)		
		AK.SoundEngine.SetListenerPosition(params.Pos, params.Listener)
	end
	
	--Compute next position
	params.Angle = params.Angle + params.Inc	
end

--Moves a listener on a circle arc
--Parameters
--ListenerID: the listener to move
--Radius: the radius of the arc
--StartAngle: the angle where the listener starts (front is 0, back is 180)
--StopAngle: the target angle
--Time: the time it takes to go from StartAngle to StopAngle
function AkMoveListenerOnArc(ListenerID, Radius, StartAngle, StopAngle, Time)
	--Convert degrees in radians
	StartAngle = (StartAngle-90) * math.pi / 180
	StopAngle = (StopAngle-90) * math.pi / 180
	
	local listenerPos = AkListenerPosition:new_local() 
	listenerPos.OrientationFront.X = 0
	listenerPos.OrientationFront.Y = 0
	listenerPos.OrientationFront.Z = 1

	listenerPos.OrientationTop.X = 0 
	listenerPos.OrientationTop.Y = 1 -- head is up
	listenerPos.OrientationTop.Z = 0 

	--Set starting position	
	listenerPos.Position.X = Radius * math.cos(StartAngle)
	listenerPos.Position.Y = 0 
	listenerPos.Position.Z = Radius * math.sin(StartAngle)	
	
	local increment = 1
	if AkLuaGameEngine.IsOffline() then
		increment = (StopAngle-StartAngle) / (Time/AK_AUDIOBUFFERMS)
	else
		increment = (StopAngle-StartAngle) / (Time * kFramerate / 1000)		
	end
	
	AkRegisterGameTickCall(AkMoveListenerOnArcTick,
		"Listener", ListenerID,
		"Pos", listenerPos,
		"Radius", Radius,
		"Angle", StartAngle,
		"Stop", StopAngle,
		"Inc", increment)		
end

function AkTurnListenerTick(params)
	
	if (math.abs(params.Angle - params.Stop) < 0.001) then
		--Make sure we're on the target point
		params.Pos.OrientationFront.X = math.cos(params.Stop)		
		params.Pos.OrientationFront.Z = math.sin(params.Stop)		
		AK.SoundEngine.SetListenerPosition(params.Pos, params.Listener)
				
		--This is the end of the arc
		AkUnregisterGameTickCall(params._Index)
		return		
	else
		params.Pos.OrientationFront.X = math.cos(params.Angle)
		params.Pos.OrientationFront.Z = math.sin(params.Angle)		
		AK.SoundEngine.SetListenerPosition(params.Pos, params.Listener)
	end
	
	--Compute next position
	params.Angle = params.Angle + params.Inc	
end

--Rotates the orientation of a listener
--Parameters
--ListenerID: the listener to move
--StartAngle: the angle where the listener starts (front is 0, back is 180)
--StopAngle: the target angle
--Time: the time it takes to go from StartAngle to StopAngle
function AkTurnListener(ListenerID, StartAngle, StopAngle, Time)
	--Convert degrees in radians
	StartAngle = (StartAngle+90) * math.pi / 180
	StopAngle = (StopAngle+90) * math.pi / 180
	
	local listenerPos = AkListenerPosition:new_local() 
	listenerPos.OrientationFront.X = math.cos(StartAngle)
	listenerPos.OrientationFront.Y = 0
	listenerPos.OrientationFront.Z = math.sin(StartAngle)

	listenerPos.OrientationTop.X = 0 
	listenerPos.OrientationTop.Y = 1 -- head is up
	listenerPos.OrientationTop.Z = 0 

	--Set starting position	
	listenerPos.Position.X = 0
	listenerPos.Position.Y = 0 
	listenerPos.Position.Z = 0
	
	local increment = 1
	if AkLuaGameEngine.IsOffline() then
		increment = (StopAngle-StartAngle) / (Time/AK_AUDIOBUFFERMS)
	else
		increment = (StopAngle-StartAngle) / (Time * kFramerate / 1000)		
	end
	
	AkRegisterGameTickCall(AkTurnListenerTick,
		"Listener", ListenerID,
		"Pos", listenerPos,		
		"Angle", StartAngle,
		"Stop", StopAngle,
		"Inc", increment)	
end

function AkMoveGameObjectOnPathTick(params)	
	
	function GetX(in_params)			
		return in_params.Path[(in_params.Target-1) *3 + 1]
	end
	function GetY(in_params)
		return in_params.Path[(in_params.Target-1) *3 + 2]
	end
	function GetTime(in_params)
		return in_params.Path[(in_params.Target-1) *3 + 3] * kFramerate /1000
	end	
	
	if (math.abs(params.Pos.Position.X - GetX(params, params.Target)) < 0.01) then
		--Make sure we're on the target point
		params.Pos.Position.X = GetX(params)
		params.Pos.Position.Z = GetY(params)
		AK.SoundEngine.SetPosition(params.GameObject, params.Pos)
		
		--We have finished this segment of the path.  Compute the next segment		
		params.Target = params.Target + 1
		if (params.Target > table.maxn(params.Path) / 3) then
			--This is the end of the path.  
			AkUnregisterGameTickCall(params._Index)
			return
		end
		
		params.xInc = (GetX(params) - params.Pos.Position.X) / GetTime(params)
		params.yInc = (GetY(params) - params.Pos.Position.Y) / GetTime(params)
	else
		AK.SoundEngine.SetPosition(params.GameObject, params.Pos)
	end
	
	
	--Compute next position
	params.Pos.Position.X = params.Pos.Position.X + params.xInc
	params.Pos.Position.Z = params.Pos.Position.Z + params.yInc
end

-- Moves a GameObject object along the given path
-- Params:
-- PathArray: Array of points and timing in the form of {x, y, time}.  You must have a multiple of 3 entries in the array
-- GameObjectID: the GameObject to move (optional.  Default is g_AkDefaultObject)
-- See AkMoveGameObjectOnLine for an example
function AkMoveGameObjectOnPath(PathArray, GameObjectID)	
	assert(#PathArray % 3 == 0, "PathArray must have 3 numbers per point: x, y, time")
	local GameObjectPos = AkSoundPosition:new_local() 
	GameObjectPos.Orientation.X = 0
	GameObjectPos.Orientation.Y = 0
	GameObjectPos.Orientation.Z = 1

	--Set starting position	
	GameObjectPos.Position.X = PathArray[1]
	GameObjectPos.Position.Y = 0 
	GameObjectPos.Position.Z = PathArray[2] 	
	
	if ( GameObjectID == nil ) then		
		GameObjectID = g_AkDefaultGameObject
	end
	
	AkRegisterGameTickCall(AkMoveGameObjectOnPathTick,
		"GameObject", GameObjectID,
		"Pos", GameObjectPos,
		"Path", PathArray,
		"Target", 1)
end

function AkMoveGameObjectOnLine(x1, y1, x2, y2, Time, GameObjectID)
	 local path ={
		x1,y1,0,
		x2,y2,Time}	
	AkMoveGameObjectOnPath(path, GameObjectID)	
end

function AkMoveGameObjectOnArcTick(params)
	
	if (math.abs(params.Angle - params.Stop) < 0.001) then
		--Make sure we're on the target point
		params.Pos.Position.X = params.Radius * math.cos(params.Stop)
		params.Pos.Position.Z = params.Radius * math.sin(params.Stop)
		AK.SoundEngine.SetPosition(params.GameObject, params.Pos)
				
		--This is the end of the arc
		AkUnregisterGameTickCall(params._Index)
		return
		
	else
		params.Pos.Position.X = params.Radius * math.cos(params.Angle)
		params.Pos.Position.Z = params.Radius * math.sin(params.Angle)		
		AK.SoundEngine.SetPosition(params.GameObject, params.Pos)
	end
	
	--Compute next position
	params.Angle = params.Angle + params.Inc	
end

--Moves a GameObject on a circle arc
--Parameters
--Radius: the radius of the arc
--StartAngle: the angle where the GameObject starts (front is 0, back is 180)
--StopAngle: the target angle
--Time: the time it takes to go from StartAngle to StopAngle
-- GameObjectID: the GameObject to move (optional.  Default is g_AkDefaultObject)
function AkMoveGameObjectOnArc(Radius, StartAngle, StopAngle, Time, GameObjectID)

	if ( GameObjectID == nil ) then
		GameObjectID = g_AkDefaultGameObject
	end
	
	--Convert degrees in radians
	StartAngle = (StartAngle-90) * math.pi / 180
	StopAngle = (StopAngle-90) * math.pi / 180
	
	local GameObjectPos = AkSoundPosition:new_local() 
	GameObjectPos.Orientation.X = 0
	GameObjectPos.Orientation.Y = 0
	GameObjectPos.Orientation.Z = 1	

	--Set starting position	
	GameObjectPos.Position.X = Radius * math.cos(StartAngle)
	GameObjectPos.Position.Y = 0 
	GameObjectPos.Position.Z = Radius * math.sin(StartAngle)

	local increment = 1
	if AkLuaGameEngine.IsOffline() then
		increment = (StopAngle-StartAngle) / (Time/AK_AUDIOBUFFERMS)
	else
		increment = (StopAngle-StartAngle) / (Time * kFramerate / 1000)		
	end	
	
	AkRegisterGameTickCall(AkMoveGameObjectOnArcTick,
		"GameObject", GameObjectID,
		"Pos", GameObjectPos,
		"Radius", Radius,
		"Angle", StartAngle,
		"Stop", StopAngle,
		"Inc", increment)		
end

function AkTurnGameObjectTick(params)
	
	if (math.abs(params.Angle - params.Stop) < 0.001) then
		--Make sure we're on the target point
		params.Pos.Orientation.X = math.cos(params.Stop)		
		params.Pos.Orientation.Z = math.sin(params.Stop)		
		AK.SoundEngine.SetPosition(params.GameObject, params.Pos)
				
		--This is the end of the arc
		AkUnregisterGameTickCall(params._Index)
		return		
	else
		params.Pos.Orientation.X = math.cos(params.Angle)
		params.Pos.Orientation.Y = math.sin(params.Angle)		
		AK.SoundEngine.SetPosition(params.GameObject, params.Pos)
	end
	
	--Compute next position
	params.Angle = params.Angle + params.Inc	
end

--Rotates the orientation of a GameObject
--Parameters
--StartAngle: the angle where the GameObject starts (front is 0, back is 180)
--StopAngle: the target angle
--Time: the time it takes to go from StartAngle to StopAngle
-- GameObjectID: the GameObject to move (optional.  Default is g_AkDefaultObject)
function AkTurnGameObject(StartAngle, StopAngle, Time, GameObjectID)
	
	if ( GameObjectID == nil ) then
		GameObjectID = g_AkDefaultGameObject
	end
	
	--Convert degrees in radians
	StartAngle = (StartAngle-90) * math.pi / 180
	StopAngle = (StopAngle-90) * math.pi / 180
	
	local GameObjectPos = AkSoundPosition:new_local() 
	GameObjectPos.Orientation.X = math.cos(StartAngle)
	GameObjectPos.Orientation.Y = 0
	GameObjectPos.Orientation.Z = math.sin(StartAngle)

	--Set starting position	
	GameObjectPos.Position.X = 0
	GameObjectPos.Position.Y = 0 
	GameObjectPos.Position.Z = 0
	
	local increment = 1
	if AkLuaGameEngine.IsOffline() then
		increment = (StopAngle-StartAngle) / (Time/AK_AUDIOBUFFERMS)
	else
		increment = (StopAngle-StartAngle) / (Time * kFramerate / 1000)		
	end
	
	AkRegisterGameTickCall(AkTurnGameObjectTick,
		"GameObject", GameObjectID,
		"Pos", GameObjectPos,		
		"Angle", StartAngle,
		"Stop", StopAngle,
		"Inc", increment)	
end

-- PRIVATE
-- Required by AkWaitUntilEventIsFinished
function AkHandleEndOfEventCallback( in_callbackType, in_data )
	if (in_callbackType == AK_EndOfEvent) then
		g_eventFinished = true
    end
end

-- Wait until an event fired with appropriate EndOfEvent callback
-- Often to be used in conjunction with  AkPlayEventUntilDone
function AkWaitUntilEventIsFinished()
	g_eventFinished = false
	while( not( g_eventFinished )) do
		if ( AkLuaGameEngine.IsOffline()) then
			AkGameTick()
		else
			coroutine.yield()
		end
	end
end

-- Wait until an event fired with appropriate EndOfEvent callback, but wait for a maximum of X millisecond
-- in_delayTime: Maximum time the function waits (in milliseconds)
function AkWaitUntilEventIsFinishedMaxDuration(in_delayTime)  
	g_eventFinished = false
	if ( not AK_LUA_RELEASE ) and ( AkLuaGameEngine.IsOffline() ) then		
		local numIter = in_delayTime/AK_AUDIOBUFFERMS				
		while (( numIter > 0 ) and (not( g_eventFinished ))) do			
			numIter = numIter - 1
			InternalGameTick()
		end
	else
		testStartTime = os.gettickcount()
		while(( os.gettickcount() - testStartTime < in_delayTime ) and (not( g_eventFinished ))) do
			if ( AkLuaGameEngine.IsOffline()) then
				AkGameTick()
			else
				coroutine.yield()
			end
		end
	end
end

-- Playback of an event using the end of event callback to block process until the event has finished playing
-- Parameters: 
-- PlayEventName: the name of the playback event to trigger
-- GameObj: the gameobject id, automatically registering and unregistering default game object if not specified
-- in_maxDuration: default is nil, the maximum time it waits (in milliseconds)
function AkPlayEventUntilDone( in_PlayEventName, in_GameObj, in_maxDuration )
	-- Default values
	in_GameObj = in_GameObj or g_AkDefaultGameObject
	
	playingID = AK.SoundEngine.PostEvent(in_PlayEventName, in_GameObj, AK_EndOfEvent,"AkHandleEndOfEventCallback",0)
	if( playingID ~= AK_INVALID_PLAYING_ID ) then
		if( in_maxDuration == nil ) then
			AkWaitUntilEventIsFinished()
		else
			AkWaitUntilEventIsFinishedMaxDuration( in_maxDuration )
			AK.SoundEngine.ExecuteActionOnEvent( in_PlayEventName, AkActionOnEventType_Stop, in_GameObj, 0, AkCurveInterpolation_Linear )
			Wait(100)
		end
	else
		print("AK.SoundEngine.PostEvent failed for event:" .. in_PlayEventName)
	end
end


-- Playback of an event for a certain duration while activating the sound engine capture output function
-- Parameters: 
-- PlayEventName: the name of the playback event to trigger
-- WAVfilename: Name of the WAV file to capture
-- GameObj: the gameobject id, automatically registering and unregistering default game object if not specified
function AkPlayAndRecordWAV( in_PlayEventName, in_WAVfilename, in_GameObj )
	if ( in_GameObj == nil ) then
		in_GameObj = g_AkDefaultGameObject
	end
	AkStartOutputCapture( in_WAVfilename )
	AK.SoundEngine.PostEvent(in_PlayEventName, in_GameObj, AK_EndOfEvent,"AkHandleEndOfEventCallback",0)
	AkWaitUntilEventIsFinished()
	AkStopOutputCapture( )
end

-- Playback of an event for a certain duration
-- Parameters: 
-- PlayEventName: the name of the playback event to trigger
-- Duration: Time (in ms) to play the sound for
-- GameObj: the gameobject id, automatically registering and unregistering default game object if not specified
function AkPlayForDuration( in_PlayEventName, in_Duration, in_GameObj )
	if ( in_GameObj == nil ) then
		in_GameObj = g_AkDefaultGameObject
	end
	AK.SoundEngine.PostEvent(in_PlayEventName, in_GameObj)
	Wait( in_Duration )
	AK.SoundEngine.ExecuteActionOnEvent( in_PlayEventName, AkActionOnEventType_Stop, in_GameObj, 0, AkCurveInterpolation_Linear )
end

-- Wraps an event in performance monitoring calls and dump performance metrics
-- Parameters: 
-- PlayEventName: the name of the playback event to trigger
-- PerfBenchMetricName: Name of the metrics statistic to output 
-- Duration: Time (in ms) to play the sound for
-- GameObj: the gameobject id, automatically registering and unregistering default game object if not specified
function AkPerfBenchEvent( in_PlayEventName, in_PerfBenchMetricName, in_Duration, in_GameObj )
	if ( in_GameObj == nil ) then
		in_GameObj = g_AkDefaultGameObject
	end
	AK.SoundEngine.PostEvent(in_PlayEventName, in_GameObj)
	Wait(1000)
	AkLuaGameEngine.StartPerfMon()
	Wait( in_Duration )
	AkLuaGameEngine.StopPerfMon()
	AkLuaGameEngine.DumpMetrics( in_PerfBenchMetricName )
	Wait(1000)
	AK.SoundEngine.StopAllObsolete()
end

-- Playback of a given number of instances of an event for a certain duration
-- Parameters: 
-- PlayEventName: the name of the playback event to trigger
-- PerfBenchMetricName: Name of the metrics statistic to output 
-- Duration: Time (in ms) to play the sound for
-- NumberOfEventsToPost: Repeat event this many times on same game object
-- GameObj: the gameobject id, automatically registering and unregistering default game object if not specified
function AkPlayNEventsForDuration( in_PlayEventName, in_Duration, in_NumberOfEventsToPost, in_GameObj )
	if ( in_GameObj == nil ) then
		in_GameObj = g_AkDefaultGameObject
	end
	for i = 0, in_NumberOfEventsToPost-1 do		
		AK.SoundEngine.PostEvent(in_PlayEventName, in_GameObj)
	end	
	Wait( in_Duration )
	AK.SoundEngine.ExecuteActionOnEvent( in_PlayEventName, AkActionOnEventType_Stop, AK_INVALID_GAME_OBJECT, 0, AkCurveInterpolation_Linear )
end

function AkGetCombinationString(...)
	local str = ""
	for n=1,select('#',...) do
		str = str .. "_" .. tostring(select(n,...))
	end	
	return str
end

--[[
	--Generate the array of tests with the given variables and routines.
	--Define all your variables and their possibilities.
	--They can be strings, numbers or any other lua type you wish.
	g_ChannelsPossibilities = {"0_1", "1_0", "1_1", "2_0", "2_1", "4_0", "5_1"}
	g_TypePossibilities = {"SFX", "Music"}

	--Define your test functions that will be called as coroutines
	--They must have one parameter.  This parameter is an array for all the variables you defined (Channels and Type in this example)
	function StartVirtualTest(inVariables)
		local inChannels = inVariables[1]	-- the Channels is the first item because we put it first in AkGenerateRoutinesWithPermutations
		local inType = inVariables[2]		-- the Type is the second item because we put it second in AkGenerateRoutinesWithPermutations
		
		print("StartVirtualTest "..AkGetCombinationString(inVariables))
	end	

	function BecomeVirtualTest(inVariables)
		local inChannels = inVariables[1]	-- the Channels is the first item because we put it first in AkGenerateRoutinesWithPermutations
		local inType = inVariables[2]		-- the Type is the second item because we put it second in AkGenerateRoutinesWithPermutations
		
		print("BecomeVirtualTest"..AkGetCombinationString(inVariables))
	end	

	--Call AkGenerateRoutinesWithPermutations
	AkGenerateRoutinesWithPermutations(g_ChannelsPossibilities, g_TypePossibilities, StartVirtualTest, BecomeVirtualTest)	
	--Could also be written this way:
	--AkGenerateRoutinesWithPermutations({"0_1", "1_0", "1_1", "2_0", "2_1", "4_0", "5_1"}, {"SFX", "Music"}, StartVirtualTest, BecomeVirtualTest)	
	--This will generate 28 CoRoutines.  StartVirtualTest and BecomeVirtualTest will be called for each permutation of the parameters (7 channels and SFX or Music)
--]]
function AkGenerateRoutinesWithPermutations(...)

	local Combinations = {}
	Combinations.Variables = {}
	Combinations.Routines = {}	
	
	local expected = 1	--Compute how many calls we will do	
	
	--Go through all the parameters and sort them between the Variables and Routines
	for n=1,select('#',...) do
		local param = select(n,...)
		if param ~= nil then		
			if type(param) == "function" then
				table.insert(Combinations.Routines, param)
			else
				table.insert(Combinations.Variables, param)
				Combinations.Variables[#Combinations.Variables].Counter = 1	--Init the counter to the first possibility			
				expected = expected * #Combinations.Variables[#Combinations.Variables] --Compute how many calls we will do
			end
		end
	end
		
	expected = expected * #Combinations.Routines
			
	local finished = 0
	--Always increment the last variable first
	
	while(finished < expected) do
				
		--Build the parameter array with all the current values
		local currentStr = ""
		local values = {}
		for var=1, #Combinations.Variables do		
			local varTable = Combinations.Variables[var]
			values[var] = varTable[varTable.Counter]
			currentStr = currentStr .. "_" .. tostring(values[var])
		end
		for routine=1,#Combinations.Routines do		
			finished = finished + 1			
			
			--Create a test routine entry (see CoHandleTests and TransformTestArray for the structure)
			local entry = {}
			entry.Name = FindFunctionNameInGlobalTable(Combinations.Routines[routine]) .. currentStr
			entry.Func = Combinations.Routines[routine]
			entry.Params = values			
			table.insert(g_TestTable, entry)
		end
					
		--Find the next permutation
		--Always increment the last variable first		
		local lastIndex = #Combinations.Variables		
		local currentVar = Combinations.Variables[lastIndex]
		currentVar.Counter = currentVar.Counter + 1	
		while lastIndex > 1 and currentVar.Counter > #currentVar do						
			--Reached the last possibility on that variable.  Go to next variable and restart
			currentVar.Counter = 1
			lastIndex = lastIndex - 1						
			currentVar = Combinations.Variables[lastIndex]	
			currentVar.Counter = currentVar.Counter + 1			
		end	
	end	
end


-- ****************
-- Global variables: overwrite these in your Lua script if you want to use other values
-- ****************
-- Tables to remember button presses
kButtonsCurrentlyDown = { }

-- Desired framerate (frames/s)
kFramerate = 30

-- Leave time to connect to Wwise?
kConnectToWwise = true
kTimeToConnect = 5000 -- milliseconds

-- **********************************************************************
-- Global stuff.  This section is always executed.
-- **********************************************************************

-- Functions can automatically register/unregister game object if not specified
g_AkDefaultGameObject = 999999999
g_MemTest = false

-- initialize g_testName only if not nitialized in main test script. This is done in order not to break old scripts.
if g_testName == nil then
	g_testName = {}	
end

-- **********************************************************************
-- This dictionary is needed for the QA automated tests to work properly.
-- **********************************************************************

--Platform string name dictionary
if AK_PLATFORM_PC then
AK_PLATFORM_NAME = "Windows"
kButtonNameMapping = 
{ 
AK_GAMEPAD_BUTTON_01 = "1 / A",
AK_GAMEPAD_BUTTON_02 = "2 / B", 
AK_GAMEPAD_BUTTON_03 = "3 / X", 
AK_GAMEPAD_BUTTON_04 = "4 / Y", 
AK_GAMEPAD_BUTTON_05 = "5 / Left shoulder", 
AK_GAMEPAD_BUTTON_06 = "6 / Right shoulder", 
AK_GAMEPAD_BUTTON_07 = "7 / Back", 
AK_GAMEPAD_BUTTON_08 = "8 / Start", 
AK_GAMEPAD_BUTTON_09 = "9 / Left thumb down", 
AK_GAMEPAD_BUTTON_10 = "0 / Right thumb down", 
AK_GAMEPAD_BUTTON_11 = "F1 / Directional pad up", 
AK_GAMEPAD_BUTTON_12 = "F2 / Directional pad right", 
AK_GAMEPAD_BUTTON_13 = "F3 / Directional pad down", 
AK_GAMEPAD_BUTTON_14 = "F4 / Directional pad left", 
AK_GAMEPAD_BUTTON_15 = "F5 / 'N/A'", 
AK_GAMEPAD_BUTTON_16 = "F6 / 'N/A'",
AK_HOME_BUTTON = "Home",
AK_GAMEPAD_ANALOG_01 = "Left thumb X axis",
AK_GAMEPAD_ANALOG_02 = "Left thumb Y axis",
AK_GAMEPAD_ANALOG_03 = "Left Trigger(+)",
AK_GAMEPAD_ANALOG_04 = "Right thumb X axis",
AK_GAMEPAD_ANALOG_05 = "Right thumb Y axis",
AK_GAMEPAD_ANALOG_06 = "Right Trigger(-)",
AK_GAMEPAD_ANALOG_07 = "'N/A'",
AK_GAMEPAD_ANALOG_08 = "'N/A'",
AK_GAMEPAD_ANALOG_09 = "'N/A'",
VK_SPACE = "Space", --Already used in: "NextPreviousRepeat", "SmartPause" & "AskAttendedMode".
VK_RETURN = "Return", --Already used in: "NextPreviousRepeat" & "AskAttendedMode".
VK_ESCAPE = "Esc",  --Already used in: "CoEndOfTest" and "NextPreviousRepeat".
VK_LEFT = "Left", --Already used in: "NextPreviousRepeat".
VK_RIGHT = "Right", --Already used in: "NextPreviousRepeat".
VK_UP = "Up",
VK_DOWN = "Down",
}
elseif AK_PLATFORM_MAC then
AK_PLATFORM_NAME = "Mac"
kButtonNameMapping = 
{ 
AK_GAMEPAD_BUTTON_01 = "1 / A",
AK_GAMEPAD_BUTTON_02 = "2 / B", 
AK_GAMEPAD_BUTTON_03 = "3 / X", 
AK_GAMEPAD_BUTTON_04 = "4 / Y", 
AK_GAMEPAD_BUTTON_05 = "5 / Left shoulder", 
AK_GAMEPAD_BUTTON_06 = "6 / Right shoulder", 
AK_GAMEPAD_BUTTON_07 = "7 / Back", 
AK_GAMEPAD_BUTTON_08 = "8 / Start", 
AK_GAMEPAD_BUTTON_09 = "9 / Left thumb down", 
AK_GAMEPAD_BUTTON_10 = "0 / Right thumb down", 
AK_GAMEPAD_BUTTON_11 = "F1 / Directional pad up", 
AK_GAMEPAD_BUTTON_12 = "F2 / Directional pad right", 
AK_GAMEPAD_BUTTON_13 = "F3 / Directional pad down", 
AK_GAMEPAD_BUTTON_14 = "F4 / Directional pad left", 
AK_GAMEPAD_BUTTON_15 = "F5 / 'N/A'", 
AK_GAMEPAD_BUTTON_16 = "F6 / 'N/A'",
AK_HOME_BUTTON = "Home",
AK_GAMEPAD_ANALOG_01 = "Left thumb X axis",
AK_GAMEPAD_ANALOG_02 = "Left thumb Y axis",
AK_GAMEPAD_ANALOG_03 = "Left Trigger(+)",
AK_GAMEPAD_ANALOG_04 = "Right thumb X axis",
AK_GAMEPAD_ANALOG_05 = "Right thumb Y axis",
AK_GAMEPAD_ANALOG_06 = "Right Trigger(-)",
AK_GAMEPAD_ANALOG_07 = "'N/A'",
AK_GAMEPAD_ANALOG_08 = "'N/A'",
AK_GAMEPAD_ANALOG_09 = "'N/A'",
VK_SPACE = "Space", --Already used in: "NextPreviousRepeat", "SmartPause" & "AskAttendedMode".
VK_RETURN = "Return", --Already used in: "NextPreviousRepeat" & "AskAttendedMode".
VK_ESCAPE = "Esc",  --Already used in: "CoEndOfTest" and "NextPreviousRepeat".
VK_LEFT = "Left", --Already used in: "NextPreviousRepeat".
VK_RIGHT = "Right", --Already used in: "NextPreviousRepeat".
VK_UP = "Up",
VK_DOWN = "Down",
}

elseif( AK_PLATFORM_XBOX360 or AK_PLATFORM_XBOXONE) then
if AK_PLATFORM_XBOX360 then
	AK_PLATFORM_NAME = "XBox360"
else
	AK_PLATFORM_NAME = "XboxOne"
end
kButtonNameMapping = 
{ 
AK_GAMEPAD_BUTTON_01 = "A", --Already used in: "NextPreviousRepeat", "SmartPause" & "AskAttendedMode".
AK_GAMEPAD_BUTTON_02 = "B", --Already used in: "NextPreviousRepeat".
AK_GAMEPAD_BUTTON_03 = "X", --Already used in: "NextPreviousRepeat" & "AskAttendedMode".
AK_GAMEPAD_BUTTON_04 = "Y", --Already used in: "NextPreviousRepeat".
AK_GAMEPAD_BUTTON_05 = "Left shoulder",
AK_GAMEPAD_BUTTON_06 = "Right shoulder",
AK_GAMEPAD_BUTTON_07 = "Left trigger",
AK_GAMEPAD_BUTTON_08 = "Right trigger",
AK_GAMEPAD_BUTTON_09 = "Back",
AK_GAMEPAD_BUTTON_10 = "Start", --Already used in: "CoEndOfTest" and "NextPreviousRepeat".
AK_GAMEPAD_BUTTON_11 = "Directional pad up",
AK_GAMEPAD_BUTTON_12 = "Directional pad right",
AK_GAMEPAD_BUTTON_13 = "Directional pad down",
AK_GAMEPAD_BUTTON_14 = "Directional pad left",
AK_GAMEPAD_BUTTON_15 = "Left thumb down",
AK_GAMEPAD_BUTTON_16 = "Right thumb down",
AK_HOME_BUTTON = "N/A",
AK_GAMEPAD_ANALOG_01 = "Left thumb X axis",
AK_GAMEPAD_ANALOG_02 = "Left thumb Y axis",
AK_GAMEPAD_ANALOG_03 = "Right thumb X axis",
AK_GAMEPAD_ANALOG_04 = "Right thumb Y axis",
AK_GAMEPAD_ANALOG_05 = "Left trigger value",
AK_GAMEPAD_ANALOG_06 = "Right trigger value",
AK_GAMEPAD_ANALOG_07 = "N/A",
AK_GAMEPAD_ANALOG_08 = "N/A",
AK_GAMEPAD_ANALOG_09 = "N/A"
}

elseif( AK_PLATFORM_PS3 ) then
AK_PLATFORM_NAME = "PS3"
kButtonNameMapping = 
{ 
AK_GAMEPAD_BUTTON_01 = "Cross", --Already used in: "NextPreviousRepeat", "SmartPause" & "AskAttendedMode".
AK_GAMEPAD_BUTTON_02 = "Circle", --Already used in: "NextPreviousRepeat".
AK_GAMEPAD_BUTTON_03 = "Square", --Already used in: "NextPreviousRepeat" & "AskAttendedMode".
AK_GAMEPAD_BUTTON_04 = "Triangle",  --Already used in: "NextPreviousRepeat".
AK_GAMEPAD_BUTTON_05 = "L1", 
AK_GAMEPAD_BUTTON_06 = "R1", 
AK_GAMEPAD_BUTTON_07 = "L2", 
AK_GAMEPAD_BUTTON_08 = "R2", 
AK_GAMEPAD_BUTTON_09 = "Select", 
AK_GAMEPAD_BUTTON_10 = "Start", --Already used in: "CoEndOfTest" and "NextPreviousRepeat".
AK_GAMEPAD_BUTTON_11 = "Directional pad up", 
AK_GAMEPAD_BUTTON_12 = "Directional pad right", 
AK_GAMEPAD_BUTTON_13 = "Directional pad down", 
AK_GAMEPAD_BUTTON_14 = "Directional pad left", 
AK_GAMEPAD_BUTTON_15 = "Left thumb down", 
AK_GAMEPAD_BUTTON_16 = "Right thumb down",
AK_HOME_BUTTON = "N/A",
AK_GAMEPAD_ANALOG_01 = "Left thumb X axis",
AK_GAMEPAD_ANALOG_02 = "Left thumb Y axis",
AK_GAMEPAD_ANALOG_03 = "Right thumb X axis",
AK_GAMEPAD_ANALOG_04 = "Right thumb Y axis",
AK_GAMEPAD_ANALOG_05 = "N/A",
AK_GAMEPAD_ANALOG_06 = "N/A",
AK_GAMEPAD_ANALOG_07 = "X acceleration axis",
AK_GAMEPAD_ANALOG_08 = "Y acceleration axis",
AK_GAMEPAD_ANALOG_09 = "Z acceleration axis"
}

elseif( AK_PLATFORM_WII or AK_PLATFORM_WIIU ) then
if AK_PLATFORM_WII then
	AK_PLATFORM_NAME = "Wii"
else
	AK_PLATFORM_NAME = "WiiUSW"
end
	
kButtonNameMapping = 
{ 
AK_GAMEPAD_BUTTON_01 = "A", --Already used in: "NextPreviousRepeat", "SmartPause" & "AskAttendedMode".
AK_GAMEPAD_BUTTON_02 = "B", --Already used in: "NextPreviousRepeat".
AK_GAMEPAD_BUTTON_03 = "X / C", --Already used in: "NextPreviousRepeat" & "AskAttendedMode".
AK_GAMEPAD_BUTTON_04 = "Y / Z",  --Already used in: "NextPreviousRepeat".
AK_GAMEPAD_BUTTON_05 = "L / -", 
AK_GAMEPAD_BUTTON_06 = "R / +", 
AK_GAMEPAD_BUTTON_07 = "'N/A' / 2", 
AK_GAMEPAD_BUTTON_08 = "'N/A'", 
AK_GAMEPAD_BUTTON_09 = "'N/A'", 
AK_GAMEPAD_BUTTON_10 = "Start / 1", --Already used in: "CoEndOfTest" and "NextPreviousRepeat".
AK_GAMEPAD_BUTTON_11 = "Directional pad up", 
AK_GAMEPAD_BUTTON_12 = "Directional pad right", 
AK_GAMEPAD_BUTTON_13 = "Directional pad down", 
AK_GAMEPAD_BUTTON_14 = "Directional pad left", 
AK_GAMEPAD_BUTTON_15 = "'N/A'", 
AK_GAMEPAD_BUTTON_16 = "'N/A'",
AK_HOME_BUTTON = "'N/A' / Home",
AK_GAMEPAD_ANALOG_01 = "Control stick X axis / 'N/A'",
AK_GAMEPAD_ANALOG_02 = "Control stick Y axis / 'N/A'",
AK_GAMEPAD_ANALOG_03 = "C stick X axis / 'N/A'",
AK_GAMEPAD_ANALOG_04 = "C stick Y axis / 'N/A'",
AK_GAMEPAD_ANALOG_05 = "Left trigger value / 'N/A'",
AK_GAMEPAD_ANALOG_06 = "Right trigger value / 'N/A'",
AK_GAMEPAD_ANALOG_07 = "'N/A'",
AK_GAMEPAD_ANALOG_08 = "'N/A'",
AK_GAMEPAD_ANALOG_09 = "'N/A'"
}

elseif( AK_PLATFORM_IOS or AK_PLATFORM_ANDROID or AK_PLATFORM_LINUX ) then

if (AK_PLATFORM_IOS) then
	AK_PLATFORM_NAME = "iOS"
elseif (AK_PLATFORM_ANDROID) then
	AK_PLATFORM_NAME = "Android"
elseif (AK_PLATFORM_LINUX) then
	AK_PLATFORM_NAME = "Linux"
end
kButtonNameMapping = 
{ 
AK_GAMEPAD_BUTTON_01 = 	"A",
AK_GAMEPAD_BUTTON_02 = 	"B",
AK_GAMEPAD_BUTTON_03 = 	"X",
AK_GAMEPAD_BUTTON_04 = 	"Y",
AK_GAMEPAD_BUTTON_05 = 	"'N/A'",
AK_GAMEPAD_BUTTON_06 = 	"'N/A'",
AK_GAMEPAD_BUTTON_07 = 	"'N/A'",
AK_GAMEPAD_BUTTON_08 = 	"'N/A'",
AK_GAMEPAD_BUTTON_09 = 	"Select",
AK_GAMEPAD_BUTTON_10 = 	"Start",
AK_GAMEPAD_BUTTON_11 = 	"Directional pad up", 
AK_GAMEPAD_BUTTON_12 = 	"Directional pad right",
AK_GAMEPAD_BUTTON_13 = 	"Directional pad down", 
AK_GAMEPAD_BUTTON_14 = 	"Directional pad left", 
AK_GAMEPAD_BUTTON_15 = 	"'N/A'",
AK_GAMEPAD_BUTTON_16 = 	"'N/A'",
AK_HOME_BUTTON = 		"'N/A'",
AK_GAMEPAD_ANALOG_01 = 	"Left thumb X axis",
AK_GAMEPAD_ANALOG_02 = 	"Left thumb Y axis",
AK_GAMEPAD_ANALOG_03 = 	"Right thumb X axis",
AK_GAMEPAD_ANALOG_04 = 	"Right thumb Y axis",
AK_GAMEPAD_ANALOG_05 = 	"'N/A'",
AK_GAMEPAD_ANALOG_06 = 	"'N/A'",
AK_GAMEPAD_ANALOG_07 = 	"'N/A'",
AK_GAMEPAD_ANALOG_08 = 	"'N/A'",
AK_GAMEPAD_ANALOG_09 = 	"'N/A'",
VK_SPACE = 				"'N/A'",
VK_RETURN = 			"'N/A'",
VK_ESCAPE = 			"'N/A'",
VK_LEFT = 				"'N/A'",
VK_RIGHT = 				"'N/A'",
VK_UP = 				"'N/A'",
VK_DOWN =				"'N/A'",
}
elseif( AK_PLATFORM_VITA_SW or AK_PLATFORM_VITA_HW) then

if (AK_PLATFORM_VITA_SW) then
	AK_PLATFORM_NAME = "VitaSW"
elseif (AK_PLATFORM_VITA_HW) then
	AK_PLATFORM_NAME = "VitaHW"
end

kButtonNameMapping = 
{ 
AK_GAMEPAD_BUTTON_01 = "Cross", --Already used in: "NextPreviousRepeat", "SmartPause" & "AskAttendedMode".
AK_GAMEPAD_BUTTON_02 = "Circle", --Already used in: "NextPreviousRepeat".
AK_GAMEPAD_BUTTON_03 = "Square", --Already used in: "NextPreviousRepeat" & "AskAttendedMode".
AK_GAMEPAD_BUTTON_04 = "Triangle",  --Already used in: "NextPreviousRepeat".
AK_GAMEPAD_BUTTON_05 = "L", 
AK_GAMEPAD_BUTTON_06 = "R", 
AK_GAMEPAD_BUTTON_07 = "N/A", 
AK_GAMEPAD_BUTTON_08 = "N/A", 
AK_GAMEPAD_BUTTON_09 = "Select", 
AK_GAMEPAD_BUTTON_10 = "Start", --Already used in: "CoEndOfTest" and "NextPreviousRepeat".
AK_GAMEPAD_BUTTON_11 = "Directional pad up", 
AK_GAMEPAD_BUTTON_12 = "Directional pad right", 
AK_GAMEPAD_BUTTON_13 = "Directional pad down", 
AK_GAMEPAD_BUTTON_14 = "Directional pad left", 
AK_GAMEPAD_BUTTON_15 = "N/A", 
AK_GAMEPAD_BUTTON_16 = "N/A",
AK_HOME_BUTTON = "N/A",
AK_GAMEPAD_ANALOG_01 = "Left thumb X axis",
AK_GAMEPAD_ANALOG_02 = "Left thumb Y axis",
AK_GAMEPAD_ANALOG_03 = "Right thumb X axis",
AK_GAMEPAD_ANALOG_04 = "Right thumb Y axis",
AK_GAMEPAD_ANALOG_05 = "N/A",
AK_GAMEPAD_ANALOG_06 = "N/A",
AK_GAMEPAD_ANALOG_07 = "N/A",
AK_GAMEPAD_ANALOG_08 = "N/A",
AK_GAMEPAD_ANALOG_09 = "N/A"
}

elseif( AK_PLATFORM_PS4) then
AK_PLATFORM_NAME = "PS4"

kButtonNameMapping = 
{ 
AK_GAMEPAD_BUTTON_01 = "Cross", --Already used in: "NextPreviousRepeat", "SmartPause" & "AskAttendedMode".
AK_GAMEPAD_BUTTON_02 = "Circle", --Already used in: "NextPreviousRepeat".
AK_GAMEPAD_BUTTON_03 = "Square", --Already used in: "NextPreviousRepeat" & "AskAttendedMode".
AK_GAMEPAD_BUTTON_04 = "Triangle",  --Already used in: "NextPreviousRepeat".
AK_GAMEPAD_BUTTON_05 = "L", 
AK_GAMEPAD_BUTTON_06 = "R", 
AK_GAMEPAD_BUTTON_07 = "N/A", 
AK_GAMEPAD_BUTTON_08 = "N/A", 
AK_GAMEPAD_BUTTON_09 = "Select", 
AK_GAMEPAD_BUTTON_10 = "Start", --Already used in: "CoEndOfTest" and "NextPreviousRepeat".
AK_GAMEPAD_BUTTON_11 = "Directional pad up", 
AK_GAMEPAD_BUTTON_12 = "Directional pad right", 
AK_GAMEPAD_BUTTON_13 = "Directional pad down", 
AK_GAMEPAD_BUTTON_14 = "Directional pad left", 
AK_GAMEPAD_BUTTON_15 = "N/A", 
AK_GAMEPAD_BUTTON_16 = "N/A",
AK_HOME_BUTTON = "N/A",
AK_GAMEPAD_ANALOG_01 = "Left thumb X axis",
AK_GAMEPAD_ANALOG_02 = "Left thumb Y axis",
AK_GAMEPAD_ANALOG_03 = "Right thumb X axis",
AK_GAMEPAD_ANALOG_04 = "Right thumb Y axis",
AK_GAMEPAD_ANALOG_05 = "N/A",
AK_GAMEPAD_ANALOG_06 = "N/A",
AK_GAMEPAD_ANALOG_07 = "N/A",
AK_GAMEPAD_ANALOG_08 = "N/A",
AK_GAMEPAD_ANALOG_09 = "N/A"
}

elseif( AK_PLATFORM_3DS ) then
AK_PLATFORM_NAME = "3DS"
kButtonNameMapping = 
{ 
AK_GAMEPAD_BUTTON_01 = "A", --Already used in: "NextPreviousRepeat", "SmartPause" & "AskAttendedMode".
AK_GAMEPAD_BUTTON_02 = "B", --Already used in: "NextPreviousRepeat".
AK_GAMEPAD_BUTTON_03 = "X", --Already used in: "NextPreviousRepeat" & "AskAttendedMode".
AK_GAMEPAD_BUTTON_04 = "Y",  --Already used in: "NextPreviousRepeat".
AK_GAMEPAD_BUTTON_05 = "L", 
AK_GAMEPAD_BUTTON_06 = "R", 
AK_GAMEPAD_BUTTON_07 = "N/A", 
AK_GAMEPAD_BUTTON_08 = "N/A", 
AK_GAMEPAD_BUTTON_09 = "Select", 
AK_GAMEPAD_BUTTON_10 = "Start", --Already used in: "CoEndOfTest" and "NextPreviousRepeat".
AK_GAMEPAD_BUTTON_11 = "Directional pad up", 
AK_GAMEPAD_BUTTON_12 = "Directional pad right", 
AK_GAMEPAD_BUTTON_13 = "Directional pad down", 
AK_GAMEPAD_BUTTON_14 = "Directional pad left", 
AK_GAMEPAD_BUTTON_15 = "N/A", 
AK_GAMEPAD_BUTTON_16 = "N/A",
AK_HOME_BUTTON = "N/A",
AK_GAMEPAD_ANALOG_01 = "Left thumb X axis",
AK_GAMEPAD_ANALOG_02 = "Left thumb Y axis",
AK_GAMEPAD_ANALOG_03 = "Right thumb X axis",
AK_GAMEPAD_ANALOG_04 = "Right thumb Y axis",
AK_GAMEPAD_ANALOG_05 = "N/A",
AK_GAMEPAD_ANALOG_06 = "N/A",
AK_GAMEPAD_ANALOG_07 = "N/A",
AK_GAMEPAD_ANALOG_08 = "N/A",
AK_GAMEPAD_ANALOG_09 = "N/A"
}

end

-- AKRESULT error codes enumeration
kResultCode = 
{
	[0] = "AK_NotImplemented",		-- This feature is not implemented.
    "AK_Success",					-- The operation was successful.
    "AK_Fail",						-- The operation failed.
    "AK_PartialSuccess",			-- The operation succeeded partially.
    "AK_NotCompatible",				-- Incompatible formats
    "AK_AlreadyConnected",			-- The stream is already connected to another node.
    "AK_NameNotSet",				-- Trying to open a file when its name was not set
    "AK_InvalidFile",				-- An unexpected value causes the file to be invalid.
    "AK_AudioFileHeaderTooLarge",	-- The file header is too large.
    "AK_MaxReached",				-- The maximum was reached.
    "AK_InputsInUsed",				-- Inputs are currently used.
    "AK_OutputsInUsed",				-- Outputs are currently used.
    "AK_InvalidName",				-- The name is invalid.
    "AK_NameAlreadyInUse",			-- The name is already in use.
    "AK_InvalidID",					-- The ID is invalid.
    "AK_IDNotFound",				-- The ID was not found.
    "AK_InvalidInstanceID",			-- The InstanceID is invalid.
    "AK_NoMoreData",				-- No more data is available from the source.
    "AK_NoSourceAvailable",			-- There is no child (source) associated with the node.
	"AK_StateGroupAlreadyExists",	-- The StateGroup already exists.
	"AK_InvalidStateGroup",			-- The StateGroup is not a valid channel.
	"AK_ChildAlreadyHasAParent",	-- The child already has a parent.
	"AK_InvalidLanguage",			-- The language is invalid (applies to the Low-Level I/O).
	"AK_CannotAddItseflAsAChild",	-- It is not possible to add itself as its own child.
	"AK_TransitionNotFound",		-- The transition is not in the list.
	"AK_TransitionNotStartable",	-- Start allowed in the Running and Done states.
	"AK_TransitionNotRemovable",	-- Must not be in the Computing state.
	"AK_UsersListFull",				-- No one can be added any more, could be AK_MaxReached.
	"AK_UserAlreadyInList",			-- This user is already there.
	"AK_UserNotInList",				-- This user is not there.
	"AK_NoTransitionPoint",			-- Not in use.
	"AK_InvalidParameter",			-- Something is not within bounds.
	"AK_ParameterAdjusted",			-- Something was not within bounds and was relocated to the nearest OK value.
	"AK_IsA3DSound",				-- The sound has 3D parameters.
	"AK_NotA3DSound",				-- The sound does not have 3D parameters.
	"AK_ElementAlreadyInList",		-- The item could not be added because it was already in the list.
	"AK_PathNotFound",				-- This path is not known.
	"AK_PathNoVertices",			-- Stuff in vertices before trying to start it
	"AK_PathNotRunning",			-- Only a running path can be paused.
	"AK_PathNotPaused",				-- Only a paused path can be resumed.
	"AK_PathNodeAlreadyInList",		-- This path is already there.
	"AK_PathNodeNotInList",			-- This path is not there.
	"AK_VoiceNotFound",				-- Unknown in our voices list
	"AK_DataNeeded",				-- The consumer needs more.
	"AK_NoDataNeeded",				-- The consumer does not need more.
	"AK_DataReady",					-- The provider has available data.
	"AK_NoDataReady",				-- The provider does not have available data.
	"AK_NoMoreSlotAvailable",		-- Not enough space to load bank.
	"AK_SlotNotFound",				-- Bank error.
	"AK_ProcessingOnly",			-- No need to fetch new data.
	"AK_MemoryLeak",				-- Debug mode only.
	"AK_CorruptedBlockList",		-- The memory manager's block list has been corrupted.
	"AK_InsufficientMemory",		-- Memory error.
	"AK_Cancelled",					-- The requested action was cancelled (not an error).
	"AK_UnknownBankID",				-- Trying to load a bank using an ID which is not defined.
    "AK_IsProcessing",   			-- Asynchronous pipeline component is processing.
	"AK_BankReadError",				-- Error while reading a bank.
	"AK_InvalidSwitchType",			-- Invalid switch type (used with the switch container)
	"AK_VoiceDone",					-- Internal use only.
	"AK_UnknownEnvironment",		-- This environment is not defined.
	"AK_EnvironmentInUse",			-- This environment is used by an object.
	"AK_UnknownObject",				-- This object is not defined.
	"AK_NoConversionNeeded",		-- Audio data already in target format, no conversion to perform.
    "AK_FormatNotReady",   			-- Source format not known yet.
	"AK_WrongBankVersion",			-- The bank version is not compatible with the current bank reader.
	"AK_DataReadyNoProcess",		-- The provider has some data but does not process it (virtual voices).
    "AK_FileNotFound",   			-- File not found.
    "AK_DeviceNotReady",   			-- IO device not ready (may be because the tray is open)
    "AK_CouldNotCreateSecBuffer",   -- The direct sound secondary buffer creation failed.
	"AK_BankAlreadyLoaded",			-- The bank load failed because the bank is already loaded.
	"AK_RenderedFX",				-- The effect on the node is rendered.
	"AK_ProcessNeeded",				-- A routine needs to be executed on some CPU.
	"AK_ProcessDone",				-- The executed routine has finished its execution.
	"AK_MemManagerNotInitialized",	-- The memory manager should have been initialized at this point.
	"AK_StreamMgrNotInitialized",	-- The stream manager should have been initialized at this point.
	"AK_SSEInstructionsNotSupported"-- The machine does not support SSE instructions (required on PC).
}

-- **********************************************************************
-- Those functions are needed for the QA automated test to work properly.
-- **********************************************************************

-- Call this with path between AK_AUTOMATEDTESTS_PATH and GeneratedSoundBanks\. Usually this is the WwiseProject's name.
-- If in_language is not specified, "English(US)" is used.
-- IMPORTANT: Don't use forwardslashes or backslashes in arguments, as type of slashes used in file paths is platform-specific.
-- Instead, use GetDirSlashChar() helper below.
-- Example: 
-- Say your soundbanks are in $(AK_AUTOMATEDTESTS_PATH)/PluginTests/CompressorTest/GeneratedSoundBanks/Windows/.
-- Call this:
-- SetDefaultBasePathAndLanguage( "PluginTests" .. GetDirSlashChar() .. "CompressorTest" )

function SetDefaultBasePathAndLanguage( in_projectName, in_language )	
	SetDefaultBasePathAndLanguageQA( FindBasePathForProject(in_projectName), in_language )	
end


-- This function can be used on it's own, if you want to specify a full path to the SoundBanks. 
-- The default "SetDefaultBasePathAndLanguage" function, used in most "Automated Tests", requires a relative path from the "AutomatedTests" folder.
-- Unfortunately, this approach is not convenient for scripts refering to Projects located outside the "AutomatedTests" folder. That's exactly what this function is for.
function SetDefaultBasePathAndLanguageQA( in_basePath, in_language )

	for k,device in pairs(g_lowLevelIO) do 
		local result = device:SetBasePath( in_basePath ) -- g_lowLevelIO is defined by audiokinetic\AkLuaFramework.lua	
		AKASSERT( result == AK_Success, "Base path set error" )	
	end
	
	g_basePath = in_basePath
	
	-- We need this variable for iOS
	-- This variable is set when uploading bank with iTunes
	if ( os.getenv("GAMESIMULATOR_FLAT_HIERARCHY") == nil) then
		--If you want to leave the language "undefined" in the lowLevelIO, you have to set "in_language" to  "none".
		if not(in_language == "none") then
			if (in_language == nil or in_language=="") then
				in_language = "English(US)"
			end
			
			local result = AK.StreamMgr.SetCurrentLanguage( in_language )
			AKASSERT( result == AK_Success, "Language set error" )
		end
	end
end


-- Returns platform-specific character used to split directories in paths.
function GetDirSlashChar()
	if( AK_PLATFORM_PC or AK_PLATFORM_XBOX360 or AK_PLATFORM_XBOXONE ) then
		return "\\"
	else
		return "/"
	end
end


function LogTestMsg( in_strMsg,LineFeed )  -- this function will log a message in the lua console and in the Wwise profiler.
	if( not AK_LUA_RELEASE ) then
		if (LineFeed) then
			print( in_strMsg )
			print( " " )
			AK.Monitor.PostString( in_strMsg, AK.Monitor.ErrorLevel_Message )
			AK.Monitor.PostString( " ", AK.Monitor.ErrorLevel_Message )
		else
			print( in_strMsg )
			AK.Monitor.PostString( in_strMsg, AK.Monitor.ErrorLevel_Message )
		end
	else
		if (LineFeed) then
			print( in_strMsg )
			print( " " )
		else
			print( in_strMsg )
		end
	end
end

function AutoLogTestMsg ( in_strMsg,in_PreLineFeed,in_PostLinefeed )

	local remainingString = in_strMsg
	
	if g_maxLogChar == nil then
		g_maxLogChar = 55  -- maximum of characters per line. Can be overridden in your main script
	end
	
	if in_PreLineFeed ~= nil then  -- apply pre linefeed if needed
		for line = 1, in_PreLineFeed do
			if( not AK_LUA_RELEASE ) then
				print (" ") 
				AK.Monitor.PostString( " ", AK.Monitor.ErrorLevel_Message )
			else
				print( " " )
		    end
		end
	end
	
	while string.len (remainingString) > g_maxLogChar do -- split too long test messages
		local currentChar = "x"
		local searchPos = g_maxLogChar

		while currentChar ~= " " do
			currentChar = string.sub (remainingString, searchPos, searchPos)
			searchPos = searchPos -1
		end
		
		if( not AK_LUA_RELEASE ) then  -- only send to Wwise capture log if not gamesim release
			print (string.sub(remainingString, 1, searchPos))
			AK.Monitor.PostString( string.sub(remainingString, 1, searchPos), AK.Monitor.ErrorLevel_Message )
	
		else
			print (string.sub(remainingString, 1, searchPos))
		end
		remainingString = string.sub(remainingString,searchPos + 2)
	end
	
	if( not AK_LUA_RELEASE ) then  -- print the rest of the string once it is smaller than g_maxLogChar
		print (remainingString)
		AK.Monitor.PostString( remainingString, AK.Monitor.ErrorLevel_Message )
	else
		print( remainingString )
	end
	
	if in_PostLinefeed ~= nil then  -- apply post linefeed if needed
		for line = 1, in_PostLinefeed do
			if( not AK_LUA_RELEASE ) then
				print (" ") 
				AK.Monitor.PostString(" ", AK.Monitor.ErrorLevel_Message )
			else
				print( " " )
		    end
		end
	end

end

--This variable is useful only in OFFLINE mode.  It simulates the output of os.gettickcount
g_TickCount = 0
function InternalGameTick()
	AkGameTick()
	g_TickCount = g_TickCount + 1
end

function Wait(delayTime)  -- useful whenever you need a delay in a coroutine, without blocking the flow of the gameloop
	if ( AkLuaGameEngine.IsOffline() ) then		
		local numIter = delayTime/AK_AUDIOBUFFERMS		
		while ( numIter > 0 ) do			
			numIter = numIter - 1
			InternalGameTick()
		end
	else
		testStartTime = os.gettickcount()
		while( os.gettickcount() - testStartTime < delayTime ) do
			coroutine.yield()
		end
	end
end

function CoWaitStartTest() -- You should always put this coroutine as the first test in your test array. It will give you time to connect to Wwise					
	if IsUnattended() == true then -- If in unattended mode, make a pause to give user time to connect.
		Pause()
	end
		
	if ( not AkLuaGameEngine.IsOffline() ) then
		Wait(500)
	end

end
g_testName[CoWaitStartTest]="CoWaitStartTest" -- give a printable name to CoWaitStartTest


function CoEndOfTest() -- You should always put this coroutine as the last one in your test array. It will end your test gracefully.

	AutoLogTestMsg( "****** All tests are finished ******",1,0 )	
	if ( not IsUnattended() )then		
		if( AK_PLATFORM_PC or AK_PLATFORM_MAC ) then		
			AutoLogTestMsg( "****** Press "..kButtonNameMapping.VK_ESCAPE.." to Exit Game Loop ******",0,1 )
			
		else			
			AutoLogTestMsg( "****** "..kButtonNameMapping.AK_GAMEPAD_BUTTON_10.." to Exit Game Loop ******",0,1 )
		end    
	end
	kEndOfTests = true
end

g_testName[CoEndOfTest]="CoEndOfTest" -- give a printable name to CoEndOfTest

function FindFunctionNameInGlobalTable(func)
	for key in pairs(_G) do			
		if _G[key] == func then			
			return key
		end
	end	
	return "Unknown"
end

function ReplaceBadCharacters(testName)	
	testName = string.gsub(testName, "|", "_")
	testName = string.gsub(testName, "\\", "_")
	testName = string.gsub(testName, "?", "_")
	testName = string.gsub(testName, "*", "_")
	testName = string.gsub(testName, "<", "_")
	testName = string.gsub(testName, "\"", "_")				
	testName = string.gsub(testName, ":", "_")
	testName = string.gsub(testName, ">", "_")
	testName = string.gsub(testName, "+", "_")											
	testName = string.gsub(testName, "]", "_")				
	testName = string.gsub(testName, "/", "_")
	testName = string.gsub(testName, ",", "_")	
	return testName
end

--This table contains all routine entries with their names and parameters 
g_TestTable = {}

function AkInsertTestRoutine(func, name, ...)
	local test = {}
	test.Func = func
	if (name == nil) then
		test.Name = FindFunctionNameInGlobalTable(func)
	else
		test.Name = name
	end
	test.Params = {...}
	table.insert(g_TestTable, test)
end

function AkGetTestName(func)
	for i=1,#g_TestTable do
		if func == g_TestTable[i].Func then
			return g_TestTable[i].Name
		end
	end
end

function TransformTestArray()
	local iTest = 1
	if (g_testsArray == nil) then
		return
	end
	
	while (iTest <= #g_testsArray) do
		local routine = {}		
		routine.Func = g_testsArray[iTest]
		if g_testName[routine.Func] ~= nil then
			routine.Name = g_testName[routine.Func]
		else
			routine.Name = FindFunctionNameInGlobalTable(routine.Func)
		end
		
		--Gather optional parameters
		iTest = iTest + 1
		routine.Params = {}
		while g_testsArray[iTest] ~= nil and type(g_testsArray[iTest]) ~= "function" do					
			table.insert(routine.Params, g_testsArray[iTest])			
			routine.Name = routine.Name.."_"..g_testsArray[iTest]
			iTest = iTest + 1
		end
		
		table.insert(g_TestTable, routine)
	end
end

function ResetEngineState()
	if( AK.SoundEngine.IsInitialized() ) then
		AK.SoundEngine.StopAllObsolete()
		AK.SoundEngine.UnregisterAllGameObj()
		
		local listenerPos = AkListenerPosition:new_local()
		listenerPos.OrientationFront.X = 0
		listenerPos.OrientationFront.Y = 0
		listenerPos.OrientationFront.Z = 1 

		listenerPos.OrientationTop.X = 0 
		listenerPos.OrientationTop.Y = 1 -- head is up
		listenerPos.OrientationTop.Z = 0 

		listenerPos.Position.X = 0
		listenerPos.Position.Y = 0 
		listenerPos.Position.Z = 0
		for i=0,8 do		
			AK.SoundEngine.SetListenerPosition(listenerPos, i)	--Reset the listener position to origin			
		end				
	end				
		
	AkClearAllGameTickCalls()
end

function CoHandleTests()  -- this is the coroutine that will execute each tests declared in g_testsArray. It will wait for user input to control the test flow.	
	
	--Transform the simple test array in the form we need.  The table of routines allow for parameters more easily
	TransformTestArray()

	local testIndex = 1
	while (testIndex <= #g_TestTable) do
	
		local current = g_TestTable[testIndex]
		currentTest = current.Func	--Legacy. The global variable currentTest is used in automated scripts.
		
		if skipMode == true then
			AutoLogTestMsg ("-> "..current.Name,0,1)			
			skipMode = false
		else
			LogTestMsg("-> "..current.Name)

			local coroutineName = ReplaceBadCharacters(current.Name)
			if ( ProfilerCapture() ) then			
				AkStartProfilerCapture(ProfilerCaptureFileName(coroutineName))
			end	

			if ( kCaptureOneFilePerCoroutine ) then								
				AkStartOutputCapture( ReplaceBadCharacters(current.Name)..".wav" )
			end
			
			-- Register default game object
			if( AK.SoundEngine.IsInitialized() ) then
				AK.SoundEngine.RegisterGameObj( g_AkDefaultGameObject, "AkDefaultGameObject" )
			end

			if (current.Params == nil) then
				current.Func()
			else							
				current.Func(unpack(current.Params))
			end
			
			if ( kCaptureOneFilePerCoroutine ) then							
				AkStopOutputCapture()
			end
			
			if ( ProfilerCapture() ) then							
				AkStopProfilerCapture()
			end	
			
			testIndex = testIndex + 1			
		end
		
		if not IsUnattended() then -- ask for user input only if not in unattended mode. IsUnattended() should be declared in main script.		
			NextPreviousRepeat()	
		end
		
		if (buttonPressed == executeButton) then
			testIndex = testIndex			
		elseif (buttonPressed == backwardButton) then		
			if testIndex >= 2 then
				testIndex = testIndex - 1				
			end
			
			skipMode = true
		elseif (buttonPressed == forwardButton) then			
			if testIndex < table.maxn(g_TestTable) then  			
				testIndex = testIndex + 1				
			end
			
			skipMode = true			
		elseif (buttonPressed == exitButton) then		
			testIndex = table.maxn(g_TestTable) -- last index is usually the End of test			
		elseif (buttonPressed == repeatButton) then		
			testIndex = testIndex - 1
		end
		
		ResetEngineState()				
	end	
end

function CoHandleTestsAutomated()  -- this is the coroutine that will execute each tests declared in g_testsArray.
	
	TransformTestArray()
	
	local testIndex = 1
	while (testIndex <= #g_TestTable) do
	
		local current = g_TestTable[testIndex]
		currentTest = current.Func	--Legacy. The global variable currentTest is used in automated scripts.
		
		-- Startup routines can be skipped
		if (current.Func ~= CoWaitStartTest and current.Func ~= CoEndOfTest) then
		
			LogTestMsg("-> "..current.Name)
			--Before starting the co-routine, reset the random seed.  Except if we are running random memory failures!
			if not g_MemTest then
				math.randomseed(12345)
			end
			
			local coroutineName = ReplaceBadCharacters(current.Name)
			if ( ProfilerCapture() ) then							
				AkStartProfilerCapture(ProfilerCaptureFileName(coroutineName))
			end	
			
			local captureFileName = ReplaceBadCharacters(current.Name)..".wav"
			if ( kCaptureOneFilePerCoroutine ) then
				AkStartOutputCapture( captureFileName )
			end
			
			-- Register default game object
			if( AK.SoundEngine.IsInitialized() ) then
				AK.SoundEngine.RegisterGameObj( g_AkDefaultGameObject, "AkDefaultGameObject" )
			end

			-- Execute the coroutine until it finishes.		
			local routine = coroutine.create(current.Func)
			while(coroutine.status(routine) ~= "dead") do	
				InternalGameTick()				
				io.flush()	--Make sure the stdout is flushed ("standard output", the output where all the "print" go)	
				local success = true
				local errMsg = ""
				if (current.Params == nil) then
					success, errMsg = coroutine.resume( routine )
				else
					success, errMsg = coroutine.resume( routine, unpack(current.Params) )
				end
					
				if success == false then
					print(errMsg)
				end				
			end		
			if ( kCaptureOneFilePerCoroutine ) then
				AkStopOutputCapture()
			end
	
			if ( ProfilerCapture() ) then							
				AkStopProfilerCapture()
			end	
			
		end
		
		testIndex = testIndex + 1
						
		ResetEngineState()
		
		if( AK_PLATFORM_WII ) then
		-- Leave some time to the wii to empty the DSP
			Wait(100)
		end
	end	
	kEndOfTests = true
end

-- This function handles the "profiler" argument that can be passed to the GameSimulator 
-- to start/stop the Game Profiler Capture for each coroutine.
function ProfilerCapture()
	--Process arguments passed to the GameSimulator.
	for i,ARG in ipairs(arg) do
		local argStart, argEnd = string.find(ARG, "-profiler")
		if argStart ~= nil then
			--"profiler" argument found. Game Profiler Capture will be executed in CoHandleTests & CoHandleTestsAutomated.
			return true
		end
	end
	return false
end

-- This function computes the file name that will be given to the "game profiler capture" files for each coroutine.
function ProfilerCaptureFileName(in_coroutineName)
	--Here we find the LUA script name of the running script.
	local luaScriptName = AkFileNameFromPath(LUA_SCRIPT,false)

	--Here we generate an ID based on the OS time/date to append to the "Game Profiler Capture" file name 
	--to make sure the Game Profiling files won't be overwritten from 1 session to another.
	--local captureTimeID = os.time()
	local captureTimeID = os.date("%Hh%Mm%Ss")
	
	--Here we generate the unique profilerFileName
	profilerFileName = captureTimeID.."_"..luaScriptName.."_"..in_coroutineName..".prof"

	return MultiPlatformCompliantName(profilerFileName)
end

--This functions finds the file name (including file name extension, if present) from a full path.
function AkFileNameFromPath(in_path, in_withExtension)
	
	--Since in LUA you can't perform a find from the end of file, we reverse the string to perform the find. 
	local reversedPath = string.reverse(in_path)

	--Here we find the position of the slash (/) in the reversed path. If "nil", there's no file name extension.
	local slashPosition = string.find(reversedPath, GetDirSlashChar())

	--There's no slash... we probably received a file name as input. 
	if slashPosition == nil then
		local fileName = in_path
		
	--There's a slash... find the file name with extension.
	else
		fileName = string.sub(in_path, -(slashPosition-1))
	end

	HandleFileNameExtension(fileName, in_withExtension )
	
	return out_fileName
end

--This function deals (leaves it or trims it) with the file name extension.
function HandleFileNameExtension(in_fileName,in_withExtension)
	--User specified that he wants the file name extension. Return in_fileName.
	if ( in_withExtension == nil or  in_withExtension == true ) then
		out_fileName = in_fileName
		return out_fileName

	--Here we will trim the file name extension (if one is present) to the user request.
	else
		--Since in LUA you can't perform a find from the end of file, we reverse the string to perform the find. 
		local reversedFileName = string.reverse (in_fileName)

		--Here we find the position of the period (.) of the file name extension in the file name. If "nil", there's no file name extension.
		local fileNameExtensionLength = string.find (reversedFileName, ".", 1, true)

		-- A file name extension was found.
		if (fileNameExtensionLength ~= nil) then 

			--Here we save the trimmed file name prefix in a variable.
			local fileNameWithoutExtension = string.sub ( in_fileName, 1,  -(fileNameExtensionLength+1))
	
			out_fileName = fileNameWithoutExtension
		end

		return out_fileName
	end
end

-- This function will take a file name (with or without a file name extension) 
-- and trim it to a specified length to make sure it can be written on any platform medium.
function MultiPlatformCompliantName(in_name)	
	local maxFileNameLength
	
	--The longest file name supported by the Xbox360 is 42 characters long.
	if (AK_PLATFORM_XBOX360) then
		maxFileNameLength = 42
	else
		maxFileNameLength = 128	
	end

	--Here we find the original file name length (including file name extension).
	local originalFileNameLength = string.len (in_name)

	--The file name received in parameter is already Multi-Platform Compliant... we return and use it.
	if (originalFileNameLength <= maxFileNameLength) then
		local out_name = in_name
		return out_name
		
	--Name received in parameter is too long. Here we compute a Multi-Platform Compliant Name.	
	else
		--Since in LUA you can't perform a find from the end of file, we reverse the string to perform the find. 
		local reversedFileName = string.reverse (in_name)
		
		--Here we find the position of the period (.) of the file name extension in the file name. If "nil", there's no file name extension.
		local fileNameExtensionLength = string.find (reversedFileName, ".", 1, true)
		
		-- A file name extension was found.
		if (fileNameExtensionLength ~= nil) then 
			--Here we save the file name extension (including the period) in a variable.
			local fileNameExtension = string.sub (in_name, -fileNameExtensionLength, -1)
		
			--Here we save the trimmed file name prefix in a variable.
			local fileNamePrefix = string.sub ( in_name, 1, (maxFileNameLength - (fileNameExtensionLength)))
			
			--Here we compute the Multi-Platform Compliant Name.
			out_name = fileNamePrefix..fileNameExtension

		--It's a file without a file name extension.
		else
			out_name = string.sub ( in_name, 1, maxFileNameLength)
		end

		--Here we return the computed Multi-Platform Compliant Name.
		return out_name	
	end
end

function NextPreviousRepeat()  -- this function waits for user input to control flow of tests.

	if( AK_PLATFORM_PC or AK_PLATFORM_MAC ) then
		executeButton = VK_SPACE
		backwardButton = VK_LEFT 
		forwardButton = VK_RIGHT 
		repeatButton =  VK_RETURN
		exitButton = VK_ESCAPE
		
		AutoLogTestMsg( "---- Press "..kButtonNameMapping.VK_SPACE.." to execute, "..kButtonNameMapping.VK_RETURN.." to repeat test ----",1,0 )
		AutoLogTestMsg( "---- "..kButtonNameMapping.VK_LEFT.." or "..kButtonNameMapping.VK_RIGHT.." arrow for previous or next test ----",0,1 )
				
	else
		executeButton = AK_GAMEPAD_BUTTON_01
		forwardButton = AK_GAMEPAD_BUTTON_02
		backwardButton = AK_GAMEPAD_BUTTON_03
		repeatButton =  AK_GAMEPAD_BUTTON_04
		exitButton = AK_GAMEPAD_BUTTON_10
		AutoLogTestMsg( "---- Press "..kButtonNameMapping.AK_GAMEPAD_BUTTON_01.." to execute, "..kButtonNameMapping.AK_GAMEPAD_BUTTON_04.." to repeat test ----",1,0 )
		AutoLogTestMsg( "---- "..kButtonNameMapping.AK_GAMEPAD_BUTTON_03.." or "..kButtonNameMapping.AK_GAMEPAD_BUTTON_02.." for previous or next test     ----",0,1 )
		
	end
	
	while(  not AkIsButtonPressedThisFrameInternal( executeButton ) ) do
	
		if AkIsButtonPressedThisFrameInternal( repeatButton )	then 
		
			buttonPressed = repeatButton
			return 
			
		elseif AkIsButtonPressed( backwardButton )	then 
		
			buttonPressed = backwardButton
			Wait(100)
			return 
			
		elseif AkIsButtonPressed( forwardButton )	then 
		
			buttonPressed = forwardButton
			Wait(100)
			return 
			
		elseif AkIsButtonPressedThisFrameInternal( exitButton )	then 
		
			buttonPressed = exitButton
			return 
			
		end
		
		coroutine.yield()
		
	end
	
	buttonPressed = executeButton
	Wait(150)
	return

end

function Pause()  -- this function considers if test is attended or unattended and skips Pause when unattended	
	
	if not IsUnattended() then 
	
		if( AK_PLATFORM_PC or AK_PLATFORM_MAC ) then
			resumeButton = VK_SPACE
			AutoLogTestMsg( "------ Press "..kButtonNameMapping.VK_SPACE.." to continue ------",0,1 )
		else
			resumeButton = AK_GAMEPAD_BUTTON_01 
			AutoLogTestMsg( "------ "..kButtonNameMapping.AK_GAMEPAD_BUTTON_01.." to continue  ------",0,1 )	
		end
		
		while(  not AkIsButtonPressedThisFrameInternal( resumeButton ) ) do
			coroutine.yield()
		end
		
		Wait(200)
		return AkIsButtonPressedThisFrameInternal( resumeButton )
	else
		if (not AkLuaGameEngine.IsOffline()) then
			Wait(200) -- do minimal wait even in unattended mode
		end
	end
end

function PauseUnattended()  -- this function will pause even in unattended mode

	if( AK_PLATFORM_PC or AK_PLATFORM_MAC ) then
		resumeButton = VK_SPACE
		AutoLogTestMsg( "------ Press "..kButtonNameMapping.VK_SPACE.." to continue ------",0,1 )
				
	else
		resumeButton = AK_GAMEPAD_BUTTON_01 
		AutoLogTestMsg( "------ Press "..kButtonNameMapping.AK_GAMEPAD_BUTTON_01.." to continue  ------",0,1 )	
	end
	
	while(  not AkIsButtonPressedThisFrameInternal( resumeButton ) ) do
		coroutine.yield()
	end
	
	Wait(200)
	return AkIsButtonPressedThisFrameInternal( resumeButton )

end

function AskAttendedMode()  -- Let user decide if test will be attended or unattended

	if ( AkLuaGameEngine.IsOffline() ) then
		g_unattended = true
		return true
	end

	if( AK_PLATFORM_PC or AK_PLATFORM_MAC ) then
	
		attendedButton = VK_SPACE
		unattendedButton =  VK_RETURN
		AutoLogTestMsg( " " )
		AutoLogTestMsg( "------ Press "..kButtonNameMapping.VK_SPACE.." for attended mode or "..kButtonNameMapping.VK_RETURN.." for unattended mode ------",0,1 )
		
	else
		attendedButton = AK_GAMEPAD_BUTTON_01 
		unattendedButton =  AK_GAMEPAD_BUTTON_03
		AutoLogTestMsg( " " )
		AutoLogTestMsg( "------ Press "..kButtonNameMapping.AK_GAMEPAD_BUTTON_01.." for attended mode or "..kButtonNameMapping.AK_GAMEPAD_BUTTON_03.." for unattended mode ------",0,1 )
		
	end

	while(not AkIsButtonPressed( attendedButton ) and not AkIsButtonPressed( unattendedButton )) do
		AkLuaGameEngine.Render()
	end

	if AkIsButtonPressed( attendedButton ) then
	
		g_unattended = false
		return AkIsButtonPressed( attendedButton )
		
	else
	
		g_unattended = true
		return AkIsButtonPressed( unattendedButton )
		
	end
	
end

-- ==========================================================
-- AnalogControl()

--This function will compute a (RTPC) value using it's pre-defined range and the position of the Controller thumbstick.
--It will mostly be used to drive a RTPC using a Thumbstick button.

-- This function works on the XBox360, PS3, Windows (using the Xbox360 controller) and Wii (using the GameCube controller).
	--NOTE:
	--On (AK_PLATFORM_PC) the Left and Right Triggers are mapped on AK_GAMEPAD_ANALOG_03, 
	--where the Left Trigger Range = [32767,65407]
	--and the Right Trigger Range = [32767, 127].

--This function REQUIRES the following parameters:
--	AK_GAMEPAD_ANALOG_ID: i.e. AK_GAMEPAD_ANALOG_01 to AK_GAMEPAD_ANALOG_09 (the specific ANALOG button you assigned to this function)
--	min_GameParameterValue: i.e. -2400
--	max_GameParameterValue: i.e. 2400
--	incrementSlider: i.e. true or false (True > incremental mode, False > range mode. There's more information below.)
--	incrementMultiplicator:  i.e. 10 (The maximum RTPC jump applied during 1 game frame.)

--		If the incrementSlider flag is "true", the thumbstick will work in incremental mode, 
--		where when we move the thumbstick, we increment the RTPC value and where when it's in it's default position, we do nothing special and leave the current value as is.

--		If the incrementSlider flag is "false", the thumbstick will work in range mode, 
--		where when the thumbstick in it's default position we map the output value to the mid-range RTPC value.

--The function RETURNS the:
--	computed (RTPC) value in your pre-defined range. i.e. 600
	
--Here's a short INTEGRATION EXAMPLE to help you with your script:

--EXAMPLE #1:
--	rtpcValue1 = AnalogControl(AK_GAMEPAD_ANALOG_01, -2400, 2400, true, 100)  <---This will compute RTPC value and return their value in the variable of your choice (rtpcValue1 in this case).	
--	AK.SoundEngine.SetRTPCValue( "Pitch_Game_Param", rtpcValue1, 2 )  <--- Here you set the computed RTPC value in the SoundEngine.
--	print ("Pitch_Game_Param > RTPC value is now: '" .. aValueToSet[AK_GAMEPAD_ANALOG_01] .. "'")  <--- You can print the current RTPC value to help you debug your script.

--EXAMPLE #2:
--	rtpcValue2 = AnalogControl(AK_GAMEPAD_ANALOG_06, 0, 100, false)  <---This will compute RTPC value and return their value in the variable of your choice (rtpcValue2 in this case).	
--	AK.SoundEngine.SetRTPCValue( "Low_Pass_Filter_Game_Param", rtpcValue2, 2 )  <--- Here you set the computed RTPC value in the SoundEngine.
--	print ("Low_Pass_Filter_Game_Param > RTPC value is now: '" .. aValueToSet[AK_GAMEPAD_ANALOG_06] .. "'")  <--- You can print the currentRTPC value to help you debug your script.

-- ==========================================================
function AnalogControl(AK_GAMEPAD_ANALOG_ID, min_GameParameterValue, max_GameParameterValue, incrementSlider, incrementMultiplicator )

	--We initialize the Analog Control range[-1,1] for the Thumbsticks here.
	--These values are used on: AK_PLATFORM_XBOX360, AK_PLATFORM_PS3 and AK_PLATFORM_.
	min_AnalogValue = -1
	max_AnalogValue = 1
	range_AnalogValue = (max_AnalogValue - min_AnalogValue) --2
	mid_AnalogValue = ((max_AnalogValue + min_AnalogValue) / 2) --0
	analogControlDirection = 1 --The default direction of the AnalogControl... the positive direction goes from left to right, or from bottom to top.

	--Here we deal with a special case: the Xbox360 and Wii Triggers (AK_GAMEPAD_ANALOG_05 and AK_GAMEPAD_ANALOG_06)
	--The Analog Control range is different: it's [0,255] for the Triggers.
	if( AK_PLATFORM_XBOX360 ) or (AK_PLATFORM_WII) then
		if (AK_GAMEPAD_ANALOG_ID == AK_GAMEPAD_ANALOG_05) or (AK_GAMEPAD_ANALOG_ID == AK_GAMEPAD_ANALOG_06) then
			min_AnalogValue = 0
			max_AnalogValue = 255
			range_AnalogValue = (max_AnalogValue - min_AnalogValue) --255
			mid_AnalogValue = ((max_AnalogValue + min_AnalogValue) / 2) --127
		end
	end
	
	if( AK_PLATFORM_PC) then
		--We defined the Windows Analog Control range for the Thumbsticks here.
		-- This is for the XBox360 controller only. Note: Each controller has it's own value.
		min_AnalogValue = 0
		max_AnalogValue = 65535
		range_AnalogValue = (max_AnalogValue - min_AnalogValue) --65535
		mid_AnalogValue = ((max_AnalogValue + min_AnalogValue) / 2) --32767

		--The direction of some AnalogControl axis is inverted on Windows(for AK_GAMEPAD_ANALOG_02 and AK_GAMEPAD_ANALOG_05). So, we switch the direction here.
		if (AK_GAMEPAD_ANALOG_ID == AK_GAMEPAD_ANALOG_02) or (AK_GAMEPAD_ANALOG_ID == AK_GAMEPAD_ANALOG_05) then
			analogControlDirection = -1
		end
	end
	
	if (AK_PLATFORM_WII) then
		--We defined the GameCube controller Analog Control range[-128,127] for the Thumbsticks here.
		min_AnalogValue = -128
		max_AnalogValue = 127
		range_AnalogValue = (max_AnalogValue - min_AnalogValue) --255
		mid_AnalogValue = ((max_AnalogValue + min_AnalogValue) / 2) --0
		analogControlDirection = 1 --The default direction of the AnalogControl... the positive direction goes from left to right, or from bottom to top.
	end
	
	
	--ERROR HANDLING: 
	--=======================================================
	if AK_GAMEPAD_ANALOG_ID == nil then
		LogTestMsg ("Your AK_GAMEPAD_ANALOG_ID was not defined!")
		LogTestMsg ("Please verify your function call.",666)
	end
	
	if min_GameParameterValue == nil then
		min_GameParameterValue = min_AnalogValue
	end
	
	if max_GameParameterValue == nil then
		max_GameParameterValue = max_AnalogValue
	end 
	 
	if incrementSlider == nil then
		incrementSlider = true
	end
	 
	if incrementMultiplicator == nil then
		incrementMultiplicator = 1
	end

	
	--=======================================================
	

	--We compute the Game Parameter range and middle value here.
	range_GameParameterValue = max_GameParameterValue - min_GameParameterValue
	mid_GameParameterValue = ((max_GameParameterValue + min_GameParameterValue) / 2)
	
	
	--We make sure the "aValueToSet" array exist. If not, we create it here.
	if aValueToSet == nil then	
		aValueToSet	= {}
	end
	
	
	--We make sure the "AK_GAMEPAD_ANALOG_ID"  index and value is in the array. If not, we create it here.
	if aValueToSet[AK_GAMEPAD_ANALOG_ID] == nil then

		aValueToSet[AK_GAMEPAD_ANALOG_ID] = mid_GameParameterValue --if there's no value set, set value to the mid_GameParameterValue

		--Here we deal with a special case: the Xbox360 Triggers  (AK_GAMEPAD_ANALOG_05 and AK_GAMEPAD_ANALOG_06)
		if( AK_PLATFORM_XBOX360 ) then
			if (AK_GAMEPAD_ANALOG_ID == AK_GAMEPAD_ANALOG_05) or (AK_GAMEPAD_ANALOG_ID == AK_GAMEPAD_ANALOG_06) then
				aValueToSet[AK_GAMEPAD_ANALOG_ID] = min_GameParameterValue --if there's no value set, set value to the min_GameParameterValue
			end
			
		end
		
	end
	
		--We only allow to reset the values if you are in increment mode, because it doesn't make sense in range mode.
		--NOTE: When both the AnalogControl and AnalogControlPos functions are used (at the same time and on the same buttons
		--of the controller to perform different operations), the reset operation is now applied in both functions, since I used "AkIsButtonPressed" in this function.
		--I originally used the AkLuaFramework "AkIsButtonPressedThisFrameInternal" function instead, but only 1 parameter was reset each time. 
		--The one from the function in which the button down operation was trapped and not the other one because the GameFrame
		--had changed after the coroutine.yield() was processed. In this case, the button down wasn't considered anymore because we weren't on the same GameFrame
		--than the one in which the button down operation was performed.
		if incrementSlider == true then
			-- Added this section to reset easily the RTPC to the "mid_GameParameterValue" using the Thumbstick button.
			if (AK_GAMEPAD_ANALOG_ID == AK_GAMEPAD_ANALOG_01) or (AK_GAMEPAD_ANALOG_ID == AK_GAMEPAD_ANALOG_02) then
				if (AK_PLATFORM_PC) then 
					if  AkIsButtonPressed( AK_GAMEPAD_BUTTON_09 ) then
						-- AK_GAMEPAD_BUTTON_09 = "Left thumb down"
						aValueToSet[AK_GAMEPAD_ANALOG_ID] = mid_GameParameterValue --reset value to the mid_GameParameterValue	
						return aValueToSet[AK_GAMEPAD_ANALOG_ID]
					end
					
				else 
					if  AkIsButtonPressed( AK_GAMEPAD_BUTTON_15 ) then
						-- AK_GAMEPAD_BUTTON_15 = "Left thumb down"
						aValueToSet[AK_GAMEPAD_ANALOG_ID] = mid_GameParameterValue --reset value to the mid_GameParameterValue	
						return aValueToSet[AK_GAMEPAD_ANALOG_ID]
					end
				end
				
			elseif (AK_GAMEPAD_ANALOG_ID == AK_GAMEPAD_ANALOG_04) or (AK_GAMEPAD_ANALOG_ID == AK_GAMEPAD_ANALOG_05) then
				if (AK_PLATFORM_PC) then 
					if  AkIsButtonPressed( AK_GAMEPAD_BUTTON_10 ) then
						-- AK_GAMEPAD_BUTTON_10 = "Right thumb down"
						aValueToSet[AK_GAMEPAD_ANALOG_ID] = mid_GameParameterValue --reset value to the mid_GameParameterValue
						return aValueToSet[AK_GAMEPAD_ANALOG_ID]
					end
					
				else 
					if  AkIsButtonPressed( AK_GAMEPAD_BUTTON_16 ) then
						-- AK_GAMEPAD_BUTTON_16= "Right thumb down"
						aValueToSet[AK_GAMEPAD_ANALOG_ID] = mid_GameParameterValue --reset value to the mid_GameParameterValue	
						return aValueToSet[AK_GAMEPAD_ANALOG_ID]
					end
				end
			end
		end

		--Get the currentAnalogPosition here.
		currentAnalogPosition = AkLuaGameEngine.GetAnalogStickPosition ( AK_GAMEPAD_ANALOG_ID )
		currentAnalogPositionNormalized = analogControlDirection * ((currentAnalogPosition - mid_AnalogValue)/(range_AnalogValue / 2))

		--Here we deal with a special case: The Xbox360 Triggers (AK_GAMEPAD_ANALOG_05 and AK_GAMEPAD_ANALOG_06)
		if( AK_PLATFORM_XBOX360 ) then
			if (AK_GAMEPAD_ANALOG_ID == AK_GAMEPAD_ANALOG_05) or (AK_GAMEPAD_ANALOG_ID == AK_GAMEPAD_ANALOG_06) then
				aValueToSet[AK_GAMEPAD_ANALOG_ID] =  min_GameParameterValue + ((currentAnalogPosition * range_GameParameterValue) / range_AnalogValue)
				return aValueToSet[AK_GAMEPAD_ANALOG_ID]
			end
		end
		
		--=====================================================================================
		--NOTE:
		--======
		--On (AK_PLATFORM_PC) the Left and Right Triggers are mapped on AK_GAMEPAD_ANALOG_03, 
		--where the Left Trigger Range = [32767,65407]
		--and the Right Trigger Range = [32767, 127].
		--=====================================================================================

		
		--Here's the Default code path. That is where the job gets done for the Analog Buttons (Triggers are handled in the  "if" section above). 
		if incrementSlider == true then
			if ( AK_PLATFORM_PC or AK_PLATFORM_PS3 ) then
				--Here, we create a "Dead Zone" for the AnalogControls on Windows.
				if (currentAnalogPositionNormalized > -0.1) and (currentAnalogPositionNormalized < 0.1) then
					aValueToSet[AK_GAMEPAD_ANALOG_ID] = aValueToSet[AK_GAMEPAD_ANALOG_ID]
				
				else
					aValueToSet[AK_GAMEPAD_ANALOG_ID] = aValueToSet[AK_GAMEPAD_ANALOG_ID] + (currentAnalogPositionNormalized * incrementMultiplicator)
				
				end
				
			else
				aValueToSet[AK_GAMEPAD_ANALOG_ID] = aValueToSet[AK_GAMEPAD_ANALOG_ID] + (currentAnalogPositionNormalized * incrementMultiplicator)
			end
			
			
			if aValueToSet[AK_GAMEPAD_ANALOG_ID] >= max_GameParameterValue then
				aValueToSet[AK_GAMEPAD_ANALOG_ID] = max_GameParameterValue
				
			elseif aValueToSet[AK_GAMEPAD_ANALOG_ID] <= min_GameParameterValue then
				aValueToSet[AK_GAMEPAD_ANALOG_ID] = min_GameParameterValue
				
			end

		-- Code path for: incrementSlider == false
		else
			aValueToSet[AK_GAMEPAD_ANALOG_ID] =  mid_GameParameterValue + ((currentAnalogPositionNormalized * range_GameParameterValue) / 2)

		end

		return aValueToSet[AK_GAMEPAD_ANALOG_ID]	
	
end

-- ==========================================================
--AnalogControlPos()

--This function will compute the current game frame "X" and "Y" position of a Game Object in your (game) World based on the previous game frame position and then return it.
-- It has it's own position array, so it remembers the previous game frame position and then compute and return the current game frame position.

-- This function works on the XBox360, PS3, Windows (using the Xbox360 controller) and Wii (using the GameCube controller).

--This function REQUIRES the following parameters:
--  	UseLeftThumbstick: i.e  true (defines which Thumbstick to use to compute the "X" and "Y" position; true = left, false = right)
--	gameObjectID: i.e. 2 (the GameObject assigned to this function)
--	min_XWorldLimit: i.e. -1000
--	max_XWorldLimit: i.e. 1000 
--	min_YWorldLimit: -1000
--	max_YWorldLimit: 1000
--	incrementSlider: i.e. true or false (True > incremental mode, False > range mode. There's more information below.)
--	incrementMultiplicator:  i.e. 10 (The maximum distance travelled in 1 footstep in your World.)
--		If the incrementSlider flag is "true", the thumbstick will work in incremental mode, 
--		where when we move the thumbstick, we increment the position value and where when it's in it's default position, we do nothing special and leave the current value as is.

--		If the incrementSlider flag is "false", the thumbstick will work in range mode, 
--		where when the thumbstick in it's default position we map the output value to the midX_WorldLimit & midY_WorldLimit value.


--The function RETURNS 2 values, the:
--	computed GameObject Position on the "X" axis: i.e. -12.5.
--	computed GameObject Position on the "Y" axis: i.e. 99.25
	
--Here's a short INTEGRATION EXAMPLE to help you with your script:
--	g_soundPos.Position.X, g_soundPos.Position.Y  = AnalogControlPos(true, 2, -1000, 1000, -1000, 1000, true, 10)  <---This will compute the (X, Y) position of your GameObject in your World using the LeftThumbstick values and return their value in the variable of your choice (g_soundPos.Position.X & g_soundPos.Position.Y in this case).	

--	AK.SoundEngine.SetPosition( 2, g_soundPos )  <--- Here you set the computed GameObject position on the (X,Y)  axis in the SoundEngine.

--	print ("PosX = "..g_soundPos.Position.X)  <--- You can print the current GameObject position on the "X" axis to help you debug your script.
--	print ("PosY = "..g_soundPos.Position.Y)  <--- You can print the current GameObject position on the "Y" axis to help you debug your script.

-- ==========================================================

function AnalogControlPos(UseLeftThumbstick, gameObjectID, min_XWorldLimit, max_XWorldLimit, min_YWorldLimit, max_YWorldLimit, incrementSlider, incrementMultiplicator )

	--We initialize the Analog Control range[-1,1] for the Thumbsticks here.
	--These values are used on :(AK_PLATFORM_XBOX360)  and (AK_PLATFORM_PS3).
	min_AnalogValue = -1
	max_AnalogValue = 1
	range_AnalogValue = (max_AnalogValue - min_AnalogValue) --2
	mid_AnalogValue = ((max_AnalogValue + min_AnalogValue) / 2) --0
	analogControlDirection = 1 --The default direction of the AnalogControl... the positive direction goes from left to right, or from bottom to top.
	
		
	if (AK_PLATFORM_PC) then
		--We defined the Windows Analog Control range for the Thumbsticks here.
		-- This is for the XBox360 controller only. Note: Each controller has it's own value.
		min_AnalogValue = 0
		max_AnalogValue = 65535
		range_AnalogValue = (max_AnalogValue - min_AnalogValue) --65535
		mid_AnalogValue = ((max_AnalogValue + min_AnalogValue) / 2) --32767
	end
	
	if (AK_PLATFORM_WII) then
		--We defined the GameCube controller Analog Control range[-128,127] for the Thumbsticks here.
		min_AnalogValue = -128
		max_AnalogValue = 127
		range_AnalogValue = (max_AnalogValue - min_AnalogValue) --255
		mid_AnalogValue = ((max_AnalogValue + min_AnalogValue) / 2) --0
		analogControlDirection = 1 --The default direction of the AnalogControl... the positive direction goes from left to right, or from bottom to top.
	end
	
	--Here we initialize the Position X and Y variables.
	PositionX = 0	--this is the index of the current PositionX entry in the table
	PositionY = 1	--this is the index of the current PositionY entry in the table


	--ERROR HANDLING: 
	--=======================================================
	
	if 	UseLeftThumbstick == nil then
		LogTestMsg ("The UseLeftThumbstick option was not defined!")
		LogTestMsg ("Please verify your function call.",666)
	end
	
	if gameObjectID == nil then
		LogTestMsg ("The GameObjectID was not defined!")
		LogTestMsg ("Please verify your function call.",666)
	end
	
	if min_XWorldLimit == nil then
		min_XWorldLimit = -100
	end
	
	if max_XWorldLimit == nil then
		max_XWorldLimit = 100
	end 
	
	if min_YWorldLimit == nil then
		min_YWorldLimit = -100
	end
	
	if max_YWorldLimit == nil then
		max_YWorldLimit = 100
	end 
	 
	if incrementMultiplicator == nil then
		incrementMultiplicator = 1
	end
	--=======================================================
	
	
	--We compute the Game Parameter range and middle value here.
	rangeX_WorldLimit = max_XWorldLimit - min_XWorldLimit
	rangeY_WorldLimit = max_YWorldLimit - min_YWorldLimit
	midX_WorldLimit = (max_XWorldLimit + min_XWorldLimit) / 2
	midY_WorldLimit = (max_YWorldLimit + min_YWorldLimit) / 2

	
		--We make sure the "aValueToSet" array exist. If not, we create it here.
	if aGameObjPos == nil then	
		aGameObjPos	= {}
	end
	
	-- We make sure the "UseLeftThumbstick" array exist. If not, we create it here.
	if aGameObjPos[UseLeftThumbstick] == nil then
		aGameObjPos[UseLeftThumbstick] = {}
	end
	
	-- We make sure the "gameObjectID" array exist. If not, we create it here.
	if aGameObjPos[UseLeftThumbstick][gameObjectID] == nil then
		aGameObjPos[UseLeftThumbstick][gameObjectID] = {}
	end

	
	-- If PositionX doesn't exist, create and set it's value to 0.
	if aGameObjPos[UseLeftThumbstick][gameObjectID][PositionX] == nil then
		aGameObjPos[UseLeftThumbstick][gameObjectID][PositionX] = 0
	end
	

	-- If PositionY doesn't exist, create and set it's value to 0.
	if aGameObjPos[UseLeftThumbstick][gameObjectID][PositionY] == nil then
		aGameObjPos[UseLeftThumbstick][gameObjectID][PositionY] = 0
	end

	
	--The  code for this function starts here.
	--===========================================

	--We only allow to reset the values if you are in increment mode, because it doesn't make sense in range mode.
	--NOTE: When both the AnalogControl and AnalogControlPos functions are used (at the same time and on the same buttons
	--of the controller to perform different operations), the reset operation is now applied in both functions, since I used "AkIsButtonPressed" in this function.
	--I originally used the AkLuaFramework "AkIsButtonPressedThisFrameInternal" function instead, but only 1 parameter was reset each time. 
	--The one from the function in which the button down operation was trapped and not the other one because the GameFrame
	--had changed after the coroutine.yield() was processed. In this case, the button down wasn't considered anymore because we weren't on the same GameFrame
	--than the one in which the button down operation was performed.
	if incrementSlider == true then
		-- Added this section to reset easily the Position to (0,0) using the Left Thumbstick button.
		if UseLeftThumbstick == true then
			if (AK_PLATFORM_PC) then 
				if  AkIsButtonPressed( AK_GAMEPAD_BUTTON_09 ) then  -- AK_GAMEPAD_BUTTON_09 = "Left thumb down"	 
					aGameObjPos[UseLeftThumbstick][gameObjectID][PositionX] = 0 --resets the Left_Right axis position to 0.
					aGameObjPos[UseLeftThumbstick][gameObjectID][PositionY] = 0 --resets the Front_Back axis position to 0.
					return (aGameObjPos[UseLeftThumbstick][gameObjectID][PositionX]), (aGameObjPos[UseLeftThumbstick][gameObjectID][PositionY]) --Exit current function and return gameObjPosX and gameObjPosY.
				end
				
			else
				if  AkIsButtonPressed( AK_GAMEPAD_BUTTON_15 ) then	 -- AK_GAMEPAD_BUTTON_15 = "Left thumb down"
					aGameObjPos[UseLeftThumbstick][gameObjectID][PositionX] = 0 --resets the Left_Right axis position to 0.
					aGameObjPos[UseLeftThumbstick][gameObjectID][PositionY] = 0 --resets the Front_Back axis position to 0.
					return (aGameObjPos[UseLeftThumbstick][gameObjectID][PositionX]), (aGameObjPos[UseLeftThumbstick][gameObjectID][PositionY]) --Exit current function and return gameObjPosX and gameObjPosY.
				end
			end
			
		-- Added this section to reset easily the Position to (0,0) using the Right Thumbstick button.
		else
			if (AK_PLATFORM_PC) then 
				if  AkIsButtonPressed( AK_GAMEPAD_BUTTON_10 ) then -- AK_GAMEPAD_BUTTON_10 = "Right thumb down"
					aGameObjPos[UseLeftThumbstick][gameObjectID][PositionX] = 0 --resets the Left_Right axis position to 0.
					aGameObjPos[UseLeftThumbstick][gameObjectID][PositionY] = 0 --resets the Front_Back axis position to 0.				
					return (aGameObjPos[UseLeftThumbstick][gameObjectID][PositionX]), (aGameObjPos[UseLeftThumbstick][gameObjectID][PositionY]) --Exit current function and return gameObjPosX and gameObjPosY.
				end
				
			else  
				if AkIsButtonPressed( AK_GAMEPAD_BUTTON_16 ) then	 -- AK_GAMEPAD_BUTTON_16 = "Right thumb down"
					aGameObjPos[UseLeftThumbstick][gameObjectID][PositionX] = 0 --resets the Left_Right axis position to 0.
					aGameObjPos[UseLeftThumbstick][gameObjectID][PositionY] = 0 --resets the Front_Back axis position to 0.
					return (aGameObjPos[UseLeftThumbstick][gameObjectID][PositionX]), (aGameObjPos[UseLeftThumbstick][gameObjectID][PositionY]) --Exit current function and return gameObjPosX and gameObjPosY.
				end
			end
		end
	end
	
	
	if (AK_PLATFORM_PC) then
		--Get the currentAnalogPosition from the "Left" Thumbstick here.		
		if UseLeftThumbstick == true then
			currentAnalogPositionX = AkLuaGameEngine.GetAnalogStickPosition ( AK_GAMEPAD_ANALOG_01 )
			currentAnalogPositionY = AkLuaGameEngine.GetAnalogStickPosition ( AK_GAMEPAD_ANALOG_02 )

		--Get the currentAnalogPosition from the "Right" Thumbstick here.
		else
			currentAnalogPositionX = AkLuaGameEngine.GetAnalogStickPosition ( AK_GAMEPAD_ANALOG_04 )
			currentAnalogPositionY = AkLuaGameEngine.GetAnalogStickPosition ( AK_GAMEPAD_ANALOG_05 )
		end
		
		--The direction of some AnalogControl axis is inverted on Windows(for AK_GAMEPAD_ANALOG_02 and AK_GAMEPAD_ANALOG_05). So, we switch the direction here using "-(analogControlDirection)".
		currentAnalogPositionYNormalized = -(analogControlDirection) * ((currentAnalogPositionY - mid_AnalogValue)/(range_AnalogValue / 2))

		
	else
		--Get the currentAnalogPosition from the "Left" Thumbstick here.		
		if UseLeftThumbstick == true then
			currentAnalogPositionX = AkLuaGameEngine.GetAnalogStickPosition ( AK_GAMEPAD_ANALOG_01 )
			currentAnalogPositionY = AkLuaGameEngine.GetAnalogStickPosition ( AK_GAMEPAD_ANALOG_02 )

		--Get the currentAnalogPosition from the "Right" Thumbstick here.
		else
			currentAnalogPositionX = AkLuaGameEngine.GetAnalogStickPosition ( AK_GAMEPAD_ANALOG_03 )
			currentAnalogPositionY = AkLuaGameEngine.GetAnalogStickPosition ( AK_GAMEPAD_ANALOG_04 )
		
		end
		currentAnalogPositionYNormalized = analogControlDirection * ((currentAnalogPositionY - mid_AnalogValue)/(range_AnalogValue / 2))

	end
	
	currentAnalogPositionXNormalized = analogControlDirection * ((currentAnalogPositionX - mid_AnalogValue)/(range_AnalogValue / 2))

	
	if incrementSlider == true then
		if ( AK_PLATFORM_PC or AK_PLATFORM_PS3) then
			--Here, we create a "Dead Zone" on the X axis  for the AnalogControls on Windows.
			if (currentAnalogPositionXNormalized > -0.2) and (currentAnalogPositionXNormalized < 0.2) then
				aGameObjPos[UseLeftThumbstick][gameObjectID][PositionX] = aGameObjPos[UseLeftThumbstick][gameObjectID][PositionX]
						
			else
				--Set the new currentAnalogPosition here.
				aGameObjPos[UseLeftThumbstick][gameObjectID][PositionX] = aGameObjPos[UseLeftThumbstick][gameObjectID][PositionX] + (currentAnalogPositionXNormalized * incrementMultiplicator)
			end
			
			--Here, we create a "Dead Zone" on the Y axis for the AnalogControls on Windows.
			if (currentAnalogPositionYNormalized > -0.2) and (currentAnalogPositionYNormalized < 0.2) then
				aGameObjPos[UseLeftThumbstick][gameObjectID][PositionY] = aGameObjPos[UseLeftThumbstick][gameObjectID][PositionY]
						
			else
				--Set the new currentAnalogPosition here.
				aGameObjPos[UseLeftThumbstick][gameObjectID][PositionY] = aGameObjPos[UseLeftThumbstick][gameObjectID][PositionY] + (currentAnalogPositionYNormalized * incrementMultiplicator)
			end
			
		else
			--Set the new currentAnalogPosition here.
			aGameObjPos[UseLeftThumbstick][gameObjectID][PositionX] = aGameObjPos[UseLeftThumbstick][gameObjectID][PositionX] + (currentAnalogPositionXNormalized * incrementMultiplicator)
			aGameObjPos[UseLeftThumbstick][gameObjectID][PositionY] = aGameObjPos[UseLeftThumbstick][gameObjectID][PositionY] + (currentAnalogPositionYNormalized * incrementMultiplicator)
		end
		
		--Here we make sure we don't bust the Min and Max "X" WorldLimit value.
		if aGameObjPos[UseLeftThumbstick][gameObjectID][PositionX] >= max_XWorldLimit  then
			aGameObjPos[UseLeftThumbstick][gameObjectID][PositionX] = max_XWorldLimit

		elseif aGameObjPos[UseLeftThumbstick][gameObjectID][PositionX] <= min_XWorldLimit  then
			aGameObjPos[UseLeftThumbstick][gameObjectID][PositionX] = min_XWorldLimit
		
		end
		
		--Here we make sure we don't bust the Min and Max "Y" WorldLimit value.
		if aGameObjPos[UseLeftThumbstick][gameObjectID][PositionY] >= max_YWorldLimit  then
			aGameObjPos[UseLeftThumbstick][gameObjectID][PositionY] = max_YWorldLimit

		elseif aGameObjPos[UseLeftThumbstick][gameObjectID][PositionY] <= min_YWorldLimit  then
			aGameObjPos[UseLeftThumbstick][gameObjectID][PositionY] = min_YWorldLimit

		end

	-- Code path for: incrementSlider == false
	else
		aGameObjPos[UseLeftThumbstick][gameObjectID][PositionX] =  midX_WorldLimit + ((currentAnalogPositionXNormalized * rangeX_WorldLimit) / 2)
		aGameObjPos[UseLeftThumbstick][gameObjectID][PositionY] =  midY_WorldLimit + ((currentAnalogPositionYNormalized * rangeY_WorldLimit) / 2)
	end

	return (aGameObjPos[UseLeftThumbstick][gameObjectID][PositionX]), (aGameObjPos[UseLeftThumbstick][gameObjectID][PositionY]) --Exit current function and return gameObjPosX and gameObjPosY.
	
end

-- ==========================================================
--AnalogControlPosLight()

--This function will use the Analog Control position to compute and return a "X" and "Y" (game object position) increment value between 0 and 1, 
-- if no increment multiplicator is specified. In this case, it will use the default incrementMultiplicator = 1.

-- This function works on the XBox360, PS3, Windows (using the Xbox360 controller) and Wii (using the GameCube controller).

--This function REQUIRES the following parameters:
--  	UseLeftThumbstick: i.e  true (defines which Thumbstick to use to compute the "X" and "Y" position; true = left, false = right)
--	incrementMultiplicatorX/incrementMultiplicatorY:  i.e. 10 (The maximum increment travelled in 1 footstep in your World.)

--The function RETURNS 2 values, the:
--	computed Position Increment on the "X" axis,: i.e. -12.5.
--	computed Position Increment on the "Y" axis: i.e. 99.25
	
--Here's a short INTEGRATION EXAMPLE to help you with your script:
--	positionIncrementX, positionIncrementX  = AnalogControlPosLight(true, 10, 20)  <---This will compute the (X, Y) position increment using the LeftThumbstick values and return their value in the variable of your choice (positionIncrementX & positionIncrementY in this case).	
--	aPlayerPos[kPosX] = aPlayerPos[kPosX] + positionIncrementX
--	aPlayerPos[kPosY] = aPlayerPos[kPosY] + positionIncrementY
--	AK.SoundEngine.SetPosition( 2, aPlayerPos )  <--- Here you set the computed GameObject position on the (X,Y)  axis in the SoundEngine.

--	print ("PosX = "..aPlayerPos[kPosX])  <--- You can print the current GameObject position on the "X" axis to help you debug your script.
--	print ("PosY = "..aPlayerPos[kPosY])  <--- You can print the current GameObject position on the "Y" axis to help you debug your script.

-- ==========================================================

function AnalogControlPosLight (UseLeftThumbstick, incrementMultiplicatorX, incrementMultiplicatorY )

	--We initialize the Analog Control range[-1,1] for the Thumbsticks here.
	--These values are used on :(AK_PLATFORM_XBOX360)  and (AK_PLATFORM_PS3).
	min_AnalogValue = -1
	max_AnalogValue = 1
	range_AnalogValue = (max_AnalogValue - min_AnalogValue) --2
	mid_AnalogValue = ((max_AnalogValue + min_AnalogValue) / 2) --0
	analogControlDirection = 1 --The default direction of the AnalogControl... the positive direction goes from left to right, or from bottom to top.
	
		
	if (AK_PLATFORM_PC) then
		--We defined the Windows Analog Control range for the Thumbsticks here.
		-- This is for the XBox360 controller only. Note: Each controller has it's own value.
		min_AnalogValue = 0
		max_AnalogValue = 65535
		range_AnalogValue = (max_AnalogValue - min_AnalogValue) --65535
		mid_AnalogValue = ((max_AnalogValue + min_AnalogValue) / 2) --32767
	end
	
	if (AK_PLATFORM_WII) then
		--We defined the GameCube controller Analog Control range[-128,127] for the Thumbsticks here.
		min_AnalogValue = -128
		max_AnalogValue = 127
		range_AnalogValue = (max_AnalogValue - min_AnalogValue) --255
		mid_AnalogValue = ((max_AnalogValue + min_AnalogValue) / 2) --0
		analogControlDirection = 1 --The default direction of the AnalogControl... the positive direction goes from left to right, or from bottom to top.
	end

	--ERROR HANDLING: 
	--=======================================================
	
	if 	UseLeftThumbstick == nil then
		LogTestMsg ("The UseLeftThumbstick option was not defined!")
		LogTestMsg ("Please verify your function call.",666)
	end
	 
	if incrementMultiplicatorX == nil then
		incrementMultiplicatorX = 1
	end
	
	if incrementMultiplicatorY == nil then
		incrementMultiplicatorY = 1
	end
	--=======================================================

	
	--The  code for this function starts here.
	--===========================================
	
	if (AK_PLATFORM_PC) then
		--Get the currentAnalogPosition from the "Left" Thumbstick here.		
		if UseLeftThumbstick == true then
			currentAnalogPositionX = AkLuaGameEngine.GetAnalogStickPosition ( AK_GAMEPAD_ANALOG_01 )
			currentAnalogPositionY = AkLuaGameEngine.GetAnalogStickPosition ( AK_GAMEPAD_ANALOG_02 )

		--Get the currentAnalogPosition from the "Right" Thumbstick here.
		else
			currentAnalogPositionX = AkLuaGameEngine.GetAnalogStickPosition ( AK_GAMEPAD_ANALOG_04 )
			currentAnalogPositionY = AkLuaGameEngine.GetAnalogStickPosition ( AK_GAMEPAD_ANALOG_05 )
		end
		
		--The direction of some AnalogControl axis is inverted on Windows(for AK_GAMEPAD_ANALOG_02 and AK_GAMEPAD_ANALOG_05). So, we switch the direction here using "-(analogControlDirection)".
		currentAnalogPositionYNormalized = -(analogControlDirection) * ((currentAnalogPositionY - mid_AnalogValue)/(range_AnalogValue / 2))

		
	else
		--Get the currentAnalogPosition from the "Left" Thumbstick here.		
		if UseLeftThumbstick == true then
			currentAnalogPositionX = AkLuaGameEngine.GetAnalogStickPosition ( AK_GAMEPAD_ANALOG_01 )
			currentAnalogPositionY = AkLuaGameEngine.GetAnalogStickPosition ( AK_GAMEPAD_ANALOG_02 )

		--Get the currentAnalogPosition from the "Right" Thumbstick here.
		else
			currentAnalogPositionX = AkLuaGameEngine.GetAnalogStickPosition ( AK_GAMEPAD_ANALOG_03 )
			currentAnalogPositionY = AkLuaGameEngine.GetAnalogStickPosition ( AK_GAMEPAD_ANALOG_04 )
		
		end
		currentAnalogPositionYNormalized = analogControlDirection * ((currentAnalogPositionY - mid_AnalogValue)/(range_AnalogValue / 2))

	end
	
	currentAnalogPositionXNormalized = analogControlDirection * ((currentAnalogPositionX - mid_AnalogValue)/(range_AnalogValue / 2))
	--print (currentAnalogPositionXNormalized, currentAnalogPositionYNormalized)
	
		if ( AK_PLATFORM_PC or AK_PLATFORM_PS3 ) then
			--Here, we create a "Dead Zone" on the X axis  for the AnalogControls on Windows.
			if (currentAnalogPositionXNormalized > -0.2) and (currentAnalogPositionXNormalized < 0.2) then
				positionIncrementX = 0
						
			else
				--Set the new currentAnalogPosition here.
				positionIncrementX = (currentAnalogPositionXNormalized * incrementMultiplicatorX)
			end
			
			--Here, we create a "Dead Zone" on the Y axis for the AnalogControls on Windows.
			if (currentAnalogPositionYNormalized > -0.2) and (currentAnalogPositionYNormalized < 0.2) then
				positionIncrementY = 0
						
			else
				--Set the new currentAnalogPosition here.
				positionIncrementY = (currentAnalogPositionYNormalized * incrementMultiplicatorY)

			end
			
		else
			--Set the new currentAnalogPosition here.
			positionIncrementX = (currentAnalogPositionXNormalized * incrementMultiplicatorX)
			positionIncrementY = (currentAnalogPositionYNormalized * incrementMultiplicatorY)

		end
	--print ("CurrentAnalogPos:" .. currentAnalogPositionX,currentAnalogPositionY)
	--print ("posincrementX-Y:" .. positionIncrementX, positionIncrementY)
	return positionIncrementX, positionIncrementY --Exit current function and return gameObjPosX and gameObjPosY.
	
end


-- ==========================================================
-- AkIsTriggerPressedThisFrame(AK_GAMEPAD_ANALOG_ID)

--This function check if the Trigged button is pressed in the current game frame.

-- This function works on the XBox360, Windows (using the Xbox360 controller) and Wii (using the GameCube controller).

--This function REQUIRES the following parameter:
--	AK_GAMEPAD_ANALOG_ID (the specific Trigger (ANALOG BUTTON)  you assigned to this function):
	-- AK_GAMEPAD_ANALOG_05 or AK_GAMEPAD_ANALOG_06 on XBOX360 or Wii. 
	-- AK_GAMEPAD_ANALOG_03 or AK_GAMEPAD_ANALOG_06 on Windows. 

--The function RETURNS :
-- "true" if and only if the Trigged button is pressed in the current game frame.

	
--Here's a short INTEGRATION EXAMPLE to help you with your script:
--		if (AK_PLATFORM_PC) and (AkIsTriggerPressedThisFrame ( AK_GAMEPAD_ANALOG_06 ))
--		then
--			buttonPressed = fireButton
--			return buttonPressed
--		end
-- ==========================================================

-- Tables to remember which buttons were pressed. 
kTriggerCurrentlyDown = { }
	
function AkIsTriggerPressedThisFrame(AK_GAMEPAD_ANALOG_ID)
	if( kTriggerCurrentlyDown[ AK_GAMEPAD_ANALOG_ID ] == true) then -- button already pressed
		return false

	else
		--Here we deal with the Xbox360 and Wii Triggers.
		--The Analog Control range is different: it's [0,255] for the Triggers.
		if ( AK_PLATFORM_XBOX360 ) or (AK_PLATFORM_WII) then

			if (not((AK_GAMEPAD_ANALOG_ID == AK_GAMEPAD_ANALOG_05) or (AK_GAMEPAD_ANALOG_ID == AK_GAMEPAD_ANALOG_06))) then
				LogTestMsg("This function is for Controller Triggers only.")
				LogTestMsg ("Please verify your function call.",666)
				return
			end
			
			if (( AkLuaGameEngine.GetAnalogStickPosition ( AK_GAMEPAD_ANALOG_ID ) ) >= 240) then
				kTriggerCurrentlyDown[ AK_GAMEPAD_ANALOG_ID ] = true
				return true
			else
				if kTriggerCurrentlyDown[ AK_GAMEPAD_ANALOG_ID ] == nil then
					kTriggerCurrentlyDown[ AK_GAMEPAD_ANALOG_ID ] = false
				end
				
				kTriggerCurrentlyDown[ AK_GAMEPAD_ANALOG_ID ] = false
				return false
			end
		end	
		--Here we deal with the Windows Triggers. The values given by the controller Triggers are: 
		-- Both triggers not pressed = 32767 , Left trigger down = 65407, Right trigger down = 127
		if (AK_PLATFORM_PC) then
		
			if (not((AK_GAMEPAD_ANALOG_ID == AK_GAMEPAD_ANALOG_03) or (AK_GAMEPAD_ANALOG_ID == AK_GAMEPAD_ANALOG_06))) then
				LogTestMsg("This function is for Controller Triggers only.")
				LogTestMsg ("Please verify your function call.",666)
				return
			end
			
			if (( AkLuaGameEngine.GetAnalogStickPosition ( AK_GAMEPAD_ANALOG_ID ) ) >= 65390) then
				kTriggerCurrentlyDown[ AK_GAMEPAD_ANALOG_ID ] = true
				return true
				
			elseif (( AkLuaGameEngine.GetAnalogStickPosition ( AK_GAMEPAD_ANALOG_ID ) ) <= 140) then
				kTriggerCurrentlyDown[ AK_GAMEPAD_ANALOG_ID ] = true
				return true
				
			else
				if kTriggerCurrentlyDown[ AK_GAMEPAD_ANALOG_ID ] == nil then
					kTriggerCurrentlyDown[ AK_GAMEPAD_ANALOG_ID ] = false
				end
				
				kTriggerCurrentlyDown[ AK_GAMEPAD_ANALOG_ID ] = false
				return false
			end
		end	
	end
end	


-- ==========================================================
-- AkTriggerCleanUp()

-- This method is used to avoid recognizing a Trigger button being pressed twice in the same game frame.
-- The function updates the state of the Trigger from 1 game frame to another in order to prevent any repetition if the Trigger was never release.

-- This function works on the XBox360, Windows (using the Xbox360 controller) and Wii (using the GameCube controller).

--This function doesn't REQUIRE any parameter.
	
--Here's a short INTEGRATION EXAMPLE to help you with your script:
--		while (not(gameOver)) do
--			if (AK_PLATFORM_PC) and (AkIsTriggerPressedThisFrame ( AK_GAMEPAD_ANALOG_06 ))
--			then
--				buttonPressed = fireButton
--			else
--				buttonPressed = nil
--			end
--
--			(...)
--
-- 			if (buttonPressed == fireButton)  then
--				AK.SoundEngine.PostEvent( "Play_GunsShot", kPlayer )
--				coroutine.yield()
--			end

--			AkTriggerCleanUp()
--		end
-- ==========================================================
function AkTriggerCleanUp()
	for AK_GAMEPAD_ANALOG_ID,bIsKeyDown in pairs( kTriggerCurrentlyDown ) do
		--Here we deal with the Xbox360 and Wii Triggers.
		--The Analog Control range is [0,255] for the Triggers.
		if ( AK_PLATFORM_XBOX360 ) or (AK_PLATFORM_WII) then
			if ((AkLuaGameEngine.GetAnalogStickPosition ( AK_GAMEPAD_ANALOG_ID ) ) >= 240) then
				kTriggerCurrentlyDown[ AK_GAMEPAD_ANALOG_ID ] = true
			else
				kTriggerCurrentlyDown[ AK_GAMEPAD_ANALOG_ID ] = false
			end
		end	
		
		--Here we deal with the Windows Triggers. The values given by the controller Triggers are: 
		-- Both triggers not pressed = 32767 , Left trigger down = 65407, Right trigger down = 127
		if (AK_PLATFORM_PC) then
			if ((AkLuaGameEngine.GetAnalogStickPosition ( AK_GAMEPAD_ANALOG_ID ) ) >= 65390) then
				kTriggerCurrentlyDown[ AK_GAMEPAD_ANALOG_ID ] = true
				
			elseif (( AkLuaGameEngine.GetAnalogStickPosition ( AK_GAMEPAD_ANALOG_ID ) ) <= 140) then
				kTriggerCurrentlyDown[ AK_GAMEPAD_ANALOG_ID ] = true
			
			else 
				kTriggerCurrentlyDown[ AK_GAMEPAD_ANALOG_ID ] = false
			end	
		end
	end
end

-- ==========================================================
--AkStartOutputCapture()
--This function uses the default Sound Engine function along with an additional 50 ms Delay afterward
--to make sure the Sound Engine has enough time to start the Capture before the sounds starts playing.
-- See http://srv-techno/jira/browse/WG-10133 for more information
-- ==========================================================
function AkStartOutputCapture( in_filename )
	if ( AK.SoundEngine.IsInitialized() ) then		
		AK.SoundEngine.StartOutputCapture( in_filename )
		Wait(50)
	end
end

function AkStopOutputCapture( )
	if ( AK.SoundEngine.IsInitialized() ) then
		Wait(100)	--To have a bit of silence at the end.  It is more natural when listening
		AK.SoundEngine.StopOutputCapture( )		
	end
end


-- ==========================================================
--AkStartProfilerCapture()
--This function uses the default Sound Engine function, but also appends the current date and time 
--to each filename in order to keep a copy of every Game Profiler Capture session.
-- ==========================================================
function AkStartProfilerCapture( in_filename )
	if ( AK.SoundEngine.IsInitialized() ) then		
		AK.SoundEngine.StartProfilerCapture(in_filename)
	end
end

function AkStopProfilerCapture()
	if ( AK.SoundEngine.IsInitialized() ) then
		AK.SoundEngine.StopProfilerCapture()	
	end
end


-- ==========================================================
--AkInitializeAllRumbleDevice()
--Initializes every rumble controller regardless of the platform or type (DirectInput or XInput)
-- ==========================================================
function AkInitializeAllRumbleDevice()

	if AK_PLATFORM_HAS_MOTION then

		AK.MotionEngine.RegisterMotionDevice(AKCOMPANYID_AUDIOKINETIC, AKMOTIONDEVICEID_RUMBLE, AkCreateRumblePlugin)
		
		if AK_PLATFORM_PC and not AkLuaGameEngine.IsOffline() then
			dev = AkMotionControllersDevice:new_local()
			GetConnectedControllerDevice(dev)
					
			for i = 0, dev.XInputCount-1 do		
				AK.MotionEngine.AddPlayerMotionDevice(i, AKCOMPANYID_AUDIOKINETIC, AKMOTIONDEVICEID_RUMBLE)					
				LogTestMsg ("Registered 'XInput' ControllerID # ".. i)
			end		

			for i = 0, dev.DirectInputCount-1 do				
				AK.MotionEngine.AddPlayerMotionDevice(i+dev.XInputCount, AKCOMPANYID_AUDIOKINETIC, AKMOTIONDEVICEID_RUMBLE, i, dev)				
				LogTestMsg ("Registered 'DirectInput' ControllerID # ".. i+dev.XInputCount)
			end		
		else
			for i = 0, 3 do
				AK.MotionEngine.AddPlayerMotionDevice(i, AKCOMPANYID_AUDIOKINETIC, AKMOTIONDEVICEID_RUMBLE)
			end
		end
		
	else
		LogTestMsg ( ">>>   Skipping 'Initialize All Rumble Device'...   <<<")
		LogTestMsg ( ">>>   Motion is NOT supported on the MAC.   <<<",666)
	end
end


-- ==========================================================
--AkInitializeRumbleDevice()
--Initializes the specified rumble controller regardless of the platform or type (DirectInput or XInput)
-- ==========================================================
function AkInitializeRumbleDevice(controllerID, listenerID)

	if AK_PLATFORM_HAS_MOTION then
	
		if (controllerID == nil) and (listenerID == nil) then
			AutoLogTestMsg ("ERROR:",1,0)
			AutoLogTestMsg ("You must specify a 'controllerID' & 'listenerID' when using the 'AkInitializeRumbleDevice' function. Please update your script and run it again.",0,1)
		end
		
		AK.MotionEngine.RegisterMotionDevice(AKCOMPANYID_AUDIOKINETIC, AKMOTIONDEVICEID_RUMBLE, AkCreateRumblePlugin)

		if( AK_PLATFORM_PC) then
			dev = AkMotionControllersDevice:new_local()
			GetConnectedControllerDevice(dev)
			
			if dev.XInputCount > 0 then
			
				if 	dev.XInputCount <= controllerID then 
					--XInput and DirectInput controllers are listed in separate arrays. 
					--The "dev" structure contains only 1 array... the list of DirectInput devices.
					--Indexes in both arrays start at 0. Controller ID's are assigned to XInput devices first.
					--That's why we need to do 'controllerID-dev.XInputCount' in order to assign
					--the right DirectInput controller from the array to the controllerID.
					AK.MotionEngine.AddPlayerMotionDevice(controllerID, AKCOMPANYID_AUDIOKINETIC, AKMOTIONDEVICEID_RUMBLE, controllerID-dev.XInputCount, dev)	
					LogTestMsg("Registered 'DirectInput' controller # ".. controllerID)

				else
					AK.MotionEngine.AddPlayerMotionDevice(controllerID, AKCOMPANYID_AUDIOKINETIC, AKMOTIONDEVICEID_RUMBLE)	
					LogTestMsg ("Registered 'XInput' controller # ".. controllerID)
				end

			else
				AK.MotionEngine.AddPlayerMotionDevice(controllerID, AKCOMPANYID_AUDIOKINETIC, AKMOTIONDEVICEID_RUMBLE, controllerID, dev)	
				LogTestMsg("Registered 'DirectInput' controller # ".. controllerID)
			end
			
		else
			AK.MotionEngine.AddPlayerMotionDevice(controllerID, AKCOMPANYID_AUDIOKINETIC, AKMOTIONDEVICEID_RUMBLE)	
			LogTestMsg ("Registered controller # ".. controllerID)
		end

		if listenerID ~= nil then
			AK.MotionEngine.SetPlayerListener(controllerID, listenerID)
			LogTestMsg ("Controller '"..controllerID.."' was assigned to Listener '"..listenerID.."'.",666)

		else
			AutoLogTestMsg ("Don't forget to assign your ControllerID/Player to a Listener using 'AK.MotionEngine.SetPlayerListener'.",0,1)
		end
	
	else
		LogTestMsg ( ">>>   Skipping 'Initialize Rumble Device'...   <<<")
		LogTestMsg ( ">>>   Motion is NOT supported on the MAC.   <<<",666)
	end
end


--==========================================================
--AkRegisterMotionPlugIns()
--Add this function to your Coroutine array in order to allow you to easily register the Motion PlugIns for Controller1 and GameObject2.
--==========================================================
function AkRegisterMotionPlugIns()
	
	if AK_PLATFORM_HAS_MOTION then
		
		continueScriptFlag = false
		allDisabledFlag  = false
		
		if( ( AK_PLATFORM_PC and AkLuaGameEngine.IsGamepadConnected() ) ) then
			D_BOXEnabled = AK_GAMEPAD_BUTTON_01
			D_BOXEnabled_String = "A"
			ControllerEnabled = AK_GAMEPAD_BUTTON_02
			ControllerEnabled_String = "B" 		
			AllEnabled = AK_GAMEPAD_BUTTON_03
			AllEnabled_String = "X"
			AllDisabled = AK_GAMEPAD_BUTTON_04
			AllDisabled_String = "Y"
		
		elseif( ( AK_PLATFORM_PC) and (not(AkLuaGameEngine.IsGamepadConnected() ) ) ) then
			D_BOXEnabled = "1"
			D_BOXEnabled_String = "1"
			AllDisabled = "2"
			AllDisabled_String = "2"
			
		elseif (AK_PLATFORM_XBOX360) then
			--D_BOXEnabled = AK_GAMEPAD_BUTTON_01
			--D_BOXEnabled_String = "A"
			ControllerEnabled = AK_GAMEPAD_BUTTON_05
			ControllerEnabled_String = "Left shoulder" 		
			--AllEnabled = AK_GAMEPAD_BUTTON_03
			--AllEnabled_String = "X"
			AllDisabled = AK_GAMEPAD_BUTTON_06
			AllDisabled_String = "Right shoulder"

		elseif (AK_PLATFORM_PS3) then
			-- D_BOXEnabled = AK_GAMEPAD_BUTTON_01
			-- D_BOXEnabled_String = "Cross"
			ControllerEnabled = AK_GAMEPAD_BUTTON_05
			ControllerEnabled_String = "L1" 		
			-- AllEnabled = AK_GAMEPAD_BUTTON_03
			-- AllEnabled_String = "Square"
			AllDisabled = AK_GAMEPAD_BUTTON_06
			AllDisabled_String = "R1"

		elseif (AK_PLATFORM_PS4) then
			-- D_BOXEnabled = AK_GAMEPAD_BUTTON_01
			-- D_BOXEnabled_String = "Cross"
			ControllerEnabled = AK_GAMEPAD_BUTTON_05
			ControllerEnabled_String = "L1" 		
			-- AllEnabled = AK_GAMEPAD_BUTTON_03
			-- AllEnabled_String = "Square"
			AllDisabled = AK_GAMEPAD_BUTTON_06
			AllDisabled_String = "R1"
			
		elseif (AK_PLATFORM_WII) then
			-- D_BOXEnabled = AK_GAMEPAD_BUTTON_01
			-- D_BOXEnabled_String = "A"
			ControllerEnabled = AK_GAMEPAD_BUTTON_06
			ControllerEnabled_String = "+" 		
			-- AllEnabled = AK_GAMEPAD_BUTTON_03
			-- AllEnabled_String = "C"
			AllDisabled = AK_GAMEPAD_BUTTON_05
			AllDisabled_String = "-"
			
		end
		

		LogTestMsg (" ")		
		if ( AK_PLATFORM_PC) then
			if (AkLuaGameEngine.IsGamepadConnected() ) then
				LogTestMsg ( "Press '" .. ControllerEnabled_String .. "' to Enable Motion on the 'Controller' only.")
				LogTestMsg ( "Press '" .. AllEnabled_String .. "' to Enable Motion on both the 'D-BOX' and 'Controller'.")
			end
			
		end

		if (not( AK_PLATFORM_PC)) then
			LogTestMsg ( "Press '" .. ControllerEnabled_String .. "' to Enable Motion on the 'Controller' only.")
		end

		LogTestMsg ( "Press '" .. AllDisabled_String .. "' to disable Motion on every Device.")

		coroutine.yield()

		while (not (continueScriptFlag ) ) do
		
			if( AkIsButtonPressedThisFrameInternal( ControllerEnabled) ) then
				--The game must register the MotionGenerator in order to use it.
				AK.SoundEngine.RegisterPlugin(AkPluginTypeMotionSource, AKCOMPANYID_AUDIOKINETIC, AKSOURCEID_MOTIONGENERATOR, AkCreateMotionGenerator, AkCreateMotionGeneratorParams)  
				
				AkInitializeAllRumbleDevice()			
				AutoLogTestMsg( ">>> Motion was enabled on 'Controller' only. <<<",1,1)

				continueScriptFlag = true
			
			elseif( AkIsButtonPressedThisFrameInternal(AllEnabled) ) then
				--The game must register the MotionGenerator in order to use it.
				AK.SoundEngine.RegisterPlugin(AkPluginTypeMotionSource, AKCOMPANYID_AUDIOKINETIC, AKSOURCEID_MOTIONGENERATOR, AkCreateMotionGenerator, AkCreateMotionGeneratorParams)  
				
				--The game must register the Device to the Motion Engine in order to use it. 
				AK.MotionEngine.RegisterMotionDevice(AKCOMPANYID_AUDIOKINETIC, AKMOTIONDEVICEID_RUMBLE, AkCreateRumblePlugin)  

				--The game must register a Player to receive motion through a given Device. 
				AK.MotionEngine.AddPlayerMotionDevice(0, AKCOMPANYID_AUDIOKINETIC, AKMOTIONDEVICEID_RUMBLE) 

				AutoLogTestMsg( ">>> Motion was enabled on 'Controller'. <<<",1,1 )

				continueScriptFlag = true
				
			elseif( AkIsButtonPressedThisFrameInternal(AllDisabled) ) then
				AutoLogTestMsg( ">>> Motion was disabled on every Device. <<<",1,1 )

				allDisabledFlag = true
				continueScriptFlag = true
			end
			coroutine.yield()
		end
		
		if 	(allDisabledFlag == false) then
			--In a game with Motion support, each player must have its own Listener.  The game must assign a Listener explicitly.
			AK.MotionEngine.SetPlayerListener(0, 0)  --SetPlayerListener([Player port], [Listener ID])
			
			--The game needs to activate the proper Listeners bits for each game object.
			AK.SoundEngine.SetActiveListeners(2, 0x01)	--SetActiveListeners([Game Object ID], [Listener Mask])
			
			--The game needs to specify which data (Audio and/or Motion) to send to each Listener.
			AK.SoundEngine.SetListenerPipeline(0, true, true)  --SetListenerPipeline([Listener ID], [bool audio], [bool motion])
		end
		
	else
		LogTestMsg ( ">>>   Skipping 'Register Motion Plugins'...   <<<")
		LogTestMsg ( ">>>   Motion is NOT supported on the MAC.   <<<",666)
	end
end
g_testName[AkRegisterMotionPlugIns]="AkRegisterMotionPlugIns" -- give a printable name to this function if used as a coroutine.

function IsUnattended()
	return AkLuaGameEngine.IsOffline() or g_unattended;
end

-- This function will initialize the Test Framework 
-- Place any initialization common to all tests here.
function AkInitAutomatedTests()
	print( string.format( "Input frames per second: %s", kFramerate ) )
	if( AK_LUA_RELEASE ) then
		print( "Not using communication" )
	else
		print( "Using communication" )
	end

	if( g_basepath ~= nil ) then		
		print("Base Path for banks is set to " .. g_basepath)
	end
	
	if( g_unattended ) then
		print("Script running unattended")
	end
	
	if( AkLuaGameEngine.IsOffline() ) then
		print("Script running with offline rendering (faster than real-time)")
	end
	
	if( kCaptureOneFilePerCoroutine ) then
		print("Script output is captured in a different file for each test")
	end
	
	--Start the routine that will run all the tests.
	if ( AkLuaGameEngine.IsOffline() ) then
		g_coroutineHandle = coroutine.create( CoHandleTestsAutomated )
	else
		g_coroutineHandle = coroutine.create( CoHandleTests )
	end	

end

function KillCoroutine(message)
	--Find the current coroutine in the test table
	
	--Try to find the name of the calling coroutine
	local found = 2
	while(debug.getinfo(found) ~= nil) do
		found = found + 1
	end
	local info = debug.getinfo(found-1)
	for i=1,#g_TestTable do
		if g_TestTable[i].Func == info.func then
			found = i			
		end
	end
	
	if found ~= 0 then
		print(g_TestTable[found].Name.. message)
	else
		print("Unknown routine "..message)
	end
	coroutine.resume(false)
	--After the resume(false), the coroutine is destroyed.  It won't execute the next lines.			
end

function AkIsButtonPressed( in_nButton )
	if AkLuaGameEngine.IsOffline() and coroutine.running() ~= nil then
		-- Kill the co-routine.  In unattended mode, we don't want to wait for the keyboard.  
		-- If a co-routine has a keyboard input loop, ignore this co-routine.	
		KillCoroutine(" was SKIPPED because it contains keyboard input instructions (AkIsButtonPressed).")				
	end
	return AkLuaGameEngine.IsButtonPressed(in_nButton)
end

function AkIsButtonPressedThisFrameInternal( in_nButton )	
		if AkLuaGameEngine.IsOffline() and coroutine.running() ~= nil then		
			-- Kill the co-routine.  In unattended mode, we don't want to wait for the keyboard.  
			-- If a co-routine has a keyboard input loop, ignore this co-routine.	
			KillCoroutine(" was SKIPPED because it contains keyboard input instructions (AkIsButtonPressedThisFrameInternal).")				
		end
	return AkIsButtonPressedThisFrame(in_nButton)	
end

function AKASSERT(in_condition, in_msg)
	if not in_condition then
		local msg = "ASSERT! " .. in_msg
		print(msg)
	end
end

function AkGetTickCount()
	if ( AkLuaGameEngine.IsOffline() ) then	
		return g_TickCount * AK_AUDIOBUFFERMS
	end
	return os.gettickcount()
end

function AkPathRemoveLastToken(in_path)
	local reverse = string.reverse(in_path)
	local slash = string.find(reverse, GetDirSlashChar())
	if slash == nil then
		return nil
	end
	
	return string.reverse(string.sub(reverse, slash+1))
end

function FindGeneratedSoundBankPath(in_path)	
	local allFiles = ScanDir(in_path)	
	for i=1,#allFiles do				
		if string.find(allFiles[i], "GeneratedSoundBanks") ~= nil then	
			return in_path .. GetDirSlashChar() .. "GeneratedSoundBanks" .. GetDirSlashChar()			
		end
	end		
	return nil
end

function FindBasePathForProject(in_basePath)
	local searchPath = {}
	if( g_basepath ~= nil ) then
		--Support the -basepath commandline option on the GameSim
		table.insert(searchPath, g_basepath)
	end
	
	--Check if a full path was passed as a parameter.  If it is a full path, add it in the search paths directly.
	if (string.find(in_basePath, ":") ~= nil) then
		table.insert(searchPath, in_basePath)
	end
	
	--Build a path from the lua script we run.  By default we will check for banks in the same directory.
	local path = LUA_SCRIPT
	if path ~= nil then
		path = AkPathRemoveLastToken(path)			
	end		
	if path ~= nil then
		table.insert(searchPath, path .. GetDirSlashChar())		
	
		--Try to find a "GeneratedSoundBanks" folder in the parent directories.
		local sbpath = nil
		repeat						
			sbpath = FindGeneratedSoundBankPath(path)						
			path = AkPathRemoveLastToken(path)		
			if path == nil then
				break
			end
		until(path == nil or sbpath ~= nil)	
		
		if sbpath ~= nil then
			table.insert(searchPath, sbpath .. AK_PLATFORM_NAME .. GetDirSlashChar())
		end
	end
	
	--Add the ordinary roots for each platform too
	if( AK_PLATFORM_XBOX360 ) then		
		table.insert(searchPath, "game:\\")		
	elseif( AK_PLATFORM_PS3 ) then		
		table.insert(searchPath, "/dev_hdd0/game/AKGS00000/USRDIR/akgamesim/")
		table.insert(searchPath, "/app_home/")		
	elseif( AK_PLATFORM_WII ) then		
		table.insert(searchPath, "/")
	elseif( AK_PLATFORM_VITA ) then		
		table.insert(searchPath, "sd0:")
		table.insert(searchPath, "app0:")	
		table.insert(searchPath, "host0:")
	elseif( AK_PLATFORM_PS4 ) then		
		table.insert(searchPath, "app0")	
	elseif( AK_PLATFORM_WIIU ) then
		table.insert(searchPath, "/vol/content/")
	elseif (AK_PLATFORM_ANDROID ) then
		table.insert(searchPath, "/sdcard/sdcard-disk0/GameSimulator/")
	end
	
	--Always include the current directory
	table.insert(searchPath, "./")
	
	local errorMsg = "Could not find any banks in the following directories:\n"
	for i=1,#searchPath do
		--Check if there is a Init.bnk or a file package in this folder
		local initFile = io.open(searchPath[i].."Init.bnk")		
		if (initFile == nil) then
			initFile = io.open(searchPath[i].."1355168291.bnk")		--Numeric version of Init.bnk
		end
		
		if (initFile ~= nil) then	
			io.close(initFile)			
			return searchPath[i]
		else
			local pckFiles = ScanDirWithExtension(searchPath[i], "pck")
			if next(pckFiles) ~= nil then
				-- Found at least one package file. Let's hope our banks are in it.
				print("Found file package(s) in directory "..searchPath[i])
				return searchPath[i]
			end
		end
		errorMsg = errorMsg .. searchPath[i] .. "\n"
	end
	
	print(errorMsg)
	return nil;
end

function ScanDir(dirname)
	local list = AkLuaGameEngine.ListDirectory(dirname)
	if list == nil then
		return {}
	end

	local tabby = {}
	local from  = 1
	local delim_from, delim_to = string.find( list, "\n", from  )
	while delim_from do		
		table.insert( tabby, string.sub( list, from , delim_from-1 ) )
		from  = delim_to + 1
		delim_from, delim_to = string.find(list, "\n", from  )
	end
	return tabby
end

-- Returns all file names of in_path with extension in_extension
function ScanDirWithExtension(in_path, in_extension)
	local strExtension = "."..in_extension
	local allFiles = ScanDir(in_path)
	local listFiles = {}
	
	for i=1,#allFiles do
		local filename = allFiles[i]
		
		-- find the .pck extension
		if string.find(filename, strExtension) ~= nil then						
			table.insert(listFiles, filename)
		end		
	end
	
	return listFiles
end

function FindAllBanks(in_basePath, in_language)

	if (in_language == nil or in_language=="") then
		in_language = "English(US)"
	end	
	
	--Load Init.bnk anyway
	local banklist = {"Init.bnk"}	
	FindBanksFromDirectory(in_basePath, banklist);
	FindBanksFromDirectory(in_basePath..in_language, banklist);
	return banklist
end

function FindBanksFromDirectory(path, in_banklist)
	print("Loading banks from " .. path)
	local allFiles = ScanDir(path)
			
	for i=1,#allFiles do
		local filename = allFiles[i]
		
		-- find the .bnk extension
		if string.find(filename, ".bnk") ~= nil and filename ~= "Init.bnk" then						
			table.insert(in_banklist, filename)
			print(filename)
		end		
	end		
end

function AkLoadBankCoRoutine(in_banks)
	print("Press space when ready to load banks\n")
	Pause()
	
	--Load the selected banks
	for i=1,#in_banks do
		local filename = in_banks[i]
		print("Loading "..filename)
		AkLoadBank(filename)
	end
end

-- Pass in an array of file package names (with their extension .pck). 
-- Note: The file package is opened from the base path.
-- Note: You may specify the low-level device in which you want the file package to be loaded. Prefix the package name with the name of the device with a semicolon. For example, "RAM:MyPackage.pck"
function AkLoadFilePackagesCoroutine(in_packages)
	print("Press space when ready to load file packages\n")
	Pause()
	
	for i=1,#in_packages do
		local packagename = in_packages[i]
		-- See if device is specified.
		local idxColon = string.find(packagename, ':', 2)
		if idxColon ~= nil then
			local deviceName = string.sub(packagename, 1, string.find(packagename, ':', 2) - 1)
			local package = string.sub(packagename, string.find(packagename, ':', 1)+1)
			assert( g_lowLevelIO[deviceName] ~= nil, "Device " .. deviceName .. " does not exist" );
			AkLoadPackageFromDevice(g_lowLevelIO[deviceName], package)
		else
			AkLoadPackage(packagename)
		end			
	end
end

function InitMemoryTest()	
	local rndseed = os.time() % 32767;
	math.randomseed(rndseed);	
	local skip = math.random(100, 1000)	--The first random is not random... It directly depends on the seed (the time!).  Weird.
	skip = math.random(100, 1000)		--But the second is random.
	local rate = math.random(100, 1000)
	print("Memory stress test is enabled.  Seed is " .. rndseed .. ".  Skipping the first " .. skip .. " allocations.  Fail one in "..rate);
	-- Enable the memory failures.  The grace period is random in order to test failures in LoadBanks as 
	-- well as the rest of the code.
	ParametrizeMemoryStress(true, skip, rate, 1, 100)
	g_MemTest = true
end

--This function will do all the setup commonly used in test scripts:
--a) Find the base path
--b) Initialize the SoundEngine with default values.  You can override the default values by setting a function in g_OverrideSESettings.  See AkInitSE
--c) Register the plugins
--d) Load the file packages if applicable. File packages must be specified with their extension (.pck), and may optionally be prepended with the device name from which you wish to load them. For example, "RAM:MyPackage.pck"
--e) Find the banks to load, if none specified in "in_banks"
--f) Load the banks (actually puts a coroutine that will load the banks)
--g) Start the game loop.
function AkDefaultScriptMain(in_basePath, in_language, in_banks, in_MetricsIP )	
	AkInitAutomatedTests()
	
	local basePath = FindBasePathForProject(in_basePath)
	if (basePath == nil) then
		if AkLuaGameEngine.IsOffline() then
			return
		end
		
		print("entering Infinite loop")
		--Don't allow script to continue
		while true do 
		end
	end
	
	if AK_PLATFORM_PS3 then
		--Small hack... On the PS3, we need to know the drive for the base path if we use the Deferred-lined up device
		g_PS3Drive = string.sub(basePath, 1, string.find(basePath, '/', 2))	
	end
	
	AkInitSE()

	if( not AK_LUA_RELEASE ) then
		AkInitComm()
	end
	
	--Process arguments.  We support -memtest.  
	--Init the memtest AFTER the communication so that we can see the seed in the log.
	if (arg ~= nil) then
		for i,ARG in ipairs(arg) do
			local argStart, argEnd = string.find(ARG, "-memtest")
			if argStart ~= nil then
				InitMemoryTest()			
			end
		end
	end

	AkRegisterPlugIns()		
		
	-- Set the project's base and language-specific paths for soundbanks:
	SetDefaultBasePathAndLanguageQA( basePath, in_language )
	
	if in_banks == nil then
		--Find all banks in the base path
		in_banks = FindAllBanks(basePath, in_language)
	end	
	
	if in_banks ~= nil then
	
		-- Split the banks array into soundbanks and file packages.
		local banks = {}
		local packages = {}
		
		for i=1,#in_banks do
			local filename = in_banks[i]
			if string.find(filename, ".pck") ~= nil then
				table.insert(packages, filename)
			else
				table.insert(banks, filename)
			end
		end

		-- Push coroutine to load file packages first, if needed.	
		if #packages ~= 0 then
			AkInsertTestRoutine(AkLoadFilePackagesCoroutine, "AkLoadFilePackagesCoroutine", packages)
		end
		
		--If there are banks specified, add a coroutine to load them
		if #banks ~= 0 then
			AkInsertTestRoutine(AkLoadBankCoRoutine, "AkLoadBankCoRoutine", banks)
		end
		
	end
	
	if ( in_MetricsIP ~= nil ) then
		LogTestMsg( "Initializing metrics",1 )
		print("Metrics Server IP: " .. in_MetricsIP)
		AkLuaGameEngine.InitMetrics( in_MetricsIP )
	end
	
	AkGameLoop()
	
	if ( in_MetricsIP ~= nil ) then
		LogTestMsg( "Terminating metrics",1 )
		AkLuaGameEngine.TermMetrics()
	end

	AkStop()
end

-- Appends the items from "itemsToAdd" to "listWhereToAppend"
-- Usage:
--   myList = ( a, b, c )
--   otherList = ( d, e, f )
--   AkAppendList( myList, otherList )
--     --> Now myList == ( a, b, c, d, e, f ) (and otherList was not modified)
function AkAppendList( listWhereToAppend, itemsToAdd )
    for k,v in ipairs( itemsToAdd ) do
		table.insert( listWhereToAppend, v )
	end
end 
