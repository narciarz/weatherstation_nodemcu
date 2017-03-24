local MAX_SIDS = 10
local CONFIG_FILE = "config.lua"
print("Get available APs")
available_aps = ""
wifi.setmode(wifi.STATION)
wifi.sta.getap(function(t)
local i = 0
if t then
for k,v in pairs(t) do
    ap = string.format("%-10s",k)
    ap = trim(ap)
    print(ap)

    if (i < MAX_SIDS) then
      available_aps = available_aps .. ap .."<br>"
    elseif ( i == MAX_SIDS) then
      print("There are more available WiFi networks than " .. MAX_SIDS .. ", so below you will find missing ones")
    end
    i=i+1
end
print("Found " .. i .. " WiFi networks")
print(available_aps)
print("Starting setup_server")
tmr.alarm(0,5000,1, function() setup_server(available_aps) end )
end
end)

local unescape = function (s)
s = string.gsub(s, "+", " ")
s = string.gsub(s, "%%(%x%x)", function (h)
return string.char(tonumber(h, 16))
end)
return s
end

function setup_server(aps)
print("Setting up Wifi AP")
wifi.setmode(wifi.SOFTAP)
wifi.ap.config({ssid="ESP8266"})
wifi.ap.setip({ip="192.168.0.1",netmask="255.255.255.0",gateway="192.168.0.1"})
print("Setting up webserver")

--web server
srv = nil
srv=net.createServer(net.TCP)
srv:listen(80,function(conn)
conn:on("receive", function(client,request)
local buf = ""
print("Request:")
print(request)
local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
if(method == nil)then
_, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP")
end

local _POST = {}

if(method == "POST")then
    print("POST message has been found")
    local start, stop, vars = string.find(request, "(wsid.*)")
    print("Print arguments to parse")
    print(vars)
    if (vars ~= nil)then
        for k, v in string.gmatch(vars, "(%w+)=([^%&]+)&*") do
            _POST[k] = unescape(v)
            print(_POST[k])
        end
    end
end


if (_POST.wpsw ~= nil and _POST.wsid ~= nil and _POST.rint ~= nil and _POST.turl ~= nil and _POST.tport ~= nil and _POST.tapi ~= nil and _POST.tftemp ~= nil and _POST.tftemp ~= nil) then
    client:send("Saving data..")
    file.open(CONFIG_FILE, "w")
    file.writeline('READ_INTERVAL = ' .. trim(_POST.rint)*1000)
    file.writeline('PIN_DHT22 = ' .. trim(_POST.dht))
    
    file.writeline('CFG_WIFI_SSID = "' .. trim(_POST.wsid) .. '"')
    file.writeline('CFG_WIFI_PASS = "' .. trim(_POST.wpsw) .. '"')
    file.writeline('TS_URL = "' .. trim(_POST.turl) .. '"')
    file.writeline('TS_PORT = "' .. trim(_POST.tport) .. '"')
    file.writeline('TS_API_RW_KEY = "' .. trim(_POST.tapi) .. '"')
    file.writeline('TS_FIELD_TEMP = "' .. trim(_POST.tftemp) .. '"')
    file.writeline('TS_FIELD_HUMID = "' .. trim(_POST.tfhumid) .. '"')
    
    if (_POST.dhcp == nil or _POST.dhcp == "on") then
        print("DHCP turned on")
        file.writeline('CFG_WIFI_AUTOIP = ' .. string.format("%s",tostring(true)))
    elseif (_POST.dhcp == "off" and _POST.wip ~= nil and _POST.wmask ~= nil and _POST.wgtw ~= nil) then
        file.writeline('CFG_WIFI_AUTOIP = ' .. string.format("%s",tostring(false)))
        file.writeline('CFG_WIFI_IP = "' .. trim(_POST.wip) .. '"')
        file.writeline('CFG_WIFI_NETMASK = "' .. trim(_POST.wmask) .. '"')
        file.writeline('CFG_WIFI_GATEWAY = "' .. trim(_POST.wgtw) .. '"')
    else
        print("DHCP with no valid static IP address has been provided")
        file.remove(CONFIG_FILE)
    end

    file.close()
    
    if file.exists(CONFIG_FILE) then
        node.compile(CONFIG_FILE)
        file.remove(CONFIG_FILE)
    end
    node.restart()
end

buf = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n<!DOCTYPE HTML>\r\n<html><body>"
buf = buf .. "<h1>ESP8266 - MAC[" .. wifi.ap.getmac() .. "]</h1>"
buf = buf .. "<br>Nearby WiFi [SSID]:<table bgcolor=\"#2ecc71\" border=\"0\">"
buf = buf .. "<tr><td>" .. aps .. "</td></tr>"
buf = buf .. "</table><br>"
buf = buf .. "<form method='POST' action='http://" .. wifi.ap.getip() .."'>"
buf = buf .. "<table border=\"0\"><tr><th>Settings [WIFI]:</th></tr>"
buf = buf .. "<tr><td>SSID:</td><td><input type='text' name='wsid'></input></td></tr>"
buf = buf .. "<tr><td>PASSWORD:</td><td><input type='password' name='wpsw'></input></td></tr>"
buf = buf .. "<tr><th>Settings [GLOBAL]:</th></tr>"
buf = buf .. "<tr><td>READ_INTERVAL(s):</td><td><input type='text' name='rint'></input></td></tr>"
buf = buf .. "<tr><td>DHT22 PIN:</td><td><input type='text' name='dht'></input></td></tr>"
buf = buf .. "<tr><th>Settings [THINGSPEAK]:</th></tr>"
buf = buf .. "<tr><td>URL:</td><td><input type='text' name='turl'></input></td></tr>"
buf = buf .. "<tr><td>PORT:</td><td><input type='text' name='tport'></input></td></tr>"
buf = buf .. "<tr><td>API_KEY:</td><td><input type='text' name='tapi'></input></td></tr>"
buf = buf .. "<tr><td>TEMP field:</td><td><input type='text' name='tftemp'></input></td></tr>"
buf = buf .. "<tr><td>HUMID field:</td><td><input type='text' name='tfhumid'></input></td></tr>"
buf = buf .. "</table><button type='submit'>Save</button>"
buf = buf .. "</form></body></html>"
client:send(buf)
client:close()
collectgarbage()
end)
end)

print("Please connect to: " .. wifi.ap.getip())
tmr.stop(0)
end

function trim(s)
return (s:gsub("^%s*(.-)%s*$", "%1"))
end
