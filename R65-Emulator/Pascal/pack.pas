 {
         *****************
         *               *
         *     pack      *
         *               *
         *****************

    2018 rricharz (r77@bluewin.ch)

Pack a floppy disk

Written 2018 to test the R65 emulator and
to demonstrate the power of Tiny Pascal.

Usage:  pack [drive]

  [drive]: disk drive (0,1), default 1
}

program pack;
uses syslib,arglib,disklib;

const apack=$c809; { exdos vector }
mem filerr=$db: integer&;

var drive,dummy: integer;
    default: boolean;

proc bcderror(e:integer);
begin
  write(invvid,'ERROR ');
  write((e shr 4) and 15);
  write(e and 15,norvid);
end;

begin
  drive:=1; {default drive}
  agetval(drive,default);
  if (drive<0) or (drive>1) then begin
    writeln('Drive must be 0 or 1');
    abort
  end;
  writeln('Packing drive ',drive);
  fildrv:=drive;
  call(apack);
  if filerr<>0 then bcderror(filerr);
  if curpos>1 then writeln;
  dummy:=freedsk(drive,true);
end.
