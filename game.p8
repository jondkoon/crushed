pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

screen_width = 128
half_screen_width = screen_width / 2

screen_height = 128
half_screen_height = screen_height / 2

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

cam = {
	x = 0,
	y = 0,
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

		desired_y = self.following.y-half_screen_height
		self.y = desired_y
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
	return {
		height = options.height,
		width = options.width,
		music = options.music,
		init = function(self)
			cam:set_scene(self)
			self.objects = {}
			if (self.music) then
				music(self.music)
			else
				music(-1)
			end
			options.init(self)
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
			if (options.update) then
				options.update(self)
			end
		end,
		draw = function(self)
			cls(0)
			cam:set()
			if (options.draw) then
				options.draw(self)
			end
			for object in all(self.objects) do
				object:draw()
			end
		end
	}
end

function change_scene(scene)
	scene:init()
	current_scene = scene
end

frame_rate = 60
ground_y = screen_height
gravity = 1
calculate_position = function(t)
	if (not t.dt) then
		t.dt = 0 -- delta time
	end

	if (t.dy != 0) then
		t.dt += 1
		t.dy += gravity * (t.dt/frame_rate)
	end

	t.y = flr(min(ground_y - t.height, t.y + t.dy))
	t.x += t.dx
	
	if (t.y + t.height == ground_y) then
		t.dy = 0
		t.dt = 0
	end
end

min_speed=0.8
max_speed=1.5
acceleration=1.05
function make_player(scene)
	return {
		player = 0,
		x = 40,
		y = 120,
		width = 8,
		height = 8,
		dy = 0,
		dx = 0,
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

			local bottom_y = self.y + self.height

			-- jumping
			if (btn(2, self.player)) then
				if (bottom_y == ground_y) then
					self.dy = -0.8
				-- the longer you push jump the higher you will go
				elseif (self.dy < 0 and self.dy > -1.3) then
					self.dy *= 1.15
				end
			end

			calculate_position(self)

			if (self.x < -2) then
				self.x = -2
			elseif (self.x > screen_width) then
				self.x = screen_width
			end

			-- in the air
			if (bottom_y < ground_y) then
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
			spr(self.sprite, self.x, self.y)
		end
	}
end

game_scene = make_scene({
	height = screen_height,
	width = screen_width * 10,
	init = function(self)
		local player = make_player(self)
		self:add(player)
	end,
	update = function(self)
	end,
	draw = function(self)
		local size = 8
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

-- current_scene = title_scene
current_scene = game_scene

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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00200000000000000002000000200000000000200002000000000200000000000000000000000000000000000000000000000000000000000000000000000000
000e220000000000000e2200000e2200000e2200000e2200000e2200000000000000000000000000000000000000000000000000000000000000000000000000
0007f700002e220000f7f7f0000ff7000007ff00000ff7000007ff00000000000000000000000000000000000000000000000000000000000000000000000000
000fff000007f700002fff20000fff00000fff00000fff00000fff00000000000000000000000000000000000000000000000000000000000000000000000000
00fdedf0002fff20002ded2000fded00000dedf000fded00000dedf0000000000000000000000000000000000000000000000000000000000000000000000000
000ddd00002ded20000ddd00000ddd00000ddd00000ddd00000ddd00000000000000000000000000000000000000000000000000000000000000000000000000
000d0d0000fdddf0000d0d00000d0d00000d0d00000d0d00000d0d00000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00200000000000000002000000200000000000200002000000000200000000000000000000000000000000000000000000000000000000000000000000000000
000e220000000000000e2200000e2200000e2200000e2200000e2200000000000000000000000000000000000000000000000000000000000000000000000000
0007f700002e220000f7f7f0000ff7000007ff00000ff7000007ff00000000000000000000000000000000000000000000000000000000000000000000000000
000fff000007f700002fff20000fff00000fff00000fff00000fff00000000000000000000000000000000000000000000000000000000000000000000000000
00fdedf0002fff20002ded2000fded00000dedf000fded00000dedf0000000000000000000000000000000000000000000000000000000000000000000000000
000ddd00002ded20000ddd00000ddd00000ddd00000ddd00000ddd00000000000000000000000000000000000000000000000000000000000000000000000000
000d0d0000fdddf0000d0d00000d0d00000d0d00000d0d00000d0d00000000000000000000000000000000000000000000000000000000000000000000000000
