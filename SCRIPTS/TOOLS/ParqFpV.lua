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
local gates = {
  {0, 2.2, 9, 3.1, 1.7, 0, 1},
  {0, 2.5, 21, 3.2, 1.9, 0, 1},
  {9, 5.0, 29, 4.0, 2.4, 1, 0},
  {21, 6.4, 29, 4.2, 2.8, 1, 0},
  {25, 3.7, 16, 4.4, 2.8, 0, -1},
  {22, 2.8, 1, 3.3, 2.1, 0, -1},
  {12, 2.5, -5, 3.6, 1.9, -1, 0},
  {0, 2.2, -3, 3.0, 1.7, 0, 1},
}
local boxes = {}
local function box(x1,y1,z1,x2,y2,z2)
  boxes[#boxes+1] = {x1,y1,z1,x2,y2,z2}
end
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

local state, row, quad, assist, invertPitch, reverseThrottle
local racing, gateIndex, lap, lapStart, raceTime, bestLap, resultPB, savedPB
local screenStart, frameTime, countStart
local drill, drillGate, drillBest, drillRecord
local motor, rollRate, pitchRate, yawRate
local lapMarks, bestMarks, splitText, splitUntil
local x,y,z, vx,vy,vz, qw,qx,qy,qz
local spawnX, spawnZ
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
local pbFile = "/SCRIPTS/TOOLS/ParqPB.dat"

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

local function worldLine(ax,ay,az,bx,by,bz,pattern)
  ax,ay,az = cameraPoint(ax,ay,az)
  bx,by,bz = cameraPoint(bx,by,bz)
  edge(ax,ay,az,bx,by,bz,pattern)
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

local function drawGate(g, active)
  local gx,gy,gz,w,h,nx,nz = g[1],g[2],g[3],g[4],g[5],g[6],g[7]
  local ax,az,bx,bz = gx-w*nz,gz+w*nx,gx+w*nz,gz-w*nx
  local pattern = active and SOLID or DOTTED
  worldLine(ax,gy-h,az,ax,gy+h,az,pattern)
  worldLine(bx,gy-h,bz,bx,gy+h,bz,pattern)
  worldLine(ax,gy-h,az,bx,gy-h,bz,pattern)
  worldLine(ax,gy+h,az,bx,gy+h,bz,pattern)
  if active then
    worldLine(ax,gy+h-0.28,az,bx,gy+h-0.28,bz)
    local cx,cy,cz = cameraPoint(gx,gy+h+0.45,gz)
    if cz>NEAR and cz<FAR then
      local sx,sy = floor(61+FOCAL*cx/cz),floor(25-FOCAL*cy/cz)
      if sx>=0 and sx<121 and sy>=8 and sy<55 then label(sx,sy,tostring(gateIndex),small+inverse) end
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
    end
  end
end

local function renderWorld()
  camera()
  local spacing = (racing or drill) and 5 or 10
  local gx,gz = floor(x/spacing)*spacing,floor(z/spacing)*spacing
  for offset=-20,20,spacing do
    worldLine(gx+offset,0,gz-20,gx+offset,0,gz+20,DOTTED)
    worldLine(gx-20,0,gz+offset,gx+20,0,gz+offset,DOTTED)
  end
  for i=1,#boxes do drawBox(boxes[i]) end
  if racing then
    local nextGate = gateIndex % #gates + 1
    drawGate(gates[nextGate],false)
  end
  if racing or drill then drawGate(gates[gateIndex],true) end
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

local function readPB()
  local file = io.open(pbFile,"r")
  if not file then return 0 end
  local value = tonumber(io.read(file,16))
  io.close(file)
  return value and value>0 and value<36000 and value or 0
end

local function writePB(value)
  local file = io.open(pbFile,"w")
  if not file then return end
  io.write(file,string.format("%.2f",value))
  io.close(file)
end

local function resetPose()
  x,y,z = spawnX,quads[quad].radius,spawnZ
  vx,vy,vz = 0,0,0
  motor,rollRate,pitchRate,yawRate = 0,0,0,0
  qw,qx,qy,qz = 1,0,0,0
  if drill then
    local g = gates[gateIndex]
    x,y,z = g[1]-7*g[6],g[2],g[3]-7*g[7]
    local heading = g[7]==-1 and math.pi or g[6]*math.pi/2
    qw,qy = cos(heading/2),sin(heading/2)
    motor = 9.81/quads[quad].thrust
  end
  basis()
end

local function prepare(isRace,now,isDrill)
  racing,drill,lap = isRace,isDrill,1
  gateIndex = drill and drillGate or 1
  lapMarks,bestMarks,splitText,splitUntil = {},{},nil,0
  lapStart,raceTime,bestLap,resultPB = 0,0,0,false
  spawnX,spawnZ = 0,(racing and -7 or 2)
  local angle = quads[quad].cam*math.pi/180
  camCos,camSin = cos(angle),sin(angle)
  resetPose()
  state,frameTime = "ready",now
end

local function gateCrossing(ox,oy,oz)
  local g = gates[gateIndex]
  local nx,nz = g[6],g[7]
  local before,after = (ox-g[1])*nx+(oz-g[3])*nz,(x-g[1])*nx+(z-g[3])*nz
  if before>=0 or after<0 then return end
  local t = -before/(after-before)
  local crossX,crossY,crossZ = ox+(x-ox)*t,oy+(y-oy)*t,oz+(z-oz)*t
  if abs((crossX-g[1])*nz-(crossZ-g[3])*nx)>g[4] or abs(crossY-g[2])>g[5] then return end
  if drill then
    local key = (quad-1)*#gates+gateIndex+(assist and #quads*#gates or 0)
    drillRecord = min(drillBest[key] or raceTime,raceTime)
    drillBest[key],state = drillRecord,"drillResult"
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
    if savedPB==0 or raceTime<savedPB then
      savedPB,resultPB = raceTime,true
      writePB(raceTime)
    end
  end
end

-- Sweep one axis at a time so contact stops normal motion and preserves sliding.
local function moveAxis(position, velocity, dt, radius, low, high, axis, cross1, p1, cross2, p2)
  if velocity==0 then return position,0 end
  local target = clamp(position+velocity*dt,low,high)
  local blocked = target==low or target==high
  for i=1,#boxes do
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
  label(19,49,"IRONWORKS / FPV SIM",small)
  label(42,57,"PRESS ENT",small)
end

local function menuItem(index, text)
  local top = 10+(index-1)*8
  if row==index then label(3,top,">",small) end
  label(13,top,text,small+(row==index and inverse or 0))
end

local function menu()
  label(2,0,"ParqFpV / IRONWORKS",small+inverse)
  menuItem(1,"Bando freestyle")
  menuItem(2,"Gate race / 3 laps")
  menuItem(3,"Quad: "..quads[quad].name)
  menuItem(4,assist and "Flight: Angle" or "Flight: Acro")
  menuItem(5,"Stick setup")
  menuItem(6,"Gate practice")
  label(2,57,"Race PB "..formatTime(savedPB),small)
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
  if racing then
    label(0,0,string.format("L%d/%d  G%d/%d",min(lap,LAPS),LAPS,gateIndex,#gates),small)
    label(84,0,formatTime(raceTime),small)
    if splitText and raceTime<splitUntil then label(2,9,splitText,small+inverse) end
  elseif drill then
    label(0,0,"PRACTICE  G"..gateIndex,small)
    label(84,0,formatTime(raceTime),small)
  else
    label(0,0,"IRONWORKS",small)
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
  for i=1,#boxes do
    local b = boxes[i]
    local hx,hy,hz = (b[4]-b[1])*0.5,(b[5]-b[2])*0.5,(b[6]-b[3])*0.5
    b[7],b[8],b[9],b[10] = b[1]+hx,b[2]+hy,b[3]+hz,sqrt(hx*hx+hy*hy+hz*hz)
  end
  state,row,quad,assist = "splash",1,1,useChannels
  invertPitch,reverseThrottle = false,false
  screenStart,savedPB = getTime(),readPB()
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
  elseif state=="menu" or state=="setup" then
    if exit then
      if state=="menu" then return 1 end
      state,row = "menu",5
    else
      local rows = state=="menu" and 6 or 4
      if nextRow then row=row%rows+1 end
      if prevRow then row=(row-2)%rows+1 end
      if enter then
        if state=="setup" then
          if row==1 then invertPitch=not invertPitch
          elseif row==2 then reverseThrottle=not reverseThrottle
          elseif row==3 then bindControls(not useChannels)
          else state,row = "menu",5 end
        elseif row<=2 then prepare(row==2,now)
        elseif row==3 then quad=quad%#quads+1
        elseif row==4 then assist=not assist
        elseif row==5 then state,row = "setup",1
        else state = "pick" end
      end
    end
  elseif state=="pick" then
    if nextRow then drillGate=drillGate%#gates+1 end
    if prevRow then drillGate=(drillGate-2)%#gates+1 end
    if exit then state,row="menu",6
    elseif enter then prepare(false,now,true) end
  elseif state=="ready" then
    local armed = drill and abs(throttle-9.81/quads[quad].thrust)<=0.05
    if exit then state=drill and "pick" or "menu"
    elseif enter and (armed or (not drill and throttle<=0.08)) then
      if racing then state,countStart = "count",now
      else state,frameTime = "fly",now end
    end
  elseif state=="count" then
    if exit then state="menu"
    elseif throttle>0.08 then state="ready"
    elseif now-countStart>=300 then state,frameTime = "fly",now end
  elseif state=="fly" then
    if exit then state,row = "pause",1
    elseif now-frameTime>=2 then
      local elapsed = floor((now-frameTime)/2)
      local steps = min(5,elapsed)
      local stepTime = elapsed*0.02/steps
      frameTime = now-(now-frameTime)%2
      local roll,pitch,yaw = expo(stick(4)),expo(stick(2)),expo(stick(1))
      if invertPitch then pitch=-pitch end
      for i=1,steps do
        if racing or drill then raceTime=raceTime+stepTime end
        physics(0.02,throttle,roll,pitch,yaw)
        if state~="fly" then break end
      end
    end
  elseif state=="pause" then
    if nextRow then row=row%3+1 end
    if prevRow then row=(row-2)%3+1 end
    if exit or (enter and row==1) then state,frameTime = "fly",now
    elseif enter and row==2 then prepare(racing,now,drill)
    elseif enter and row==3 then state,row = "menu",drill and 6 or racing and 2 or 1 end
  elseif state=="drillResult" then
    if exit then state="pick"
    elseif enter then prepare(false,now,true) end
  elseif state=="result" then
    if exit then state,row = "menu",racing and 2 or 1
    elseif enter then prepare(racing,now) end
  end

  lcd.clear()
  if state=="splash" then splash()
  elseif state=="menu" then menu()
  elseif state=="setup" then settings()
  elseif state=="pick" then
    label(2,1,"GATE PRACTICE",small+inverse)
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
    label(3,2,"IRONWORKS / RESULTS",small+inverse)
    label(4,14,resultPB and "NEW PERSONAL BEST" or "RACE COMPLETE")
    label(4,28,"Total  "..formatTime(raceTime),small)
    label(4,38,"Best lap  "..formatTime(bestLap),small)
    label(4,55,"ENT Retry   RTN Menu",small)
  else
    renderWorld()
    hud(throttle)
    if state=="ready" then
      local hint = throttle>0.08 and "Lower throttle" or "ENT Start   RTN Back"
      if drill then
        local hover = 9.81/quads[quad].thrust
        hint = abs(throttle-hover)<=0.05 and "ENT Start   RTN Back"
          or string.format("Set throttle to %d%%",floor(hover*100+0.5))
      end
      panel(drill and ("PRACTICE G"..gateIndex) or racing and "GATE RACE" or "BANDO FREESTYLE",
        quads[quad].name.." / "..(assist and "Angle" or "Acro"),
        hint)
    elseif state=="count" then
      panel("START IN "..tostring(max(1,3-floor((now-countStart)/100))),
        "Fly gates in order","Keep throttle low")
    elseif state=="pause" then
      fill(22,12,84,40,erase)
      rect(22,12,84,40,ink)
      label(27,14,"PAUSED",small+inverse)
      label(27,23,"Resume",small+(row==1 and inverse or 0))
      label(27,32,"Restart",small+(row==2 and inverse or 0))
      label(27,41,"Main menu",small+(row==3 and inverse or 0))
    end
  end
  return 0
end

return {init=init,run=run}
