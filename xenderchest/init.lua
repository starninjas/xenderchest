if minetest.get_modpath("intllib") then
		S = intllib.Getter()
	else
		S = function(s) return s end
end

local save_password = function(name, inv)
	local filename = minetest.get_worldpath().."/xenderchest_password_"..name
	local file = io.open(filename, "r")
	local save = minetest.deserialize(file:read())
	file:close()
	file = io.open(filename, "w")
	save.inv = inv:get_list(name)
	for x=1,32 do
		save.inv[x] = save.inv[x]:to_table()
	end
	file:write(minetest.serialize(save))
	file:close()
end

local load_password = function(name, inv)
	local filename = minetest.get_worldpath().."/xenderchest_password_"..name
	local file = io.open(filename, "r")
	if file == nil then
		return nil
	end
	local save = minetest.deserialize(file:read())
	file:close()
	inv:set_size(name, 32)
	inv:set_list(name, save.inv)
end

local new_password = function(name, password)
	local filename = minetest.get_worldpath().."/xenderchest_password_"..name
	file = io.open(filename, "w")
	local save = {}
	save.inv = {}
	save.password=password
	file:write(minetest.serialize(save))
	file:close()
	file = io.open(minetest.get_worldpath().."/xenderchest_passwords","a")
	file:write(name.."\n")
	file:close()
end

local get_password = function(name)
	local filename = minetest.get_worldpath().."/xenderchest_password_"..name
	local file = io.open(filename, "r")
	if file == nil then
		return nil
	end
	local save = minetest.deserialize(file:read())
	file:close()
	return save.password
end

local inv = minetest.create_detached_inventory("xenderchest_password", {
	on_move = function(inv, from_list, from_index, to_list, to_index, count, player) 
		if from_list == to_list then
			save_password(to_list,inv)
		end
	end,

	on_put = function(inv, listname, index, stack, player) 
		save_password(listname,inv)
	end,

	
	on_take = function(inv, listname, index, stack, player) 
		save_password(listname,inv)
	end,	
})

minetest.register_node("xenderchest:password_chest", {
	description = S("Enderchest"),
	tiles = {"xenderchest_chest_top.png", "xenderchest_chest_top.png", "xenderchest_chest_side.png",
		"xenderchest_chest_side.png", "xenderchest_chest_side.png", "xenderchest_chest_front.png"},
	groups={choppy=2},
	on_construct=function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", "size[8,9]"..
		"field[0,1;4,1;name;Name:;]"..
		"pwdfield[4,1;4,1;password;Password:]"..
		"button[0,2;8,1;ok;Done]")
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.get_meta(pos)
		if fields.ok ~= nil and fields.name ~= "" and fields.password ~= "" then
			if fields.name:match("%W") or fields.password:match("%W") then
				minetest.chat_send_player(sender:get_player_name(), S("Error name or password contains not allowed character use a_zA_Z0_9!"))
				return nil
			end
			if get_password(fields.name) == nil then
				new_password(fields.name, fields.password)
			end
			if get_password(fields.name) == fields.password then
				load_password(fields.name, inv)
				meta:set_string("formspec", "size[8,9]"..
					"list[detached:xenderchest_password;"..fields.name..";0,0;8,4;]"..
					"list[current_player;main;0,5;8,4;]")
			else
				minetest.chat_send_player(sender:get_player_name(), S("Error incorrect Password"))
			end
		end
	end,
	
})

local file = io.open(minetest.get_worldpath().."/xenderchest_passwords", "r")
if file ~= nil then
	local name = file:read()
	while name ~= nil do
		load_password(name, inv)
		name = file:read()
	end
end

minetest.register_craft({
	output = '"xenderchest:password_chest" 1',
	recipe = {
		{'default:mese_crystal', 'default:obsidian', 'default:mese_crystal', },
		{'default:obsidian', 'default:chest', 'default:obsidian', },
		{'default:mese_crystal', 'default:obsidian', 'default:mese_crystal', },
		}
})