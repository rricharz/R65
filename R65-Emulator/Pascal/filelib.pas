
{ *************************************** }
{ *         FILELIB - LIBRARY           * }
{ *************************************** }


{ Provides functions for the handling of  }
{ files and disk directories.             }

{ The directory table has 256 entries of  }
{ 32 bytes. The disk name is stored in    }
{ the last entry (255). The last          }
{ used entry has filtyp=DEND              }

{$U+}

library filelib;

mem
    FILFLG = $00da: integer&;
    FILDRV = $00dc: integer&;
    FILTYP = $0300:char&;
    FILNAM = $0301: array[15] of char&;
    FILCYC = $0311: integer&;
    FILSTP = $0312: char&;
    FILNM1 = $0320: array[15] of char&;
    FILCY1 = $0330: integer&;

func _uppercase(ch1: char): char;
{*******************************}
{ returns uppercase of char }
begin
  if (ch1 >= 'a') and (ch1 <= 'z') then
    _uppercase := chr(ord(ch1) - 32)
  else
    _uppercase := ch1;
end;

proc _asetfile(name: array[15] of char;
      cyclus,device: integer; subtype: char);
{*******************************************}
{ prepare for disk io }
var i,e: integer;
begin
  e:=0;
  for i:=0 to 15 do begin
    FILNAM[i]:=_uppercase(name[i]);
    FILNM1[i]:=_uppercase(name[i]);
    if (e=0) and ((name[i]=':')
        or (name[i]=' ')) then
      e:=i;
  end;
  if (subtype<>' ') and (e<>0)
      and (e<15) then begin
    FILSTP :=subtype;
    FILNAM[e]:=':'; FILNM1[e]:=':';
    FILNAM[e+1]:=subtype; FILNM1[e+1]:=subtype
  end;
  FILCYC:=cyclus; FILCY1:=cyclus;
  FILDRV:=device;
  FILFLG:=$40; { Do not show file entry }
end;

func _bestmatch: boolean;
{***********************}
{find the best (highers cyclus) entry in directory}
const
  preprd = $f62c;
  prflab = $ece3;
  CUP = chr($1a);
  mem filerr = $00db: integer&;
begin
  filerr := 0;
  call(preprd); { find entry with system subroutine }
  if (filerr = 0) then begin
    write(CUP);   { get rid of empty line }
    call(prflab); { print info with system subroutine}
  end;
  _bestmatch := (filerr = 0);
end;

func _freedrv(drive:integer; printit:boolean);
{********************************************}
{ gets and prints % of free sectors }
const
  aprepdo  = $f4a7;
  aenddo   = $f625;
  agetentx = $f63a;
  DSECTORS = 2560;
  INVVID   = chr($0e);
  NORVID   = chr($0b);
  DEND     = chr(0); { directory end mark }
  MMAXSEQ  = 8;      {max no of seq. files}
  MAXENT   = 255;    { max no of entries }

mem
  MAXSEQ   = $0336: integer&;
  _fidrtp  = $0339: array[MMAXSEQ] of integer&;
  filloc   = $0313:integer;
  scyfc    = $037c:integer&;

var
  s:integer;
  r:real;

begin
  FILDRV:=drive;
  call(aprepdo);
  s := 0;
  repeat
    scyfc := s;
    call(agetentx);
    s := s+1;
  until (FILTYP = DEND) or (s >= MAXENT);
  r := conv(DSECTORS  -filloc);
  s := trunc(100.0*r/conv(DSECTORS)+0.5);
  _freedrv := s; { return no of free sectors }
  call(aenddo);
  if printit then begin
    if s < 20 then write(INVVID);
    writeln( 'Free space on drive ', drive,
      ': ',s,'%',NORVID);
  end;
end;

proc _write_label;
{****************}
{ print label without leading and trailing linefeed }
const prflab   = $ece3;
begin
  call(prflab);
end;

begin
end.
