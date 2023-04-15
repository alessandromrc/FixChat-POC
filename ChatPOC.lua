util.require_natives("natives-1672190175-uno")

local draft = nil
local chat_open = false
local mode = 0
local has_pressed_enter = false
local message_sent = true
local last_enter_press_time = 0
local debounce_interval = 0.5 -- in seconds

menu.slider_float(menu.my_root(),  "Debouncing", {"debounceTime"}, "Lower the debounce time if the messages aren't getting sent and higher it up if you're sending double/triple messages", 0, 100, 50, 10, function(value)
    debounce_interval = value / 100
end)

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
            message_sent = true
            coroutine.yield()
        elseif state == 1 then
            draft = chat.get_draft()
            chat_open = true
            mode = 1
            message_sent = true
            coroutine.yield()
        else
            chat_open = false
            if message_sent == false then
                message_sent = true
            end
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
        local current_time = os.clock()
        if has_pressed_enter and not message_sent and current_time - last_enter_press_time > debounce_interval then
            last_enter_press_time = current_time
            local pid = players.user()
            for k, iter_pid in pairs(players.list(true, true, true)) do
                if iter_pid ~= pid then
                    if mode == 1 then
                        chat.send_targeted_message(iter_pid, pid, draft, true)
                    elseif mode == 2 then
                        chat.send_targeted_message(iter_pid, pid, draft, false)
                    end
                end
            end
            chat_open = false
            message_sent = true
        end
    end
    has_pressed_enter = util.is_key_down(0x0D)
    if not chat_open and has_pressed_enter and message_sent == true then
        coroutine.resume(chat_input_co)
        message_sent = false
    end
    util.yield()
    NETWORK.NETWORK_OVERRIDE_SEND_RESTRICTIONS_ALL(true)
end

util.keep_running()
