if mods.pypostprocessing then return end -- This code already exists in py

local function collision_box(machine)
    local collision_box = machine.selection_box or machine.collision_box
    if not collision_box then return nil end

    local left_top = collision_box[1] or collision_box.left_top
    local right_bottom = collision_box[2] or collision_box.right_bottom
    if not left_top or not right_bottom then return nil end

    local x1, y1 = left_top[1] or left_top.x, left_top[2] or left_top.y
    local x2, y2 = right_bottom[1] or right_bottom.x, right_bottom[2] or right_bottom.y
    if not x1 or not y1 or not x2 or not y2 then return nil end

    return x1, y1, x2, y2
end

local function scale_module_alt_icons(machine, inventory_index)
    local already_has_icons = false
    -- if the machine already has defined some custom icons positioning, remove them and replace with ours
    local new_icons_positioning = {}
    if machine.icons_positioning and type(machine.icons_positioning) == "table" then
        for _, positioning in pairs(machine.icons_positioning) do
            if positioning.inventory_index ~= inventory_index then
                table.insert(new_icons_positioning, positioning)
            else
                already_has_icons = true
            end
        end
    end

    local x1, y1, x2, y2 = collision_box(machine)
    if not x1 then return end
    local width, height = x2 - x1, y2 - y1
    if math.abs(width - height) > 0.5 then
        if already_has_icons then return end -- we skip manually defined rectangular machines
        width, height = math.min(width, height), math.min(width, height)
        if width > height then
            x1, x2 = y1, y2
        else
            y1, y2 = x1, x2
        end
    end
    local area = width * height

    if machine.type == "lab" and area <= 16 then return end

    local module_slots = machine.module_slots
    if not module_slots or module_slots == 0 then return end

    local scale_factors = {1}
    for i = 1, 40 do scale_factors[i + 1] = scale_factors[i] * 0.95 end

    if width > 4 then table.insert(scale_factors, 1, 1.25) end
    if width > 5 then table.insert(scale_factors, 1, 1.5) end
    if width > 12 then table.insert(scale_factors, 1, 2) end
    if width > 22 then table.insert(scale_factors, 1, 2.5) end
    if width > 32 then table.insert(scale_factors, 1, 3) end

    for _, scale in pairs(scale_factors) do
        local module_alt_mode_width = 1.1 * scale     -- width and height of the module icon in tiles

        local area_covered_by_modules = (math.ceil(module_slots ^ 0.5) ^ 2) * (module_alt_mode_width ^ 2)
        if area_covered_by_modules > area * 0.4 then goto too_big end

        local max_icons_per_row = module_slots
        while max_icons_per_row * module_alt_mode_width > width do
            if max_icons_per_row <= 2 then break end
            max_icons_per_row = max_icons_per_row - 1
        end

        local num_module_rows = math.ceil(module_slots / max_icons_per_row)
        if num_module_rows ~= 1 and num_module_rows * module_alt_mode_width > height * 0.325 then goto too_big end

        -- make it as even a square as possible
        while true do
            max_icons_per_row = max_icons_per_row - 1
            local new_rows = math.ceil(module_slots / max_icons_per_row)
            if num_module_rows ~= new_rows then
                max_icons_per_row = max_icons_per_row + 1
                break
            end
        end

        local y = y2 - (num_module_rows * module_alt_mode_width)
        local shift = {0, y}

        if machine.type == "beacon" then shift = {0, 0} end

        table.insert(new_icons_positioning, {inventory_index = inventory_index, shift = shift, scale = scale, max_icons_per_row = max_icons_per_row})
        machine.icons_positioning = new_icons_positioning
        do return end

        ::too_big::
    end
end

for prototype_name, inventory_index in pairs {
    ["mining-drill"] = defines.inventory.mining_drill_modules,
    ["assembling-machine"] = defines.inventory.assembling_machine_modules,
    ["furnace"] = defines.inventory.furnace_modules,
    ["lab"] = defines.inventory.lab_modules,
    ["rocket-silo"] = defines.inventory.rocket_silo_modules,
    ["beacon"] = defines.inventory.beacon_modules,
} do
    for _, machine in pairs(data.raw[prototype_name] or {}) do
        scale_module_alt_icons(machine, inventory_index)
    end
end

if data.raw["assembling-machine"]["electromagnetic-plant"] then
    data.raw["assembling-machine"]["electromagnetic-plant"].icon_draw_specification.scale = 1.8
end

for _, lab in pairs(data.raw.lab) do
    for _, positioning in pairs(lab.icons_positioning or {}) do
        if positioning.inventory_index == defines.inventory.lab_input then
            local scale = 1

            local x1, y1, x2, y2 = collision_box(lab)
            if not x1 then return end
            local width, height = x2 - x1, y2 - y1
            local area = width * height

            local module_alt_mode_width = positioning.separation_multiplier or 1.1 -- width and height of the module icon in tiles
            local scale = math.min(1.5, (width * 0.8) / module_alt_mode_width / positioning.max_icons_per_row)

            positioning.shift = {0, -0.5 * scale}
            positioning.scale = scale
        end
    end
end
