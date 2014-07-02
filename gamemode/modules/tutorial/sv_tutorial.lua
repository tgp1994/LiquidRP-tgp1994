local LDRP = {}

--[[---------------------------------------------------------------------------
	General client->server->client tutorial system runtime control
-----------------------------------------------------------------------------]]
function LDRP.RepeatTut(ply, cmd, args)
	local tutLady = LDRP_SH.ShopPoses["Tutorial Lady"]
	if !tutLady or ply:GetPos():Distance( tutLady ) > 300 then
		print("Not running")
		return
	end
	ply:DoTutorial("start")
end
concommand.Add("_repetut",LDRP.RepeatTut)

function LDRP.FinishTut(ply,cmd,args)
	if ply.InTut then
		ply:DoTutorial("done")
	end
end
concommand.Add("_fintut",LDRP.FinishTut)

--[[---------------------------------------------------------------------------
	Define a function on the Player for starting and stopping the tutorial.
-----------------------------------------------------------------------------]]
local meta = FindMetaTable( "Player" )

util.AddNetworkString( "StartTutorial" )
function meta:DoTutorial(Type)
	if !LDRP_SH.ShowTutorial then return end
	local ply = self
	if Type == "start" then
		ply.InTut = true
		ply:Spectate(OBS_MODE_ROAMING)
		ply:StripWeapons()
		ply:SetColor(255,255,255,0)
		ply:Freeze(true)
		
		net.Start( "StartTutorial" )
		net.Send( self )
	elseif Type == "done" then
		ply:Spawn()
		ply:SetColor(255,255,255,255)
		ply:Freeze(false)
	end
end

local masterTutorialParts = {}
--[[---------------------------------------------------------------------------
	Function: SendTutPartsToPlayer
	Description: Sends the master tutorial parts table to the specified player.
this could be called whenever an administrator adds/removes a tutorial point,
so all players can stay up to date.
-----------------------------------------------------------------------------]]
util.AddNetworkString( "LoadTutParts" )
local function SendTutPartsToPlayer( ply )
	net.Start( "LoadTutParts" )
	net.WriteTable( masterTutorialParts )
	net.Send( ply )
end

hook.Add( "PlayerInitialSpawn", "SendTutToNewPlayer", function( ply )
	SendTutPartsToPlayer( ply )
end )

--[[---------------------------------------------------------------------------
	Function: LoadTutorialsFromDB
	Description: Called as a result of a SQL query performed on the table
holding tutorial point information. result is supposed to be a table of
tables of point information, similar to the structure of
masterTutorialParts.
-----------------------------------------------------------------------------]]
local function LoadTutorialsFromDB( result )
	if result == nil then return end
	if type( result ) ~= "table" then
		GAMEMODE:WriteOut( "Received unexpected result when querying tutorials: "..
			type( restult )..": "..tostring( result ), Severity.Info )
		return
	end
	GAMEMODE:WriteOut( "Loading "..#result.." tutorial points...", Severity.Info)
	local newMasterTable = {}
	for _, v in ipairs( result ) do
		local pos = Vector( v.pos_x, v.pos_y, v.pos_z )
		local ang = Angle( 0, 0, 0 )
		ang.pitch = v.ang_pitch
		ang.yaw = v.ang_yaw
		ang.roll = v.ang_roll
		table.insert( newMasterTable, #newMasterTable + 1, { 
			["name"] = v.title,
			["descrpt"] = v.description,
			["pos"] = pos,
			["angs"] = ang} )
	end
	masterTutorialParts = newMasterTable
	GAMEMODE:WriteOut( "Broadcasting updated master tutorial point table to all players...",
		Severity.Debug )
	SendTutPartsToPlayer( player.GetHumans() )
end

local function InitLoadTutsFromDB()
	local map = game.GetMap()
	MySQLite.query("SELECT * FROM "..Prefix.."_tutorials WHERE map = \"" .. map .. "\";", LoadTutorialsFromDB)
end

hook.Add( "DarkRPDBInitialized", "Load tutorials from DB", function()
	MySQLite.query([[
			CREATE TABLE IF NOT EXISTS ]]..Prefix..[[_tutorials(
				map VARCHAR(64) NOT NULL,
				title VARCHAR(32) NOT NULL,
				description VARCHAR(256) NOT NULL,
				pos_x INTEGER NOT NULL,
				pos_y INTEGER NOT NULL,
				pos_z INTEGER NOT NULL,
				ang_pitch INTEGER NOT NULL,
				ang_yaw INTEGER NOT NULL,
				ang_roll INTEGER NOT NULL
			)
		]])

	InitLoadTutsFromDB()
end )

util.AddNetworkString( "SaveTutorialPoint" )
net.Receive( "SaveTutorialPoint", function( length, ply )
	if not ( ply:IsAdmin() or ply:IsSuperAdmin() ) then return end
	GAMEMODE:WriteOut( "Receiving request to save new tutorial point from "..tostring( ply ), Severity.Debug )
	local tbl = { map = game.GetMap(),
		title = net.ReadString(),
		description = net.ReadString(),
		pos_x = net.ReadInt( 32 ),
		pos_y = net.ReadInt( 32 ),
		pos_z = net.ReadInt( 32 ),
		ang_pitch = net.ReadInt( 9 ),
		ang_yaw = net.ReadInt( 9 ),
		ang_roll = net.ReadInt( 9 ) }
		
	--SQLify strings
	for k, v in pairs(tbl) do
		if type(v) == "string" then
			tbl[k] = SQLStr( v )
		end
	end
	
	MySQLite.query([[INSERT INTO "..Prefix.."_tutorials (
		map, title, description, pos_x, pos_y, pos_z, ang_pitch, ang_yaw, ang_roll
		) VALUES (]] ..
		tbl[map] .. [[, ]] ..
		tbl[title] .. [[, ]] ..
		tbl[description] .. [[, ]] ..
		tbl[pos_x] .. [[, ]] ..
		tbl[pos_y] .. [[, ]] ..
		tbl[pos_z] .. [[, ]] ..
		tbl[ang_pitch] .. [[, ]] ..
		tbl[ang_yaw] .. [[, ]] ..
		tbl[ang_roll] .. [[);]], function( result )
			if not result then
				ply:ChatPrint( "Tutorial point saved!" )
		--Reload saved tutorials, and bcast the new table to all players.
				InitLoadTutsFromDB()
			else
				ply:ChatPrint( "Result of saving tutorial: "..tostring( result ) )
			end
		end )
end )

util.AddNetworkString( "DeleteTutPoint" )
net.Receive( "DeleteTutPoint", function( length, ply )
	if not ( ply:IsAdmin() or ply:IsSuperAdmin() ) then return end
	local tutName = net.ReadString()
	GAMEMODE:WriteOut( "Receiving request to delete tut point "..tutName.." from "..tostring( ply ), Severity.Debug )
	MySQLite.query("DELETE FROM "..Prefix.."_tutorials WHERE title = \""..MySQLite.SQLStr(tutName).."\";", function( result )
		InitLoadTutsFromDB()
	end )
end )