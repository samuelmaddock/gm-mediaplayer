local mporder = 3200

--
-- Adds a media player property.
--
-- Blue icons correspond to admin actions.
--
local function AddMediaPlayerProperty( name, config )
	-- Assign incrementing order ID
	config.Order = mporder
	mporder = mporder + 1

	properties.Add( name, config )
end

local function IsMediaPlayer( self, ent, ply )
	return IsValid(ent) and IsValid(ply) and
			IsValid(ent:GetMediaPlayer()) and
			gamemode.Call( "CanProperty", ply, self.InternalName, ent )
end

local function IsPrivilegedMediaPlayer( self, ent, ply )
	return IsMediaPlayer( self, ent, ply ) and
		( ply:IsAdmin() or ent:GetOwner() == ply )
end

local function HasMedia( mp )
	return mp:GetPlayerState() >= MP_STATE_PLAYING
end

AddMediaPlayerProperty( "mp-pause", {
	MenuLabel	=	"Pause",
	MenuIcon	=	"icon16/control_pause_blue.png",

	Filter		=	function( self, ent, ply )
		if not IsPrivilegedMediaPlayer(self, ent, ply) then return end
		local mp = ent:GetMediaPlayer()
		return IsValid(mp) and mp:GetPlayerState() == MP_STATE_PLAYING
	end,

	Action		=	function( self, ent )
		MediaPlayer.Pause( ent )
	end
})

AddMediaPlayerProperty( "mp-resume", {
	MenuLabel	=	"Resume",
	MenuIcon	=	"icon16/control_play_blue.png",

	Filter		=	function( self, ent, ply )
		if not IsPrivilegedMediaPlayer(self, ent, ply) then return end
		local mp = ent:GetMediaPlayer()
		return IsValid(mp) and mp:GetPlayerState() == MP_STATE_PAUSED
	end,

	Action		=	function( self, ent )
		MediaPlayer.Pause( ent )
	end
})

AddMediaPlayerProperty( "mp-skip", {
	MenuLabel	=	"Skip",
	MenuIcon	=	"icon16/control_end_blue.png",

	Filter		=	function( self, ent, ply )
		if not IsPrivilegedMediaPlayer(self, ent, ply) then return end
		local mp = ent:GetMediaPlayer()
		return IsValid(mp) and HasMedia(mp)
	end,

	Action		=	function( self, ent )
		MediaPlayer.Skip( ent )
	end
})

AddMediaPlayerProperty( "mp-seek", {
	MenuLabel	=	"Seek",
	-- MenuIcon	=	"icon16/timeline_marker.png",
	MenuIcon	=	"icon16/control_fastforward_blue.png",

	Filter		=	function( self, ent, ply )
		if not IsPrivilegedMediaPlayer(self, ent, ply) then return end
		local mp = ent:GetMediaPlayer()
		return IsValid(mp) and HasMedia(mp)
	end,

	Action		=	function( self, ent )

		Derma_StringRequest(
			"Media Player",
			"Enter a time in HH:MM:SS format (hours, minutes, seconds):",
			"", -- Default text
			function( time )
				MediaPlayer.Seek( ent, time )
			end,
			function() end,
			"Seek",
			"Cancel"
		)

	end
})

AddMediaPlayerProperty( "mp-request-url", {
	MenuLabel	=	"Request URL",
	MenuIcon	=	"icon16/link_add.png",
	Filter		=	IsMediaPlayer,

	Action		=	function( self, ent )

		MediaPlayer.OpenRequestMenu( ent )

	end
})

AddMediaPlayerProperty( "mp-copy-url", {
	MenuLabel	=	"Copy URL to clipboard",
	MenuIcon	=	"icon16/paste_plain.png",

	Filter		=	function( self, ent, ply )
		if not IsMediaPlayer(self, ent, ply) then return end
		local mp = ent:GetMediaPlayer()
		return IsValid(mp) and HasMedia(mp)
	end,

	Action		=	function( self, ent )

		local mp = ent:GetMediaPlayer()
		local media = mp and mp:CurrentMedia()
		if not IsValid(media) then return end

		SetClipboardText( media:Url() )
		LocalPlayer():ChatPrint( "Media URL has been copied into your clipboard." )

	end
})

AddMediaPlayerProperty( "mp-enable", {
	MenuLabel	=	"Turn On",
	MenuIcon	=	"icon16/lightbulb.png",

	Filter		=	function( self, ent, ply )
		return IsValid(ent) and IsValid(ply) and
				ent.IsMediaPlayerEntity and
				not IsValid(ent:GetMediaPlayer()) and
				gamemode.Call( "CanProperty", ply, self.InternalName, ent )
	end,

	Action		=	function( self, ent )
		MediaPlayer.RequestListen( ent )
	end
})

AddMediaPlayerProperty( "mp-disable", {
	MenuLabel	=	"Turn Off",
	MenuIcon	=	"icon16/lightbulb_off.png",

	Filter		=	function( self, ent, ply )
		return IsValid(ent) and IsValid(ply) and
				ent.IsMediaPlayerEntity and
				IsValid(ent:GetMediaPlayer()) and
				gamemode.Call( "CanProperty", ply, self.InternalName, ent )
	end,

	Action		=	function( self, ent )
		MediaPlayer.RequestListen( ent )
	end
})
