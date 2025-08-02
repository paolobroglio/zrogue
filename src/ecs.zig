const std = @import("std");
const testing = std.testing;
const rl = @import("raylib");

const PositionComponent = struct {
  x: f32,
  y: f32
};

const KeyboardControlledComponent = struct {
  up_velocity: f32,
  down_velocity: f32,
  right_velocity: f32,
  left_velocity: f32
};

const SpriteComponent = struct {
  texture_id: []const u8,
  width: i32,
  height: i32,
  src_rect: rl.Rectangle
};

const Entity = u32;

pub fn ComponentStore(comptime T: type) type {
  return struct {
    const Self = @This();
    
    components: std.ArrayList(T),
    entity_to_index: std.AutoHashMap(Entity, usize),
    index_to_entity: std.ArrayList(Entity),
    
    pub fn init(allocator: std.mem.Allocator) Self {
      return Self {
        .components = std.ArrayList(T).init(allocator),
        .entity_to_index = std.AutoHashMap(Entity, usize).init(allocator),
        .index_to_entity = std.ArrayList(Entity).init(allocator)
      };
    }
    pub fn deinit(self: *Self) void {
      self.components.deinit();
      self.entity_to_index.deinit();
      self.index_to_entity.deinit();
    }
    pub fn add(self: *Self, entity: Entity, component: T) !void {
      const index = self.components.items.len;

      try self.components.append(component);
      try self.entity_to_index.put(entity, index);
      try self.index_to_entity.append(entity);
    }
    pub fn get(self: *const Self, entity: Entity) ?*T {
      const index = self.entity_to_index.get(entity) orelse return null;
      return &self.components[index];
    }
    pub fn has(self: *const Self, entity: Entity) bool {
      return self.entity_to_index.contains(entity);
    }
    pub fn count(self: *const Self) usize {
      return self.components.items.len;
    }
  };
}

const EntityManager = struct {
  next_id: Entity = 0,
    
  pub fn createEntity(self: *EntityManager) Entity {
    const entity = self.next_id;
    self.next_id += 1;
    return entity;
  }
};


test "ECS" {
  const allocator = testing.allocator;

  var entity_manager = EntityManager{};

  var position_store = ComponentStore(PositionComponent).init(allocator);
  defer position_store.deinit();

  const player = entity_manager.createEntity();
  const orc = entity_manager.createEntity();

  try position_store.add(player, PositionComponent {.x = 5.0, .y = 5.0});
  try position_store.add(orc, PositionComponent {.x = 15.0, .y = 10.0});

  try testing.expect(player == 0);
  try testing.expect(orc == 1);

  try testing.expect(position_store.has(player));
  try testing.expect(position_store.has(orc));
}