-- TODO: Target only matters while sleeping, but keeps getting updated while awake. Should dim it in that case.
return Entity_AI:new({
    id = "skeleton",
    name = "Skeleton & Red Skeleton",
    ent_type = { ENT_TYPE.MONS_SKELETON, ENT_TYPE.MONS_REDSKELETON },
    ranges = {
        {
            -- TODO: I think red skeletons follow the same rules after settling down, but I haven't thoroughly tested that.
            id = "aggro",
            name = "Aggro",
            shape = geometry.create_circle_shape(4):clip_top(0.5),
            is_visible = function(ent)
                return ent.move_state == 0
            end
        }
    }
})
