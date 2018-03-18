describe("txid", function()
  local txid = require "resty.txid"

  it("generates", function()
    local id
    for i=1,1000000 do
      id = txid()
    end
    print(id)
  end)
end)
