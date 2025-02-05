if( AK_PLATFORM_PC or AK_PLATFORM_XBOX360 ) then
	g_dirChar = "\\"
else
	g_dirChar = "/"
end

function FindBanksToLoad(path, io_banklist, io_languages)		
	local allFiles = ScanDir(path)
	for i=1,#allFiles do
		local filename = allFiles[i]			
		if string.find(filename, "%.bnk") ~= nil then	
			if filename ~= "Init.bnk" then
				table.insert(io_banklist, filename)
			end
		elseif io_languages ~= nil and string.find(filename, "%.") == nil and filename ~= "." and filename ~= ".." then
			--Maybe a language directory.  Try it.			
			table.insert(io_languages, filename)			
		end
	end		
end

function AnalyzeAllBanks(banklist, language)
	local info = AK.MemoryMgr.PoolStats:new_local()	
	for i=1,#banklist do
		local bank = banklist[i]
		
		AK.MemoryMgr.GetPoolStats(2, info)
		before = info.uUsed
		local bankID = 0			
		result, bankID = AK.SoundEngine.LoadBank( bank, -1, bankID )
		if result ~= AK_Success then
			print( string.format( "Error(%d) loading bank [%s]", result, bank ) )
		else
			AK.MemoryMgr.GetPoolStats(2, info)
			local result = (info.uUsed-before) .. "\t" ..language..bank.."\n"
			print(result)
			g_outputFile:write(result)
			if bank ~= "Init.bnk" then
				AK.SoundEngine.UnloadBank(bankID) 
			end
		end	
	end
end

if g_basepath == nil then
	if AK_PLATFORM_XBOX360 then
		g_basepath = "game:\\"
	elseif AK_PLATFORM_PS3 then
		g_basepath = "/app_home/"
	elseif AK_PLATFORM_IOS then
		-- Basepath is set dynamically by the iphone app
		-- place your files in the gamesimulator application 
		-- bundle in the folder /Data/banks/
		--g_basepath = g_basepath	
	elseif( AK_PLATFORM_VITA ) then
        g_basepath = "app0:\\"	
	else
		g_basepath =  LUA_EXECUTABLE_DIR		
	end	
end

--The base path must end with a slash.
if string.sub(string.reverse(g_basepath), 1,1) ~= g_dirChar then
	print("ADD")
	print(string.sub(string.reverse(g_basepath), 1,1) )
	g_basepath = g_basepath .. g_dirChar
end

AkInitSE()
AkRegisterPlugIns()
if not(AK_PLATFORM_MAC or AK_PLATFORM_IOS or AK_PLATFORM_VITA or AK_PLATFORM_3DS) then
	--The game must register the MotionGenerator in order to use it.
	AK.SoundEngine.RegisterPlugin(AkPluginTypeMotionSource, AKCOMPANYID_AUDIOKINETIC, AKSOURCEID_MOTIONGENERATOR, AkCreateMotionGenerator, AkCreateMotionGeneratorParams)  
end

local banklist = {}
local languages = {}
print("Searching banks from " .. g_basepath.."\n")
FindBanksToLoad(g_basepath, banklist, languages)

g_lowLevelIO["Default"]:SetBasePath( g_basepath )
g_outputFile = io.open(g_basepath.."BanksMemSize.txt", "w")

--Load Init.bnk first
table.insert(banklist, 1, "Init.bnk")

AnalyzeAllBanks(banklist, "")

--Load language banks too
for i=1,#languages do
	banklist = {}	
	local language = languages[i]
	AK.StreamMgr.SetCurrentLanguage( language )
	FindBanksToLoad(g_basepath..language, banklist)
	AnalyzeAllBanks(banklist, language..g_dirChar)
end

io.close(g_outputFile)

AkTermSE()

print("\nBanks default pool usage are reported in file BanksMemSize.txt, in the specified base path\n")