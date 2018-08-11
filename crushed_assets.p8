pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
world = {
	bounds = 128
}

platforms = {}
make_platform = function(x, y, w, h, appearance, directions)
	platform = {
		x = x,
		y = y,
		width = w,
		height = h,
		corner_sprite = 3,
		corner_sprite_size = 8,
		sliver_width = 2,
		sprite_height = 8,
		counter = 1,
		grow_delta = 2,
		directions = directions,
		should_grow = false,
		available_x_slivers = {
			{26, 0}, -- plain
			{26, 0}, -- plain
			{26, 0}, -- plain
			{40, 0}, -- spotted
			{42, 0},
			{44, 0},
			{46, 0}
		},
		available_y_slivers = {
			{64, 6}, -- plain
			{64, 6}, -- plain
			{64, 6}, -- plain
			{56, 0}, -- spotted
			{56, 2},
			{56, 4},
			{56, 6}
		},
		slivers = {
			top = {},
			right = {},
			bottom = {},
			left = {}
		},
		init = function(self)
			-- populate slivers for width/height > 16
			if (self.width > 16) then
				local hor_slivers = (self.width - 16) / 2
				for i = 1, hor_slivers do
					add(self.slivers["top"], self:get_random_x_sliver())
					add(self.slivers["bottom"], self:get_random_x_sliver())
				end
			end
			if (self.height > 16) then
				local vert_slivers = (self.height - 16) / 2
				for i = 1, vert_slivers do
					add(self.slivers["right"], self:get_random_y_sliver())
					add(self.slivers["left"], self:get_random_y_sliver())
				end
			end
		end,
		update = function(self)
			self.counter += 1
			if self.counter % 2 == 0 then
				if self.should_grow then
					self:grow()
				end
			end
		end,
		draw = function(self)
			-- bounding box
			-- rect(self.x, self.y, self.x + self.width - 1, self.y + self.height - 1, 7)

			-- corners
			-- top left
			spr(self.corner_sprite, self.x, self.y)
			-- top right
			spr(self.corner_sprite, self.x + self.width - self.corner_sprite_size, self.y, 1, 1, true)
			-- bottom left
			spr(self.corner_sprite, self.x, self.y + self.height - self.corner_sprite_size, 1, 1, false, true)
			-- bottom right
			spr(self.corner_sprite, self.x + self.width - self.corner_sprite_size, self.y + self.height - self.corner_sprite_size, 1, 1, true, true)

			-- slivers
			for key, collection in pairs(self.slivers) do
				for j = 1, #collection do
					self:draw_sliver(key, j, collection[j])
				end
			end

			-- center area
			local center_x0 = self.x+self.corner_sprite_size
			local center_y0 = self.y+self.corner_sprite_size
			local center_x1 = center_x0 + self.width - (self.corner_sprite_size * 2)
			local center_y1 = center_y0 + self.height - (self.corner_sprite_size * 2)
			rectfill(center_x0, center_y0, center_x1, center_y1, 11)

			-- debug
			print(self.should_grow, 100, 100)
		end,
		get_random_x_sliver = function(self)
			local random_sliver_index = flr(rnd(#self.available_x_slivers)) + 1
			return self.available_x_slivers[random_sliver_index]
		end,
		get_random_y_sliver = function(self)
			local random_sliver_index = flr(rnd(#self.available_y_slivers)) + 1
			return self.available_y_slivers[random_sliver_index]
		end,
		make_sliver = function(self, key)
			if (key == "top" or key == "bottom") then
				add(self.slivers[key], self:get_random_x_sliver())
			elseif (key == "right" or key == "left") then
				add(self.slivers[key], self:get_random_y_sliver())
			end
		end,
		draw_sliver = function(self, key, i, sliver)
			local spr_x = sliver[1]
			local spr_y = sliver[2]

			if (key == "top") then
				local x = self:get_sliver_x_pos(i)
				sspr(spr_x, spr_y, 2, 8, x, self.y, 2, 8)
			end

			if (key == "bottom") then
				local x = self:get_sliver_x_pos(i)
				local y = self:get_sliver_y_pos(i)
				sspr(spr_x, spr_y, 2, 8, x, y, 2, 8, false, true)
			end

			if (key == "left") then
				local x = self.x
				local y = self.y + self.corner_sprite_size + (self.grow_delta * (i - 1))
				sspr(spr_x, spr_y, 8, 2, x, y, 8, 2)
			end

			if (key == "right") then
				local x = self.x + self.width - 8
				local y = self.y + self.corner_sprite_size + (self.grow_delta * (i - 1))
				sspr(spr_x, spr_y, 8, 2, x, y, 8, 2, true, false)
			end
		end,
		get_sliver_x_pos = function(self, i)
			return self.x + self.corner_sprite_size + (self.grow_delta * (i - 1))
		end,
		get_sliver_y_pos = function(self, i)
			return self.y + self.height - 8
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

	add(platforms, platform)
end

function _init()
	make_platform(64, 64, 16, 40, nil, {up=true,down=false,left=true,right=false})
	make_platform(64, 20, 16, 16, nil, {up=true,down=true,left=true,right=true})
	make_platform(40, 64, 16, 16, nil, {up=false,down=false,left=true,right=false})

	for platform in all(platforms) do
		platform:init()
	end
end

global_grow_toggle = false
function _update()
	if (btnp(5)) then
		global_grow_toggle = not global_grow_toggle
		for platform in all(platforms) do
			platform:toggle_growth(global_grow_toggle)
		end
	end

	for platform in all(platforms) do
		platform:update()
	end
end

function _draw()
	cls()
	for platform in all(platforms) do
		platform:draw()
	end
end
__gfx__
000000000000033333333333003333330003333333333333333333333bbbbbbb3bbbbbbb00000000000000000000000000000000000000000000000000000000
0000000000003bbbbbbbbbbb03bbbbbb003bbbbbbbbbbbbbbbbbbbbb3b6b6bb63bbbbbbb00000000000000000000000000000000000000000000000000000000
007007000003bbbbbb7bbbbb3bbbbbbb03bbbbbbb6bbbbb6b7bbbbbb3bbbbbbb3bbbbbbb00000000000000000000000000000000000000000000000000000000
00077000003bbbbbbbbbbb7b3bbbbbbb3bbbbbbbbbbbb6bbbbbbb7bb3bbbb6bb3bbbbbbb00000000000000000000000000000000000000000000000000000000
0007700003bbbbbbbb7bbbbb3bbbbbbb3bbbbbbbb6bbbbbbb7bbbbbb3bbbbbbb3bbbbbbb00000000000000000000000000000000000000000000000000000000
007007003bbbbbbbbb7bbb7b3bbbbbbb3bbbbbbbbbb6bbbbb7bbb7bb3bb6bbbb3bbbbbbb00000000000000000000000000000000000000000000000000000000
000000003bbbbbbbbbbbbb7b3bbbbbbb3bbbbbbbbbbbbbb6bbbbb7bb3bbbbbbb3bbbbbbb00000000000000000000000000000000000000000000000000000000
000000003bbbbbbbbbbbbbbb3bbbbbbb3bbbbbbbb6bbbbbbbbbbbbbb3b6bbb6b3bbbbbbb00000000000000000000000000000000000000000000000000000000
