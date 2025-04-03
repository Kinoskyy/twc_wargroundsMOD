local Map = {}
local Round = {
    show = false,
    teams = {},
    p = {},
    winner = nil,
    wintext = ""
}

local screen = Vector2(guiGetScreenSize())
local scale = screen.x/1920
local rectW, rectH = 600*scale, 600*scale
local font = dxCreateFont('verdana.ttf', 15*scale) or "default"
local font_2 = dxCreateFont('verdana.ttf', math.max(10, 12*scale)) or "default"
local dxDrawText_ = dxDrawText
local animationProgress = 0
local animationDuration = 600
local hideAnimationDuration = 1300
local animationStartTime = nil
local isHiding = false
local hideAnimationStartTime = nil

function dxDrawTextAligned(text, x, y, b, b1, color, scale, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded, border, ...)
    if not text or not x or not y or not color then return end
    
    font = font or "default"
    local textWidth = dxGetTextWidth(colorCoded and text:gsub('#%x%x%x%x%x%x', '') or text, scale, font)
    local textHeight = dxGetFontHeight(scale, font)

    if alignX == "center" then
        x = x - textWidth/2
    elseif alignX == "right" then
        x = x - textWidth
    end

    if alignY == "center" then
        y = y - textHeight/2
    elseif alignY == "bottom" then
        y = y - textHeight
    end

    if border then
        dxDrawText_(text:gsub('#%x%x%x%x%x%x', ''), x+1.5, y+1.5, _, _, tocolor(0, 0, 0), scale, font, 'left', 'top', clip, wordBreak, false, colorCoded, false, ...)
    end
    dxDrawText_(text, x, y, _, _, color, scale, font, 'left', 'top', clip, wordBreak, postGUI, colorCoded, false, ...)
end

function interpolateProgress(startTime, duration)
    if not startTime then return 0 end
    local now = getTickCount()
    local elapsed = now - startTime
    return math.min(elapsed/duration, 1)
end

function easeOutQuad(t)
    return t * (2 - t)
end

function removeColorCodes(text)
    return type(text) == "string" and text:gsub('#%x%x%x%x%x%x', '') or ""
end

