ABORT_TIME = 1000

function startup()
    print('in startup')
    if abort == true then
        print('startup aborted')
        return
        end
    dofile('main.lua')
    end
abort = false
print('NodeMCU started')
print('Assign variable abort=true in '..(ABORT_TIME/1000)..' sec to abort startup procedure')
tmr.alarm(0,ABORT_TIME,0,startup)
