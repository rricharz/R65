{ IFILE:P - common file handling procedures }

proc runprog
  (name: array[15] of char;
   cyc: integer; drv: integer);
var i: integer;
begin
  for i:=0 to 15 do filnm1[i]:=name[i];
  filcy1:=cyc; fildrv:=drv; filflg:=$40;
  run
end;

proc writename(text: array[15] of char);
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
  carg,cyc,drv:integer);
var k:integer;
begin
  argtype[carg]:='s';
    for k:=0 to 7 do
      arglist[carg+k]:=
        ord(packed(fname[2*k+1],
                    fname[2*k]));
    argtype[carg+8]:='i';
    arglist[carg+8]:=cyc;
    argtype[carg+9]:='i';
    arglist[carg+9]:=drv;
end;

proc setargi(val,carg:integer);
begin
  argtype[carg]:='i';
  arglist[carg]:=val;
end;