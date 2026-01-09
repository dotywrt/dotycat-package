module("luci.controller.modeminfo", package.seeall)

function index()
    entry({"admin", "modem"}, firstchild(), _("Modem"), 40).dependent = false
    entry({"admin", "modem", "modeminfo"}, call("action_modeminfo"), _("Modem Info"), 20).dependent = false
    entry({"admin", "modem", "modeminfo", "get_info"}, call("get_modem_info")).dependent = false
    entry({"admin", "modem", "modeminfo", "set_refresh"}, call("set_refresh")).dependent = false
    entry({"admin", "modem", "modeminfo", "get_ports_info"}, call("get_ports_info")).dependent = false
    entry({"admin", "modem", "modeminfo", "save_port"}, call("save_port")).dependent = false
end

function action_modeminfo()
    local uci = require "luci.model.uci".cursor()

    local modeminfo = {}
    local file = io.open("/tmp/modeminfo", "r")
    if file then
        for line in file:lines() do
            local key, value = line:match("^(.-):%s*(.*)$")
            if key and value then
                modeminfo[key] = value
            end
        end
        file:close()
    end

    local refresh_rate = uci:get("modeminfo", "settings", "refresh_rate") or "5"

    local saved_comm = uci:get("modeminfo", "settings", "comm") or "/dev/ttyUSB3"

    luci.template.render("modeminfo", {modeminfo = modeminfo, refresh_rate = refresh_rate, saved_comm = saved_comm})
end

function get_ports_info()
    local available_ports = {}
    local fs = require "nixio.fs"
    local uci = require "luci.model.uci".cursor()

    for file in fs.dir("/dev") do
        if file:match("^ttyUSB%d+$") or file:match("^ttyACM%d+$") then
            available_ports[#available_ports + 1] = "/dev/" .. file
        end
    end

    local saved_comm = uci:get("modeminfo", "settings", "comm") or "/dev/ttyUSB3"

    luci.http.prepare_content("application/json")
    luci.http.write_json({ports = available_ports, default_port = saved_comm})
end

function save_port()
    local uci = require "luci.model.uci".cursor()
    local http = require "luci.http"
    
    local selected_port = http.formvalue("commport")
    
    luci.sys.exec("logger -t modeminfo 'Attempting to save selected comm port: " .. (selected_port or "None") .. "'")
    
    if selected_port then
        if not uci:get("modeminfo", "settings") then
            luci.sys.exec("logger -t modeminfo 'Settings section does not exist, creating it'")
            uci:section("modeminfo", "settings", "settings")
        end

        luci.sys.exec("logger -t modeminfo 'Saving selected port: " .. selected_port .. "'")
        uci:set("modeminfo", "settings", "comm", selected_port)

        uci:commit("modeminfo")
        luci.sys.exec("logger -t modeminfo 'Committed selected port: " .. selected_port .. "'")
    else
        luci.sys.exec("logger -t modeminfo 'Error: No comm port selected'")
    end

    luci.http.redirect(luci.dispatcher.build_url("admin/modem/modeminfo"))
end


function update_cron(refresh_rate)
    luci.sys.call("crontab -l | grep -v '/usr/bin/modeminfo' | crontab -")
    
    if refresh_rate then
        local cron_job = "*/" .. refresh_rate .. " * * * * /bin/sh /usr/bin/modeminfo > /dev/null 2>&1"
        luci.sys.call(string.format('(crontab -l ; echo "%s") | crontab -', cron_job))
    end
end

function set_refresh()
    local uci = require "luci.model.uci".cursor()
    local http = require "luci.http"
    
    local refresh_rate = http.formvalue("refresh_rate")

    luci.sys.exec("logger -t modeminfo 'Attempting to save refresh rate: " .. (refresh_rate or "None") .. "'")
    
    if refresh_rate then
        uci:set("modeminfo", "settings", "refresh_rate", refresh_rate)
        uci:commit("modeminfo")

        luci.sys.exec("logger -t modeminfo 'Saved refresh rate: " .. refresh_rate .. "'")
    else
        luci.sys.exec("logger -t modeminfo 'Error: No refresh rate selected'")
    end
    luci.http.redirect(luci.dispatcher.build_url("admin/modem/modeminfo"))
end


function get_modem_info()
    luci.sys.call("/bin/sh /usr/bin/modeminfo")

    local modeminfo = {}
    local file = io.open("/tmp/modeminfo", "r")
    if file then
        for line in file:lines() do
            local key, value = line:match("^(.-):%s*(.*)$")
            if key and value then
                modeminfo[key] = value
            end
        end
        file:close()
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(modeminfo)
end
