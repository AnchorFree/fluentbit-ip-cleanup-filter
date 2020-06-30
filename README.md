Provides a [Lua filter](https://docs.fluentbit.io/manual/pipeline/filters/lua)
for [fluent-bit](https://github.com/fluent/fluent-bit) to anonymize IPv4 and
IPv6 addresses from log records.

## Motivation

Section in progress


## Usage

### Docker

- Clone this repo and `cd` into it
- Run fluent-bit with the sample configuration (`fluent-bit.conf`) mounting current directory inside container:

```
# Contents of fluent-bit.conf
[INPUT]
    Name   dummy
    Dummy {"ipPort":"127.0.0.1:3233", "email":"example@foo.com"}
    Tag    dummy.log

[FILTER]
    Name            lua
    Match           *
    Protected_mode  false
    script          cleanup_ip.lua
    call            clean

[OUTPUT]
    Name   stdout
    Match  *
```

```
$ docker run -ti --rm -v $PWD:/fluent-bit/etc -e VENDOR_PATH="/fluent-bit/etc/" fluent/fluent-bit
Fluent Bit v1.4.6
* Copyright (C) 2019-2020 The Fluent Bit Authors
* Copyright (C) 2015-2018 Treasure Data
* Fluent Bit is a CNCF sub-project under the umbrella of Fluentd
* https://fluentbit.io

[2020/06/30 16:05:19] [ info] [storage] version=1.0.3, initializing...
[2020/06/30 16:05:19] [ info] [storage] in-memory
[2020/06/30 16:05:19] [ info] [storage] normal synchronization mode, checksum disabled, max_chunks_up=128
[2020/06/30 16:05:19] [ info] [engine] started (pid=1)
[2020/06/30 16:05:19] [ info] [sp] stream processor started
[0] dummy.log: [1593533120.216797700, {"ipPort"=>"0.0.0.0:3233", "email"=>"example@foo.com"}]
[1] dummy.log: [1593533121.216744100, {"ipPort"=>"0.0.0.0:3233", "email"=>"example@foo.com"}]
[2] dummy.log: [1593533122.217766100, {"ipPort"=>"0.0.0.0:3233", "email"=>"example@foo.com"}]
[3] dummy.log: [1593533123.219193500, {"ipPort"=>"0.0.0.0:3233", "email"=>"example@foo.com"}]
```

### Kubernetes

Section in progress


## Configuration

It is possible to configure script parameters via environment variables:

```
VENDOR_PATH - path to ./vendor directory (relies on how volumes are mounted in container)
IPV4_REPL   - replacement for IPv4 addresses (default: 0.0.0.0)
IPV6_REPL   - replacement for IPv6 addresses (default: 0000:0000:0000:0000:0000:0000:0000:0000)
```


## Development

### Update `./vendor`

Currently containers from [fluent/fluent-bit](https://hub.docker.com/r/fluent/fluent-bit)
are running Lua 5.1 under Linux. Thus, `./vendor` should be built under linux,
using Lua 5.1 and [luarocks](https://github.com/luarocks/luarocks):

```
$ luarocks install --tree vendor lpeg
$ luarocks install --tree vendor lpeg_patterns
$ luarocks install --tree vendor lunajson
```

### Local development

Install dev dependencies:

```
$ make install-dev
```

Lint code (requires [luacheck](https://github.com/mpeterv/luacheck)):

```
$ make lint
```

Format code (requires [lua-format](https://github.com/Koihik/LuaFormatter)):

```
$ make format
```

Run tests:

```
$ make test
```
