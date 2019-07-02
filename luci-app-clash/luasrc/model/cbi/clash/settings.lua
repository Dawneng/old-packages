
local NXFS = require "nixio.fs"
local SYS  = require "luci.sys"
local HTTP = require "luci.http"
local DISP = require "luci.dispatcher"
local UTIL = require "luci.util"



m = Map("clash")
s = m:section(TypedSection, "clash")
s.anonymous = true
s.addremove=false




md = s:option(Flag, "proxylan", translate("Proxy Lan IP"))
md.default = 1
md.rmempty = false
md.description = translate("Only selected IPs will be proxied if enabled")
md:depends("rejectlan", 0)


o = s:option(DynamicList, "lan_ac_ips", translate("Proxy Lan List"))
o.datatype = "ipaddr"
o.description = translate("Only selected IPs will be proxied")
luci.ip.neighbors({ family = 4 }, function(entry)
       if entry.reachable then
               o:value(entry.dest:string())
       end
end)
o:depends("proxylan", 1)


update_time = SYS.exec("ls -l --full-time /etc/clash/Country.mmdb|awk '{print $6,$7;}'")
o = s:option(Button,"update",translate("Update GEOIP Database")) 
o.title = translate("GEOIP Database")
o.inputtitle = translate("Update GEOIP Database")
o.description = update_time
o.inputstyle = "reload"
o.write = function()
  SYS.call("bash /usr/share/clash/ipdb.sh >>/tmp/clash.log 2>&1 &")
  HTTP.redirect(DISP.build_url("admin", "services", "clash","settings"))
end




md = s:option(Flag, "rejectlan", translate("Bypass Lan IP"))
md.default = 1
md.rmempty = false
md.description = translate("Selected IPs will not be proxied if enabled")
md:depends("proxylan", 0)


o = s:option(DynamicList, "lan_ips", translate("Bypass Lan List"))
o.datatype = "ipaddr"
o.description = translate("Selected IPs will not be proxied")
luci.ip.neighbors({ family = 4 }, function(entry)
       if entry.reachable then
               o:value(entry.dest:string())
       end
end)
o:depends("rejectlan", 1)

y = s:option(Flag, "dnsforwader", translate("DNS Forwarding"))
y.default = 1
y.rmempty = false
y.description = translate("Enabling will set custom DNS forwarder in DHCP and DNS Settings")



md = s:option(Flag, "mode", translate("Custom DNS"))
md.default = 1
md.rmempty = false
md.description = translate("Enabling Custom DNS will Overwrite your config.yml dns section")


local dns = "/usr/share/clash/dns.yml"
o = s:option(TextValue, "dns",translate("Modify yml DNS"))
o.template = "clash/tvalue"
o.rows = 21
o.wrap = "off"
o.cfgvalue = function(self, section)
	return NXFS.readfile(dns) or ""
end
o.write = function(self, section, value)
	NXFS.writefile(dns, value:gsub("\r\n", "\n"))
	--SYS.call("/etc/init.d/adbyby restart")
end
o.description = translate("Please modify the file here.")
o:depends("mode", 1)

return m


