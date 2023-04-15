local draft = nil
local last_draft = nil
local chat_open = false
local mode = 0
local has_pressed_enter = false

local send_chat_message = memory.scan("48 8D 15 ? ? ? ? 48 8D 4E 20 E8 ? ? ? ?")
assert(send_chat_message ~= 0)

if memory.read_ubyte(send_chat_message + 0x3D) == 0x74 then
    memory.write_ubyte(send_chat_message + 0x3D, 0x75) -- triggers exceptions but won't waste time on finding a better place
end

util.on_stop(function(_)
    memory.write_ubyte(send_chat_message + 0x3D, 0x74)
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
            last_draft = draft
            util.toast(draft)
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
