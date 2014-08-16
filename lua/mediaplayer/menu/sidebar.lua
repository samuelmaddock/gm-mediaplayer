include "volume_control.lua"

local PANEL = {}

function PANEL:Init()

	self:SetPaintBackgroundEnabled( true )
	self:SetPaintBorderEnabled( false )

	self:SetSize( 385, 580 )

	self.VolumeControls = vgui.Create( "MP.VolumeControl", self )
	self.VolumeControls:Dock( BOTTOM )
	self.VolumeControls:SetHeight( 48 )

end

function PANEL:Think()

end

function PANEL:Paint(w, h)

	surface.SetDrawColor( 0, 0, 0, 140 )
	surface.DrawRect( 0, 0, w, h )

end

function PANEL:PerformLayout()

	self:Center()
	self:AlignLeft( 10 )

end

local MP_SIDEBAR = vgui.RegisterTable( PANEL, "EditablePanel" )


function MediaPlayer.ShowSidebar()

	local sidebar = MediaPlayer._Sidebar

	if not ValidPanel( sidebar ) then
		sidebar = vgui.CreateFromTable( MP_SIDEBAR )
	end

	sidebar:MakePopup()
	sidebar:ParentToHUD()

	sidebar:SetKeyboardInputEnabled( false )
	sidebar:SetMouseInputEnabled( true )

	MediaPlayer._Sidebar = sidebar

end

function MediaPlayer.HideSidebar()

	local sidebar = MediaPlayer._Sidebar

	if ValidPanel( sidebar ) then
		sidebar:Remove()
		MediaPlayer._Sidebar = nil
	end

end

control.AddKeyPress( KEY_C, "MP.ShowSidebar", MediaPlayer.ShowSidebar )
control.AddKeyRelease( KEY_C, "MP.HideSidebar", MediaPlayer.HideSidebar )
