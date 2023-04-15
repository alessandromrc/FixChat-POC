local draft = nil
local last_draft = nil
local chat_open = false
local mode = 0;
local has_pressed_enter = false;

local send_chat_message = memory.scan("40 53 48 83 EC ? 48 8B D9 E8 ? ? ? ? 33 D2 85 C0 78 ? 48 98 48 8B 8C C3 90 23 00 00 EB ? 48 8B CA 48 85 C9 0F 95 C0?")
assert(send_chat_message ~= 0)

if memory.read_byte(send_chat_message + 0x12) == 0x78 then
  memory.write_byte(send_chat_message + 0x12, 0x74)
end

util.on_stop(function(_)
  memory.write_byte(send_chat_message + 0x12, 0x78)
end)


while true do

    -- Wait for chat to open
    while not chat_open do
        local state = chat.get_state()

        if state == 2 then
            draft = chat.get_draft()
            chat_open = true
            mode = 2
        end

        if state == 1 then
            draft = chat.get_draft()
            chat_open = true
            mode = 1
        end

        has_pressed_enter = util.is_key_down(0x0D)

        util.yield(100)
    end

    -- Wait for chat to close
    while chat_open do
        local state = chat.get_state()

        if state == 2 or state == 1 then
            draft = chat.get_draft()
        elseif state == 0 then
            if has_pressed_enter then
                last_draft = draft
                util.toast(draft)
                chat.send_message(draft, 0, 0, 1)
                local pid = players.user()
                for k,iter_pid in pairs(players.list(true, true, true)) do
                    if iter_pid ~= pid then
                        if mode == 1 then
                        chat.send_targeted_message(iter_pid, pid, draft, true)
                        else
                          chat.send_targeted_message(iter_pid, pid, draft, false)
                        end
                    end
                end
            end
            chat_open = false
        end

        has_pressed_enter = util.is_key_down(0x0D)

        util.yield(100)
    end
end

util.keep_running()
