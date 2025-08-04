---@class Entity_AI
---@field id string Unique identifier.
---@field name string Display name to show in the options.
---@field ent_type nil | ENT_TYPE | ENT_TYPE[] Entity types to associate this AI with.
---@field is_dead (fun(ent: Entity): boolean)? Function to determine whether the entity is dead. Defaults to checking whether health is 0.
---@field preprocess (fun(ent: Entity, ctx: table))? Function to add data to the processing context object `ctx` for entity `ent`. This object is passed into every function call (TODO: except `is_dead`) during this entity processing event.
---@field targeting nil | false | table TODO
---@field ranges Entity_AI_Range[]?

---@class Entity_AI_Range
---@field id string Unique identifier.
---@field name string Display name to show in the options and use as a default value for the label.
---@field shape nil | Shape | fun(ent: Entity, ctx: table): Shape
---@field shapes nil | (Shape | fun(ent: Entity, ctx: table): Shape)[]
---@field flip_with_ent boolean? Whether to horizontally flip this range based on the facing direction of the entity. Defaults to 'false'.
---@field line_of_sight_checks integer? Number of solid entity checks to perform for a line-of-sight range. Requires `flip_with_ent` to be `true`.
---@field line_of_sight_extra_length number? Extra length to preserve in this range when clipping based on line-of-sight. Defaults to `0.5`. Requires `line_of_sight_checks` to be defined.
---@field type Entity_AI_Range_Type? Range type to determine drawing style. Defaults to `ORIGIN_CHECK`.
---@field translate_shape (fun(ent: Entity, ctx: table): number?, number?)? Function to specify a translation vector for a shape, with X and Y return values. If `nil`, then the translation vector is the position of the entity.
---@field post_transform_shape (fun(ent: Entity, ctx: table, shape: Shape): Shape)? Function allowing a final modification of a shape after all other transformations have occurred. If `nil`, then no modifications are made.
---@field layer nil | LAYER | fun(ent: Entity, ctx: table): LAYER Layer on which to draw this range. Defaults to the entity's current layer.
---@field is_visible (fun(ent: Entity, ctx: table): boolean)? Function to determine whether to draw this range. If `nil`, then this range is always visible.
---@field is_inactive_when_stuck boolean? Whether this range is inactive when the entity is stuck in a web or sticky trap. If `true`, then stuck entities don't evaluate `is_active`. Defaults to `true`.
---@field is_active (fun(ent: Entity, ctx: table): boolean)? Function to determine whether this range is active. If `nil`, then this range is always active.
---@field label nil | false | string | fun(ent: Entity, ctx: table): any Text to draw over this range. If `nil`, then the `name` field is used as the text. If `false`, then no label is drawn.
---@field label_position table? Drawing position within this range for the label. Defaults to center position.

local Entity_AI = {
    ---@enum Entity_AI_Range_Type
    RANGE_TYPE = { MISC = 1, ORIGIN_CHECK = 2, HITBOX_OVERLAP = 3, HURTBOX = 4, SOLID_CHECK = 5 },
    is_dead = function(ent)
        return ent.health == 0
    end,
    targeting = {
        id_field = "chased_target_uid",
        timer_field = "target_selection_timer",
        timer_max = 60
    }
}
Entity_AI.__index = Entity_AI

---@param o Entity_AI
---@return Entity_AI
function Entity_AI:new(o)
    setmetatable(o, self)
    return o
end

return Entity_AI
