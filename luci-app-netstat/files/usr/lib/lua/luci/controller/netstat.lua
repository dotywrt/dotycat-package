module("luci.controller.netstat", package.seeall)

function index()
	entry({"admin", "modem", "netstat_config"}, cbi("netstat/config"), _("Netstat Config"), 20).leaf = true
end
