meta.name = "AI Visualizer"
meta.version = "0.0.0"
meta.description = "Adds an overlay showing entity AI ranges and targeting information."
meta.author = "Cosine"

local ai_common = require("ai/common")
Entity_AI = require("ai/entity_ai")
geometry = require("geometry")
local drawing = require("drawing")
LABEL_POSITION = drawing.Draw_Item.LABEL_POSITION
local persistence = require("persistence")

local ENTITY_AI_MODULES = {
    "ammit",
    "anubis",
    "anubis_2",
    "axolotl",
    "bat",
    "bee",
    "beg",
    "bodyguard",
    "butterfly",
    "cat_mummy",
    "caveman",
    "celestial_jelly",
    "crab",
    "crocman",
    "drone",
    "egg_sac",
    "eggplant_king",
    "firefly",
    "fish",
    "flying_fish",
    "frog",
    "ghist_shopkeeper",
    "ghost",
    "giant_spider",
    "golden_monkey",
    "goliath_frog",
    "great_humphead",
    "grub",
    "hang_spider",
    "hermit_crab",
    "hired_hand",
    "horned_lizard",
    "hundun",
    "imp",
    "jiangshi",
    "jiangshi_assassin",
    "jungle_sister",
    "kingu",
    "lahamu",
    "lamassu",
    "lavamander",
    "leprechaun",
    "locust",
    "madame_tusk",
    "mech",
    "mole",
    "monkey",
    "mosquito",
    "mummy",
    "necromancer",
    "octopy",
    "olmec",
    "olmite",
    "osiris",
    "pangxie",
    "quillback",
    "robot",
    "rock_dog",
    "scarab",
    "scorpion",
    "shopkeeper",
    "shopkeeper_clone",
    "shopkeeper_generator",
    "skeleton",
    "sorceress",
    "spark_trap",
    "sparrow",
    "spider",
    "sun_challenge_generator",
    "tadpole",
    "tiamat",
    "tiki_man",
    "tun",
    "turkey",
    "ufo",
    "vampire",
    "van_horsing",
    "waddler",
    "witch_doctor",
    "yang",
    "yeti_king",
    "yeti_queen"
}

INDENT = 5

ENT_TYPE_ID_TO_KEY_MAP = {}
for key, id in pairs(ENT_TYPE) do
    ENT_TYPE_ID_TO_KEY_MAP[id] = key
end

local ORIGIN_CHECK_COLOR = drawing.Draw_Color:new({
    Color:new(0.5, 1, 1, 1),
    Color:new(0.5, 0.75, 1, 1),
    Color:new(0.5, 1, 0.75, 1),
    Color:new(0.375, 1, 1, 1)
})
local HITBOX_OVERLAP_COLOR = drawing.Draw_Color:new({
    Color:new(0.25, 0.5, 1, 1),
    Color:new(0.25, 0.25, 1, 1)
})
local HURTBOX_COLOR = drawing.Draw_Color:new({
    Color:new(1, 0.5, 0.5, 1),
    Color:new(0.875, 0.625, 0.5, 1)
})
local SOLID_CHECK_COLOR = drawing.Draw_Color:new({
    Color:new(1, 0, 0.5, 1)
})
local MISC_BOX_COLOR = drawing.Draw_Color:new({
    Color:new(1, 0.875, 0.25, 1),
    Color:new(0.875, 1, 0.25, 1)
})
local TARGET_COLOR = drawing.Draw_Color:new({
    Color:new(1, 0.5, 0, 1)
})

local default_options = {
    options_window_visible = false,
    player_origin_visible = true,
    entity_ranges_visible = true,
    entity_target_visible = true
    -- entity_ai will be populated while loading entity AIs.
}

---List of entity AIs. Contents should be initialized while loading the script.
---@type Entity_AI[]
local entity_ai_list
---Map of entity AIs with entity type IDs as keys. Generated based on entity_ai_list.
---@type { [ENT_TYPE]: Entity_AI }
local entity_ai_by_ent_type
-- List of all entity types covered by entity AIs. Generated based on entity_ai_by_ent_type.
local entity_ai_ent_type_list

-- Map of tracked entity IDs and their stored data.
local tracked_ents

