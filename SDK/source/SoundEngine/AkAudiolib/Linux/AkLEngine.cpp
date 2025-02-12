/***********************************************************************
  The content of this file includes source code for the sound engine
  portion of the AUDIOKINETIC Wwise Technology and constitutes "Level
  Two Source Code" as defined in the Source Code Addendum attached
  with this file.  Any use of the Level Two Source Code shall be
  subject to the terms and conditions outlined in the Source Code
  Addendum and the End User License Agreement for Wwise(R).

  Version:  Build: 
  Copyright (c) 2006-2020 Audiokinetic Inc.
 ***********************************************************************/

//////////////////////////////////////////////////////////////////////
//
// AkLEngine.cpp
//
// Implementation of the IAkLEngine interface. Android version.
//
//////////////////////////////////////////////////////////////////////

#include "stdafx.h"
#include "AkLEngine.h"

#include <AK/SoundEngine/Common/AkSimd.h>
#include <AK/Tools/Common/AkPlatformFuncs.h>

#include "Ak3DListener.h"
#include "AkAudioLibTimer.h"
#include "AkSettings.h"
#include "AkSink.h"
#include "AkProfile.h"
#include "AkMonitor.h"
#include "Ak3DParams.h"
#include "AkDefault3DParams.h"			// g_DefaultListenerPosition.
#include "AkRegistryMgr.h"
#include "AkResampler.h"
#include "AkRTPCMgr.h"
#include "AkFXMemAlloc.h"
#include "AkSpeakerPan.h"
#include "AkEnvironmentsMgr.h"
#include "AkAudioMgr.h"
#include "AkEffectsMgr.h"
#include "AkPlayingMgr.h"
#include "AkPositionRepository.h"
#include "AkSound.h"
#include "AkVPLFilterNodeOutOfPlace.h"
#include "AkFxBase.h"
#include "AkOutputMgr.h"
#include <dlfcn.h>

#include "PulseAudioAPI.h"

//-----------------------------------------------------------------------------
//Static variables.
//-----------------------------------------------------------------------------
extern AkInitSettings		g_settings;
extern AkPlatformInitSettings g_PDSettings;

AkEvent	CAkLEngine::m_EventStop;
AK::IAkPlatformContext* CAkLEngine::m_pPlatformContext = NULL;

#define PULSE_AUDIO_MAX_NB_DEVICES 25

//
// CAkLinuxContext provides sink information for PulseAudio (stream name and number of channels).
// The assumption is that deviceIDs other than the default (0) are provided by AK::SoundEngine::GetDeviceList.
// This will fill the list of sink info in CAkLinuxContext (in CAkLEngine::GetPlatformDeviceList)
// which can then be used by the sink to retrieve the stream name and number of channels at initialization.
//
class CAkLinuxContext: public AK::IAkLinuxContext
{
public:
	// AK::IAkLinuxContext --
	CAkLinuxContext()
	{
		PopulateDeviceList();
	}

	bool UsePulseAudioServerInfo() override
	{
		return true;
	}	

	bool IsStreamReady(AkPluginID pluginID) override
	{
		return true;
	}

	bool IsPluginSupported(AkPluginID pluginID) override
	{
		return pluginID == AKPLUGINID_DEFAULT_SINK;
	}

	const char* GetStreamName(AkDeviceID deviceID) override
	{
		// Let the sink use the default PulseAudio server info
		if (deviceID == 0)
			return "Wwise Main"; // must be non-empty

		static char streamName[AK_MAX_PATH] = "";
		{
			// Make sure GetPlatformDeviceList does not update sinkInfoList
			// while we're reading from it (it's updated in PopulateDeviceList)
			AkAutoLock<CAkLock> lock(sinkListLock);

			const PulseAudioAPI::SinkInfo* sinkInfo = GetSinkInfo(deviceID);

			if (sinkInfo != nullptr)
				AKPLATFORM::SafeStrCpy(streamName, sinkInfo->name, AK_MAX_PATH);
			else
				strcpy(streamName, "");
		}

		return streamName;
	}

	const char* GetStreamName(AkPluginID /* pluginID */, AkDeviceID deviceID) override
	{
		return GetStreamName(deviceID);
	}

	AkUInt32 GetChannelCount(AkDeviceID deviceID) override
	{
		// Let the sink use the default PulseAudio server info
		if (deviceID == 0)
			return 0;

		AkUInt32 nbChannels = 0;
		{
			// Make sure GetPlatformDeviceList does not update sinkInfoList
			// while we're reading from it (it's updated in PopulateDeviceList)
			AkAutoLock<CAkLock> lock(sinkListLock);

			const PulseAudioAPI::SinkInfo* sinkInfo = GetSinkInfo(deviceID);

			if (sinkInfo != nullptr)
				nbChannels = sinkInfo->nbChannels;
		}

		return nbChannels;
	}
	
