program find;
{ find files on drive 0 and drive 1.
  Wildcards * and ? are allowed.
  The cyclus is ignored.
  File type is required either as
  name:x, name* or name:?

  2023 rricharz                       }

uses syslib,arglib,wildlib;

const afloppy=$c827;

mem   filerr=$db: integer&;

var   cyclus,drive,entry: integer;
      default,found,last: boolean;
      name: array[namesize] of char;

proc findond(nm:array[15] of char; d:integer);
{********************************************}

const  prflab     = $ece3;

var first: boolean;
    i: integer;

begin
  first:=true;
  cyclus:=0; drive:=d;
  asetfile(nm,cyclus,drive,' ');
  call(afloppy);
  if filerr=0 then begin
    last:=false; entry:=0;
    while (entry<numentries) and not last do begin
      cyclus:=0;
      findentry(name,d,entry,found,last);
      if found and (not last) then begin
        if first then begin
          write(invvid,'Disk ');
          writename(nm); writeln(':',norvid);
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
  cyclus:=0; drive:=0;
  agetstring(name,default,cyclus,drive);
  findond('WORK            ',1);
  findond('PROGRAMS        ',0);
  findond('SOURCE          ',0);
  findond('BASIC           ',0);
  findond('PSOURCE         ',0);
  findond('PASCAL          ',0);
end.
