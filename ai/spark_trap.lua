return Entity_AI:new({
    id = "spark_trap",
    name = "Spark Trap",
    ent_type = ENT_TYPE.FLOOR_SPARK_TRAP,
    ranges = {
        {
            id = "activate",
            name = "Activate",
            shape = geometry.create_box_shape(-8, -8, 8, 8),
            type = Entity_AI.RANGE_TYPE.HITBOX_OVERLAP
        }
    }
})
