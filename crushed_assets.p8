pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
world = {
	bounds = 128
}

platform = {
	x = 64,
	y = 64,
	width = 16,
	height = 16,
	corner_sprite = 3,
	corner_sprite_size = 8,
	sliver_width = 2,
	sprite_height = 8,
	counter = 1,
	grow_delta = 2,
	grown_x = 0,
	grown_y = 0,
	available_slivers = {
		{26, 0}, -- plain
		{40, 0}, -- spotted
		{42, 0},
		{44, 0},
		{46, 0}
	},
	slivers = {
		top = {},
		right = {},
		bottom = {},
		left = {}
	},
	update = function(self)
		self.counter += 1
		if self.counter % 30 == 0 then
			self:grow()
		end
	end,
	draw = function(self)
		-- bounding box
		rect(self.x, self.y, self.x + self.width - 1, self.y + self.height - 1)

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

		print(self.grown_x, 6, 6)
	end,
	get_random_sliver = function(self)
		local random_sliver_index = flr(rnd(#self.available_slivers)) + 1
		return self.available_slivers[random_sliver_index]
	end,
	make_sliver = function(self, collection)
		add(collection, self:get_random_sliver())
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
			local x = self:get_sliver_x_pos(i)
			sspr(spr_x, spr_y, 2, 8, x, self.y, 2, 8)
		end
	end,
	get_sliver_x_pos = function(self, i)
		return self.x + self.corner_sprite_size + (self.grow_delta * (i - 1))
	end,
	get_sliver_y_pos = function(self, i)
		return self.y + self.height - 8
	end,
	grow = function(self)
		self.x -= self.grow_delta / 2
		self.width += self.grow_delta
		self.y -= self.grow_delta / 2
		self.height += self.grow_delta
		self.grown_x += 1
		self.grown_y += 1

		self:make_sliver(self.slivers.top)
		self:make_sliver(self.slivers.right)
		self:make_sliver(self.slivers.bottom)
		self:make_sliver(self.slivers.left)
	end
}

function _update()
	platform:update()
end

function _draw()
	cls()
	platform:draw()
end
__gfx__
00000000000003333333333300333333000333333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000
0000000000003bbbbbbbbbbb03bbbbbb003bbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000
007007000003bbbbbb7bbbbb3bbbbbbb03bbbbbbb6bbbbb6b7bbbbbb000000000000000000000000000000000000000000000000000000000000000000000000
00077000003bbbbbbbbbbb7b3bbbbbbb3bbbbbbbbbbbb6bbbbbbb7bb000000000000000000000000000000000000000000000000000000000000000000000000
0007700003bbbbbbbb7bbbbb3bbbbbbb3bbbbbbbb6bbbbbbb7bbbbbb000000000000000000000000000000000000000000000000000000000000000000000000
007007003bbbbbbbbb7bbb7b3bbbbbbb3bbbbbbbbbb6bbbbb7bbb7bb000000000000000000000000000000000000000000000000000000000000000000000000
000000003bbbbbbbbbbbbb7b3bbbbbbb3bbbbbbbbbbbbbb6bbbbb7bb000000000000000000000000000000000000000000000000000000000000000000000000
000000003bbbbbbbbbbbbbbb3bbbbbbb3bbbbbbbb6bbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000
