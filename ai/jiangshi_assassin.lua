local HITBOX_W_HALF = get_type(ENT_TYPE.MONS_FEMALE_JIANGSHI).hitboxx

return Entity_AI:new({
    id = "jiangshi_assassin",
    name = "Jiangshi Assassin",
    ent_type = ENT_TYPE.MONS_FEMALE_JIANGSHI,
    ranges = {
        {
            id = "jump_flip_floor",
            name = "Jump/flip (on floor)",
            shape = geometry.create_circle_shape(8),
            is_visible = function(ent)
                return not ent.on_ceiling
            end,
            is_active = function(ent)
                return ent.state == CHAR_STATE.STANDING and ent.move_state == 0 and ent.wait_timer == 0
            end,
            label = function(ent)
                return ent.jump_counter == 0 and "Flip" or "Jump"
            end
        },
        {
            id = "jump_ceiling",
            name = "Jump (on ceiling)",
            shape = geometry.create_circle_shape(8),
            is_visible = function(ent)
                return ent.on_ceiling
            end,
            is_active = function(ent)
                return ent.state == CHAR_STATE.STANDING and ent.move_state == 0 and ent.wait_timer == 0
            end,
            label = "Jump"
        },
        {
            -- Flipping is prioritized over jumping.
            id = "flip_ceiling_hitbox",
            name = "Flip (on ceiling, hitbox check)",
            shape = geometry.create_box_shape(-HITBOX_W_HALF, -12, HITBOX_W_HALF, 0),
            type = Entity_AI.RANGE_TYPE.HITBOX_OVERLAP,
            is_visible = function(ent)
                return ent.on_ceiling
            end,
            is_active = function(ent)
                return ent.state == CHAR_STATE.STANDING and ent.move_state == 0
            end,
            label = "Flip"
        },
        {
            id = "flip_ceiling_distance",
            name = "Flip (on ceiling, distance check)",
            shape = geometry.create_box_shape(-1000, -1000, 1000, -12),
            is_visible = function(ent)
                return ent.on_ceiling
            end,
            is_active = function(ent)
                return ent.state == CHAR_STATE.STANDING and ent.move_state == 0
            end,
            label = "Flip",
            label_position = LABEL_POSITION.TOP
        },
        {
            id = "walk_check_corridor",
            name = "Walk check (on floor in corridor)",
            shape = geometry.create_point_set_shape(Vec2:new(-HITBOX_W_HALF, 1), Vec2:new(HITBOX_W_HALF, 1)),
            type = Entity_AI.RANGE_TYPE.SOLID_CHECK,
            is_visible = function(ent)
                return not ent.on_ceiling
            end,
            is_active = function(ent)
                return ent.state == CHAR_STATE.STANDING and ent.move_state == 0
            end,
            label = "Walk check",
            -- TODO: This hack puts the label above the points.
            label_position = LABEL_POSITION.BOTTOM
        },
        {
            id = "flip_check_corridor",
            name = "Flip check (on ceiling in corridor)",
            shape = geometry.create_point_set_shape(Vec2:new(-HITBOX_W_HALF, -1), Vec2:new(HITBOX_W_HALF, -1)),
            type = Entity_AI.RANGE_TYPE.SOLID_CHECK,
            is_visible = function(ent)
                return ent.on_ceiling
            end,
            is_active = function(ent)
                return ent.state == CHAR_STATE.STANDING and ent.move_state == 0
            end,
            label = "Flip check",
            -- TODO: This hack puts the label below the points.
            label_position = LABEL_POSITION.TOP
        }
    }
})
