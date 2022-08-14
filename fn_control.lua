local func_env = getrawmetatable(getfenv(functionx)).__index
local fn_leak  = loadstring

local functions = {current_args = {}}

function functions:unload()
    setfenv(fn_leak, func_env)
    debug.setconstant(fn_leak, 1, "loadstring")
end

function functions:load_fn_control(name)
    setfenv(fn_leak, setmetatable({}, {
        __index = function(_, index)
            if index == "string" then
                return setmetatable({}, {
                    __index = function(_, index)
                        if index == "len" then
                            return (function(...)
                                table.remove(self.current_args, 1)
                                return unpack(self.current_args) 
                            end)
                        end

                        return func_env.string[index]
                    end
                })
            elseif index == "type" then
                return (function() return "function" end)
            end

            return func_env[index]
        end
    }))
end

function functions:send_fn_control(fnName, fnResult, ...)
    local args   = {...}

    debug.setconstant(fn_leak, 1, fnName)

    self.current_args = args
    local result = fn_leak(args[1])

    if fnResult then
        repeat task.wait() until fnResult
        return result
    end
end

return functions
