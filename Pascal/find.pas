program find;
{ find files on drive 0 and drive 1.
  Wildcards * and ? are allowed,
  except as the first character, where
  they are rejected by the argument
  entry routine in system.pas, which
  requires that th first character
  is a letter.The cyclus is ignored.
  File type is required either as
  name:x, name* or name:?
 
  2023 rricharz                       }
 
uses syslib,arglib;
 
const namesize=15;
      afloppy=$d0db; { exdos vector }
 
mem   filerr=$db: integer&;
 
var   cyclus,drive,entry: integer;
      default,found,last: boolean;
      name: array[namesize] of char;
 
proc test(s1:array[namesize] of char;
      var found:boolean);
{***********************************}
var i1,i2,l1,l2:integer;
 
func match(i0,i2:integer): boolean;
var i1:integer;
    b:boolean;
begin
  i1:=i0;
  if (i1>=l1) and (i2>=l2) then
    match:=true
  else begin
    if s1[i1]='*' then
      while (i1<l1) and (s1[i1+1]='*') do i1:=i1+1;
{    writeln('skipped: i1=',i1,', i2=',i2); }
    if (s1[i1]='*') and (i1<l1-1) and (i2>=l2) then
      match:=false
    else begin
{      writeln('ckeck ? or equal: i1=',i1,', i2=',i2,
        ' ',s1[i1],filnam[i2]); }
      if (s1[i1]='?') or (s1[i1]=filnam[i2]) then
        match:=match(i1+1,i2+1)
      else begin
{        writeln('char not equal'); }
        if (s1[i1]='*') and (i1<l1) then begin
          b:=match(i1+1,i2);
          if not b then
            b:=match(i1,i2+1);
          match:=b;
        end else begin
          match:=false;
        end;
      end;
    end;
  end;
end;
 
proc findends;
var k:integer;
begin
  k:=namesize;
  while (s1[k]=' ') and (k>0) do k:=k-1;
  l1:=k+1;
  k:=namesize;
  while (filnam[k]=' ') and (k>0) do k:=k-1;
  l2:=k+1;
end;
 
begin {test}
  findends;
  found:=match(0,0);
end;
 
proc findentry(var nm:array[namesize] of char;
       drv:integer;var ent: integer;
       var fnd,lst:boolean);
{********************************************}
const aprepdo    = $f4a7;
      agetentx   = $f63a;
      aenddo     = $f625;
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
    i:=0;
    test(nm,fnd);
    if (fillnk and $80)<>0 then {deleted file}
      fnd:=false;
    ent:=ent+1;
    lst:=(filtyp=chr(0));
    until fnd or lst or (ent>=numentries);
  call (aenddo);
 
end;
 
proc findond(nm:array[15] of char; d:integer);
{********************************************}
const numentries = 79;
      prflab     = $ece3;
 
 
var first: boolean;
    i: integer;
 
proc writename(nm1:array[15] of char);
var j,k:integer;
begin
  k:=15;
  while (nm1[k]=' ') and (k>1) do k:=k-1;
  for j:=0 to k do write(nm1[j]);
end;
 
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
 
  findond('SOURCEEPROM     ',0);
 
  findond('BASIC           ',0);
 
  findond('SOURCECOMPIL    ',0);
 
  findond('SOURCEPASCAL    ',0);
 
  findond('PASCAL          ',0);
end.
 