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

proc _writename(text: array[15] of char);
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
  _carg,cyc,drv:integer);
var k:integer;
begin
  ARGTYPE[_carg]:='s';
    for k:=0 to 7 do
      ARGLIST[_carg+k]:=
        ord(packed(fname[2*k+1],
                    fname[2*k]));
    ARGTYPE[_carg+8]:='i';
    ARGLIST[_carg+8]:=cyc;
    ARGTYPE[_carg+9]:='i';
    ARGLIST[_carg+9]:=drv;
end;

proc setargi(val,_carg:integer);
begin
  ARGTYPE[_carg]:='i';
  ARGLIST[_carg]:=val;
end;
