--- Global settings ---
READ_INTERVAL = 240000
OPERATION_TRESHOLD = 5000

-- WIFI configuration --
CFG_WIFI_AUTOIP = false
CFG_WIFI_SSID = "YOURSIDNAME"
CFG_WIFI_PASS = "YOURWIFIPASSWORD"
CFG_WIFI_IP = "192.168.1.200"
CFG_WIFI_NETMASK = "255.255.255.0"
CFG_WIFI_GATEWAY = "192.168.1.1"

-- DHT22 sensor
PIN_DHT22 = 4

--- Thingspeak ---
TS_URL = 'api.thingspeak.com'
TS_PORT = 80
TS_API_RW_KEY = "YOURAPIKEY"
TS_FIELD_TEMP = "field1"
TS_FIELD_HUMID = "field2"

function wificonfigprint()
    ledconfirm(1, 1500, 700)
    print("ESP8266 mode is: " .. wifi.getmode())
    print("The module MAC address is: " .. wifi.ap.getmac())
    print("Config done, IP is "..wifi.sta.getip())
end

function ledconfirm(blinkCounter, speed, blinkDuration)
    lednr = 4
    limit = blinkDuration+blinkDuration
    if (speed<limit) then
        speed=limit
    end
    gpio.mode(lednr,gpio.OUTPUT)
    tmr.alarm(2, speed, 1, function()
            if blinkCounter > 0 then
                tmr.alarm(0,blinkDuration,0,function()
                    gpio.write(lednr, gpio.LOW)
                    tmr.alarm(0,blinkDuration,0,function()
                        gpio.write(lednr, gpio.HIGH)
                        blinkCounter = blinkCounter - 1
                    end)
                end)
            else
                tmr.stop(2)
            end
    end)    
end

function wificonfig(ssid, pass, autoip)
    print('Configuring WiFi')
    wifi.setmode(wifi.STATION)
	wifi.setphymode(wifi.PHYMODE_N)
    wifi.sta.config(ssid,pass)
    wifi.sta.connect()
    
    if autoip==true then
        tmr.alarm(1, 1000, 1, function()
            if wifi.sta.getip()== nil then
                ledconfirm(1, 200, 50)
                print("IP unavaiable, Waiting...")
            else
                tmr.stop(1)
                wificonfigprint()
            end
        end)
    else
        wifi.sta.setip({ip=CFG_WIFI_IP,netmask=CFG_WIFI_NETMASK,gateway=CFG_WIFI_GATEWAY})
        wificonfigprint()
    end
end

function pushDataToTs()
        -- Get sensor data
		DHT22 = require("dht")
		status, temperature, humidity = DHT22.read(PIN_DHT22)
		if (status == DHT22.OK) then
			con = net.createConnection(net.TCP, 0)
			con:connect(TS_PORT, TS_URL)
			
			con:on("connection", function(con, payloadout)
			
			con:send(
				"POST /update?api_key=" .. TS_API_RW_KEY .. 
				"&".. TS_FIELD_TEMP .."=" .. temperature .. 
				"&".. TS_FIELD_HUMID .."=" .. humidity .. 
				" HTTP/1.1\r\n" .. 
				"Host: api.thingspeak.com\r\n" .. 
				"Connection: close\r\n" .. 
				"Accept: */*\r\n" .. 
				"User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n" .. 
				"\r\n")
			end)
			
			con:on("receive", function(con, payloadout)
				if (string.find(payloadout, "Status: 200") ~= nil) then
					print("Posted to ThingSpeak OK values:"..temperature.." "..humidity)
				end
			end)
			
			con:on("disconnection", function(con, payloadout)
				con:close();
				collectgarbage();
				print("Connection closed::going sleep for "..(READ_INTERVAL/1000).." seconds")
				node.dsleep(READ_INTERVAL*1000) 
			end)
		else
			print("Something bad happens while reading DHT22 sensor")
		end
		DHT22 = nil
        package.loaded["dht22"]=nil
end

function loop() 
        -- Stop main loop
        tmr.stop(2)
		pushDataToTs()
end

print('in main.lua')
wificonfig(CFG_WIFI_SSID, CFG_WIFI_PASS, CFG_WIFI_AUTOIP)
tmr.alarm(2, 500, 1, function() loop() end)
