
# NEON

*A simple dependency fetcher for Synapse.*

## Loader

Run this snippet to download and run NEON.
```lua
if not NEON then
    if not isfile('neon/init.lua')then
        makefolder('neon')
        local raw = 'https://raw.githubusercontent.com/%s/%s/master/init.lua'
        writefile('neon/init.lua',game:HttpGet(raw:format('belkworks','neon')))
    end
    pcall(loadfile('neon/init.lua'))
end
-- now NEON will be in the environment!
```
Alternatively, you can download the [loader](https://raw.githubusercontent.com/Belkworks/NEON/master/loader.lua) and put it in your `autoexec` folder.

## API

**Loading from GitHub**

```lua
:github(author, repository, file = 'init.lua', branch = 'master', opts)
```
```lua
quick = NEON:github('belkworks', 'quick')
```

**Loading from Pastebin**

```lua
:pastebin(id, opts)
```
```lua
package = NEON:pastebin('pastebin-id')
```

**Loading from URL**

```lua
:web(url, opts)
```
```lua
package = NEON:web('http://path.to/the/file.lua')
```

**Options**

`opts` is a dictionary that changes how modules are loaded/saved.
|Key|Type|Default|Description|
|--|--|--|--|
|`cache`|Boolean|True|Save the resource to file
|`minify`|Boolean|True|Save the resource as minified Lua
|`fresh`|Boolean|False|Force the resource to be redownloaded|
|`text`|Boolean|False|Return the raw text
|`maxAge`|Number|7 Days|Maximum cached age (in minutes)

## Official Modules

- [flat](https://github.com/Belkworks/flat) - a simple flatfile database
- [quick](https://github.com/Belkworks/quick) - an underscore port
- [chance](https://github.com/Belkworks/chance) - a random generator
- [logfile](https://github.com/Belkworks/logfile) - a log writer
- [future](https://github.com/Belkworks/future) - an alternative to promises
