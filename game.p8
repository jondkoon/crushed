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

cam = {
	x = 0,
	y = 0,
	desired_y = 0,
	dx = 0,
	dy = 0,
	max_x = screen_width,
	max_y = 0,
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
			for object in all(self.objects) do
				if (object.update) then
					object:update()
				end
			end
			cam:update()
			if (o.update) then
				o.update(self)
			end
		end,
		draw = function(self)
			cls(0)
			cam:set()
			if (o.draw) then
				o.draw(self)
			end
			for object in all(self.objects) do
				object:draw()
			end
		end
	}
	return merge_tables(options, scene)
end

function change_scene(scene)
	scene:init()
	current_scene = scene
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
		width = 3,
		height = 6,
		dy = 0,
		dx = 0,
		dt = 0,
		default_sprite = 16,
		squating_sprite = 17,
		jumping_sprite = 18,
		moving_right_sprite = 19,
		moving_left_sprite = 20,
		jumping_right_sprite = 21,
		jumping_left_sprite = 22,
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

			local ground_y = scene:get_ground(self)

			-- jumping
			if (btn(2, self.player)) then
				if (self.y + self.height == ground_y) then
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

			local collision_x = scene:check_block_collision({
				x = self.x + self.dx,
				y = self.y,
				width = self.width,
				height = self.height
			})

			if (collision_x) then
				self.dx = 0
			else
				self.x += self.dx
			end

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
				end
			else
				self.y = flr(min(ground_y - self.height, self.y + self.dy))
			end

			if (self.y + self.height == ground_y) then
				self.dy = 0
				self.dt = 0
			end

			if (self.x < 0) then
				self.x = 0
			elseif (self.x + self.width > scene.width) then
				self.x = scene.width - self.width
			end

			-- in the air
			if (self.y + self.height < ground_y) then
				if (self.dx > 0) then
					self.sprite = self.jumping_right_sprite
				elseif (self.dx < 0) then
					self.sprite = self.jumping_left_sprite
				else
					self.sprite = self.jumping_sprite
				end
			elseif (self.squating) then
				self.sprite = self.squating_sprite
			elseif (self.dx > 0) then
				self.sprite = self.moving_right_sprite
			elseif (self.dx < 0) then
				self.sprite = self.moving_left_sprite
			else
				self.sprite = self.default_sprite
			end
		end,
		draw = function(self)
			spr(self.sprite, self.x - 3, self.y - 2)
		end
	}
end

tile_size = 8
function make_block(tile_id, x, y)
	return {
		x = x,
		y = y,
		width = tile_size,
		height = tile_size,
		update = function(self)
			self.y -= 0.5
		end,
		draw = function(self)
			spr(tile_id, self.x, self.y)
		end
	}
end

function make_explosion(scene, x, y)
	cam:shake()
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
	for i = 0, 10 do
		make_particle(x, y)
	end
end

function make_platform(x, y, w, h, directions)
	return {
		x = x,
		y = y,
		width = w,
		height = h,
		directions = directions,
		corner_size = 4,
		sliver_width = 2,
		sliver_height = 6,
		counter = 1,
		grow_delta = 2,
		should_grow = false,
		grow_speed = 3,
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
		end,
		update = function(self)
			self.counter += 1
			if self.counter % self.grow_speed == 0 then
				if self.should_grow then
					self:grow()
				end
			end
		end,
		draw = function(self)
			-- bounding box
			-- rect(self.x, self.y, self.x + self.width - 1, self.y + self.height - 1, 7)

			-- center area
			local center_x0 = self.x+self.corner_size
			local center_y0 = self.y+self.corner_size
			local center_x1 = center_x0 + self.width - (self.corner_size * 2)
			local center_y1 = center_y0 + self.height - (self.corner_size * 2)
			rectfill(center_x0, center_y0, center_x1, center_y1, 11)

			-- slivers
			self:draw_slivers()

			-- corners
			self:draw_corners()

			-- debug
			-- print(self.should_grow, 100, 100)
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
		grow = function(self)
			local grow_up = self.directions.up
			local grow_down = self.directions.down
			local grow_left = self.directions.left
			local grow_right = self.directions.right

			-- up and down directions
			if (grow_up or grow_down) then
				self.height += self.grow_delta

				self:make_sliver("left")
				self:make_sliver("right")
			end
			if (grow_up and grow_down) then
				self.y -= self.grow_delta / 2
			elseif (grow_up) then
				self.y -= self.grow_delta
			end

			-- left and right directions
			if (grow_left or grow_right) then
				self.width += self.grow_delta

				self:make_sliver("top")
				self:make_sliver("bottom")
			end
			if (grow_left and grow_right) then
				self.x -= self.grow_delta / 2
			elseif (grow_left) then
				self.x -= self.grow_delta
			end
		end
	}
