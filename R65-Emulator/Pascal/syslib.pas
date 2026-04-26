
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

  MMAXSEQ  = 8;         {max no of seq. files}

  TOPMEM   = $c780;     {top of user memory}
  MAXINT   = $7fff;     {max integer value}

  INPUT    = @0;        {line input}
  OUTPUT   = @0;        {display output}
  KEY      = @1;        {unbuffered kb input}
  PRINTER  = @1;        {hardcopy output}

mem
  { The & below is required for 8-bit }
  RUNERR   = $000c: integer&;
  ENDSTK   = $000e: integer;
  BUFFPN   = $0015: integer&;
  IOCHECK  = $0023: boolean&;
  CURPOS   = $00ee: integer&;

var
  _day:    integer;
  _month:  integer;
  _year:   integer;

proc _setemucom(i:integer);
{*************************}
{ set emulator command register }
mem emucom=$1430:integer&;
begin
  emucom:=i;
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

proc _prtext8(device: file; text: array[7] of char);
{**************************************************}
{ print array of 8 characters }
var i: integer;
begin
  for i:=0 to 7 do write(@device,text[i]);
end;

proc _prtext16(device: file; text: array[15] of char);
{****************************************************}
{ print array of 16 characters }
var i: integer;
begin
  for i:=0 to 15 do write(@device,text[i]);
end;

func _random: integer;
{********************}
{ pseudo random generator, result is 0..255 }
begin
  _random:=mem[$1706] and 255;
end;

proc __wrintf(value, width: integer);
{***********************************}
{ Write value right justified in a field of width.
  This procedure is a helper for the compiler. I is
  used in the write and writeln commands for
  justified numbers. Do not change the format.     }
var
  buf: array [5] of char;
  { 0..5, enough for -32768..32767 }
  i, len, n, w, q, r: integer;
  neg: boolean;
begin
  w := width;
  { Special case, because -(-32768) would overflow
    on a 16-bit machine, -32768 cannot be entered }
  if value = $8000 then begin
    len := 6;
    while w > len do begin
      write(' ');
      w := w - 1
    end;
    write('-32768');
    exit
  end;
  neg := value < 0;
  if neg then
    n := -value
  else
    n := value;
  i := 5;
  { Generate digits backwards into buf }
  repeat
    q := n div 10;
    r := n - q*10;
    buf[i] := chr(ord('0') + r);
    n := q;
    i := i - 1
  until n = 0;
  if neg then begin
    buf[i] := '-';
    i := i - 1
  end;
  { Characters are now in buf[i+1..5] }
  len := 5 - i;
  while w > len do begin
    write(' ');
    w := w - 1
  end;
  while i < 5 do begin
    i := i + 1;
    write(buf[i])
  end
end;

begin {main}
end.
