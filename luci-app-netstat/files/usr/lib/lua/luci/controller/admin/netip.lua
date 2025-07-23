module("luci.controller.admin.netip", package.seeall)

function index()
    entry({"admin", "status", "netip_status"}, call("get_netip"), nil).leaf = true
end

function get_netip()
    local http  = require "luci.http"
    local json  = require "luci.jsonc"
    local sys   = require "luci.sys"

    local ip, org, city, country = "Unknown", "Unknown", "Unknown", "Unknown"

    local apis = {
        {
            url = "http://ip-api.com/json",
            parse = function(data)
                return data.query, data.org or "Unknown", data.city or "Unknown", data.country or "Unknown"
            end
        },
        {
            url = "https://ipwho.is/",
            parse = function(data)
                return data.ip, data.connection and data.connection.org or "Unknown", data.city or "Unknown", data.country or "Unknown"
            end
        },
        {
            url = "https://ipinfo.io/json",
            parse = function(data)
                return data.ip, data.org or "Unknown", data.city or "Unknown", data.country or "Unknown"
            end
        },
        {
            url = "https://ifconfig.co/json",
            parse = function(data)
                return data.ip, data.asn_org or data.org or "Unknown", data.city or "Unknown", data.country or "Unknown"
            end
        },
        {
            url = "https://ipapi.co/json",
            parse = function(data)
                return data.ip, data.org or "Unknown", data.city or "Unknown", data.country_name or data.country or "Unknown"
            end
        }
    }

    for _, api in ipairs(apis) do
        local raw = sys.exec("curl -s --max-time 3 '" .. api.url .. "'")
        local data = json.parse(raw or "{}")
        if data and (data.ip or data.query) then
            ip, org, city, country = api.parse(data)
            break
        end
    end

    http.prepare_content("application/json")
    http.write_json({
        ip = ip,
        org = org,
        city = city,
        country = country
    })
end
