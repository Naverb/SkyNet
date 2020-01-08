--[[

    ======================================================================
    ===================== SKYNET PERSISTENCE LIBRARY =====================
    ======================================================================

    When the persistence system initializes, it will scan the computer for
    .pfs files in order to assemble the homological structure of the
    persistent file system. As .pst files are loaded, this program will
    assign pointers to references *(REF) found in the .pst files. Finally,
    this program will create the interface to read the persistence data and
    to write to the system.
]]

PERSISTENCE_PATH = '/pst'

persistent_variables = {}

local function findPFSs(start_dir)
    local PFSs = {}

    local children = fs.list(start_dir)
    for _,child in ipairs(children) do
        if not fs.isDir(fs.combine(start_dir,child)) and not string.find(child,'%.pfs$') then
            -- If the above evaluates to true, then child is not a directory,
            -- and it ends with the extension .pfs
            table.insert(PFSs,fs.combine(start_dir,child))
        else
            -- In this case, child is a directory
            for _,PFS in ipairs(findPFSs(fs.combine(start_dir,child))) do
                table.insert(PFSs,PFS)
            end
        end
    end

    return PSTs
end

function generate()
    -- We run this function at startup to initialize the persistence filesystem
    if not fs.exists(PERSISTENCE_PATH) then
        try {
            body = function()
                fs.makeDir(PERSISTENCE_PATH)
            end
        }
    end

    local PFSs = findPFSs(PERSISTENCE_PATH)
    local links = {}
    local paths = {}

    for _, PFS in ipairs(PFSs) do
        local body = nym.readLines(PFS)
        local contents = textutils.unserialize(body)

        persistent_variables[contents.ref] = contents.data
        links[contents.ref] = contents.links
        paths[contents.ref] = PFS
    end

    -- Now that all PFS files have been loaded, we reconstruct the homological structure.

    for ref,var in pairs(persistent_variables) do
        if links[ref] ~= nil then
            for key,target_ref in pairs(links[ref]) do
                var[key] = persistent_variables[target_ref]
            end
        end
    end
end