	AkUInt32 GetChannelCount(AkPluginID /* pluginID */, AkDeviceID deviceID) override
	{
		return GetChannelCount(deviceID);
	}

	void SetSinkInitialized(bool isInitialized) override { }

	void SetSinkInitialized(AkPluginID /* pluginID */, bool /* isInitiliazed */) override {}

	// --

	const PulseAudioAPI::SinkInfo* GetSinkInfo(AkDeviceID deviceID)
	{
		for (int i = 0; i < nbDevices; ++i)
		{
			if ((deviceID == 0 && sinkInfoList[i].isDefaultDevice) ||
				 deviceID == sinkInfoList[i].deviceID)
			{
				return &sinkInfoList[i];
			}
		}

		return nullptr;
	}

	// Called by CAkLEngine::GetPlatformDeviceList
	// when a user calls AK::SoundEngine::GetDeviceList
	// and during sound engine initialization.
	AKRESULT PopulateDeviceList()
	{
		// Make sure we don't update while GetStreamName
		// or GetChannelCount is reading from sinkInfoList.
		AkAutoLock<CAkLock> lock(sinkListLock);
	
		nbDevices = PULSE_AUDIO_MAX_NB_DEVICES;

		if (PulseAudioAPI::GetSinkInfoList(nbDevices, sinkInfoList, nbDevices) != AK_Success)
		{
			nbDevices = 0;
			return AK_Fail;
		}

		return AK_Success;
	}

	CAkLock sinkListLock;
	AkUInt32 nbDevices{ 0 };
	PulseAudioAPI::SinkInfo sinkInfoList[PULSE_AUDIO_MAX_NB_DEVICES];
};

void CAkLEngine::GetDefaultPlatformInitSettings( 
	AkPlatformInitSettings &      out_pPlatformSettings      // Platform specific settings. Can be changed depending on hardware.
	)
{
	memset( &out_pPlatformSettings, 0, sizeof( AkPlatformInitSettings ) );
	out_pPlatformSettings.threadLEngine.nPriority = AK_THREAD_PRIORITY_ABOVE_NORMAL;
	out_pPlatformSettings.threadLEngine.uStackSize = AK_DEFAULT_STACK_SIZE;
	out_pPlatformSettings.threadBankManager.nPriority = AK_THREAD_BANK_MANAGER_PRIORITY;
	out_pPlatformSettings.threadBankManager.uStackSize = AK_BANK_MGR_THREAD_STACK_BYTES;
	out_pPlatformSettings.uLEngineDefaultPoolSize = LENGINE_DEFAULT_POOL_SIZE;
	out_pPlatformSettings.fLEngineDefaultPoolRatioThreshold = 1.0f; // 1.0f == means 100% == disabled by default
	out_pPlatformSettings.uNumRefillsInVoice = AK_DEFAULT_NUM_REFILLS_IN_VOICE_BUFFER;
	out_pPlatformSettings.uSampleRate = DEFAULT_NATIVE_FREQUENCY;
	out_pPlatformSettings.threadMonitor.nPriority = AK_THREAD_PRIORITY_ABOVE_NORMAL;
	out_pPlatformSettings.threadMonitor.uStackSize = AK_DEFAULT_STACK_SIZE;
	out_pPlatformSettings.threadMonitor.uSchedPolicy = AK_THREAD_DEFAULT_SCHED_POLICY;
}

void CAkLEngine::GetDefaultOutputSettings( AkSinkType in_eSinkType, AkOutputSettings & out_settings )
{
	GetDefaultOutputSettingsCommon(out_settings);
}

bool CAkLEngine::PlatformSupportsHwVoices()
{
	return false;
}

void CAkLEngine::PlatformWaitForHwVoices()
{
}

//-----------------------------------------------------------------------------
// Name: Init
// Desc: Initialise the object.
//
// Parameters:
//
// Return: 
//	Ak_Success:          Object was initialised correctly.
//  AK_InvalidParameter: Invalid parameters.
//  AK_Fail:             Failed to initialise the object correctly.
//-----------------------------------------------------------------------------
AKRESULT CAkLEngine::Init()
{
/*
	if (g_PDSettings.sampleType != AK_INT && g_PDSettings.sampleType != AK_FLOAT)
	{
		AkOSChar msg[256];
		AK_OSPRINTF(msg, 256,
			"Invalid AkPlatformInitSettings::sampleType: '%d'. "
			"Supported values are AK_INT (0) and AK_FLOAT (1). "
			"Reverting to default (%d).\n",
			g_PDSettings.sampleType, AK_DEFAULT_SAMPLE_TYPE
		);
		AKPLATFORM::OutputDebugMsg(msg);
		g_PDSettings.sampleType = AK_DEFAULT_SAMPLE_TYPE;
	}

	AkAudioLibSettings::SetAudioBufferSettings(g_PDSettings.uSampleRate, g_settings.uNumSamplesPerFrame);
*/
	return SoftwareInit();
} // Init

