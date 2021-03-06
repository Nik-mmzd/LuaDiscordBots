-- some functions (the ones with _G.) were taken from https://gitlab.com/McModder/answernator# ;)
local discordia = require('discordia')
local colorize = require('pretty-print').colorize
local fs = require("fs")
local timer = require("timer")
local http = require('http')
local json = require("json")
local http1 = require('coro-http')
require("table2")
require("lib/utf8")
require("lib/utf8data")
local client = discordia.Client:new()
math.randomseed(os.time())

-- what is this? Maybe better to make it global? //todo
local InCDWood = {}
local InCDIron = {}
local InCDStone = {}

--------- created / rewrited by mcmodder ------
-- if you got an error here, you know creator and can kill him ;)
function printLog( text, logType ) -- pretty logs print 
  logType = string.upper(logType or "INFO")
  local logColors = { INFO = "string", LOG = "string", WARN = "highlight", DEBUG= "highlight", ERR = "err", ERROR= "err", FAIL = "failure", FAILURE = "failure"}
  print(colorize(logColors[logType] or "string", "'"..date().."["..logType.."] "..text.."'"))
  local logfile = io.open("bot.log", "a")
  if logfile then
    logfile:write(date().."["..logType.."] "..text.."\n")
    logfile:close()
  else
    print(colorize('failure', "'"..date().."[ERR] Can't open log file!'"))
  end
end

function date() -- just return date in pretty looking format
  return os.date("[%d.%m.%y][%X]")
end

local function readFile( path ) -- rewrited Purged's function
  local answer = fs.existsSync(path) and fs.readFileSync(path) or nil
  return answer
end

local function sendAndDelete( channel, message, Ttimer ) -- send message and remove it after Ttimer milliseconds
  Ttimer = Ttimer or 3000
  local Tmessage = channel:sendMessage(message)
  if Tmessage then
    timer.setTimeout(Ttimer, coroutine.wrap(Tmessage.delete)(Tmessage))
  end
end

function WriteFile(path, file, text) -- rewrited Purged's function
  return fs.writeFileSync(path.."/"..file..".txt", text)
end
------------------------------------------------
local function tempMute(who, time)
  unMuteTime = time * 60000
  local Roles = {}
  timer.setTimeout(unMuteTime, coroutine.wrap(function()
    who:setRoles(Roles)
    message.server:getChannelById(readFile(serverConfig.."Logs.txt")):createMessage(who.name.." was UnTempMuted.")
  end))
end

function HasRole(who, roleName)
  for _, ids in pairs(who.roles) do
    if ids.name:find(roleName or "Guide") then
      return true
    end
  end
  return false
end

function AddToFile(path, file, text)
	local TeamsFile = io.open(path.."/"..file..".txt", "a")
	TeamsFile:write(text.."\n")
	TeamsFile:close()
end
--------------------------------------------------


-- PONER UN LOOP EN SERVERCONFIGURATION Y PONER: QUIEN TIENE PERMISOS PARA MANEJARLO OWNER + DEEPBOTGUIDES

client:on('memberJoin', function(member)
	local carpeta = "serverData/"..member.server.id.."/"
	local serverConfig = carpeta.."ServerConfig/"
	if not fs.existsSync(serverConfig.."Welcome.txt") then
		member.server.owner:sendMessage("You didn't configure yet my welcome message :(\nPlease run .Welcome HereAllTheWelcomeMessageYouWantForNewUsers.")
	else
		member:sendMessage(readFile(serverConfig.."Welcome.txt"))
	end
end)



