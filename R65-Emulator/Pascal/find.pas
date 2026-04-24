
program find;

{  find files on all disks             }
{  Wildcards * and ? are allowed.      }
{  The cyclus is ignored.              }
{  File type is required either as     }
{  name:x, name* or name:?             }

{  2023 rricharz                       }

{$U+}

uses syslib, arglib, wildlib, filelib;

const afloppy  = $c827;
      agetentx = $f63a;
      MAXENT   = 255;

mem   filerr=$db: integer&;
      scyfc   =$037c: integer&;

var   cyclus,drive,entry,saventry,nfound: integer;
      default,found,last: boolean;
      name: array[NAMESIZE] of char;

proc checkfilerr;
{***************}
begin
  if filerr<>0 then begin
    writeln('Cannot read directory');
    _abort;
  end;
end;

proc findond(nm:array[15] of char; drv:integer);
{********************************************}

const  prflab     = $e82d;

var first: boolean;
    i: integer;
    nm2: array[NAMESIZE] of char;

begin
  filerr:=0;
  first:=true;
  FILDRV:=drv;
  if nm[0]<>' ' then begin
    cyclus:=0; drive:=drv;
    _asetfile(nm,cyclus,drive,' ');
    call(afloppy);
  end else begin
    scyfc:=MAXENT;
    call(agetentx);
    checkfilerr;
    for i:=0 to NAMESIZE do nm2[i]:=FILNAM[i];
  end;
  if filerr=0 then begin
    last:=false; entry:=0;
    while (entry<NUMENTRIES) and not last do begin
      cyclus:=0; saventry:=entry;
      _findentry(name,drv,entry,found,last);
      if found and (not last) then begin
        if first then begin
          write(INVVID,'Disk ');
          if nm[0]=' ' then
            _writename(nm2)
          else
            _writename(nm);
          write(':',NORVID); _tab(20);
          writeln('(',_freedrv(drv,false),'% free)');
          first:=false;
          entry:=saventry;
          { find again because of _freedrv }
          _findentry(name,drv,entry,found,last);
        end;
        call(prflab);
        writeln;
        nfound := succ(nfound);
        end;
      end;
    entry:=entry+1;
  end else begin
    write('disk ');
    _writename(nm);
    writeln(' not found');
  end;
end;

begin
  cyclus:=0; drive:=255; nfound:=0;
  _agetstring(name,default,cyclus,drive);
  if drive<>255 then
    findond('                ',drive)
  else begin
    findond('WORK            ',1);
    findond('PROGRAMS        ',0);
    findond('SOURCE          ',0);
    findond('BASIC           ',0);
    findond('HELP            ',0);
    findond('PSOURCE         ',0);
    { PASCAL must be last entry }
    findond('PASCAL          ',0);
  end;
  if nfound = 0 then
    writeln('Nothing found, try FIND name*')
  else
    writeln('Files found: ',nfound);
end.

