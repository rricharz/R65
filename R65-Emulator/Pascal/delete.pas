
{         *****************                }
{         *    delete     *                }
{         *****************                }

{    2018 rricharz (r77@bluewin.ch)        }
{    2023 added wildcards                  }

{ Usage:  delete FILNAM[:x][.cy][,drive]   }

{W ild cards * and ? are allowed           }

{$U+}

program delete;
uses syslib, arglib, filelib, wildlib;

const adelete  = $c80c; { exdos vector }

mem filerr=$db: integer&;

var cyclus, scyclus, drive, entry,
    fcount,i:                    integer;
    name, savename:              array[15] of char;
    default,found,last,quiet:    boolean;

proc bcderror(e:integer);
{***********************}
begin
  write(INVVID,'ERROR ');
  write((e shr 4) and 15);
  writeln(e and 15,NORVID);
end;

func haswildcard(nm1:array[15] of char): boolean;
{***********************************************}
var k:integer;
begin
  haswildcard:=false;
  for k:=0 to 15 do
    if (nm1[k]='*') or (nm1[k]='?') then
      haswildcard:=true;
end;

begin
  cyclus:=0; drive:=1; filerr:=0;
  _agetstring(name,default,cyclus,drive);
  scyclus:=cyclus;
  quiet := false;
  if ARGTYPE[_carg] = 's' then
    quiet := option('Q');
  fcount:=0; last:=false; entry:= 0;
  while (entry<NUMENTRIES) and not last do begin
    cyclus:=scyclus;
    _findentry(name,drive,entry,found,last);
    if found and (not last) and
        ((scyclus=0) or (scyclus=FILCYC)) then begin
      for i:=0 to 15 do begin
        savename[i]:=name[i];
        name[i]:=FILNAM[i];
      end;
      _asetfile(name,FILCYC,drive,' ');
      if not quiet then begin
        _write_label;
        writeln('-');
      end;
      call(adelete);
      if filerr<>0 then begin
        writeln;
        bcderror(filerr);
        last:=true;
      end;
      fcount:=fcount+1;
      for i:=0 to 15 do
        name[i]:=savename[i];
    end;
  end;
  if (fcount = 0) and not haswildcard(name) then
    writeln(INVVID,'File not found',NORVID)
end.
