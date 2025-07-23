module("luci.controller.admin.services", package.seeall)

function index()
    entry({"admin", "services", "appmanager"}, firstchild(), _("DStore"), 10).dependent = false

    -- Tab entries (reordered)
    entry({"admin", "services", "appmanager", "all"}, template("appmanager/all"), _("All"), 1)
    entry({"admin", "services", "appmanager", "installed"}, template("appmanager/installed"), _("Installed"), 2)
    entry({"admin", "services", "appmanager", "not_installed"}, template("appmanager/not_installed"), _("Not Installed"), 3)
    entry({"admin", "services", "appmanager", "update"}, template("appmanager/update"), _("Update"), 4)
    entry({"admin", "services", "appmanager", "settings"}, cbi("appmanager/settings"), _("Settings"), 5)

    -- API endpoints
    entry({"admin", "services", "appmanager", "api", "list"}, call("action_app_json"), nil).leaf = true
    entry({"admin", "services", "appmanager", "api", "manage"}, call("action_app_manage"), nil).leaf = true
end

function action_app_manage()
    local url = luci.http.formvalue("url")
    local pkg = luci.http.formvalue("pkg")
    local action = luci.http.formvalue("do")

    luci.http.prepare_content("text/plain")

    if action == "list" then
        luci.http.write(luci.sys.exec("opkg list-installed"))
        return
    end

    if action == "install" and url and url:match("^https?://") and pkg then
        luci.http.write("Installing " .. pkg .. "...\n\n")

        local tmp_path = "/tmp/app.ipk"

        -- Attempt using wget first
        luci.http.write("Trying to download with wget...\n")
        local wget_cmd = string.format("wget -O '%s' '%s' 2>&1", tmp_path, url)
        local wget_output = luci.sys.exec(wget_cmd)

        -- Check if wget downloaded the file
        local wget_success = nixio.fs.stat(tmp_path) and nixio.fs.stat(tmp_path).size > 0

        if not wget_success then
            luci.http.write("wget failed, retrying with curl...\n")
            local curl_cmd = string.format("curl -L --retry 3 -o '%s' '%s' 2>&1", tmp_path, url)
            local curl_output = luci.sys.exec(curl_cmd)

            -- Output curl result
            luci.http.write(curl_output .. "\n")
        else
            -- Output wget result
            luci.http.write(wget_output .. "\n")
        end

        -- Final check: does the file exist and is not empty?
        local file_stat = nixio.fs.stat(tmp_path)
        if file_stat and file_stat.size > 0 then
            luci.http.write("\nInstalling package...\n")
            luci.http.write(luci.sys.exec("opkg install " .. tmp_path .. " 2>&1"))
            luci.sys.exec("rm -f " .. tmp_path)
        else
            luci.http.write("\nDownload failed. Could not install package.\n")
        end

        return
    end

    if action == "uninstall" and pkg then
        luci.http.write("Uninstalling " .. pkg .. "...\n\n")
        luci.http.write(luci.sys.exec("opkg remove " .. pkg .. " 2>&1"))
        return
    end

    luci.http.status(400, "Bad Request")
    luci.http.write("Invalid parameters.\n")
end


function action_app_json()
    local uci = require "luci.model.uci".cursor()
    local json = require "luci.jsonc"
    local util = require "luci.util"
    local urls = uci:get_list("dstore", "settings", "json_urls")

    if not urls or #urls == 0 then
        luci.http.status(500, "Missing JSON URLs in /etc/config/dstore")
        luci.http.write("Error: No 'json_urls' found in /etc/config/dstore")
        return
    end

    -- Get installed packages and versions
    local installed_map = {}
    for line in io.popen("opkg list-installed"):lines() do
        local pkg, ver = line:match("^(%S+)%s+%-%s+(.+)$")
        if pkg and ver then
            installed_map[pkg] = ver
        end
    end

    local app_map = {}

    local function normalize_version(ver)
        return ver:gsub("^v", "")
    end

    local function compare_versions(a, b)
        local function split(v)
            local parts = {}
            for p in v:gmatch("[^%.%-]+") do
                table.insert(parts, tonumber(p) or p)
            end
            return parts
        end

        local pa = split(a)
        local pb = split(b)
        local len = math.max(#pa, #pb)

        for i = 1, len do
            local va = pa[i] or 0
            local vb = pb[i] or 0
            if type(va) == "number" and type(vb) == "number" then
                if va ~= vb then return va > vb end
            else
                va = tostring(va)
                vb = tostring(vb)
                if va ~= vb then return va > vb end
            end
        end
        return false
    end

    for _, url in ipairs(urls) do
        if url:match("^https?://") then
            local output = luci.sys.exec("wget -qO- '" .. url .. "'")
            local ok, data = pcall(json.parse, output)

            if ok and type(data) == "table" then
                for _, app in ipairs(data) do
                    if app.package and app.version then
                        local pkg = app.package
                        local new_ver = normalize_version(app.version)

                        -- Add installed version
                        if installed_map[pkg] then
                            app.installed_version = normalize_version(installed_map[pkg])
                        end

                        if not app_map[pkg] or compare_versions(new_ver, normalize_version(app_map[pkg].version)) then
                            app_map[pkg] = app
                        end
                    end
                end
            else
                util.perror("Failed to parse JSON from: " .. url)
            end
        end
    end

    local all_apps = {}
    for _, app in pairs(app_map) do
        table.insert(all_apps, app)
    end

    luci.http.prepare_content("application/json")
    luci.http.write(json.stringify(all_apps))
end
