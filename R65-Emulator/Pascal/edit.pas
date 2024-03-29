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
uses syslib,arglib,disklib;

const aedit=$c80f; { exdos vector }
      cup = chr($1a);
mem filerr=$db: integer&;

var cyclus,drive,free: integer;
    name: array[15] of char;
    default: boolean;

proc bcderror(e:integer);
begin
  writeln;
  write(invvid,'ERROR ');
  write((e shr 4) and 15);
  write(e and 15,norvid);
end;

proc delay10msec(time:integer);
{*****************************}
{ delay10msec: delay 10 msec }
{ process is suspended during delay }
mem emucom=$1430: integer&;
var i:integer;
begin
  for i:=1 to time do
    emucom:=6;
end;

proc setsubtype(subtype:char);
{ only set subtype if not already there }
var i:integer;
begin
  i:=0;
  repeat
    i:=i+1;
  until (name[i]=':') or
    (name[i]=' ') or (i>=14);
  if name[i]<>':' then begin
    name[i]:=':';
    name[i+1]:=subtype;
  end;
end;

begin { main }
  cyclus:=0; drive:=1;
  agetstring(name,default,cyclus,drive);
  setsubtype('P');
  asetfile(name,cyclus,drive,' ');
  delay10msec(3); { allow R65 display to updatee }
  write(cup);
  call(aedit);
  if filerr<>0 then bcderror(filerr);
  writeln;
  free:=freedsk(fildrv,true);
end.