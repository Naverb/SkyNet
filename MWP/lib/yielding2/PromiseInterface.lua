local PromiseInterface = {
    -- Any Class that uses a Promise must provide a way to check whether a Promise is resolved or reserved by a different Class.
    checkPromise = function() end
}

_module = PromiseInterface
