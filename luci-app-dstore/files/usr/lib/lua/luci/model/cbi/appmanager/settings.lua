local m = Map("dstore", nil, translate("Configure one or more JSON sources for available applications."))

local s = m:section(NamedSection, "settings", "settings", translate("Configuration"))
s.anonymous = true

local json_urls = s:option(DynamicList, "json_urls", translate("App List JSON URLs"),
    translate("Enter one or more URLs to JSON files containing available apps."))

json_urls.datatype = "string"
json_urls.placeholder = "https://raw.githubusercontent.com/NuhaHumaira/doty_store/main/apps.json"

return m
