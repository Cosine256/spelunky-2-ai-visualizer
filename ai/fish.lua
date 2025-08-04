return Entity_AI:new({
    id = "fish",
    name = "Fish",
    ent_type = ENT_TYPE.MONS_CRITTERFISH,
    ranges = {
        {
            -- The target must also be submerged in any liquid.
            id = "swim_fast",
            name = "Swim fast",
            shape = geometry.create_circle_shape(4),
            is_active = function(ent)
                return ent.state == 3
            end
        }
    }
})
