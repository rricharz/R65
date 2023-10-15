library wildlib;
{ find filesentries. Wildcards * and ? are allowed.
  The cyclus is ignored.
  File type is required either as
  name:x, name* or name:?
 
  2023 rricharz                       }
 
const namesize=15;
      numentries=79;
 
mem filnam=$0301: array[namesize] of char&;
 
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
 
mem   filtyp     = $0300: char&;
      fillnk     = $031e: integer&;
      scyfc      = $037c: integer&;
      fildrv     = $00dc: integer&;
 
var   i: integer;
 
 
proc checkfilerr;
const stopcode=$2010;
mem filerr = $db: integer&;
    runerr = $0c: integer&;
begin
  if filerr<>0 then begin
    writeln('Directory error');
    runerr:=$36;
    call(stopcode);
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
 
proc writename(nm1:array[15] of char);
var j,k:integer;
begin
  k:=15;
  while (nm1[k]=' ') and (k>1) do k:=k-1;
  for j:=0 to k do write(nm1[j]);
end;
 
begin
end.
 