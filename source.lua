-- globals
block_count = 18
dt = 0
isFirePressed = false
last_time = t()
camera_x = 0
camera_y = 0
camera_shake_amount = 0
camera_shake_time_passed = 0
checkpoint_x = 64

ceil_pos_y = 30
ground_pos_y = 120

angles = {
    0, 45, 90, 135, 180, 225, 270, 315
}
cos_look_up = {
    1, 0.707, 0, -0.707, -1, -0.707, 0, 0.707
}
sin_look_up = {
    0, 0.707, 1, 0.707, 0, -0.707, -1, -0.707
}

stars = {}

lines = {}

blocks = {}
block = {
    x = 0,
    y = 0,
    dx = 0,
    dy = 0,
    sizex = 5,
    sizey = 5,
    offset_x = 0,
    offset_y = 0,
    start_x = 0,
    start_y = 0,
    is_sleeping = true,
    can_collide = true,

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
    on_hit_with_ship = function(self)
        if self.can_collide then
            self.can_collide = false
            move_y = 0
            if ship.y > self.y then
                move_y = ship.dx * sin_look_up[6] * rnd(10)
            else
                move_y = ship.dx * sin_look_up[2] * rnd(10)
            end

            self.dx = ship.dx * (50 + rnd(10))
            self.dy = move_y
            self.is_sleeping = false
        end
    end,

    update = function(self)
        if not self.is_sleeping then
            self.dy += 9.8 * dt * 10
            self.dx *= 0.98 --friction
            self.x += self.dx * dt
            self.y += self.dy * dt
        else
            if self.x - camera_x < 0 then
                del(blocks, self)
            end
        end
    end,

    draw = function(self)
        rect(self.x - camera_x, self.y - camera_y, self.x + self.sizex - camera_x, self.y + self.sizey - camera_y, 2)
    end
}

particles = {}
particle = {
    x = 0,
    y = 0,
    dx = 1,
    dy = 1,
    radius = 0,
    color = 1,
    update = function(self)
        self.radius += dt * 10
        self.dy += dt * 10
        self.y -= self.dy * dt
        self.x -= self.dx * dt
        if self.radius > 5 then
            del(particles, self)
        end
    end,
    new = function(self, x, y, dx, dy, start_angle, color)
        local obj = {
            dx = dx,
            dy = dy,
            x = x,
            y = y,
            color = color,
            radius = 1
        }
        setmetatable(obj, { __index = self })
        add(particles, obj)
        return obj
    end,
    draw = function(self)
        circfill(self.x - camera_x, self.y - camera_y, self.radius, self.color)
    end
}

ship = {
    is_dead = false,
    dead_time = 0,
    dead_anim_index = 1,
    particleReleaseTime = 0,
    ship_rotation = 1,
    ship_rotation_speed = 7,

    friction = 0.01, --between 0 - 1

    acceleration = 5,
    gravity = -1,
    x = 64,
    y = 64,
    dx = 0,
    dy = 0,
    debug_move = true,
    sprites = { 0, 1, 2, 3, 4, 5, 6, 7 },
    explosion_sprites = { 8, 9, 10, 11, 12, 13, 14, 15, 16 },

    update = function(self, dt)
        if (ship.y + 8 > ground_pos_y or ship.y < ceil_pos_y) then
            if not self.is_dead then
                self.dead_time = t()
            end
            self.is_dead = true
            return
        end
        if self.debug_move then
            self.gravity = 0
            if btn(0) then self.dx -= 1 end
            if btn(1) then self.dx += 1 end
            if btn(2) then self.dy -= 1 end
            if btn(3) then
                self.dy += 1
            end
        end
        if not isFirePressed then
            self.ship_rotation += dt * self.ship_rotation_speed
            self.particleReleaseTime = 0
            self.dx *= (1 - self.friction)
            self.dy *= (1 - self.friction)
        else
            --if pressed
            self.particleReleaseTime += dt
            if self.particleReleaseTime > 0.01 then
                particle:new(
                    self.x + cos_look_up[flr(self.ship_rotation)] * -8 + 4,
                    self.y + sin_look_up[flr(self.ship_rotation)] * 4 + 4,
                    ship.dx,
                    ship.dy,
                    flr(self.ship_rotation),
                    1
                )
            end
            self.dx += cos_look_up[flr(self.ship_rotation)]
                    * dt * self.acceleration

            self.dy -= sin_look_up[flr(self.ship_rotation)]
                    * dt * self.acceleration

            self.particleReleaseTime = 0
        end

        if self.ship_rotation > 9 then
            self.ship_rotation = 1
        end
        self.dy -= self.gravity * dt
        self.x += self.dx
        self.y += self.dy
    end,
    draw = function(self)
        if self.is_dead then
            self.dx = 0
            self.dy = 0
            self.dead_anim_index += dt * 50
            if self.dead_anim_index < 10 then
                spr(
                    self.explosion_sprites[flr(self.dead_anim_index)],
                    self.x - camera_x, self.y - camera_y
                ) --draw explosion
            end
            particle:new(
                self.x,
                self.y,
                rnd(10),
                rnd(15),
                flr(2),
                rnd(5)
            )
        else
            spr(self.sprites[flr(self.ship_rotation)], self.x - camera_x, self.y - camera_y)
        end
    end
}
function check_collision_with_ship(_block)
    return ship.x < _block.x + block.sizex
            and ship.x + 10 > _block.x
            and ship.y < _block.y + block.sizey
            and ship.y + 10 > _block.y
