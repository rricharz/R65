{ ************************************
  *  strlib: handling cpnt pointers  *
  ************************************

type cpnt are pointers to strings of
0 delimited strings of up to 64 characters }

library strlib;

const strsize=64;
      endmark=chr(0);

{ ***** strnew: allocate heap memory for cpnt ***** }

func strnew:cpnt;
const stopcode = $2010;
mem   endstk = $000e: integer;
      runerr = $000c: integer&;
      sp     = $0008: integer;
var fbytes,i:integer;
    str:cpnt;
begin
  fbytes:=endstk-sp;
  if (endstk>0) and ((endstk-sp) < (strsize+512))
  { avoid 16-bit signed integer overflow }
  then begin
    runerr:=$88;
    call(stopcode);
  end;
  { allocate heap memory }
  endstk:=endstk-strsize;
  str:=cpnt(endstk+144);
  { initialize the string }
  for i:=0 to strsize-1 do str[i]:=endmark;
  strnew:=str;
end;

{ ***** strlen: length of string ***** }
func strlen(strin:cpnt):integer;
var i:integer;
begin
  i:=0;
  while (strin[i]<>endmark) and (i<strsize) do
    i:=succ(i);
  strlen:=i;
end;

{ ***** strcopy: copy cpnt string ***** }

proc strcpy(strin, strout:cpnt);
var i: integer;
begin
  i:=0;
  while (strin[i]<>endmark)
                and (i<strsize-2) do begin
    strout[i]:=strin[i];
    i:=succ(i);
  end;
  strout[i]:=endmark;
end;

{ **** stradd: add string to string ***** }
proc stradd(strin,strinout:cpnt);
var i,j:integer;
begin
    i:=strlen(strinout); j:=0;
    while (strin[j]<>endmark)
                and (i<prec(strsize)) do begin
      strinout[i]:=strin[j];
      i:=succ(i); j:=succ(j);
    end;
    strinout[i]:=endmark;
end;

{ **** strcmp: compare two strings **** }
{ returns -1  if s1<s2
           0  if s1=s2
           1  if s1>s2                  }
func strcmp(s1,s2:cpnt):integer;
var i:integer;
begin
  { find first difference or end of string }
  i:=0;
  while (s1[i]<>endmark) and (s1[i]=s2[i])
    and (i<strsize) do i:=succ(i);
  if s1[i]=s2[i] then strcmp:=0
  else if s1[i]>s2[i] then strcmp:=1
  else strcmp:=-1;
end;

{ **** strpos: find occurance of char **** }
{ returns -1 if char not found }
func strpos(ch:char; s1:cpnt; start:integer): integer;
var i,len: integer;
begin
  len:=strlen(s1);
  if start>=len then strpos:=-1
  else  begin
    i:=start;
    while (i<len) and (s1[i]<>ch) do i:=succ(i);
    if s1[i]=ch then strpos:=i
    else strpos:=-1;
  end;
end;

begin
end.
 