{  hex converter                               }
{  Input decimal, hex or binary numbers        }
{  Output decimal, hex and binary              }
{  Decimal output is signed and unsigned word  }
{  For syntax type hex without arguments       }
{                                              }
{  Original version by rricharz for PDP-11     }
{  rricharz 2019 for R65 Pascal                }

program hex;
uses syslib, arglib;

var number:  integer;
    str:     array[40] of char;
    errflag: boolean;

  proc readline;
  var ch: char;
      i: integer;
  begin
    i := 0;
    repeat
      read(@input,ch);
      if i = 40 then ch := cr;
      str[i] := uppercase(ch);
      i := i + 1;
    until (ch = cr);
  end;

  proc inputerror(c: char; s: array[7] of char);
  var i: integer;
  begin
    write(invvid,'Illegal character ',c, ' ');
    for i := 0 to 7 do write(s[i]);
    writeln(norvid);
    writeln;
    writeln('Input examples:');
    writeln('123');
    writeln('+256');
    writeln('-500');
    writeln('$2FFF');
    writeln('%0101111');
    errflag := true;
  end;

  proc overflow;
  begin
    writeln(invvid,
        'Overflow (number too large)',norvid);
    errflag :=true;
  end;

  func scanstr: integer;

  var
    i:            integer;
    base:         integer;
    digit:        integer;
    topdigit:     char;
    negative:     boolean;
    result:       integer;
  begin
    i        := 0;
    base     := 10;
    topdigit := '9';
    negative := false;
    result   := 0;
    errflag  := false;

    if str[i]='+' then
      i := i + 1
    else if str[i] = '-' then
      begin
        negative := true;
        i := i + 1;
      end
    else if str[i] = '$' then
      begin
        base := 16;
        topdigit := 'F';
        i := i + 1;
      end
    else if str[i] = '%' then
      begin
        base := 2;
        topdigit := '1';
        i := i + 1;
      end;
    while (str[i]>='0') and (str[i]<=topdigit)
               and (i < 40) and not errflag do
      begin
        if str[i] > '9' then
          begin
            if base <= 10 then
              inputerror(str[i],'no digit');
            if (str[i]<'A') then
              inputerror(str[i],'not hex ');
            digit := ord(str[i]) - ord('A') + 10
          end
        else
          digit := ord(str[i]) - ord('0');
        if base = 10 then
          begin
            if result <= 3276 then
              begin
                result := base * result;
                if result > (32767-digit+1) then
                  overflow
                else
                  result:=result + digit;
              end
            else
              overflow;
          end
        else if base = 16  then
          begin
            if result < 4096 then
              result := result shl 4 + digit
            else
              overflow;
          end
        else
          begin
            if result >= 0 then
              result := result shl 1 + digit
            else
              overflow;
          end;
        i := i + 1;
      end;
    if not errflag then
      begin
        if (str[i] <> cr) then
          inputerror(str[i], 'no <cr> ');
        if negative then
          result := -result;
      end;
    scanstr := result;
  end;

  proc writehex(r: integer);
  var mask, m, n, r1: integer;
  begin
    write('$');
    mask := $f000;
    n := 12;
    while mask <>0 do
      begin
        r1 := (r and mask) shr n;
        if r1 < 10 then
          write(r1)
        else
          write(chr(ord(r1) + ord('A') - 10));
        mask := mask shr 4;
        n := n - 4;
      end;
  end;

  proc writebinary(r: integer);
  var mask: integer;
  begin
    write('% ');
    mask := $8000;
    while mask <> 0 do
      begin
        if (r and mask) <> 0 then
          write('1')
        else
          write('0');
        mask := mask shr 1;
        if mask = $0800 then
          write(' ');
        if mask = $0080 then
          write(' ');
        if mask = $0008 then
          write(' ');
      end;
  end;

begin { hex }

  repeat

    write('Number (<return> to exit)? ');
    readline;
    number := scanstr;

    if (not errflag) and (str[0]<>cr) then
      begin
        writeln('Decimal: ', number);
        write('Hex:     ');
        writehex(number);
        writeln;
        write  ('Binary:  ');
        writebinary(number);
        writeln;
      end;
    until str[0] = cr
end.
