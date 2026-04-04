library filelib;
{ provides functions for the handling of disks

  The directory table has 256 entries of 32 bytes
  The disk name is stored in the last entry (255)
  The last currently used entry has filtyp=TEND
}

const
  FILFLG = $00da: integer&;
  FILDRV = $00dc: integer&;
  FILNUM = $0301: array[15] of char&;
  FILNM1 = $0320: array[15] of char&;
  FILCYC = $0311: integer&;
  FILCY1 = $0330: integer&;
  MAXSEQ = $0336: integer&;
  FIDRTP = $0339: array[MMAXSEQ] of integer&;

func _freedrv(drive:integer; printit:boolean);
{ get and print % of free sectors }
const 
    aprepdo  = $f4a7;
    aenddo   = $f625;
    agetentx = $f63a;
    DSECTORS = 2560;
    INVVID   = chr($0e);
    NORVID   = chr($0b);
    DEND     = chr(0); { directory end mark }
    MAXENT   = 255; { max no of entries }

mem                    
    filloc=$0313:integer;
    scyfc =$037c:integer&;

var 
    s:integer;
    r:real;

begin
  FILDRV:=drive;
  call(aprepdo);
  s:=0;
  repeat
    scyfc:=s; call(agetentx);
    s:=s+1;
  until (filtyp=DEND) or (s>=MAXENT);
  r:=conv(tsectors-filloc);
  s:=trunc(100.0*r/conv(DSECTORS)+0.5);
  _freedrv := s; { return no of free sectors }
  call(aenddo);
  if printit then begin
    if s<20 then write(INVVID);
    writeln( 'Free space on drive ', drive,
      ': ',s,'%',NORVID);
  end;
end;

begin
end.
