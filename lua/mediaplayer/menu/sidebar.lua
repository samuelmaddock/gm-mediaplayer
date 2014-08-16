local PANEL = {}

function PANEL:Init()

	self:SetPaintBackground( true )

	self:SetPaintBackgroundEnabled( false )
	self:SetPaintBorderEnabled( false )

	self:SetKeyboardInputEnabled( false )
	self:SetMouseInputEnabled( true )

	self.VolumeControls = vgui.Create( "MP.VolumeControls" )
	self.VolumeControls:Dock( BOTTOM )

end

function PANEL:Think()

end

function PANEL:Paint(w, h)

end

function PANEL:PerformLayout()



end

local MP_SIDEBAR = vgui.RegisterTable( PANEL, "EditablePanel" )

function MediaPlayer.OpenSidebar()

	local sidebar = MediaPlayer.Sidebar

	if not ValidPanel( sidebar ) then
		sidebar = vgui.CreateFromTable( MP_SIDEBAR )
	end

	sidebar:Open()

	MediaPlayer.Sidebar = sidebar

end
