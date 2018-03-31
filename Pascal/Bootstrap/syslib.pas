
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

library syslib;

{ R65 Pascal constants }

const
  tab8=chr(9);      {tabulate}
  lf=chr($a);       {line feed}
  formfeed=chr($c); {form feed}
  cr=chr($d);       {carriage return}
  eof=chr($1f);     {end of file}
  norvid=chr($0b);  {normal video}
  invvid=chr($0e);  {inverse video}
  prton=chr($12);   {autoprint on}
  prtoff=chr($14);  {autoprint off}

  mmaxseq = 8;      {max no of seq. files}

  topmem = $c780;   {top of user memory}
  maxint = $7fff;   {max integer value}

  input  = @0;      {line input}
  output = @0;      {display output}
  key    = @1;      {unbuffered kb input}
  printer= @1;      {hardcopy output}

{ R65 Pascal system variables}

mem  { The & below are required for 8-bit!}
  runerr =$000c: integer&;
  endstk =$000e: integer;
  buffpn =$0015: integer&;
  iocheck=$0023: boolean&;

  numarg =$005f: integer&;
  arglist=$0060: array[31] of integer;
  argtype=$00a0: array[31] of char&;

  filflg =$00da: integer&;
  fildrv =$00dc: integer&;
  curpos =$00ee: integer&;

  filnam =$0301: array[15] of char&;
  filnm1 =$0320: array[15] of char&;
  filcy1 =$0330: integer&;
  maxseq =$0336: integer&;
  fidrtb =$0339: array[mmaxseq] of integer&;

var day,month,year: integer;

{ * getbcd(address) * }
{ get 18-bit data from memory in bcd format }

func getbcd(address: integer): integer;
var data: integer;
begin
  data:=mem[address];
  getbcd:=data- 6*(data div 16);
end;

{ * getdate * }
proc getdate;
begin
  day:=getbcd($17b9);
  month:=getbcd($17ba);
  year:=getbcd($17bb);
end;

{ * prtdate(device) * }
proc prtdate(device: file);
begin
  getdate;
  write(@device,day,'/',month,'/',year);
end;

{ * abs(x) * }

func abs(x: integer): integer;
begin
  if x<0 then abs:=-x else  abs:=x
end;

{ * mod(x,n) * }

func mod(x,n: integer): integer;
begin
  mod:=x - (x div n)*n;
end;

{ * tab(x: integer) * }

proc tab(x: integer);
begin
 while (x>curpos) do write(' ');
end;

{ * abort * }
{ stop execution and go tp Pascal system }

proc abort;
const stopcode=$2010;
begin
  runerr:=$36;
  call(stopcode);
end;

{ * prttext8(device,text) * }

proc prtext8(device: file;
  text: array[7] of char);

var i: integer;

begin
  for i:=0 to 7 do write(@device,text[i]);
end;

{ * prttext16(device,text) * }

proc prtext16(device: file;
  text: array[15] of char);

var i: integer;

begin
  for i:=0 to 15 do write(@device,text[i]);
end;

{ * initialization * }

begin {main}
end.
