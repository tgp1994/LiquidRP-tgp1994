GM.Version = "1"
GM.Name = "Liquid DarkRP"
GM.Author = "By Jackool + DarkRP creators and Deadman123/Derp"

DeriveGamemode("sandbox")
local function LoadModules()
	local root = GM.FolderName.."/gamemode/modules/"

	local _, folders = file.Find(root.."*", "LUA")

	for _, folder in SortedPairs(folders, true) do
		if DarkRP.disabledDefaults["modules"][folder] then continue end

		for _, File in SortedPairs(file.Find(root .. folder .."/sh_*.lua", "LUA"), true) do
			if File == "sh_interface.lua" then continue end
			include(root.. folder .. "/" ..File)
		end
		for _, File in SortedPairs(file.Find(root .. folder .."/cl_*.lua", "LUA"), true) do
			if File == "cl_interface.lua" then continue end
			include(root.. folder .. "/" ..File)
		end
	end
end

LDRP_DLC = {}
LDRP_DLC.Find = file.Find(GM.FolderName .. "/gamemode/dlc/*.lua", "LUA")
LDRP_DLC.CL = {}
include("modules/von.lua")

for k,v in pairs(LDRP_DLC.Find) do
	local Ext = string.sub(v,1,3)
	local LoadAfter = (string.find(string.lower(v,"_loadafterdarkrp"),"_loadafterdarkrp") and "after") or "before"
	if Ext == "sh_" or Ext == "cl_" then
		LDRP_DLC.CL["dlc/" .. v] = LoadAfter
	elseif Ext != "sv_" then
		MsgN("One of your DLCs is using an invalid format!")
		MsgN("DLCs must start with either cl_ sv_ or sh_")
	end
end


for k,v in pairs(LDRP_DLC.CL) do
	if v == "before" then
		include(k)
		LDRP_DLC.CL[k] = nil
	end
end

local function MC(num)
	return math.Clamp(num,1,255)
end

local function LDRPColorMod(r,g,b,a)
	local Clrs = LDRP_Theme[LDRP_Theme.CurrentSkin].TradeMenu
	return Color(MC(Clrs.r+r),MC(Clrs.g+g),MC(Clrs.b+b),MC(Clrs.a+a))
end

local function IcoClrMod(r,g,b,a)
	local Clrs = LDRP_Theme[LDRP_Theme.CurrentSkin].IconBG
	return Color(MC(Clrs.r+r),MC(Clrs.g+g),MC(Clrs.b+b),MC(Clrs.a+a))
end

function CreateIcon(panel,model,sizex,sizey,clickfunc,campos,lookat) -- Liquid DarkRP CreateIcon
	local BG = vgui.Create("DPanel")
	if panel then BG:SetParent(panel) end
	BG:SetSize( sizex, sizey )
	local Pressed = false
	BG.Paint = function()
		local Clr = (Pressed and LDRPColorMod(50,50,50,-50)) or LDRPColorMod(30,30,30,-50)
		draw.RoundedBox(6,0,0,sizex,sizey,LDRPColorMod(-60,-60,-60,-20))
		draw.RoundedBox(6,4,4,sizex-8,sizey-8,Clr)
	end
	
	local icon = vgui.Create( "DModelPanel", BG )
	icon:SetModel(model)
	icon:SetSize( sizex-8,sizey-8 )
	icon:SetPos(4,4)

	local iconmove = 0
	local Hovered = false
	function icon:LayoutEntity(Ent)
		if Hovered then
			iconmove = iconmove+1
			Ent:SetAngles( Angle( 0, iconmove,  0) )
		else
			if iconmove != 0 then iconmove = 0 end
			Ent:SetAngles( Angle( 0, 0, 0) )
		end
	end
	icon:SetCamPos( campos or Vector( 12, 12, 12 ) )
	icon:SetLookAt( lookat or Vector( 0, 0, 0 ) )
	
	local iconbutton = vgui.Create( "DButton", icon )
	iconbutton:SetSize(sizex,sizey)
	iconbutton:SetDrawBackground(false)
	iconbutton:SetText("")
	iconbutton.OnCursorEntered = function()
		Hovered = true
	end
	iconbutton.OnCursorExited = function()
		Hovered = false
		Pressed = false
	end
	iconbutton.OnMousePressed = function()
		Pressed = true
	end
	iconbutton.OnMouseReleased = function()
		Pressed = false
		clickfunc()
	end
	
	function BG:SetToolTip(str)
		iconbutton:SetToolTip(str)
	end
	
	return BG
end

include("client/help.lua")
include("liquiddrp/sh_liquiddrp.lua")

include("liquiddrp/cl_dermaskin.lua")
function GM:ForceDermaSkin()
	return "LiquidDRP2"
end

local function LoadLiquidDarkRP()
	include("liquiddrp/cl_stores.lua")

	include("liquiddrp/sh_qmenu.lua")
	
	include("liquiddrp/cl_crafting.lua")
	
	include("liquiddrp/cl_skills.lua")
end

CUR = "$"

HelpLabels = { }
HelpCategories = { }

