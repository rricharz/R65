program find;
{ find files on drive 0 and drive 1.
  Wildcards * and ? are allowed.
  The cyclus is ignored.
  File type is required either as
  name:x, name* or name:?

  2023 rricharz                       }

uses syslib,arglib,wildlib,disklib;

const afloppy=$c827;

mem   filerr=$db: integer&;

var   cyclus,drive,entry: integer;
      default,found,last: boolean;
      name: array[namesize] of char;

proc findond(nm:array[15] of char; drv:integer);
{********************************************}

const  prflab     = $ece3;

var first: boolean;
    i: integer;
    nm2: array[namesize] of char;

begin
  filerr:=0;
  first:=true;
  fildrv:=drv;
  if nm[0]<>' ' then begin
    cyclus:=0; drive:=drv;
    asetfile(nm,cyclus,drive,' ');
    call(afloppy);
  end else begin
    dskname;
    for i:=0 to namesize do nm2[i]:=filnam[i];
  end;
  if filerr=0 then begin
    last:=false; entry:=0;
    while (entry<numentries) and not last do begin
      cyclus:=0;
      findentry(name,drv,entry,found,last);
      if found and (not last) then begin
        if first then begin
          write(invvid,'Disk ');
          if nm[0]=' ' then
            writename(nm2)
          else
            writename(nm);
          writeln(':',norvid);
          first:=false;
        end;
        call(prflab); writeln;
        end;
      end;
    entry:=entry+1;
  end else begin
    write('disk ');
    writename(nm);
    writeln(' not found');
  end;
end;

begin
  cyclus:=0; drive:=255;
  agetstring(name,default,cyclus,drive);
  if drive<>255 then
    findond('                ',drive)
  else begin
    findond('WORK            ',1);
    findond('PROGRAMS        ',0);
    findond('SOURCE          ',0);
    findond('BASIC           ',0);
    findond('HELP            ',0);
    findond('PSOURCE         ',0);
    findond('PASCAL          ',0);
  end;
end.