-- Builds precomputed data structures and prepares options for the entity AIs. This needs to be called before trying to process any entities.
local function init_entity_ai()
    entity_ai_list = {}
    for _, module_name in ipairs(ENTITY_AI_MODULES) do
        local full_module_name = "ai/"..module_name
        -- Load the module with error handling to identify it if it fails to load. The error that gets thrown by default is unhelpful.
        local success, module = pcall(function() return require(full_module_name) end)
        if success then
            if module[1] then
                -- The module contains a list of entity AIs.
                for _, module_entity_ai in ipairs(module) do
                    table.insert(entity_ai_list, module_entity_ai)
                end
            else
                -- The module contains a single entity AI.
                table.insert(entity_ai_list, module)
            end
        else
            print("Warning: Failed to load entity AI module \""..full_module_name.."\": "..module)
        end
    end

    entity_ai_by_ent_type = {}
    default_options.entity_ai = {}
    for _, entity_ai in ipairs(entity_ai_list) do
        local ent_types
        if type(entity_ai.ent_type) == "number" then
            ent_types = { entity_ai.ent_type }
        elseif type(entity_ai.ent_type) == "table" then
            ent_types = entity_ai.ent_type --[[@as table]]
        else
            ent_types = {}
        end
        for _, ent_type in ipairs(ent_types) do
            entity_ai_by_ent_type[ent_type] = entity_ai
        end
        local entity_ai_options = {
            visible = true
        }
        default_options.entity_ai[entity_ai.id] = entity_ai_options
        if entity_ai.targeting then
            entity_ai_options.target_visible = true
        end
        if entity_ai.ranges then
            entity_ai_options.ranges = {}
            for _, range in ipairs(entity_ai.ranges) do
                entity_ai_options.ranges[range.id] = {
                    visible = true
                }
            end
        end
    end

    entity_ai_ent_type_list = {}
    for ent_type, _ in pairs(entity_ai_by_ent_type) do
        table.insert(entity_ai_ent_type_list, ent_type)
    end
end

local function get_entity_ai(ent)
    if not ent then
        return nil
    end
    local entity_ai = entity_ai_by_ent_type[ent.type.id]
    if entity_ai == nil then
        -- TODO: This shouldn't happen, but I keep finding edge cases that cause it.
        print("Warning: entity_ai is nil for id="..ent.uid.." type="..ENT_TYPE_ID_TO_KEY_MAP[ent.type.id])
        tracked_ents[ent.uid] = nil
    end
    return entity_ai
end

local function add_tracked_entity(ent)
    tracked_ents[ent.uid] = {}
end

local function should_process_entities(screen)
    return screen == SCREEN.CAMP or screen == SCREEN.LEVEL or screen == SCREEN.DEATH
end

local function clip_line_of_sight(process_ctx, shape, max_checks, extra_length)
    local facing_mult = process_ctx.is_facing_left and -1 or 1
    local check_count = 1
    while true do
        if ai_common.is_point_solid_grid_entity_or_active_floor(
            process_ctx.ent_x + (facing_mult * check_count), process_ctx.ent_y, process_ctx.ent_layer)
        then
            break
        elseif check_count >= max_checks then
            return
        else
            check_count = check_count + 1
        end
    end
    local clip_offset = check_count - 1 + extra_length
    if process_ctx.is_facing_left then
        shape:clip_left(process_ctx.ent_x - clip_offset)
    else
        shape:clip_right(process_ctx.ent_x + clip_offset)
    end
end