function Map.Render()
    if not (Round.show or isHiding) then return end
    
    local progress
    if isHiding and hideAnimationStartTime then
        progress = 1 - easeOutQuad(interpolateProgress(hideAnimationStartTime, hideAnimationDuration))
        if progress <= 0 then
            Round.show = false
            isHiding = false
            return
        end
    else
        progress = easeOutQuad(interpolateProgress(animationStartTime, animationDuration))
    end

    local winTextAlpha = tocolor(255, 255, 255, 255 * progress)
    dxDrawTextAligned(tostring(Round.wintext or ""), screen.x/2, screen.y/2-rectH/2-50*scale, _, _, winTextAlpha, 1, font, 'center', 'bottom', false, false, false, true, true)

    if isElement(Round.teams[1]) then
        local team = Round.teams[1]
        local score = tonumber(getElementData(team, getRoundMapInfo().modename == 'domination' and 'Points' or 'Score') or 0)
        local attackname = getTeamName(team) or "Equipo 1"
        local attackcolor = {getTeamColor(team)}
        local team1FinalX = screen.x/2 - rectW - 25*scale
        local team1InitialX = -rectW - 50*scale
        local team1CurrentX = isHiding and (team1FinalX - (team1FinalX - team1InitialX) * (1-progress)) or (team1InitialX + (team1FinalX - team1InitialX) * progress)
        dxDrawRectangle(team1CurrentX, screen.y/2-rectH/2+rectH/7, rectW, rectH-rectH/7, tocolor(0, 0, 0, 100 * progress))
        dxDrawRectangle(team1CurrentX - 5*scale, screen.y/2-rectH/2, rectW+10*scale, rectH/7, tocolor(attackcolor[1], attackcolor[2], attackcolor[3], 150 * progress))
        
        dxDrawTextAligned(attackname:upper(), team1CurrentX - 5*scale, screen.y/2-rectH/2, _, _, tocolor(attackcolor[1], attackcolor[2], attackcolor[3], 255 * progress), 1, 'bankgothic', 'left', 'bottom', false, false, false, true, true)
        dxDrawTextAligned(tostring(score), team1CurrentX + rectW + 5*scale, screen.y/2-rectH/2,_, _, tocolor(attackcolor[1], attackcolor[2], attackcolor[3], 255 * progress),1, 'bankgothic', 'right', 'bottom', false, false, false, true, true)

		if Round.winner ~= 'Draw' then 
    	dxDrawTextAligned(Round.winner == attackname and 'WINNER' or 'LOSER', team1CurrentX + rectW/2, screen.y/2-rectH/2+((rectH/7)/2),_, _, tocolor(255, 255, 255, 255 * progress),math.max(1, math.floor(3*scale)), 'bankgothic', 'center', 'center', false, false, false, true, false)
		else
    	dxDrawTextAligned('TIE', team1CurrentX + rectW/2, screen.y/2-rectH/2+((rectH/7)/2),_, _, tocolor(255, 255, 255, 255 * progress),math.max(1, math.floor(3*scale)), 'bankgothic', 'center', 'center', false, false, false, true, false)
		end
        local offsetx, offsety = team1CurrentX, screen.y/2-rectH/2+rectH/7
        dxDrawTextAligned('Name:', offsetx+10*scale, offsety+15*scale, _, _, tocolor(255, 255, 255, 255 * progress), 1, font_2,'left', 'top', false, false, false, true, false)
        dxDrawTextAligned('Damage:', offsetx+350*scale, offsety+15*scale,_, _, tocolor(255, 255, 255, 255 * progress), 1, font_2,'right', 'top', false, false, false, true, false)
        dxDrawTextAligned('Kills:', offsetx+450*scale, offsety+15*scale,_, _, tocolor(255, 255, 255, 255 * progress), 1, font_2,'right', 'top', false, false, false, true, false)
        dxDrawTextAligned('Health:', offsetx+560*scale, offsety+15*scale,_, _, tocolor(255, 255, 255, 255 * progress), 1, font_2,'right', 'top', false, false, false, true, false)

        local dmgx = offsetx+350*scale - dxGetTextWidth('Damage:', 1, font_2)/2
        local killsx = offsetx+450*scale - dxGetTextWidth('Kills:', 1, font_2)/2
        local hpx = offsetx+560*scale - dxGetTextWidth('Health:', 1, font_2)/2 
        offsety = offsety + 25*scale

        for k, v in pairs(Round.p or {}) do
            if v.Team == team then
                dxDrawTextAligned(removeColorCodes(v.Name or ""), offsetx+10*scale, offsety+25*scale,_, _, tocolor(255, 255, 255, 255 * progress), 1, font_2,'left', 'top', false, false, false, true, false)
                dxDrawTextAligned(tostring(v.Damage or 0), dmgx, offsety+25*scale,_, _, tocolor(255, 255, 255, 255 * progress), 1, font_2,'center', 'top', false, false, false, true, false)
                dxDrawTextAligned(tostring(v.Kills or 0), killsx, offsety+25*scale,_, _, tocolor(255, 255, 255, 255 * progress), 1, font_2,'center', 'top', false, false, false, true, false)
                dxDrawTextAligned((v.Health or 0) <= 0 and "Dead" or tostring(math.floor((v.Health or 0)+(v.Armor or 0))), hpx, offsety+25*scale,_, _, tocolor(255, 255, 255, 255 * progress), 1, font_2,'center', 'top', false, false, false, true, false)
                offsety = offsety + 25*scale
            end
        end
    end

    if isElement(Round.teams[2]) then
        local team2 = Round.teams[2]
        local score2 = tonumber(getElementData(team2, getRoundMapInfo().modename == 'domination' and 'Points' or 'Score') or 0)
        local defenseName = getTeamName(team2) or "Equipo 2"
        local defenseColor = {getTeamColor(team2)}
        local team2FinalX = screen.x/2 + 30*scale
        local team2InitialX = screen.x + 50*scale
        local team2CurrentX = isHiding and (team2FinalX - (team2FinalX - team2InitialX) * (1-progress)) or (team2InitialX + (team2FinalX - team2InitialX) * progress)

        dxDrawRectangle(team2CurrentX, screen.y/2-rectH/2+rectH/7, rectW, rectH-rectH/7, tocolor(0, 0, 0, 100 * progress))
        dxDrawRectangle(team2CurrentX - 10*scale, screen.y/2-rectH/2, rectW+20*scale, rectH/7, tocolor(defenseColor[1], defenseColor[2], defenseColor[3], 150 * progress))
        dxDrawTextAligned(defenseName:upper(), team2CurrentX + rectW + 10*scale, screen.y/2-rectH/2,_, _, tocolor(defenseColor[1], defenseColor[2], defenseColor[3], 255 * progress),1, 'bankgothic', 'right', 'bottom', false, false, false, true, true)
        dxDrawTextAligned(tostring(score2), team2CurrentX - 10*scale, screen.y/2-rectH/2,_, _, tocolor(defenseColor[1], defenseColor[2], defenseColor[3], 255 * progress),1, 'bankgothic', 'left', 'bottom', false, false, false, true, true)

		if Round.winner ~= 'Draw' then
    	dxDrawTextAligned(Round.winner == defenseName and 'WINNER' or 'LOSER',team2CurrentX + rectW/2, screen.y/2-rectH/2+((rectH/7)/2),_, _, tocolor(255, 255, 255, 255 * progress),math.max(1, math.floor(3*scale)), 'bankgothic', 'center', 'center', false, false, false, true, false)
		else
    	dxDrawTextAligned('TIE', team2CurrentX + rectW/2, screen.y/2-rectH/2+((rectH/7)/2),_, _, tocolor(255, 255, 255, 255 * progress),math.max(1, math.floor(3*scale)), 'bankgothic', 'center', 'center', false, false, false, true, false)
		end
        local offsetx2, offsety2 = team2CurrentX, screen.y/2-rectH/2+rectH/7
        dxDrawTextAligned('Name:', offsetx2+10*scale, offsety2+15*scale,_, _, tocolor(255, 255, 255, 255 * progress), 1, font_2,'left', 'top', false, false, false, true, false)
        dxDrawTextAligned('Damage:', offsetx2+350*scale, offsety2+15*scale,_, _, tocolor(255, 255, 255, 255 * progress), 1, font_2,'right', 'top', false, false, false, true, false)
        dxDrawTextAligned('Kills:', offsetx2+450*scale, offsety2+15*scale,_, _, tocolor(255, 255, 255, 255 * progress), 1, font_2,'right', 'top', false, false, false, true, false)
        dxDrawTextAligned('Health:', offsetx2+560*scale, offsety2+15*scale,_, _, tocolor(255, 255, 255, 255 * progress), 1, font_2,'right', 'top', false, false, false, true, false)

        local dmgx2 = offsetx2+350*scale - dxGetTextWidth('Damage:', 1, font_2)/2
        local killsx2 = offsetx2+450*scale - dxGetTextWidth('Kills:', 1, font_2)/2
        local hpx2 = offsetx2+560*scale - dxGetTextWidth('Health:', 1, font_2)/2
        offsety2 = offsety2 + 25*scale
        
        for k, v in pairs(Round.p or {}) do
            if v.Team == team2 then
                dxDrawTextAligned(removeColorCodes(v.Name or ""), offsetx2+10*scale, offsety2+25*scale,_, _, tocolor(255, 255, 255, 255 * progress), 1, font_2,'left', 'top', false, false, false, true, false)
                dxDrawTextAligned(tostring(v.Damage or 0), dmgx2, offsety2+25*scale,_, _, tocolor(255, 255, 255, 255 * progress), 1, font_2,'center', 'top', false, false, false, true, false)
                dxDrawTextAligned(tostring(v.Kills or 0), killsx2, offsety2+25*scale,_, _, tocolor(255, 255, 255, 255 * progress), 1, font_2,'center', 'top', false, false, false, true, false)
                dxDrawTextAligned((v.Health or 0) <= 0 and "Dead" or tostring(math.floor((v.Health or 0)+(v.Armor or 0))), hpx2, offsety2+25*scale,_, _, tocolor(255, 255, 255, 255 * progress), 1, font_2,'center', 'top', false, false, false, true, false)
                offsety2 = offsety2 + 25*scale
            end
        end
    end

    if progress > 0.3 or not isHiding then
        local mostDamage, damageColor = getMostDamage(Round.p)
        local mostKills, killsColor = getMostKills(Round.p)
        local mostHP, hpColor = getMostHP(Round.p)
        local statsFinalY = screen.y/2+rectH/2+25*scale
        local statsInitialY = screen.y + 100*scale
        local statsCurrentY = isHiding and (statsFinalY + (statsInitialY - statsFinalY) * (1-progress))or (statsInitialY + (statsFinalY - statsInitialY) * progress)
        local offsetx3 = (25*scale)+screen.x/2-((rectW+20*scale)*2)/2
        dxDrawRectangle(offsetx3, statsCurrentY, ((rectW)*2), rectH/6, tocolor(0, 0, 0, 50 * progress))
        
        local function drawStatText(text, x, align)
            dxDrawText(text:gsub('#%x%x%x%x%x%x', ''), x+1, statsCurrentY+(rectH/6)/2+1,_, _, tocolor(0, 0, 0, 255 * progress), 1, font_2, align, 'center', false, false, false, true)
            dxDrawText(text, x, statsCurrentY+(rectH/6)/2,_, _, tocolor(255, 255, 255, 255 * progress), 1, font_2, align, 'center', false, false, false, true) end

        if mostDamage and damageColor then
            drawStatText('Most Damage: '..damageColor..(mostDamage or "N/A"), offsetx3+(((rectW+25*scale)*2)/2), 'center')
        end
        if mostKills and killsColor then
            drawStatText('Most Kills: '..killsColor..(mostKills or "N/A"), offsetx3+50*scale, 'left')
        end
        if mostHP and hpColor then
            drawStatText('Most HP: '..hpColor..(mostHP or "N/A"), offsetx3+(((rectW)*2))-50*scale, 'right')
        end
    end
