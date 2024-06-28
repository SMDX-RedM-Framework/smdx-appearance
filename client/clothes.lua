local SMDXCore = exports['smdx-core']:GetSMDX()
local ClothingCamera = nil
local c_zoom = 2.4
local c_offset = -0.15
local Outfits_tab = {}
local CurrentPrice = 0
local CurentCoords = {}
local playerHeading = nil
local inClothingStore = false
local RoomPrompts = GetRandomIntInRange(0, 0xffffff)
local Divider = "<img style='margin-top: 10px;margin-bottom: 10px; margin-left: -10px;'src='nui://smdx-appearance/img/divider_line.png'>"
local image = "<img style='max-height:250px;max-width:250px;float: center;'src='nui://smdx-appearance/img/%s.png'>"

local clothing = require 'data.clothing'

exports('IsCothingActive', function()
    return inClothingStore
end)

Citizen.CreateThread(function()
    for _,v in pairs(SMDX.SetDoorState) do
        Citizen.InvokeNative(0xD99229FE93B46286, v.door, 1, 1, 0, 0, 0, 0)
        DoorSystemSetDoorState(v.door, v.state)
    end
end)

function GetDescriptionLayout(value, price)
    local desc = image:format(value.img) .. "<br><br>" .. value.desc .. "<br><br>" .. Divider ..
        "<br><span style='font-family:crock; float:left; font-size: 22px;'>" ..
        SMDX.Label.total .. " </span><span style='font-family:crock;float:right; font-size: 22px;'>$" ..
        (price or CurrentPrice) .. "</span><br>" .. Divider
    return desc
end

