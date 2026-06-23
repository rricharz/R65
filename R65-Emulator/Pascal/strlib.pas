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
{$U+}

library strlib;

const STRSIZE=64;
      ENDMARK=chr(0);

proc _runerr(e:integer);
{**********************}
{ set runerr to e and stop execution of app }
const stopcode = $2010;
mem   _mrunerr = $000c: integer&;
begin
  _mrunerr:=e;
  call(stopcode);
end;

func _new: cpnt;
{**************}
{ alocate memory on heap for string }
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

proc _release(s: cpnt);
{*********************}
{ release memory on heap }
{ Only the last allocated string can be _released }
{ This is suitable for recursive functions }
mem endstk=$000e: integer;
begin
  if cpnt(endstk)=s then endstk:=endstk+STRSIZE+1
  else _runerr($92);
end;

func _strlen(strin:cpnt):integer;
{*******************************}
{ length of sring }
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

proc _strcpy(strin, strout:cpnt);
{*******************************}
{ make copy of string }
var i: integer;
begin
  strout[0] := ENDMARK;
  write(@strout, strin);
end;

proc _stradd(strin,strinout:cpnt);
{********************************}
{ add string to string }
var i,j: integer;
begin
  write(@strinout, strin);
end;

func _strcmp(s1,s2:cpnt):integer;
{*******************************}
{ compare 2 strings }
{ returns -1  if s1<s2                   }
{          0  if s1=s2                   }
{          1  if s1>s2                   }
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

func _strpos(ch:char; s1:cpnt;
          start:integer): integer;
{********************************}
{ get first position of character in string }

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

func _strread(f:file; s:cpnt;
          var ateof0:boolean):integer;
{************************************}
{ read string from file }
var ch  : char;
    i   : integer;
    done: boolean;
begin
  ateof0 := false;
  i := 0;
  done := false;
  while not done do begin
    read(@f, ch);
    if (ch = chr($7f)) or (ch = chr($1f))
      then begin { EOF, also for old files }
      ateof0 := true;
      done := true;
    end;
    if (ch = chr($0d)) or (ch = chr($0a)) then
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

proc _strdelc(pos:integer; s:cpnt);
{*********************************}
{ delete char in string at position }
var i,l:integer;
begin
  l:=_strlen(s);
  if pos<0 then _runerr($91);
  if pos>l then _runerr($91);
  for i:=pos to l-1 do
      { move includes ENDMARK }
      s[i]:=s[i+1];
end;

proc _strinsc(ch:char;pos:integer;s:cpnt);
{****************************************}
{ inserts char if string is short enough }
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

proc _intstr(n:integer;s:cpnt;fsize:integer);
{*******************************************}
{ convert integer to right justified  string }
begin
  s[0]:=ENDMARK;
  write(@s,n);
  while _strlen(s)<fsize do _strinsc(' ',0,s);
end;

begin
end.
