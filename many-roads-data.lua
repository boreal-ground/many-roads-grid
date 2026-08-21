MR = {}
MR.exclude_files = {'many-roads.lua', 'many-roads-data.lua', 'init.lua', 'lib.lua'}
MR.exclude_prefixes = {'pset_', 'data_', 'd_', 'state_'}
MR.led_active = 4
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
    print("many-roads v1.2")

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
    MR.draw_sel();

end

MR.draw_sel = function()
    grid_led_all(0)
    for i = 1, #MR.scripts do
        local x, y = MR.index_to_coord(i)
        grid_led(x, y, MR.led_active)
    end
    grid_refresh()
end

MR.load_print = function(x, y)
    local i = MR.coord_to_index(x, y)
    print('loading ' .. i .. ': ' .. MR.scripts[i])
end

MR.is_valid = function(x,y,z)
    if z ~= 1 then return false end
    if #MR.scripts < 1 then return false end
    local index = MR.coord_to_index(x,y)
    if MR.scripts[index] ~= nil then return true end
    return false
end
