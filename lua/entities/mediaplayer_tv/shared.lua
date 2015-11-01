AddCSLuaFile()

ENT.PrintName 		= "Media Player TV"
ENT.Author 			= "Samuel Maddock"
ENT.Instructions 	= "Right click on the TV to see available Media Player options. Alternatively, press E on the TV to turn it on."
ENT.Category 		= "Media Player"

ENT.Type = "anim"
ENT.Base = "mediaplayer_base"

ENT.Spawnable = true

ENT.Model = Model( "models/gmod_tower/suitetv_large.mdl" )

ENT.PlayerConfig = {
	angle = Angle(-90, 90, 0),
	offset = Vector(6, 59.49, 103.65),
	width = 119,
	height = 69
}
