local MEDIAPLAYER_DUPE = nil
local MEDIAPLAYER_SAVE = false
local MEDIAPLAYER_THUMBNAIL = nil

local HTMLMAT_STYLE_DUPE = "htmlmat.style.dupe"
-- AddHTMLMaterialStyle( HTMLMAT_STYLE_DUPE, {
-- 	width = 512,
-- 	height = 512,
-- 	css = [[
-- img {
-- 	width: 100%;
-- 	position: absolute;
-- 	top: 50%;
-- 	left: 50%;
-- 	-webkit-filter: blur(6px);
-- 	-webkit-transform: translate(-50%, -50%) scale(1.1,1.1);
-- }]]
-- } )
AddHTMLMaterialStyle( HTMLMAT_STYLE_DUPE, {
	width = 512,
	height = 512,
	css = [[
img {
	-webkit-filter: blur(6px) brightness(0.9);
	-webkit-transform: translate(-50%, -50%) scale(1.05, 1.05);
}]]
}, HTMLMAT_STYLE_COVER_IMG )

surface.CreateFont( "DupeMediaText", {
	font		= "Clear Sans Medium",
	antialias	= true,
	weight		= 400,
	size        = 80
} )

local function PreSaveMediaPlayerDupe( Dupe )

	local mediaplayers = {}

	for _, ent in pairs( Dupe.Entities or {} ) do
		if ent.IsMediaPlayerEntity then
			table.insert( mediaplayers, ent )
		end
	end

	local mp = mediaplayers[1]
	local snapshot = mp.MediaPlayerSnapshot

	local media = snapshot.media
	local metadata = media and media._metadata
	local thumbnail = metadata and metadata.thumbnail

	if thumbnail then
		HTMLMaterial( thumbnail, HTMLMAT_STYLE_DUPE, function( material )
			MEDIAPLAYER_THUMBNAIL = material
			MEDIAPLAYER_SAVE = true
		end )
	else
		MEDIAPLAYER_THUMBNAIL = Material( "gui/dupe_bg.png" )
		MEDIAPLAYER_SAVE = true
	end

end

local function DrawOutlinedText(text, font, x, y, colour, xalign, yalign)
	local outlineColor = Color(0,0,0,colour.a)
	draw.SimpleText(text, font, x, y + 2, outlineColor, xalign, yalign)
	draw.SimpleText(text, font, x + 1, y + 2, outlineColor, xalign, yalign)
	draw.SimpleText(text, font, x - 1, y + 2, outlineColor, xalign, yalign)

	draw.SimpleText(text, font, x, y - 2, outlineColor, xalign, yalign)
	draw.SimpleText(text, font, x + 1, y - 2, outlineColor, xalign, yalign)
	draw.SimpleText(text, font, x - 1, y - 2, outlineColor, xalign, yalign)

	draw.SimpleText(text, font, x + 2, y + 2, outlineColor, xalign, yalign)
	draw.SimpleText(text, font, x + 2, y + 1, outlineColor, xalign, yalign)
	draw.SimpleText(text, font, x + 2, y - 1, outlineColor, xalign, yalign)

	draw.SimpleText(text, font, x - 2, y + 2, outlineColor, xalign, yalign)
	draw.SimpleText(text, font, x - 2, y + 1, outlineColor, xalign, yalign)
	draw.SimpleText(text, font, x - 2, y - 1, outlineColor, xalign, yalign)

	draw.SimpleText(text, font, x, y, colour, xalign, yalign)
end

