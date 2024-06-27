
--- coordinateprovider.lua

-- Provides iterators which can be used to loop through coordinates between a certain set of coordinates or around a point.





--- Creates an iterator which returns X/Z coordinates between the provided min/max x and z coordinates.
function CoordinateProviderArea(a_MinX, a_MaxX, a_MinZ, a_MaxZ)
	local sizeX = a_MaxX - a_MinX + 1;
	local sizeZ = a_MaxZ - a_MinZ + 1;
	local idx = 0;
	return function()
		if (idx == sizeX * sizeZ) then
			return;
		end
		local x = idx % sizeX;
		local z = math.floor(idx / sizeX)
		idx = idx + 1
		return a_MinX + x, a_MinZ + z
	end
end





--- Creates an iterator which returns X/Z coordinates that spirals around a_X and a_Z until the requested radius is reached.
function CoordinateProviderSpiral(a_X, a_Z, a_Radius)
	-- Spiral code from https://stackoverflow.com/a/19287714
	local function spiral(n)
		-- given n an index in the squared spiral
		-- p the sum of point in inner square
		-- a the position on the current square
		-- n = p + a

		-- Original code: http:--jsfiddle.net/davidonet/HJQ4g/
		if (n == 0) then
			return 0, 0;
		end
		n = n - 1;
		
		local r = math.floor((math.sqrt(n + 1) - 1) / 2) + 1;
		
		-- compute radius : inverse arithmetic sum of 8+16+24+...=
		local p = (8 * r * (r - 1)) / 2;
		-- compute total point on radius -1 : arithmetic sum of 8+16+24+...

		local en = r * 2;
		-- points by face

		local a = (1 + n - p) % (r * 8);
		-- compute de position and shift it so the first is (-r,-r) but (-r+1,-r)
		-- so square can connect

		local x, z;
		local face = math.floor(a / (r * 2))
		if (face == 0) then
			x = a - r;
			z = -r;
		elseif (face == 1) then
			x = r;
			z = (a % en) - r;
		elseif (face == 2) then
			x = r - (a % en);
			z = r;
		elseif (face == 3) then
			x = -r;
			z = r - (a % en);
		end
		return x, z;
	end
	
	local idx = 0;
	local target = (a_Radius * 2 + 1) ^ 2
	return function()
		if (idx == target) then
			return;
		end
		local offsetX, offsetZ = spiral(idx)
		idx = idx + 1
		return a_X + offsetX, a_Z + offsetZ
	end
end





--[[
Returns 0 if the provided value is 0, -1 if the value is negative and 1 of the value is positive.
]]
function sgn(x)
	if (x == 0) then
		return 0
	elseif x > 0 then
		return 1
	else
		return -1;
	end
end





function gilbert2d(x, y, ax, ay, bx, by)
	--[[
	Based upon https://github.com/jakubcerveny/gilbert 
	Copyright (c) 2018, Jakub Červený
	]]
	local w = math.abs(ax + ay)
	local h = math.abs(bx + by)

	local dax, day = sgn(ax), sgn(ay) -- unit major direction
	local dbx, dby = sgn(bx), sgn(by) -- unit orthogonal direction

	if h == 1 then
		-- trivial row fill
		for i = 0, w - 1 do
			coroutine.yield(x, y)
			x, y = x + dax, y + day
		end
		return
	end
	if w == 1 then
		-- trivial column fill
		for i = 0, h - 1 do
			coroutine.yield(x, y)
			x, y = x + dbx, y + dby
		end
		return
	end
	local ax2, ay2 = math.floor(ax/2), math.floor(ay/2)
	local bx2, by2 = math.floor(bx/2), math.floor(by/2)

	local w2 = math.abs(ax2 + ay2)
	local h2 = math.abs(bx2 + by2)

	if 2*w > 3*h then
		if (w2 % 2) ~= 0 and (w > 2) then
			-- prefer even steps
			ax2, ay2 = ax2 + dax, ay2 + day
		end
		-- long case: split in two parts only
		gilbert2d(x, y, ax2, ay2, bx, by)
		gilbert2d(x+ax2, y+ay2, ax-ax2, ay-ay2, bx, by)
	else
		if (h2 % 2) ~= 0 and (h > 2) then
			-- prefer even steps
			bx2, by2 = bx2 + dbx, by2 + dby
		end
		-- standard case: one step up, one long horizontal, one step down
		gilbert2d(x, y, bx2, by2, ax2, ay2)
		gilbert2d(x+bx2, y+by2, ax, ay, bx-bx2, by-by2)
		gilbert2d(x+(ax-dax)+(bx2-dbx), y+(ay-day)+(by2-dby),
				 -bx2, -by2, -(ax-ax2), -(ay-ay2))
	end
end





function CreateIteratorHilbert(a_X, a_Z, a_Radius)
	local cor = coroutine.create(gilbert2d)
	local diameter = a_Radius * 2 + 1
	local width, height = diameter, diameter
	local args = { 0, 0, width, 0, 0, height }

	return function()
		if (coroutine.status(cor) == "dead") then
			return
		end
		local success, x, z = coroutine.resume(cor, unpack(args))
		if (not x or not z) then
			return
		end
		return x + a_X - a_Radius, z + a_Z - a_Radius
	end
end





--- Creates the requested chunk iterator using the provided radius and chunk coordinates.
function GetChunkOrderProvider(a_ChunkOrder, a_Radius, a_ChunkX, a_ChunkZ)
	if (a_ChunkOrder == ChunkOrder.Lines) then
		return CoordinateProviderArea(
			a_ChunkX - a_Radius, a_ChunkX + a_Radius,
			a_ChunkZ - a_Radius, a_ChunkZ + a_Radius
		);
	elseif (a_ChunkOrder == ChunkOrder.Spiral) then
		return CoordinateProviderSpiral(a_ChunkX, a_ChunkZ, a_Radius)
	elseif (a_ChunkOrder == ChunkOrder.Hilbert) then
		return CreateIteratorHilbert(a_ChunkX, a_ChunkZ, a_Radius)
	else
		return false, "Unknown chunk order"
	end
end