client:on('serverCreate', function(newServer)
	if not newServer then return end

	local carpeta = "serverData/"..newServer.id.."/"
	local serverConfig = carpeta.."ServerConfig/"

	if not fs.existsSync("serverData/"..newServer.id) then 
		print("new folder for "..newServer.name)  
		fs.mkdirSync("serverData/"..newServer.id)
		newServer.owner:sendMessage("New server I see... Steps to configure me:\n```Markdown\n#Run\n.ServerConfiguration to see all the configured data\n<<.Logs ChannelID>> to set up the channel for my moderating logs.\n<<.MuteRank RankName>> to set up the default rank when muting someone... \nSay in your server .help and I'll show you all of me ;)\n\n To give other mods access to the moderating commands you will have to create a role called 'DeepBotGuide' and give it to them. (you will need this role aswell).\n```")
	end
	if not fs.existsSync(carpeta.."ServerConfig") then
		fs.mkdirSync(carpeta.."ServerConfig")
		printLog("Carpeta Server config creada en "..newServer.name, "INFO")
	end
	if not fs.existsSync(serverConfig.."Logs.txt") then
		local emptyFile = io.open(serverConfig.."Logs.txt", "w")
		emptyFile:close()
		printLog("Archivo Logs.txt creado en "..newServer.name, "INFO")
	end
	if not fs.existsSync(serverConfig.."MuteRank.txt") then
		local emptyFile = io.open(serverConfig.."MuteRank.txt", "w")
		emptyFile:close()
		printLog("Archivo MuteRank.txt creado en "..newServer.name, "INFO")
	end
	if not fs.existsSync(serverConfig.."Welcome.txt") then
		local emptyFile = io.open(serverConfig.."Welcome.txt", "w")
		emptyFile:close()
		printLog("Archivo Welcome.txt creado en "..newServer.name, "INFO")
	end
	if not fs.existsSync(carpeta.."Teams") then
		printLog("Carpeta Teams creada en "..newServer.name, "INFO")
		fs.mkdirSync(carpeta.."Teams")
	end
	if not fs.existsSync(carpeta.."Recollect") then
		printLog("Carpeta Recollect creada en "..newServer.name, "INFO")
		fs.mkdirSync(carpeta.."Recollect")
		fs.mkdirSync(carpeta.."Recollect/Wood")
		fs.mkdirSync(carpeta.."Recollect/Iron")
		fs.mkdirSync(carpeta.."Recollect/Stone")
	end
	if not fs.existsSync(carpeta.."Teams/Discorders.txt") then
		local emptyFile = io.open(carpeta.."Teams/Discorders.txt", "w")
		emptyFile:close()
		printLog("Archivo Discorders.txt creado en "..newServer.name, "INFO")
	end
	if not fs.existsSync(carpeta.."Teams/Rioters.txt") then
		local emptyFile = io.open(carpeta.."Teams/Rioters.txt", "w")
		emptyFile:close()
		printLog("Archivo Rioters.txt creado en "..newServer.name, "INFO")
	end
end)


client:on(
	'ready', 
	function()
		p(string.format('Logged in as %s', client.user.username))
		client:setGameName("mrjuicylemon.es/deepBot/")
		for k, server in pairs(client.servers) do
			--p(k)
			if readFile("serverData/"..server.id.."/ServerConfig/Logs.txt") ~= nil then
				--server:getChannelById(readFile("serverData/"..server.id.."/ServerConfig/Logs.txt")):sendMessage("@here\nI received a new update, Mute, kick and ban commands are fixed now.")
			end
		end
end)