end

function _init()
    -- create_blocks()
    create_stars()
    create_lines()
end

function create_lines()
    for i = 1, 16 do
        local _line = {
            x1 = i * 8,
            y1 = 0,
            x2 = i * 8,
            y2 = ceil_pos_y
        }
        local _lineground = {
            x1 = i * 8,
            y1 = 200,
            x2 = i * 8,
            y2 = ground_pos_y
        }
        add(lines, _lineground)
        add(lines, _line)
    end
end

function create_blocks()
    random_y =
        --rnd(30) + 25
        25
    for i = 1, block_count do
        block:new(camera_x + 128, i * block.sizey + random_y)
    end
end
function start_camera_shake(amount)
    camera_shake_amount = amount
    camera_shake_time_passed = 0
end

function update_camera()
    local lerp_factor = 0.5
    camera_x += (ship.x - 64 - camera_x) * lerp_factor
    camera_y += (ship.y - 64 - camera_y) * lerp_factor
    local duration = 0.2
    if camera_shake_time_passed < duration then
        camera_shake_time_passed += dt
        camera_x += rnd(camera_shake_amount)
        camera_y += rnd(camera_shake_amount)
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
    has_hit = false
    foreach(
        blocks, function(block)
            block:update()
            if not has_hit and block.can_collide then
                if check_collision_with_ship(block) then
                    has_hit = true
                    on_hit_new_wall()
                end
            end
        end
    )
    if has_hit then
    end

    update_camera()

    last_time = current_time
end

function draw_lines()
    foreach(
        lines, function(_line)
            line(_line.x1 - camera_x - 32, _line.y1 - camera_y, _line.x2 - camera_x, _line.y2 - camera_y, 4)
            if _line.x1 - camera_x < 0 then
                _line.x1 += 128
                _line.x2 += 128
            end
        end
    )
end

function draw_ground()
    rectfill(0, ceil_pos_y - camera_y, 128, 0, 3)
    rectfill(0, ground_pos_y - camera_y, 128, 128, 3)
end

function create_stars()
    for i = 1, 30 do
        local star = {
            x = flr(rnd(128)),
            y = flr(rnd(128)),
            size = flr(i / 15),
            color = flr(rnd(15))
        }
        add(stars, star)
    end
end

function on_hit_new_wall()
    has_hit = false
    foreach(
        blocks, function(block)
            block.is_sleeping = false
            block:on_hit_with_ship()
        end
    )
    start_camera_shake(ship.dx * 4)
    ship.dx = ship.dx / 2
end

function draw_background_starts()
    local starspr = 16
    local mid_startspr = 17
    local big_startspr = 18
    foreach(
        stars, function(star)
            local star_pos_x = star.x - (camera_x / 16 * (star.size + 1))
            local star_pos_y = star.y - (camera_y / 16 * (star.size + 1))
            if (star_pos_x < 0) star.x += 128
            spr(16 + flr(star.size), star_pos_x, star_pos_y)
        end
    )
end

function _draw()
    cls()
    draw_background_starts()
    foreach(blocks, function(p) p:draw() end)

    ship.draw(ship)
    draw_ground()
    draw_lines()
    print(ship.dx, 2)
    foreach(particles, function(p) p:draw() end)
end