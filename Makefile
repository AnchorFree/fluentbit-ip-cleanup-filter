lint:
	luacheck *.lua

format:
	lua-format -c .lua-format cleanup_ip.lua

test:
	@VENDOR_PATH=foo lua test.lua

install-dev:
	luarocks install lpeg
	luarocks install lpeg_patterns
	luarocks install lunajson