end
        
function getMostDamage(round)
    if not round then return "N/A", "#FFFFFF" end
    local player, damage, team = nil, -1, nil
    for k, v in pairs(round) do
        if v.Team and isElement(v.Team) and isValidTeam(v.Team) and (v.Damage or 0) > damage then
            damage = v.Damage or 0
            player = v.Name or "N/A"
            team = v.Team
        end
    end
    return player, team and getHexTeamColor(team) or "#FFFFFF"
end

function getMostKills(round)
    if not round then return "N/A", "#FFFFFF" end
    local player, kills, team = nil, -1, nil
    for k, v in pairs(round) do
        if v.Team and isElement(v.Team) and isValidTeam(v.Team) and (v.Kills or 0) > kills then
            kills = v.Kills or 0
            player = v.Name or "N/A"
            team = v.Team
        end
    end
    return player, team and getHexTeamColor(team) or "#FFFFFF" end

function getMostHP(round)
    if not round then return "N/A", "#FFFFFF" end
    local player, hp, team = nil, -1, nil
    for k, v in pairs(round) do
        if v.Team and isElement(v.Team) and isValidTeam(v.Team) then
            local totalHP = (v.Health or 0) + (v.Armor or 0)
            if totalHP > hp then
                hp = totalHP
                player = v.Name or "N/A"
                team = v.Team
            end
        end
    end
    return player, team and getHexTeamColor(team) or "#FFFFFF" end

