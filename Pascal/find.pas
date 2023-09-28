program find;
uses syslib,arglib;
var   cyclus,drive,entry: integer;
      default,found,last: boolean;
      name: array[15] of char;
 
{**************************************}
proc findentry(var nm:array[15] of char;
       drv:integer;var ent: integer;
       var fnd,lst:boolean);
{**************************************}
const aprepdo    = $f4a7;
      agetentx   = $f63a;
      aenddo     = $f625;
      prflab     = $ece3;
      numentries = 79;
 
mem   filtyp     = $0300: char&;
      fillnk     = $031e: integer&;
      scyfc      = $037c: integer&;
 
var   i: integer;
 
proc checkfilerr;
mem   filerr=$db: integer&;
begin
  if filerr<>0 then begin
    writeln('Cannot read directory');
    abort;
  end;
end;
 
begin
  fildrv:=drv;
  call(aprepdo);
  checkfilerr;
  repeat
    scyfc:=ent:
    call(agetentx);
    checkfilerr;
    fnd:=true;
    if (fillnk and $80)<>0 then {deleted file}
      fnd:=false;
    i:=0;
    repeat
      if (nm[i]<>filnam[i]) and
        (nm[i]<>'*') then fnd:=false;
      i:=i+1;
      until (fnd=false) or (i>15) or (nm[i-1]='*');
    ent:=ent+1;
    lst:=(filtyp=chr(0));
    until fnd or lst or (ent>=numentries);
  call (aenddo);
  if fnd and (not lst) then begin
    ent:=ent-1;
    call(prflab); writeln;
    end;
end;
 
proc findond(d:integer);
const numentries = 79;
begin
  entry:=0;
  writeln(invvid,'Disk ',d,':',norvid);
  last:=false;
  while (entry<numentries) and not last do begin
    cyclus:=0;
    findentry(name,d,entry,found,last);
    entry:=entry+1;
    end;
end;
 
begin
  cyclus:=0; drive:=0; {defaults}
  agetstring(name,default,cyclus,drive);
  { drive and cyclus are ignored }
  findond(0);
  writeln;
  findond(1);
end.
