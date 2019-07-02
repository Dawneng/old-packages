
local NXFS = require "nixio.fs"
local SYS  = require "luci.sys"
local HTTP = require "luci.http"
local DISP = require "luci.dispatcher"
local UTIL = require "luci.util"


local http = luci.http

ful = SimpleForm("upload", nil)
ful.reset = false
ful.submit = false

sul =ful:section(SimpleSection, "", translate(""))
o = sul:option(FileUpload, "")
o.title = translate("Upload Clash Configuration")
o.template = "clash/clash_upload"
o.description = translate("NB: Rename your config file to config.yml before upload. file will save to /etc/clash")
um = sul:option(DummyValue, "", nil)
um.template = "clash/clash_dvalue"

local dir, fd
dir = "/etc/clash/"
http.setfilehandler(
	function(meta, chunk, eof)
		if not fd then
			if not meta then return end

			if	meta and chunk then fd = nixio.open(dir .. meta.file, "w") end

			if not fd then
				um.value = translate("upload file error.")
				return
			end
		end
		if chunk and fd then
			fd:write(chunk)
		end
		if eof and fd then
			fd:close()
			fd = nil
			um.value = translate("File saved to") .. ' "/etc/clash/' .. meta.file .. '"'
		end
	end
)

if luci.http.formvalue("upload") then


	local f = luci.http.formvalue("ulfile")
	if #f <= 0 then
		um.value = translate("No specify upload file.")
	end
end


m = Map("clash")
s = m:section(TypedSection, "clash")
s.anonymous = true
s.addremove=false


local conf = "/etc/clash/config.yml"
sev = s:option(TextValue, "conf")
sev.readonly=true
update_time = SYS.exec("ls -l --full-time /etc/clash/config.yml|awk '{print $6,$7;}'")
sev.description = update_time
--sev.description = translate("Changes to config file must be made from source")
sev.rows = 20
sev.wrap = "off"
sev.cfgvalue = function(self, section)
	return NXFS.readfile(conf) or ""
end
sev.write = function(self, section, value)
end



return ful , m
