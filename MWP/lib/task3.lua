--[[ Welcome to the new, new task API.
 May your stay be pleasant and full of indices
 Sincerely, Anthony and Brevan.
]]

-- import rickScript

-- From task2:
--[[
    This is the new API to handle tasks (listeners) and taskSequences (taskHandlers). We found the previous API had some major shortcomings, including:
    1) When a coroutine yielded within a listener, the task_co would intercept the yield before the BIOS coroutine could receive the event. This prevented APIs like GPS, GPS2, and rednet from working.
    2) We needed to modify attributes of a parent taskHandler from within a specific listener. So we need to find a clean and simple way to pass a parent object (taskSequence) to child objects (task).
]]

--[[
    Description of control flow in handy-dandy natural language:

    taskFoo: Hi, to finish my action, I need requiredPromise.
    PTS (parent task sequence): Ok, let me see if I have a task that gives you that...
        (if yes): here, taskBar promises registeredOutcome requiredPromise. Let me run it real quick and get back to you.
        (if no): sorry, I need to ask someone else. You'll have to wait a bit.
    PTS (to its own parent, PPTS): Hi, I need requiredPromise, can you give me that?
    PPTS: Let me check..
        [ The process repeats until requiredPromise is fullfilled.]
]]

-- CLASS Promise
--[[
    Contains the metadata of a resumeEvent along with any contingent data necessary to resume a task that requests this promise.
    -- "The promise class may not have any methods - it may just be a table"

    Attributes:
        type: String -- A label that describes what kind of tasks can fulfill this promise (see task.registeredOutcome).
        dataWasAccessed: Bool -- This boolean is a flag to see if a yielding_object has used this promise before.
        data: Table -- Stores the data of the promise
        questionData: Table -- Store the metadata of the context in which a task requested this promise.
        askingTask: Task -- Pointer to the task that asked for this promise.

    Methods:
		new{(askingTask, questionData)}: Promise -- Creates a new promise.
			// I recommend {attributes} be {askingTask, questionData, type} makes the most sense, with {attributes} pulling from any of the above properties we choose to define.
]]

-- INTERFACE YieldingObject
--[[
    This is the interface that contains the methods necessary to yield and send and receive promises.

    Attributes:
        isActive: Bool -- The status of the yielding_object
		parent: taskSequence -- A pointer to the taskSequence that contains this yielding_object.
			// See my lengthy comment below
        name: String

    Methods:
        yield(requiredPromises: Promise[]): Promise[] -- Yields the yielding_object, informing the parent that this yielding_object needs requiredPromises[] where requiredPromises is a table of promises necessary to resume.
		registerParent(parent: taskSequence): void -- Sets self.parent.
			// If we are somewhat differentiating tasks and taskSequences by making them extensions of an interface rather than both essentially tasks, I feel like "parent" might not be the right term - I would suggest something akin to registerToTaskSequence(_)
]]

-- CLASS Task IMPLEMENTS YieldingObject
--[[
    This is the class that implements YieldingObject to run a predetermined function when the tasks conditions are satisfied in addition to receiving a promise that satisfies the task's requiredPromises.

    Attributes:
        isActive: Bool -- Determines whether this task will try to do anything if task:run(...) is called.
		parent: TaskSequence
			// See my comment above
        name: String
        requiredPromises: Promise[] -- Contains the promises needed by this task in order to resume after yielding.
		registeredOutcome: String -- The type of promise this task can fulfill.
			// Perhaps we should make this registeredOutcomes[], in case we can satisfy multiple outcomes? It also occurs to me right now that we might want to consider whether we want to seperate two tasks that do very related jobs with a slight difference, or both make them extensions of a base task - i.e. we have a base registeredOutcome for getFuel and can extend it with tasks that have extra functionality. Or we could make these metafunctions for the base getFuel task. It really depends on the programming paradigm we wanna go for here, but we should deside from the start.
        action: Coroutine -- The coroutine that contains this task's procedure to be resumed/executed on self:run(...).
        procedure: Function -- The function that is wrapped by self.action containing the code that is executed when task:run(...) is called.
        condition: Function -- The function that is evaluated to see if this task is clear to run.

    Methods:
        checkCondition(): Bool -- Checks self.condition() to see if this task is clear to run.
        run(promises: Promise[]): Table -- Runs a predefined procedure if this task's asked promises are fullfilled and checkCondition returns true. Returns information specific to the task.
        yield(requiredPromises: Promise[]): Promise[] -- Yields this task, informing the parent of what promises this task has asked. When this task is resumed, an array of promises is returned back to the task's action when task:run(promises) is called.
        registerParent(parent: taskSequence): void
        registerOutcome(newRegisteredOutcome: String): void -- Sets self.registeredOutcome.
        resurrect(): Bool -- Recreates the action from this task's procedure. Returns whether the resurrection was a success.
        enable(): void -- sets self.isActive = true.
		disable(): void -- sets self.isActive = false.
		requestPromise{attributes} : Promise
			// Wrapper for Promise:new, that keeps track of askingTask

]]

-- CLASS TaskSequence IMPLEMENTS YieldingObject
--[[
    This is a class to handle the sequencing between a given set of tasks, handling yielding and providing promises

    Attributes:
        status: String
        parent: TaskSequence
        name: String
        pendingTasks: Task[] -- The table that contains all the tasks this taskSequence will run.
        registeredTasks: Task[] -- The table that tracks all tasks that can fulfill promises asked by tasks in taskSequence.pendingTasks.
        askedPromises: Promise[] -- A table containing the promises that this taskSequence cannot fulfill.
    Methods:
        yield(requiredPromises: Promise[]): Promise[] -- Yields this taskSequence, informing the parent of what promises this taskSequence needs in order to resume its pendingTasks. When this taskSequence is resumed, an array of promises is sent to this taskSequences promises table (would this always be self.askedPromises?).
        registerParent(parent: TaskSequence or nil): void -- Sets self.parent.
        checkPromiseFullfillment(promise: Promise): Bool - Checks if any task in registeredTasks can fulfill promise. If so, return true. If not, return false and add promise to self.askedPromises so that self.parent can try to fulfill them.
        run(promises: Promise[]): Table -- Takes in promises and loads them into a table of promises to be reachable by self.pendingTasks. If the sequence is enabled, it then begins/resumes execution of the action for each task in self.pendingTasks.
        enable(): void -- sets self.isActive = true.
        disable(): void -- sets self.isActive = false.
]]
