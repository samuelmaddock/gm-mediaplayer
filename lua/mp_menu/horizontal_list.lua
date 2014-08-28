local PANEL = {}

function PANEL:Init()
	DPanelList.Init( self )

	self:EnableVerticalScrollbar( false )
	self:EnableHorizontal( true )
	self:SetAutoSize( true )
end

function PANEL:Rebuild()

	local OffsetX, OffsetY = 0, 0
	self.m_iBuilds = self.m_iBuilds + 1;

	self:CleanList()

	if ( self.Horizontal ) then

		local x, y = self.Padding, self.Padding;
		for k, panel in pairs( self.Items ) do

			if ( panel:IsVisible() ) then

				local OwnLine = (panel.m_strLineState and panel.m_strLineState == "ownline");

				local w = panel:GetWide()
				local h = panel:GetTall()

				local breakLine = ( not self.m_bSizeToContents and
					( x > self.Padding ) and
					(x + w > self:GetWide() or OwnLine) )

				if breakLine then

					x = self.Padding
					y = y + h + self.Spacing

				end

				if ( self.m_fAnimTime > 0 and self.m_iBuilds > 1 ) then
					panel:MoveTo( x, y, self.m_fAnimTime, 0, self.m_fAnimEase )
				else
					panel:SetPos( x, y )
				end

				x = x + w + self.Spacing

				OffsetX = x
				OffsetY = y + h + self.Spacing

				if ( OwnLine ) then

					x = self.Padding
					y = y + h + self.Spacing

				end

			end

		end

	else

		for k, panel in pairs( self.Items ) do

			if ( panel:IsVisible() ) then

				if ( self.m_bNoSizing ) then
					panel:SizeToContents()
					if ( self.m_fAnimTime > 0 and self.m_iBuilds > 1 ) then
						panel:MoveTo( (self:GetCanvas():GetWide() - panel:GetWide()) * 0.5, self.Padding + OffsetY, self.m_fAnimTime, 0, self.m_fAnimEase )
					else
						panel:SetPos( (self:GetCanvas():GetWide() - panel:GetWide()) * 0.5, self.Padding + OffsetY )
					end
				else
					panel:SetSize( self:GetCanvas():GetWide() - self.Padding * 2, panel:GetTall() )
					if ( self.m_fAnimTime > 0 and self.m_iBuilds > 1 ) then
						panel:MoveTo( self.Padding, self.Padding + OffsetY, self.m_fAnimTime, self.m_fAnimEase )
					else
						panel:SetPos( self.Padding, self.Padding + OffsetY )
					end
				end

				-- Changing the width might ultimately change the height
				-- So give the panel a chance to change its height now,
				-- so when we call GetTall below the height will be correct.
				-- True means layout now.
				panel:InvalidateLayout( true )

				OffsetY = OffsetY + panel:GetTall() + self.Spacing

			end

		end

		OffsetY = OffsetY + self.Padding

	end

	self:GetCanvas():SetWide( OffsetX + self.Padding - self.Spacing )
	self:GetCanvas():SetTall( OffsetY + self.Padding - self.Spacing )

	-- Although this behaviour isn't exactly implied, center vertically too
	if ( self.m_bNoSizing and self:GetCanvas():GetTall() < self:GetTall() ) then
		self:GetCanvas():SetPos( 0, (self:GetTall()-self:GetCanvas():GetTall()) * 0.5 )
	end

end

function PANEL:PerformLayout()

	local Wide = self:GetWide()
	local YPos = 0

	self:Rebuild()

	if self.VBar and not m_bSizeToContents then

		self.VBar:SetPos( self:GetWide() - 13, 0 )
		self.VBar:SetSize( 13, self:GetTall() )
		self.VBar:SetUp( self:GetTall(), self.pnlCanvas:GetTall() )
		YPos = self.VBar:GetOffset()

		if ( self.VBar.Enabled ) then Wide = Wide - 13 end

	end

	if self:GetAutoSize() then

		self:SetWide( self.pnlCanvas:GetWide() )
		self:SetTall( self.pnlCanvas:GetTall() )
		self.pnlCanvas:SetPos( 0, 0 )

	else

		self.pnlCanvas:SetPos( 0, YPos )
		self.pnlCanvas:SetWide( Wide )

	end

end

derma.DefineControl( "DHorizontalList", "", PANEL, "DPanelList" )
