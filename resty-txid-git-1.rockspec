package = "resty-txid"
version = "git-1"
source = {
  url = "git://github.com/GUI/lua-resty-txid.git",
}
description = {
  summary = "",
  detailed = "",
  homepage = "https://github.com/GUI/lua-resty-txid",
  license = "MIT",
}
build = {
  type = "builtin",
  modules = {
    ["resty.txid"] = "lib/resty/txid.lua",
    ["resty.txid.base32hex"] = "lib/resty/txid/base32hex.lua",
  },
}