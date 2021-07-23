GetPlayerMouseX = {}
GetPlayerMouseY = {}
function InitMouseMoveTrigger()
    local MouseMoveTrigger = CreateTrigger()
    for i = 0, bj_MAX_PLAYER_SLOTS - 1 do
        local player = Player(i)
        TriggerRegisterPlayerEvent(MouseMoveTrigger, player, EVENT_PLAYER_MOUSE_MOVE)
        GetPlayerMouseX[i] = 0
        GetPlayerMouseY[i] = 0
    end
    TriggerAddAction(MouseMoveTrigger, function()
        local id = GetPlayerId(GetTriggerPlayer())
        --print(BlzGetTriggerPlayerMouseX())
        if BlzGetTriggerPlayerMouseX() ~= 0 then
            if BlzGetTriggerPlayerMouseX() >= 511 and BlzGetTriggerPlayerMouseX() <= 513 then
                --print("mouse error")
            else
                GetPlayerMouseX[id] = BlzGetTriggerPlayerMouseX()
                GetPlayerMouseY[id] = BlzGetTriggerPlayerMouseY()
                if HERO[id] then
                    local data=HERO[id]
                    if data.BowReady then
                        local angle=AngleBetweenXY(GetUnitX(data.UnitHero), GetUnitY(data.UnitHero),BlzGetTriggerPlayerMouseX(),BlzGetTriggerPlayerMouseY()) / bj_DEGTORAD
                        SetUnitFacing(data.UnitHero,angle)
                    end
                end
            end

        else
            -- GetPlayerMouseX[id] = GetPlayerMouseX[id]
            -- print("мышь в нуле")
        end

    end)
end