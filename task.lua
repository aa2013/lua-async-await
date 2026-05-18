local co = coroutine
local isFunction = function(fun)
    return "function" == type(fun);
end

-- ================
-- waitable
-- ================
local getAwaiter = function()
    local task = {
        isCompleted = false,
        onCompletedList = {},
        result = nil
    };

    function task:onCompleted(fun)
        if isFunction(fun) then
            table.insert(self.onCompletedList, fun)
        end
    end

    function task:done ()
        if self.isCompleted then
            return
        end
        self.isCompleted = true;
        for i, v in ipairs(self.onCompletedList) do
            pcall(v, self.result)
        end
    end
    return task;
end

local isAwaiter = function(awaiter)
    if awaiter == nil or "table" ~= type(awaiter) or awaiter.isCompleted == nil then
        return false
    end

    if awaiter.OnCompleted == nil or "function" ~= type(awaiter.OnCompleted) then
        return false
    end
    return true
end

-- ================
-- async
-- ================
local async = function(fun)
    return function(...)
        if not isFunction(fun) then
            return
        end

        local thread = co.create(fun)
        local next = nil
        local awaiter = getAwaiter()
        next = function(...)
            local state, moveNext = co.resume(thread, ...)
            if "dead" ~= co.status(thread) then
                if isFunction(moveNext) then
                    moveNext(next)
                end
            else
                awaiter.result = moveNext
                awaiter:done()
            end
        end

        next(...)

        return awaiter
    end
end

local await = function(awaiter)

    if not co.isyieldable() then
        error("not yield")
        return
    end

    if awaiter == nil or "table" ~= type(awaiter) then
        return
    end

    if awaiter.isCompleted == nil or awaiter.isCompleted then
        return awaiter.result
    end

    return co.yield(function(continuation)
        if awaiter.isCompleted then
            continuation(awaiter.result)
        else
            awaiter:onCompleted(continuation)
        end
    end)
end

local asyncWrapper = function(fun, ...)
    async(fun)(...)
end

-- ================
-- Task
-- ================

local taskWhenAny = function(...)
    local task = getAwaiter()
    local awaiters = { ... }

    if #awaiters == 0 then
        task:done()
        return task
    end
    local done = function()
        task:done()
    end
    for i, v in ipairs(awaiters) do
        if isAwaiter(v) then
            if v.isCompleted then
                task:done()
            else
                v:OnCompleted(done)
            end
        end
    end

    return task
end

local taskWhenAll = function(...)
    local task = getAwaiter()
    local awaiters = { ... }
    local taskLen = #awaiters

    if taskLen == 0 then
        task:done()
        return task
    end

    local doneCount = 0
    local done = function()
        doneCount = doneCount + 1
        if doneCount >= taskLen then
            task:done()
        end
    end
    for i, v in ipairs(awaiters) do
        if isAwaiter(v) then
            if v.isCompleted then
                done()
            else
                v:OnCompleted(done)
            end
        end
    end

    return task
end

return {
    async = async,
    await = await,
    asyncWrapper = asyncWrapper,
    create = getAwaiter,
    whenAny = taskWhenAny,
    whenAll = taskWhenAll,
}
