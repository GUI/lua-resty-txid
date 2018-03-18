local bitwise = require "bit"

local bitwise_and = bitwise.band
local bitwise_lshift = bitwise.lshift
local bitwise_or = bitwise.bor
local bitwise_rshift = bitwise.rshift

local BYTE_MASK = 0x1f
local BASE32_ALPHABET = "0123456789abcdefghijklmnopqrstuv"
local BASE32_ALPHABET_TABLE = {}
for index = 1, #BASE32_ALPHABET do
  local char = BASE32_ALPHABET:sub(index, index)
  BASE32_ALPHABET_TABLE[index - 1] = char
end

return function(src, pad)
  local out = {}
  local len = #src
  local offset = 0
  while len > 0 do
    local bit1 = 0
    local bit2 = 0
    local bit3 = 0
    local bit4 = 0
    local bit5 = 0
    local bit6 = 0
    local bit7 = 0
    local bit8 = 0

    if len >= 5 then
      local byte5_pos = 5 + offset
      local src_byte5 = string.byte(string.sub(src, byte5_pos, byte5_pos))
      bit8 = bitwise_or(bit8, bitwise_and(src_byte5, BYTE_MASK))
      bit7 = bitwise_or(bit7, bitwise_rshift(src_byte5, 5))
    end

    if len >= 4 then
      local byte4_pos = 4 + offset
      local src_byte4 = string.byte(string.sub(src, byte4_pos, byte4_pos))
      bit7 = bitwise_or(bit7, bitwise_and(bitwise_lshift(src_byte4, 3), BYTE_MASK))
      bit6 = bitwise_or(bit6, bitwise_and(bitwise_rshift(src_byte4, 2), BYTE_MASK))
      bit5 = bitwise_or(bit5, bitwise_rshift(src_byte4, 7))
    end

    if len >= 3 then
      local byte3_pos = 3 + offset
      local src_byte3 = string.byte(string.sub(src, byte3_pos, byte3_pos))
      bit5 = bitwise_or(bit5, bitwise_and(bitwise_lshift(src_byte3, 1), BYTE_MASK))
      bit4 = bitwise_or(bit4, bitwise_and(bitwise_rshift(src_byte3, 4), BYTE_MASK))
    end

    if len >= 2 then
      local byte2_pos = 2 + offset
      local src_byte2 = string.byte(string.sub(src, byte2_pos, byte2_pos))
      bit4 = bitwise_or(bit4, bitwise_and(bitwise_lshift(src_byte2, 4), BYTE_MASK))
      bit3 = bitwise_or(bit3, bitwise_and(bitwise_rshift(src_byte2, 1), BYTE_MASK))
      bit2 = bitwise_or(bit2, bitwise_and(bitwise_rshift(src_byte2, 6), BYTE_MASK))
    end

    if len >= 1 then
      local byte1_pos = 1 + offset
      local src_byte1 = string.byte(string.sub(src, byte1_pos, byte1_pos))
      bit2 = bitwise_or(bit2, bitwise_and(bitwise_lshift(src_byte1, 2), BYTE_MASK))
      bit1 = bitwise_or(bit1, bitwise_rshift(src_byte1, 3))
    end

    if len >= 1 then
      table.insert(out, BASE32_ALPHABET_TABLE[bit1])
      table.insert(out, BASE32_ALPHABET_TABLE[bit2])
    elseif pad then
      table.insert(out, "=")
      table.insert(out, "=")
    end

    if len >= 2 then
      table.insert(out, BASE32_ALPHABET_TABLE[bit3])
      table.insert(out, BASE32_ALPHABET_TABLE[bit4])
    elseif pad then
      table.insert(out, "=")
      table.insert(out, "=")
    end

    if len >= 3 then
      table.insert(out, BASE32_ALPHABET_TABLE[bit5])
      table.insert(out, BASE32_ALPHABET_TABLE[bit6])
    elseif pad then
      table.insert(out, "=")
      table.insert(out, "=")
    end

    if len >= 4 then
      table.insert(out, BASE32_ALPHABET_TABLE[bit7])
      table.insert(out, BASE32_ALPHABET_TABLE[bit8])
    elseif pad then
      table.insert(out, "=")
      table.insert(out, "=")
    end

    len = len - 5
    offset = offset + 5
  end

  local out_str = table.concat(out, "")
  return out_str
end

