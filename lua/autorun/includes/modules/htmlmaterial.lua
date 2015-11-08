local ipairs = ipairs
local table = table
local timer = timer
local ceil = math.ceil
local log = math.log
local pow = math.pow

local tblconcat = table.concat

local cache = {}
local downloads = {}
local styles = {}

local embedHtml = [[
<!doctype html>
<html>
<head>
	<meta charset="utf-8">
</head>
<body>
	<script>
	var src = '%s';
	</script>
	<img id="mat">

	<style>
	html, body {
		width: 100%%;
		height: 100%%;
		margin: 0;
		padding: 0;
		overflow: hidden;
	}
	%s
	</style>

	<script>
	var mat = document.getElementById('mat');
	mat.onload = function() {
		setTimeout(function() {
			gmod.imageLoaded();
		}, 100);
	};
	mat.onerror = function() {
		gmod.imageLoaded();
	};
	mat.src = src;
	</script>
</body>
</html>]]

local UpdateTimerName = "HtmlMatUpdate"
local TimerRunning = false

local function updateCache(download)
	download.browser:UpdateHTMLTexture()
	cache[download.key] = download.browser:GetHTMLMaterial()
end

local function updateMaterials()
	for _, download in ipairs(downloads) do
		updateCache(download)
	end
end

local function onImageLoaded(key, browser)
	local idx

	for k, v in pairs(downloads) do
		if v.key == key then
			idx = k
			break
		end
	end

	if idx > 0 then
		-- html materials are unique to each browser; re-using a browser will
		-- result in previous materials being updated. Therefore, used browsers
		-- must be destroyed rather than pooled.
		local download = downloads[idx]
		browserpool.release(browser, true)
		table.remove(downloads, idx)
	end

	if #downloads == 0 and TimerRunning then
		timer.Destroy(UpdateTimerName)
		TimerRunning = false
	end
end

local DefaultMat = Material("vgui/white")
local DefaultWidth = 128
local DefaultStyle = {}

local function enqueueUrl( url, styleName, key, callback )
	cache[key] = DefaultMat

	browserpool.get(function(browser)
		local style = styles[styleName] or DefaultStyle
		local w = style.width or DefaultWidth
		local h = style.height or w

		browser:SetSize( w, h )

		local download = {
			url = url,
			key = key,
			browser = browser
		}

		table.insert(downloads, download)

		browser:AddFunction("gmod", "imageLoaded", function()
			updateCache(download)
			onImageLoaded(key, browser)

			if type(callback) == "function" then
				callback( cache[key] )
			end
		end)

		if not TimerRunning then
			timer.Create(UpdateTimerName, 0.05, 0, updateMaterials)
			timer.Start(UpdateTimerName)
			TimerRunning = true
		end

		local html = (style.html or embedHtml):format(url, style.css or '')
		browser:SetHTML( html )
	end)
end

-- cached for performance
local MAT_STR_TABLE = { '', '@', '' }

---
-- Renders a URL as a material.
--
-- @param url		URL.
-- @param style		HTMLMaterial style.
--
function HTMLMaterial( url, style, callback )
	if not url then
		return DefaultMat
	end

	local key

	-- Build unique key for material
	if style then
		MAT_STR_TABLE[1] = url
		MAT_STR_TABLE[3] = style
		key = tblconcat( MAT_STR_TABLE )
	else
		key = url
	end

	-- Enqueue the URL to be downloaded if it hasn't been loaded yet.
	if cache[key] == nil then
		enqueueUrl( url, style, key, callback )
	elseif callback then
		callback( cache[key] )
	end

	-- Return cached URL
	return cache[key]
end

local SetDrawColor = surface.SetDrawColor
local SetMaterial = surface.SetMaterial
local DrawTexturedRect = surface.DrawTexturedRect

function CeilPower2(n)
	return pow(2, ceil(log(n) / log(2)))
end

