 {
         *****************
         *               *
         *      edit     *
         *               *
         *****************

    2018 rricharz (r77@bluewin.ch)

Edit a text file.

Written 2018 to test the R65 emulator and
to demonstrate the power of Tiny Pascal.

Usage:  edit filnam[:x][.cy[,drive]]

  [:X]:    type of file,     default :P
  [drive]: disk drive (0,1), default 1
}

program edit;
uses syslib,arglib;

const aedit=$c80f; { exdos vector }
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
  cyclus:=0; drive:=1;
  agetstring(name,default,cyclus,drive);
  asetfile(name,cyclus,drive,'P');
  call(aedit);
  if filerr<>0 then bcderror(filerr);
end.