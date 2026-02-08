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

return m
