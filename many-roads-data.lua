MR = {}
MR.exclude_files = {'many-roads.lua', 'many-roads-data.lua', 'init.lua', 'lib.lua'}
MR.exclude_prefixes = {'pset_', 'data_', 'd_', 'state_'}
MR.tour = true -- scroll script names across the grid; false for the plain view
MR.led_active = 4
MR.led_tour = 15 -- slot whose name is scrolling
MR.led_text = 10
MR.tour_step = 0.08 -- seconds per column of scrolling
MR.hold_time = 0.4 -- seconds a slot is held before release shows its name instead of loading
MR.grid_size_x = grid_size_x()
MR.grid_size = grid_size_x() * grid_size_y()
MR.index_to_coord = function(index)
    local x = ((index - 1) % MR.grid_size_x) + 1
    local y = math.floor((index - 1) / MR.grid_size_x) + 1
    return x, y
end
MR.coord_to_index = function(x, y)
    local i = x + ((y - 1) * (MR.grid_size_x))
    return i
end
MR.exclude_lookup = {}
MR.scripts = {}

MR.has_excluded_prefix = function(filename)
    for _, prefix in ipairs(MR.exclude_prefixes) do
        if filename:sub(1, #prefix) == prefix then
            return true
        end
    end
    return false
end

MR.init = function()
    print("many-roads v1.2.1-og1")

    local exclude_lookup = {}
    for i = 1, #MR.exclude_files do
        exclude_lookup[MR.exclude_files[i]] = true
    end
    for _, i in ipairs(fs_list_files()) do
        if i:match("%.lua$") and not exclude_lookup[i] and not MR.has_excluded_prefix(i) then
            if #MR.scripts <= MR.grid_size then
                table.insert(MR.scripts, i)
            end
        end
    end
    print('-------')
    print('installed iii scripts:')
    for i = 1, #MR.scripts do
        print(i .. ': ' .. MR.scripts[i])
    end
    MR.tour_init()
    MR.draw_sel()
end

MR.draw_sel = function()
    grid_led_all(0)
    for i = 1, #MR.scripts do
        local x, y = MR.index_to_coord(i)
        grid_led(x, y, i == MR.tour_i and MR.led_tour or MR.led_active)
    end
    grid_refresh()
end

-- Tour: light each slot in turn and scroll its name across the rows below the
-- slots, so you can tell what is where without a computer.

-- 3x5 glyphs, one digit per row (top first): 4 = left, 2 = middle, 1 = right
MR.font = {
    a = '25755', b = '65656', c = '34443', d = '65556', e = '74647', f = '74644',
    g = '34553', h = '55755', i = '72227', j = '11152', k = '55655', l = '44447',
    m = '57755', n = '65555', o = '25552', p = '65644', q = '25563', r = '65655',
    s = '34216', t = '72222', u = '55557', v = '55552', w = '55775', x = '55255',
    y = '55222', z = '71247', ['0'] = '75557', ['1'] = '26227', ['2'] = '61247',
    ['3'] = '61216', ['4'] = '55711', ['5'] = '74616', ['6'] = '34757', ['7'] = '71222',
    ['8'] = '75757', ['9'] = '75716', ['-'] = '00700', ['_'] = '00007', ['.'] = '00002'
}

-- Columns of the rendered name, each a 5-bit number (bit 0 = top row)
MR.text_cols = function(name)
    local cols = {}
    for ch in name:lower():gmatch('.') do
        local g = MR.font[ch] or '00000'
        for _, bit in ipairs({4, 2, 1}) do
            local col = 0
            for r = 1, 5 do
                if tonumber(g:sub(r, r)) & bit ~= 0 then
                    col = col | (1 << (r - 1))
                end
            end
            cols[#cols + 1] = col
        end
        cols[#cols + 1] = 0
    end
    return cols
end

MR.tour_init = function()
    if not MR.tour or #MR.scripts < 1 then
        return
    end
    local last_row = math.floor((#MR.scripts - 1) / MR.grid_size_x) + 1
    MR.text_y = grid_size_y() - 4
    if MR.text_y <= last_row then
        MR.text_y = nil -- no room for text: only the highlight moves
    end
    MR.tour_show(1)
    MR.tour_metro = metro.init(MR.tour_tick, MR.tour_step)
    MR.tour_metro:start()
end

MR.tour_show = function(i)
    MR.tour_i = ((i - 1) % #MR.scripts) + 1
    local name = MR.scripts[MR.tour_i]:gsub('%.lua$', '')
    MR.tour_cols = MR.text_cols(name)
    MR.tour_pos = 1 - MR.grid_size_x -- enter from the right edge
    MR.draw_sel()
end

MR.tour_tick = function()
    if not MR then
        return -- a tick queued just before a script was loaded
    end
    MR.tour_pos = MR.tour_pos + 1
    if MR.tour_pos > #MR.tour_cols then
        MR.tour_show(MR.held_i or MR.tour_i + 1) -- a held slot repeats its name
    end
    if not MR.text_y then
        return
    end
    for x = 1, MR.grid_size_x do
        local col = MR.tour_cols[x + MR.tour_pos - 1] or 0
        for r = 0, 4 do
            grid_led(x, MR.text_y + r, (col >> r) & 1 == 1 and MR.led_text or 0)
        end
    end
    grid_refresh()
end

-- A press in the text area steps the tour: left half back, right half forward
MR.tour_key = function(x, y, z)
    if not MR.text_y or y < MR.text_y then
        return false
    end
    if z == 1 then
        MR.tour_show(MR.tour_i + (x <= MR.grid_size_x / 2 and -1 or 1))
    end
    return true
end

-- Holding a slot scrolls its name; a short press loads it on release. Returns
-- the index of the script to load, if any.
MR.slot_key = function(x, y, z)
    local i = MR.coord_to_index(x, y)
    if MR.scripts[i] == nil then
        return nil
    end
    if z == 1 then
        MR.held_i, MR.held_t = i, get_time()
        if MR.tour_metro then
            MR.tour_show(i)
        end
        return nil
    end
    if MR.held_i ~= i then
        return nil
    end
    MR.held_i = nil
    if get_time() - MR.held_t < MR.hold_time then
        return i
    end
    return nil
end

MR.tour_stop = function()
    if MR.tour_metro then
        metro.free(MR.tour_metro.id)
        MR.tour_metro.event = nil
    end
    grid_led_all(0)
    grid_refresh()
end

MR.load_print = function(x, y)
    local i = MR.coord_to_index(x, y)
    print('loading ' .. i .. ': ' .. MR.scripts[i])
end
