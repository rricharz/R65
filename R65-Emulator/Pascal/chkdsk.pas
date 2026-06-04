{  ***************************************         }
{  * chkdsk: check and fix a floppy disk *         }
{  ***************************************         }

{  usage: chkdsk [d]      check drive d            }
{         chkdsk [d] /F   check and fix drive d    }

{         Default for d is disk 1                  }

{  2024   rricharz                                 }

{  The directory table has 256 entries of 32 bytes }
{  The disk name is stored in the last entry (255) }
{  The last currently used entry has filtyp=TEND.  }

{$U+}

program chkdsk;
uses syslib,arglib,filelib;

const aprepdo  = $f4a7;
      aenddo   = $f625;
      agetentx = $f63a;
      MAXENT   = 255;    {number of entries in table}
      TSECTORS = 2560;   {number of sectors on disk }
      TEND     = chr(0); {end mark last used entry  }

mem
      filtyp   = $0300:char&;
      filloc   = $0313:integer;
      filsiz   = $0315:integer;
      fillnk   = $031e:integer;
      scyfc    = $037c:integer&;

var entry, sector,drive: integer;
    done,default,notok: boolean;

proc checkfilerr;
{***************}
begin
  if FILERR<>0 then begin
    call(aenddo);
    writeln(INVVID,'Cannot read directory',NORVID);
    _abort;
  end;
end;

func hex(d:integer):char;
{***********************}
{ convert hex digit to hex char }
begin
  if (d>=0) and (d<10) then
    hex:=chr(d+ord('0'))
  else if (d>=10) and (d<16) then
    hex:=chr(d+ord('A')-10)
  else hex:='?';
end;

proc getdrive;
{************}
var i:integer;
{ get drive number, default drive 1 }
begin
  drive:=1; {default drive}
  FILERR:=0;
  if ARGTYPE[_carg]='i' then _agetval(drive,default);
  if (drive<0) or (drive>1) then begin
    writeln(INVVID,'Drive must be 0 or 1',NORVID);
    _abort
  end;
  FILDRV:=drive;
  write('Checking drive ',drive,': ');
  call(aprepdo);
  checkfilerr;
  scyfc:=255; { disk name }
  call(agetentx);
  checkfilerr;
  for i:=0 to 15 do
    write(FILNAM[i]);
  writeln;
end;

proc check;
{*********}
{ check one entry }
var i:integer;
    ok:boolean;
begin
  write(entry+1:3,' ');
  if (fillnk and 255) >= 128 then
    write('DELETED SPACE       ')
  else begin
    for i:=0 to 15 do
      write(FILNAM[i]);
    write('.',hex(FILCYC shr 4),
      hex(FILCYC and 15),' ');
  end;
  ok:=(sector=filloc);
  write(sector:3,'-',
    sector+((filsiz+1) shr 8):3,'   ');
  sector:=sector+((filsiz+1) shr 8);
  if sector>TSECTORS then begin
    writeln(INVVID,'END OF DISK SPACE',NORVID);
    notok:=true;
  end else if (ok) then writeln('OK')
  else begin
    writeln(INVVID,'SECTOR START',NORVID);
    notok:=true;
  end;
end;

begin {main}
{***3******}
  done:=false;
  sector:=0;
  entry:=0;
  getdrive;

  notok:=false;
  scyfc:=entry;
  call(agetentx);
  checkfilerr;
  repeat
    check;
    entry:=entry+1;
    scyfc:=entry;
    call(agetentx);
    checkfilerr;
    until (filtyp=TEND) or (entry>=MAXENT);
  writeln('Last sector used ', sector,' of ',TSECTORS)
;
  writeln('Last entry used ', entry,' of ',MAXENT);
  if (entry >= MAXENT) then
    writeln(INVVID,'FILE TABLE ON DISK FULL',NORVID);
  if notok then
    writeln(INVVID,'INCONSISTENCY FOUND',NORVID);
  call(aenddo);
end.