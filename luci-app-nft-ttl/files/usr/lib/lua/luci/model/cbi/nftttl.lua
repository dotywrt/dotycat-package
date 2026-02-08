local uci = require "luci.model.uci".cursor()
local util = require "luci.util"

local m = Map("nftttl", translate("TTL Settings"))

local support = m:section(SimpleSection)
support.template = "admin_support_info"

local s = m:section(NamedSection, "ttl", "ttl", translate("Settings"))
s.addremove = false

s:option(Flag, "enabled", translate("Enable"))

local ttl4 = s:option(Value, "value", translate("IPv4 TTL Value"))
ttl4.datatype = "uinteger"
ttl4.default = 64
ttl4.description = translate(
    "Set the TTL for IPv4 packets. Default is 64. Init.d service will apply this automatically."
)

local hl6 = s:option(Value, "hl6", translate("IPv6 HopLimit Value"))
hl6.datatype = "uinteger"
hl6.default = 64
hl6.description = translate(
    "Set the HopLimit for IPv6 packets. Default is 64. Init.d service will apply this automatically."
)

function m.on_after_commit(map)
    util.exec("/etc/init.d/nft-custom-ttl restart &")

    util.exec(string.format('logger -t nft-custom-ttl "TTL %s IPv4 / %s IPv6 updated and service restarted"', 
        uci:get("nftttl", "ttl", "value") or "64", 
        uci:get("nftttl", "ttl", "hl6") or "64"
    ))
end

return m
