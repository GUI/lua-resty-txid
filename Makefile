.PHONY: lint test

lint:
	luacheck lib spec

test: lint
	luarocks make --local resty-txid-git-1.rockspec
	env LUA_PATH="${HOME}/.luarocks/share/lua/5.1/?.lua;;" busted spec
