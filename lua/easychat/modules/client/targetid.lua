local default_color = Color(68, 112, 146, 255)
local black_color = Color(0, 0, 0, 255)

local function default_trace()
	local eye_pos = EyePos()
	return util.TraceLine({
		start = eye_pos,
		endpos = eye_pos + EyeAngles():Forward() * 6000,
		filter = LocalPlayer(),
	})
end

local function get_vehicle_driver(vehicle)
	local driver = vehicle.GetDriver and vehicle:GetDriver()
	local me = LocalPlayer()

	if driver and driver:IsValid() and driver ~= me then
		return driver
	else
		-- find the player that has the vehicle we're looking at
		for k, v in next, player.GetAll() do
			if v:InVehicle() and v ~= me then
				local veh = v:GetVehicle()
				if veh == vehicle then
					return v
				end
			end
		end
	end
end

local hud_font, hud_shadow_font = "TargetIDFont", "TargetIDShadowFont"
surface.CreateFont(hud_font, {
	font = "Tahoma",
	size = 25,
	weight = 880,
	extended = true,
	additive = true,
})

surface.CreateFont(hud_shadow_font, {
	font = "Tahoma",
	size = 25,
	weight = 880,
	extended = true,
	blursize = 5,
})

local function cache_nick(ply)
	return ec_markup.CachePlayer("TargetID", ply, function()
		return ec_markup.AdvancedParse(ply:Nick(), {
			shadow_intensity = 2,
			nick = true,
			default_font = hud_font,
			default_shadow_font = hud_shadow_font,
			default_color = team.GetColor(ply:Team())
		})
	end)
end

local function draw_targetid(x, y, ent)
	if ent:IsVehicle() then
		local driver = get_vehicle_driver(ent)
		if not IsValid(driver) then return end

		ent = driver
	end

	-- check if we should actually draw or not
	if hook.Run("ShouldDrawTargetID", ent) == false then return end

	if ent:IsPlayer() then
		local mk = cache_nick(ent)
		if mk then
			if ent:Health() < ent:GetMaxHealth() then
				mk:Draw(x - mk:GetWide() / 2, y - 30)

				-- draw health text after
				surface.SetFont(hud_font)

				local health_text = ("%d%%"):format(ent:Health())
				local tw, th = surface.GetTextSize(health_text)
				local tx, ty = x - tw / 2, y + th - 15

				-- draw shadow
				surface.SetFont(hud_shadow_font)
				surface.SetTextColor(black_color)
				for _ = 1, 2 do
					surface.SetTextPos(tx, ty)
					surface.DrawText(health_text)
				end

				-- draw actual text
				surface.SetFont(hud_font)
				surface.SetTextColor(team.GetColor(ent:Team()))
				surface.SetTextPos(tx, ty)
				surface.DrawText(health_text)
			else
				mk:Draw(x - mk:GetWide() / 2, y - 13)
			end
		end
	elseif ent:IsWeapon() then
		-- draw weapon name
		surface.SetFont(hud_font)

		local weapon_name = ent.PrintName or ent:GetClass():gsub("weapon_", ""):gsub("_", " ")
		local tw, th = surface.GetTextSize(weapon_name)
		local tx, ty = x - tw / 2, y - (th + 5)

		-- draw shadow
		surface.SetFont(hud_shadow_font)
		surface.SetTextColor(black_color)
		for _ = 1, 2 do
			surface.SetTextPos(tx, ty)
			surface.DrawText(weapon_name)
		end

		-- draw the actual text
		surface.SetFont(hud_font)
		surface.SetTextColor(default_color)
		surface.SetTextPos(tx, ty)
		surface.DrawText(weapon_name)
	end
end

hook.Add("HUDDrawTargetID", "EasyChatTargetID", function()
	local x, y = gui.MouseX(), gui.MouseY()
	local me = LocalPlayer()
	local ent = (me:Alive() and me:GetEyeTrace() or default_trace()).Entity
	if not IsValid(ent) then return end

	-- cursor is not active, draw player/weapon where we are aiming at
	if x == 0 and y == 0 then
		draw_targetid(ScrW() / 2, ScrH() / 2, ent)
		return true
	else
		draw_targetid(x, y, ent)
		return true
	end
end)