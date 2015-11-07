AddCSLuaFile()

if SERVER then
	resource.AddFile( "models/gmod_tower/suitetv_large.mdl" )
	resource.AddFile( "materials/models/gmod_tower/suitetv_large.vmt" )
	resource.AddSingleFile( "materials/entities/mediaplayer_tv.png" )
end

DEFINE_BASECLASS( "mediaplayer_base" )

ENT.PrintName 		= "Big Screen TV"
ENT.Author 			= "Samuel Maddock"
ENT.Instructions 	= "Right click on the TV to see available Media Player options. Alternatively, press E on the TV to turn it on."
ENT.Category 		= "Media Player"

ENT.Type = "anim"
ENT.Base = "mediaplayer_base"

ENT.Spawnable = true

ENT.Model = Model( "models/gmod_tower/suitetv_large.mdl" )

list.Set( "MediaPlayerModelConfigs", ENT.Model, {
	angle = Angle(-90, 90, 0),
	offset = Vector(6, 59.49, 103.65),
	width = 119,
	height = 69
} )

function ENT:SetupDataTables()
	BaseClass.SetupDataTables( self )

	self:NetworkVar( "String", 1, "MediaThumbnail" )
end

if SERVER then

	function ENT:SetupMediaPlayer( mp )
		mp:on("mediaChanged", function(media) self:OnMediaChanged(media) end)
	end

	function ENT:OnMediaChanged( media )
		self:SetMediaThumbnail( media and media:Thumbnail() or "" )
	end

else -- CLIENT

	local draw = draw
	local surface = surface
	local Start3D2D = cam.Start3D2D
	local End3D2D = cam.End3D2D
	local DrawHTMLMaterial = DrawHTMLMaterial

	local TEXT_ALIGN_CENTER = TEXT_ALIGN_CENTER
	local color_white = color_white

	local StaticMaterial = Material( "theater/STATIC" )
	local TextScale = 700

	function ENT:Draw()
		self:DrawModel()

		local mp = self:GetMediaPlayer()

		if not mp then
			self:DrawMediaPlayerOff()
		end
	end

	local HTMLMAT_STYLE_ARTWORK_BLUR = 'htmlmat.style.artwork_blur'
	AddHTMLMaterialStyle( HTMLMAT_STYLE_ARTWORK_BLUR, {
		width = 720,
		height = 480
	}, HTMLMAT_STYLE_BLUR )

	local DrawThumbnailsCvar = MediaPlayer.Cvars.DrawThumbnails

	function ENT:DrawMediaPlayerOff()
		local w, h, pos, ang = self:GetMediaPlayerPosition()
		local thumbnail = self:GetMediaThumbnail()

		Start3D2D( pos, ang, 1 )
			if DrawThumbnailsCvar:GetBool() and thumbnail != "" then
				DrawHTMLMaterial( thumbnail, HTMLMAT_STYLE_ARTWORK_BLUR, w, h )
			else
				surface.SetDrawColor( color_white )
				surface.SetMaterial( StaticMaterial )
				surface.DrawTexturedRect( 0, 0, w, h )
			end
		End3D2D()


		local scale = w / TextScale
		Start3D2D( pos, ang, scale )
			local tw, th = w / scale, h / scale
			draw.SimpleText( "Press E to begin watching", "MediaTitle",
				tw/2, th/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		End3D2D()
	end

end
