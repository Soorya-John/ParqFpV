-- toolName = "TNS|ParqFpV|TNE"
local abs, min, max, floor = math.abs, math.min, math.max, math.floor
local sin, cos, sqrt = math.sin, math.cos, math.sqrt
local line, rect, fill, label = lcd.drawLine, lcd.drawRectangle, lcd.drawFilledRectangle, lcd.drawText
local small, inverse, erase, ink = SMLSIZE or 0, INVERS or 0, ERASE or 0, FORCE or 0
local quads = {
  {name="65mm Whoop", thrust=22, rate=5.4, yaw=3.6, drag=0.95, radius=0.13, cam=10},
  {name="3in Cine", thrust=27, rate=4.7, yaw=3.1, drag=0.65, radius=0.22, cam=15},
  {name="5in Freestyle", thrust=39, rate=8.2, yaw=4.8, drag=0.45, radius=0.33, cam=22},
  {name="5in Racer", thrust=46, rate=9.4, yaw=5.3, drag=0.38, radius=0.33, cam=30},
}
-- Gate fields: center x/y/z, half width, half height, normal x/z.
-- The start pad faces the first gate, along positive z.
local ironGates = {
  {0, 2.2, 9, 3.1, 1.7, 0, 1},
  {0, 2.5, 21, 3.2, 1.9, 0, 1},
  {9, 5.0, 29, 4.0, 2.4, 1, 0},
  {21, 6.4, 29, 4.2, 2.8, 1, 0},
  {25, 3.7, 16, 4.4, 2.8, 0, -1},
  {22, 2.8, 1, 3.3, 2.1, 0, -1},
  {12, 2.5, -5, 3.6, 1.9, -1, 0},
  {0, 2.2, -3, 3.0, 1.7, 0, 1},
}
-- Clean circuits use gate centres in flight order. The gate plane faces
-- halfway between the incoming and outgoing legs, including the lap seam.
local courses = {
  {name="Club Loop", detail="Wide gates / broad turns", file="ParqClub.dat", w=3.6,h=2.1,
    gates={{-7,2.7,6},{-7,3.1,23},{5,4.3,33},{20,3.5,24},{21,2.8,4},{3,2.5,-5}}},
  {name="Switchback", detail="Offset slalom / hairpin", file="ParqSwt.dat", w=2.9,h=1.85,
    gates={{-8,2.8,5},{-14,3.4,15},{-4,4.2,23},{-10,4.8,32},
           {6,5.2,35},{17,3.5,22},{10,4.6,10},{4,2.8,-4}}},
  {name="Highline", detail="Climb / dive / tight gates", file="ParqHigh.dat", w=2.25,h=1.55,
    gates={{-9,2.4,4},{-15,4.8,12},{-9,8,22},{-14,11.5,32},{-1,12.5,37},
           {10,8.4,30},{22,4.5,35},{24,3,18},{11,6.6,8},{4,2.6,-4}}},
  {name="Ironworks", detail="Classic warehouse circuit", file="ParqPB.dat", gates=ironGates},
}
local selectedCourse, gates
local function selectCourse(index)
  selectedCourse = index
  local course = courses[index]
  gates = course.gates
  if gates[1][6] then return end
  for i,g in ipairs(gates) do
    local prev,nextGate = gates[(i-2)%#gates+1],gates[i%#gates+1]
    local ax,az,bx,bz = g[1]-prev[1],g[3]-prev[3],nextGate[1]-g[1],nextGate[3]-g[3]
    local a,b = sqrt(ax*ax+az*az),sqrt(bx*bx+bz*bz)
    local nx,nz = ax/a+bx/b,az/a+bz/b
    local length = sqrt(nx*nx+nz*nz)
    g[4],g[5],g[6],g[7] = course.w,course.h,nx/length,nz/length
  end
end
-- Reuse one set of obstacle tables as the pilot browses the sites. Drawing
-- and collision use the same active count, including on smaller layouts.
local boxes, boxCount = {},0
local function box(x1,y1,z1,x2,y2,z2)
  boxCount = boxCount+1
  local b = boxes[boxCount]
  if not b then
    b = {}
    boxes[boxCount] = b
  end
  b[1],b[2],b[3],b[4],b[5],b[6] = x1,y1,z1,x2,y2,z2
  local hx,hy,hz = (x2-x1)*0.5,(y2-y1)*0.5,(z2-z1)*0.5
  b[7],b[8],b[9],b[10] = x1+hx,y1+hy,z1+hz,sqrt(hx*hx+hy*hy+hz*hz)
end

local function ironworks()
  -- Warehouse shell with open loading bays at both ends and overhead beams.
  box(-10,0,12,-9,8,24)
  box(9,0,12,10,8,24)
  box(-9,0,12,-4,7,13)
  box(4,0,12,9,7,13)
  box(-9,5.4,12,9,7,13)
  box(-9,0,23,-4,7,24)
  box(4,0,23,9,7,24)
  box(-9,5.4,23,9,7,24)
  box(-9,7,16,9,7.5,17)
  box(-9,7,20,9,7.5,21)
  box(-8,0,17,-5,2,22)
  box(5,0,15,8,2,20)
  -- Broken upper floor and support columns along the north yard.
  box(7,7.9,32,22,8.7,40)
  box(7,0,32,8,7.9,33)
  box(21,0,32,22,7.9,33)
  box(7,0,39,8,7.9,40)
  box(21,0,39,22,7.9,40)
  box(7,0,39,22,4.2,40)
  box(16,0,34,20,2.2,37)
  -- Containers, chimney, yard wall and concrete blocks.
  box(13,0,9,16,3.2,19)
  box(17,0,9,20,3.2,17)
  box(13,3.2,11,16,5.8,18)
  box(30,0,11,33,14,14)
  box(32,0,16,33,4,30)
  box(8,0,2,13,0.9,4)
  box(-8,0,-6,-4,2.5,-1)
  box(17,0,-10,23,1.2,-9)
  box(-15,0,8,-13,3,12)
end

local function spillway()
  -- Two sluice mouths feed a dry channel. The low line weaves right, left,
  -- right between baffles; the service bridge leaves both banks accessible.
  box(-10,0,0,-8,5,34)
  box(8,0,0,10,5,34)
  box(-8,0,5,-5.5,7,7)
  box(-1.5,0,5,1.5,7,7)
  box(5.5,0,5,8,7,7)
  box(-8,5.5,5,8,7,7)
  box(-8,0,13,1.5,3.6,14)
  box(-1.5,0,21,8,3.6,22)
  box(-8,0,29,0.5,3.6,30)
  box(-13,5,23,15,5.8,25)
  box(13,0,22,16,8.5,26)
  box(11,8.5,20,18,11,28)
  box(-15,0,24,-13,5,26)
end

local function parkade()
  -- Four slabs per floor leave a continuous 7 x 9 m lightwell.
  for level=1,2 do
    local h = level*4.8
    box(-11,h,5,-3,h+0.65,29)
    box(4,h,5,12,h+0.65,29)
    box(-3,h,5,4,h+0.65,12)
    box(-3,h,21,4,h+0.65,29)
  end
  for z=6,26,10 do
    box(-10,0,z,-8.8,9.6,z+1.2)
    box(9.8,0,z,11,9.6,z+1.2)
  end
  -- A high skybridge gives a return line around the detached lift tower.
  box(12,9.6,22,22,10.25,25)
  box(21,0,20,25,13.2,27)
  box(22,13.2,21,24,14.6,25)
end

local function dryDock()
  box(-14,0,2,-5,2.8,37)
  box(5,0,2,16,2.8,37)
  for z=8,28,20 do
    box(-10,2.8,z,-8.5,12,z+2)
    box(8.5,2.8,z,10,12,z+2)
    box(-13,12,z,13,13.2,z+2)
  end
  -- Suspended loads alternate sides. The floor of the dock is open end to end.
  box(-3.8,7.2,8.7,-3,12,9.3)
  box(-5.6,4.2,7,-1.4,7.2,11)
  box(1,8.5,28.7,1.8,12,29.3)
  box(-0.6,5.8,27,3.4,8.5,31)
  box(-13,2.8,15,-9,5.4,21)
  box(11,2.8,17,15,5.4,24)
  box(11,5.4,18,15,8,24)
end

local function kiln(cx,front,height)
  box(cx-4.2,0,front,cx-2.4,4.5,front+6)
  box(cx+2.4,0,front,cx+4.2,4.5,front+6)
  box(cx-4.2,4.5,front,cx+4.2,6,front+6)
  box(cx-3.8,6,front+2,cx-1.8,height,front+4)
  box(cx+1.8,6,front+2,cx+3.8,height-2,front+4)
end

local function kilnYard()
  kiln(-5,5,20)
  kiln(10,21,15)
  -- An overhead flue turns across the yard to join the two furnaces.
  box(-2,9,7,14,10,9)
  box(12,9,9,14,10,24)
  box(12.4,0,14,13.6,9,15.2)
  box(-13,0,23,-8,1.8,29)
  box(-13,1.8,25,-10,3.4,29)
end

local sites = {
  {name="Ironworks", line="Loading bays", x=0, z=2, build=ironworks},
  {name="Spillway", line="Sluice slalom", x=-3.5, z=-8, build=spillway},
  {name="Parkade", line="Lightwell dive", x=0, z=-7, build=parkade},
  {name="Dry Dock", line="Gantry run", x=0, z=-8, build=dryDock},
  {name="Kiln Yard", line="Twin flue gap", x=-5, z=-9, build=kilnYard},
}
local selectedSite, activeSite
local function loadSite(site)
  if site==activeSite then return end
  boxCount = 0
  if site then site.build() end
  activeSite = site
end

local state, row, quad, assist, invertPitch, reverseThrottle
local racing, gateIndex, lap, lapStart, raceTime, bestLap, resultPB
local screenStart, frameTime, countStart
local drill, drillGate, drillBest, drillRecord
local motor, rollRate, pitchRate, yawRate
local lapMarks, bestMarks, splitText, splitUntil
local endless, runScore, runSpeed, randomState
local runRecord = {file="ParqRun.dat", count=true}
local runGates = {{},{},{}}
local x,y,z, vx,vy,vz, qw,qx,qy,qz
local stickIds = {}
local useChannels
local function bindControls(channels)
  useChannels = channels
  -- Internal axis order is yaw, pitch, throttle, roll.
  local names = channels and {"ch4","ch2","ch3","ch1"} or {"rud","ele","thr","ail"}
  for i=1,4 do
    local info = getFieldInfo(names[i])
    stickIds[i] = info and info.id or names[i]
  end
end
local camRightX,camRightY,camRightZ, camUpX,camUpY,camUpZ, camFwX,camFwY,camFwZ
local rX,rY,rZ, uX,uY,uZ, fX,fY,fZ
local camCos, camSin
local NEAR, FAR, FOCAL = 0.38, 37, 51
local LAPS = 3
local dataDir = "/SCRIPTS/TOOLS/"

local function clamp(value, low, high)
  return max(low, min(high, value))
end

local function drawLine(x1,y1,x2,y2,pattern)
  line(floor(x1+0.5),floor(y1+0.5),floor(x2+0.5),floor(y2+0.5),pattern or SOLID,ink)
end

-- Clip projected lines against the viewport before calling the LCD API.
local function screenLine(ax,ay,bx,by,pattern,bold)
  if (ax<0 and bx<0) or (ax>127 and bx>127)
    or (ay<8 and by<8) or (ay>55 and by>55) then return end
  if ax<0 or ax>127 then
    local edge = clamp(ax,0,127)
    ay,ax = ay+(by-ay)*(edge-ax)/(bx-ax),edge
  end
  if bx<0 or bx>127 then
    local edge = clamp(bx,0,127)
    by,bx = by+(ay-by)*(edge-bx)/(ax-bx),edge
  end
  if (ay<8 and by<8) or (ay>55 and by>55) then return end
  if ay<8 or ay>55 then
    local edge = clamp(ay,8,55)
    ax,ay = ax+(bx-ax)*(edge-ay)/(by-ay),edge
  end
  if by<8 or by>55 then
    local edge = clamp(by,8,55)
    bx,by = bx+(ax-bx)*(edge-by)/(ay-by),edge
  end
  drawLine(ax,ay,bx,by,pattern)
  if bold then
    if abs(bx-ax)>=abs(by-ay) then
      local offset = max(ay,by)>=54.5 and -1 or 1
      drawLine(ax,clamp(ay+offset,8,55),bx,clamp(by+offset,8,55),pattern)
    else
      local offset = max(ax,bx)>=126.5 and -1 or 1
      drawLine(clamp(ax+offset,0,127),ay,clamp(bx+offset,0,127),by,pattern)
    end
  end
end

local function cameraPoint(px,py,pz)
  px,py,pz = px-x,py-y,pz-z
  return px*camRightX+py*camRightY+pz*camRightZ,
         px*camUpX+py*camUpY+pz*camUpZ,
         px*camFwX+py*camFwY+pz*camFwZ
end

local function edge(ax,ay,az,bx,by,bz,pattern,bold)
  if (az<NEAR and bz<NEAR) or (az>FAR and bz>FAR) then return end
  if az<NEAR or az>FAR then
    local depth = clamp(az,NEAR,FAR)
    local t = (depth-az)/(bz-az)
    ax,ay,az = ax+(bx-ax)*t,ay+(by-ay)*t,depth
  end
  if bz<NEAR or bz>FAR then
    local depth = clamp(bz,NEAR,FAR)
    local t = (depth-bz)/(az-bz)
    bx,by,bz = bx+(ax-bx)*t,by+(ay-by)*t,depth
  end
  local sa,sb = FOCAL/az,FOCAL/bz
  screenLine(64+ax*sa,32-ay*sa,64+bx*sb,32-by*sb,pattern,bold)
end

local function structureEdge(ax,ay,az,bx,by,bz)
  edge(ax,ay,az,bx,by,bz,SOLID,not racing)
end

local function worldLine(ax,ay,az,bx,by,bz,pattern,bold)
  ax,ay,az = cameraPoint(ax,ay,az)
  bx,by,bz = cameraPoint(bx,by,bz)
  edge(ax,ay,az,bx,by,bz,pattern,bold)
end

local function basis()
  local xx,yy,zz = qx*qx,qy*qy,qz*qz
  local xy,xz,yz = qx*qy,qx*qz,qy*qz
  local wx,wy,wz = qw*qx,qw*qy,qw*qz
  rX,rY,rZ = 1-2*(yy+zz),2*(xy+wz),2*(xz-wy)
  uX,uY,uZ = 2*(xy-wz),1-2*(xx+zz),2*(yz+wx)
  fX,fY,fZ = 2*(xz+wy),2*(yz-wx),1-2*(xx+yy)
end

local function camera()
  camRightX,camRightY,camRightZ = rX,rY,rZ
  camUpX,camUpY,camUpZ = uX*camCos-fX*camSin,uY*camCos-fY*camSin,uZ*camCos-fZ*camSin
  camFwX,camFwY,camFwZ = fX*camCos+uX*camSin,fY*camCos+uY*camSin,fZ*camCos+uZ*camSin
end

local function drawBox(b)
  -- Cull entire boxes against the camera frustum with a bounding sphere.
  local depthX,depthY,depthZ = cameraPoint(b[7],b[8],b[9])
  local radius = b[10]
  if depthZ+radius<NEAR or depthZ-radius>FAR
    or abs(depthX)>1.26*max(0,depthZ)+1.62*radius
    or abs(depthY)>0.64*max(0,depthZ)+1.20*radius then return end
  local ax,ay,az = cameraPoint(b[1],b[2],b[3])
  local bx,by,bz = cameraPoint(b[4],b[2],b[3])
  local cx,cy,cz = cameraPoint(b[4],b[2],b[6])
  local dx,dy,dz = cameraPoint(b[1],b[2],b[6])
  local tx,ty,tz = (b[5]-b[2])*camRightY,(b[5]-b[2])*camUpY,(b[5]-b[2])*camFwY
  local left,right,front,back = x<b[1],x>b[4],z<b[3],z>b[6]
  local top,bottom = y>b[5],y<b[2]
  if front or bottom then structureEdge(ax,ay,az,bx,by,bz) end
  if right or bottom then structureEdge(bx,by,bz,cx,cy,cz) end
  if back or bottom then structureEdge(cx,cy,cz,dx,dy,dz) end
  if left or bottom then structureEdge(dx,dy,dz,ax,ay,az) end
  if left or front then structureEdge(ax,ay,az,ax+tx,ay+ty,az+tz) end
  if right or front then structureEdge(bx,by,bz,bx+tx,by+ty,bz+tz) end
  if right or back then structureEdge(cx,cy,cz,cx+tx,cy+ty,cz+tz) end
  if left or back then structureEdge(dx,dy,dz,dx+tx,dy+ty,dz+tz) end
  ax,ay,az,bx,by,bz = ax+tx,ay+ty,az+tz,bx+tx,by+ty,bz+tz
  cx,cy,cz,dx,dy,dz = cx+tx,cy+ty,cz+tz,dx+tx,dy+ty,dz+tz
  if front or top then structureEdge(ax,ay,az,bx,by,bz) end
  if right or top then structureEdge(bx,by,bz,cx,cy,cz) end
  if back or top then structureEdge(cx,cy,cz,dx,dy,dz) end
  if left or top then structureEdge(dx,dy,dz,ax,ay,az) end
end

local function drawGate(g, active, number)
  local gx,gy,gz,w,h,nx,nz = g[1],g[2],g[3],g[4],g[5],g[6],g[7]
  local ax,az,bx,bz = gx-w*nz,gz+w*nx,gx+w*nz,gz-w*nx
  local pattern = active and SOLID or DOTTED
  worldLine(ax,gy-h,az,ax,gy+h,az,pattern,active)
  worldLine(bx,gy-h,bz,bx,gy+h,bz,pattern,active)
  worldLine(ax,gy-h,az,bx,gy-h,bz,pattern)
  worldLine(ax,gy+h,az,bx,gy+h,bz,pattern,active)
  if active then
    worldLine(ax,gy+h-0.28,az,bx,gy+h-0.28,bz)
    local cx,cy,cz = cameraPoint(gx,gy+h+0.45,gz)
    if cz>NEAR and cz<FAR then
      local sx,sy = floor(61+FOCAL*cx/cz),floor(25-FOCAL*cy/cz)
      if sx>=0 and sx<115 and sy>=8 and sy<=49 then label(sx,sy,tostring(number),small+inverse) end
    end
    -- Bearing to the gate centre, including targets behind the pilot.
    cx,cy,cz = cameraPoint(gx,gy,gz)
    if cz<NEAR or abs(cx)*FOCAL>59*cz or abs(cy)*FOCAL>19*cz then
      local side = cx>=0 and 1 or -1
      local dx,dy = side,0
      if cz>=NEAR and abs(cy)*59>abs(cx)*19 then dx,dy=0,(cy>0 and -1 or 1) end
      local sx,sy = 64+dx*58,32+dy*18
      drawLine(sx,sy,sx-4*dx+3*dy,sy-4*dy+3*dx)
      drawLine(sx,sy,sx-4*dx-3*dy,sy-4*dy-3*dx)
      if cz<=0 then drawLine(sx-6*dx,sy-2,sx-6*dx,sy+2) end
    elseif cz>FAR then
      rect(floor(62+FOCAL*cx/cz),floor(30-FOCAL*cy/cz),5,5,ink)
    end
  end
end

local function trackEdges(a,b)
  for side=-1,1,2 do
    local wa,wb = (a[4]+1)*side,(b[4]+1)*side
    worldLine(a[1]+a[7]*wa,0,a[3]-a[6]*wa,b[1]+b[7]*wb,0,b[3]-b[6]*wb,DOTTED)
  end
end

local function renderWorld()
  camera()
  local spacing = activeSite and (racing or drill) and 5 or 10
  local gx,gz = floor(x/spacing)*spacing,floor(z/spacing)*spacing
  for offset=-20,20,spacing do
    worldLine(gx+offset,0,gz-20,gx+offset,0,gz+20,DOTTED)
    worldLine(gx-20,0,gz+offset,gx+20,0,gz+offset,DOTTED)
  end
  for i=1,boxCount do drawBox(boxes[i]) end
  if endless then
    trackEdges(runGates[1],runGates[2])
    trackEdges(runGates[2],runGates[3])
    drawGate(runGates[3],false)
    drawGate(runGates[2],false)
    drawGate(runGates[1],true,runScore+1)
  elseif racing or drill then
    local gate = gates[gateIndex]
    if racing then
      local nextGate = gates[gateIndex%#gates+1]
      if not activeSite then
        trackEdges(gates[(gateIndex-2)%#gates+1],gate)
        trackEdges(gate,nextGate)
      end
      drawGate(nextGate,false)
    end
    drawGate(gate,true,gateIndex)
  end
  drawLine(59,32,62,32)
  drawLine(66,32,69,32)
  drawLine(64,34,64,36)
end

local function stick(id)
  local raw = getValue(stickIds[id])
  if type(raw)~="number" then return 0 end
  return clamp(raw/1024,-1,1)
end

local function expo(value)
  if abs(value)<0.02 then return 0 end
  return value*(0.66+0.34*value*value)
end

local function readPB(name,limit)
  local file = io.open(dataDir..name,"r")
  if not file then return 0 end
  local data = io.read(file,16) or ""
  io.close(file)
  if data:sub(1,1)=="P" then data = data:match("^P(%d+%.%d%d)\n$") end
  local value = tonumber(data)
  return value and value>0 and value<limit and value or 0
end

local function loadRecord(record)
  record.limit = record.count and 10000000 or 36000
  local primary = readPB(record.file,record.limit)
  local alternate = readPB(record.file..".bak.dat",record.limit)
  record.best,record.slot = primary,record.file
  if alternate>0 and (primary==0 or (record.count and alternate>primary)
      or (not record.count and alternate<primary)) then
    record.best,record.slot = alternate,record.file..".bak.dat"
  end
  if record.count then record.best=floor(record.best) end
  record.saved = record.best
end

local function saveRecord(record,value)
  value = tonumber(string.format("%.2f",value))
  local improved = value>0 and value<record.limit and (record.best==0
    or (record.count and value>record.best) or (not record.count and value<record.best))
  if improved then record.best=value end
  if record.best==record.saved then return end

  -- Keep the last valid slot intact until the new score survives a read-back.
  local alternate = record.file..".bak.dat"
  local slot = record.slot==record.file and record.saved>0 and alternate or record.file
  local file = io.open(dataDir..slot,"w")
  if file then
    local wrote = io.write(file,"P"..string.format("%.2f",record.best).."\n")
    io.close(file)
    if wrote and readPB(slot,record.limit)==record.best then
      record.saved,record.slot = record.best,slot
      return improved and "saved" or nil
    end
  end
  return "unsaved"
end

local function flushRecords()
  local failed = saveRecord(runRecord,0)=="unsaved"
  for _,course in ipairs(courses) do
    if saveRecord(course,0)=="unsaved" then failed=true end
  end
  return not failed
end

-- A fixed ring holds six seconds of freestyle at five samples per second.
-- Restoring rates and motor spool keeps a resumed flip or dive continuous.
local history, livePose = {},{}
local historyHead, historyCount, flightTick, rewindBack
local HISTORY_SIZE = 31
local function capture(p)
  p[1],p[2],p[3],p[4],p[5],p[6] = x,y,z,vx,vy,vz
  p[7],p[8],p[9],p[10] = qw,qx,qy,qz
  p[11],p[12],p[13],p[14],p[15] = motor,rollRate,pitchRate,yawRate,flightTick
end

local function restore(p)
  x,y,z,vx,vy,vz = p[1],p[2],p[3],p[4],p[5],p[6]
  qw,qx,qy,qz = p[7],p[8],p[9],p[10]
  motor,rollRate,pitchRate,yawRate,flightTick = p[11],p[12],p[13],p[14],p[15]
  basis()
end

local function remember()
  historyHead = historyHead%HISTORY_SIZE+1
  historyCount = min(historyCount+1,HISTORY_SIZE)
  history[historyHead] = history[historyHead] or {}
  capture(history[historyHead])
end

local function rewindIndex()
  return (historyHead-rewindBack-1)%HISTORY_SIZE+1
end

local function openRewind()
  capture(livePose)
  rewindBack = min(5,historyCount-1)
  restore(history[rewindIndex()])
  state = "rewind"
end

local function rewindInput(enter,exit,nextRow,prevRow,now)
  if exit then
    restore(livePose)
    state,row = "pause",2
  elseif enter then
    historyHead,historyCount = rewindIndex(),historyCount-rewindBack
    state,frameTime = "fly",now
  elseif nextRow or prevRow then
    rewindBack = clamp(rewindBack+(prevRow and 1 or -1),0,historyCount-1)
    restore(history[rewindIndex()])
  end
end

local function resetPose()
  vx,vy,vz = 0,0,0
  motor,rollRate,pitchRate,yawRate = 0,0,0,0
  qw,qx,qy,qz = 1,0,0,0
  y = quads[quad].radius
  if racing or drill then
    local g = gates[gateIndex]
    local distance = drill and 7 or gates==ironGates and 16 or 10
    x,z = g[1]-distance*g[6],g[3]-distance*g[7]
    qw = sqrt(max(0,(1+g[7])*0.5))
    qy = (g[6]<0 and -1 or 1)*sqrt(max(0,(1-g[7])*0.5))
    if drill then y,motor = g[2],9.81/quads[quad].thrust end
  else
    x,z = activeSite.x,activeSite.z
  end
  basis()
end

local function prepare(isRace,now,isDrill)
  endless,racing,drill,lap = false,isRace,isDrill,1
  gateIndex = drill and drillGate or 1
  if racing then lapMarks,bestMarks,splitText,splitUntil = {},{},nil,0 end
  lapStart,raceTime,bestLap,resultPB = 0,0,0,nil
  if racing or drill then
    loadSite(gates==ironGates and sites[1] or nil)
  else
    loadSite(sites[selectedSite])
  end
  local angle = quads[quad].cam*math.pi/180
  camCos,camSin = cos(angle),sin(angle)
  resetPose()
  state,frameTime = "ready",now
end

-- nil means no forward crossing, false means the quad missed the opening.
local function throughGate(g,ox,oy,oz,radius)
  local nx,nz = g[6],g[7]
  local before,after = (ox-g[1])*nx+(oz-g[3])*nz,(x-g[1])*nx+(z-g[3])*nz
  if before>=0 or after<0 then return end
  local t = -before/(after-before)
  local crossX,crossY,crossZ = ox+(x-ox)*t,oy+(y-oy)*t,oz+(z-oz)*t
  return abs((crossX-g[1])*nz-(crossZ-g[3])*nx)<=g[4]-radius and abs(crossY-g[2])<=g[5]-radius
end

local function gateCrossing(ox,oy,oz)
  if not throughGate(gates[gateIndex],ox,oy,oz,quads[quad].radius) then return end
  if drill then
    local records = drillBest[selectedCourse]
    local key = (quad-1)*#gates+gateIndex+(assist and #quads*#gates or 0)
    drillRecord = min(records[key] or raceTime,raceTime)
    records[key],state = drillRecord,"drillResult"
    return
  end
  local split = raceTime-lapStart
  lapMarks[gateIndex] = split
  if bestMarks[gateIndex] then
    splitText = string.format("G%d  %+.2fs",gateIndex,split-bestMarks[gateIndex])
  else
    splitText = string.format("G%d  %.2fs",gateIndex,split)
  end
  splitUntil = raceTime+1.4
  gateIndex = gateIndex+1
  if gateIndex<=#gates then return end
  if bestLap==0 or split<bestLap then
    bestLap,bestMarks,lapMarks = split,lapMarks,bestMarks
  end
  lapStart,gateIndex,lap = raceTime,1,lap+1
  if lap>LAPS then
    state = "result"
    resultPB = saveRecord(courses[selectedCourse],raceTime)
  end
end

-- Three recycled gates are sufficient for a run of any length. Keep the
-- generator's integer arithmetic exact on single-precision Lua builds.
local function randomUnit()
  randomState = (randomState*109+1021)%65536
  return randomState/65536
end

local function difficulty(cleared)
  local tier = floor(cleared/5)
  return tier/(tier+6)
end

local function extendRunGate(g,previous,cleared)
  local hard = difficulty(cleared)
  local dx = (2*randomUnit()-1)*(3.4+3.6*hard)
  local dy = (2*randomUnit()-1)*(0.9+2.2*hard)
  g[1] = clamp(previous[1]+dx,-11,11)
  g[2] = clamp(previous[2]+dy,2.9,12)
  g[3] = previous[3]+16-2*hard+randomUnit()*3
  g[4],g[5],g[6],g[7] = 3.9-2*hard,2.2-0.95*hard,0,1
end

local function prepareRun(now)
  endless,racing,drill = true,false,false
  loadSite(nil)
  runScore,runSpeed,resultPB = 0,6,nil
  randomState = ((randomState or 0)+now+4051)%65536
  local first = runGates[1]
  first[1],first[2],first[3],first[4],first[5],first[6],first[7] = 0,3.5,13,3.9,2.2,0,1
  extendRunGate(runGates[2],first,1)
  extendRunGate(runGates[3],runGates[2],2)
  x,y,z,vx,vy,vz = 0,3.5,0,0,0,runSpeed
  qw,qx,qy,qz,camCos,camSin = 1,0,0,0,1,0
  basis()
  state,frameTime = "ready",now
end

local function advanceRun(dt,steer,pitch)
  local ox,oy,oz = x,y,z
  vx,vy,vz = vx+(steer*13-vx)*0.18,vy+(-pitch*8-vy)*0.18,runSpeed
  x,y,z = clamp(x+vx*dt,-15,15),clamp(y+vy*dt,0.4,17),z+vz*dt
  -- Pitch the view into the climb and lean into a carve.
  local p,b = -vy*0.014,-vx*0.021
  local cp,sp,cb,sb = cos(p),sin(p),cos(b),sin(b)
  qw,qx,qy,qz = cp*cb,sp*cb,-sp*sb,cp*sb
  basis()
  local first = runGates[1]
  local passed = throughGate(first,ox,oy,oz,0)
  if passed==nil then return end
  if not passed then
    resultPB = saveRecord(runRecord,runScore)
    state = "runResult"
    return
  end
  runScore = runScore+1
  runSpeed = 6+10*difficulty(runScore)
  runGates[1],runGates[2],runGates[3] = runGates[2],runGates[3],first
  extendRunGate(first,runGates[2],runScore+2)
  -- Rebase by a multiple of the floor grid so it stays visually continuous.
  if z>=200 then
    z = z-200
    for i=1,3 do runGates[i][3] = runGates[i][3]-200 end
  end
end

-- Sweep one axis at a time so contact stops normal motion and preserves sliding.
local function moveAxis(position, velocity, dt, radius, low, high, axis, cross1, p1, cross2, p2)
  if velocity==0 then return position,0 end
  local target = clamp(position+velocity*dt,low,high)
  local blocked = target==low or target==high
  for i=1,boxCount do
    local b = boxes[i]
    if p1>b[cross1]-radius and p1<b[cross1+3]+radius
      and p2>b[cross2]-radius and p2<b[cross2+3]+radius then
      local near,far = b[axis]-radius,b[axis+3]+radius
      if velocity>0 and position<=near and target>=near then
        target,blocked = near,true
      elseif velocity<0 and position>=far and target<=far then
        target,blocked = far,true
      end
    end
  end
  return target,blocked and 0 or velocity
end

local function physics(dt, throttle, roll, pitch, yaw)
  local spec = quads[quad]
  -- First-order motor and rate response at the fixed 50 Hz physics tick.
  motor = motor+(throttle-motor)*(throttle>motor and 0.32 or 0.23)
  local onGround = y<=spec.radius and motor*spec.thrust<=9.81
  if onGround then
    rollRate,pitchRate,yawRate = 0,0,0
    roll,pitch,yaw = 0,0,0
  end
  if assist and not onGround then
    -- Angle mode steers the body up vector towards the commanded tilt.
    -- Downward optical pitch is positive around the right axis.
    roll = clamp((roll*0.63*uY+rY)*5,-spec.rate,spec.rate)
    pitch = clamp((pitch*0.63*uY+fY)*5,-spec.rate,spec.rate)
  else
    roll,pitch = roll*spec.rate,pitch*spec.rate
  end
  if onGround then
    qx,qz = 0,0
    if abs(qw)+abs(qy)<0.001 then qw,qy = 1,0 end
  end
  rollRate = rollRate+(roll-rollRate)*0.40
  pitchRate = pitchRate+(pitch-pitchRate)*0.40
  yawRate = yawRate+(yaw*spec.yaw-yawRate)*0.30
  local a,b,c = pitchRate*dt*0.5,yawRate*dt*0.5,-rollRate*dt*0.5
  local nw = qw-qx*a-qy*b-qz*c
  local nx = qx+qw*a+qy*c-qz*b
  local ny = qy+qw*b+qz*a-qx*c
  local nz = qz+qw*c+qx*b-qy*a
  local norm = 1/sqrt(nw*nw+nx*nx+ny*ny+nz*nz)
  qw,qx,qy,qz = nw*norm,nx*norm,ny*norm,nz*norm
  basis()
  local thrust = motor*spec.thrust
  local drag = spec.drag+0.037*sqrt(vx*vx+vy*vy+vz*vz)
  vx,vy,vz = vx+(uX*thrust-vx*drag)*dt,vy+(uY*thrust-9.81-vy*drag)*dt,vz+(uZ*thrust-vz*drag)*dt
  local ox,oy,oz = x,y,z
  local radius = spec.radius
  x,vx = moveAxis(x,vx,dt,radius,-23,40,1,2,y,3,z)
  z,vz = moveAxis(z,vz,dt,radius,-16,46,3,1,x,2,y)
  y,vy = moveAxis(y,vy,dt,radius,radius,28,2,1,x,3,z)
  if y<=radius then
    vx,vz = vx*0.65,vz*0.65
  end
  if racing or drill then gateCrossing(ox,oy,oz) end
end

local function formatTime(seconds)
  if seconds==0 then return "--.--" end
  return string.format("%.2fs",seconds)
end

local function panel(title, subtitle, detail)
  fill(5,14,118,38,erase)
  rect(5,14,118,38,ink)
  label(10,18,title)
  label(10,31,subtitle,small)
  if detail then label(10,42,detail,small) end
end

local function splash()
  label(29,16,"ParqFpV",DBLSIZE or 0)
  drawLine(8,35,120,35,DOTTED)
  drawLine(16,35,31,39)
  drawLine(31,39,64,44)
  drawLine(64,44,97,39)
  drawLine(97,39,112,35)
  label(42,47,"PRESS ENT",small)
  label(43,57,"by soorya",small)
end

local function menuItem(index, text)
  local top = 9+(index-1)*8
  if row==index then label(3,top,">",small) end
  label(13,top,text,small+(row==index and inverse or 0))
end

local function menu()
  label(2,0,"ParqFpV",small+inverse)
  local unsaved = runRecord.best~=runRecord.saved
  for _,course in ipairs(courses) do
    if course.best~=course.saved then unsaved=true; break end
  end
  if unsaved then label(60,0,"BEST UNSAVED",small+inverse) end
  menuItem(1,"Bando freestyle")
  menuItem(2,"Gate race / 3 laps")
  menuItem(3,"Endless Run")
  menuItem(4,"Gate practice")
  menuItem(5,"Quad: "..quads[quad].name)
  menuItem(6,assist and "Flight: Angle" or "Flight: Acro")
  menuItem(7,"Stick setup")
end

local function courseMenu()
  label(2,0,state=="drills" and "PRACTICE / COURSE" or "RACE / COURSE",small+inverse)
  for i,course in ipairs(courses) do
    menuItem(i,(course.gates==ironGates and "Classic  " or i.."  ")..course.name)
  end
  local course = courses[row]
  label(2,46,course.detail,small)
  label(2,56,#course.gates.." gates   PB "..formatTime(course.best),small)
end

local function settings()
  label(2,0,"STICK SETUP",small+inverse)
  menuItem(1,invertPitch and "Pitch: Reversed" or "Pitch: Normal")
  menuItem(2,reverseThrottle and "Throttle: Reversed" or "Throttle: Normal")
  menuItem(3,useChannels and "Inputs: CH1-4 AETR" or "Inputs: Radio sticks")
  menuItem(4,"Back")
  local throttle = (1+stick(3)) * 50
  if reverseThrottle then throttle=100-throttle end
  label(2,44,string.format("THR %d%%  YAW %d",floor(throttle),floor(stick(1)*100)),small)
  label(2,54,string.format("PITCH %d  ROLL %d",floor(stick(2)*100),floor(stick(4)*100)),small)
end

local function hud(throttle)
  fill(0,0,128,8,erase)
  fill(0,56,128,8,erase)
  if endless then
    label(0,0,"GATES "..runScore,small+inverse)
    label(78,0,"LEVEL "..(1+floor(runScore/5)),small)
    label(0,56,string.format("%.1fm/s",runSpeed),small)
    label(74,56,runRecord.best~=runRecord.saved and "UNSAVED" or "BEST "..runRecord.best,small)
    return
  elseif racing then
    label(0,0,string.format("L%d/%d  G%d/%d",min(lap,LAPS),LAPS,gateIndex,#gates),small)
    label(84,0,formatTime(raceTime),small)
    if splitText and raceTime<splitUntil then label(2,9,splitText,small+inverse) end
  elseif drill then
    label(0,0,"PRACTICE  G"..gateIndex,small)
    label(84,0,formatTime(raceTime),small)
  else
    label(0,0,activeSite.name,small)
    label(88,0,assist and "ANGLE" or "ACRO",small)
  end
  label(0,56,string.format("ALT %dm",floor(y)),small)
  label(46,56,string.format("%dm/s",floor(sqrt(vx*vx+vy*vy+vz*vz))),small)
  label(96,56,string.format("T%d%%",floor(throttle*100)),small)
end

local function init()
  local _,radio = getVersion()
  bindControls(string.find(string.lower(radio or ""),"mt12",1,true)~=nil)
  drillGate,drillBest = 1,{}
  for i,course in ipairs(courses) do
    loadRecord(course)
    drillBest[i] = {}
  end
  loadRecord(runRecord)
  selectCourse(1)
  selectedSite = 1
  state,row,quad,assist = "splash",1,1,useChannels
  invertPitch,reverseThrottle = false,false
  screenStart = getTime()
end

local function freestyle()
  return not (racing or drill or endless)
end

local function readyInput(enter,exit,nextRow,prevRow,throttle,now)
  if exit then
    if drill then state="pick"
    elseif racing then state,row="races",selectedCourse
    else state,row="menu",endless and 3 or 1 end
  elseif freestyle() and (nextRow or prevRow) then
    selectedSite = (selectedSite-1+(nextRow and 1 or -1))%#sites+1
    prepare(false,now)
  elseif enter then
    if drill then
      if abs(throttle-9.81/quads[quad].thrust)>0.05 then return end
    elseif throttle>0.08 then return end
    if racing then state,countStart="count",now
    else
      state,frameTime="fly",now
      if freestyle() then
        historyHead,historyCount,flightTick = 0,0,0
        remember()
      end
    end
  end
end

local function fly(now,throttle)
  local elapsed = floor((now-frameTime)/2)
  if elapsed<1 then return end
  -- Drop excess time after a stall for both the flight and its timer.
  local steps = min(5,elapsed)
  frameTime = now-(now-frameTime)%2
  local roll,pitch,yaw = expo(stick(4)),expo(stick(2)),expo(stick(1))
  if invertPitch then pitch=-pitch end
  for i=1,steps do
    if endless then
      advanceRun(0.02,clamp(roll+yaw,-1,1),pitch)
    else
      if racing or drill then raceTime=raceTime+0.02 end
      physics(0.02,throttle,roll,pitch,yaw)
      if not racing and not drill then
        flightTick = flightTick+1
        if flightTick%10==0 then remember() end
      end
    end
    if state~="fly" then break end
  end
end

local function pauseInput(enter,exit,nextRow,prevRow,now)
  local rows = freestyle() and 4 or 3
  if nextRow then row=row%rows+1 end
  if prevRow then row=(row-2)%rows+1 end
  if exit or (enter and row==1) then state,frameTime="fly",now
  elseif enter then
    if freestyle() and row==2 then openRewind()
    elseif row==rows-1 then
      if endless then
        saveRecord(runRecord,runScore)
        prepareRun(now)
      else prepare(racing,now,drill) end
    else
      if endless then saveRecord(runRecord,runScore) end
      state,row="menu",endless and 3 or drill and 4 or racing and 2 or 1
    end
  end
end

local function drawScreen(throttle,now)
  lcd.clear()
  if state=="splash" then splash()
  elseif state=="menu" then menu()
  elseif state=="setup" then settings()
  elseif state=="exitUnsaved" then
    label(2,0,"BEST NOT SAVED",small+inverse)
    menuItem(1,"Retry save")
    menuItem(2,"Discard and exit")
    label(2,56,"ENT Select  RTN Back",small)
  elseif state=="races" or state=="drills" then courseMenu()
  elseif state=="pick" then
    label(2,1,courses[selectedCourse].name.." / PRACTICE",small+inverse)
    label(4,15,"<  Gate "..drillGate.." / "..#gates.."  >")
    label(4,30,"Start in a level hover",small)
    label(4,40,"7m from the gate",small)
    label(4,55,"ENT Select   RTN Back",small)
  elseif state=="drillResult" then
    label(2,1,"GATE "..gateIndex.." / CLEAR",small+inverse)
    label(4,16,formatTime(raceTime),DBLSIZE or 0)
    label(4,38,"Session best  "..formatTime(drillRecord),small)
    label(4,55,"ENT Retry   RTN Gates",small)
  elseif state=="result" then
    label(3,2,courses[selectedCourse].name.." / RESULTS",small+inverse)
    label(4,14,resultPB=="unsaved" and "BEST NOT SAVED"
      or resultPB=="saved" and "NEW PERSONAL BEST" or "RACE COMPLETE")
    label(4,28,"Total  "..formatTime(raceTime),small)
    label(4,38,"Best lap  "..formatTime(bestLap),small)
    label(4,55,"ENT Retry   RTN Menu",small)
  elseif state=="runResult" then
    label(2,1,"ENDLESS RUN / FINISH",small+inverse)
    label(4,15,runScore.." gates",DBLSIZE or 0)
    label(4,37,"Level "..(1+floor(runScore/5)).."   Best "..runRecord.best,small)
    label(4,46,resultPB=="unsaved" and "Best not saved"
      or resultPB=="saved" and "New personal best" or "Missed gate "..(runScore+1),small)
    label(4,56,"ENT New run   RTN Menu",small)
  elseif state=="rewind" then
    renderWorld()
    label(1,0,"< REWIND >",small+inverse)
    label(88,0,string.format("-%.1fs",(livePose[15]-flightTick)*0.02),small)
    label(1,56,"ENT Fly here   RTN Cancel",small)
  elseif state=="ready" and freestyle() then
    renderWorld()
    label(1,0,"< "..activeSite.name.." >",small+inverse)
    label(102,0,selectedSite.."/"..#sites,small)
    label(1,56,activeSite.line,small)
    if throttle>0.08 then label(76,56,"THR to 0%",small+inverse)
    else label(92,56,"ENT Fly",small+inverse) end
  else
    renderWorld()
    hud(throttle)
    if state=="ready" and endless then
      panel("ENDLESS RUN","Steer L/R  Pull to climb",
        throttle>0.08 and "Lower throttle" or "ENT Run   RTN Back")
    elseif state=="ready" then
      local hint = throttle>0.08 and "Lower throttle" or "ENT Start   RTN Back"
      if drill then
        local hover = 9.81/quads[quad].thrust
        hint = abs(throttle-hover)<=0.05 and "ENT Start   RTN Back"
          or string.format("Set throttle to %d%%",floor(hover*100+0.5))
      end
      panel(drill and ("PRACTICE G"..gateIndex) or courses[selectedCourse].name,
        quads[quad].name.." / "..(assist and "Angle" or "Acro"),
        hint)
    elseif state=="count" then
      panel("START IN "..tostring(max(1,3-floor((now-countStart)/100))),
        "Fly gates in order","Keep throttle low")
    elseif state=="pause" then
      local n = freestyle() and 4 or 3
      fill(22,9,84,46,erase)
      rect(22,9,84,46,ink)
      label(27,11,"PAUSED",small+inverse)
      label(27,21,"Resume",small+(row==1 and inverse or 0))
      if n==4 then label(27,29,"Rewind",small+(row==2 and inverse or 0)) end
      label(27,21+(n-2)*8,"Restart",small+(row==n-1 and inverse or 0))
      label(27,21+(n-1)*8,"Main menu",small+(row==n and inverse or 0))
    end
  end
end

local function run(event)
  if event==nil then return 2 end
  local now = getTime()
  local throttle = (1+stick(3))*0.5
  if reverseThrottle then throttle=1-throttle end
  local enter = event==EVT_VIRTUAL_ENTER or event==EVT_ENTER_BREAK or event==EVT_ROT_BREAK
  local exit = event==EVT_VIRTUAL_EXIT or event==EVT_EXIT_BREAK
  local nextRow = event==EVT_VIRTUAL_NEXT or event==EVT_ROT_RIGHT
  local prevRow = event==EVT_VIRTUAL_PREV or event==EVT_ROT_LEFT

  if state=="splash" then
    if exit then return 1 end
    if enter or now-screenStart>=180 then state="menu" end
  elseif state=="exitUnsaved" then
    if exit then state,row="menu",1
    elseif nextRow or prevRow then row=3-row
    elseif enter and (row==2 or flushRecords()) then return 1 end
  elseif state=="menu" or state=="setup" then
    if exit then
      if state=="menu" then
        if flushRecords() then return 1 end
        state,row = "exitUnsaved",1
      else
        state,row = "menu",7
      end
    else
      local rows = state=="menu" and 7 or 4
      if nextRow then row=row%rows+1 end
      if prevRow then row=(row-2)%rows+1 end
      if enter then
        if state=="setup" then
          if row==1 then invertPitch=not invertPitch
          elseif row==2 then reverseThrottle=not reverseThrottle
          elseif row==3 then bindControls(not useChannels)
          else state,row = "menu",7 end
        elseif row==1 then prepare(false,now)
        elseif row==2 or row==4 then state,row=row==2 and "races" or "drills",selectedCourse
        elseif row==3 then prepareRun(now)
        elseif row==5 then quad=quad%#quads+1
        elseif row==6 then assist=not assist
        else state,row="setup",1 end
      end
    end
  elseif state=="races" or state=="drills" then
    if nextRow then row=row%#courses+1 end
    if prevRow then row=(row-2)%#courses+1 end
    if exit then state,row="menu",state=="races" and 2 or 4
    elseif enter then
      if selectedCourse~=row then drillGate=1 end
      selectCourse(row)
      if state=="drills" then state="pick" else prepare(true,now) end
    end
  elseif state=="pick" then
    if nextRow then drillGate=drillGate%#gates+1 end
    if prevRow then drillGate=(drillGate-2)%#gates+1 end
    if exit then state,row="drills",selectedCourse
    elseif enter then prepare(false,now,true) end
  elseif state=="ready" then
    readyInput(enter,exit,nextRow,prevRow,throttle,now)
  elseif state=="count" then
    if exit then state,row="races",selectedCourse
    elseif throttle>0.08 then state="ready"
    elseif now-countStart>=300 then state,frameTime = "fly",now end
  elseif state=="fly" then
    if exit then state,row = "pause",1
    else fly(now,throttle) end
  elseif state=="pause" then
    pauseInput(enter,exit,nextRow,prevRow,now)
  elseif state=="rewind" then
    rewindInput(enter,exit,nextRow,prevRow,now)
  elseif state=="runResult" then
    if exit then state,row="menu",3 elseif enter then prepareRun(now) end
  elseif state=="drillResult" then
    if exit then state="pick"
    elseif enter then prepare(false,now,true) end
  elseif state=="result" then
    if exit then state,row = "menu",racing and 2 or 1
    elseif enter then prepare(racing,now) end
  end

  drawScreen(throttle,now)
  return 0
end

return {init=init,run=run}
