local sx, sy = guiGetScreenSize();

local scoreboard = {};

local function onPageLoaded()
	
end

local function loadPage()
	loadBrowserURL(source, scoreboard.page);
	--toggleBrowserDevTools(source, true);
	removeEventHandler("onClientBrowserCreated", scoreboard.theBrowser, loadPage);
	addEventHandler("onClientBrowserDocumentReady", scoreboard.theBrowser, onPageLoaded);
	loadPage = nil;
end

function initScoreboard()
	scoreboard.page = "http://mta/local/html/index.html";

	--local blurbox = exports.dgs:dgsCreateBlurBox(sx,sy);
	--exports.dgs:dgsBlurBoxSetIntensity(blurbox, 3);
	--scoreboard.background = exports.dgs:dgsCreateImage(0,0,sx,sy,blurbox,false);
	--exports.dgs:dgsSetPostGUI(scoreboard.background, false);

	--exports.dgs:dgsSetVisible(scoreboard.background, false);

	--scoreboard.theBrowser = createBrowser(sx, sy, true, true);
	scoreboard.guiBrowser = guiCreateBrowser(0, 0, sx, sy, true, true, false);
	scoreboard.theBrowser = guiGetBrowser(scoreboard.guiBrowser);
	
	guiSetVisible(scoreboard.guiBrowser, false);
	--setBrowserRenderingPaused(scoreboard.theBrowser, true);
	
	addEventHandler("onClientBrowserCreated", scoreboard.theBrowser, loadPage);
end

addEventHandler("onClientResourceStart", resourceRoot,
function()
	--triggerServerEvent("scoreboard:requestMaxPlayers", localPlayer);
	initScoreboard()
end)

local function getPlayerRole(player)
	if ( ( getElementData(player, 'hiddenadmin') or 0 ) == 1 ) then return false end;
	local adminDuty = getElementData(player, "duty_admin") or 0;
	if (exports.integration:isPlayerFounder(player) and adminDuty == 1) then
		return 'owner_founder';
	end
	local devDuty = getElementData(player, "duty_dev") or 0;
	if (exports.integration:isPlayerScripter(player) and devDuty == 1) then
		return 'scripter';
	end
	if (exports.integration:isPlayerHeadAdmin(player) and adminDuty == 1) then
		return 'vice_head';
	end
	if (exports.integration:isPlayerTrialAdmin(player) and adminDuty == 1) then
		return 'admin';
	end
	
	local supportDuty = getElementData(player, "duty_supporter") or 0;
	if (exports.integration:isPlayerSupporter(player) and supportDuty == 1) then
		return 'support';
	end
	if getElementData(player,"Dubai:VIP") == true then
		return 'vip';
	end
	return false;
end


local function getPlayerData(player, isStaff)
local playerTeam = getPlayerTeam ( player )
	local pdata = {};
	pdata.id 		= getElementData(player, "playerid");
	if ( not pdata.id ) then return false end;
	pdata.name 		= getPlayerName(player):gsub("#%x%x%x%x%x%x", "");
	if getElementData(player, "fakename") then
		pdata.name = getElementData(player, "fakename");
	end
	pdata.played	= getElementData(player, "dailyLogin") or 0;
	pdata.totalHours= getElementData(player, "hoursplayed") or 0;
    pdata.rank = getElementData(player, "hoursplayed") or 0;
    pdata.level = getElementData(player, "hoursplayed") or 0;
    pdata.isAFK = 'status no-afk';

	pdata.fps		= getElementData(player, "fps") or -1;
	pdata.ping		= getPlayerPing(player);
	local role 		= getPlayerRole(player);
	if (role) then
		pdata.role		= role or '';
	end
	if (isStaff) then
		local acc 		= getElementData(player, "account:username");
		if (acc) then
			pdata.acc		= "("..getElementData(player, "account:username")..")";
		else
			pdata.acc		= '';
		end
	end
	
	return pdata;
end

local function updatePlayers()
	local data = {};
	data.players = {};
	local players = getElementsByType("player");
	local isStaff = exports.integration:isPlayerStaff(localPlayer);
	
	data.playersCount = #players;
	for k,player in ipairs(players) do
		if (player ~= localPlayer) then
			local hasHidSco, hidScoState = exports.donators:hasPlayerPerk(localPlayer, 12);
			if (not hasHidSco or hasHidSco and hidScoState == 0) then
				local pdata = getPlayerData(player, isStaff);
				if (pdata) then
					table.insert(data.players, pdata);
				end
			end
		end
	end
	table.sort(data.players, function(a, b) return b.id > a.id end);
	
	-- insert local to be at the top
	local pdata = getPlayerData(localPlayer, isStaff);
	if (pdata) then
		table.insert(data.players, 1, pdata);
	end
	executeBrowserJavascript(scoreboard.theBrowser, "refreshPlayers(`".. toJSON(data) .."`)");
end

local function setScoreboardVisible(bool)
	if (bool) then
		--setBrowserRenderingPaused(scoreboard.theBrowser, false);
		guiSetVisible(scoreboard.guiBrowser, true);
		addEventHandler("onClientRender",getRootElement(),PlayerList) 
		updatePlayers()
		scoreboard.updateTimer = setTimer(updatePlayers, 800, 0);
	else
		guiSetVisible(scoreboard.guiBrowser, false);
		--setBrowserRenderingPaused(scoreboard.theBrowser, true);
		removeEventHandler("onClientRender",getRootElement(),PlayerList) 
		killTimer(scoreboard.updateTimer);
	end
	showCursor(bool);
end

bindKey("tab", "down",
function()
	setScoreboardVisible(true);
end)

bindKey("tab", "up",
function()
	setScoreboardVisible(false);
end)

function isVisible ( )
	return guiGetVisible(scoreboard.guiBrowser);
end


local fps = 0
local fpsTick = getTickCount();
local function updateFPS(msSinceLastFrame)
    -- FPS are the frames per second, so count the frames rendered per milisecond using frame delta time and then convert that to frames per second.
    fps = (1 / msSinceLastFrame) * 1000
	if (getTickCount()-fpsTick >= 1000) then
		fpsTick = getTickCount();
		setElementData(localPlayer, "fps", math.ceil(fps));
	end
end
addEventHandler("onClientPreRender", root, updateFPS)
