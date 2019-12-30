program hilbert;
  {plot Hilbert curves of orders 1 to n}
  {adapted from N. Wirth,}
  { Algorithms+Data Structures=Programs,p132}
  {76/11/18.  JFM.}
  {adapted to P8 using devput, 79/07/10  JFM}
  {adapted to P8RTS using TEK:, 81-12-06 JTE}
  {adapted to R65 Pascal, 2019/12/30 RR }

  const
    {place in center of tek 4015 - 1 scope}
    xoffset = 256 ;
    yoffset = 128;
    h0 = 512    {size factor - -  power of 2};
    {character codes for plotting}
    sp = 32     {ascii space};
    gs = 29     {ascii gs};
    bq = 96     {ascii back - quote};
    at = 64     {ascii at - sign};
    esc= 27     {ascii escape};
    ff = 12     {ascii form feed};
    cr = 13     {ascii carriage return};

    tek = @1;

  var
    i, h, x, y, x0, y0, n : integer;
    erase : boolean;

  proc startplot {clear the screen};
  begin
    write(@tek,chr(17)); { raw mode }
    write(@tek,chr(esc),chr(ff))
  end;

  proc plot {plot a vector};
  begin
    write(@tek,
      chr(sp + (y + yoffset) div 32),
      chr(bq + (y + yoffset) and 31),
      chr(sp + (x + xoffset) div 32),
      chr(at + (x + xoffset) and 31))
  end {plot};

  proc move;
  {move the pen to (x,y) - -  dark vector}
  begin write(@tek, chr(gs)); plot end{move};

  proc endplot {leave graph mode};
  begin
    write(@tek, chr(cr))
    write(@tek,chr(18)); { end raw mode }
  end {endplot};

  proc b(i: integer); forward;
  proc c(i: integer); forward;
  proc d(i: integer); forward;

  proc a(i: integer);
  begin
    writeln('a(',i,')');
    if i > 0 then
      begin
        d(i - 1); x := x - h; plot;
        a(i - 1); y := y - h; plot;
        a(i - 1); x := x + h; plot;
        b(i - 1)
      end
  end {a};

  proc b(i: integer);
  begin
    writeln('b(',i,')');
    if i > 0 then
      begin
        c(i - 1); y := y + h; plot;
        b(i - 1); x := x + h; plot;
        b(i - 1); y := y - h; plot;
        a(i - 1)
      end
  end {b};

  proc c(i: integer);
  begin
    writeln('c(',i,')');
    if i > 0 then
      begin
        b(i - 1); x := x + h; plot;
        c(i - 1); y := y + h; plot;
        c(i - 1); x := x - h; plot;
        d(i - 1)
      end
  end {c};

  proc d(i: integer);
  begin
    writeln('d(',i,')');
    if i > 0 then
      begin
        a(i - 1); y := y - h; plot;
        d(i - 1); x := x - h; plot;
        d(i - 1); y := y + h; plot;
        c(i - 1)
      end
  end {d};

begin {Hilbert}
  write('enter n of levels: ');
  read(n);
  erase := n<0;
  if erase then n :=  - n;
  startplot;
  i := 0;   h := h0;
  x0 :=  h div 2; y0 := x0;
  if erase then
    while i < n - 1 do
      begin
        i := i + 1;
        h := h div 2;
        x0 := x0 + (h div 2);
        y0 := y0 + (h div 2)
      end;
  repeat
    {plot Hilbert curve of order i + 1}
    i := i + 1;
    h := h div 2;
    x0 := x0 + (h div 2);
    y0 := y0 + (h div 2);
    x := x0;   y := y0;   move;
    writeln('i=',i,', h=',h,' ,x=',x,
    ', y=',y);
    a(i)
  until i = n;
  endplot
end {Hilbert}.
