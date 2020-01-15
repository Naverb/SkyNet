TestInterface = {
    ExampleFunction = function() end
}

TestExtends = {
    NewFunction = function(self,str)
        print(str)
    end
}

TestMetatable = {
    __add = function(self,rhs)
        return self.attribute .. tostring(rhs)
    end
}

TestClass = Class {
    constructor = function(self,str)
        local obj = {
            attribute = str
        }
        return obj
    end,

    metatable = TestMetatable,
    implements = TestInterface,
    extends = TestExtends,

    attribute = 'Example_Default_Value',
    ExampleFunction = function(self)
        print(self.attribute)
    end
}

TestInstance = TestClass:new('Test')
print('Testing if TestInstance can access ExampleFunction.')
TestInstance:ExampleFunction()
print('Testing if TestInstance can access the extended function NewFunction.')
TestInstance:NewFunction('Extends Test')
print('Testing TestInstance metatable.')
print(TestInstance + 'Foo')
