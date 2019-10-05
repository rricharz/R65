 {
         *****************
         *               *
         *    floppy     *
         *               *
         *****************

    2019 rricharz (r77@bluewin.ch)

Change floppy disk

Written 2019 to test the R65 emulator and
to demonstrate the power of R65 Pascal.

Usage:  floppy name drive

  [drive]: disk drive (0,1), no default
}

program floppy;
uses syslib,arglib;

const afloppy=$d0db; { exdos vector }
mem filerr=$db: integer&;

var cyclus,drive: integer;
    name: array[15] of char;
    default: boolean;

proc bcderror(e:integer);
begin
  write('*** ERROR ');
  write((e shr 4) and 15);
  write(e and 15);
end;

begin
  cyclus:=0; drive:=0;
  agetstring(name,default,cyclus,drive);
  asetfile(name,cyclus,drive,' ');
  call(afloppy);
  if filerr<>0 then bcderror(filerr);
end.   