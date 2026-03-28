{    ************************************    }
{    *  strlib: handling cpnt pointers  *    }
{    ************************************    }

{ Type cpnt are pointers to 0 delimided      }
{ strings of up to STRSIZE (64) characters.  }
{ Following the definition of arrays in R65  }
{ Pascal the first character is s[0.         }
{ s[STRSIZE] can be used to set ENDMARK for  }
{ a string of STRSIZE characters. Range      }
{ checking is turned on for safety.          }
{ Strings need to be released in reverse     }
{ order. There is no garbage collection.     }

{$R+}

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

func _new: cpnt;
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
    { 255 words are left for the growing stack }
    _runerr($88);
  end;
  { allocate heap memory }
  endstk := endstk - STRSIZE - 1;
  str := cpnt(endstk);
  { initialize the string }
  str[0] := ENDMARK;
  _new := str;
end;

{ ***** _release: _release heap memory ***** }

proc _release(s: cpnt);
{ Only the last allocated string can be _released }
{ This is suitable for recursive functions }
mem endstk=$000e: integer;
begin
  if cpnt(endstk)=s then endstk:=endstk+STRSIZE+1
  else _runerr($92);
end;

{ ***** _strlen: length of string ***** }

func _strlen(strin:cpnt):integer;
var i: integer;
begin
  i:=0;
  while i<STRSIZE do begin
    if strin[i]=ENDMARK then begin
      _strlen:=i;
      exit;
    end;
    i:=i+1;
  end;
  _strlen:=STRSIZE;
end;

{ ***** strcopy: copy cpnt string ***** }

proc _strcpy(strin, strout:cpnt);
var i: integer;
begin
  strout[0] := ENDMARK;
  write(@strout, strin);
end;

{ **** _stradd: add string to string ***** }

proc _stradd(strin,strinout:cpnt);
var i,j: integer;
begin
  write(@strinout, strin);
end;

{ **** _strcmp: compare two strings **** }
{ returns -1  if s1<s2                   }
{          0  if s1=s2                   }
{          1  if s1>s2                   }

func _strcmp(s1,s2:cpnt):integer;
var i:integer;
begin
  i:=0;
  while i<STRSIZE do begin
    if s1[i]<>s2[i] then begin
      if s1[i]>s2[i] then _strcmp:=1
      else _strcmp:=-1;
      exit;
    end;
    if s1[i]=ENDMARK then begin
      _strcmp:=0;
      exit;
    end;
    i:=i+1;
  end;
  _strcmp:=0;
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
    while (i<len) and (s1[i]<>ch) do i :=i + 1;
    if s1[i]=ch then _strpos := i
    else _strpos := -1;
  end;
end;

{***** strread: read line from file *****}
func _strread(f:file; s:cpnt;
                 var ateof0:boolean):integer;
var ch  : char;
    i   : integer;
    done: boolean;
begin
  ateof0 := false;
  i := 0;
  done := false;
  while not done do begin
    read(@f, ch);
    if ch = chr($7f) then begin { EOF }
      ateof0 := true;
      done := true;
    end;
    if (not done) and (ch = chr($0d)) then
      done := true;
    if (not done) and (ch = chr($0a)) then
      done := true;
    if not done then
      if i < STRSIZE-1 then
      begin
        s[i] := ch;
        i := i + 1;
      end;
  end;
  s[i] := ENDMARK;
  _strread := i;
end;

{ _hexstr: convert hex byte to hex string }

proc _hexstr(d:integer; s:cpnt);
  func hchar(h:integer):char;
  begin
    if h<10 then hchar := chr(h+ord('0'))
    else hchar := chr(h-10+ord('A'));
  end;
begin
  s[0] := hchar((d shr 4) and 15);
  s[1] := hchar(d and 15);
  s[2] := chr(0);
end;proc _strdelc(pos:integer;s:cpnt);
var i,l:integer;
begin
  l:=_strlen(s);
  if pos<0 then _runerr($91);
  if pos>l then _runerr($91);
  for i:=pos to l-1 do
      { move includes end mark }
      s[i]:=s[i+1];
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
  if pos<0 then _runerr($91);
  if pos>l then _runerr($91);
  for i:=pos to l-1 do
      { move includes end mark }
      s[i]:=s[i+1];
end;

{ **** _intstr: convert integer to string **** }
{ right justified in a field of fsize chars }

proc _intstr(n:integer;s:cpnt;fsize:integer);
{ Very useful for tables }
begin
  s[0]:=ENDMARK;
  write(@s,n);
  while _strlen(s)<fsize do _strinsc(' ',0,s);
end;

begin
end.
