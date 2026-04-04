
{         *****************             }
{         *               *             }
{         *      edit     *             }
{         *               *             }
{         *****************             }

{    2018 rricharz (r77@bluewin.ch)     }

{ Edit a text file.                     }

{ Usage:  edit FILNAM[:x][.cy[,drive]]  }

program edit;
uses syslib, arglib, filelib;

const aedit=$c80f; { exdos vector }
      cup = chr($1a);
mem filerr=$db: integer&;

var cyclus,drive,free: integer;
    name: array[15] of char;
    default: boolean;

proc bcderror(e:integer);
begin
  writeln;
  write(INVVID,'ERROR ');
  write((e shr 4) and 15);
  write(e and 15,NORVID);
end;

proc _delay10msec(time:integer);
{*****************************}
{ _delay10msec: _delay 10 msec }
{ process is suspended during _delay }
mem emucom=$1430: integer&;
var i:integer;
begin
  for i:=1 to time do
    emucom:=6;
end;

proc setsubtype(subtype:char);
{ only set subtype if not already there }
mem filstp=$312:char&;
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
    filstp:=subtype;
  end
  else
    filstp:=name[i+1];
end;

begin { main }
  cyclus:=0; drive:=1;
  _agetstring(name,default,cyclus,drive);
  setsubtype('P');
  _asetfile(name,cyclus,drive,' ');
  _delay10msec(3); { allow R65 display to updatee }
  write(cup);
  call(aedit);
  if filerr<>0 then bcderror(filerr);
  writeln;
  free:=_freedrv(FILDRV,true);
end.