local function process_tracked_entity(id)
    local ent = get_entity(id)

    if not ent then
        -- This entity no longer exists.
        tracked_ents[id] = nil
        return
    end

    local tracked_ent_data = {
        draw_items = {}
    }
    tracked_ents[id] = tracked_ent_data

    local entity_ai = get_entity_ai(ent)
    if not entity_ai or entity_ai.is_dead(ent) then
        return
    end

    local entity_ai_options = options.entity_ai[entity_ai.id]
    if not entity_ai_options.visible then
        return
    end

    local ranges_visible = false
    if entity_ai.ranges and options.entity_ranges_visible then
        for _, range_options in pairs(entity_ai_options.ranges) do
            if range_options.visible then
                ranges_visible = true
                break
            end
        end
    end
    local targeting_visible = entity_ai.targeting and options.entity_target_visible and entity_ai_options.target_visible
    if not ranges_visible and not targeting_visible then
        return
    end

    local ent_x, ent_y, ent_layer = get_position(ent.uid)

    -- This processing context has a lifespan of one entity processing event, and is passed into every Entity_AI function. The entity is also passed into every function as its own parameter for convenience due to how frequently it is used.
    local process_ctx = {
        ent = ent,
        ent_x = ent_x,
        ent_y = ent_y,
        ent_layer = ent_layer
    }

    if ranges_visible then
        if entity_ai.preprocess then
            entity_ai.preprocess(ent, process_ctx)
        end

        process_ctx.is_facing_left = test_flag(ent.flags, ENT_FLAG.FACING_LEFT)
        -- TODO: The "stuck in something" flag is currently missing from ENT_MORE_FLAG.
        local is_stuck = test_flag(ent.more_flags, 8)
        -- TODO: Is state, stun_timer, or stun_state responsible for this?
        local is_stunned = ent.state == CHAR_STATE.STUNNED
        local is_frozen = ent.frozen_timer and ent.frozen_timer > 0

        for i, range in ipairs(entity_ai.ranges) do
            if not entity_ai_options.ranges[range.id].visible or (range.is_visible and not range.is_visible(ent, process_ctx)) then
                goto skip_range
            end

            local layer
            if range.layer then
                if type(range.layer) == "function" then
                    layer = range.layer(ent, process_ctx)
                else
                    layer = range.layer
                end
            else
                layer = ent_layer
            end
            if layer ~= LAYER.BOTH and layer ~= state.camera_layer then
                goto skip_range
            end

            local shapes = {}
            if range.shape then
                if type(range.shape) == "function" then
                    table.insert(shapes, range.shape(ent, process_ctx))
                else
                    table.insert(shapes, range.shape:clone())
                end
            end
            if range.shapes then
                for _, shape in ipairs(range.shapes) do
                    if type(shape) == "function" then
                        table.insert(shapes, shape(ent, process_ctx))
                    else
                        table.insert(shapes, shape:clone())
                    end
                end
            end

            local draw_color = ORIGIN_CHECK_COLOR
            if range.type == Entity_AI.RANGE_TYPE.MISC then
                draw_color = MISC_BOX_COLOR
            elseif range.type == Entity_AI.RANGE_TYPE.HITBOX_OVERLAP then
                -- TODO: Make it more obvious that this is a hitbox overlap check. It's difficult to understand with just a color.
                draw_color = HITBOX_OVERLAP_COLOR
            elseif range.type == Entity_AI.RANGE_TYPE.HURTBOX then
                -- TODO: Make it more obvious that this is a hitbox overlap check. It's difficult to understand with just a color.
                draw_color = HURTBOX_COLOR
            elseif range.type == Entity_AI.RANGE_TYPE.SOLID_CHECK then
                draw_color = SOLID_CHECK_COLOR
            end

            local is_inactive_when_stuck = range.is_inactive_when_stuck == nil or range.is_inactive_when_stuck
            local is_active = not is_stunned and not is_frozen
                and not (is_inactive_when_stuck and is_stuck)
                and (not range.is_active or range.is_active(ent, process_ctx))

            local ucolors = is_active and draw_color:get_variant(i).bright or draw_color:get_variant(i).dim

            local label = range.label
            if type(label) == "function" then
                label = label(ent, process_ctx)
            end
            if label == nil then
                label = range.name
            elseif label ~= false and type(label) ~= "string" then
                label = tostring(label)
            end
            local label_position = range.label_position

            local x, y
            if range.translate_shape then
                x, y = range.translate_shape(ent, process_ctx)
            end
            if not x or not y then
                x, y = ent_x, ent_y
            end

            for _, shape in ipairs(shapes) do
                if range.flip_with_ent and process_ctx.is_facing_left then
                    shape:flip_horizontal()
                    label_position = drawing.Draw_Item.flip_label_position_horizontal(label_position)
                end
                shape:translate(x, y)

                if range.flip_with_ent and range.line_of_sight_checks then
                    clip_line_of_sight(process_ctx, shape, range.line_of_sight_checks, range.line_of_sight_extra_length or 0.5)
                end

                if range.post_transform_shape then
                    shape = range.post_transform_shape(ent, process_ctx, shape)
                end

                table.insert(tracked_ent_data.draw_items, drawing.Draw_Item:new({
                    shape = shape,
                    ucolors = ucolors,
                    label = label,
                    label_position = label_position
                }))
            end

            ::skip_range::
        end
    end

    -- TODO: Dim the targeting when the entity is in a state where target doesn't matter, similar to dimming ranges. Maybe dim when entity cannot update targeting timer or find new targets.
    -- TODO: Put the timer somewhere on the entity if it has no target (target was destroyed or changed layer), but it's still seeking a new target.
    -- TODO: Indicate the direction of the targeting for when both the entity and target are off-screen.
    if targeting_visible then
        local target = get_entity(ai_common.get_field(ent, entity_ai.targeting.id_field))
        if target then
            local timer_value = ai_common.get_field(ent, entity_ai.targeting.timer_field)
            local timer
            if timer_value then
                timer = { value = timer_value, max_value = entity_ai.targeting.timer_max }
            end
            local target_x, target_y = get_position(target.uid)
            -- TODO: Don't show targeting when both entities are not on the camera layer.
            -- TODO: Handle targeting between both layers.
            table.insert(tracked_ent_data.draw_items, drawing.Draw_Item:new({
                shape = geometry.create_line_shape(Vec2:new(ent_x, ent_y), Vec2:new(target_x, target_y)),
                ucolors = TARGET_COLOR:get().bright,
                label = "Target",
                timer = timer
            }))
        end
    end
