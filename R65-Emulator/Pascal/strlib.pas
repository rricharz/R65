{ ************************************
  *  strlib: handling cpnt pointers  *
  ************************************

type cpnt are pointers to strings of
0 delimited strings of up to 64 characters }

library strlib;

const STRSIZE=64;
      ENDMARK=chr(0);

{ ***** _runerr: stop with runtime error ***** }

proc _runerr(e:integer);
const stopcode = $2010;
mem   _runerr = $000c: integer&;
begin
  _runerr:=e;
  call(stopcode);
end;

{ ***** _new: allocate heap memory ***** }

func _new:cpnt;
mem  sp     = $0008: integer;
     endstk = $000e: integer;
var  freewords,i:integer;
     str:cpnt;
begin
  { Pascal has no type unsigned integer. }
  { But the free space can be larger than 32767 }
  { We work therefore with free words here }
  freewords:=(endstk-sp) shr 1;
  if freewords < (STRSIZE + 256) then begin
    { 256 words are left for the growing stack }
    _runerr($88);
  end;
  { allocate heap memory }
  endstk:=endstk-STRSIZE;
  str:=cpnt(endstk);
  { initialize the string }
  str[0]:=ENDMARK;
  _new:=str;
end;

{ ***** _release: _release heap memory ***** }

proc _release(s: cpnt);
{ Only the last allocated string can be _released }
{ This is suitable for recursive functions }
mem endstk=$000e: integer;
begin
  if cpnt(endstk)=s then endstk:=endstk+STRSIZE
  else _runerr($92);
end;

{ ***** _strlen: length of string ***** }

func _strlen(strin:cpnt):integer;
var i:integer;
begin
  i:=0;
  while (strin[i]<>ENDMARK) and (i<STRSIZE) do
    i:=succ(i);
    _strlen:=i;
end;

{ ***** strcopy: copy cpnt string ***** }

proc _strcpy(strin, strout:cpnt);
var i: integer;
begin
  strout[0]:=ENDMARK;
  write(@strout,strin);
end;

{ **** _stradd: add string to string ***** }

proc _stradd(strin,strinout:cpnt);
var i,j:integer;
begin
  write(@strinout,strin);
end;

{ **** _strcmp: compare two strings **** }
{ returns -1  if s1<s2
           0  if s1=s2
           1  if s1>s2                  }

func _strcmp(s1,s2:cpnt):integer;
var i:integer;
begin
  { find first difference or end of string }
  i:=0;
  while (s1[i]<>ENDMARK) and (s1[i]=s2[i])
    and (i<STRSIZE) do i:=succ(i);
  if s1[i]=s2[i] then _strcmp:=0
  else if s1[i]>s2[i] then _strcmp:=1
  else _strcmp:=-1;
end;

{ **** _strpos: find occurance of char **** }
{ returns -1 if char not found }
func _strpos(ch:char; s1:cpnt; start:integer): integer;
var i,len: integer;
begin
  len:=_strlen(s1);
  if start>=len then _strpos:=-1
  else  begin
    i:=start;
    while (i<len) and (s1[i]<>ch) do i:=succ(i);
    if s1[i]=ch then _strpos:=i
    else _strpos:=-1;
  end;
end;

{ **** _strread: read string from input }
{ returns the number of chars read }

func _strread(f: file; s: cpnt): integer;
var i: integer;
    ch: char;
begin
  i:=-1;
  repeat
    i:=succ(i);
    read(@f,ch);
    s[i]:=ch;
    until (ch=chr($d)) or (ch=chr($1f)) or
      (ch=chr($7f)) or (ch=chr(0)) or (i>=STRSIZE-1);
  s[i]:=chr(0);
  _strread:=i;
end;

{ _hexstr: convert hex byte to hex string }

proc _hexstr(d:integer; s:cpnt);
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

{ *** _strinsc: insert char into string *** }
{ inserts char if string is short enough }

proc _strinsc(ch:char;pos:integer;s:cpnt);
var i,l:integer;
begin
  l:=_strlen(s);
  if (l<STRSIZE-1) and (pos>=0)
    and (pos<STRSIZE-1) then begin
    for i:=l downto pos do
      { move includes end mark }
      s[i+1]:=s[i];
    if pos > l then begin
      for i:=l to pos-1 do s[i]:=' ';
      s[pos+1]:=chr(0);
    end;
    s[pos]:=ch;
  end
  else _runerr($91);
end;

{ *** _strdelc: delete char in string *** }

proc _strdelc(pos:integer;s:cpnt);
var i,l:integer;
begin
  l:=_strlen(s);
  for i:=pos to l-1 do
      { move includes end mark }
      s[i]:=s[i+1];
end;

{ **** _intstr: convert integer to string **** }
{ right justified in a field of 6 chars }

proc _intstr(n:integer;s:cpnt;fsize:integer);
begin
  s[0]:=ENDMARK;
  write(@s,n);
  while _strlen(s)<fsize do _strinsc(' ',0,s);
end;

begin
end.
