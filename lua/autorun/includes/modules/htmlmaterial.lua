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
	<img id="mat" src="%s" width="100%%" height="100%%" />

	<style type="text/css">
	html, body {
		width: 100%%;
		height: 100%%;
		margin: 0;
		padding: 0;
		overflow: hidden;
	}
	%s
	</style>

	<script type="text/javascript">
	var mat = document.getElementById('mat');
	mat.onload = function() {
		setTimeout(function() { gmod.imageLoaded(); }, 100);
	}
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
		local download = downloads[idx]
		browserpool.release(browser)
		table.remove(downloads, idx)
	end

	if #downloads == 0 and TimerRunning then
		timer.Destroy(UpdateTimerName)
		TimerRunning = false
	end
end

local DefaultMat = Material("vgui/white")
local DefaultWidth = 128

local function enqueueUrl( url, styleName, key )
	cache[key] = DefaultMat

	browserpool.get(function(browser)
		local style = styles[styleName] or {}
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
		end)

		if not TimerRunning then
			timer.Create(UpdateTimerName, 0.05, 0, updateMaterials)
			timer.Start(UpdateTimerName)
			TimerRunning = true
		end

		local html = embedHtml:format(url, style.css or '')
		browser:SetHTML( html )
	end)
end

---
-- Renders a URL as a material.
--
-- @param url		URL.
-- @param style		HTMLMaterial style.
--
function HTMLMaterial( url, style )
	local key

	-- Build unique key for material
	if style then
		key = table.concat({url, '@', style})
	else
		key = url
	end

	-- Enqueue the URL to be downloaded if it hasn't been loaded yet.
	if cache[key] == nil then
		enqueueUrl( url, style, key )
	end

	-- Return cached URL
	return cache[key]
end

---
-- Registers a style that can be used with `HTMLMaterial`
--
-- @param name		Style name.
-- @param params	Table of style parameters.
--
function AddHTMLMaterialStyle(name, params)
	styles[name] = params
end
