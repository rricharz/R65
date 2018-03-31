 {
         *****************
         *               *
         *    delete     *
         *               *
         *****************

    2018 rricharz (r77@bluewin.ch)

Delete a file.

Written 2018 to test the R65 emulator and
to demonstrate the power of Tiny Pascal.

Usage:  delete filnam[:x][.cy[,drive]]

  [:X]:    type of file,     default :P
  [drive]: disk drive (0,1), default 1
}

program delete;
uses syslib,arglib;

const adelete=$c80c; { exdos vector }
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
  asetfile(name,cyclus,drive,' ');
  call(adelete);
  if filerr<>0 then bcderror(filerr);
end. 