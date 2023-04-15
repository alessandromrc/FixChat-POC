util.require_natives("natives-1672190175-uno")

local draft = nil
local chat_open = false
local mode = 0
local has_pressed_enter = false

NETWORK.NETWORK_OVERRIDE_SEND_RESTRICTIONS_ALL(true)

util.on_stop(function(_)
    NETWORK.NETWORK_OVERRIDE_SEND_RESTRICTIONS_ALL(false)
end)

local function chat_input()
    while true do
        local state = chat.get_state()
        if state == 2 then
            draft = chat.get_draft()
            chat_open = true
            mode = 2
            coroutine.yield()
        elseif state == 1 then
            draft = chat.get_draft()
            chat_open = true
            mode = 1
            coroutine.yield()
        else
            chat_open = false
            coroutine.yield()
        end
        util.yield()
    end
end

local chat_input_co = coroutine.create(chat_input)
coroutine.resume(chat_input_co)

while true do
    if chat_open then
        has_pressed_enter = util.is_key_down(0x0D)
        if has_pressed_enter then
            local pid = players.user()
            for k, iter_pid in pairs(players.list(true, true, true)) do
                if iter_pid ~= pid then
                    if mode == 1 then
                        chat.send_targeted_message(iter_pid, pid, draft, true)
                    else
                        chat.send_targeted_message(iter_pid, pid, draft, false)
                    end
                end
            end
            chat_open = false
        end
    end
    has_pressed_enter = util.is_key_down(0x0D)
    if not chat_open and has_pressed_enter then
        coroutine.resume(chat_input_co)
    end
    util.yield()
end

util.keep_running()
