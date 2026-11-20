-- Run from the repository root with Lua 5.2. Inputs drive the public Tools
-- entry points. Targeted race tests also stage the quad near each gate plane.
local now,radio,captions,highlight,axes,sourceNames
local enter,back,nextKey,prevKey = 1,2,3,4
EVT_VIRTUAL_ENTER,EVT_VIRTUAL_EXIT,EVT_VIRTUAL_NEXT,EVT_VIRTUAL_PREV = enter,back,nextKey,prevKey
SOLID,DOTTED,SMLSIZE,INVERS = 1,2,4,8
lcd = {
  clear=function() captions,highlight={},nil end,
  drawLine=function(x1,y1,x2,y2)
    assert(x1>=0 and x1<128 and x2>=0 and x2<128)
    assert(y1>=0 and y1<64 and y2>=0 and y2<64)
  end,
  drawText=function(x,y,s,flags)
    captions[#captions+1]=s
    if (x==13 or (x==27 and y>=21)) and flags==SMLSIZE+INVERS then highlight=s end
    if s=="by soorya" then assert(y>=56 and y<=58 and flags==SMLSIZE) end
  end,
  drawRectangle=function() end, drawFilledRectangle=function() end
}
function getVersion() return "test",radio end
function getTime() return now end
function getFieldInfo(name)
  for i,n in ipairs(sourceNames) do if n==name then return {id=i} end end
end
function getValue(id) return assert(axes[id],"unbound source "..tostring(id)) end

local dir="/SCRIPTS/TOOLS/"
local files={[dir.."ParqPB.dat"]="222.34",[dir.."ParqSwt.dat"]="bad"}
io.open=function(path,mode)
  if mode=="w" or files[path] then return path end
end
io.read=function(path) return files[path] end
io.write=function(path,s) files[path]=s end
io.close=function() end

local game=dofile("SCRIPTS/TOOLS/ParqFpV.lua")
local function tick(key)
  now=now+2
  assert(game.run(key or 0)==0)
end
local function shows(s)
  for _,label in ipairs(captions) do if label==s then return true end end
  return false
end
local function expect(s)
  assert(shows(s),s.." missing on screen: "..table.concat(captions," / "))
end
local function choose(item)
  for i=1,7 do
    if item==highlight then tick(enter); return end
    tick(nextKey)
  end
  error("Menu item missing: "..item.." / "..table.concat(captions," / "))
end
local function boot(model)
  radio,now=model,0
  sourceNames=model=="MT12" and {"ch4","ch2","ch3","ch1"} or {"rud","ele","thr","ail"}
  axes={0,0,-1024,0}
  game.init()
  tick()
  expect("by soorya")
  tick(enter)
end

local circuits={
  {name="Club Loop",menu="1  Club Loop",n=6,file="ParqClub.dat"},
  {name="Switchback",menu="2  Switchback",n=8,file="ParqSwt.dat"},
  {name="Highline",menu="3  Highline",n=10,file="ParqHigh.dat"},
  {name="Ironworks",menu="Classic  Ironworks",n=8,file="ParqPB.dat"}
}
for _,model in ipairs({"Pocket","Boxer","GX12","Zorro","TX12MK2","TX12","T8","MT12"}) do
  boot(model)
  if model~="MT12" then choose("Flight: Acro") end
  expect("Flight: Angle")
  for _,course in ipairs(circuits) do
    choose("Gate practice")
    choose(course.menu)
    for gate=1,course.n do
      tick(enter)
      expect("PRACTICE G"..gate)
      tick(enter)
      expect("Set throttle to 45%")
      axes[3]=-110
      tick(enter)
      axes[2],axes[3]=1024,55
      for frame=1,240 do
        tick()
        if shows("GATE "..gate.." / CLEAR") then break end
      end
      expect("GATE "..gate.." / CLEAR")
      tick(enter)
      expect("PRACTICE G"..gate)
      tick(back)
      axes[2],axes[3]=0,-1024
      tick(nextKey)
    end
    tick(back)
    tick(back)
  end
  print(model.." flew all 32 gate approaches")
end

local function slot(fn,name)
  for i=1,255 do
    local key,v=debug.getupvalue(fn,i)
    if key==name then return i,v end
    if not key then break end
  end
  error("missing upvalue "..name)
end
local function value(fn,key)
  local _,v=slot(fn,key)
  return v
end
local function set(fn,key,v)
  local i=slot(fn,key)
  debug.setupvalue(fn,i,v)
end
local fly=value(game.run,"fly")
local physics=value(fly,"physics")
local crossing=value(physics,"gateCrossing")
local moveAxis=value(physics,"moveAxis")
local runner=value(fly,"advanceRun")

local function cross(g,sign,verticalOffset)
  set(physics,"x",g[1]-sign*g[6]*0.04)
  set(physics,"y",g[2]+verticalOffset)
  set(physics,"z",g[3]-sign*g[7]*0.04)
  set(physics,"vx",sign*g[6]*5)
  set(physics,"vy",0)
  set(physics,"vz",sign*g[7]*5)
  tick()
end
for _,course in ipairs(circuits) do
  choose("Gate race / 3 laps")
  choose(course.menu)
  axes[3]=900
  tick(enter)
  expect("Lower throttle")
  axes[3]=-1024
  tick(enter)
  expect("START IN 3")
  for i=1,151 do tick() end
  local gates=value(crossing,"gates")
  assert(#gates==course.n)
  assert((value(moveAxis,"boxCount")==0)==(course.name~="Ironworks"))
  cross(gates[1],-1,0)
  cross(gates[1],1,4)
  expect("L1/3  G1/"..#gates)
  local before={}
  for key,v in pairs(files) do before[key]=v end
  for lap=1,3 do
    for i,g in ipairs(gates) do
      cross(g,1,0)
      if i<#gates then expect(string.format("L%d/3  G%d/%d",lap,i+1,#gates)) end
      if lap==2 and i==1 then assert(table.concat(captions," "):match("G1  %-")) end
    end
  end
  expect("NEW PERSONAL BEST")
  assert(tonumber(files[dir..course.file])>0)
  for key,v in pairs(before) do
    if key~=dir..course.file then assert(files[key]==v) end
  end
  tick(enter)
  expect(course.name)
  tick(back)
  tick(back)
end
print("All four three-lap races, splits, aperture misses, direction and independent PB files passed")

boot("Pocket")
choose("Bando freestyle")
local bandos={"Ironworks","Spillway","Parkade","Dry Dock","Kiln Yard"}
tick(prevKey)
expect("< Kiln Yard >")
tick(nextKey)
for i,name in ipairs(bandos) do
  expect("< "..name.." >")
  expect(i.."/5")
  -- Sweep the largest quad through a signature opening and into an adjacent solid.
  local function sweep(axis,start,finish,c1,p1,c2,p2)
    return moveAxis(start,finish-start,1,0.33,-50,50,axis,c1,p1,c2,p2)
  end
  local function alongZ(px,py,from,to)
    return sweep(3,from,to,1,px,2,py)
  end
  if i==1 then
    assert(alongZ(0,2,2,25)==25 and alongZ(5,2,2,25)<12)
  elseif i==2 then
    assert(alongZ(-3.5,2,-8,10)==10 and alongZ(0,2,-8,10)<5)
    assert(alongZ(4,2,8,16)==16 and alongZ(-4,2,16,24)==24)
  elseif i==3 then
    assert(sweep(2,15,1,1,0,3,17)==1 and sweep(2,15,1,1,6,3,17)>10)
  elseif i==4 then
    assert(alongZ(0,2,-8,38)==38 and alongZ(-3,6,-8,18)<7)
  else
    assert(alongZ(-5,2,-9,14)==14 and alongZ(-8.2,2,-9,14)<5)
    assert(alongZ(-5,12,-9,12)==12 and alongZ(-7.5,12,-9,12)<7)
  end
  tick(enter)
  expect(name)
  axes[3]=850
  for j=1,65 do tick() end
  assert(not shows("ALT 0m"))
  tick(back)
  choose("Restart")
  expect("< "..name.." >")
  axes[3]=-1024
  if i<#bandos then tick(nextKey) end
end
print("Five distinct freestyle sites, clearance, solids, takeoff and restart passed")

-- Verify a rewind by re-flying the same inputs and comparing the complete state.
local fields={"x","y","z","vx","vy","vz","qw","qx","qy","qz","motor","rollRate","pitchRate","yawRate"}
local function snapshot()
  local result={}
  for i,key in ipairs(fields) do result[i]=value(physics,key) end
  return result
end
local function samePose(expected)
  for i,key in ipairs(fields) do assert(math.abs(value(physics,key)-expected[i])<1e-8,key.." diverged") end
end
local function manoeuvre(t)
  axes[1]=math.sin(t/31)*420
  axes[2]=math.cos(t/39)*380
  axes[3]=t<65 and 640 or 28
  axes[4]=math.sin(t/45)*450
  tick()
end
tick(enter)
local log={}
for t=1,347 do manoeuvre(t); log[t]=snapshot() end
tick(back)
choose("Rewind")
for i=1,40 do tick(prevKey) end
expect("< REWIND >")
assert(value(fly,"flightTick")==40)
samePose(log[40])
tick(back)
samePose(log[347])
choose("Rewind")
tick(prevKey)
local branch=value(fly,"flightTick")
tick(enter)
for t=branch+1,branch+8 do manoeuvre(t); samePose(log[t]) end
tick(back)
choose("Rewind")
for i=1,32 do tick(nextKey) end
assert(value(fly,"flightTick")==branch)
tick(back)
choose("Main menu")
print("Rewind ring wrap, cancel, exact flight continuation and discarded future passed")

-- A stick-only pilot aims at the current opening. Run across many difficulty
-- changes and coordinate rebases, then deliberately miss and start a fresh run.
axes={0,0,-1024,0}
choose("Endless Run")
expect("ENDLESS RUN")
local queue=value(runner,"runGates")
local original={ [queue[1]]=true,[queue[2]]=true,[queue[3]]=true }
local firstLayout=queue[2][1]
local function stickInput(speed)
  return math.max(-1,math.min(1,speed*1.4))*1024
end
tick(enter)
local checkpoints,rebases,lastZ=0,0,0
local width=queue[1][4]
for frame=1,20000 do
  local gate=queue[1]
  local px,py,pz=value(runner,"x"),value(runner,"y"),value(runner,"z")
  local speed=value(runner,"runSpeed")
  local lead=math.max(0.18,(gate[3]-pz)/speed*0.55)
  axes[4]=stickInput((gate[1]-px)/(13*lead))
  axes[2]=stickInput((py-gate[2])/(8*lead))
  tick()
  assert(not shows("ENDLESS RUN / FINISH"),"generated approach defeated the stick-only pilot")
  local score=value(runner,"runScore")
  if score>checkpoints then
    assert(#queue==3 and original[queue[1]] and original[queue[2]] and original[queue[3]])
    assert(queue[1][3]<queue[2][3] and queue[2][3]<queue[3][3])
    assert(queue[1][4]<=width)
    checkpoints,width=score,queue[1][4]
  end
  if pz<lastZ then rebases=rebases+1 end
  lastZ=pz
  if checkpoints==100 then break end
end
assert(checkpoints==100 and rebases>=5 and value(runner,"runSpeed")>13)
tick(back)
expect("PAUSED")
assert(not shows("Rewind"))
local pausedZ=value(runner,"z")
for i=1,30 do tick() end
assert(value(runner,"z")==pausedZ)
tick(enter)
axes[4],axes[2]=1024,1024
for i=1,300 do
  tick()
  if shows("ENDLESS RUN / FINISH") then break end
end
expect("ENDLESS RUN / FINISH")
assert(tonumber(files[dir.."ParqRun.dat"])==value(runner,"runScore"))
tick(enter)
expect("ENDLESS RUN")
assert(queue[2][1]~=firstLayout and value(runner,"runScore")==0)
print("Endless Run cleared 100 procedural gates on stick inputs, saved the best and generated a fresh retry")
