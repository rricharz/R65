
{         *****************             }
{         *               *             }
{         *      edit     *             }
{         *               *             }
{         *****************             }

{    2018 rricharz (r77@bluewin.ch)     }
{ 2026/4 Use Emucom commands directly   }

{ Edit a text file.                     }

{ Usage:  edit FILNAM[:x][.cy[,drive]]  }

{$U+}

program edit;
uses syslib, arglib, filelib;

const cup      = chr($1a);
      PRFLAB   = $ece3;

mem filerr = $db: integer&;
    filstp=$312:char&;

var cyclus,drive,free: integer;
    name:    array[15] of char;
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
  _asetfile(name,cyclus,drive,filstp);
  if not _bestmatch then begin
    writeln;
    writeln(CUP,INVVID,'File not found',NORVID);
    exit;
  end;
  writeln('e');
  filerr := _emulator(ECEXPORT);
  if filerr<>0 then begin
    bcderror(filerr);
    writeln;
    exit;
  end;
  filerr := _emulator(ECEDIT);
  if filerr<>0 then begin
    if filerr=$69 then
      writeln(INVVID,'File not stored',NORVID)
    else begin
      bcderror(filerr);
      writeln;
      end;
    exit;
  end;

  filerr := _emulator(ECIMPORT);
  if filerr<>0 then begin
    bcderror(filerr);
    writeln;
    exit;
  end;
  call(PRFLAB);
  writeln('+');

  free:=_freedrv(FILDRV,true);
end.
