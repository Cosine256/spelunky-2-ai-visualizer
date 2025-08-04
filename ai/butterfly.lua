return Entity_AI:new({
    id = "butterfly",
    name = "Butterfly",
    ent_type = ENT_TYPE.MONS_CRITTERBUTTERFLY,
    ranges = {
        {
            id = "move_away",
            name = "Move away",
            shape = geometry.create_circle_shape(4),
            is_active = function(ent)
                return ent.move_state == 9
            end
        }
    }
})
