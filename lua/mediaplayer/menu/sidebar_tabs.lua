local math = math
local ceil = math.ceil
local clamp = math.Clamp

local surface = surface
local color_white = color_white

local PANEL = {}

PANEL.TabHeight = 43

function PANEL:Init()

	self:SetShowIcons( false )

	self:SetFadeTime( 0 )
	self:SetPadding( 0 )

	self.animFade = Derma_Anim( "Fade", self, self.CrossFade )

	self.Items = {}

end

function PANEL:Paint( w, h )

end

function PANEL:AddSheet( label, panel, material, NoStretchX, NoStretchY, Tooltip )

	if not IsValid( panel ) then return end

	local Sheet = {}

	Sheet.Name = label

	Sheet.Tab = vgui.Create( "MP.SidebarTab", self )
	Sheet.Tab:SetTooltip( Tooltip )
	Sheet.Tab:Setup( label, self, panel, material )

	Sheet.Panel = panel
	Sheet.Panel.NoStretchX = NoStretchX
	Sheet.Panel.NoStretchY = NoStretchY
	Sheet.Panel:SetPos( self:GetPadding(), self.TabHeight + self:GetPadding() )
	Sheet.Panel:SetVisible( false )

	panel:SetParent( self )

	table.insert( self.Items, Sheet )

	if not self:GetActiveTab() then
		self:SetActiveTab( Sheet.Tab )
		Sheet.Panel:SetVisible( true )
	end

	-- self.tabScroller:AddPanel( Sheet.Tab )

	return Sheet

end

function PANEL:PerformLayout()

	local ActiveTab = self:GetActiveTab()
	local Padding = self:GetPadding()

	if not ActiveTab then return end

	-- Update size now, so the height is definitiely right.
	ActiveTab:InvalidateLayout( true )

	local ActivePanel = ActiveTab:GetPanel()

	local numItems = #self.Items
	local tabWidth = ceil(self:GetWide() / numItems)

	local tab

	for k, v in pairs( self.Items ) do

		tab = v.Tab

		tab:SetSize( tabWidth, self.TabHeight )
		tab:SetPos( (k-1) * tabWidth )

		-- Handle tab panel visibility
		if tab:GetPanel() == ActivePanel then
			tab:GetPanel():SetVisible( true )
			tab:SetZPos( 100 )
		else
			tab:GetPanel():SetVisible( false )
			tab:SetZPos( 1 )
		end

		tab:ApplySchemeSettings()

	end

	ActivePanel:SetWide( self:GetWide() - Padding * 2 )
	ActivePanel:SetTall( (self:GetTall() - ActiveTab:GetTall() ) - Padding )

	ActivePanel:InvalidateLayout()

	-- Give the animation a chance
	self.animFade:Run()

end

derma.DefineControl( "MP.SidebarTabs", "", PANEL, "DPropertySheet" )


local SIDEBAR_TAB = {}

SIDEBAR_TAB.BgColor = Color( 28, 100, 157 )
SIDEBAR_TAB.SelectedBorderColor = color_white
SIDEBAR_TAB.SelectedBorderHeight = 2

function SIDEBAR_TAB:Init()

	self.BaseClass.Init( self )

	self:SetContentAlignment( 5 )
	self:SetTextInset( 0, 0 )

end

function SIDEBAR_TAB:Paint( w, h )

	surface.SetDrawColor( self.BgColor )
	surface.DrawRect( 0, 0, w, h )

	if self:IsActive() then
		surface.SetDrawColor( self.SelectedBorderColor )
		surface.DrawRect( 0, h - self.SelectedBorderHeight, w, self.SelectedBorderHeight )
	end

end

function SIDEBAR_TAB:ApplySchemeSettings()

	self:SetTextInset( 0, 0 )

	DLabel.ApplySchemeSettings( self )

end

derma.DefineControl( "MP.SidebarTab", "", SIDEBAR_TAB, "DTab" )
