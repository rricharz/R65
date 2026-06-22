
{  ***************************************  }
{  *                                     *  }
{  *  R65 Computer System                *  }
{  *  Pascal LIBRARY SYSLIB              *  }
{  *                                     *  }
{  ***************************************  }

{  The system library contains a set of     }
{  standard constants, variables and        }
{  procedures for the implementation of     }
{  Pascal on the R65 microcomputer system   }

{ Based on version 11  01/08/1982 rricharz  }
{ Current version 12.1 04/03/2026 rricharz  }

{$U+}

library syslib;

{ R65 Pascal constants }

const
  TAB8     = chr(9);    {tabulate}
  HOM      = chr(1);    {cursor home}
  CSC      = chr($11);  {clear screen}
  LF       = chr($a);   {line feed}
  FF       = chr($c);   {form feed}
  CR       = chr($d);   {carriage return}
  EOF      = chr($7f);  {end of file}
  CUP      = chr($1a);
  CLRLIN   = chr($17);
  NORVID   = chr($0b);  {normal video}
  INVVID   = chr($0e);  {inverse video}
  PRTON    = chr($12);  {autoprint on}
  PRTOFF   = chr($14);  {autoprint off}

  TOPMEM   = $c780;     {top of user memory}
  MAXINT   = $7fff;     {max integer value}

  INPUT    = @0;        {line input}
  OUTPUT   = @0;        {display output}
  KEY      = @1;        {unbuffered kb input}
  PRINTER  = @1;        {hardcopy output}

  ECEXPORT = 1;         {emulator commands}
  ECIMPORT = 2;
  ECEDIT   = 3;
  EC_CLR_PRTOUT = 9;

mem
  { The & below is required for 8-bit }
  RUNERR   = $000c: integer&;
  FILERR   = $00db: integer&;
  ENDSTK   = $000e: integer;
  IOCHECK  = $0023: boolean&;
  CURPOS   = $00ee: integer&;

var
  _day:    integer;
  _month:  integer;
  _year:   integer;

func _emulator(i:integer): integer;
{*************************}
{ set emulator command register }
mem
{$I IHIDDENMEM:P}
begin
  emucom := i;
  _emulator := emures;
end;

func _getbcd(address: integer): integer;
{**************************************}
{ get 16-bit data from memory in bcd format }
var data: integer;
begin
  data:=mem[address];
  _getbcd:=data- 6*(data div 16);
end;

proc _getdate;
{************}
{ get date from Linux }
begin
  _day:=_getbcd($17b9);
  _month:=_getbcd($17ba);
  _year:=_getbcd($17bb);
end;

proc _prtdate(device: file);
{**************************}
{ print date }
begin
  _getdate;
  write(@device,_day,'/',_month,'/',_year);
end;

func _abs(x: integer): integer;
{*****************************}
{ compute absolute value of integer }
begin
  if x<0 then _abs:=-x else _abs:=x
end;

func _mod(x,n: integer): integer;
{*******************************}
{ compute modulo function of ineger }
begin
  _mod:=x - (x div n)*n;
end;

proc _tab(pos: integer);
{**********************}
{ tabulate to position on screen }
begin
 while (pos>CURPOS) do write(' ');
end;

proc _abort;
{**********}
{ abort program and give error 54 }
const STOPCODE=$2010;
begin
  RUNERR:=54;
  call(STOPCODE);
end;

func _random: integer;
{********************}
{ pseudo random generator, result is 0..255 }
begin
  _random:=mem[$1706] and 255;
end;

func _readint(f:file; var n:integer): boolean;
{********************************************}
var
  ch: char;
  neg, digit: boolean;
begin
  n := 0;
  neg := false;
  digit := false;

  read(@f,ch);
  while (ch=' ') or (ch=',') or (ch=chr(13)) do
    read(@f,ch);

  if ch=chr($7f) then
    _readint:=false
  else begin
    if ch='-' then begin
      neg:=true;
      read(@f,ch)
    end else if ch='+' then
      read(@f,ch);

    while (ch>='0') and (ch<='9') do begin
      digit:=true;
      n:=10*n+ord(ch)-ord('0');
      read(@f,ch)
    end;

    if neg then n:=-n;
    _readint:=digit
  end
end;

func _isesc:boolean;
{*****************}
mem SFLAG=$1781:integer&;
begin
  _isesc:=((SFLAG and $80) <> 0);
  SFLAG:=SFLAG and $7f;
end;

begin {main}
end.
