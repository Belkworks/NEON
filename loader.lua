if NEON then return end
if not isfile('neon/init.lua')then
    makefolder('neon')
    local raw = 'https://raw.githubusercontent.com/%s/%s/master/init.lua'
    writefile('neon/init.lua',game:HttpGet(raw:format('belkworks','neon')))
end
pcall(loadfile('neon/init.lua'))
