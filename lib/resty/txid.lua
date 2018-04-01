local base32hex = require "resty.txid.base32hex"
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

  -- Generate random data to append after the timestamp.
  local random = resty_random.bytes(7)

  -- Convert the time to a 64 bit integer for further manipulation.
  local msec = ffi_cast("uint64_t", time)

  -- The timestamp is 64 bits, but shorten it to 42 bits. This is enough to
  -- store dates up to 2109-05-15 (4398046511103 milliseconds past epoch)
  -- before cycling back to the original epoch values.
  local msec_truncated = bitwise_lshift(msec, TRUNCATED_TIMESTAMP_SHIFT)

  -- Extract individual bytes from the timestamp as numeric character codes.
  local byte1 = byte_from_time(msec_truncated, BYTE1_SHIFT)
  local byte2 = byte_from_time(msec_truncated, BYTE2_SHIFT)
  local byte3 = byte_from_time(msec_truncated, BYTE3_SHIFT)
  local byte4 = byte_from_time(msec_truncated, BYTE4_SHIFT)
  local byte5 = byte_from_time(msec_truncated, BYTE5_SHIFT)

  -- For the 6th byte, use the last 2 bits from the timestamp (bits 41-42), and
  -- the rest of the byte is shared with the first byte of random data.
  local byte6 = bitwise_or(byte_from_time(msec_truncated, BYTE6_SHIFT), string.byte(string.sub(random, 1, 1)))

  -- Construct the full ID by converting the timestamp character codes to their
  -- string values (6 bytes, 48 total bits, 42 of which represent the
  -- timestamp), and then append the rest of the random data (6 bytes/48 bits),
  -- resulting in a 12 byte/96 bit ID.
  local data = string.char(byte1, byte2, byte3, byte4, byte5, byte6) .. string.sub(random, 2)

  -- Base32hex encode the binary data (without padding), resulting in a 20
  -- character, lexically sortable sting.
  local encoded = base32hex(data, false)
  return encoded
end