end

game_scene = make_scene({
	height = screen_height * 4,
	width = screen_width,
	get_ground = function(self, player)
		local ground
		for block in all(self.blocks) do
			if (not ground and test_collision(block, {
				x = player.x,
				y = player.y + 2,
				width = player.width,
				height = player.height
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
	check_for_death = function(self, player)

	end,
	init = function(self)
		self.blocks = {}
		local level_width = screen_width
		local level_height = screen_height * 4

		local player = make_player(self)
		for x = 0, level_width, tile_size do
			for y = 0, level_height, tile_size do
				local tile_id = mget(x / tile_size,y / tile_size)
				if (tile_id == 49) then
					local block = make_block(tile_id, x, y)
					self:add(block)
					add(self.blocks, block)
				end
				if (tile_id == 16) then
					player.x = x
					player.y = y
					player.dy = 1 -- falling
				end
			end
		end

		cam.y = self.height - screen_height

		cam:follow(player, 20)
		self:add(player)
	end,
	update = function(self)
	end,
	draw = function(self)
		local size = 16
		for y = 0, self.height / size do
			for x = 0, self.width / size do
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
	end,
})

local title = {
	y = 40,
	height = 4,
	init = function(self)
		self.text = "crushed"
		self.width = (#self.text + 2) * 4
		self.x = (screen_width - self.width) / 2
	end,
	draw = function(self)
		print(self.text, self.x, self.y, 7)
	end
}

local start_prompt = {
	y = title.y + title.height + 20,
	height = 4,
	init = function(self)
		self.text = "press ❎ or 🅾️ to start"
		self.width = (#self.text + 2) * 4
		self.x = (screen_width - self.width) / 2
		self.timer = 60
	end,
	update = function(self)
		self.timer -= 1
		if (self.timer < -20) then
			self.timer = 60
		end
		if (btn(4) or btn(5)) then
			change_scene(game_scene)
		end
	end,
	draw = function(self)
		if (self.timer > 0) then
			print(self.text, self.x, self.y, 7)
		end
	end
}

title_scene = make_scene({
	height = screen_height,
	width = screen_width,
	music = 5,
	init = function(self)
		self:add(title)
		self:add(start_prompt)
	end
})

current_scene = title_scene
-- current_scene = game_scene

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
66655666665555666665556666555666666666666665566666656666000000000000000000000000000000000000000000000000000000000000000000000000
66577566665775666657756666577566665665666657756666575666000000000000000000000000000000000000000000000000000000000000000000000000
65777756555775556577555555557756657557566577775665777566000000000000000000000000000000000000000000000000000000000000000000000000
57777775575775755777777557777775577777756657756657575756000000000000000000000000000000000000000000000000000000000000000000000000
57577575577777755777777557777775577777756657756677777775000000000000000000000000000000000000000000000000000000000000000000000000
55577555657777566577555555557756657557566577775657575756000000000000000000000000000000000000000000000000000000000000000000000000
66577566665775666657756666577566665665666657756665777566000000000000000000000000000000000000000000000000000000000000000000000000
66555566666556666665556666555666666666666665566666575666000000000000000000000000000000000000000000000000000000000000000000000000
33333333555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbbbbb3566666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbbbbb3566666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbbbbb3566666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbbbbb3566666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbbbbb3566666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbbbbb3566666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
13130000000000131300000000001313000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
13130000000000000000035203001313000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
13130000010000000000000000001313000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
13131313131313131313131313131313000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
