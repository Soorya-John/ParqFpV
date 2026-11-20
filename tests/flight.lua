-- Run from the repository root with Lua 5.2.
-- Drive the public EdgeTX Tools entry points using a simulated clock and inputs.
local now, radio, captions, axes, sourceNames
EVT_VIRTUAL_ENTER, EVT_VIRTUAL_EXIT, EVT_VIRTUAL_NEXT, EVT_VIRTUAL_PREV = 1,2,3,4
SOLID, DOTTED = 1,2
lcd = {
  clear=function() captions={} end,
  drawLine=function(x1,y1,x2,y2)
    assert(x1>=0 and x1<128 and x2>=0 and x2<128)
    assert(y1>=0 and y1<64 and y2>=0 and y2<64)
  end,
  drawText=function(_,_,s) captions[#captions+1]=s end,
  drawRectangle=function() end, drawFilledRectangle=function() end
}
function getVersion() return "test",radio end
function getTime() return now end
function getFieldInfo(name)
  for i,n in ipairs(sourceNames) do if n==name then return {id=i} end end
end
function getValue(id) return assert(axes[id], "unbound source "..tostring(id)) end
io.open=function() return nil end -- exercise an SD card with no saved PB

local game=dofile("SCRIPTS/TOOLS/ParqFpV.lua")
local function tick(key)
  now=now+2
  assert(game.run(key or 0)==0)
end
local function shows(s)
  for _,text in ipairs(captions) do if text==s then return true end end
  return false
end
local function expect(s)
  assert(shows(s),s.." missing on screen: "..table.concat(captions," / "))
end

for _,model in ipairs({"Pocket","Boxer","GX12","Zorro","TX12MK2","TX12","T8","MT12"}) do
  radio,now=model,0
  sourceNames=model=="MT12" and {"ch4","ch2","ch3","ch1"} or {"rud","ele","thr","ail"}
  axes={0,0,-1024,0}
  game.init()
  tick(1)
  if model~="MT12" then
    for i=1,3 do tick(3) end
    tick(1) -- select Angle for repeatable pitch on every target
    tick(3)
    tick(3)
  else
    expect("Flight: Angle")
    tick(4)
  end
  tick(1)
  for gate=1,8 do
    tick(1)
    expect("PRACTICE G"..gate)
    tick(1)
    expect("Set throttle to 45%")
    axes[3]=-110
    tick(1)
    axes[2],axes[3]=1024,55
    for frame=1,240 do
      tick()
      if shows("GATE "..gate.." / CLEAR") then break end
    end
    expect("GATE "..gate.." / CLEAR")
    tick(1)
    expect("PRACTICE G"..gate)
    tick(2)
    axes[2],axes[3]=0,-1024
    tick(3)
  end
  tick(2)
  tick(3) -- wrap to freestyle
  tick(1)
  tick(1)
  axes[3]=800
  for i=1,75 do tick() end
  assert(not shows("ALT 0m"))
  tick(2)
  expect("PAUSED")
  tick(1)
  tick(2)
  tick(3)
  tick(3)
  tick(1)
  tick(3)
  tick(1)
  tick(1)
  expect("Lower throttle")
  axes[3]=-1024
  tick(1)
  expect("START IN 3")
  for i=1,151 do tick() end
  expect("L1/3  G1/8")
  print(model.." passed")
end

-- Place the quad just before each gate to test race scoring independently
-- of the pilot. The normal tick still runs physics, crossings, HUD and SD I/O.
local function slot(fn,name)
  for i=1,255 do
    local key,value=debug.getupvalue(fn,i)
    if key==name then return i,value end
    if not key then break end
  end
  error("missing upvalue "..name)
end
local _,physics=slot(game.run,"physics")
local _,crossing=slot(physics,"gateCrossing")
local _,gates=slot(crossing,"gates")
local function set(fn,key,value)
  local i=slot(fn,key)
  debug.setupvalue(fn,i,value)
end
local function cross(g,sign,verticalOffset)
  set(physics,"x",g[1]-sign*g[6]*0.04)
  set(physics,"y",g[2]+verticalOffset)
  set(physics,"z",g[3]-sign*g[7]*0.04)
  set(physics,"vx",sign*g[6]*5)
  set(physics,"vy",0)
  set(physics,"vz",sign*g[7]*5)
  tick()
end
cross(gates[1],-1,0)
expect("L1/3  G1/8")
cross(gates[1],1,3)
expect("L1/3  G1/8")
local saved
io.open=function(_,mode) return mode=="w" and {} or nil end
io.write=function(_,value) saved=value end
io.close=function() end
for lap=1,3 do
  for i,g in ipairs(gates) do
    cross(g,1,0)
    if i<8 then expect(string.format("L%d/3  G%d/8",lap,i+1)) end
    if lap==2 and i==1 then
      assert(table.concat(captions," "):match("G1  %-"))
    end
  end
end
expect("NEW PERSONAL BEST")
assert(tonumber(saved)>0)
tick(1)
expect("GATE RACE")
print("Race direction, misses, splits, three laps, PB write and retry passed")