/*---------------------------------------------------------------------------
Names
---------------------------------------------------------------------------*/
-- Make sure the client sees the RP name where they expect to see the name
local pmeta = FindMetaTable("Player")

local ENT = FindMetaTable("Entity")
ENT.OldIsVehicle = ENT.IsVehicle

function ENT:IsVehicle()
	if type(self) ~= "Entity" then return false end
	local class = string.lower(self:GetClass())
	return ENT:OldIsVehicle() or string.find(class, "vehicle") 
	-- Ent:IsVehicle() doesn't work correctly clientside:
	--[[
		] lua_run_cl print(LocalPlayer():GetEyeTrace().Entity)
		> 		Entity [128][prop_vehicle_jeep_old]
		] lua_run_cl print(LocalPlayer():GetEyeTrace().Entity:IsVehicle())
		> 		false
	]]
end

function GM:DrawDeathNotice(x, y)
	if not GAMEMODE.Config.showdeaths then return end
	self.BaseClass:DrawDeathNotice(x, y)
end

local function DisplayNotify(msg)
	local txt = msg:ReadString()
	GAMEMODE:AddNotify(txt, msg:ReadShort(), msg:ReadLong())
	surface.PlaySound("buttons/lightswitch2.wav")

	-- Log to client console
	print(txt)
end
usermessage.Hook("_Notify", DisplayNotify)

LocalPlayer().DarkRPVars = LocalPlayer().DarkRPVars or {}
for k,v in pairs(player.GetAll()) do
	v.DarkRPVars = v.DarkRPVars or {}
end

GM.Config = {} -- config table

include("config/config.lua")
include("libraries/fn.lua")
include("libraries/interfaceloader.lua")
include("libraries/disjointset.lua")

include("libraries/modificationloader.lua")
LoadModules()

DarkRP.DARKRP_LOADING = true
include("config/jobrelated.lua")
include("config/addentities.lua")
DarkRP.DARKRP_LOADING = nil

DarkRP.finish()

include("MakeThings.lua")
include("cl_vgui.lua")
include("showteamtabs.lua")
include("client/help.lua")

if UseFPP then
	include("FPP/sh_settings.lua")
	include("FPP/client/FPP_Menu.lua")
	include("FPP/client/FPP_HUD.lua")
	include("FPP/client/FPP_Buddies.lua")
	include("FPP/sh_CPPI.lua")
end

LoadLiquidDarkRP()

-- Copy from FESP(made by FPtje Falco)
-- This is no stealing since I made FESP myself.
local vector = FindMetaTable("Vector")
function vector:RPIsInSight(v, ply)
	ply = ply or LocalPlayer()
	local trace = {}
	trace.start = ply:EyePos()
	trace.endpos = self	
	trace.filter = v
	trace.mask = -1
	local TheTrace = util.TraceLine(trace)
	if TheTrace.Hit then
		return false, TheTrace.HitPos
	else
		return true, TheTrace.HitPos
	end
end

function GM:HUDShouldDraw(name)
	if name == "CHudHealth" or
		name == "CHudBattery" or
		name == "CHudSuitPower" or
		(HelpToggled and name == "CHudChat") then
			return false
	else
		return true
	end
end

function GM:HUDDrawTargetID()
    return false
end

function FindPlayer(info)
	local pls = player.GetAll()

	-- Find by Index Number (status in console)
	for k, v in pairs(pls) do
		if tonumber(info) == v:UserID() then
			return v
		end
	end

	-- Find by RP Name
	for k, v in pairs(pls) do
		if string.find(string.lower(v.DarkRPVars.rpname or ""), string.lower(tostring(info))) ~= nil then
			return v
		end
	end

	-- Find by Partial Nick
	for k, v in pairs(pls) do
		if string.find(string.lower(v:Name()), string.lower(tostring(info))) ~= nil then
			return v
		end
	end
	return nil
end

local GUIToggled = false
local HelpToggled = false

local function ToggleClicker()
	RunConsoleCommand("-menu_context")
	GUIToggled = not GUIToggled
	gui.EnableScreenClicker(GUIToggled)
end
usermessage.Hook("ToggleClicker", ToggleClicker)
	
include("sh_commands.lua")
include("shared.lua")
include("ammotypes.lua")

