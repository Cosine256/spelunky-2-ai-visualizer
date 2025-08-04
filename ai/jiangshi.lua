local HITBOX_W_HALF = get_type(ENT_TYPE.MONS_JIANGSHI).hitboxx

return Entity_AI:new({
    id = "jiangshi",
    name = "Jiangshi",
    ent_type = ENT_TYPE.MONS_JIANGSHI,
    ranges = {
        {
            id = "jump",
            name = "Jump",
            shape = geometry.create_circle_shape(8),
            is_active = function(ent)
                return ent.state == CHAR_STATE.STANDING and ent.move_state == 0 and ent.wait_timer == 0
            end
        },
        {
            id = "walk_check_corridor",
            name = "Walk check (in corridor)",
            shape = geometry.create_point_set_shape(Vec2:new(-HITBOX_W_HALF, 1), Vec2:new(HITBOX_W_HALF, 1)),
            type = Entity_AI.RANGE_TYPE.SOLID_CHECK,
            is_active = function(ent)
                return ent.state == CHAR_STATE.STANDING and ent.move_state == 0 and ent.wait_timer == 0
            end,
            label = "Walk check",
            -- TODO: This hack puts the label above the points.
            label_position = LABEL_POSITION.BOTTOM
        }
    }
})
