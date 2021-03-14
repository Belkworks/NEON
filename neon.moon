-- init.moon - neon
-- SFZILabs 2020

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

	__call: (url) => @raw url 

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
			Method: 'GET'
			Headers: options.headers or {}
			Cookies: options.cookies or {}
			Body: options.body or nil

	_cache: (key, value) => @cache[key] = value

	_cachecheck: (tag, options = {}) =>
		return if options.fresh
		if E = @cache[tag]
			@_debug "serving #{tag} from cache"
			return E

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
			@_cache options.tag, result
			unpack result
		else
			err = table.remove result, 1
			@_error 'error execute #{options.tag}: #{err}'

	_execute: (code, options = {}) => -- str -> ...result
		return @_error 'invalid options passed to :_execute' unless 'table' == type options
		return @_error 'invalid tag passed to :_execute' unless 'string' == type options.tag
		@_debug "loading #{options.tag}"

		if options.cache
			@_writefile code, options

		if options.text
			return code

		chunk = @_loadstring code, options
		@_executeChunk chunk, options

	clearCache: (K) =>
		if K = tostring K
			@cache[K] = nil
		else @cache = {}

	web: (url, options = {}) =>
		return @_error 'invalid options passed to :raw' unless 'table' == type options

		defaults options, tag: "web:#{url}", cache: true

		return @_error 'invalid tag passed to :raw' unless 'string' == type options.tag

		with Y = @_cachecheck options.tag, options
			return unpack Y if Y

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

		dump = if options.text
			code
		else dumpstring code

		writefile path, dump
		
		if @packages
			@packages\set options.tag, os.time!
			@manifest\write!

		@_debug "wrote #{options.tag} to file as #{name}"

	init: =>
		@_error 'platform not supported!' unless syn
		
		@_makeDirectories!
		tag = 'github:belkworks/flat[master]/init.lua'
		flat = @github 'belkworks', 'flat'

		@manifest = with flat 'neon/manifest.json'
			@packages = \namespace 'packages'

		unless @packages\get tag
			@packages\set tag, time: os.time!
		@manifest\write!

	__call: (...) => @github ...

singleton = Neon! -- debug: true
getgenv!.NEON = singleton if getgenv
singleton