function DrawHTMLMaterial( url, styleName, w, h )
	local mat = HTMLMaterial( url, styleName )
	local style = styles[styleName] or DefaultStyle

	-- Desired dimensions
	local width = style.width or DefaultWidth
	local height = style.height or w

	-- Convert to scalar
	w = w / width
	h = h / height

	-- Fix for non-power-of-two html panel size
	width = CeilPower2(width)
	height = CeilPower2(height)

	SetDrawColor( color_white )
	SetMaterial( mat )
	DrawTexturedRect( 0, 0, w * width, h * height )
end

---
-- Registers a style that can be used with `HTMLMaterial`
--
-- @param name		Style name.
-- @param params	Table of style parameters.
--
function AddHTMLMaterialStyle( name, params, base )
	params = params or {}

	if base then
		table.Merge( params, table.Copy( styles[base] or {} ) )
	end

	styles[name] = params
end

HTMLMAT_STYLE_BLUR       = 'htmlmat.style.blur'
HTMLMAT_STYLE_GRAYSCALE  = 'htmlmat.style.grayscale'
HTMLMAT_STYLE_SEPIA      = 'htmlmat.style.sepia'
HTMLMAT_STYLE_INVERT     = 'htmlmat.style.invert'
HTMLMAT_STYLE_CIRCLE     = 'htmlmat.style.circle'
HTMLMAT_STYLE_COVER      = 'htmlmat.style.cover'
HTMLMAT_STYLE_COVER_IMG  = 'htmlmat.style.coverimg'

AddHTMLMaterialStyle( HTMLMAT_STYLE_BLUR, {
	css = [[img {
	-webkit-filter: blur(8px);
	-webkit-transform: scale(1.1, 1.1);
}]]
})
AddHTMLMaterialStyle( HTMLMAT_STYLE_GRAYSCALE, {
	css = [[img { -webkit-filter: grayscale(1); }]]
})
AddHTMLMaterialStyle( HTMLMAT_STYLE_SEPIA, {
	css = [[img { -webkit-filter: sepia(1); }]]
})
AddHTMLMaterialStyle( HTMLMAT_STYLE_INVERT, {
	css = [[img { -webkit-filter: invert(1); }]]
})
AddHTMLMaterialStyle( HTMLMAT_STYLE_CIRCLE, {
	css = [[img { border-radius: 50%; }]]
})
AddHTMLMaterialStyle( HTMLMAT_STYLE_COVER, {
	html = [[
<script>
var src = '%s';
</script>

<style type="text/css">
html, body {
	width: 100%%;
	height: 100%%;
	margin: 0;
	padding: 0;
	overflow: hidden;
}

#mat {
	background: no-repeat 50%% 50%%;
	background-size: cover;
	width: 100%%;
	height: 100%%;
}

%s
</style>

<div id="mat"></div>

<script type="application/javascript">
var mat = document.getElementById('mat');
mat.style.backgroundImage = 'url('+src+')';

var img = new Image();
img.onload = function() {
	setTimeout(function() {
		gmod.imageLoaded();
	}, 100);
};
img.onerror = gmod.imageLoaded.bind(gmod);
img.src = src;
</script>
]]
})

-- Use this if you want to use -webkit-filter blur on the image;
-- you'll also need to use a transform to scale it a bit. This prevents
-- the edges from blurring as seen with background-size cover.
AddHTMLMaterialStyle( HTMLMAT_STYLE_COVER_IMG, {
	html = [[
<script>
var src = '%s';
</script>

<style type="text/css">
html, body {
	width: 100%%;
	height: 100%%;
	margin: 0;
	padding: 0;
	overflow: hidden;
}
img {
	width: auto;
	height: auto;
	position: absolute;
	top: 50%%;
	left: 50%%;
	-webkit-transform: translate(-50%%, -50%%);
}
%s
</style>

<img id="mat">

<script type="application/javascript">
var mat = document.getElementById('mat');
mat.onload = function() {
	if (mat.width > mat.height) {
		mat.style.height = '100%%';
	} else {
		mat.style.width = '100%%';
	}
	setTimeout(function() {
		gmod.imageLoaded();
	}, 100);
};
mat.onerror = function() {
	gmod.imageLoaded();
};
mat.src = src;
</script>
]]
})
