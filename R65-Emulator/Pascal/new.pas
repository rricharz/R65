 {
         *****************
         *               *
         *      new      *
         *               *
         *****************

    2018 rricharz (r77@bluewin.ch)

Create a new empty text file

Written 2018 to test the R65 emulator and
to demonstrate the power of Tiny Pascal.

Usage:  new filnam[:x][.cy[,drive]]

  [:X]:    type of file,     default :P
  [drive]: disk drive (0,1), default 1
}

program new;
uses syslib,arglib;

const anew=$c812; { exdos vector }
      cup=chr($1a);

mem filerr=$db: integer&;

var cyclus,drive: integer;
    name: array[15] of char;
    default: boolean;

proc bcderror(e:integer);
begin
  write(invvid,'ERROR ');
  write((e shr 4) and 15);
  writeln(e and 15,norvid);
end;

func haswildcard(nm1:array[15] of char): boolean;
var k:integer;
begin
  haswildcard:=false;
  for k:=0 to 15 do
    if (nm1[k]='*') or (nm1[k]='?') then
      haswildcard:=true;
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

begin
  cyclus:=0; drive:=1;
  agetstring(name,default,cyclus,drive);
  if haswildcard(name) then
    writeln(invvid,'Wild cards not allowed',norvid)
  else begin
    setsubtype('P');
    asetfile(name,cyclus,drive,' ');
    write(cup); { avoid empty line }
    call(anew);
    if filerr<>0 then bcderror(filerr);
    writeln;
  end;
end.
