-- globals
block_count = 5
dt = 0
isFirePressed = false
last_time = t()
camera_x = 0
camera_y = 0
checkpoint_x = 64

angles = {
    0, 45, 90, 135, 180, 225, 270, 315
}
cos_look_up = {
    1, 0.707, 0, -0.707, -1, -0.707, 0, 0.707
}
sin_look_up = {
    0, 0.707, 1, 0.707, 0, -0.707, -1, -0.707
}

blocks = {}
block = {
    x = 0,
    y = 0,
    dx = 0,
    dy = 0,
    offset_x = 0,
    offset_y = 0,
    start_x = 0,
    start_y = 0,
    is_sleeping = true,

    new = function(self, x, y)
        local obj = {
            x = x,
            y = y,
            start_x = x,
            start_y = y
        }
        setmetatable(obj, { __index = self })
        add(blocks, obj)
    end,
    on_hit = function(self, hit_power)
        self.dx = hit_power
        self.is_sleeping = false
    end,

    update = function(self)
        if not self.is_sleeping then
            self.dy += 9.8 * dt
            self.dx *= 0.98 --friction
        end
    end,

    draw = function(self)
        self.x += self.dx * dt
        self.y += self.dy * dt
        rect(self.x - camera_x, self.y + camera_y, self.x + 10 - camera_x, self.y + 10 + camera_y)
    end
}
particles = {}
particle = {
    x = 0,
    y = 0,
    dx = 50,
    dy = -20,
    radius = 0,
    update = function(self)
        self.radius += dt * 10
        self.dy += dt * 10
        self.y -= self.dy * dt - ship.dy
        self.x -= self.dx * dt + ship.dx
        if self.radius > 5 then
            del(particles, self)
        end
    end,
    new = function(self, x, y, start_angle)
        local obj = {
            dx = (cos_look_up[start_angle] or 1) * self.dx,
            dy = (sin_look_up[start_angle] or 1) * self.dy,
            x = x,
            y = y, radius = 1
        }
        setmetatable(obj, { __index = self })
        add(particles, obj)
        return obj
    end,
    draw = function(self)
        circ(self.x, self.y, self.radius, 1)
    end
}

ship = {
    particleReleaseTime = 0,
    ship_rotation = 1,
    ship_rotation_speed = 5,

    friction = 0.1, --between 0 - 1

    acceleration = 50,
    x = 64,
    y = 64,
    dx = 0,
    dy = 0,

    sprites = { 0, 1, 2, 3, 4, 5, 6, 7 },

    update = function(self, dt)
        if not isFirePressed then
            self.ship_rotation += dt * self.ship_rotation_speed
            self.particleReleaseTime = 0
            self.dx *= (1 - self.friction)
            self.dy *= (1 - self.friction)
        else
            --if pressed
            self.particleReleaseTime += dt
            if self.particleReleaseTime > 0.1 then
                particle:new(
                    self.x + cos_look_up[flr(self.ship_rotation)] * -8 + 4,
                    self.y + sin_look_up[flr(self.ship_rotation)] * 4 + 4,
                    flr(self.ship_rotation)
                )
                self.dx += cos_look_up[flr(self.ship_rotation)]
                        * dt * self.acceleration

                self.dy += sin_look_up[flr(self.ship_rotation)]
                        * dt * self.acceleration

                self.particleReleaseTime = 0
            end
        end

        if self.ship_rotation > 9 then
            self.ship_rotation = 1
        end
        camera_x += self.dx
        camera_y += self.dy
    end,
    draw = function(self)
        spr(self.sprites[flr(self.ship_rotation)], self.x, self.y)
    end
}
function check_collision_with_ship(_block)
    local ship_x = ship.x
    local ship_y = ship.y

    local obj_x = _block.x - camera_x
    local obj_y = _block.y + camera_y

    return ship_x < obj_x + 10
            and ship_x + 10 > obj_x
            and ship_y < obj_y + 10
            and ship_y + 10 > obj_y
end

function _init()
    create_blocks()
end
function create_blocks()
    for i = 1, block_count do
        deli(blocks, 1)
    end
    for i = 1, block_count do
        block:new(camera_x + 128, i * 10 - camera_y + 32)
    end
end
function _update()
    local current_time = t()
    dt = current_time - last_time
    ship.update(ship, dt)
    isFirePressed = btn(5)
    if camera_x > checkpoint_x then
        checkpoint_x += 128
        create_blocks()
    end
    foreach(particles, function(p) p:update() end)
    foreach(blocks, function(p) p:update() end)
    last_time = current_time
end

function _draw()
    cls()
    foreach(particles, function(p) p:draw() end)
    foreach(blocks, function(p) p:draw() end)
    foreach(
        blocks, function(block)
            if check_collision_with_ship(block) then
                block.is_sleeping = false
                block:on_hit(ship.dx * 50)
                ship.dx = ship.dx / 2
                print("Collided!")
            end
        end
    )

    print(ship.dx)

    ship.draw(ship)
end