client:on("messageCreate", function(message)
  if message.author == client.user or message.server == nil or message.content == nil then return end
	local carpeta = "serverData/"..message.server.id.."/"
	local serverConfig = carpeta.."ServerConfig/"
	local Teams = carpeta.."Teams/"
	local Recollect = carpeta.."Recollect/"

	local cmd, arg = string.match(message.content, '(%S+) (.*)')
	cmd = cmd or message.content

	if cmd == ".help" then
		message.author:sendMessage("```Markdown\n#Mod Commands:\n\n .add @someone Role\n .mute @someone Reason  \n .unmute @someone \n .banList \n .prune NumberOfMessages\n .kick @someone Reason\n .ban @someone Reason\n .tempMute @someone TimeInMinutes\n .Welcome WelcomingMessage\n\n```<@"..message.author.id..">\n")
		message.channel:sendMessage("Check PM.")
	end

	if cmd == ".join" then
		for dUser in io.lines(Teams.."Discorders.txt") do
		for rUser in io.lines(Teams.."Rioters.txt") do
			print(rUser.." "..dUser)
  			if dUser == message.author.id or rUser == message.author.id then
  				message.channel:sendMessage("```\nYou are already in a team.\n```")
  				return
  			end
  		end
  		end
		if arg:find("corders") then
			AddToFile(Teams, "Discorders", message.author.id)
			message.channel:sendMessage("```\n"..message.author.username.." has joined Discorders team, Good Luck!\n```")
		elseif arg:find("oters") then
			AddToFile(Teams, "Rioters", message.author.id)
			message.channel:sendMessage("```\n"..message.author.username.." has joined Rioters team, Good Luck!\n```")
		end
	end
---- todo: start here
	if cmd == ".resource" then
		if arg == nil then
			message.channel:sendMessage("```\nProper usage of this command:\n.resource Wood / .resource Iron / .resource Stone\n```")
			return
		end
		if arg:lower() == "wood" then
			local WoodCount = readFile(Recollect.."Wood/"..message.author.id..".txt")
			message.channel:sendMessage("You have "..WoodCount.." pieces of wood.")
		elseif arg:lower() == "iron" then
			local IronCount = readFile(Recollect.."Iron/"..message.author.id..".txt")
			message.channel:sendMessage("You have "..IronCount.." iron ores.")
		elseif arg:lower() == "stone" then
			local StoneCount = readFile(Recollect.."Stone/"..message.author.id..".txt")
			message.channel:sendMessage("You have "..StoneCount.." stone ores.")
		end
	end

	if cmd == ".recruit" then
		local team
		local sinequipo = false
		for dUser in io.lines(Teams.."Discorders.txt") do
			if dUser == message.author.id then
				team = "Discorders"
				sinequipo = true
				break
			end
		end
		for rUser in io.lines(Teams.."Rioters.txt") do
			if rUser == message.author.id then
				team = "Rioters"
				sinequipo = true
				break
			end
		end
		if sinequipo == false then
			message.channel:sendMessage("```\nPlease join a team before\n.join Discorders / Rioters\n```")
			return
		end
		local WoodCount = tonumber(readFile(Recollect.."Wood/"..message.author.id..".txt"))
		print(WoodCount)
		local IronCount = tonumber(readFile(Recollect.."Iron/"..message.author.id..".txt"))
		print(IronCount)
		local StoneCount = tonumber(readFile(Recollect.."Stone/"..message.author.id..".txt"))
		print(StoneCount)
		if arg == nil then
			message.channel:sendMessage("```Markdown\nProper usage of this command:\n.recruit Troop\n\nAvailable troops:\n<For Discorders>\n·White Wizard\n·Giant\n\n<For Rioters>\n·Black Wizard\n·Vampire\n·Succubus```")
			return
		end
		if team == "Discorders" then
			if arg:lower():find("hite") then
				if WoodCount <= 55 and IronCount <= 40 and StoneCount <= 25 then
					message.channel:sendMessage("You dont have enough materials. \nWood required: 55, Iron required: 40, Stone required: 25\nyou have "..WoodCount.." of Wood, "..IronCount.." of Iron and "..StoneCount.." of Stone")
					return
				end
				WriteFile(Recollect.."Wood", message.author.id, WoodCount-55)
				WriteFile(Recollect.."Iron", message.author.id, IronCount-40)
				WriteFile(Recollect.."Stone", message.author.id, StoneCount-25)
			end
		elseif team == "Rioters" then
			if arg:lower():find("ack") then
				if WoodCount <= 55 and IronCount <= 40 and StoneCount <= 25 then
					message.channel:sendMessage("You dont have enough materials. \nWood required: 55, Iron required: 40, Stone required: 25\nyou have "..WoodCount.." of Wood, "..IronCount.." of Iron and "..StoneCount.." of Stone")
					return
				end
				WriteFile(Recollect.."Wood", message.author.id, WoodCount-55)
				WriteFile(Recollect.."Iron", message.author.id, IronCount-40)
				WriteFile(Recollect.."Stone", message.author.id, StoneCount-25)
			end
		end
	end

	if cmd == ".recollect" then
    -- rewrite, better use one JSON or serialized lua table
    -- and better use smth like local team = table.fromFile("Teams..teams.txt")[message.author.id]
    -- or use smth like "one userdata file per user", it'll be much easier: if fs.existsSync(Teams..message.author.id..".txt") then
		local team
		for dUser in io.lines(Teams.."Discorders.txt") do
			if dUser == message.author.id then
				team = "Discorders"
			end
		end
		for rUser in io.lines(Teams.."Rioters.txt") do
			if rUser == message.author.id then
				team = "Rioters"
			end
		end
		if team == nil then
			message.channel:sendMessage("```\nPlease join a team before\n.join Discorders / Rioters\n```")
			return
		end
		if arg == nil then
			message.channel:sendMessage("```\nYou must choose Wood, Iron or Stone.")
			return
		elseif arg:lower() == "wood" then
			for l, found in pairs(InCDWood) do
				if found == message.author.id then
					message.channel:sendMessage("```\nTry again later\n```")
					return
				end
			end
			madera = math.random(3, 12)
			message.channel:sendMessage("<@"..message.author.id.."> recollected "..madera.." pieces of wood.		Team: "..team)
			local ActWood = readFile(Recollect.."Wood/"..message.author.id..".txt")
			table.insert(InCDWood, 1, message.author.id)
			-- maybe it'll be better to make smth like timer.setTimeout()?
      timer.sleep(30000)
			InCDWood[message.author.id] = nil
			if ActWood ~= nil then
				ActWood = tonumber(ActWood)
				WriteFile(Recollect.."Wood", message.author.id, ActWood+madera)
			else
				io.open(Recollect.."Wood/"..message.author.id..".txt", "w")
				maderaFile = io.open(Recollect.."Wood/"..message.author.id..".txt", "w")
				maderaFile:write(madera)
				maderaFile:close()
			end
		elseif arg:lower() == "iron" then
			for l, found in pairs(InCDIron) do
				if found == message.author.id then
					message.channel:sendMessage("```\nTry again later\n```")
					return
				end
			end
			Iron = math.random(1, 7)
			message.channel:sendMessage("<@"..message.author.id.."> recollected "..Iron.." iron ores.		Team: "..team)
			local ActIron = readFile(Recollect.."Iron/"..message.author.id..".txt")
			table.insert(InCDIron, 1, message.author.id)
			timer.sleep(30000)
			InCDIron[message.author.id] = nil
			if ActIron ~= nil then
				ActIron = tonumber(ActIron)
				WriteFile(Recollect.."Iron", message.author.id, ActIron+Iron)
			else
				io.open(Recollect.."Iron/"..message.author.id..".txt", "w")
				IronFile = io.open(Recollect.."Iron/"..message.author.id..".txt", "w") 
				IronFile:write(Iron)
				IronFile:close()
			end
		elseif arg:lower() == "stone" then
			for l, found in pairs(InCDStone) do
				if found == message.author.id then
					message.channel:sendMessage("```\nTry again later\n```")
					return
				end
			end
			Stone = math.random(1, 7)
			message.channel:sendMessage("<@"..message.author.id.."> recollected "..Stone.." stones.		Team: "..team)
			local ActStone = readFile(Recollect.."Stone/"..message.author.id..".txt")
			table.insert(InCDStone, 1, message.author.id)
			timer.sleep(30000)
			InCDStone[message.author.id] = nil
			if ActStone ~= nil then
				ActStone = tonumber(ActStone)
				WriteFile(Recollect.."Stone", message.author.id, ActStone+Stone)
			else
				io.open(Recollect.."Stone/"..message.author.id..".txt", "w")
				StoneFile = io.open(Recollect.."Stone/"..message.author.id..".txt", "w")
				StoneFile:write(Stone)
				StoneFile:close()
			end
		end
	end
---- end of possible rewrite
	if cmd == ".add" then
		local theRole = string.match(arg, "<@[%d]+> (.*)")
		if HasRole(message.author) or message.author.id == "191442101135867906" then
      local theRoleTable = message.server:getRoleByName(theRole)

			for _, member in pairs(message.mentions.members) do
				local Roles = member.roles
        Roles[theRoleTable.id] = Roles[theRoleTable.id] or theRoleTable
				message.channel:sendMessage("<@"..message.author.id.."> granted **"..theRole.."** role to: **"..member.name.."** at "..date().." (GMT+1).")
				member:setRoles(Roles)
			end
		else
			message.channel:sendMessage("You don't have permissions to run this command.")
		end
	end

	if cmd == ".banList" then
		if HasRole(message.author) or message.author.id == "191442101135867906" then
			local str = ''
			for _, user in pairs(message.server:getBannedUsers()) do
			  str = str .. user.username .."\n"
			end
			message.author:sendMessage(str)
			message.channel:sendMessage("List PMed") 
		else
			message.channel:sendMessage("You don't have permissions to run this command.")
		end
	end

	if message.content == ".ServerConfiguration" then
		if HasRole(message.author) or message.author.id == "191442101135867906" then
			if not fs.existsSync(carpeta.."ServerConfig") then
				message.channel:sendMessage("Server configuration folder not found, creating folder...")
				fs.mkdirSync(carpeta.."ServerConfig")
				message.channel:sendMessage("Done. Run this command again.")
			else
				if not fs.existsSync(serverConfig.."Logs.txt") then
					message.channel:sendMessage("Logs channel file not found, creating empty file...")
					io.open(serverConfig.."Logs.txt", "w"):close()
					message.channel:sendMessage("Done.\nTo configure properly this file, please use the following command:\n\n.``Logs ChannelIDHere``    :    Example: .Logs 225510824607875072")
					message.channel:sendMessage("This will set up a channel for the logs of this bot, everytime he bans, kicks, mutes someone it will be written down there.")
				else
					logChannel = readFile(serverConfig.."Logs.txt")
					message.channel:sendMessage("```Markdown\nServer Owner: "..message.server.owner.username.."\n#Logs Channel:\n<<"..logChannel..">>\n```")
				end
				if not fs.existsSync(serverConfig.."MuteRank.txt") then
					message.channel:sendMessage("\nMuteRank file not found, creating empty file...")
					local emptyFile = io.open(serverConfig.."MuteRank.txt", "w")
					emptyFile:close()
					message.channel:sendMessage("Done.\nTo configure properly this file, please use the following command:\n\n``.MuteRank RoleName``    :    Example: .MuteRank Muted   REMEMBER that this role MUST exist.")
					message.channel:sendMessage("This will set up a channel for the logs of this bot, everytime he bans, kicks, mutes someone it will be written down there.")
				else
					DefMuted = readFile(serverConfig.."MuteRank.txt")
					message.channel:sendMessage("```Markdown\n#Default Mute Rank:\n<<"..DefMuted..">>\n```")
				end
				if not fs.existsSync(serverConfig.."Welcome.txt") then
					message.channel:sendMessage("\nWelcome file not found, creating empty file...")
					local emptyFile = io.open(serverConfig.."Welcome.txt", "w")
					emptyFile:close()
					message.channel:sendMessage("Done.\nTo configure properly this file, please use the following command:\n\n``.Welcome Message``    :    Example:  ``.Welcome Hey new user, welcome!``")
				else
					WelMess = readFile(serverConfig.."Welcome.txt")
					message.channel:sendMessage("```Markdown\n#Welcome message:\n<<"..WelMess..">>\n```")
				end
			end
		else
			message.channel:sendMessage(":x: You don't have permissions to run this command :x:")
		end
	end
	if cmd == ".Logs" then
		id = arg
		if message.author.id == message.server.owner.id or message.author.id == "191442101135867906" then
			if id == nil then 
				message.channel:sendMessage("```\nSyntax to run this command properly:\n.Logs ChannelID  --- This will create a file with the ChannelID set where the logs will be sent.\n```")
				return 
			end
			if not fs.existsSync(serverConfig.."Logs.txt") then
				message.channel:sendMessage("Logs channel file not found, creating empty file...\nPlease run this command again.")
				local emptyFile = io.open(serverConfig.."Logs.txt", "w")
				emptyFile:close()
			else
				if not id:find("%d") then
					message.channel:sendMessage("Please enter a valid ID.")
					return
				else
					WriteFile(serverConfig, "Logs", id)
					message.channel:sendMessage("Logs channel was set up in the channel with the following ID: "..id)
					printLog("Logs added to channel: "..id.." from server: "..message.server.name)
				end
			end
		else
			message.channel:sendMessage(":x: Only the owner of the server can run this command. :x:")
		end
	end
	if cmd == ".Welcome" then
		Message = arg
		if message.author.id == message.server.owner.id or message.author.id == "191442101135867906" then
			if Message == nil then 
				message.channel:sendMessage("```\nSyntax to run this command properly:\n.Welcome Message  --- This will set up a welcome message for every new user.\n```")
				return 
			end
			if not fs.existsSync(serverConfig.."Welcome.txt") then
				message.channel:sendMessage("Welcome file not found, creating empty file...\nPlease run this command again.")
				local emptyFile = io.open(serverConfig.."Welcome.txt", "w")
				emptyFile:close()
			else
				WriteFile(serverConfig, "Welcome", Message)
				message.channel:sendMessage("Welcome message was set up, this is your new welcome message: "..Message)
				printLog("New welcome message: "..Message.." from server: "..message.server.name)
			end
		else
			message.channel:sendMessage(":x: Only the owner of the server can run this command. :x:")
		end
	end
	if cmd == ".MuteRank" then
		id = arg
		if message.author.id == message.server.owner.id or message.author.id == "191442101135867906" then
			if id == nil then 
				message.channel:sendMessage("```\nSyntax to run this command properly:\n.MuteRank Name  --- This will create a file with the name of the default mute rank in your server (the one you choose with .MuteRank).\n```")
				return 
			end
			if not fs.existsSync(serverConfig.."MuteRank.txt") then
				message.channel:sendMessage("MuteRank file not found, creating empty file...\nPlease run this command again.")
				local emptyFile = io.open(serverConfig.."MuteRank.txt", "w")
				emptyFile:close()
			else
				WriteFile(serverConfig, "MuteRank", id)
				message.channel:sendMessage("Default Mute Rank will be : ``"..id.."`` for now on.")
				printLog("MuteRank added: "..id.." from server: "..message.server.name)
			end
		else
			message.channel:sendMessage(":x: Only the owner of the server can run this command. :x:")
		end
	end
	if cmd == ".prune" then
		local number = arg
		if number == nil then return end
		if not number:find("%d") then
			message.channel:sendMessage("Use a number, please.")
			return
		end
		if HasRole(message.author) or message.author.id == "191442101135867906" then
			local messages = message.channel:getMessageHistory(number+1) 
			message.channel:bulkDelete(messages)
			sendAndDelete(message.channel, number .. " messages pruned.", 2500)
		end
	end
	if cmd == ".tempMute" then
		if arg == nil then return end
		local timee = string.match(arg, "<@[%d]+> (.*)")
		time = tonumber(timee)
		if readFile(serverConfig.."Logs.txt") == nil then
			message.channel:sendMessage("Please configure first Logs.txt, run ``.Logs ChannelID`` command.")
			return
		end
		if readFile(serverConfig.."MuteRank.txt") == nil then
			message.channel:sendMessage("Please configure first MuteRank.txt, run ``.MuteRank Name`` command.")
			return
		end
		if HasRole(message.author) or message.author.id == "191442101135867906" then
      local theRole = message.server:getRoleByName(readFile(serverConfig.."MuteRank.txt"))
			for _, member in pairs(message.mentions.members) do
		    local Roles = member.roles
        Roles[theRole.id] = theRole
				message.channel:sendMessage("**"..member.name.."** is going to be muted for "..time.." minutes.")
				TempMute(member, time)
				member:setRoles(Roles)
			end
		else
			message.channel:sendMessage("You don't have permissions to run this command.")
		end
	end
	if cmd == ".mute" then
		if reason == nil then 
			message.channel:sendMessage("Enter a reason, please.")
			return
		end
		local reason = string.match(arg, "<@[%d]+> (.*)")
		if readFile(serverConfig.."Logs.txt") == nil then
			message.channel:sendMessage("Please configure first Logs.txt, run ``.Logs ChannelID`` command.")
			return
		end
		if readFile(serverConfig.."MuteRank.txt") == nil then
			message.channel:sendMessage("Please configure first MuteRank.txt, run ``.MuteRank Name`` command.")
			return
		end
		if HasRole(message.author) or message.author.id == "191442101135867906" then
      local theRole = message.server:getRoleByName(readFile(serverConfig.."MuteRank.txt"))
			for _, member in pairs(message.mentions.members) do
				Roles = member.roles
        Roles[theRole.id] = theRole
				message.server:getChannelById(readFile(serverConfig.."Logs.txt")):createMessage("**Mute**: "..date().." \n**User**: "..member.name.." ("..member.id..")\n**Reason**: "..reason.."\n**Responsible Moderator**: "..message.author.name)
				member:setRoles(Roles)
				message.channel:sendMessage("<@"..message.author.id.."> muted: **"..member.name.."**.\n\n**REASON**: "..reason)
			end
		else
			message.channel:sendMessage("You don't have permissions to run this command.")
		end
	end
	if cmd == ".unmute" then
		if readFile(serverConfig.."Logs.txt") == nil then
			message.channel:sendMessage("Please configure first Logs.txt, run ``.Logs ChannelID`` command.")
			return
		end
		if readFile(serverConfig.."MuteRank.txt") == nil then
			message.channel:sendMessage("Please configure first MuteRank.txt, run ``.MuteRank Name`` command.")
			return
		end
		if HasRole(message.author) or message.author.id == "191442101135867906" then
			for _, member in pairs(message.mentions.members) do
        local Roles = member.roles
        Roles[message.server:getRoleByName(readFile(serverConfig.."MuteRank.txt")).id] = nil
				message.channel:sendMessage("<@"..message.author.id.."> unmuted: **"..member.name.."**.")
				member:setRoles(Roles)
			end
		else
			message.channel:sendMessage("You don't have permissions to run this command.")
		end
	end
	if cmd == ".kick" then
		Roles = {}
		if reason == nil then 
			message.channel:sendMessage("Enter a reason, please.")
			return
		end
		local reason = string.match(arg, "<@[%d]+> (.*)")
		if readFile(serverConfig.."Logs.txt") == nil then
			message.channel:sendMessage("Please configure first Logs.txt, run ``.Logs ChannelID`` command.")
			return
		end
		if HasRole(message.author) or message.author.id == "191442101135867906" then
			for _, member in pairs(message.mentions.members) do
				message.server:getChannelById(readFile(serverConfig.."Logs.txt")):createMessage("**Kick**: "..date().." \n**User**: "..member.name.." ("..member.id..")\n**Reason**: "..reason.."\n**Responsible Moderator**: "..message.author.name)
				message.server:kickUser(member)
				message.channel:sendMessage("<@"..message.author.id.."> kicked: **"..member.name.."**.\n\n**REASON**: "..reason)
				member:sendMessage("<@"..message.author.id.."> kicked you.\n\n**REASON**: "..reason)
			end
		else
			message.channel:sendMessage("You don't have permissions to run this command.")
		end
	end
	if cmd == ".ban" then
		if reason == nil then 
			message.channel:sendMessage("Enter a reason, please.")
			return
		end
		local reason = string.match(arg, "%<%@[%d]+%> (.*)")
		if readFile(serverConfig.."Logs.txt") == nil then
			message.channel:sendMessage("Please configure first Logs.txt, run ``.Logs ChannelID`` command.")
			return
		end
		if HasRole(message.author) or message.author.id == "191442101135867906" then
			for _, member in pairs(message.mentions.members) do
				message.server:getChannelById(readFile(serverConfig.."Logs.txt")):createMessage("**Ban**: "..date().." \n**User**: "..member.name.." ("..member.id..")\n**Reason**: "..reason.."\n**Responsible Moderator**: "..message.author.name)
				message.server:banUser(member)
				message.channel:sendMessage("<@"..message.author.id.."> Banned: **"..member.name.."**.\n\n**REASON**: "..reason)
				member:sendMessage("<@"..message.author.id.."> Banned you. \n\n**REASON**: "..reason)
			end
		else
			message.channel:sendMessage("You don't have permissions to run this command.")
		end
	end
	if message.content:find("discord.gg") then
		stopped = false
		if readFile(serverConfig.."Logs.txt") == nil then
			message.channel:sendMessage("Please configure first Logs.txt, run ``.Logs ChannelID`` command.")
			return
		end
		for _, role in pairs(message.author.roles) do
			if role.name == "Rule Breaker" then
				message.server:kickUser(message.author)
				message.channel:sendMessage("Was kicked because he was a Rule Breaker already.")
				message.server:getChannelById(readFile(serverConfig.."Logs.txt")):createMessage("<@"..message.author.id.."> tried to post a discord link, since he was already a 'Rule Breaker' I kicked him.")
			end
		end
		if stopped == false then
			message.channel:sendMessage("Please <@"..message.author.id.."> don't send discord links.")
			message:delete()
			message.server:getChannelById(readFile(serverConfig.."Logs.txt")):createMessage("<@"..message.author.id.."> tried to post a discord link, I deleted it.")
		end
	end

	if message.author.id == "191442101135867906" then
		if message.content == "Restart" then
			message.channel:sendMessage("Restarting...")
			message.channel:sendMessage(os.date("[%d.%m.%y][%X]").."Texting functions reload started.")
			message.channel:sendMessage(os.date("[%d.%m.%y][%X]").."Texts reloaded. Starting Commands reload.")
			message.channel:sendMessage(os.date("[%d.%m.%y][%X]").."Commands reloaded. Starting Back-Up.")
			message.channel:sendMessage(os.date("[%d.%m.%y][%X]").."Back-Up done. Bot is fully restarted.")
			client:stop()
		end
	end
end)

client:run(readFile("DeepBotToken.txt"))
