local ai_common = require("ai/common")

return {
    Entity_AI:new({
        id = "witch_doctor",
        name = "Witch Doctor",
        ent_type = ENT_TYPE.MONS_WITCHDOCTOR,
        targeting = {
            id_field = "chased_target_uid"
        },
        ranges = {
            {
                id = "attack",
                name = "Attack",
                shape = geometry.create_box_shape(0, -0.4, 6, 0.4),
                flip_with_ent = true,
                line_of_sight_checks = 6,
                is_active = function(ent)
                    -- TODO: When can the witch doctor initiate another attack after just doing one? He can start another attack at some point during the finishing animation from the previous one.
                    -- ANSWER?: It looks like it is always active, and will spawn a hint entity on its target if the target does not already have one.
                    return true
                end
            },
            ai_common.create_caveman_chat_range()
        }
    }),
    Entity_AI:new({
        id = "witch_doctor_skull",
        name = "Witch Doctor Skull",
        ent_type = ENT_TYPE.MONS_WITCHDOCTORSKULL,
        ranges = {
            {
                -- The skull can move when partially transparent, but has no hurtbox unless it's fully opaque.
                id = "chase",
                name = "Chase",
                shape = geometry.create_circle_shape(4),
                is_visible = function(ent)
                    local witch = get_entity(ent.witch_doctor_uid)
                    if witch ~= nil then
                        return witch.stun_timer == 0 and witch.frozen_timer == 0 and not test_flag(witch.flags, ENT_FLAG.DEAD)
                    end
                    return false
                end,
                is_active = function(ent)
                    return ent.color.a >= 1
                end
            },
            {
                id = "orbit",
                name = "Orbit",
                shape = geometry.create_donut_shape(1.3, 1.3),
                translate_shape = function(ent)
                    if ent.witch_doctor_uid >= 0 then
                        local x, y = get_position(ent.witch_doctor_uid)
                        return x, y
                    end
                end,
                is_visible = function(ent)
                    local witch = get_entity(ent.witch_doctor_uid)
                    return witch ~= nil
                end,
                is_active = function(ent)
                    local witch = get_entity(ent.witch_doctor_uid)
                    if witch == nil then return false end
                    return witch.stun_timer == 0 and witch.frozen_timer == 0 and not test_flag(witch.flags, ENT_FLAG.DEAD) and ent.move_state ~= 6
                end,
                label_position = LABEL_POSITION.TOP
            }
        }
    })
}
