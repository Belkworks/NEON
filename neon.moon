-- init.moon - neon
-- SFZILabs 2020

return NEON if NEON -- don't load twice

defaults = (d, s) ->
	for i in pairs s
		d[i] = s[i] if d[i] == nil

tohex = (s) -> s\gsub '.', (c) -> string.format '%02X', string.byte c

-- 	Options:
-- 		fresh: force redownload
--		cache: write to file
--		text: return text
--		maxAge: max file age

class Neon
	new: (options = {}) =>
		defaults options, debug: false
		@DEBUG = options.debug
		@cache = {}
		@init!

	_debug: (...) =>
		return unless @DEBUG
		print '[DEBUG]',...

	_error: (message) =>
		error message -- TODO: show onscreen?
		return

	_http: (url, options = {}) =>
		return @_error 'your exploit does not support http requests!' unless syn
		return @_error 'invalid url passed to :_http' unless 'string' == type url

		@_debug "web request for #{options.tag} to #{url}"

		syn.request
			Url: url
			Method: options.method or 'GET'
			Headers: options.headers or {}
			Cookies: options.cookies or {}
			Body: options.body or nil

	_cache: (key, value) => @cache[key] = value

	_cachecheck: (tag, options = {}) =>
		return if options.fresh
		if E = @cache[tag]
			@_debug "serving #{tag} from cache"
			return unpack E

	_loadstring: (code, options = {}) =>
		S, EorF = pcall loadstring, code
		if S
			EorF
		else @_error "error loadstring #{options.tag}: #{EorF}"
	
	_executeChunk: (chunk, options = {}) =>
		-- execute
		result = { pcall chunk }
		success = table.remove result, 1
		if success
			-- cache
			unless options._dontCache
				@_cache options.tag, result
			unpack result
		else
			err = table.remove result, 1
			@_error 'error execute #{options.tag}: #{err}'

	_execute: (code, options = {}) => -- str -> ...result
		return @_error 'invalid options passed to :_execute' unless 'table' == type options
		return @_error 'invalid tag passed to :_execute' unless 'string' == type options.tag
		@_debug "loading #{options.tag}"

		result = code

		if options.text
			@_cache options.tag, code
		else
			chunk = @_loadstring code, options
			result = @_executeChunk chunk, options

		if options.cache
			@_writefile code, options

		result

	clearCache: (K) =>
		K = tostring K
        if K
        	@cache[K] = nil
        else @cache = { }

	web: (url, options = {}) =>
		return @_error 'invalid options passed to :raw' unless 'table' == type options

		defaults options, tag: "web:#{url}", cache: true

		return @_error 'invalid tag passed to :raw' unless 'string' == type options.tag

		cached = @_cachecheck options.tag, options
		return cached if cached

		found, result = @_fromTag options.tag
		return result if found

		response = @_http url, options
		if response.Success
			@_execute response.Body, options
		else @_error "failed http request to #{url}"

	pastebin: (id, options = {}) =>
		return @_error 'invalid id passed to :pastebin' unless 'string' == type id

		defaults options, tag: "pastebin:#{id}"
		@web "https://pastebin.com/raw/#{id}", options

	github: (user, repo, file = 'init.lua', branch = 'master', options = {}) =>
		return @_error 'no user passed to :github' unless 'string' == type user
		return @_error 'no repo passed to :github' unless 'string' == type repo
		return @_error 'no file passed to :github' unless 'string' == type file
		return @_error 'no branch passed to :github' unless 'string' == type branch

		defaults options, tag: "github:#{user}/#{repo}[#{branch}]/#{file}"

		-- TODO: tag with last commit
		-- url: https://api.github.com/repos/user/repo/commits

		with 'https://raw.githubusercontent.com/%s/%s/%s/%s'
			url = \format user, repo, branch, file
			return @web url, options

	_makeDirectories: =>
		unless isfolder 'neon'
			makefolder 'neon'

		unless isfolder 'neon/cache'
			makefolder 'neon/cache'

	_fromTag: (tag, options = {}) =>
		return if options.fresh

		@_makeDirectories!

		defaults options, maxAge: 7 * 24 * 60
		
		if @packages
			if x = @packages\get tag
				return if os.time! - x.time > options.maxAge*60
			else return

		name = tohex syn.crypt.derive tag, 12
		path = "neon/cache/#{name}.bin"
		if isfile path
			if code = readfile path
				@_debug "read #{tag} from file"
				options.cache = false
				options.tag = tag
				return true, @_execute code, options

	_writefile: (code, options) =>
		@_makeDirectories!

		name = tohex syn.crypt.derive options.tag, 12
		path = "neon/cache/#{name}.bin"

		defaults options, minify: true

		data = if options.text
			code
		elseif options.minify
			luamin = @github 'belkworks', 'minify'
			luamin.minify code
		else dumpstring code

		writefile path, data
		
		if @packages
			@packages\set options.tag, time: os.time!
			@manifest\write!

		@_debug "wrote #{options.tag} to file as #{name}"

	init: =>
		@_error 'platform not supported!' unless syn
		
		@_makeDirectories!

		game.Loaded\Wait! if not game\IsLoaded!

		tag = 'github:belkworks/flat[master]/init.lua'
		flat = @github 'belkworks', 'flat'

		@manifest = with flat 'neon/cache/manifest.json'
			@packages = \namespace 'packages'

		@github 'belkworks', 'minify', nil, nil, _dontCache: true

		unless @packages\get tag
			@packages\set tag, time: os.time!

		@manifest\write!

	__call: (...) => @github ...

singleton = Neon!
getgenv!.NEON = singleton if getgenv
singleton