end

local function clear_tracked_entities()
    tracked_ents = {}
end

local function refresh_tracked_entities()
    clear_tracked_entities()
    if should_process_entities(state.screen) then
        for _, ent_id in ipairs(get_entities_by_type(entity_ai_ent_type_list)) do
            add_tracked_entity(get_entity(ent_id))
        end
    end
end

local function draw_indented_text(ctx, text)
    ctx:win_indent(INDENT)
    ctx:win_text(text)
    ctx:win_indent(-INDENT)
end

local function draw_options(ctx, is_window)
    if not is_window then
        if ctx:win_button("Detach options into window") then
            options.options_window_visible = true
        end
    end
    if ctx:win_button("Refresh visualizations") then
        refresh_tracked_entities()
    end
    draw_indented_text(ctx, "Regenerate all visualization data. This may fix frozen or missing visualizations.")

    options.player_origin_visible = ctx:win_check("Show player origin point", options.player_origin_visible)

    ctx:win_separator()

    ctx:win_section("Entity AI Visualizations", function()
        ctx:win_indent(INDENT)

        options.entity_target_visible = ctx:win_check("Targeting visible", options.entity_target_visible)
        draw_indented_text(ctx, "Global toggle for entity targeting visualizations.")

        options.entity_ranges_visible = ctx:win_check("Ranges visible", options.entity_ranges_visible)
        draw_indented_text(ctx, "Global toggle for entity range visualizations.")

        ctx:win_pushid("entities")
        ctx:win_text("Entities:")
        ctx:win_indent(INDENT)
        if ctx:win_button("Check all") then
            for id, _ in pairs(options.entity_ai) do
                options.entity_ai[id].visible = true
            end
        end
        ctx:win_inline()
        if ctx:win_button("Uncheck all") then
            for id, _ in pairs(options.entity_ai) do
                options.entity_ai[id].visible = false
            end
        end
        for _, entity_ai in ipairs(entity_ai_list) do
            local entity_ai_options = options.entity_ai[entity_ai.id]
            ctx:win_pushid(entity_ai.id)
            entity_ai_options.visible = ctx:win_check("##visible", entity_ai_options.visible)
            ctx:win_inline()
            ctx:win_section(entity_ai.name.."###section", function()
                ctx:win_indent(INDENT)
                if entity_ai.targeting then
                    entity_ai_options.target_visible = ctx:win_check("Targeting visible", entity_ai_options.target_visible)
                end
                if entity_ai.ranges and #entity_ai.ranges > 0 then
                    ctx:win_pushid("ranges")
                    ctx:win_text("Ranges visible:")
                    ctx:win_indent(INDENT)
                    if #entity_ai.ranges > 1 then
                        if ctx:win_button("Check all") then
                            for _, range in ipairs(entity_ai.ranges) do
                                entity_ai_options.ranges[range.id].visible = true
                            end
                        end
                        ctx:win_inline()
                        if ctx:win_button("Uncheck all") then
                            for _, range in ipairs(entity_ai.ranges) do
                                entity_ai_options.ranges[range.id].visible = false
                            end
                        end
                    end
                    for _, range in ipairs(entity_ai.ranges) do
                        local range_options = entity_ai_options.ranges[range.id]
                        ctx:win_pushid(range.id)
                        range_options.visible = ctx:win_check(range.name.."###visible", range_options.visible)
                        ctx:win_popid()
                    end
                    ctx:win_indent(-INDENT)
                    ctx:win_popid()
                end
                ctx:win_indent(-INDENT)
            end)
            ctx:win_popid()
        end
        ctx:win_indent(-INDENT)
        ctx:win_popid()

        ctx:win_indent(-INDENT)
    end)

    ctx:win_separator()

    if ctx:win_button("Save options") then
        if not save_script() then
            print("Save occurred too recently. Wait a few seconds and try again.")
        end
    end
    draw_indented_text(ctx, "Immediately save the current options. Saves also happen automatically during screen changes.")

    if ctx:win_button("Reset options") then
        options = persistence.deep_copy(default_options)
    end
    draw_indented_text(ctx, "Reset all options to their default values.")
