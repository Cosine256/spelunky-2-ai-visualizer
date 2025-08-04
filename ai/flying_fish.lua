-- TODO: How does the targeting work?
return Entity_AI:new({
    id = "flying_fish",
    name = "Flying Fish",
    ent_type = ENT_TYPE.MONS_FISH,
    ranges = {
        {
            id = "rise",
            name = "Rise",
            -- TODO: Ceiling will reduce the height of the rise shape. Getting close may cause a rise even when there is a low ceiling.
            shape = geometry.create_box_shape(-10, 0, 10, 4),
            is_active = function(ent)
                return ent.state == 3 and ent.move_state == 0 and ent.target_selection_timer == 0
            end
        },
        {
            id = "attack",
            name = "Attack",
            shape = geometry.create_box_shape(-1000, -1000, 1000, 0),
            is_visible = function(ent)
                return ent.move_state == 2
            end,
            label_position = LABEL_POSITION.TOP
        },
        {
            id = "stop_rising_check",
            name = "Stop rising check",
            shape = function(ent)
                local top_pos = ent.offsety + ent.hitboxy + 0.15
                return geometry.create_point_set_shape(Vec2:new(ent.offsetx - ent.hitboxx, top_pos), Vec2:new(0, top_pos), Vec2:new(ent.offsetx + ent.hitboxx, top_pos))
            end,
            type = Entity_AI.RANGE_TYPE.SOLID_CHECK,
            is_visible = function(ent)
                return ent.move_state == 2
            end,
            -- TODO: This hack puts the label above the points.
            label_position = LABEL_POSITION.BOTTOM
        }
    }
})
