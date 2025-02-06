-- globals
block_count = 18
dt = 0
isFirePressed = false
last_time = t()
spawn_wall_x_amount = 64
--camera
camera_x = 0
camera_y = 0
camera_shake_amount = 0
camera_shake_time_passed = 0

--game rules
walls_passed = 0
checkpoint_x = 64
score = 0

--environment
ceil_pos_y = 30
ground_pos_y = 120
ground_close_speed = 1

angles = {
    0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170, 180, 190, 200, 210, 220, 230, 240, 250, 260, 270, 280, 290, 300, 310, 320, 330, 340, 350
}
cos_look_up = {}
sin_look_up = {}

stars = {}

ground_lines = {}
ceil_lines = {}
bonus_texts = {}
bonus_text = {
    x = 0,
    y = 0,
    text = "",
    new = function(self, x, y, text)
        local obj = {
            x = x,
            y = y,
            text = text
        }
        setmetatable(obj, { __index = self })
        add(bonus_texts, obj)
    end,
    update = function(self)
        self.y -= 1
        if self.y < 15 then
            del(bonus_texts, self)
        end
    end,
    draw = function(self)
        print(self.text, self.x, self.y, 7)
    end
}

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
        self.is_sleeping = false
        if self.can_collide then
            self.can_collide = false
            move_y = 0
            if ship.y > self.y then
                move_y = ship.dx * sin_look_up[6] * 100
            else
                move_y = ship.dx * sin_look_up[2] * 100
            end

            self.dx = ship.dx * (50 + rnd(10))
            self.dy = move_y
            self.is_sleeping = false
            particle:new(
                self.x,
                self.y,
                1,
                move_y / rnd(5),
                flr(2),
                rnd(5)
            )
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
        rectfill(self.x - camera_x, self.y - camera_y, self.x + self.sizex - camera_x, self.y + self.sizey - camera_y, 2)
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
        self.dy += dt * 2
        self.y -= self.dy
        self.x -= self.dx
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
    ship_rotation_speed = 30,
    max_speed = 1,

    friction = 0.01, --between 0 - 1

    acceleration = 2,
    gravity = -0.3,
    x = 64,
    y = 64,
    dx = 0,
    dy = 0,
    debug_move = false,
    sprites = { 0, 1, 2, 3, 4, 5, 6, 7 },
    explosion_sprites = { 64, 65, 66, 67, 68, 69, 70, 71 },

    update = function(self, dt)
        local sin_rot = sin_look_up[flr(ship.ship_rotation)]
        if (ship.y + 10 * sin_rot > ground_pos_y or ship.y + 10 * sin_rot < ceil_pos_y) then
            --if hit ground or ceil
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
            local angles_count = #angles --TODO: cache
            self.ship_rotation += dt * self.ship_rotation_speed
            if self.ship_rotation > #angles then
                --TODO: cache angles count
                self.ship_rotation = 1
            end
            self.particleReleaseTime = 0
            self.dx *= (1 - self.friction)
            self.dy *= (1 - self.friction)
        else
            --if pressed
            self.particleReleaseTime += dt
            if self.particleReleaseTime > 0.01 then
                local rot = (flr(self.ship_rotation) - 1) % (#angles - 1) + 1
                particle:new(
                    self.x,
                    self.y,
                    ship.dx,
                    ship.dy,
                    rot,
                    1
                )
            end
            self.dx += cos_look_up[flr(self.ship_rotation)]
                    * dt * self.acceleration

            self.dy += sin_look_up[flr(self.ship_rotation)]
                    * dt * self.acceleration
            self.particleReleaseTime = 0
        end

        self.dy -= self.gravity * dt
        self.dx = mid(-self.max_speed, self.dx, self.max_speed)
        self.dy = mid(-self.max_speed, self.dy, self.max_speed)
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
                rnd(1),
                rnd(1),
                flr(2),
                rnd(5)
            )
        else
            local rot = (flr(self.ship_rotation) - 1) % (#angles - 1) + 1

            -- Compute front and back points
            local nose_x = self.x + 8 * cos_look_up[rot]
            local nose_y = self.y + 8 * sin_look_up[rot]
            local back_left_x = self.x - 4 * cos_look_up[(rot + 5) % #angles + 1]
            local back_left_y = self.y - 4 * sin_look_up[(rot + 5) % #angles + 1]
            local back_right_x = self.x - 4 * cos_look_up[(rot - 5) % #angles + 1]
            local back_right_y = self.y - 4 * sin_look_up[(rot - 5) % #angles + 1]

            -- Draw rocket as a triangle
            line(nose_x - camera_x, nose_y - camera_y, back_left_x - camera_x, back_left_y - camera_y, 2)
            line(nose_x - camera_x, nose_y - camera_y, back_right_x - camera_x, back_right_y - camera_y, 2)
            line(back_left_x - camera_x, back_left_y - camera_y, back_right_x - camera_x, back_right_y - camera_y, 1)
            -- spr(self.sprites[flr(self.ship_rotation)], self.x - camera_x, self.y - camera_y)
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
    create_blocks()
    initialize_trig_tables()
    create_stars()
    create_lines()
end
function initialize_trig_tables()
    cos_look_up = {}
    sin_look_up = {}

    for i, angle in ipairs(angles) do
        cos_look_up[i] = cos(angle / 365)
        sin_look_up[i] = sin(angle / 365)
    end
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
        add(ground_lines, _lineground)
        add(ceil_lines, _line)
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
    local lerp_factor = 0.9
    camera_x += (ship.x - 64 - camera_x) * lerp_factor
    local duration = 0.2
    if camera_shake_time_passed < duration then
        camera_shake_time_passed += dt
        camera_x += rnd(camera_shake_amount) - rnd(camera_shake_amount)
        camera_y += rnd(camera_shake_amount) - rnd(camera_shake_amount)
    else
        camera_y = 0
    end
end

function on_level_up()
    local max_speed = ship.max_speed
    local acceleration = ship.acceleration
    local gravity = ship.gravity
    local ship_rotation_speed = ship.ship_rotation_speed

    spawn_wall_x_amount += 10
    ground_close_speed += 0.1
    max_speed += 0.08
    gravity -= 0.03
    ship_rotation_speed += 0.1
    acceleration += 0.08

    spawn_wall_x_amount = min(128, spawn_wall_x_amount)
    ground_close_speed = min(10, ground_close_speed)
    ship.max_speed = min(2, max_speed)
    ship.ship_rotation_speed = min(50, ship_rotation_speed)
    ship.gravity = max(-1, gravity)
    ship.acceleration = min(5, acceleration)
end

function _update()
    local current_time = t()
    dt = current_time - last_time
    ceil_pos_y += dt * ground_close_speed
    ground_pos_y -= dt * ground_close_speed
    ship.update(ship, dt)
    isFirePressed = btn(5)
    if camera_x > checkpoint_x then
        checkpoint_x += spawn_wall_x_amount
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
                    on_hit_new_wall(ship.dx + ship.dy)
                end
            end
        end
    )
    if has_hit then
    end
    foreach(
        bonus_texts,
        function(text)
            text:update()
        end
    )

    update_camera()

    last_time = current_time
end

function draw_lines()
    foreach(
        ground_lines, function(_line)
            line(_line.x1 - camera_x - 32, _line.y1 - camera_y, _line.x2 - camera_x, ground_pos_y - camera_y, 4)
            if _line.x1 - camera_x < 0 then
                _line.x1 += 128
                _line.x2 += 128
            end
        end
    )
    foreach(
        ceil_lines, function(_line)
            line(_line.x1 - camera_x - 32, _line.y1 - camera_y, _line.x2 - camera_x, ceil_pos_y - camera_y, 4)
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

function on_hit_new_wall(hit_speed)
    local score_to_earn = flr(abs(ship.dx) * 100 + abs(ship.dy) * 100)
    bonus_text:new(ship.x - camera_x, ship.y - camera_y, score_to_earn)
    score += score_to_earn
    walls_passed += 1
    has_hit = false
    foreach(
        blocks, function(block)
            block:on_hit_with_ship()
        end
    )
    local push_back_walls_amount = hit_speed * 2.2
    ceil_pos_y -= push_back_walls_amount
    ground_pos_y += push_back_walls_amount
    start_camera_shake(ship.dx)
    ship.dx = ship.dx / 2

    if walls_passed % 1 == 0 then
        on_level_up()
    end
end

function draw_bonus_texts()
    foreach(
        bonus_texts, function(text)
            text:draw()
        end
    )
end

function draw_background_starts()
    local starspr = 16
    local mid_startspr = 17
    local big_startspr = 18
    foreach(
        stars, function(star)
            local star_pos_x = star.x - (camera_x / 4 * (star.size + 1))
            local star_pos_y = star.y - (camera_y / 4 * (star.size + 1))
            if (star_pos_x < 0) star.x += 128
            spr(16 + flr(star.size), star_pos_x, star_pos_y)
        end
    )
end

function _draw()
    cls()
    draw_background_starts()
    foreach(blocks, function(p) p:draw() end)

    draw_ground()
    draw_lines()
    foreach(particles, function(p) p:draw() end)
    ship.draw(ship)
    -- print(flr(abs(ship.dx) * 100 + abs(ship.dy) * 100))
    print("score: " ..score, 7)
    draw_bonus_texts()
end