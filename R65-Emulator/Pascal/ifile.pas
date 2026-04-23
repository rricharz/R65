{ IFILE:P - common file handling procedures }

proc runprog
  (name: array[15] of char;
   cyc: integer; drv: integer);
var i: integer;
begin
  for i:=0 to 15 do FILNM1[i]:=name[i];
  FILCY1:=cyc; FILDRV:=drv; FILFLG:=$40;
  run
end;

proc writename_nobl(text: array[15] of char);
{ write name without blanks }
var i: integer;
begin
  for i:=0 to 15 do
    if text[i]<>' ' then write(text[i]);
end;

proc setsubtype(subtype:char);
var i:integer;
begin
  i:=0;
  repeat
    i:=i+1;
  until (fname[i]=':') or
    (fname[i]=' ') or (i>=14);
  fname[i]:=':';
  fname[i+1]:=subtype;
end;

func contains(t:array[7] of char):boolean;
{ check for substring in fname }
{ the substring must end with a blank }
var i,i1,j:integer;
    found:boolean;
begin
  i:=0; found:=false;
  repeat
    j:=0;
    if fname[i]=t[j] then begin
      i1:=i;
      repeat
        i1:=i1+1;
        j:=j+1;
        found:=t[j]=' ';
      until (i1>14) or (fname[i1]<>t[j])
                             or found;
    end;
    i:=i+1;
  until found or (i>15);
  contains:=found;
end;


func letter(ch:char):boolean;
begin
  letter:=(ch>='A') and (ch<='Z');
end;

proc setargs(name:array[15] of char;
  _carg0,cyc,drv:integer);
var k9:integer;
begin
  ARGTYPE[_carg0]:='s';
    for k9:=0 to 7 do
      ARGLIST[_carg0+k9]:=
        ord(packed(fname[2*k9+1],
                    fname[2*k9]));
    ARGTYPE[_carg0+8]:='i';
    ARGLIST[_carg0+8]:=cyc;
    ARGTYPE[_carg0+9]:='i';
    ARGLIST[_carg0+9]:=drv;
end;

proc setargi(val,_carg0:integer);
begin
  ARGTYPE[_carg0]:='i';
  ARGLIST[_carg0]:=val;
end;
