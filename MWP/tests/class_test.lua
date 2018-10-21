kiwiInterface = {
    mango = function() end
}

kiwiExtends = {
    apple = function(self,str) print(str) end
}

potatoMt = {
    __add = function(potato,rhs)
        return potato.cheezburger .. tostring(rhs)
    end
}

potato = Class {

    constructor = function(self,str)
        local obj = {
            cheezburger = str
        }
        return obj
    end,

    metatable = potatoMt,
    implements = kiwiInterface,
    extends = kiwiExtends,

    cheezburger = 'yee',
    mango = function(self)
        print(self.cheezburger)
    end
}

potatoInstance = potato:new('hot stuff')

potatoInstance:mango()
potatoInstance:apple('heck yeah')

print(potatoInstance + 'yyeeeee')