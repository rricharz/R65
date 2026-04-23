
{         *****************               }
{         *               *               }
{         *     EXPORT    *               }
{         *               *               }
{         *****************               }

{    2026 rricharz (r77@bluewin.ch)       }

{ Export a text file.                     }
{ 3/2026 rricharz direct call to emulator }

{ Usage: export FILNAM[:x][.cy[,drive]]   }

{$U+}

program export;
uses syslib, arglib, filelib;

const
    cup = chr($1a);
    ECEXPORT = 1;

mem filerr=$db: integer&;
    emucom=$1430: integer&;
    emures=$1431: integer&;

var cyclus,drive,free: integer;
    name: array[15] of char;
    default,silentflag: boolean;

{$I ISILENT:P}

proc bcderror(e:integer);
{**********************}
begin
  writeln;
  write(INVVID,'ERROR ');
  write((e shr 4) and 15);
  write(e and 15,NORVID);
end;

proc setsubtype(subtype:char);
{****************************}
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
  silentflag := false;
  if ARGTYPE[_carg]='s' then
    silentflag := option('S');
  silent(silentflag);
  bestmatch;
  writeln;
  emucom := ECEXPORT;
  filerr := emures;
  if filerr<>0 then bcderror(filerr);
    silent(false);
end.
  