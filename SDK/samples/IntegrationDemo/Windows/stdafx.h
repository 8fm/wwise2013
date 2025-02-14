// stdafx.h
// Copyright (C) 2010 Audiokinetic Inc
/// \file 
/// Precompiled Header File for the Integration Demo application.

#pragma once

////////////////////////////////////////////
// Helper Includes
////////////////////////////////////////////

#include <AK/SoundEngine/Common/AkTypes.h>
#include <AK/Tools/Common/AkPlatformFuncs.h>

#define WIN32_LEAN_AND_MEAN	
#define DIRECTINPUT_VERSION 0x0800
#define INTEGRATIONDEMO_SRC_BUILD
#if defined(_MSC_VER) && (_MSC_VER < 1900)
	#define snprintf _snprintf
#endif
#include <windows.h>
#include <dinput.h>
#include <xinput.h>
#include <d3d9.h>
#include <D3dx9core.h>

#include <wchar.h>