-- Note that we loop over many tests 100 times when checking timestamp behavior
-- to ensure that the first 8 chars only correspond to the timestamp and don't
-- contain any of the random bits.
describe("txid", function()
  local txid = require "resty.txid"

  it("generates a 20 character base32hex encoded id", function()
    local id = txid()
    assert.truthy(ngx.re.match(id, [[^[0-9a-v]{20}$]]), id)
  end)

  it("generates ids that are unique", function()
    local ids = {}
    for _ = 1, 100 do
      local id = txid()
      assert.truthy(ngx.re.match(id, [[^[0-9a-v]{20}$]]), id)

      assert.is_nil(ids[id])

      ids[id] = 1
      assert.is_not_nil(ids[id])
    end
  end)

  it("generates ids at the same timestamp that are unique", function()
    local ids = {}
    for _ = 1, 100 do
      local id = txid(1522545688552) -- 2018-04-01 01:21:28
      assert.truthy(ngx.re.match(id, [[^b2fr5nvq[0-9a-v]{12}$]]), id)

      assert.is_nil(ids[id])

      ids[id] = 1
      assert.is_not_nil(ids[id])
    end
  end)

  it("generates ids that are lexically sortable", function()
    local ids = {}
    for _ = 1, 10 do
      -- Briefly sleep between ID generation to ensure the initial timestamp
      -- portion of the id will increase.
      ngx.sleep(0.1)

      table.insert(ids, txid())
    end

    local original_order = { unpack(ids) }
    local sorted_order = { unpack(ids) }
    table.sort(sorted_order)

    assert.equal(10, #sorted_order)
    assert.same(sorted_order, original_order)
  end)

  it("generates expected ids in the past", function()
    for _ = 1, 100 do
      local id = txid(655829050000) -- 1990-10-13 14:44:10
      assert.truthy(ngx.re.match(id, [[^4om9qi54[0-9a-v]{12}$]]), id)
    end
  end)

  it("generates expected ids in the future", function()
    for _ = 1, 100 do
      local id = txid(4387530288000) -- 2109-01-13 14:24:48
      assert.truthy(ngx.re.match(id, [[^vthknin0[0-9a-v]{12}$]]), id)
    end
  end)

  it("generates ids that are lexically sortable within a few milliseconds precision", function()
    for _ = 1, 100 do
      local id = txid(0) -- 1970-01-01 00:00:00.000
      assert.truthy(ngx.re.match(id, [[^00000000[0-9a-v]{12}$]]), id)

      -- The last 2 bits of the timestamp are mixed with random data, so it
      -- requires at least a 4 milliseconds increment the portion of the ID
      -- that is reliably lexically sortable.
      local id_next = txid(4) -- 1970-01-01 00:00:00.004
      assert.truthy(ngx.re.match(id_next, [[^00000001[0-9a-v]{12}$]]), id_next)
    end
  end)

  it("generates expected ids at the epoch boundary", function()
    for _ = 1, 100 do
      local id_at_epoch = txid(0) -- 1970-01-01 00:00:00.000
      assert.truthy(ngx.re.match(id_at_epoch, [[^00000000[0-9a-v]{12}$]]), id_at_epoch)

      local id_before_epoch = txid(-1) -- 1969-12-31 23:59:59.999
      assert.truthy(ngx.re.match(id_before_epoch, [[^vvvvvvvv[0-9a-v]{12}$]]), id_before_epoch)
    end
  end)


  it("generates expected ids at the 42 bit timestamp boundary", function()
    for _ = 1, 100 do
      local id_at_max = txid(4398046511103) -- 2109-05-15 07:35:11.103
      assert.truthy(ngx.re.match(id_at_max, [[^vvvvvvvv[0-9a-v]{12}$]]), id_at_max)

      local id_after_max = txid(4398046511104) -- 2109-05-15 07:35:11.104
      assert.truthy(ngx.re.match(id_after_max, [[^00000000[0-9a-v]{12}$]]), id_after_max)
    end
  end)

  it("rolls over the sortable timestamp representation at the epoch and 42 bit timestamp maximum", function()
    for _ = 1, 100 do
      -- The same time prior to the epoch and prior to the 42bit timestamp
      -- maximum should have equivalent representations.
      local id_before_epoch = txid(-1000000000) -- 1969-12-20 10:13:20
      assert.truthy(ngx.re.match(id_before_epoch, [[^vvohijc0[0-9a-v]{12}$]]), id_before_epoch)

      local id_before_max = txid(4398046511104 - 1000000000) -- 2109-05-03 17:48:31
      assert.truthy(ngx.re.match(id_before_max, [[^vvohijc0[0-9a-v]{12}$]]), id_before_max)

      -- Similarly, the same time after the epoch and after the 42bit timestamp
      -- maximum should appear similarly (the 42bit timestamp maximum becomes
      -- the new epoch).
      local id_after_epoch = txid(1000000000) -- 1970-01-12 13:46:40
      assert.truthy(ngx.re.match(id_after_epoch, [[^007edck0[0-9a-v]{12}$]]), id_after_epoch)

      local id_after_max = txid(4398046511104 + 1000000000) -- 2109-05-26 21:21:51
      assert.truthy(ngx.re.match(id_after_max, [[^007edck0[0-9a-v]{12}$]]), id_after_max)
    end
  end)
end)
