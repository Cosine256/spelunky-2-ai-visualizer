return Entity_AI:new({
    id = "celestial_jelly",
    name = "Celestial Jelly",
    ent_type = ENT_TYPE.MONS_MEGAJELLYFISH,
    targeting = {
        id_field = "chased_target_uid"
    }
})
