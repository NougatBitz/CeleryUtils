local func_env = getrawmetatable(getfenv(functionx)).__index
local fn_leak  = loadstring

local cfnc_env = function(args)
    return setmetatable({}, {
        __index = function(_, index)
            if index == "string" then
                return setmetatable({}, {
                    __index = function(_, index)
                        if index == "len" then
                            return (function(...) table.remove(args, 1) return unpack(args) end)
                        end

                        return func_env.string[index]
                    end
                })
            elseif index == "type" then
                return (function() return "function" end)
            end

            return func_env[index]
        end
    })
end

function celery_fn_control(data, ...)
    local hasResult = false
    local fnName    = data 

    if type(data) == "table" then
        fnName = data.name
        hasResult = data.result
    end

    local args   = {...}
    local result

    debug.setconstant(fn_leak, 1, fnName)
    setfenv(fn_leak, cfnc_env(args))

    result = fn_leak(args[1])

    setfenv(fn_leak, func_env)
    debug.setconstant(fn_leak, 1, "loadstring")

    if hasResult then
        repeat task.wait()
        until result
    end

    return result
end

return celery_fn_control
