
{  ***************************************  }
{  *                                     *  }
{  *  R65 Computer System                *  }
{  *  Pascal LIBRARY ARGLIB              *  }
{  *                                     *  }
{  ***************************************  }

{      Version 07 01/08/82 rricharz         }
{      Recovered 2018 by rricharz           }

{ gets arguments given to app               }
{ prepares system disk io                   }

{$U+}

library arglib;

mem
    NUMARG   = $005f: integer&;
    ARGLIST  = $0060: array[10] of integer;
    ARGLISTS = $0060: array[63] of char&;
    ARGTYPE  = $00a0: array[31] of char&;

var _carg: integer;

proc _argerror(e: integer);
{*************************}
{ display argument error e and stop app }
const STOP=$2010;
      NORVID   = chr($0b);  {normal video}
      INVVID   = chr($0e);  {inverse video}
mem RUNERR=$000c: integer&;
begin
    writeln;
    writeln(INVVID,'Argument error ',e,NORVID);
    RUNERR:=255;
    call(STOP)
end;

proc _agetval(var value:integer; var default:boolean);
{****************************************************}
{ get integer argument }
{ does not change value, if no argument }
begin
  case ARGTYPE[_carg] of
    'i': begin value:=ARGLIST[_carg];
           _carg:=succ(_carg); default:=false;
         end;
    'd': begin
           _carg:=succ(_carg); default:=true;
         end;
    chr(0):
         begin
           default:=true;
         end
    else _argerror(102)
  end {case}
end;

proc _agetstring(var string: array[15] of char;
  var default: boolean; var cyclus, drive: integer);
{**************************************************}
{ get string argument }
{ set string to blank if no argument }
var i: integer;
    dummy: boolean;
begin
  case ARGTYPE[_carg] of
    's': begin
           for i:=0 to 15 do
             string[i]:=ARGLISTS[2 *_carg + i];
           _carg:=_carg + 8;
           default:=false;
         end;
    'd': begin
           string:='                ';
           default:=true; _carg:= succ(_carg);
         end;
    chr(0):
         begin
           string:='                ';
           default:=true;
         end
    else _argerror(101)
  end {case}
  _agetval(cyclus,dummy);
  _agetval(drive,dummy);
end;

func option(opt:char):boolean;
{****************************}
{ check and set option }
var i,dummy,savecarg:integer;
    options:array[15] of char;
    default:boolean;
begin
  savecarg:=_carg; { save for next call to option }
  _agetstring(options,default,dummy,dummy);
  option:=false;
  if not default then begin
    if options[0]<>'/' then _argerror(103);
    for i:=1 to 15 do
      if options[i]=opt then option:=true;
  end;
  _carg:=savecarg;
end;

begin {main}
{**********}
  _carg:=0;
end.



