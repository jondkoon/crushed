pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

screen_width = 128
half_screen_width = screen_width / 2
screen_height = 128
half_screen_height = screen_height / 2
frame_rate = 60
sound_on = true
stop = false
_sfx = sfx
function sfx(id)
	if (sound_on) then
		_sfx(id)
	end
end

_music = music
function music(id)
	if (sound_on) then
		_music(id)
	end
end

function draw_hit_box(o)
	rect(o.x, o.y, o.x + o.width, o.y + o.height, 11)
end

function white_pal()
	for i = 0, 15 do
		pal(i, 7)
	end
end

function test_collision(a, b)
	return (
		a.x < b.x + b.width and
		a.x + a.width > b.x and
		a.y < b.y + b.height and
		a.y + a.height > b.y
	)
end

function random_one(set)
	return set[1 + flr(rnd(count(set)))]
end

function merge_tables(a, b)
	for k,v in pairs(b) do
		a[k] = v
	end
	return a
end

local fadetable = {
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
 {1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
 {2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0},
 {3,3,3,3,3,3,3,3,3,3,3,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0},
 {4,4,4,4,4,4,4,2,2,2,2,2,2,2,2,2,1,1,0,0,0,0,0,0,0,0,0,0,0},
 {5,5,5,5,5,5,5,5,5,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0},
 {6,6,6,6,13,13,13,13,13,13,13,13,5,5,5,5,5,5,5,5,1,1,1,1,1,0,0,0,0},
 {7,7,7,6,6,6,6,6,6,13,13,13,13,13,13,5,5,5,5,5,5,5,1,1,1,1,0,0,0},
 {8,8,8,8,8,8,8,8,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0},
 {9,9,9,9,9,9,9,4,4,4,4,4,4,4,4,4,4,5,5,5,5,0,0,0,0,0,0,0,0},
 {10,10,10,10,10,9,9,9,9,4,4,4,4,4,4,4,5,5,5,5,5,5,1,0,0,0,0,0,0},
 {11,11,11,11,11,11,11,3,3,3,3,3,3,3,3,3,3,3,3,0,0,0,0,0,0,0,0,0,0},
 {12,12,12,12,12,12,12,12,12,3,3,3,3,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0},
 {13,13,13,13,13,13,5,5,5,5,5,5,5,5,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0},
 {14,14,14,14,14,14,13,4,4,4,4,2,2,2,2,2,2,2,2,2,1,1,1,1,0,0,0,0,0},
 {15,15,15,15,15,6,6,13,13,13,13,13,5,5,5,5,5,5,5,5,5,5,1,1,1,0,0,0,0}
}

function fade(i)
	for c = 0, 15 do
		if flr(i+1) >= 30 then
			pal(c, 0)
		else
			pal(c, fadetable[c+1][flr(i+1)])
		end
	end
end

cam = {
	x = 0,
	y = 0,
	desired_y = 0,
	dx = 0,
	dy = 0,
	max_x = screen_width,
	max_y = 0,
	to_print = '',
	print = function(self, string)
		print(string, self.x, self.y, 7)
	end,
	set_scene = function(self, scene)
		self.scene = scene
		self.min_x = 0
		self.max_x = scene.width - screen_width
		self.max_y = scene.height - screen_height
		self.min_y = 0
	end,
	shake_counter = 0,
	shake = function(self)
		self.shake_counter = 10
	end,
	follow = function(self, following, follow_x_offset)
		self.following = following
		self.follow_x_offset = follow_x_offset
	end,
	in_view = function(self, object)
		return test_collision({
			x = self.x,
			y = self.y,
			width = screen_width,
			height = screen_height
		}, object)
	end,
	update_shake = function(self)
		if (self.shake_counter > 0) then
			self.shake_counter -= 1
			self.shake_x  = rnd(3)
			self.shake_y  = rnd(3)
		else
			self.shake_x  = 0
			self.shake_y  = 0
		end
	end,
	update_follow = function(self)
		if (not self.following) then
			return
		end
		local desired_x = self.following.x - self.follow_x_offset
		if (self.following.dx < 0) then
			desired_x = self.following.x - screen_width + self.follow_x_offset + self.following.width
		end

		if (desired_x < self.min_x) then
			desired_x = self.min_x
		elseif (desired_x > self.max_x) then
			desired_x = self.max_x
		end

		local diff = self.x - desired_x

		if (abs(diff) <= 3) then
			self.x = desired_x
		else
			self.dx = min(self.dx + 1, abs(self.following.dx) + 2)
			if (diff < 0) then
				self.x += self.dx
			else
				self.x -= self.dx
			end
		end

		if (self.following.dy == 0) then
			 self.desired_y = self.following.y - half_screen_height
		end

		local diff = self.y - self.desired_y

		if (abs(diff) <= 3) then
			self.y = self.desired_y
			self.desired_y = self.y
		else
			self.dy = min(self.dy + 1, abs(self.following.dy) + 2)
			if (diff < 0) then
				self.y += self.dy
			else
				self.y -= self.dy
			end
		end
	end,
	update = function(self)
		self:update_shake()
		self:update_follow()

		if (self.y < self.min_y) then
			self.y = self.min_y
		elseif(self.y > self.max_y) then
			self.y = self.max_y
		end
	end,
	set = function(self)
		camera(self.x + self.shake_x, self.y + self.shake_y)
	end
}

function make_scene(options)
	local o = {
		init = options.init,
		update = options.update,
		draw = options.draw
	}

	local scene = {
		init = function(self)
			cam:set_scene(self)
			self.objects = {}
			if (self.music) then
				music(self.music)
			else
				music(-1)
			end
			o.init(self)
		end,
		fade_update = function(self)
			if (self.fade_timer_dx) then
				fade(flr(self.fade_timer))
				self.fade_timer += self.fade_timer_dx
				if (self.fade_timer < 0 or self.fade_timer > (self.fade_max or 30)) then
					self.fade_timer_dx = false
					if (self.fade_callback) then
						self.fade_callback()
					end
				end
			end
		end,
		fade_down = function(self, fade_callback)
			self.fade_timer = 0
			self.fade_timer_dx = 1
			self.fade_max = 30
			self.fade_callback = fade_callback
		end,
		fade_up = function(self, fade_callback)
			self.fade_timer = 30
			self.fade_timer_dx = -1
			self.fade_callback = fade_callback
		end,
		add = function(self, object)
			if (object.init) then
				object:init()
			end
			add(self.objects, object)
		end,
		remove = function(self, object)
			del(self.objects, object)
		end,
		update = function(self)
			if (o.update) then
				o.update(self)
			end
			for object in all(self.objects) do
				if (object.update) then
					object:update()
				end
			end
			cam:update()
		end,
		draw = function(self)
			cls(0)
			self:fade_update()
			cam:set()
			if (o.draw) then
				o.draw(self)
			end
			for object in all(self.objects) do
				if (object.draw) then
					object:draw()
				end
			end
		end
	}
	return merge_tables(options, scene)
end

local changing_scene = false
function change_scene(scene)
	if (changing_scene) then
		return
	end
	changing_scene = true
	menuitem(1) -- remove reset level
	current_scene:fade_down(function()
		scene:init()
		current_scene = scene
		scene:fade_up()
		changing_scene = false
	end)
end

gravity = 1
min_speed=0.8
max_speed=1.5
acceleration=1.05
function make_player(scene)
	return {
		player = 0,
		x = 40,
		y = 120,
		width = 4,
		height = 8,
		dy = 0,
		dx = 0,
		dt = 0,
		default_sprite = 112,
		squating_sprite = 116,
		jumping_sprite = 115,
		moving_right_sprite = 113,
		jumping_right_sprite = 117,
		walk_cycle = {113,114},
		current_walk_sprite = 1,
		counter = 1,
		colliding_bottom = function(self, object, offset)
			return test_collision(object, {
				x = self.x,
				y = self.y,
				width = self.width,
				height = self.height + (offset or 1)
			})
		end,
		colliding_right = function(self, object, offset)
			return test_collision(object, {
				x = self.x,
				y = self.y,
				width = self.width + (offset or 1),
				height = self.height
			})
		end,
		colliding_left = function(self, object, offset)
			return test_collision(object, {
				x = self.x - (offset or 1),
				y = self.y,
				width = self.width,
				height = self.height
			})
		end,
		colliding_top = function(self, object, offset)
			return test_collision(object, {
				x = self.x,
				y = self.y - (offset or 1),
				width = self.width,
				height = self.height
			})
		end,
		colliding = function(self, object)
			return {
				top = self:colliding_top(object),
				right = self:colliding_right(object),
				bottom = self:colliding_bottom(object),
				left = self:colliding_left(object)
			}
		end,
		destroy = function(self)
			make_explosion(scene, self.x, self.y)
			scene:reset_level()
		end,
		update = function(self)
			self.squating = btn(3, self.player)
			if (btn(0, self.player)) then
				if (self.dx > -min_speed) then
					self.dx = -min_speed
				elseif (self.dx > -max_speed) then
					self.dx *= acceleration
				end
			elseif (btn(1, self.player)) then
				if (self.dx < min_speed) then
					self.dx = min_speed
				elseif (self.dx < max_speed) then
					self.dx *= acceleration
				end
			-- if velocity is above threshold but no button is being pushed decelerate
			elseif (abs(self.dx) > 0.2) then
				self.dx *= 0.75
			else
				self.dx = 0
			end

			local collision_x = scene:check_block_collision({
				x = self.x + self.dx,
				y = self.y,
				width = self.width,
				height = self.height
			})

			if (collision_x) then
				self.dx = 0
				-- sfx(2)
			else
				self.x += self.dx
			end

			if (self.x < 0) then
				self.x = 0
			elseif (self.x + self.width > scene.width) then
				self.x = scene.width - self.width
			end

			local ground_y = scene:get_ground(self)

			-- jumping
			if (btn(4, self.player) or btn(2, self.player)) then
				if (self.dy == 0) then
					sfx(2)
					self.dy = -0.8
				-- the longer you push jump the higher you will go
				elseif (self.dy < 0 and self.dy > -1.3) then
					self.dy *= 1.15
				end
			end

			-- in the air
			if (self.dy != 0 or self.y + self.height < ground_y) then
				self.dt += 1
				self.dy += gravity * (self.dt/frame_rate)
			end

			-- going up
			if (self.dy < 0) then
				local desired_y = flr(self.y + self.dy)
				local collision_y = scene:check_block_collision({
					x = self.x,
					y = desired_y,
					width = self.width,
					height = self.height
				})
				if (not collision_y) then
					self.y = desired_y
				else
					-- quick bounce back when you hit your head
					self.dy = 0.1
					-- sfx(2)
				end
			else
				self.y = flr(min(ground_y - self.height, self.y + self.dy))
			end

			if (self.y + self.height == ground_y) then
				self.dy = 0
				self.dt = 0
			end

			-- in the air
			if (self.y + self.height < ground_y) then
				if (self.dx > 0) then
					self.sprite = self.jumping_right_sprite
					self.flip_sprite = false
				elseif (self.dx < 0) then
					self.sprite = self.jumping_right_sprite
					self.flip_sprite = true
				else
					self.sprite = self.jumping_sprite
					self.flip_sprite = false
				end
			elseif (self.squating) then
				self.sprite = self.squating_sprite
				self.flip_sprite = false
			elseif (self.dx > 0) then
				self.sprite = self:get_next_walk_sprite()
				self.flip_sprite = false
			elseif (self.dx < 0) then
				self.sprite = self:get_next_walk_sprite()
				self.flip_sprite = true
			else
				self.sprite = self.default_sprite
				self.flip_sprite = false
			end
		end,
		draw = function(self)
			spr(self.sprite, self.x - 1, self.y, 1, 1, self.flip_sprite)
		end,
		get_next_walk_sprite = function(self)
			self.counter += 1
			if (self.counter % 5 == 0) then
				self.current_walk_sprite += 1
				if (self.current_walk_sprite > #self.walk_cycle) then
					self.current_walk_sprite = 1
				end
			end
			return self.walk_cycle[self.current_walk_sprite]
		end
	}
end



function make_explosion(scene, x, y)
	cam:shake()
	sfx(12)
	local make_particle = function(x, y)
		local particle_colors = { 6, 7, 9, 10 }
		local particle = {
			x = x - 4 + flr(rnd(8)),
			y = y - 4 + flr(rnd(8)),
			width = 5 + flr(rnd(8)),
			color = random_one(particle_colors),
			counter = 10 + flr(rnd(10)),
			dx = flr(rnd(3)) - 1.5,
			dy = flr(rnd(3)) - 1.5,
			dwidth = flr(rnd(3)) - 1.5,
			update = function(self)
				self.x += self.dx
				self.y += self.dy
				self.width += self.dwidth
				self.counter -= 1
				if (self.counter <= 0) then
					scene:remove(self)
				end
			end,
			draw = function(self)
				circfill(self.x, self.y, self.width / 2, self.color)
			end
		}
		scene:add(particle)
	end
	for i = 0, 50 do
		make_particle(x, y)
	end
end

function make_platform(x, y, w, h, directions, color_swatch)
	return {
		x = x,
		y = y,
		width = w,
		height = h,
		directions = directions,
		corner_size = 4,
		sliver_width = 2,
		sliver_height = 6,
		counter = 10,
		grow_delta = 2,
		should_grow = false,
		grow_speed = 3,
		color_swatch = color_swatch,
		available_slivers = {
			top = {
				{26, 0}, -- plain
				{48, 0}, -- dripping
				{50, 0},
				{52, 0},
				{54, 0},
			},
			bottom = {
				{26, 0}, -- plain
				{26, 0}, -- plain
				{40, 0}, -- spotted
				{42, 0},
				{44, 0},
				{46, 0}
			},
			left = {
				{64, 6}, -- plain
				{64, 6}, -- plain
				{56, 0}, -- spotted
				{56, 2},
				{56, 4},
				{56, 6}
			},
			right = {
				{104, 0}, -- shine
			},
		},
		slivers = {
			bottom = {},
			top = {},
			left = {},
			right = {}
		},
		init = function(self)
			-- populate slivers for width/height > (self.corner_size*2)
			if (self.width > (self.corner_size*2)) then
				local hor_number_slivers_to_create = (self.width - (self.corner_size*2)) / 2
				for i = 1, hor_number_slivers_to_create do
					add(self.slivers["top"], self:get_random_sliver("top"))
					add(self.slivers["bottom"], self:get_random_sliver("bottom"))
				end
			end
			if (self.height > (self.corner_size*2)) then
				local vert_number_slivers_to_create = (self.height - (self.corner_size*2)) / 2
				for i = 1, vert_number_slivers_to_create do
					add(self.slivers["right"], self:get_random_sliver("right"))
					add(self.slivers["left"], self:get_random_sliver("left"))
				end
			end

			local sprite_x = (self.color_swatch % 16) * 8
			local sprite_y = (ceil((self.color_swatch + 1) / 16) - 1) * 8
			self.border_color = sget(sprite_x, sprite_y)
			self.inside_color = sget(sprite_x + 1, sprite_y + 1)
		end,
		update = function(self)
			self.counter += 1
			if self.counter % self.grow_speed == 0 then
				if self.should_grow and self.counter % 10 == 0 then
					sfx(3)
				end

				if self.should_grow then
					self:grow()
				end
			end
		end,
		draw = function(self)
			pal(3, self.border_color)
			pal(11, self.inside_color)

			local center_x0 = self.x+self.corner_size
			local center_y0 = self.y+self.corner_size
			local center_x1 = center_x0 + self.width - (self.corner_size * 2)
			local center_y1 = center_y0 + self.height - (self.corner_size * 2)
			rectfill(center_x0, center_y0, center_x1, center_y1, 11)

			self:draw_slivers()
			self:draw_corners()

			pal(3, 3)
			pal(11, 11)
		end,
		draw_slivers = function(self)
			local draw_order = {'bottom', 'left', 'top', 'right'}
			for i, side in pairs(draw_order) do
				for j = 1, #self.slivers[side] do
					self:draw_sliver(side, j, self.slivers[side][j])
				end
			end
		end,
		draw_corners = function(self)
			local top_left = {x=88,y=0}
			local top_right = {x=92,y=0}
			local bottom_left = {x=88,y=4}
			local bottom_right = {x=92,y=4}

			-- top_left
			sspr(
				top_left.x,
				top_left.y,
				self.corner_size,
				self.corner_size,
				self.x,
				self.y,
				self.corner_size,
				self.corner_size
			)

			-- top_right
			sspr(
				top_right.x,
				top_right.y,
				self.corner_size,
				self.corner_size,
				self.x + self.width - self.corner_size,
				self.y,
				self.corner_size,
				self.corner_size
			)

			-- bottom_left
			sspr(
				bottom_left.x,
				bottom_left.y,
				self.corner_size,
				self.corner_size,
				self.x,
				self.y + self.height - self.corner_size,
				self.corner_size,
				self.corner_size
			)

			-- bottom_right
			sspr(
				bottom_right.x,
				bottom_right.y,
				self.corner_size,
				self.corner_size,
				self.x + self.width - self.corner_size,
				self.y + self.height - self.corner_size,
				self.corner_size,
				self.corner_size
			)
		end,
		get_random_sliver = function(self, side)
			local collection = self.available_slivers[side]
			local random_sliver_index = flr(rnd(#collection)) + 1
			return collection[random_sliver_index]
		end,
		make_sliver = function(self, side)
			add(self.slivers[side], self:get_random_sliver(side))
		end,
		draw_sliver = function(self, side, i, sliver)
			local spr_x = sliver[1]
			local spr_y = sliver[2]

			if (side == "top") then
				local x = self.x + self.corner_size + (self.grow_delta * (i - 1))
				sspr(spr_x, spr_y, self.sliver_width, self.sliver_height, x, self.y, self.sliver_width, self.sliver_height)
			end

			if (side == "bottom") then
				local x = self.x + self.corner_size + (self.grow_delta * (i - 1))
				local y = self.y + self.height - self.sliver_height
				sspr(spr_x, spr_y, self.sliver_width, self.sliver_height, x, y, self.sliver_width, self.sliver_height, false, true)
			end

			if (side == "left") then
				local x = self.x
				local y = self.y + self.corner_size + (self.grow_delta * (i - 1))
				sspr(spr_x, spr_y, self.sliver_height, self.sliver_width, x, y, self.sliver_height, self.sliver_width)
			end

			if (side == "right") then
				local x = self.x + self.width - self.sliver_height
				local y = self.y + self.corner_size + (self.grow_delta * (i - 1))
				sspr(spr_x, spr_y, self.sliver_height, self.sliver_width, x, y, self.sliver_height, self.sliver_width, true, false)
			end
		end,
		toggle_growth = function(self, toggle)
			self.should_grow = toggle
		end,
		touching_player = function(self, player)
			self.player = player
		end,
		grow = function(self)
			local grow_up = self.directions.up
			local grow_down = self.directions.down
			local grow_left = self.directions.left
			local grow_right = self.directions.right

			local d_height = 0
			local d_width = 0
			local dx = 0
			local dy = 0

			-- up and down directions
			if (grow_up or grow_down) then
				d_height = self.grow_delta
				self.height += d_height

				self:make_sliver("left")
				self:make_sliver("right")
			end
			if (grow_up and grow_down) then
				dy = self.grow_delta / 2
			elseif (grow_up) then
				dy = self.grow_delta
			end
			self.y -= dy

			-- left and right directions
			if (grow_left or grow_right) then
				d_width = self.grow_delta
				self.width += d_width

				self:make_sliver("top")
				self:make_sliver("bottom")
			end
			if (grow_left and grow_right) then
				dx = self.grow_delta / 2
			elseif (grow_left) then
				dx = self.grow_delta
			end
			self.x -= dx

			if (self.player) then
				local colliding = self.player:colliding(self)
				if (colliding.bottom and grow_up) then
					self.player.y -= dy
				elseif (colliding.left and grow_right) then
					self.player.x += dx
				elseif (colliding.right and grow_left) then
					self.player.x -= dx
				elseif (colliding.top and grow_down) then
					self.player.y += dy
				end
			end
		end
	}
end

tile_size = 8
function make_block(tile_id, x, y)
	return {
		x = x,
		y = y,
		width = tile_size,
		height = tile_size
	}
end

function make_chalice(x,y)
	return {
		x = x,
		y = y,
		width = 8,
		height = 8
	}
end

function make_door(x,y,current_level,player)
	return {
		x = x,
		y = y,
		width = 16,
		height = 16,
		update = function(self)
			if (test_collision(self, player)) then
				change_scene(make_game_scene(current_level+1))
			end
		end
	}
end

function make_game_scene(level)
	return make_scene({
		height = screen_height * 4,
		width = screen_width,
		music = 3,
		background_tile = 53,
		needs_background = {},
		paint_background = function(self, x, y)
			add(self.needs_background, { x = x, y = y})
		end,
		get_ground = function(self, player)
			local ground
			for block in all(self.blocks) do
				if (not ground and test_collision(block, {
					x = player.x,
					y = player.y + player.height,
					width = player.width,
					height = 3
				})) then
					ground = block.y
				end
			end
			return ground or self.height
		end,
		check_block_collision = function(self, player)
			for block in all(self.blocks) do
				if (test_collision(block, player)) then
					return true
				end
			end
		end,
		check_to_grow = function(self)
			for platform in all(self.platforms) do
				local player = self.player
				local is_touching = test_collision(platform, {
					x = player.x - 1,
					y = player.y - 1,
					width = player.width + 2,
					height = player.height + 2
				})
				platform:toggle_growth(is_touching)
				platform:touching_player(is_touching and player or nil)
				self.is_touching = is_touching
			end
		end,
		check_for_death = function(self)
			local is_top = false
			local is_right = false
			local is_bottom = false
			local is_left = false
			for block in all(self.blocks) do
				if (test_collision(block, self.player)) then
					if (not is_left and self.player:colliding_left(block, 0)) then
						is_left = true
					end
					if (not is_right and self.player:colliding_right(block, 0)) then
						is_right = true
					end
					if (not is_top and self.player:colliding_top(block, 0)) then
						is_top = true
					end
					if (not is_bottom and self.player:colliding_bottom(block, 0)) then
						is_bottom = true
					end
				end
			end

			-- function s(c, bool)
			-- 	return bool and c..':t ' or c..':f '
			-- end

			-- cam.to_print = s('t',is_top)..s('r',is_right)..s('b',is_bottom)..s('l',is_left)

			if ((is_left and is_right) or (is_top and is_bottom)) then
				if (self.trigger_death and not self.is_dying) then
					-- only kill player if squashed for 2 frames
					self:kill_player()
				end
				self.trigger_death = true
			else
				self.trigger_death = false
			end
		end,
		kill_player = function(self)
			self.player:destroy()
			self.is_dying = true
		end,
		form_platform = function(self, map_x, map_y)
			function is_behavior(tile_id)
				return (tile_id >= 32 and tile_id <= 46)
			end

			function is_appearance(tile_id)
				return tile_id == 48 or (tile_id >= 87 and tile_id <= 93)
			end

			function is_platform(tile_id)
				return is_behavior(tile_id) or is_appearance(tile_id)
			end

			self.visited = self.visited or {}
			local tile_id = mget(map_x,map_y)
			if(not is_platform(tile_id) or self.visited[map_x..','..map_y]) then
				return
			end

			local left_x = map_x
			local top_y = map_y
			local right_x = map_x
			local bottom_y = map_y
			local behavior
			local platform_sprite

			function visit_adjacent(map_x, map_y)
				visit(map_x,map_y-1)
				visit(map_x,map_y+1)
				visit(map_x+1,map_y)
				visit(map_x-1,map_y)
			end

			function visit (map_x, map_y)
				local key = map_x..','..map_y
				if (self.visited[key]) then
					return
				else
					self.visited[key] = true
					local tile_id = mget(map_x,map_y)
					if(is_platform(tile_id)) then
						platform_sprite = tile_id
						left_x = map_x < left_x and map_x or left_x
						right_x = map_x > right_x and map_x or right_x
						top_y = map_y < top_y and map_y or top_y
						bottom_y = map_y > bottom_y and map_y or bottom_y
						if (not behavior and is_behavior(tile_id)) then
							behavior = tile_id
						end
						self:paint_background(map_x*tile_size - self.level_x_offset, map_y*tile_size)
						visit_adjacent(map_x, map_y)
					end
				end
			end

			visit(map_x, map_y)

			local x = left_x * tile_size
			local y = top_y * tile_size
			local width = (right_x - left_x) * tile_size + tile_size
			local height = (bottom_y - top_y) * tile_size + tile_size

			local up = fget(behavior, 0)
			local right = fget(behavior, 1)
			local down = fget(behavior, 2)
			local left = fget(behavior, 3)

			local platform = make_platform(x - self.level_x_offset,y,width,height,{ up = up, down = down, right = right, left = left }, tile_id)
			return platform
		end,
		check_for_win = function(self)
			if (self.chalice and test_collision(self.player, self.chalice)) then
				change_scene(winning_scene)
			end
		end,
		reset_level = function(self)
			change_scene(make_game_scene(level))
		end,
		init = function(self)
			menuitem(1, "restart level", self.reset_level)

			self.blocks = {}
			self.platforms = {}
			local level_width = screen_width
			local level_height = screen_height * 4

			self.player = make_player(self)
			self.level_x_offset = level * level_width
			for x = self.level_x_offset, (self.level_x_offset + level_width), tile_size do
				for y = 0, level_height, tile_size do
					local map_x = x / tile_size
					local map_y = y / tile_size
					local tile_id = mget(map_x, map_y)
					if (fget(tile_id, 7)) then
						local block = make_block(tile_id, x - self.level_x_offset, y)
						self:add(block)
						add(self.blocks, block)
					elseif (tile_id == 68) then
						local door = make_door(x - self.level_x_offset, y, level, self.player)
						self:add(door)
					elseif (tile_id == 86) then
						self.player.x = x + 2 - self.level_x_offset
						self.player.y = y
						self.player.dy = 1 -- falling
					elseif (tile_id == 71) then
						self.chalice = make_chalice(x - self.level_x_offset,y)
					else
						local platform = self:form_platform(map_x, map_y)
						if (platform) then
							self:add(platform)
							add(self.blocks, platform)
							add(self.platforms, platform)
						end
					end
				end
			end

			cam.y = self.height - screen_height
			cam:follow(self.player, 20)
			self:add(self.player)
		end,
		update = function(self)
			self:check_to_grow()
			self:check_for_death()
			self:check_for_win()
		end,
		draw = function(self)
			self:fade_update()
			palt(0, false)
			map(self.level_x_offset / tile_size, 0, 0, 0, self.width / tile_size, self.height / tile_size)
			for bg in all(self.needs_background) do
				spr(self.background_tile, bg.x, bg.y)
			end
			palt(0, true)
			cam:print(cam.to_print)
		end,
	})
end

function checker_board(scene)
	local size = 16
	for y = 0, scene.height / size do
		for x = 0, scene.width / size do
			local x_odd = x % 2 == 0
			local y_odd = y % 2 == 0
			local color = x_odd and 5 or 6
			if (y_odd) then
				color = x_odd and 6 or 5
			end
			local start_x = x * size
			local start_y = y * size
			rectfill(start_x, start_y, start_x + size, start_y + size, color)
			print(start_y, start_x, start_y, 10)
		end
	end
end

local title_screen_text = {
	letter_width = 4,
	letter_height = 6,
	border_buffer = 6,
	draw = function(self)
		local texts = {
			jon = {text="jon koon",x,y},
			rusty = {text="rusty bailey",x,y},
			ld42 = {text="ludum dare 42",x,y}
		}

		texts.rusty.x = self.border_buffer
		texts.rusty.y = screen_height - self.letter_height - self.border_buffer
		texts.jon.x = texts.rusty.x
		texts.jon.y = texts.rusty.y - self.letter_height

		texts.ld42.x = screen_width - (#texts.ld42.text * self.letter_width) - self.border_buffer
		texts.ld42.y = texts.rusty.y

		for key, value in pairs(texts) do
			print(texts[key].text, texts[key].x, texts[key].y, 7)
		end
	end
}

make_start_prompt = function(y,text)
	return {
		y = y,
		height = 4,
		init = function(self)
			self.text = text or "press ❎ or 🅾️ to start"
			self.width = (#self.text) * 4 + 4
			self.x = (screen_width - self.width) / 2
			self.timer = 60
		end,
		update = function(self)
			self.timer -= 1
			if (self.timer < -20) then
				self.timer = 60
			end
			if (btn(4) or btn(5)) then
				change_scene(make_game_scene(0))
			end
		end,
		draw = function(self)
			if (self.timer > 0) then
				print(self.text, self.x, self.y, 7)
			end
		end
	}
end

title_scene = make_scene({
	height = screen_height,
	width = screen_width,
	music = 10,
	draw = function(self)
		cls(1)
	end,
	init = function(self)
		self:add(title_screen_text)
		self:add(make_start_prompt(64))
	end
})

local you_won = {
	y = 35,
	height = 4,
	init = function(self)
		self.text = "you're a winner"
		self.width = (#self.text) * 4
		self.x = (screen_width - self.width) / 2
	end,
	draw = function(self)
		palt(1, true)
		spr(71, screen_width / 2 - 4, self.y)
		palt(1, false)
		print(self.text, self.x, self.y + 15, 7)
	end
}

winning_scene = make_scene({
	height = screen_height,
	width = screen_width,
	music = 8,
	draw = function(self)
		cls(1)
	end,
	init = function(self)
		self:add(you_won)
		self:add(make_start_prompt(70, "press ❎ or 🅾️ to play again"))
	end
})

current_scene = title_scene
-- current_scene = make_game_scene(0)
-- current_scene = winning_scene

function _init()
	current_scene:init()
end

function _update60()
	if (stop) then
		return
	end

	current_scene:update()
end

function _draw()
	if (stop) then
		return
	end

	current_scene:draw()
end
__gfx__
000000000000033333333333003333330003333333333333333333333bbbb6bb3bbbbbbb003333330033330000333300333333003b7bbbbb0000000000000000
0000000000003bbbbbbbbbbb03bbbbbb003bbbbbbbbbbbbb3b3b3b3b3bbbbbbb3bbbbbbb03bbbbbb03bbbb3003bbbb30bbbbbb303b7bbbbb0000000000000000
007007000003bbbbbb7bbbbb3bbbbbbb03bbbbbbb6bbbbbb3b3b3bbb3bbb6bbb3bbbbbbb3bbbbbbb3bbbbbb33bbb7bb3bbbbbbb33b7bbbbb0000000000000000
00077000003bbbbbbbbbbb7b3bbbbbbb3bbbbbbbbbb6bbbb3b3bbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbb33bbbb7b3bbbbbbb33b7bbbbb0000000000000000
0007700003bbbbbbbb7bbbbb3bbbbbbb3bbbbbbbbbbbb6bb3bbbbbbb3bb6bbbb3bbbbbbb3bbbbbbb3bbbbbb33bbbbbb3bbbbbbb33b7bbbbb0000000000000000
007007003bbbbbbbbb7bbb7b3bbbbbbb3bbbbbbbbbbbbbb6bbbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbb33bbbbbb3bbbbbbb33b7bbbbb0000000000000000
000000003bbbbbbbbbbbbb7b3bbbbbbb3bbbbbbbbbbbbbbbbbbbbbbb3b6bbbbb3bbbbbbb03bbbbbb3bbbbbb303bbbb30bbbbbb303b7bbbbb0000000000000000
000000003bbbbbbbbbbbbbbb3bbbbbbb3bbbbbbbbbbbbbbbbbbbbbbb3bbbbbbb3bbbbbbb003333333bbbbbb300333300333333003b7bbbbb0000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00200000000000000002000000200000000000200002000000000200000000000000000000000000000000000000000000000000000000000000000000000000
000e220000000000000e2200000e2200000e2200000e2200000e2200000000000000000000000000000000000000000000000000000000000000000000000000
0007f700002e220000f7f7f0000ff7000007ff00000ff7000007ff00000000000000000000000000000000000000000000000000000000000000000000000000
000fff000007f700002fff20000fff00000fff00000fff00000fff00000000000000000000000000000000000000000000000000000000000000000000000000
00fdedf0002fff20002ded2000fded00000dedf000fded00000dedf0000000000000000000000000000000000000000000000000000000000000000000000000
000ddd00002ded20000ddd00000ddd00000ddd00000ddd00000ddd00000000000000000000000000000000000000000000000000000000000000000000000000
000d0d0000fdddf0000d0d00000d0d00000d0d00000d0d00000d0d00000000000000000000000000000000000000000000000000000000000000000000000000
66655666665555666665556666555666666666666665566666656666666656666666666666666666666566666666566666666666665756666665666600000000
66577566665775666657756666577566665665666657756666575666666575666656666666666566665756666665756666566656657775666657566600000000
65777756555775556577555555557756657557566577775665777566665777566575566666655756657775666657775665755575665757566577756600000000
57777775575775755777777557777775577777756657756657575756657575665777756666577775665757566575756657777777665777755757575600000000
57577575577777755777777557777775577777756657756677777775577775666575756666575756665777755777756665757575665757567777777500000000
55577555657777566577555555557756657557566577775657575756657556666657775665777566666557566575756666577756657775665755575600000000
66577566665775666657756666577566665665666657756665777566665666666665756666575666666665666657775666657566665756666566656600000000
66555566666556666665556666555666666666666665566666575666666666666666566666656666666666666665756666665666666566666666666600000000
333333335555555577777776ddddddd2222222251111111111111101111991111111111111111111711711711711711719999111119991110000000000000000
3bbbbbb3566666657cccccc1d1111110211111101001111111111001119999111119911111111111171711711711717111999111119999110000000000000000
3bbbbbb3566666657cccccc1d1111110211111101100011111110011199aa991119aa911111aa1111171777117771711199a9911199aa9110000000000000000
3bbbbbb3566666657cccccc1d1111110211111101111111111100011119999111119911111199111771711711711717711999911119999110000000000000000
3bbbbbb3566666657cccccc1d1111110211111101111000111011001555555555555555555555555117171711717171155555555555555550000000000000000
3bbbbbb3566666657cccccc1d1111110211111101101111110011101125555311255553112555531117117711771171112555531125555310000000000000000
3bbbbbb3566666657cccccc1d1111110211111101000011110001111112553111125531111255311777777777777777711255311112553110000000000000000
33333333555555556111111120000000500000001111111111101111111231111112311111123111111111711711111111123111111231110000000000000000
00000000000000000000000000000000111111111111111100000000111111110000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000111111111111111100000000aaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000033322222222223339aaaaaaa19aaaaa10000000000000000000000000000000000000000000000000000000000000000
02111111111111200211111111111120393229222292239309aaaaa0119aaa110000000000000000000000000000000000000000000000000000000000000000
221111111111112222111111111111223332222222222333009aaa001119a1110000000000000000000000000000000000000000000000000000000000000000
1100000000006611110000000000001121200000000002120009a0001119a1110000000000000000000000000000000000000000000000000000000000000000
1100000000077711110000000000001121200000000072120009a000119aaa110000000000000000000000000000000000000000000000000000000000000000
110000000066661111000000000000112120000000066212099aaaa019aaaaa10000000000000000000000000000000000000000000000000000000000000000
11000000077777111100000000000011212000000077721211677611333333338888888855555555111111112222222299999999ffffffff0000000000000000
110000006666661111000000000000112120000006666212170000713bbbbbb3899999985eeeeee51cccccc12dddddd29aaaaaa9f777777f0000000000000000
110000077777771111000000000077112120000077777212600000063bbbbbb3899999985eeeeee51cccccc12dddddd29aaaaaa9f777777f0000000000000000
110000666666661111000000006666112120000666666212700000073bbbbbb3899999985eeeeee51cccccc12dddddd29aaaaaa9f777777f0000000000000000
110007777777771111000000777777112120007777777212600000063bbbbbb3899999985eeeeee51cccccc12dddddd29aaaaaa9f777777f0000000000000000
110066666666661111000066666666112120066666666212700000073bbbbbb3899999985eeeeee51cccccc12dddddd29aaaaaa9f777777f0000000000000000
110777777777771111007777777777112120777777777212600000063bbbbbb3899999985eeeeee51cccccc12dddddd29aaaaaa9f777777f0000000000000000
11666666666666111166666666666611212666666666621270000007333333338888888855555555111111112222222299999999ffffffff0000000000000000
00c0c00000c0c00000c0c00000c0c0000c0c00000c0c000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00c0c00000c0c00000c0c00000c0c00000c0c00000c0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000
00cccc0000cccc0000cccc0000cccc0000cccc0000cccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000
00c7c70000c7c70000c7c70000c7c70000c7c70000c7c70000000000000000000000000000000000000000000000000000000000000000000000000000000000
00cccc0000cccc0000cccc0000cccc0000cccc0000cccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000
064440000c444c000044400000444000004440000044400000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c466c000ca4a00000a4ac0000a4a00000a4ac000ca4a00000000000000000000000000000000000000000000000000000000000000000000000000000000000
00c0c0000000c00000c0000000c0c00000c000000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000
00c0c00000c0c00000c0c00000c0c000000000000c0c000000c0c000000000000000000000000000000000000000000000000000000000000000000000000000
00c0c00000c0c00000c0c00000c0c00000c0c00000c0c00000c0c000000000000000000000000000000000000000000000000000000000000000000000000000
00ccc00000cccc0000cccc0000ccc00000c0c00000cccc0000ccc000000000000000000000000000000000000000000000000000000000000000000000000000
007c700000c7c70000c7c7000c7c7c0000ccc00000c7c700007c7000000000000000000000000000000000000000000000000000000000000000000000000000
006e600000c66e0000c66e000c6e6c00007c700000c66ec00c6e6c00000000000000000000000000000000000000000000000000000000000000000000000000
0d555d000d5550000d5550000d555d00006e60000d555d000d555d00000000000000000000000000000000000000000000000000000000000000000000000000
0cd5dc000c5ddc000c5ddc0000d5d0000d555d000c5dd00000d5d000000000000000000000000000000000000000000000000000000000000000000000000000
00c0c00000c000000000c00000c0c0000cd5dc0000c0c00000c0c000000000000000000000000000000000000000000000000000000000000000000000000000
33535353535353535353535353535333335353735333335353333353735353333353535353535353535353535353533300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3375a2a2a25353535353537572727233335353535353535353535353535353333353535353535353536353535353533300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333353535353535353535353333333335353333333333333333333335353333353535353535353535353535353533300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33535353535363535353535353535333335353535353535353535353535353333353535353535353536353535353533300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33535353535353535353535363535333335353535353535353635353536353333353535353535353535353535353533300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
75424242424253535353754242424242335353536353535353535353535353333353535353535353536353535353533300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42424242424253535353424242424242335353535353536353535353635353333353535353535353535353535353533300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42424242424253535353424242424242335363535353535353635353535353333353535353535353536353535353533300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42424242424253535353424242424242335353535353535353535353535353333353535353535353535353535353533300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42424242424253535353424242424242335353535353535353535353535353333353535353535353536353535353533300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42424242424253535353424242424242335353536353535353535353635353333353535353535353535353535353533300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33a36353535353535353535353535333335353535353535353535353535353333353535353535353536353535353533300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33535353535353535353535363535333335353535353536353535353535353333353535353535353535353535353533300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33535353535353536353535353535333335353535353535353535353535353333353535353535353536353535353533300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3353536353535353535353535353533333535353635385e2e2e25353535353333353535353535353535353535353533300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33535353535353535353535353535333335353535353e2e2e2e25353536353333353535353535353536353535353533300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33535353535353535353635353735333335353535353333333335353535353333353535353535353537353535353533300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33535353536353535353535353535333335353535353535353535353535353333353535353535353536353535353533300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33535353535353535353535375727233335353536353535353635353535353333353535353535353635363635353533300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
335373535353535353535353533333333353535353535353535353535353533333b5625353535353536353535353533300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3353535353536353535353535353b333335353535353535353535353535353333333333333333333333333335353533300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33753232535353535353535353535333335373535353535353535353537353333353535353535353536353535353533300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333353535353536353535353635333335353535353535353535353535353333353535353535353535353535353533300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33a35353537353535353535353535333338512125353536353535353850202333353535353535353b5b5b5b553b5b53300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33536353535353535353635353535333333333335353535353535353333333333353535353535353b502b5b55352523300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3353535333333353535353536353533333a3535353535353535353535353b3333353535353535353333333333333333300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
335353535353535353535353535353333353536353533333333353535363533333b5b59253535353535353535353533300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333353535363535353535353535333335353535353535353535353535353333333333333535353535353535353533300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333353535353535353535353535333335353535353535353635353535353333353535353535353535353535353533300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333353535353635353535353535333335353535363535353535353735353333353535353535353536353535353533300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333353655353535375222253535333335385020253536553535353535353333353535353655353533333535353533300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333300000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000010408020a050f090c06030d0e070b000000808080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000033000033000033000033000033000033330000330000330000330000330000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000033333333333333333333333333333333333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000033333333333333333333333333333333333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000033353535353535353535353535353533333535353535353535353535353535330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000033353535353635353535353535363533333535353536353535353535353635330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000033353535353535353535353535353533333535353535353535353535353535330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000033444535353535353535353535353533334445353535353535353535353535330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3300003300003300003300003300003333545535353535353635353535353533335455353535353536353535353535330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3333333333333333333333333333333333333333333535353535353635353533333333333335353535353536353535330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333333333333333333333333333a3535353535353535353535353533333535353535353535353535353535330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3335353535353535353535353535353333353535353535353535353535353533333535353535353535363535353535330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3335353535363535353535353536353333353535363533353535353535353633333535353535353535353535353535330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3335353535353535353535353535353333353535353535582a35353535353533333535353535353535363535353535330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3335363535353544453535353535353333353535353535353335353535353533333535353535353535363535353535330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3335353535353554553535353535353333353535353535353535353535353533333535353535353535363535353535330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3335353533333333333333333535363333353535363535353635333535353533333535353535353535353535353535330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3336353535353535353535353535353333353535353535353535353535363533333535353535353535363535353535330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3335353535353535363535353535353333353535353535353535353535353533333535353535353535353535353535330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3335373535353535353535353537353333353535355821212121213535353533333535353535353535363535353535330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010c0004105570f55710557145571e500005003550035500355001850035500355003550035500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
010500001105323000230002300028000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800001e55723507005070050700507005070050700507005070050700507005070050700507005070050700507005070050700507005070050700507005070050700507005070050700507005070050700507
0110000007550095500b5502250007500095000b50000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
001000000f0500f0500f0500f0500f05011050130501305016050160501605016050160501805018050180501b0501b0501b0501b0501b0501b0501d0501d0501f0501f0501f0501f05022050220502205022050
011000001d0511d0511d0511d0511d0511b0501b0501b050180501805018050130511105111050110501105011050110501305016050180501b0501d0501f0502205024050270512705127051270512405124051
011000202405524055240551f0551b0551805516055160551605516055180551f0552705527055270552705527055220551b05518055240552405524055240551b0551805522055220551b055180551b05518055
001000001d0501e0501e05020050210502205023050250502a0522a0522a0522a0002a0002c0002d0002e0002f000310003600036000000000000000000000000000000000000000000000000000000000000000
011000101904300000276450000019043000002764500000190430000027645276451904319043276450000019033000002763500000190530000027655000001905300000276552765519053190532765500000
001000000f05000000190500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002405500000240550000024055000002405500000240550000024055240552405524055240550000030055000003005500000300550000030055000003005500000300553005530055300553005500000
011000002705500000270550000027055000002705500000270550000027055270552705527055270550000033055000003305500000330550000033055000003305500000330553305533055330553305500000
01080000226531f6531d6401b63019620166101361005603006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603
010800002265319620166101361005603006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603000000000000000
001000100c055130551b0550c0551b0550e0550c0550c0550c0550e05512055160551b0550c0551b0550c0550f005120050000500005000050000500005000050000500005000050000500005000050000500005
001000000f5551e5001e55500505115550f5550850514551165511655116551005001955514555105550c55500505005050050500505005050050500505005050050500505005050050500505005050050500505
00200b0022552225521d5521d552225522455227552295522b5522455224552265522b55224552245522455224552275522b5522755224552225521d552185521d555165551d5551655518555075520a5520c552
002000000f5520f5520f5520f552185521855218552185520f5520f5520f5520f5521d5521d5521d5521d5520f5520f5520f5520f552225522255222552225521f5521f5521f5521f5521b5521b5521b5521b552
__music__
01 04064344
02 05064344
00 47424344
01 08044344
00 08054344
00 080a4444
02 080b4344
00 41424344
00 07424344
00 41424344
01 060e1051
00 060e1151
02 060e0a0b

