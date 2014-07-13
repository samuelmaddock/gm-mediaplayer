local file = file

function file.ReadJSON( name, path )
	path = path or "DATA"

	local json = file.Read( name, path )
	if not json then return end

	return util.JSONToTable(json)
end
