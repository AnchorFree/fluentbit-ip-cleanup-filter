dofile("cleanup_ip.lua")

local json = require('lunajson')

local TAG = "test.*"
local TS = "2020-06-25T01:12:11.099408022-07:00"
local IPV4_REPL = "0%.0%.0%.0"
local IPV6_REPL = ("0000:"):rep(8):sub(1, -2)

local test_cases = {
  -- IPv4 addresses
  [{ip = "11.22.33.44"}] = {code = 2, ts = TS, subs = 1}, -- valid IPv4
  [{ip = "127.0.0.1"}] = {code = 2, ts = TS, subs = 1}, -- valid IPv4
  [{ip = "260.0.0.1"}] = {code = 2, ts = TS, subs = 1}, -- contains valid IPv4 (60.0.0.1)
  [{ip = "xxx127.0.0.1"}] = {code = 2, ts = TS, subs = 1}, -- contains valid IPv4 (127.0.0.1)
  [{ip = "127.260.0.1"}] = {code = 0, ts = TS, subs = 0}, -- invalid IPv4
  [{ip = "999.12345.0.0001"}] = {code = 0, ts = TS, subs = 0}, -- invalid IPv4

  -- IPv6 addresses
  [{ip = "1050:0:0:0:5:600:300c:326b"}] = {code = 2, ts = TS, subs = 1}, -- valid IPv6
  [{ip = "1050:0000:0000:0000:0005:0600:300c:326b"}] = {code = 2, ts = TS, subs = 1}, -- valid IPv6
  [{ip = "fe80:0000:0000:0000:0202:b3ff:fe1e:8329"}] = {code = 2, ts = TS, subs = 1}, -- valid IPv6
  [{ip = "fe80:0:0:0:202:b3ff:fe1e:8329"}] = {code = 2, ts = TS, subs = 1}, -- valid IPv6
  [{ip = "fe80::202:b3ff:fe1e:8329"}] = {code = 2, ts = TS, subs = 1}, -- valid IPv6
  [{ip = "::"}] = {code = 2, ts = TS, subs = 1}, -- valid IPv6
  [{ip = "::1"}] = {code = 2, ts = TS, subs = 1}, -- valid IPv6
  [{ip = "fe80::202:b3ff::fe1e:8329"}] = {code = 2, ts = TS, subs = 2}, -- contains 2 valid IPv6 addresses
  [{ip = ":"}] = {code = 0, ts = TS, subs = 0}, -- invalid IPv6
  [{ip = "1050!0!0+0-5@600$300c#326b"}] = {code = 0, ts = TS, subs = 0}, -- invalid IPv6
  [{ip = "1050:0:0:0:5:600:300c:326babcdef"}] = {code = 2, ts = TS, subs = 1}, -- contains valid IPv6 (1050:0:0:0:5:600:300c:326b)
  [{ip = "fe80:0000:0000:0000:0202:b3ff:fe1e:8329"}] = {code = 2, ts = TS, subs = 1}, -- valid IPv6
  [{ip = "fe80:0000:0000:0000:0202:b3ff:fe1e:8329:abcd"}] = {code = 2, ts = TS, subs = 1}, -- contains valid IPv6 (fe80:0000:0000:0000:0202:b3ff:fe1e:8329)

  -- Other
  [{ipPort = "127.0.0.1:3233"}] = {code = 2, ts = TS, subs = 1}, -- IPv4:port
  [{ipv4 = "192.168.0.1", ipv6 = "1050::30c:36b"}] = {code = 2, ts = TS, subs = 2}, -- IPv4, IPv6
  [{member_id = "12345", mail = "example@example.com"}] = {code = 0, ts = TS, subs = 0} -- no IPs
}

-- Count number of pattern occurrences in a given string
local function count_matches(s, patt)
  local n = 0
  for _ in s:gmatch(patt) do
    n = n + 1
  end
  return n
end

local function test_clean()
  for record, expect in pairs(test_cases) do
    local code, ts, record_out = clean(TAG, TS, record) -- luacheck:ignore
    local jrecord = json.encode(record) -- convert to string

    -- check return code
    if code ~= expect.code then
      print(("test_clean FAILED:\nCase: %s\nExpect code: %s\nGot: %s"):format(
              jrecord, expect.code, code))
    end

    -- check timestamp
    if ts ~= expect.ts then
      print(("test_clean FAILED:\nCase: %s\nExpect ts: %s\nGot: %s"):format(
              jrecord, expect.ts, ts))
    end

    -- check number of IP substitutions
    local jrecord_out = json.encode(record_out) -- convert to string
    local subs = count_matches(jrecord_out, IPV4_REPL) +
                   count_matches(jrecord_out, IPV6_REPL)
    if subs ~= expect.subs then
      print(("test_clean FAILED:\nCase: %s\nExpect subs: %s\nGot: %s"):format(
              jrecord, expect.subs, subs))
    end

  end
end

-- run tests
test_clean()
