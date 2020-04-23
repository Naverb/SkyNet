-- Since `type` is used by lua, let's call our type function `category`
function category(x)
    return getmetatable(x).type or type(x)
end
