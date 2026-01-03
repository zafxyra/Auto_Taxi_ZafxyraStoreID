function string:split(sep)
    local result = {}
    for part in self:gmatch("([^" .. sep .. "]+)") do
        table.insert(result, part)
    end
    return result
end


-- AUTO TAXI - FINAL SAMP-SAFE VERSION (PROFESSIONAL FIXED)
script_name("AUTO TAXI")
script_author("ZafxyraStoreID")
script_version("STABLE-PRO")

local imgui = require 'mimgui'
local encoding = require 'encoding'
require "lib.moonloader"
require "lib.sampfuncs"
require "lib.samp.events"
local ffi = require("ffi")
local sampev = require 'lib.samp.events'

encoding.default = 'CP1251'
local u8 = encoding.UTF8

local new = imgui.new
local windowState = new.bool(false)

local autoSend = imgui.new.bool(false)
local autoSSRP = imgui.new.bool(false)
local autoP = imgui.new.bool(false)
local pesanInput = imgui.new.char[508]()
local sliderDelay = imgui.new.int(5)
local lastSend = os.clock()

local dutyActive = false
local hasPassenger = false
local lastQueueTime = 0.0
local queueCooldown = 120.0

function isCharDriver(ped)
    local veh = getCarCharIsUsing(ped)
    if veh and doesVehicleExist(veh) then
        return getDriverOfCar(veh) == ped
    end
    return false
end

sampRegisterChatCommand("atx", function()
    windowState[0] = not windowState[0]
end)

imgui.OnFrame(function() return windowState[0] end, function()
    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.1, 0.1, 0.1, 1.0))
    imgui.PushStyleColor(imgui.Col.TitleBg, imgui.ImVec4(0.15, 0.15, 0.15, 1.0))
    imgui.PushStyleColor(imgui.Col.TitleBgActive, imgui.ImVec4(0.2, 0.2, 0.2, 1.0))

    if imgui.Begin(u8"🚕 AUTO TAXI SSRP by Zafxyra (PRO)", windowState, imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoCollapse) then
        if imgui.BeginTabBar("AutoTaxiBar") then
            if imgui.BeginTabItem("AUTO") then
                imgui.Text("Aktifkan auto taxi SSRP")
                imgui.Checkbox("Auto Taxi SSRP", autoSSRP)
                imgui.Checkbox("Auto Jawab Telpon /p", autoP)
                imgui.Checkbox("Kirim pesan terus menerus", autoSend)
                imgui.InputText("Isi Pesan", pesanInput, 508)
                imgui.SliderInt("Delay Kirim (detik)", sliderDelay, 1, 100)
                imgui.EndTabItem()
            end
            if imgui.BeginTabItem("CREDITS") then
                imgui.TextColored(imgui.ImVec4(0.9, 0.2, 0.8, 1), "AUTHOR: ZafxyraStoreID")
                imgui.TextColored(imgui.ImVec4(0.2, 0.8, 1.0, 1), "VERSION: STABLE-PRO")
                imgui.EndTabItem()
            end
            imgui.EndTabBar()
        end
        imgui.End()
    end

    imgui.PopStyleColor(3)
end)

function sampev.onServerMessage(color, msg)
    if autoP[0] and (msg:find("/p") or msg:find("CELLPHONE form")) then
        sampSendChat("/p")
    end

    if autoSSRP[0] and msg:lower():find("taxi call") and msg:lower():find("accept taxi call") then
        lua_thread.create(function()
            wait(100)
            sampSendChat("/taximenu")
        end)
    end
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    if autoSSRP[0] then
        local lowerTitle = title:lower()
        local lowerText = text:lower()

        --[[ DISABLED AUTO ORDER TAXI FEATURE
        -- Cari dan klik opsi bernama "Order Taxi" secara dinamis
        if lowerTitle:find("taxi menu") and lowerText:find("order taxi") then
            lua_thread.create(function()
                wait(500)
                local index = nil
                for i, line in ipairs(text:split("\n")) do
                    if line:lower():gsub("^%s*(.-)%s*$", "%1") == "order taxi" then
                        index = i - 1
                        break
                    end
                end
                if index then
                    sampSendDialogResponse(dialogId, 1, index, "")
                end
            end)
        end

        if lowerTitle:find("order taxi") or lowerText:find("order taxi") then
            lua_thread.create(function()
                wait(500)
                sampSendDialogResponse(dialogId, 1, 0, "")
                wait(500)
                sampSendChat("/taximenu")
            end)
        end
        --]]
    end
end

function main()
    while not isSampAvailable() do wait(100) end
    sampAddChatMessage("[AUTO TAXI SSRP LOADED - PRO VERSION] cmd /atx to open menu", 0xFFFF69B4)

    while true do
        wait(100)
        local status, err = pcall(function()
            local msg = ffi.string(pesanInput)
            if autoSend[0] and os.clock() - lastSend >= sliderDelay[0] then
                if #msg > 0 then
                    sampSendChat(msg)
                    lastSend = os.clock()
                end
            end

            if autoSSRP[0] then
                local inCar = isCharInAnyCar(PLAYER_PED)
                local veh = getCarCharIsUsing(PLAYER_PED)
                local isDriver = isCharDriver(PLAYER_PED)
                if inCar and veh and doesVehicleExist(veh) and isDriver then
                    if not dutyActive then
                        sampSendChat("/taxiduty")
                        dutyActive = true
                    end

                    local rawCount = getNumberOfPassengers(veh)
                    local passengerCount = type(rawCount) == "number" and rawCount or 0
                    if passengerCount > 0 then
                        hasPassenger = true
                    else
                        if hasPassenger and os.clock() - lastQueueTime >= queueCooldown then
                            sampSendChat("/taximenu")
                            lastQueueTime = os.clock()
                            hasPassenger = false
                        end
                    end
                else
                    dutyActive = false
                    hasPassenger = false
                end
            end
        end)

        if not status then
            sampAddChatMessage("[ERROR]: " .. tostring(err), 0xFF0000)
        end
    end
end