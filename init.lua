ABORT_TIME = 5000
FILE_MAIN = "main.lua"
FILE_CONFIG = "config.lc"
FILE_PREPCONFIG = "setconfig.lua"

function startup()
    print('in startup')
    if abort == true then
        print('startup aborted')
        return
    end

    if file.exists(FILE_CONFIG) then
        print("Config file found")
		print("startup config")
        dofile(FILE_CONFIG)
		print("startup main")
		dofile(FILE_MAIN)
    else
        print("Config file not found")
		print("startup configuration mode")
        dofile(FILE_PREPCONFIG)
    end    
end
abort = false
print('NodeMCU started')
print('Assign variable abort=true in '..(ABORT_TIME/1000)..' sec to abort startup procedure')
tmr.alarm(0,ABORT_TIME,0,startup)
