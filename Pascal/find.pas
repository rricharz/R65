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
 
{********************************************}
proc findentry(var nm:array[namesize] of char;
       drv:integer;var ent: integer;
       var fnd,lst:boolean);
{********************************************}
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
    i:=0;
    test(nm,fnd);
    if (fillnk and $80)<>0 then {deleted file}          
      fnd:=false;                                       
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
 