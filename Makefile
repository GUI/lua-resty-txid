.PHONY: lint test

lint:
	luacheck lib spec

test: lint
	luarocks make --local lua-resty-txid-git-1.rockspec
	env LUA_PATH="${HOME}/.luarocks/share/lua/5.1/?.lua;;" busted spec

release:
	# Ensure the OPM version number has been updated.
	grep -q -F 'version = ${VERSION}' dist.ini
	# Ensure the rockspec has been renamed and updated.
	grep -q -F 'version = "${VERSION}-1"' "lua-resty-txid-${VERSION}-1.rockspec"
	grep -q -F 'tag = "v${VERSION}"' "lua-resty-txid-${VERSION}-1.rockspec"
	# Ensure the CHANGELOG has been updated.
	grep -q -F '## ${VERSION} -' CHANGELOG.md
	# Make sure tests pass.
	docker-compose run --rm -v "${PWD}:/app" app make test
	# Check for remote tag.
	git ls-remote -t | grep -F "refs/tags/v${VERSION}^{}"
	# Verify LuaRock and OPM can be built locally.
	docker-compose run --rm -v "${PWD}:/app" app luarocks pack "lua-resty-txid-${VERSION}-1.rockspec"
	docker-compose run --rm -v "${HOME}/.opmrc:/root/.opmrc" -v "${PWD}:/app" app opm build
	# Upload to LuaRocks and OPM.
	docker-compose run --rm -v "${HOME}/.luarocks/upload_config.lua:/root/.luarocks/upload_config.lua" -v "${PWD}:/app" app luarocks upload "lua-resty-txid-${VERSION}-1.rockspec"
	docker-compose run --rm -v "${HOME}/.opmrc:/root/.opmrc" -v "${PWD}:/app" app opm upload
