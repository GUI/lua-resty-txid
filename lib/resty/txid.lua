local base32 = require "resty.txid.base32"
local bitwise = require "bit"
local ffi = require "ffi"
local resty_random = require "resty.random"

local bitwise_and = bitwise.band
local bitwise_lshift = bitwise.lshift
local bitwise_or = bitwise.bor
local bitwise_rshift = bitwise.rshift
local ffi_cast = ffi.cast

local BYTE_SIZE = 8
local TIMESTAMP_SIZE = 64
local TRUNCATED_TIMESTAMP_SIZE = 42
local TRUNCATED_TIMESTAMP_SHIFT = TIMESTAMP_SIZE - TRUNCATED_TIMESTAMP_SIZE
local BYTE_MASK = 0xff

local BYTE1_SHIFT = TIMESTAMP_SIZE - 1 * BYTE_SIZE
local BYTE2_SHIFT = TIMESTAMP_SIZE - 2 * BYTE_SIZE
local BYTE3_SHIFT = TIMESTAMP_SIZE - 3 * BYTE_SIZE
local BYTE4_SHIFT = TIMESTAMP_SIZE - 4 * BYTE_SIZE
local BYTE5_SHIFT = TIMESTAMP_SIZE - 5 * BYTE_SIZE
local BYTE6_SHIFT = TIMESTAMP_SIZE - 6 * BYTE_SIZE

local function byte_from_time(msec, shift)
  return tonumber(bitwise_and(bitwise_rshift(msec, shift), BYTE_MASK))
end

return function(time)
  if not time then
    time = ngx.now() * 1000
  end

  local random = resty_random.bytes(7)
  local msec = ffi_cast("uint64_t", time)
  local msec_truncated = bitwise_lshift(msec, TRUNCATED_TIMESTAMP_SHIFT)

  local byte1 = byte_from_time(msec_truncated, BYTE1_SHIFT)
  local byte2 = byte_from_time(msec_truncated, BYTE2_SHIFT)
  local byte3 = byte_from_time(msec_truncated, BYTE3_SHIFT)
  local byte4 = byte_from_time(msec_truncated, BYTE4_SHIFT)
  local byte5 = byte_from_time(msec_truncated, BYTE5_SHIFT)
  local byte6 = bitwise_or(byte_from_time(msec_truncated, BYTE6_SHIFT), string.byte(string.sub(random, 1, 1)))
  local data = string.char(byte1, byte2, byte3, byte4, byte5, byte6) .. string.sub(random, 2)

  local encoded = base32(data, false)
  return encoded
end
