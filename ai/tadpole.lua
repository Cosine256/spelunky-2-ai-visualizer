return Entity_AI:new({
    id = "tadpole",
    name = "Tadpole",
    ent_type = ENT_TYPE.MONS_TADPOLE,
    ranges = {
        {
            id = "aggro",
            name = "Aggro",
            shape = geometry.create_circle_shape(4),
            is_visible = function(ent)
                return ent.state == 3
            end,
            is_active = function(ent)
                -- TODO
                return true
            end
        }
    }
})
