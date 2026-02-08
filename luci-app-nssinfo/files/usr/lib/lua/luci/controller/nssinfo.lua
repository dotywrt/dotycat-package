module("luci.controller.nssinfo", package.seeall)

function index()
    entry({"admin", "status", "nssinfo"}, call("action_index"), "NSS Info", 50).dependent = false
end

function action_index()
    local tpl = require "luci.template"
    local sys = require "luci.sys"
    local nss_diag = sys.exec("nss_diag 2>/dev/null")
    local rmnet_stats = sys.exec("cat /sys/kernel/debug/qca-nss-drv/stats/rmnet_rx 2>/dev/null")

    tpl.render("nssinfo/index", { nss_diag = nss_diag, rmnet_stats = rmnet_stats })
end
