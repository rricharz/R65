
{         *****************               }
{         *               *               }
{         *     IMPORT    *               }
{         *               *               }
{         *****************               }

{    2026 rricharz (r77@bluewin.ch)       }

{ Import a text file.                     }
{ 3/2026 rricharz direct call to emulator }

{ Usage: import FILNAM[:x][.cy[,drive]]   }

program import;
uses syslib, arglib, filelib;

const
    ECIMPORT = 2;

mem filerr = $db: integer&;

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
  filerr := _emulator(ECIMPORT);
  if filerr<>0 then bcderror(filerr);
  _write_label;
  writeln('+')
  free:=_freedrv(FILDRV,true);
end.
 