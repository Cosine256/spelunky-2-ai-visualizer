-- The mounted caveman's aggro_timer controls when the turkey stops running around after aggroing.
-- TODO: Is the aggro controlled by the turkey entity, or the caveman rider entity?
return Entity_AI:new({
    id = "turkey",
    name = "Turkey",
    ent_type = ENT_TYPE.MOUNT_TURKEY,
    preprocess = function(ent, ctx)
        local rider_ent = get_entity(ent.rider_uid)
        if rider_ent and rider_ent.type.id == ENT_TYPE.MONS_CAVEMAN then
            ctx.hostile_rider_ent = rider_ent
        end
    end,
    ranges = {
        {
            id = "aggro",
            name = "Aggro (caveman rider)",
            shape = geometry.create_box_shape(0, -0.4, 6, 0.4),
            flip_with_ent = true,
            line_of_sight_checks = 6,
            is_visible = function(ent, ctx)
                return ent.tamed and ctx.hostile_rider_ent
            end,
            is_active = function(ent, ctx)
                return ctx.hostile_rider_ent.move_state ~= 4 and ctx.hostile_rider_ent.move_state ~= 6
            end,
            label = "Aggro"
        }
    }
})