local function RenderMediaPlayerDupe( Dupe )

	local FOV = 17

	--
	-- This is gonna take some cunning to look awesome!
	--
	local Size		= Dupe.Maxs - Dupe.Mins;
	local Radius	= Size:Length() * 0.5;
	local CamDist	= Radius / math.sin( math.rad( FOV ) / 2 ) -- Works out how far the camera has to be away based on radius + fov!
	local Center	= LerpVector( 0.5, Dupe.Mins, Dupe.Maxs );
	local CamPos	= Center + Vector( -1, 0, 0.5 ):GetNormal() * CamDist;
	local EyeAng	= ( Center - CamPos ):GetNormal():Angle();

	--
	-- The base view
	--
	local view =
	{
		type		= "3D",
		origin		= CamPos,
		angles		= EyeAng,
		x			= 0,
		y			= 0,
		w			= 512,
		h			= 512,
		aspect		= 1,
		fov			= FOV
	}

	--
	-- Create a bunch of entities we're gonna use to render.
	--
	local entities = {}

	for k, v in pairs( Dupe.Entities ) do

		local ent

		if ( v.Class == "prop_ragdoll" ) then

			ent = ClientsideRagdoll( v.Model or "error.mdl", RENDERGROUP_OTHER )

			if ( istable( v.PhysicsObjects ) ) then

				for boneid, v in pairs( v.PhysicsObjects ) do

					local obj = ent:GetPhysicsObjectNum( boneid )
					if ( IsValid( obj ) ) then
						obj:SetPos( v.Pos )
						obj:SetAngles( v.Angle )
					end

				end

				ent:InvalidateBoneCache()

			end

		elseif v.IsMediaPlayerEntity then

			ent = ClientsideModel( v.Model or "error.mdl", RENDERGROUP_OTHER )
			ent.PlayerConfig = v.PlayerConfig

			local mp = MediaPlayer.GetById( v.DT.MediaPlayerID )
			if mp and mp:GetType() == "entity" then
				mp._oldent = mp.Entity
				mp.Entity = ent
			end

		end

		entities[k] = ent

	end


	--
	-- DRAW THE BACKGROUND
	--
	render.SetMaterial( Material( "gui/dupe_bg.png" ) )
	render.DrawScreenQuadEx( 0, 0, 512, 512 )

	render.SetMaterial( MEDIAPLAYER_THUMBNAIL )
	render.DrawScreenQuadEx( 0, 0, 512, 512 )
	render.SuppressEngineLighting( true )

	--
	-- BLACK OUTLINE
	-- AWESOME BRUTE FORCE METHOD
	--
	render.SuppressEngineLighting( true )

	local BorderSize	= CamDist * 0.004
	local Up			= EyeAng:Up() * BorderSize
	local Right			= EyeAng:Right() * BorderSize

	render.SetColorModulation( 1, 1, 1, 1 )
	render.MaterialOverride( Material( "models/debug/debugwhite" ) )

	-- Render each entity in a circle
	for k, v in pairs( Dupe.Entities ) do

		for i=0, math.pi*2, 0.2 do

			view.origin = CamPos + Up * math.sin( i ) + Right * math.cos( i )

			cam.Start( view )

				render.Model(
				{
					model	=	v.Model,
					pos		=	v.Pos,
					angle	=	v.Angle,

				}, entities[k] )

			cam.End()

		end

	end

	-- Because ee just messed up the depth
	render.ClearDepth()
	render.SetColorModulation( 0, 0, 0, 1 )

	-- Try to keep the border size consistent with zoom size
	local BorderSize	= CamDist * 0.002
	local Up			= EyeAng:Up() * BorderSize
	local Right			= EyeAng:Right() * BorderSize

	-- Render each entity in a circle
	for k, v in pairs( Dupe.Entities ) do

		for i=0, math.pi*2, 0.2 do

			view.origin = CamPos + Up * math.sin( i ) + Right * math.cos( i )
			cam.Start( view )

			render.Model(
			{
				model	=	v.Model,
				pos		=	v.Pos,
				angle	=	v.Angle,
				skin	=	v.Skin
			}, entities[k] )

			cam.End()

		end

	end

	--
	-- ACUAL RENDER!
	--

	-- We just fucked the depth up - so clean it
	render.ClearDepth()

	-- Set up the lighting. This is over-bright on purpose - to make the ents pop
	render.SetModelLighting( 0, 0, 0, 0 )
	render.SetModelLighting( 1, 2, 2, 2 )
	render.SetModelLighting( 2, 3, 2, 0 )
	render.SetModelLighting( 3, 0.5, 2.0, 2.5 )
	render.SetModelLighting( 4, 3, 3, 3 ) -- top
	render.SetModelLighting( 5, 0, 0, 0 )
	render.MaterialOverride( nil )

	view.origin = CamPos
	cam.Start( view )

	-- Render each model
	for k, v in pairs( Dupe.Entities ) do

		render.SetColorModulation( 1, 1, 1, 1 )

		if ( istable( v.EntityMods ) ) then

			if ( istable( v.EntityMods.colour ) ) then
				render.SetColorModulation( v.EntityMods.colour.Color.r/255, v.EntityMods.colour.Color.g/255, v.EntityMods.colour.Color.b/255, v.EntityMods.colour.Color.a/255 )
			end

			if ( istable( v.EntityMods.material ) ) then
				render.MaterialOverride( Material( v.EntityMods.material.MaterialOverride ) )
			end

		end

		local ent = entities[k]

		render.Model(
		{
			model	=	v.Model,
			pos		=	v.Pos,
			angle	=	v.Angle,
			skin	=	v.Skin
		}, ent )

		if v.IsMediaPlayerEntity then

			local mp = MediaPlayer.GetById( v.DT.MediaPlayerID )
			if mp then
				mp:Draw( true, false )
				mp.Entity = mp._oldent
			else
				local w, h, pos, ang = ent:GetMediaPlayerPosition()
				cam.Start3D2D( pos, ang, 1 )
					surface.SetDrawColor( color_white )
					surface.SetMaterial( Material( "theater/STATIC" ) )
					surface.DrawTexturedRect( 0, 0, w, h )
				cam.End3D2D()
			end

		end

		render.MaterialOverride( nil )

	end

	cam.End()

	-- Enable lighting again (or it will affect outside of this loop!)
	render.SuppressEngineLighting( false )
	render.SetColorModulation( 1, 1, 1, 1 )

	--
	-- Finished with the entities - remove them all
	--
	for k, v in pairs( entities ) do
		v:Remove()
	end

	--
	-- Media Player branding
	--
	cam.Start2D()
		DrawOutlinedText( "MEDIA PLAYER", "DupeMediaText", 512/2, 512 - 34,
			color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	cam.End2D()

	local jpegdata = render.Capture{
		format		=	"jpeg",
		x			=	0,
		y			=	0,
		w			=	512,
		h			=	512,
		quality		=	100
	}

	return jpegdata

end

local function SaveMediaPlayerDupe( Dupe, jpegdata )

	--
	-- Encode and compress the dupe
	--
	local Dupe = util.TableToJSON( Dupe )
	if ( !isstring( Dupe ) ) then
		Msg( "There was an error converting the dupe to a json string" );
	end

	Dupe = util.Compress( Dupe )

	--
	-- And save it! (filename is automatic md5 in dupes/)
	--
	if ( engine.WriteDupe( Dupe, jpegdata ) ) then

		-- Disable the save button!!
		hook.Run( "DupeSaveUnavailable" )
		hook.Run( "DupeSaved" )

		MsgN( "Saved!" )

		-- TODO: Open tab and show dupe!

	end

end

hook.Add( "PostRenderVGUI", "MediaPlayerDupe", function()

	if not g_ClientSaveDupe then return end
	local isMediaDupe = false

	for _, ent in pairs( g_ClientSaveDupe.Entities or {} ) do
		if ent.IsMediaPlayerEntity then
			isMediaDupe = true
			break
		end
	end

	if isMediaDupe then
		MEDIAPLAYER_DUPE = g_ClientSaveDupe
		g_ClientSaveDupe = nil

		PreSaveMediaPlayerDupe( MEDIAPLAYER_DUPE )
	end

end )

hook.Add( "PostRender", "MediaPlayerDupe", function()

	if not ( MEDIAPLAYER_DUPE and MEDIAPLAYER_SAVE ) then return end

	local jpeg = RenderMediaPlayerDupe( MEDIAPLAYER_DUPE )
	SaveMediaPlayerDupe( MEDIAPLAYER_DUPE, jpeg )

	MEDIAPLAYER_DUPE = nil
	MEDIAPLAYER_SAVE = false

end )

