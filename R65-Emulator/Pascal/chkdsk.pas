{ ***************************************
  * chkdsk: check and fix a floppy disk *
  ***************************************

  usage: chkdsk [d]      check drive d
         chkdsk [d] /f   check and fix drive d

         Default for d is disk 1

  2024   rricharz                        }

program chkdsk;
uses syslib,arglib;

const aprepdo  = $f4a7;
      aenddo   = $f625;
      agetentx = $f63a;
      maxent   = 255;
      tsectors = 2560;

mem   filerr   = $00db:integer&;
      filtyp   = $0300:char&;
      filcyc   = $0311:integer&;
      filloc   = $0313:integer;
      filsiz   = $0315:integer;
      fillnk   = $031e:integer;
      scyfc    = $037c:integer&;

var entry, sector,drive: integer;
    done,fixit,default,notok: boolean;

{$I IOPTION:P}

proc checkfilerr;
begin
  if filerr<>0 then begin
    call(aenddo);
    writeln('Cannot read directory');
    abort;
  end;
end;

func hex(d:integer):char;
{ convert hex digit to hex char }
begin
  if (d>=0) and (d<10) then
    hex:=chr(d+ord('0'))
  else if (d>=10) and (d<16) then
    hex:=chr(d+ord('A')-10)
  else hex:='?';
end;

proc getdrive;
var i:integer;
{ get drive number, default drive 1 }
begin
  drive:=1; {default drive}
  filerr:=0;
  if argtype[carg]='i' then agetval(drive,default);
  if (drive<0) or (drive>1) then begin
    writeln('Drive must be 0 or 1');
    abort
  end;
  fildrv:=drive;
  write('Checking drive ',drive,': ');
  call(aprepdo);
  checkfilerr;
  scyfc:=255; { disk name }
  call(agetentx);
  checkfilerr;
  for i:=0 to 15 do
    write(filnam[i]);
  writeln;
end;

proc check;
{ check one entry }
var i:integer;
    ok:boolean;
begin
  write(entry+1,' ');
  if (fillnk and 255) >= 128 then
    write('DELETED SPACE       ')
  else begin
    for i:=0 to 15 do
      write(filnam[i]);
    write('.',hex(filcyc shr 4),
      hex(filcyc and 15),' ');
  end;
  ok:=(sector=filloc);
  sector:=sector+(filsiz shr 8);
  if sector>tsectors then begin
    writeln(invvid,'FILE SIZE TOO LONG',norvid);
    notok:=true;
  end else if (ok) then writeln('OK')
  else begin
    writeln(invvid,'SECTOR START INCONSISTENT',norvid);
    notok:=true;
  end;
end;

begin
  done:=false;
  sector:=0;
  entry:=0;
  getdrive;
  if option('H') then begin
    writeln('/F    fix errors');
    call(aenddo);
    exit;
  end;
  fixit:=option('F');
  if fixit then begin
    writeln('Fix errors not yet implemented');
    call(aenddo);
    exit;
  end;
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
    until (filtyp=chr(0)) or (entry>maxent);
  if notok then
    writeln(invvid,'INCONSISTENCY FOUND',norvid);
  call(aenddo);
end.