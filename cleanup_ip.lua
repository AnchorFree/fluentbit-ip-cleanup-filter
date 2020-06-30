-- required to use local deps from ./vendor
-- vendor is built for linux and lua v5.1
local version = _VERSION:match("%d+%.%d+")
local vendor_path = os.getenv("VENDOR_PATH")
if vendor_path ~= nil then
  if vendor_path:sub(-1) ~= "/" then
    vendor_path = vendor_path .. "/"
  end
else
  print("Error: VENDOR_PATH is not set; aborting script execution")
  os.exit(1)
end

package.path = vendor_path .. 'vendor/share/lua/' .. version ..
                 '/?.lua;vendor/share/lua/' .. version .. '/?/init.lua;' ..
                 package.path
package.cpath = vendor_path .. 'vendor/lib/lua/' .. version .. '/?.so;' ..
                  package.cpath

-- Replacements for IPv4 and IPv6 addresses
local IPV4_REPL = os.getenv("IPV4_REPL") or "0.0.0.0"
local IPV6_REPL = os.getenv("IPV6_REPL") or ("0000:"):rep(8):sub(1, -2)

--[[
    Each function called by fluent-bit lua filter must return 3 values:

        return code, timestamp, record

    where:
    - code     : -1 record must be deleted
                 0 record not modified, keep the original
                 1 record was modified, replace timestamp and record.
                 2 record was modified, replace record and keep timestamp.
    - timestamp: Unix timestamp with precision (double)
    - record   : Table with multiple key/val

    Uppon return if code == 1 (modified), then filter_lua plugin
    will replace the original timestamp and record with the returned
    values. If code == 0 the original record is kept otherwise if
    code == -1, the original record will be deleted.
]]
function clean(tag, timestamp, record) -- luacheck:ignore
  -- Making imports at module level leads to errors from fluentbit:
  -- [error] [filter:lua:lua.0] function clean is not found
  -- [error] Failed initialize filter lua.0
  --
  -- Thus, everyting placed under single function
  local lpeg = require("lpeg")
  local lpat_ipv4 = require("lpeg_patterns.IPv4")
  local lpat_ipv6 = require("lpeg_patterns.IPv6")
  local json = require('lunajson')

  --[[
    Global substitution.

    Somewhat similar to string.gsub. It receives a pattern and a replacement
    value, and substitutes the replacement value for all occurrences of the
    pattern in a given string.

    http://www.inf.puc-rio.br/~roberto/lpeg/#ex
  ]]
  local function lpeg_gsub(s, patt, repl)
    patt = lpeg.Cs((patt / repl + 1) ^ 0)
    return lpeg.match(patt, s)
  end

  -- convert rocord to string
  local json_record = json.encode(record)

  -- Using 2 calls to lpeg_gsub instead of run single with pattern (ipv4 + ipv6)
  -- because there is no simple way to handle replacements in such case
  local cleaned_ipv4 = lpeg_gsub(json_record, lpat_ipv4.IPv4address, IPV4_REPL)
  local cleaned_all = lpeg_gsub(cleaned_ipv4, lpat_ipv6.IPv6address, IPV6_REPL)

  -- String equality is cheap:
  --- https://www.cryptobells.com/constant-time-string-comparison-in-lua/
  if json_record == cleaned_all then
    -- no modifications was done to record
    return 0, timestamp, record
  end

  -- modified record (keep timestamp)
  return 2, timestamp, json.decode(cleaned_all)
end
