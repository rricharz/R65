{ maketable -                        }
{ make a table of real numbers for   }
{ display with graph                 }
{   fsize: number of real elements   }
{   fu: function used to make table  }
{ The first 3 entries in the table   }
{ are size, xmin and xmax            }
{                                    }
{   rricharz 2019                    }

program maketable;
uses syslib,ralib,mathlib;

const fsize=509;

var f:file;
    i,bsize:integer;
    fading:real;
    ch:char;
    xmin,xsize:real;

func fu1(i:integer):real;
var x:real;
begin
  x:=xsize*conv(i)/conv(fsize)+xmin;
  fu1:=sin(x)*fading;
  fading:=0.995*fading;
end;

func fu2(i:integer):real;
var x:real;
begin
  x:=xsize*conv(i)/conv(fsize)+xmin;
  fu2:=exp(x);
end;

func fu3(i:integer):real;
var x:real;
begin
  x:=xsize*conv(i)/conv(fsize)+xmin;
  fu3:=ln(x);
end;

func fu4(i:integer):real;
var x:real;
begin
  x:=xsize*conv(i)/conv(fsize)+xmin;
  fu4:=exp(-x*x);
end;

func fu5(i:integer):real;
var x:real;
begin
  x:=xsize*conv(i)/conv(fsize)+xmin;
  fu5:=sin(5.0*x)*sin(11.0*x);
end;

proc setlimits(l,r:real);
begin
  xmin:=l;
  xsize:=r-l;
  putword(f,0,fsize);
  putreal(f,1,l);
  putreal(f,2,r);
end;

begin

  fading:=1.0;

  f:=attach('TABLE:X         ',0,1,fnew,
    4*(fsize+3),0,'X');
  bsize:=getsize;
  writeln('Table opened, bsize=',
    bsize,' bytes');

  repeat
    writeln('Select a function:');
    writeln('1: fading sine wave');
    writeln('2: exponential exp(x)');
    writeln('3: natural logarithm');
    writeln('4: gaussian function');
    writeln('5: multiplied sine waves');
    read(@key,ch);
  until (ch>='1') and (ch<='5');

  writeln;
  case ch of
     '1': setlimits(0.0,8.0*360.0);
     '2': setlimits(-2.0,2.0);
     '3': setlimits(0.1,4.0);
     '4': setlimits(-2.0,2.0);
     '5': setlimits(0.0,360.0)
     end;

  for i:=0 to fsize-1 do begin
    write('.');
    case ch of
     '1': putreal(f,i+3,fu1(i));
     '2': putreal(f,i+3,fu2(i));
     '3': putreal(f,i+3,fu3(i));
     '4': putreal(f,i+3,fu4(i));
     '5': putreal(f,i+3,fu5(i))
     end;
  end;

  close(f);
  writeln;
  writeln('Table written');

end. 