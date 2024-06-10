
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




