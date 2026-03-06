
{  ***************************************  }
{  *                                     *  }
{  *  R65 Computer System                *  }
{  *  Pascal LIBRARY SYSL                *  }
{  *                                     *  }
{  ***************************************  }

{  The system library contains a set of     }
{  standard constants, variables and        }
{  procedures for the implementation of     }
{  Pascal on the R6 microcomputer system    }

{ Based on version 11 01/08/82 rricharz     }
{ Current version 12.0 03/09/2018 rricharz  }
{ Added function: random                    }

library syslib;

{ R65 Pascal constants }

const
  TAB8=chr(9);      {tabulate}
  HOM=chr(1);       {cursor home}
  CSC=chr($11);     {clear screen}
  LF=chr($a);       {line feed}
  FF=chr($c);       {form feed}
  CR=chr($d);       {carriage return}
  EOF=chr($1f);     {end of file}
  NORVID=chr($0b);  {normal video}
  INVVID=chr($0e);  {inverse video}
  PRTON=chr($12);   {autoprint on}
  PRTOFF=chr($14);  {autoprint off}

  MMAXSEQ = 8;      {max no of seq. files}

  TOPMEM = $c780;   {top of user memory}
  MAXINT = $7fff;   {max integer value}

  INPUT  = @0;      {line input}
  OUTPUT = @0;      {display output}
  KEY    = @1;      {unbuffered kb input}
  PRINTER= @1;      {hardcopy output}

{ R65 Pascal system variables}

mem  { The & below are required for 8-bit!}
  RUNERR =$000c: integer&;
  ENDSTK =$000e: integer;
  BUFFPN =$0015: integer&;
  IOCHECK=$0023: boolean&;

  MUMARG =$005f: integer&;
  ARGLIST=$0060: array[31] of integer;
  ARGTYPE=$00a0: array[31] of char&;

  FILFLG =$00da: integer&;
  FILDRV =$00dc: integer&;
  CURPOS =$00ee: integer&;

  FILNUM =$0301: array[15] of char&;
  FILNM1 =$0320: array[15] of char&;
  FILCYC =$0330: integer&;
  MAXSEQ =$0336: integer&;
  FIDRTP =$0339: array[MMAXSEQ] of integer&;

var _day,_month,_year: integer;

proc _setemucom(i:integer);
mem emucom=$1430:integer&;
begin
  emucom:=i;
end;

func _getbcd(address: integer): integer;
{ get 16-bit data from memory in bcd format }
var data: integer;
begin
  data:=mem[address];
  _getbcd:=data- 6*(data div 16);
end;

proc _getdate;
begin
  _day:=_getbcd($17b9);
  _month:=_getbcd($17ba);
  _year:=_getbcd($17bb);
end;

proc _prtdate(device: file);
begin
  _getdate;
  write(@device,_day,'/',_month,'/',_year);
end;

func _abs(x: integer): integer;
begin
  if x<0 then _abs:=-x else _abs:=x
end;

func _mod(x,n: integer): integer;
begin
  _mod:=x - (x div n)*n;
end;

proc _tab(x: integer);
begin
 while (x>CURPOS) do write(' ');
end;

proc _abort;
const STOPCODE=$2010;
begin
  RUNERR:=$36;
  call(STOPCODE);
end;

proc _prtext8(device: file;
  text: array[7] of char);
var i: integer;
begin
  for i:=0 to 7 do write(@device,text[i]);
end;

proc _prtext16(device: file;
  text: array[15] of char);
var i: integer;
begin
  for i:=0 to 15 do write(@device,text[i]);
end;

func _random: integer;
{uses the pseudo random generator}
{provided by C, seeded at startup}
{returned values in range 9 - 255}
begin
  _random:=mem[$1706] and 255;
end;

begin {main}
end.
