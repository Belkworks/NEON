
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
:github(author, repository, opts)
```
```lua
-- gets 'init.lua' from the 'master' branch
quick = NEON:github('belkworks', 'quick')
```
To use a different file/branch, specify `file` or `branch` in `opts`.

**Loading from Pastebin**

```lua
:pastebin(id, opts)
```
```lua
package = NEON:pastebin('pastebin-id')
```

**Loading from Ghostbin**

```lua
:ghostbin(id, opts)
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
|`secured`|String||Value to take from the global environment|

## Official Modules

- [quick](https://github.com/Belkworks/quick) - an underscore port
- [broom](https://github.com/Belkworks/broom) - a reactive task runner, inspired by Nevermore's `maid` class.
- [nest](https://github.com/Belkworks/nset) - an event emitter
- [flat](https://github.com/Belkworks/flat) - a simple flatfile database
- [chance](https://github.com/Belkworks/chance) - a random generator
- [logfile](https://github.com/Belkworks/logfile) - a log writer
- [synlog](https://github.com/Belkworks/synlog) - a visual logger compatible with logfile
- [chalk](https://github.com/Belkworks/chalk) - a terminal styler
- [future](https://github.com/Belkworks/future) - an alternative to promises
- [hold](https://github.com/Belkworks/hold) - a caching mechanism
- [machine](https://github.com/Belkworks/machine) - a robust state machine
- [clerk](https://github.com/Belkworks/clerk) - a state manager
- [gate](https://github.com/Belkworks/gate) - a pausable event handler
- [builder](https://github.com/Belkworks/builder) - a table builder
- [mono](https://github.com/Belkworks/mono) - a table printer
- [chain](https://github.com/Belkworks/chain) - a middleware runner
- [flags](https://github.com/Belkworks/flags) - a flag reader/writer
- [bucket](https://github.com/Belkworks/bucket) - a rate limiter
- [envo](https://github.com/Belkworks/envo) - secure environment variables 
