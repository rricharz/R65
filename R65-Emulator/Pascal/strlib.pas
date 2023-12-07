{ ************************************
  *  strlib: handling cpnt pointers  *
  ************************************

type cpnt are pointers to strings of
0 delimited strings of up to 64 characters }

library strlib;

const strsize=64;
      endmark=chr(0);

{ ***** runerr: stop with runtime error ***** }

proc runerr(e:integer);
const stopcode = $2010;
mem   runerr = $000c: integer&;
begin
  runerr:=e;
  call(stopcode);
end;

{ ***** new: allocate heap memory ***** }

func new:cpnt;
mem  sp     = $0008: integer;
     endstk = $000e: integer;
var  freewords,i:integer;
     str:cpnt;
begin
  { Pascal has no type unsigned integer. }
  { But the free space can be larger than 32767 }
  { We work therefore with free words here }
  freewords:=(endstk-sp) shr 1;
  if freewords < (strsize + 256) then begin
    { 256 words are left for the growing stack }
    runerr($88);
  end;
  { allocate heap memory }
  endstk:=endstk-strsize;
  str:=cpnt(endstk);
  { initialize the string }
  str[0]:=endmark;
  new:=str;
end;

{ ***** release: release heap memory ***** }

proc release(s: cpnt);
{ Only the last allocated string can be released }
{ This is suitable for recursive functions }
mem endstk=$000e: integer;
begin
  if cpnt(endstk)=s then endstk:=endstk+strsize
  else runerr($92);
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
  strout[0]:=endmark;
  write(@strout,strin);
end;

{ **** stradd: add string to string ***** }

proc stradd(strin,strinout:cpnt);
var i,j:integer;
begin
  write(@strinout,strin);
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

{ **** strread: read string from input }
{ returns the number of chars read }

func strread(f: file; s: cpnt): integer;
var i: integer;
    ch: char;
begin
  i:=-1;
  repeat
    i:=succ(i);
    read(@f,ch);
    s[i]:=ch;
    until (ch=chr($d)) or (ch=chr($1f)) or
      (ch=chr($7f)) or (ch=chr(0)) or (i>=strsize-1);
  s[i]:=chr(0);
  strread:=i;
end;

{ hexstr: convert hex byte to hex string }

proc hexstr(d:integer; s:cpnt);
  func hchar(h:integer):char;
  begin
    if h<10 then hchar:=chr(h+ord('0'))
    else hchar:=chr(h-10+ord('A'));
  end;
begin
  s[0]:=hchar((d shr 4) and 15);
  s[1]:=hchar(d and 15);
  s[2]:=chr(0);
end;

{ *** strinsc: insert char into string *** }
{ inserts char if string is short enough }

proc strinsc(ch:char;pos:integer;s:cpnt);
var i,l:integer;
begin
  l:=strlen(s);
  if (l<strsize-1) and (pos>=0)
    and (pos<strsize-1) then begin
    for i:=l downto pos do
      { move includes end mark }
      s[i+1]:=s[i];
    if pos > l then begin
      for i:=l to pos-1 do s[i]:=' ';
      s[pos+1]:=chr(0);
    end;
    s[pos]:=ch;
  end
  else runerr($91);
end;

{ *** strdelc: delete char in string *** }

proc strdelc(pos:integer;s:cpnt);
var i,l:integer;
begin
  l:=strlen(s);
  for i:=pos to l-1 do
      { move includes end mark }
      s[i]:=s[i+1];
end;

{ **** intstr: convert integer to string **** }
{ right justified in a field of 6 chars }

proc intstr(n:integer;s:cpnt;fsize:integer);
begin
  s[0]:=endmark;
  write(@s,n);
  while strlen(s)<fsize do strinsc(' ',0,s);
end;

begin
end.
