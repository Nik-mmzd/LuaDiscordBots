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

function date()
  return os.date("[%d.%m.%y][%X]")
end

local function readFile( path )
  local answer = fs.existsSync(path) and fs.readFileSync(path) or nil
  return answer
end

local function sendAndDelete( channel, message, Ttimer )
  Ttimer = Ttimer or 3000
  local Tmessage = channel:sendMessage(message)
  if Tmessage then
    timer.setTimeout(Ttimer, coroutine.wrap(function()
      Tmessage:delete()
    end))
  end
end

function WriteFile(path, file, text)
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
	if not fs.existsSync("serverData/"..newServer.id) then 
		print("new folder for "..newServer.name)  
		fs.mkdirSync("serverData/"..newServer.id)
		newServer.owner:sendMessage("New server I see... Steps to configure me:\n```Markdown\n#Run\n.ServerConfiguration to see all the configured data\n<<.Logs ChannelID>> to set up the channel for my moderating logs.\n<<.MuteRank RankName>> to set up the default rank when muting someone... \nSay in your server .help and I'll show you all of me ;)\n\n To give other mods access to the moderating commands you will have to create a role called 'DeepBotGuide' and give it to them. (you will need this role aswell).\n```")
	end
end)


client:on(
	'ready', 
	function()
		p(string.format('Logged in as %s', client.user.username))
		client:setGameName("mrjuicylemon.es/deepBot/")
end)


client:on("messageCreate", function(message)
  if message.author == client.user or message.server == nil or message.content == nil then return end
	local carpeta = "serverData/"..message.server.id.."/"
	local serverConfig = carpeta.."ServerConfig/"

  local cmd, arg = string.match(message.content, '(%S+) (.*)')
	cmd = cmd or message.content

	if cmd == ".help" then
		message.author:sendMessage("```Markdown\n#Mod Commands:\n\n .add @someone Role\n .mute @someone Reason  \n .unmute @someone \n .banList \n .prune NumberOfMessages\n .kick @someone Reason\n .ban @someone Reason\n .tempMute @someone TimeInMinutes\n .Welcome WelcomingMessage\n\n```<@"..message.author.id..">\n")
		message.channel:sendMessage("Check PM.")
	end
	local Commander = false

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
		Roles = {}
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
		local reason = string.match(arg, "<@[%d]+> (.*)")
		Roles = {}
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
