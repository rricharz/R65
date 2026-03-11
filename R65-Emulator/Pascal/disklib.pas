library disklib;
{ provides functions for the handling of disks

  The directory table has 256 entries of 32 bytes
  The disk name is stored in the last entry (255)
  The last currently used entry has filtyp=TEND
}

const MAXENT   = 255; { max no of entries }

func _freedrv(drive:integer;showit:boolean);
{*****************************************}
{ freedrv: get % of free sectors *** }
const aprepdo  = $f4a7;
      aenddo   = $f625;
      agetentx = $f63a;
      tsectors = 2560;

      INVVID   = chr($0e);
      NORVID   = chr($0b);
      TEND     = chr(0); { end mark }

mem FILDRV=$00dc:integer&;
    filtyp=$0300:char&;
    filloc=$0313:integer;
    scyfc =$037c:integer&;

var s:integer;
    r:real;

begin
  FILDRV:=drive;
  call(aprepdo);
  s:=0;
  repeat
    scyfc:=s; call(agetentx);
    s:=s+1;
    until (filtyp=TEND) or (s>=MAXENT);
  r:=conv(tsectors-filloc);
  s:=trunc(100.0*r/conv(tsectors)+0.5);
  _freedrv := s; { return no of free sectors }
  call(aenddo);
  if showit then begin
    if s<20 then write(INVVID);
    writeln( 'Free space on drive ', drive,
      ': ',s,'%',NORVID);
  end;
end;

begin
end.
