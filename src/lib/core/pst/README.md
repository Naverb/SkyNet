# Skynet Persistence library

### Update 19 April 2020

We should create a standard for serializing objects into PSTVars. Perhaps we can
add a function `serialize` for each class, and persistence calls this function
if it exists.

### 7 January 2020

There are two key elements of the data we want to save to persistence:

- Raw data: strings, numbers, etc..
- Metadata: Table reference graphs, etc..

We found naive serialization methods were incapable of capturing the
complexity of the data structures we were creating. For example,
Lua allows circular references in tables: it is possible for the
expression `T[v] == T` to evaluate to true.

Our solution is the *Persistence File System* data format. It is a
specification that allows us to separate the raw data of a Lua
variable from its metadata.

When the persistence system initializes, it will scan the computer for `.pfs`
files in order to assemble the topological structure of the persistent file
system. The advantage of this format is that `.pfs` follows a "drag-and-drop"
paradigm: any valid `.pfs` detected will be reloaded back into memory.

Any `.pfs` file should be a plaintext file containing a single table
formatted in the style of the ComputerCraft function
`textutils.serialize`. The root table should resemble:

```
{
    ref = [A string used to reference the persistence data from the
    persistence library],

    data = {
        -- The data table consists of raw data stored in the ubiquitous
        -- key,value pair format:
        KEY = VALUE
    },

    links = {
        -- Keys in this table corresponding to pointers to other .pst files.
        -- After the persistence system detects all .pst files, it will
        -- traverse each .pst to regenerate the homology of the file system.
        -- This is done by setting the value of KEY to a pointer to the
        -- corresponding data.

        KEY = [REF]
    }
}
```

7 January 2020
