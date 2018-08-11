pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
world = {
	bounds = 128
}

platforms = {}
make_platform = function(x, y, w, h, directions)
	platform = {
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
		should_grow = true,
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

	add(platforms, platform)
end

function _init()
	make_platform(6, 64, 16, 40, {up=true,down=false,left=true,right=false})
	make_platform(64, 20, 16, 8, {up=true,down=true,left=true,right=true})
	make_platform(100, 64, 8, 8, {up=false,down=false,left=true,right=false})
	make_platform(112, 64, 8, 8, {up=false,down=true,left=false,right=false})

	for platform in all(platforms) do
		platform:init()
	end
end

global_grow_toggle = true
function _update60()
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
000000000000033333333333003333330003333333333333333333333bbbb6bb3bbbbbbb003333330033330000333300333333003b7bbbbb0000000000000000
0000000000003bbbbbbbbbbb03bbbbbb003bbbbbbbbbbbbb3b3b3b3b3bbbbbbb3bbbbbbb03bbbbbb03bbbb3003bbbb30bbbbbb303b7bbbbb0000000000000000
007007000003bbbbbb7bbbbb3bbbbbbb03bbbbbbb6bbbbbb3b3b3bbb3bbb6bbb3bbbbbbb3bbbbbbb3bbbbbb33bbb7bb3bbbbbbb33b7bbbbb0000000000000000
00077000003bbbbbbbbbbb7b3bbbbbbb3bbbbbbbbbb6bbbb3b3bbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbb33bbbb7b3bbbbbbb33b7bbbbb0000000000000000
0007700003bbbbbbbb7bbbbb3bbbbbbb3bbbbbbbbbbbb6bb3bbbbbbb3bb6bbbb3bbbbbbb3bbbbbbb3bbbbbb33bbbbbb3bbbbbbb33b7bbbbb0000000000000000
007007003bbbbbbbbb7bbb7b3bbbbbbb3bbbbbbbbbbbbbb6bbbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbb33bbbbbb3bbbbbbb33b7bbbbb0000000000000000
000000003bbbbbbbbbbbbb7b3bbbbbbb3bbbbbbbbbbbbbbbbbbbbbbb3b6bbbbb3bbbbbbb03bbbbbb3bbbbbb303bbbb30bbbbbb303b7bbbbb0000000000000000
000000003bbbbbbbbbbbbbbb3bbbbbbb3bbbbbbbbbbbbbbbbbbbbbbb3bbbbbbb3bbbbbbb003333333bbbbbb300333300333333003b7bbbbb0000000000000000
