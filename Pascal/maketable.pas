{ maketable -                        }
{ make a table of real numbers for   }
{ display with graph                 }
{   fsize: number of real elements   }
{   fu: function used to make table  }
{                                    }
{   rricharz 2019 to test ralib      }

{ the example makes a fading   sine  }

program maketable;
uses syslib,ralib,mathlib;

const fsize=256;

var f:file;
    i,bsize:integer;
    fading:real;
    ch:char;

func fu1(i:integer):real;
var x:real;
begin
  x:=8.0*360.0*conv(i)/conv(fsize);
  fu1:=sin(x)*fading;
  fading:=0.99*fading;
end;

func fu2(i:integer):real;
var x:real;
begin
  x:=4.0*conv(i)/conv(fsize)-2.0;
  fu2:=exp(x);
end;

func fu3(i:integer):real;
var x:real;
begin
  x:=4.0*conv(i+1)/conv(fsize);
  fu3:=ln(x);
end;

func fu4(i:integer):real;
var x:real;
begin
  x:=4.0*conv(i)/conv(fsize)-2.0;
  fu4:=exp(-x*x);
end;

begin

  fading:=1.0;

  f:=attach('TABLE:X         ',0,1,fnew,
    4*fsize,0,'X');
  bsize:=getsize;
  writeln('Table opened, bsize=',
    bsize,' bytes');

  repeat
    writeln('Select a function:');
    writeln('1: fading sine wave');
    writeln('2: exponential exp(x)');
    writeln('3: natural logarithm');
    writeln('4: gaussian function');
    read(@key,ch);
  until (ch>='1') and (ch<='4');

  writeln;
  for i:=0 to fsize-1 do begin
    write('.');
    case ch of
     '1': putreal(f,i,fu1(i));
     '2': putreal(f,i,fu2(i));
     '3': putreal(f,i,fu3(i));
     '4': putreal(f,i,fu4(i))
     end;
  end;

  close(f);
  writeln;
  writeln('Table written');

end. 