function OpenClothingMenu()
    MenuData.CloseAll()
    local elements = {}

    for v, k in pairsByKeys(SMDX.MenuElements) do
        elements[#elements + 1] = { label = k.label or v, value = v, category = v, desc = image:format(k.label) .. "<br><br>" .. Divider .. "<br> " .. "clothing options for this category", }
    end
    if not (IsInCharCreation or Skinkosong) then
        local descLayout = GetDescriptionLayout({ img = "menu_icon_tick", desc = 'Confirm purchase' })
        elements[#elements + 1] = { label = SMDX.Label.save or "Save", value = "save", desc = descLayout }
    end
    MenuData.Open('default', GetCurrentResourceName(), 'clothing_store_menu',
        { title = SMDX.Label.clothes, subtext = SMDX.Label.options, align = 'top-left', elements = elements, itemHeight = "4vh"},
        function(data, menu)
            if data.current.value ~= "save" then
                OpenCateogry(data.current.value)
            else
                menu.close()
                destory()
                local alert = lib.alertDialog({
                    header = 'Save Outfit',
                    centered = true,
                    cancel = true
                })
                local ClothesHash = ConvertCacheToHash(ClothesCache)
                if alert == 'confirm' then
                    local input = lib.inputDialog('Save Outfit', {
                        { type = 'input', label = 'Outfit Name', required = true },
                    })
                    if not input then return menu.close() end
                    local outfitname = input[1]
                    if outfitname then
                        TriggerServerEvent("smdx-appearance:server:saveOutfit", ClothesHash, CurrentPrice, outfitname )
                    end
                else
                    TriggerServerEvent("smdx-appearance:server:saveOutfit", ClothesHash, CurrentPrice)
                end
                if next(CurentCoords) == nil then
                    CurentCoords = SMDX.Zones1[1]
                end
                TeleportAndFade(CurentCoords.quitcoords, true)
            end
        end, function(data, menu)
            if (IsInCharCreation or Skinkosong) then
                menu.close()
                FirstMenu()
            else
                menu.close()
                destory()
                if next(CurentCoords) == nil then
                    CurentCoords = SMDX.Zones1[1]
                end
                TeleportAndFade(CurentCoords.quitcoords, true)
                Wait(1000)
                ExecuteCommand('loadskin')
            end
        end)
end

function OpenCateogry(menu_catagory)
    MenuData.CloseAll()
    local elements = {}
    if IsPedMale(PlayerPedId()) then
        local a = 1
        for v, k in pairsByKeys(SMDX.MenuElements[menu_catagory].category) do
            if clothing["male"][k] ~= nil then
                local category = clothing["male"][k]
                if ClothesCache[k] == nil or type(ClothesCache[k]) ~= "table" then
                    ClothesCache[k] = {}
                    ClothesCache[k].model = 0
                    ClothesCache[k].texture = 1
                end
                elements[#elements + 1] = {
                    label = SMDX.Price[k] .. "$ " .. SMDX.Label[k] or v,
                    value = ClothesCache[k].model or 0,
                    category = k,
                    desc = "",
                    type = "slider",
                    min = 0,
                    max = #category,
                    change_type = "model",
                    id = a
                }
                a = a + 1
                elements[#elements + 1] = {
                    label = SMDX.Label.color .. SMDX.Label[k] or v,
                    value = ClothesCache[k].texture or 1,
                    category = k,
                    desc = "",
                    type = "slider",
                    min = 1,
                    max = GetMaxTexturesForModel(k, ClothesCache[k].model or 1, true),
                    change_type = "texture",
                    id = a
                }
                a = a + 1
            end
        end
    else
        local a = 1
        for v, k in pairsByKeys(SMDX.MenuElements[menu_catagory].category) do
            if clothing["female"][k] ~= nil then
                local category = clothing["female"][k]
                if ClothesCache[k] == nil or type(ClothesCache[k]) ~= "table" then
                    ClothesCache[k] = {}
                    ClothesCache[k].model = 0
                    ClothesCache[k].texture = 0
                end
                elements[#elements + 1] = {
                    label = SMDX.Price[k] .. "$ " .. SMDX.Label[k] or v,
                    value = ClothesCache[k].model or 0,
                    category = k,
                    desc = "",
                    type = "slider",
                    min = 0,
                    max = #category,
                    change_type = "model",
                    id = a
                }
                a = a + 1
                elements[#elements + 1] = {
                    label = SMDX.Label.color .. SMDX.Label[k] or v,
                    value = ClothesCache[k].texture or 1,
                    category = k,
                    desc = "",
                    type = "slider",
                    min = 1,
                    max = GetMaxTexturesForModel(k, ClothesCache[k].model or 1, true),
                    change_type = "texture",
                    id = a
                }
                a = a + 1
            end
        end
    end
    MenuData.Open('default', GetCurrentResourceName(), 'clothing_store_menu_category',
        {title = SMDX.Label.clothes, subtext = SMDX.Label.options, align = 'top-left', elements = elements, itemHeight = "4vh"}, function(data, menu)
    end, function(data, menu)
        menu.close()
        OpenClothingMenu()
    end, function(data, menu)
        MenuUpdateClothes(data, menu)
    end)
end

function MenuUpdateClothes(data, menu)
    if data.current.change_type == "model" then
        if ClothesCache[data.current.category].model ~= data.current.value then
            ClothesCache[data.current.category].texture = 1
            ClothesCache[data.current.category].model = data.current.value
            if data.current.value > 0 then
                menu.setElement(data.current.id + 1, "max", GetMaxTexturesForModel(data.current.category, data.current.value, true))
                menu.setElement(data.current.id + 1, "min", 1)
                menu.setElement(data.current.id + 1, "value", 1)
                menu.refresh()
                Change(data.current.value, data.current.category, data.current.change_type)
            else
                if data.current.category == 'cloaks' then
                    data.current.category = 'ponchos'
                end
                Citizen.InvokeNative(0xD710A5007C2AC539, PlayerPedId(), GetHashKey(data.current.category), 0)
                NativeUpdatePedVariation(PlayerPedId())
                if data.current.category == "pants" or data.current.category == "boots" then
                    NativeSetPedComponentEnabledClothes(PlayerPedId(), exports['smdx-appearance']:GetBodyCurrentComponentHash("BODIES_LOWER"), false, true, true)
                end
                if data.current.category == "shirts_full" then
                    NativeSetPedComponentEnabledClothes(PlayerPedId(), exports['smdx-appearance']:GetBodyCurrentComponentHash("BODIES_UPPER"), false, true, true)
                end
                menu.setElement(data.current.id + 1, "max", 0)
                menu.setElement(data.current.id + 1, "min", 0)
                menu.setElement(data.current.id + 1, "value", 0)
                menu.refresh()
            end
            if not (IsInCharCreation or Skinkosong) then
                if CurrentPrice ~= CalculatePrice() then
                    CurrentPrice = CalculatePrice()
                end
            end
        end
    end
    if data.current.change_type == "texture" then
        if ClothesCache[data.current.category].texture ~= data.current.value then
            ClothesCache[data.current.category].texture = data.current.value
            Change(data.current.value, data.current.category, data.current.change_type)
        end
    end
end

function ClothingLight()
    while ClothingCamera do
        Wait(0)

        TogglePrompts({ "TURN_LR", "CAM_UD", "ZOOM_IO" }, true)

        if IsControlPressed(2, SMDXCore.Shared.Keybinds['D']) then
            local heading = GetEntityHeading(PlayerPedId())
            SetEntityHeading(PlayerPedId(), heading + 2)
        end
        if IsControlPressed(2, SMDXCore.Shared.Keybinds['A']) then
            local heading = GetEntityHeading(PlayerPedId())
            SetEntityHeading(PlayerPedId(), heading - 2)
        end
        if IsControlPressed(2, 0x8BDE7443) then
            if c_zoom + 0.25 < 2.5 and c_zoom + 0.25 > 0.7 then
                c_zoom = c_zoom + 0.25
                camera(c_zoom, c_offset)
            end
        end
        if IsControlPressed(2, 0x62800C92) then
            if c_zoom - 0.25 < 2.5 and c_zoom - 0.25 > 0.7 then
                c_zoom = c_zoom - 0.25
                camera(c_zoom, c_offset)
            end
        end
        if IsControlPressed(2, SMDXCore.Shared.Keybinds['W']) then
            if c_offset + 0.5 / 7 < 1.2 and c_offset + 0.5 / 7 > -1.0 then
                c_offset = c_offset + 0.5 / 7
                camera(c_zoom, c_offset)
            end
        end
        if IsControlPressed(2, SMDXCore.Shared.Keybinds['S']) then
            if c_offset - 0.5 / 7 < 1.2 and c_offset - 0.5 / 7 > -1.0 then
                c_offset = c_offset - 0.5 / 7
                camera(c_zoom, c_offset)
            end
        end
    end
end

function Change(id, category, change_type)
    if IsPedMale(PlayerPedId()) then
        if change_type == "model" then
            NativeSetPedComponentEnabledClothes(PlayerPedId(), clothing["male"][category][id][1].hash, false, true, true)
        else
            local hash = clothing["male"][category][ClothesCache[category].model]

            if not hash then return end

            NativeSetPedComponentEnabledClothes(PlayerPedId(), clothing["male"][category][ClothesCache[category].model][id].hash, false, true, true)
        end
    else
        if change_type == "model" then
            NativeSetPedComponentEnabledClothes(PlayerPedId(), clothing["female"][category][id][1].hash, false, true, true)
        else
            local hash = clothing["female"][category][ClothesCache[category].model]

            if not hash then return end

            NativeSetPedComponentEnabledClothes(PlayerPedId(), clothing["female"][category][ClothesCache[category].model][id].hash, false, true, true)
        end
    end
end

RegisterNetEvent('smdx-clothes:ApplyClothes')
AddEventHandler('smdx-clothes:ApplyClothes', function(ClothesComponents, Target)
    Citizen.CreateThread(function()
        local _Target = Target or PlayerPedId()
        if type(ClothesComponents) ~= "table" then
            return
        end
        if next(ClothesComponents) == nil then
            return
        end
        SetEntityAlpha(_Target, 0)
        ClothesCache = ClothesComponents
        for k, v in pairs(ClothesComponents) do
            if v ~= nil and v ~= 0 then
                if type(v) ~= "table" then v = { hash = v} end
                if v.hash and v.hash ~= 0 then
                    NativeSetPedComponentEnabledClothes(_Target, v.hash, false, true, true)
                    if v.palette then
                        NativeSetTextureOutfitTints(_Target,joaat(k),v.palette,v.tint0,v.tint1,v.tint2)
                    end
                else
                    local id = tonumber(v.model)
                    if id >= 1 then
                        if IsPedMale(_Target) then
                            if clothing["male"][k] ~= nil then
                                if clothing["male"][k][tonumber(v.model)] ~= nil then
                                    if clothing["male"][k][tonumber(v.model)][tonumber(v.texture)] ~= nil then
                                        NativeSetPedComponentEnabledClothes(_Target, tonumber(clothing["male"][k][tonumber(v.model)][tonumber(v.texture)].hash), false, true, true)
                                    end
                                end
                            end
                        else
                            if clothing["female"][k] ~= nil then
                                if clothing["female"][k][tonumber(v.model)] ~= nil then
                                    if clothing["female"][k][tonumber(v.model)][tonumber(v.texture)] ~= nil then
                                        NativeSetPedComponentEnabledClothes(_Target, tonumber(clothing["female"][k][tonumber(v.model)][tonumber(v.texture)].hash), false, true, true)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        SetEntityAlpha(_Target, 255)
    end)
end)

function destory()
    OldClothesCache = {}
    SetCamActive(ClothingCamera, false)
    RenderScriptCams(false, true, 500, true, true)
    DisplayHud(true)
    DisplayRadar(true)
    DestroyAllCams(true)
    ClothingCamera = nil
    playerHeading = nil
    Citizen.InvokeNative(0x4D51E59243281D80, PlayerId(), true, 0, false) -- ENABLE PLAYER CONTROLS
end

function TeleportAndFade(coords4, resetCoords)
    DoScreenFadeOut(500)
    Wait(1000)
    Citizen.InvokeNative(0x203BEFFDBE12E96A, PlayerPedId(), coords4)
    SetEntityCoordsNoOffset(PlayerPedId(), coords4, true, true, true)
    inClothingStore = true
    Wait(1500)
    DoScreenFadeIn(1800)
    if resetCoords then
        CurentCoords = {}
        TogglePrompts({ "TURN_LR", "CAM_UD", "ZOOM_IO" }, false)
        inClothingStore = false
        TriggerServerEvent('smdx-appearance:SetPlayerBucket', 0)
    end
end

function camera(zoom, offset)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local zoomOffset = zoom
    local angle

    if playerHeading == nil then
        playerHeading = GetEntityHeading(playerPed)
        angle = playerHeading * math.pi / 180.0
    else
        angle = playerHeading * math.pi / 180.0
    end

    local pos = {
        x = coords.x - (zoomOffset * math.sin(angle)),
        y = coords.y + (zoomOffset * math.cos(angle)),
        z = coords.z + offset
    }
    
    if not ClothingCamera then
        DestroyAllCams(true)
        ClothingCamera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", pos.x, pos.y, pos.z, 300.00, 0.00, 0.00, 50.00, false, 0)

        local pCoords = GetEntityCoords(PlayerPedId())
        PointCamAtCoord(ClothingCamera, pCoords.x, pCoords.y, pCoords.z + offset)

        SetCamActive(ClothingCamera, true)
        RenderScriptCams(true, true, 1000, true, true)
        DisplayRadar(false)
    else
        local ClothingCamera2 = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", pos.x, pos.y, pos.z, 300.00, 0.00, 0.00, 50.00, false, 0)
        SetCamActive(ClothingCamera2, true)
        SetCamActiveWithInterp(ClothingCamera2, ClothingCamera, 750)

        local pCoords = GetEntityCoords(PlayerPedId())
        PointCamAtCoord(ClothingCamera2, pCoords.x, pCoords.y, pCoords.z + offset)

        Wait(150)
        SetCamActive(ClothingCamera, false)
        DestroyCam(ClothingCamera)
        ClothingCamera = ClothingCamera2
    end
end

function Outfits()
    MenuData.CloseAll()
    local Result = lib.callback.await('smdx-clothes:server:getOutfits', false)
    local elements_outfits = {}
    local name
    for k, v in pairs(Result) do
        name = v.name
        elements_outfits[#elements_outfits + 1] = {
            label = '#' .. k .. '. ' .. name,
            value = v.clothes,
            desc = SMDX.Label.choose
        }
    end
    MenuData.Open('default', GetCurrentResourceName(), 'outfits_menu',
        {title = SMDX.Label.clothes, subtext = SMDX.Label.choose, align = 'top-left', elements = elements_outfits, itemHeight = "4vh"},
        function(data, menu)
            OutfitsManage(data.current.value, name)
        end, function(data, menu)
            menu.close()
        end)
end

function OutfitsManage(outfit, id)
    MenuData.CloseAll()
    local elements_outfits_manage = {
        {label = SMDX.Label.wear, value = "SetOutfits", desc = SMDX.Label.wear_desc},
        {label = SMDX.Label.delete, value = "DeleteOutfit", desc = SMDX.Label.delete_desc}
    }
    MenuData.Open('default', GetCurrentResourceName(), 'outfits_menu_manage',
        {title = SMDX.Label.clothes, subtext = SMDX.Label.options, align = 'top-left', elements = elements_outfits_manage, itemHeight = "4vh"}, function(data, menu)
            menu.close()
        if data.current.value == 'SetOutfits' then
            TriggerEvent('smdx-clothes:ApplyClothes', outfit, PlayerPedId())
            local ClothesHash = ConvertCacheToHash(outfit)
            TriggerServerEvent('smdx-clothes:server:saveUseOutfit', ClothesHash)
        end
        if data.current.value == 'DeleteOutfit' then
            return TriggerServerEvent('smdx-clothes:DeleteOutfit', id)
        end
    end, function(data, menu)
        Outfits()
    end)
end

exports('GetClothesComponents', function()
    return {ComponentsClothesMale, ComponentsClothesFemale}
end)

exports('GetClothesCache', function(name)
    return ClothesCache
end)

exports('GetClothesComponentId', function(name)
    return ClothesCache[name]
end)

exports('GetClothesCurrentComponentHash', function(name)
    if ClothesCache[name] == nil then
        return 0
    end
    local hash
    if IsPedMale(PlayerPedId()) then
        if clothing["male"][name] ~= nil then
            hash = clothing["male"][name][hash]
        end
    else
        if clothing["female"][name] ~= nil then
            hash = clothing["female"][name][hash]
        end
    end
    return hash
end)

local Cloakroom = GetRandomIntInRange(0, 0xffffff)

function OpenCloakroom()
    local str = 'Cloak Room'
    CloakPrompt = PromptRegisterBegin()
    PromptSetControlAction(CloakPrompt, SMDX.OpenKey)
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(CloakPrompt, str)
    PromptSetEnabled(CloakPrompt, true)
    PromptSetVisible(CloakPrompt, true)
    PromptSetHoldMode(CloakPrompt, true)
    PromptSetGroup(CloakPrompt, Cloakroom)
    PromptRegisterEnd(CloakPrompt)
end

Citizen.CreateThread(function()
    OpenCloakroom()
    while true do
        Wait(5)
        local sleep = true
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        for k, v in pairs(SMDX.Cloakroom) do
            local dist = #(coords - v)
            if dist < 2.0 then
                sleep = false
                local PromptGroup = CreateVarString(10, 'LITERAL_STRING', SMDX.Cloakroomtext)
                PromptSetActiveGroupThisFrame(Cloakroom, PromptGroup)
                if PromptHasHoldModeCompleted(CloakPrompt) then
                    Outfits()
                    break
                end
            end
        end
        if sleep then
            Wait(1500)
        end
    end
end)

function GenerateMenu()
    TriggerEvent('smdx-horses:client:FleeHorse')
    Wait(0)
    TeleportAndFade(CurentCoords.fittingcoords, false)
    local ClothesComponents = lib.callback.await('smdx-clothes:LoadClothes', false)
    ClothesCache = ClothesComponents
    if IsPedMale(PlayerPedId()) then
        for k,v in pairs(clothing["male"]) do
            if ClothesCache[k] == nil then
                ClothesCache[k] = {}
                ClothesCache[k].model = 0
                ClothesCache[k].texture = 0
            end
        end
    else
        for k,v in pairs(clothing["female"]) do
            if ClothesCache[k] == nil then
                ClothesCache[k] = {}
                ClothesCache[k].model = 0
                ClothesCache[k].texture = 0
            end
        end
    end
    OldClothesCache = deepcopy(ClothesCache)
    camera(2.4, -0.15)
    CreateThread(ClothingLight)
    OpenClothingMenu()
end

Citizen.CreateThread(function()
    CreateBlips()
    if RegisterPrompts() then
        local room = false

        while true do
            room = GetClosestConsumer()

            if room then
                if not PromptsEnabled then TogglePrompts({ "OPEN_CLOTHING_MENU" }, true) end
                if PromptsEnabled then
                    if IsPromptCompleted("OPEN_CLOTHING_MENU") then
                        Citizen.InvokeNative(0x4D51E59243281D80, PlayerId(), false, 0, true) -- ENABLE PLAYER CONTROLS
                        GenerateMenu()
                    end
                end
            else
                if PromptsEnabled then TogglePrompts({ "OPEN_CLOTHING_MENU" }, false) end
                Citizen.Wait(250)
            end
            Citizen.Wait(100)
        end
    end
end)

local playerCoords = nil
GetClosestConsumer = function()
    playerCoords = GetEntityCoords(PlayerPedId())

    for _,data in pairs(SMDX.Zones1) do
        if (data.promtcoords and #(playerCoords - data.promtcoords) < 1.0) or (data.epromtcoords and #(playerCoords - data.epromtcoords) < 1.0) then
            CurentCoords = data
            -- CreateModelBook(data.promtcoords)
            return true
        end
    end
    return false
end

-- function CreateModelBook(dcoords)
--     local model = "mp001_s_mp_catalogue01x_store"
--     RequestModel(model)

--     while not HasModelLoaded(model) do
--         Wait(1)
--     end

--     local catalog = CreateObjectNoOffset(joaat(model), dcoords, false, false, false)
--     SetModelAsNoLongerNeeded(model)
--     SetEntityHeading(catalog, dcoords.w)
--     FreezeEntityPosition(catalog, true)
-- end

-- function SetupScene(dcoords)
--     RequestModel("mp001_s_mp_catalogue01x_store")

--     while not HasModelLoaded("mp001_s_mp_catalogue01x_store") do
--         Wait(1)
--     end

--     local catalog = CreateObjectNoOffset(joaat("mp001_s_mp_catalogue01x_store"), dcoords, false, false, false)
--     SetModelAsNoLongerNeeded("mp001_s_mp_catalogue01x_store")
--     SetEntityHeading(catalog, dcoords.w)
--     FreezeEntityPosition(catalog, true)

--     ClearPedTasksImmediately(PlayerPedId())

--     local animscene = Citizen.InvokeNative(0x1FCA98E33C1437B3, "script@ambient@shop@CATALOG_PLAYER", 0, "PBL_ENTER",
--         false, true)
--     SetAnimSceneEntity(animscene, "player", PlayerPedId(), 0)
--     SetAnimSceneEntity(animscene, "CATALOG", catalog, 0)

--     LoadAnimScene(animscene)

--     while not Citizen.InvokeNative(0x477122B8D05E7968, animscene, 1, 0) do Citizen.Wait(10) end                                                                          --// _IS_ANIM_SCENE_LOADED

--     Citizen.InvokeNative(0x020894BF17A02EF2, animscene, GetEntityCoords(catalog).x, GetEntityCoords(catalog).y, GetEntityCoords(catalog).z - 1, GetEntityRotation(catalog), 2)                                                                                                   -- SET ANIM SCENE ORIGIN

--     StartAnimScene(animscene)

--     Wait(10000)

--     Citizen.InvokeNative(0x84EEDB2C6E650000, animscene)

--     animscene = Citizen.InvokeNative(0x1FCA98E33C1437B3, "script@ambient@shop@CATALOG_PLAYER", 0, "PBL_EXIT_INDEX", false, true)
--     SetAnimSceneEntity(animscene, "player", PlayerPedId(), 0)
--     SetAnimSceneEntity(animscene, "CATALOG", catalog, 0)

--     LoadAnimScene(animscene)

--     while not Citizen.InvokeNative(0x477122B8D05E7968, animscene, 1, 0) do Citizen.Wait(10) end                                                                          --// _IS_ANIM_SCENE_LOADED

--     Citizen.InvokeNative(0x020894BF17A02EF2, animscene, GetEntityCoords(catalog).x, GetEntityCoords(catalog).y, GetEntityCoords(catalog).z - 1, GetEntityRotation(catalog), 2)                                                                                                   -- SET ANIM SCENE ORIGIN

--     StartAnimScene(animscene)

--     Wait(10000)

--     GenerateMenu()
-- end

RegisterPrompts = function()
    local newTable = {}

    for i=1, #SMDX.Prompts do
        local prompt = Citizen.InvokeNative(0x04F97DE45A519419, Citizen.ResultAsInteger())
        Citizen.InvokeNative(0x5DD02A8318420DD7, prompt, CreateVarString(10, "LITERAL_STRING", SMDX.Prompts[i].label))
        Citizen.InvokeNative(0xB5352B7494A08258, prompt, SMDX.Prompts[i].control or SMDXCore.Shared.Keybinds[SMDX.Keybind])
        
        if SMDX.Prompts[i].control2  then
            Citizen.InvokeNative(0xB5352B7494A08258, prompt, SMDX.Prompts[i].control2)
        end

        Citizen.InvokeNative(0x94073D5CA3F16B7B, prompt, SMDX.Prompts[i].time or 1000)

        if SMDX.Prompts[i].control  then
            Citizen.InvokeNative(0x2F11D3A254169EA4, prompt, RoomPrompts)
        end

        Citizen.InvokeNative(0xF7AA2696A22AD8B9, prompt)
        Citizen.InvokeNative(0x8A0FB4D03A630D21, prompt, false)
        Citizen.InvokeNative(0x71215ACCFDE075EE, prompt, false)

        table.insert(SMDX.CreatedEntries, { type = "PROMPT", handle = prompt })
        newTable[SMDX.Prompts[i].id] = prompt
    end

    SMDX.Prompts = newTable
    return true
end

TogglePrompts = function(data, state)
    for index,prompt in pairs((data ~= "ALL" and data) or SMDX.Prompts) do
        if SMDX.Prompts[(data ~= "ALL" and prompt) or index] then
            Citizen.InvokeNative(0x8A0FB4D03A630D21, (data ~= "ALL" and SMDX.Prompts[prompt]) or prompt, state)
            Citizen.InvokeNative(0x71215ACCFDE075EE, (data ~= "ALL" and SMDX.Prompts[prompt]) or prompt, state)
        end
    end
    local label  = CreateVarString(10, 'LITERAL_STRING', SMDX.Label.shop.. ' - ~t6~'..CurrentPrice..'$')
    PromptSetActiveGroupThisFrame(RoomPrompts, label)
    PromptsEnabled = state
end

IsPromptCompleted = function(name)
    if SMDX.Prompts[name] then
        return Citizen.InvokeNative(0xE0F65F0640EF0617, SMDX.Prompts[name])
    end 
    return false
end

-- blips
CreateBlips = function()
    for _, coordsList in pairs(SMDX.Zones1) do
        if #coordsList.blipcoords > 0 and coordsList.showblip then
            local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, coordsList.blipcoords)
            SetBlipSprite(blip, SMDX.BlipSprite, 1)
            SetBlipScale(blip, SMDX.BlipScale)
            Citizen.InvokeNative(0x9CB1A1623062F402, blip, SMDX.BlipName)
            
            table.insert(SMDX.CreatedEntries, { type = "BLIP", handle = blip })
        end
    end
    for _, v in pairs(SMDX.Cloakroom) do
        local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, v)
        SetBlipSprite(blip, SMDX.BlipSpriteCloakRoom, 1)
        SetBlipScale(blip, SMDX.BlipScale)
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, SMDX.BlipNameCloakRoom)

        table.insert(SMDX.CreatedEntries, { type = "BLIP", handle = blip })
    end
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    destory()
    for i=1, #SMDX.CreatedEntries do
        if SMDX.CreatedEntries[i].type == "BLIP" then
            RemoveBlip(SMDX.CreatedEntries[i].handle)
        elseif SMDX.CreatedEntries[i].type == "PROMPT" then
            Citizen.InvokeNative(0x00EDE88D4D13CF59, SMDX.CreatedEntries[i].handle)
            PromptsEnabled = false
        end
    end
end)