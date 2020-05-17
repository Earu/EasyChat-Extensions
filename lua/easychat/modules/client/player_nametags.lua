local tag = "NameTags"

local EC_NT_OFFSET = CreateClientConVar("easychat_nt_offset", "18", true, false, "How far away from the player should the nametag display")
local EC_NT_ME = CreateClientConVar("easychat_nt_draw_me", "1", true, false, "Should we draw our own nametag")
local EC_NT_FONT_SIZE = CreateClientConVar("easychat_nt_font_size", "100", true, false, "Size of the font used in nametags")
local EC_NT_FONT_NAME = CreateClientConVar("easychat_nt_font_name", "Tahoma", true, false, "The font to use for nametags")
local EC_NT_FONT_WEIGHT = CreateClientConVar("easychat_nt_font_weight", "880", true, false, "How bold should the nametags font be")

local function update_fonts()
	surface.CreateFont("NameTagFont", {
		font = EC_NT_FONT_NAME:GetString(),
		extended = true,
		size = EC_NT_FONT_SIZE:GetInt(),
		weight = EC_NT_FONT_WEIGHT:GetInt(),
		additive = false,
	})

	surface.CreateFont("NameTagShadowFont", {
		font = EC_NT_FONT_NAME:GetString(),
		extended = true,
		size = EC_NT_FONT_SIZE:GetInt(),
		weight = EC_NT_FONT_WEIGHT:GetInt(),
		blursize = 5,
	})
end

update_fonts()
-- in case the chat is reloaded we dont want to keep stacking callbacks
cvars.RemoveChangeCallback(EC_NT_FONT_SIZE:GetName(), tag)
cvars.RemoveChangeCallback(EC_NT_FONT_NAME:GetName(), tag)
cvars.RemoveChangeCallback(EC_NT_FONT_WEIGHT:GetName(), tag)

cvars.AddChangeCallback(EC_NT_FONT_SIZE:GetName(), update_fonts, tag)
cvars.AddChangeCallback(EC_NT_FONT_NAME:GetName(), update_fonts, tag)
cvars.AddChangeCallback(EC_NT_FONT_WEIGHT:GetName(), update_fonts, tag)

-- actual drawing after this
local player_GetAll, ipairs, LocalPlayer = _G.player.GetAll, _G.ipairs, _G.LocalPlayer
local IsValid, EyeAngles, Vector = _G.IsValid, _G.EyeAngles, _G.Vector

local cam_Start3D2D, cam_End3D2D = _G.cam.Start3D2D, _G.cam.End3D2D

local function should_get_overhead_pos(ply)
	local lp = LocalPlayer()
	if lp == ply and not ply:ShouldDrawLocalPlayer() then return false end
	if ply:Crouching() then return false end
	if lp:GetPos():DistToSqr(ply:GetPos()) > 5000 * 5000 then return false end

	return true
end

local function get_overhead_pos(ply)
	if not should_get_overhead_pos(ply) then return end

	local bone = 6
	local pos = ply:GetBonePosition(bone) or ply:EyePos()
	if not ply:GetBoneName(bone):lower():find("head") and ply:GetBoneCount() >= bone then
		for i = 1, ply:GetBoneCount() do
			if ply:GetBoneName(i):lower():find("head") then
				pos = ply:GetBonePosition(i)
				bone = i
			end
		end
	end

	if not ply:Alive() then
		local rag = ply:GetRagdollEntity()
		if IsValid(rag) then
			pos = rag:GetBonePosition(bone)
		end
	end

	return pos
end

local function draw_player(ply)
	local mk = ec_markup.CachePlayer(tag, ply, function()
		local team_col, nick = team.GetColor(ply:Team()), ply:Nick()
		return ec_markup.AdvancedParse(nick, {
			nick = true,
			default_color = team_col,
			default_font = "NameTagFont",
			default_shadow_font = "NameTagShadowFont",
			shadow_intensity = 1,
		})
	end)

	mk:Draw(-mk:GetWide() / 2, 0)
end

hook.Add("PostDrawTranslucentRenderables", tag, function()
	local lp = LocalPlayer()
	for _, ply in ipairs(player_GetAll()) do
		if ply ~= lp or (ply == lp and EC_NT_ME:GetBool()) then
			local pos = get_overhead_pos(ply)
			if pos then
				local ang = EyeAngles()
				ang:RotateAroundAxis(ang:Right(), 90)
				ang:RotateAroundAxis(ang:Up(), -90)
				cam_Start3D2D(pos + ply:GetUp() * EC_NT_OFFSET:GetInt(), ang, 0.07)
					draw_player(ply)
				cam_End3D2D()
			end
		end
	end
end)

return tag