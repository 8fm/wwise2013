/*******************************************************************************
The content of this file includes portions of the AUDIOKINETIC Wwise Technology
released in source code form as part of the SDK installer package.

Commercial License Usage

Licensees holding valid commercial licenses to the AUDIOKINETIC Wwise Technology
may use this file in accordance with the end user license agreement provided 
with the software or, alternatively, in accordance with the terms contained in a
written agreement between you and Audiokinetic Inc.

Apache License Usage

Alternatively, this file may be used under the Apache License, Version 2.0 (the 
"Apache License"); you may not use this file except in compliance with the 
Apache License. You may obtain a copy of the Apache License at 
http://www.apache.org/licenses/LICENSE-2.0.

Unless required by applicable law or agreed to in writing, software distributed
under the Apache License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
OR CONDITIONS OF ANY KIND, either express or implied. See the Apache License for
the specific language governing permissions and limitations under the License.

  Version: 2016.1  Build: 5775
  Copyright (c) 2016 Audiokinetic Inc.
*******************************************************************************/
//////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2011 Audiokinetic Inc. / All Rights Reserved
//
//////////////////////////////////////////////////////////////////////

// AkLinuxSoundEngine.h

/// \file 
/// Main Sound Engine interface, specific to Linux.

#pragma once

#include <AK/SoundEngine/Common/AkTypes.h>
#include <AK/Tools/Common/AkPlatformFuncs.h>

///< API used for audio output
///< Use with AkPlatformInitSettings to select the API used for audio output.  
///< Use AkAPI_Default, it will select the more appropriate API depending on the computer's capabilities.  Other values should be used for testing purposes.
///< \sa AK::SoundEngine::Init
typedef enum AkAudioAPILinux
{
	AkAPI_PulseAudio = 1 << 0,						///< Use PulseAudio (this is the preferred API on Linux)
	AkAPI_ALSA = 1 << 1,							///< Use ALSA
	AkAPI_Default = AkAPI_PulseAudio | AkAPI_ALSA,	///< Default value, will select the more appropriate API
} AkAudioAPI;

///< API used for audio output (PC only).
enum AkSinkType
{
	AkSink_Main	= 0,		///< Main device.  When initializing, the proper sink is instantiated based on system's capabilities (PulseAudio first, then ALSA).
	AkSink_Main_PulseAudio,	///< Main device PulseAudio sink (this is the preferred API on Linux).
	AkSink_Main_ALSA,		///< Main device ALSA sink (for backward compatibility).
	AkSink_Dummy,			///< No output.  Used internally.
	AkSink_MergeToMain,		///< Secondary output.  This sink will output to the main sink.
	AkSink_NumSinkTypes
};

/// Platform specific initialization settings
/// \sa AK::SoundEngine::Init
/// \sa AK::SoundEngine::GetDefaultPlatformInitSettings
/// - \ref soundengine_initialization_advanced_soundengine_using_memory_threshold
struct AkPlatformInitSettings
{
	// Threading model.
    AkThreadProperties  threadLEngine;			///< Lower engine threading properties
	AkThreadProperties  threadBankManager;		///< Bank manager threading properties (its default priority is AK_THREAD_PRIORITY_NORMAL)
	AkThreadProperties  threadMonitor;			///< Monitor threading properties (its default priority is AK_THREAD_PRIORITY_ABOVENORMAL). This parameter is not used in Release build.
	
    // Memory.
	AkReal32            fLEngineDefaultPoolRatioThreshold;	///< 0.0f to 1.0f value: The percentage of occupied memory where the sound engine should enter in Low memory mode. \ref soundengine_initialization_advanced_soundengine_using_memory_threshold
	AkUInt32            uLEngineDefaultPoolSize;///< Lower Engine default memory pool size
	
	//Voices.
	AkUInt32			uSampleRate;			///< Sampling Rate. Default 48000 Hz
	AkUInt16            uNumRefillsInVoice;		///< Number of refill buffers in voice buffer. 2 == double-buffered, defaults to 4.
	AkAudioAPI			eAudioAPI;				///< Main audio API to use. Leave to AkAPI_Default for the default sink (default value).
													///< If a valid audioDeviceShareset plug-in is provided, the AkAudioAPI will be Ignored.
													///< \ref AkAudioAPI
};

///< Used with \ref AK::SoundEngine::AddSecondaryOutput to specify the type of secondary output.
enum AkAudioOutputType
{
	AkOutput_None = 0,		///< Used for uninitialized type, do not use.
	AkOutput_Dummy,			///< Dummy output, simply eats the audio stream and outputs nothing.
	AkOutput_Main,			///< Main output.  This cannot be used with AddSecondaryOutput, but can be used to query information about the main output (GetSpeakerConfiguration for example).	
	AkOutput_MergeToMain,	///< This output will mix back its content to the main output, after the master mix.
	AkOutput_NumBuiltInOutputs,		///< Do not use.
	AkOutput_Plugin			///< Specify if using Audio Device Plugin Sink.
};
