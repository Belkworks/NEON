if NEON then
  return NEON
end
local tohex
tohex = function(s)
  return s:gsub('.', function(c)
    return string.format('%02X', string.byte(c))
  end)
end
local copy
copy = function(t)
  local _tbl_0 = { }
  for i, v in pairs(t) do
    _tbl_0[i] = v
  end
  return _tbl_0
end
local defaults
defaults = function(d, s)
  for i in pairs(s) do
    if d[i] == nil then
      d[i] = s[i]
    end
  end
end
local clonedefaults
clonedefaults = function(d, s)
  d = copy(d)
  defaults(d, s)
  return d
end
local Neon
do
  local _class_0
  local _base_0 = {
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
        Method = options.method or 'GET',
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
          return unpack(E)
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
        if not (options._dontCache) then
          self:_cache(options.tag, result)
        end
        return unpack(result)
      else
        local err = table.remove(result, 1)
        return self:_error("error executing " .. tostring(options.tag) .. ": " .. tostring(err))
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
      if not (self.haveInit) then
        self:_init()
      end
      self:_debug("loading " .. tostring(options.tag))
      local result = code
      if options.text then
        self:_cache(options.tag, {
          code
        })
      else
        local chunk = self:_loadstring(code, options)
        result = self:_executeChunk(chunk, options)
      end
      if options.cache then
        self:_writefile(code, options)
      end
      return result
    end,
    clearCache = function(self, K)
      K = tostring(K)
      if K then
        self.cache[K] = nil
      else
        self.cache = { }
      end
    end,
    web = function(self, url, options)
      if options == nil then
        options = { }
      end
      if not ('table' == type(options)) then
        return self:_error('invalid options passed to :raw')
      end
      options = clonedefaults(options, {
        tag = "web:" .. tostring(url),
        cache = true
      })
      if not ('string' == type(options.tag)) then
        return self:_error('invalid tag passed to :raw')
      end
      local cached = self:_cachecheck(options.tag, options)
      if cached then
        return cached
      end
      local found, result = self:_fromTag(options.tag, options)
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
      options = clonedefaults(options, {
        tag = "pastebin:" .. tostring(id)
      })
      return self:web("https://pastebin.com/raw/" .. tostring(id), options)
    end,
    ghostbin = function(self, id, options)
      if options == nil then
        options = { }
      end
      if not ('string' == type(id)) then
        return self:_error('invalid id passed to :ghostbin')
      end
      options = clonedefaults(options, {
        tag = "ghostbin:" .. tostring(id)
      })
      return self:web("https://ghostbin.co/paste/" .. tostring(id) .. "/raw", options)
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
      options = clonedefaults(options, {
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
    _tagToFile = function(self, tag)
      return syn.crypt.hash('neonfile:' .. tag):upper():sub(1, 24)
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
        maxAge = 7 * 24 * 60
      })
      if self.packages then
        do
          local x = self.packages.get(tag):value()
          if x then
            if os.time() - x.time > options.maxAge * 60 then
              return 
            end
          else
            return 
          end
        end
      end
      local name = self:_tagToFile(tag)
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
      local name = self:_tagToFile(options.tag)
      local path = "neon/cache/" .. tostring(name) .. ".bin"
      defaults(options, {
        minify = false
      })
      local data
      if options.minify then
        local luamin = self:github('belkworks', 'minify')
        data = luamin.minify(code)
      elseif options.dump then
        data = dumpstring(code)
      else
        data = code
      end
      writefile(path, data)
      if self.packages then
        self.packages.set(options.tag, {
          time = os.time()
        }):write()
        self.manifest:write()
      end
      return self:_debug("wrote " .. tostring(options.tag) .. " to file as " .. tostring(name))
    end,
    _init = function(self)
      if not (syn) then
        self:_error('platform not supported!')
      end
      self:_debug("running init routine")
      self.haveInit = true
      self:_makeDirectories()
      if not game:IsLoaded() then
        game.Loaded:Wait()
      end
      local tag = 'github:belkworks/flat[master]/init.lua'
      local flat = self:github('belkworks', 'flat')
      do
        local _with_0 = flat('neon/cache/manifest.json')
        self.packages = _with_0:namespace('packages')
        self.manifest = _with_0
      end
      if not (self.packages.get(tag):value()) then
        self.packages.set(tag, {
          time = os.time()
        }):write()
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
local singleton = Neon()
if getgenv then
  getgenv().NEON = singleton
end
return singleton
