library disklib;
{ provides functions for the handling of disks }

{ *** dskname: get name of disk **** }

proc dskname;
{ name is in filnam }
const aprepdo  = $f4a7;
      aenddo   = $f625;
      agetentx = $f63a;
      maxent   = 255;
mem   scyfc    = $037c:integer&;
      

begin
  call(aprepdo);
  scyfc:=maxent; { disk name }
  call(agetentx);
  call(aenddo);
end;

{ *** freesec: get % of free sectors *** }

func freedsk(drive:integer;showit:boolean);

const aprepdo  = $f4a7;
      aenddo   = $f625;
      agetentx = $f63a;
      tsectors = 2560;
      maxent   = 255;
      invvid   = chr($0e);
      norvid   = chr($0b);

mem fildrv=$00dc:integer&;
    filtyp=$0300:char&;
    filloc=$0313:integer;
    scyfc =$037c:integer&;
    filnam   = $0301: array[15] of char&;

var s,i:integer;
    r:real;
begin
  fildrv:=drive;
  call(aprepdo);
  s:=0;
  repeat
    scyfc:=s; call(agetentx);
    s:=s+1;
    until (filtyp=chr(0)) or (s>=maxent);
  r:=conv(tsectors-filloc);
  s:=trunc(100.0*r/conv(tsectors)+0.5);
  freedsk:=s;
  call(aenddo);
  dskname;
  if showit then begin
    if s<20 then write(invvid);
    write( 'Free space on drive ');
    i:=0;
    while (filnam[i]<>' ') and (i<15) do begin
      write(filnam[i]);
      i:=i+1;
    end;
    writeln(': ',s,'%',norvid);
  end;
end;

begin
end.