AKRESULT CAkLEngine::InitPlatformContext()
{
	m_pPlatformContext = AkNew(AkMemID_SoundEngine, CAkLinuxContext());
	if (!m_pPlatformContext)
		return AK_InsufficientMemory;
	return AK_Success;
}

void CAkLEngine::Term()
{
	SoftwareTerm();
} // Term

AkUInt32 CAkLEngine::GetNumBufferNeededAndSubmit()
{
	AkUInt32 uBuffersNeeded = 0;

	AKRESULT eResult = g_pAkSink->IsDataNeeded( uBuffersNeeded );
	if ( eResult != AK_Success )
	{
		AKASSERT( false );
	}

	//nothing to submit, simply return num buffers
	return uBuffersNeeded;
}

void CAkLEngine::TermPlatformContext()
{
	AkDelete(AkMemID_SoundEngine, m_pPlatformContext);
	m_pPlatformContext = NULL;
}

//-----------------------------------------------------------------------------
// Name: Perform
// Desc: Perform all VPLs.
//-----------------------------------------------------------------------------
void CAkLEngine::Perform()
{
	//WWISE_SCOPED_PROFILE_MARKER( "CAkLEngine::Perform" );

#if defined(AK_CPU_X86) || defined(AK_CPU_X86_64)
	// Avoid denormal problems in audio processing
	AkUInt32 uFlushZeroMode = _MM_GET_FLUSH_ZERO_MODE();
	_MM_SET_FLUSH_ZERO_MODE(_MM_FLUSH_ZERO_ON);
#endif
	
	SoftwarePerform();
	
#if defined(AK_CPU_X86) || defined(AK_CPU_X86_64)
	_MM_SET_FLUSH_ZERO_MODE(uFlushZeroMode);
#endif
} // Perform

void CAkLEngine::StartVoice()
{
	g_pAkSink->Play();
}

//-----------------------------------------------------------------------------
// Implementation of GetDeviceList for PulseAudio
//-----------------------------------------------------------------------------

AKRESULT CAkLEngine::GetPlatformDeviceList(
	AkPluginID in_pluginID,
	AkUInt32& io_maxNumDevices,					///< In: The maximum number of devices to read. Must match the memory allocated for AkDeviceDescription. Out: Returns the number of devices. Pass out_deviceDescriptions as NULL to have an idea of how many devices to expect.
	AkDeviceDescription* out_deviceDescriptions	///< The output array of device descriptions, one per device. Must be preallocated by the user with a size of at least io_maxNumDevices*sizeof(AkDeviceDescription).
)
{
	// Linux only supports System sink
	if (in_pluginID != AKPLUGINID_DEFAULT_SINK)
	{
		return AK_NotCompatible;
	}

	// Not implemented for ALSA
	if (g_PDSettings.eAudioAPI == AkAPI_ALSA)
		return AK_NotImplemented;

	// else, it's either AkAPI_PulseAudio or AkAPI_Default -> PulseAudio

	auto platformContext = static_cast<CAkLinuxContext*>(m_pPlatformContext);

	platformContext->PopulateDeviceList();

	// We assume only one thread at a time will call this function
	// If that's the case then we don't need to lock here for reading sinkInfoList
	// since this would be the only thread writing to it.

	PulseAudioAPI::SinkInfo* sinkInfoList = platformContext->sinkInfoList;

	if (out_deviceDescriptions != nullptr)
	{
		// Copy device info to output
		io_maxNumDevices = AkMin(io_maxNumDevices, platformContext->nbDevices);
		for (int i = 0; i < io_maxNumDevices; ++i)
		{
			out_deviceDescriptions[i].idDevice = sinkInfoList[i].deviceID;
			out_deviceDescriptions[i].isDefaultDevice = sinkInfoList[i].isDefaultDevice;
			AKPLATFORM::SafeStrCpy(out_deviceDescriptions[i].deviceName, sinkInfoList[i].description, AK_MAX_PATH);
			out_deviceDescriptions[i].deviceStateMask =
				sinkInfoList[i].state == PA_SINK_INVALID_STATE ?
					AkDeviceState_Unknown : AkDeviceState_Active;
		}
	}
	else
	{
		// Just set the real number of devices if user asked for it
		io_maxNumDevices = platformContext->nbDevices;
	}

	return AK_Success;
}
