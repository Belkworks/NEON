local defaults
defaults = function(d, s)
  for i in pairs(s) do
    if d[i] == nil then
      d[i] = s[i]
    end
  end
end
local tohex
tohex = function(s)
  return s:gsub('.', function(c)
    return string.format('%02X', string.byte(c))
  end)
end
local Neon
do
  local _class_0
  local _base_0 = {
    __call = function(self, url)
      return self:raw(url)
    end,
    _debug = function(self, ...)
      if not (self.DEBUG) then
        return 
      end
      return print('[DEBUG]', ...)
    end,
    _error = function(self, message)
      error(message)
    end,
    _http = function(self, url, options)
      if options == nil then
        options = { }
      end
      if not (syn) then
        return self:_error('your exploit does not support http requests!')
      end
      if not ('string' == type(url)) then
        return self:_error('invalid url passed to :_http')
      end
      self:_debug("web request for " .. tostring(options.tag) .. " to " .. tostring(url))
      return syn.request({
        Url = url,
        Method = 'GET',
        Headers = options.headers or { },
        Cookies = options.cookies or { },
        Body = options.body or nil
      })
    end,
    _cache = function(self, key, value)
      self.cache[key] = value
    end,
    _cachecheck = function(self, tag, options)
      if options == nil then
        options = { }
      end
      if options.fresh then
        return 
      end
      do
        local E = self.cache[tag]
        if E then
          self:_debug("serving " .. tostring(tag) .. " from cache")
          return E
        end
      end
    end,
    _loadstring = function(self, code, options)
      if options == nil then
        options = { }
      end
      local S, EorF = pcall(loadstring, code)
      if S then
        return EorF
      else
        return self:_error("error loadstring " .. tostring(options.tag) .. ": " .. tostring(EorF))
      end
    end,
    _executeChunk = function(self, chunk, options)
      if options == nil then
        options = { }
      end
      local result = {
        pcall(chunk)
      }
      local success = table.remove(result, 1)
      if success then
        self:_cache(options.tag, result)
        return unpack(result)
      else
        local err = table.remove(result, 1)
        return self:_error('error execute #{options.tag}: #{err}')
      end
    end,
    _execute = function(self, code, options)
      if options == nil then
        options = { }
      end
      if not ('table' == type(options)) then
        return self:_error('invalid options passed to :_execute')
      end
      if not ('string' == type(options.tag)) then
        return self:_error('invalid tag passed to :_execute')
      end
      self:_debug("loading " .. tostring(options.tag))
      if options.cache then
        self:_writefile(code, options)
      end
      if options.text then
        return code
      end
      local chunk = self:_loadstring(code, options)
      return self:_executeChunk(chunk, options)
    end,
    clearCache = function(self, K)
      do
        K = tostring(K)
        if K then
          self.cache[K] = nil
        else
          self.cache = { }
        end
      end
    end,
    web = function(self, url, options)
      if options == nil then
        options = { }
      end
      if not ('table' == type(options)) then
        return self:_error('invalid options passed to :raw')
      end
      defaults(options, {
        tag = "web:" .. tostring(url),
        cache = true
      })
      if not ('string' == type(options.tag)) then
        return self:_error('invalid tag passed to :raw')
      end
      do
        local Y = self:_cachecheck(options.tag, options)
        if Y then
          return unpack(Y)
        end
      end
      local found, result = self:_fromTag(options.tag)
      if found then
        return result
      end
      local response = self:_http(url, options)
      if response.Success then
        return self:_execute(response.Body, options)
      else
        return self:_error("failed http request to " .. tostring(url))
      end
    end,
    pastebin = function(self, id, options)
      if options == nil then
        options = { }
      end
      if not ('string' == type(id)) then
        return self:_error('invalid id passed to :pastebin')
      end
      defaults(options, {
        tag = "pastebin:" .. tostring(id)
      })
      return self:web("https://pastebin.com/raw/" .. tostring(id), options)
    end,
    github = function(self, user, repo, file, branch, options)
      if file == nil then
        file = 'init.lua'
      end
      if branch == nil then
        branch = 'master'
      end
      if options == nil then
        options = { }
      end
      if not ('string' == type(user)) then
        return self:_error('no user passed to :github')
      end
      if not ('string' == type(repo)) then
        return self:_error('no repo passed to :github')
      end
      if not ('string' == type(file)) then
        return self:_error('no file passed to :github')
      end
      if not ('string' == type(branch)) then
        return self:_error('no branch passed to :github')
      end
      defaults(options, {
        tag = "github:" .. tostring(user) .. "/" .. tostring(repo) .. "[" .. tostring(branch) .. "]/" .. tostring(file)
      })
      do
        local _with_0 = 'https://raw.githubusercontent.com/%s/%s/%s/%s'
        local url = _with_0:format(user, repo, branch, file)
        return self:web(url, options)
      end
    end,
    _makeDirectories = function(self)
      if not (isfolder('neon')) then
        makefolder('neon')
      end
      if not (isfolder('neon/cache')) then
        return makefolder('neon/cache')
      end
    end,
    _fromTag = function(self, tag, options)
      if options == nil then
        options = { }
      end
      if options.fresh then
        return 
      end
      self:_makeDirectories()
      defaults(options, {
        maxAge = 7 * 24 * 60 * 60
      })
      if self.packages then
        do
          local x = self.packages:get(tag)
          if x then
            if os.time() - x.time > options.maxAge then
              return 
            end
          else
            return 
          end
        end
      end
      local name = tohex(syn.crypt.derive(tag, 12))
      local path = "neon/cache/" .. tostring(name) .. ".bin"
      if isfile(path) then
        do
          local code = readfile(path)
          if code then
            self:_debug("read " .. tostring(tag) .. " from file")
            options.cache = false
            options.tag = tag
            return true, self:_execute(code, options)
          end
        end
      end
    end,
    _writefile = function(self, code, options)
      self:_makeDirectories()
      local name = tohex(syn.crypt.derive(options.tag, 12))
      local path = "neon/cache/" .. tostring(name) .. ".bin"
      local dump
      if options.text then
        dump = code
      else
        dump = dumpstring(code)
      end
      writefile(path, dump)
      if self.packages then
        self.packages:set(options.tag, os.time())
        self.manifest:write()
      end
      return self:_debug("wrote " .. tostring(options.tag) .. " to file as " .. tostring(name))
    end,
    init = function(self)
      if not (syn) then
        self:_error('platform not supported!')
      end
      self:_makeDirectories()
      local tag = 'github:safazi/flat/init.lua'
      local flat = self:github('safazi', 'flat')
      do
        local _with_0 = flat('neon/manifest.json')
        self.packages = _with_0:namespace('packages')
        self.manifest = _with_0
      end
      if not (self.packages:get(tag)) then
        self.packages:set(tag, {
          time = os.time()
        })
      end
      return self.manifest:write()
    end,
    __call = function(self, ...)
      return self:github(...)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, options)
      if options == nil then
        options = { }
      end
      defaults(options, {
        debug = false
      })
      self.DEBUG = options.debug
      self.cache = { }
      return self:init()
    end,
    __base = _base_0,
    __name = "Neon"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Neon = _class_0
end
local singleton = Neon
if getgenv then
  getgenv().NEON = singleton
end
return singleton