end

local function on_draw_gui(ctx)
    ctx:draw_layer(DRAW_LAYER.BACKGROUND)
    if should_process_entities(state.screen) then
        drawing.compute_screen_vars()
        for _, tracked_ent_data in pairs(tracked_ents) do
            if tracked_ent_data.draw_items then
                for _, draw_item in ipairs(tracked_ent_data.draw_items) do
                    draw_item:draw(ctx)
                end
            end
        end
        if options.player_origin_visible then
            for _, player in ipairs(players) do
                local x, y, layer = get_position(player.uid)
                if layer == state.camera_layer then
                    drawing.draw_point_mark(ctx, x, y)
                end
            end
        end
    end

    ctx:draw_layer(DRAW_LAYER.WINDOW)
    if options.options_window_visible then
        options.options_window_visible = ctx:window(meta.name.." Options", -1.0, 0.74, 0.35, 0.85, true, function()
            ctx:win_indent(INDENT)
            draw_options(ctx, true)
            ctx:win_indent(-INDENT)
        end)
    end
end

local function on_post_game_loop()
    if should_process_entities(state.screen) then
        for id, _ in pairs(tracked_ents) do
            process_tracked_entity(id)
        end
    end
end

local function on_pre_load_screen()
    -- Check whether the game is unloading a screen that could be tracking entities. It isn't normally possible to move from the options screen directly into a new level, so that case isn't handled here.
    if should_process_entities(state.screen) and state.screen_next ~= SCREEN.OPTIONS and state.screen_next ~= SCREEN.DEATH then
        clear_tracked_entities()
    end
end

set_callback(function(ctx)
    init_entity_ai()
    local load_table = persistence.load(ctx)
    options = persistence.combine_tables(default_options, load_table.options)
    register_option_callback("", options, draw_options)
    set_callback(persistence.save, ON.SAVE)

    set_callback(on_draw_gui, ON.GUIFRAME)
    set_callback(on_post_game_loop, ON.POST_GAME_LOOP)
    -- Also execute this logic even if the game loop was blocked, ensuring that visualizations will update regularly during freeze pauses. This matters for changes that could affect visualizations while paused, such as toggling visibility options or moving entities in Overlunky.
    set_callback(on_post_game_loop, ON.BLOCKED_GAME_LOOP)
    set_callback(on_pre_load_screen, ON.PRE_LOAD_SCREEN)
    -- TODO: This callback does not execute between Playlunky and Overlunky. For example, if this script is loaded in Playlunky, then it won't detect when Overlunky loads a save state.
    set_callback(refresh_tracked_entities, ON.POST_LOAD_STATE)

    -- Immediately track entities that already exist.
    refresh_tracked_entities()

    -- Track subsequent entities as they are created.
    if #entity_ai_ent_type_list > 0 then
        set_post_entity_spawn(function(ent)
            if should_process_entities(state.screen) then
                add_tracked_entity(ent)
            end
        end, SPAWN_TYPE.ANY, MASK.ANY, entity_ai_ent_type_list)
    end
end, ON.LOAD)
