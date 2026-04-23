
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
      prflb1   = $f151;
      CUP      = chr($1a);

mem filerr=$db: integer&;

var cyclus,scyclus,drive,entry,fcount,i: integer;
    name,savename: array[15] of char;
    default,found, last: boolean;

{$I ISILENT:P}

proc bcderror(e:integer);
begin
  write(INVVID,'ERROR ');
  write((e shr 4) and 15);
  writeln(e and 15,NORVID);
end;

func haswildcard(nm1:array[15] of char): boolean;
var k:integer;
begin
  haswildcard:=false;
  for k:=0 to 15 do
    if (nm1[k]='*') or (nm1[k]='?') then
      haswildcard:=true;
end;

begin
  write(CUP);
  cyclus:=0; drive:=1; filerr:=0;
  _agetstring(name,default,cyclus,drive);
  scyclus:=cyclus;
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
      silent(false);
      call(prflb1);
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
  writeln;
  if (fcount = 0) then begin
    if not haswildcard(name) then begin
      writeln(INVVID,'File not found',NORVID)
    end
  end else
    writeln(fcount, ' file(s) deleted');
end.