function isValidTeam(team)
    if not isElement(team) then return false end
    local data = tonumber(getElementData(team, 'Side') or 0)
    return (data == 1) or (data == 2) end

function getHexTeamColor(team)
    if not isElement(team) then return "#FFFFFF" end
    local r, g, b = getTeamColor(team)
    return string.format("#%.2X%.2X%.2X", math.floor(r), math.floor(g), math.floor(b)) end

addEvent('showTopRound', true)
addEventHandler('showTopRound', root, function(show, p, teams, wintext, winner, previous)
    if show then
        Round.show = true
        isHiding = false
        animationStartTime = getTickCount()
        
        if not previous and teams then
            Round.teams = {}
            for k, v in pairs(teams) do
                if isElement(v) then
                    local side = tonumber(getElementData(v, 'Side') or 0)
                    Round.teams[side] = v
                end
            end
            Round.p = p or {}
        end
    else
        isHiding = true
        hideAnimationStartTime = getTickCount()
    end
    Round.winner = winner or "Draw"
    Round.wintext = wintext or ""
end)

function dxDrawShadowText( text, x, y, t, r, color, scale, font, alignx, aligny, ... )
dxDrawText( text:gsub('#%x%x%x%x%x%x', ''), x+1, y+1, _,_, tocolor(0,0,0), scale, font, alignx, aligny, unpack({...})); 
return dxDrawText( text, x, y, _,_, color, scale, font, alignx, aligny, unpack({...})); 
end 
addEvent("onMapStarting", true)
addEventHandler("onMapStarting", root, function(mapInfo)
    if Round.show then
        isHiding = true
        hideAnimationStartTime = getTickCount()
        hideAnimationDuration = 1300
    end
end)
addEventHandler('onClientRender', root, Map.Render)
