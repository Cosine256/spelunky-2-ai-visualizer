-- Tiamat cannot shoot while yelling and vice-versa. The yell is preferred if both attacks are possible at the same time.
-- Bomb yelling is triggered by having a paste bomb stuck to Tiamat's face, shoulder, or arm rest platforms, and has nothing to do with proximity. It uses the same cooldown timer as normal yells.
return Entity_AI:new({
    id = "tiamat",
    name = "Tiamat",
    ent_type = ENT_TYPE.MONS_TIAMAT,
    ranges = {
        { -- Shoot
            -- TODO: This range is actually hard-coded as (7.5, 55.5, 27.5, 70.5). It is not based on Tiamat's position nor the level size.
            shape = geometry.create_box_shape(-11, -6, 9, 10),
            is_active = function(ent)
                return ent.move_state == 0 and ent.attack_timer == 0
            end,
            label = "Shoot"
        },
        { -- Yell
            shape = geometry.create_circle_shape(2),
            is_active = function(ent)
                return ent.move_state == 0 and ent.damage_timer == 0
            end,
            label = "Yell"
        },
        { -- Yell hurtbox
            -- The yell only stuns and deals damage on the first frame. It applies knockback to entities and detaches paste bombs for the entire duration.
            shape = geometry.create_box_shape(-4.4, -5.25, 4.6, 3.75),
            type = Entity_AI.RANGE_TYPE.HURTBOX,
            is_active = function(ent)
                return ent.move_state == 6
            end,
            label = "Yell hurtbox",
            label_position = LABEL_POSITION.BOTTOM
        }
    }
})