if UseFadmin then
	-- DarkRP plugin for FAdmin. It's this simple to make a plugin. If FAdmin isn't installed, this code won't bother anyone
	include("fadmin_darkrp.lua")
	
	--hook.Add("PostGamemodeLoaded", "FAdmin_DarkRP", function()
		if not FAdmin or not FAdmin.StartHooks then return end
		FAdmin.StartHooks["DarkRP"] = function()
			-- DarkRP information:
			FAdmin.ScoreBoard.Player:AddInformation("Steam name", function(ply) return ply:SteamName() end, true)
			FAdmin.ScoreBoard.Player:AddInformation("Money", function(ply) if LocalPlayer():IsAdmin() and ply.DarkRPVars and ply.DarkRPVars.money then return "$"..ply.DarkRPVars.money end end)
			FAdmin.ScoreBoard.Player:AddInformation("Wanted", function(ply) if ply.DarkRPVars and ply.DarkRPVars.wanted then return tostring(ply.DarkRPVars["wantedReason"] or "N/A") end end)
			FAdmin.ScoreBoard.Player:AddInformation("Community link", function(ply) return FAdmin.SteamToProfile(ply:SteamID()) end)

			-- Warrant
			FAdmin.ScoreBoard.Player:AddActionButton("Warrant", "FAdmin/icons/Message",	Color(0, 0, 200, 255),
				function(ply) local t = LocalPlayer():Team() return t == TEAM_POLICE or t == TEAM_MAYOR or t == TEAM_CHIEF end,
				function(ply, button)
					Derma_StringRequest("Warrant reason", "Enter the reason for the warrant", "", function(Reason)
						LocalPlayer():ConCommand("darkrp /warrant ".. ply:UserID().." ".. Reason)
					end)
				end)

			--wanted
			FAdmin.ScoreBoard.Player:AddActionButton(function(ply)
					return ((ply.DarkRPVars.wanted and "Unw") or "W") .. "anted"
				end,
				function(ply) return "FAdmin/icons/jail", ply.DarkRPVars.wanted and "FAdmin/icons/disable" end,
				Color(0, 0, 200, 255),
				function(ply) local t = LocalPlayer():Team() return t == TEAM_POLICE or t == TEAM_MAYOR or t == TEAM_CHIEF end,
				function(ply, button)
					if not ply.DarkRPVars.wanted  then
						Derma_StringRequest("wanted reason", "Enter the reason to arrest this player", "", function(Reason)
							LocalPlayer():ConCommand("darkrp /wanted ".. ply:UserID().." ".. Reason)
						end)
					else
						LocalPlayer():ConCommand("darkrp /unwanted ".. ply:UserID())
					end
				end)

			--Teamban
			local function teamban(ply, button)

				local menu = DermaMenu()
				local Title = vgui.Create("DLabel")
				Title:SetText("  Jobs:\n")
				Title:SetFont("UiBold")
				Title:SizeToContents()
				Title:SetTextColor(color_black)
				local command = (button.TextLabel:GetText() == "Unban from job") and "rp_teamunban" or "rp_teamban"

				menu:AddPanel(Title)
				for k,v in SortedPairsByMemberValue(RPExtraTeams, "name") do
					menu:AddOption(v.name, function() RunConsoleCommand(command, ply:UserID(), k) end)
				end
				menu:Open()
			end
			FAdmin.ScoreBoard.Player:AddActionButton("Ban from job", "FAdmin/icons/changeteam", Color(200, 0, 0, 255),
			function(ply) return FAdmin.Access.PlayerHasPrivilege(LocalPlayer(), "rp_commands", ply) end, teamban)

			FAdmin.ScoreBoard.Player:AddActionButton("Unban from job", function() return "FAdmin/icons/changeteam", "FAdmin/icons/disable" end, Color(200, 0, 0, 255),
			function(ply) return FAdmin.Access.PlayerHasPrivilege(LocalPlayer(), "rp_commands", ply) end, teamban)
		end
	--end)
end

local function blackScreen(um)
	local toggle = um:ReadBool()
	if toggle then
		local black = Color(0, 0, 0)
		local w, h = ScrW(), ScrH()
		hook.Add("HUDPaintBackground", "BlackScreen", function()
			surface.SetDrawColor(black)
			surface.DrawRect(0, 0, w, h)
		end)
	else
		hook.Remove("HUDPaintBackground", "BlackScreen")
	end
end
usermessage.Hook("blackScreen", blackScreen)

function GM:PlayerEndVoice(ply) //voice/icntlk_pl.vtf
	if LocalPlayer().DarkRPVars and IsValid(LocalPlayer().DarkRPVars.phone) then
		ply.DRPIsTalking = false
		timer.Simple(0.2, function() 
			if IsValid(LocalPlayer().DarkRPVars.phone) then
				LocalPlayer():ConCommand("+voicerecord") 
			end
		end)
		self.BaseClass:PlayerEndVoice(ply)
		return
	end
	
	isSpeaking = false
	
	if ply == LocalPlayer() and not GAMEMODE.Config.sv_alltalk and GAMEMODE.Config.voiceradius then
		HearMode = "talk"
		hook.Remove("Think", "RPGetRecipients")
		hook.Remove("HUDPaint", "RPinstructionsOnSayColors")
		Messagemode = false
		playercolors = {}
	end
	
	if ply == LocalPlayer() then
		ply.DRPIsTalking = false
		return
	end	
	self.BaseClass:PlayerEndVoice(ply)
end

local function GetAvailableVehicles()
	print("Available vehicles for custom vehicles:")
	for k,v in pairs(list.Get("Vehicles")) do
		print("\""..k.."\"")
	end
end
concommand.Add("rp_getvehicles", GetAvailableVehicles)

include("liquiddrp/cl_qmenu.lua")

for k,v in pairs(LDRP_DLC.CL) do
	include(k)
end