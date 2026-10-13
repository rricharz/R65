program hilbert;
  {_plot Hilbert curves of orders 1 to n}
  {adapted from N. Wirth,}
  { Algorithms+Data Structures=Programs,p132}
  {76/11/18.  JFM.}
  {adapted to P8 using devput, 79/07/10  JFM}
  {adapted to P8RTS using TEK:, 81-12-06 JTE}
  {adapted to R65 Pascal, 2019/12/30 RR }

  uses syslib,teklib;

  const
    {place in center of tek 4015 - 1 scope}
    xoffset = 256;
    yoffset = 128;
    h0 = 512    {size factor - -  power of 2};
    {character codes for plotting}
    sp = 32     {ascii space};
    gs = 29     {ascii gs};
    bq = 96     {ascii back - quote};
    at = 64     {ascii at - sign};
    esc= 27     {ascii escape};
    FF = 12     {ascii form feed};
    CR = 13     {ascii carriage return};

  var
    i, h, x, y, x0, y0, n : integer;
    erase : boolean;

  proc _plot;
  begin
    _draw(x+xoffset,y+yoffset);
  end;

  proc b(i: integer); forward;
  proc c(i: integer); forward;
  proc d(i: integer); forward;

  proc a(i: integer);
  begin
    if i > 0 then
      begin
        d(i - 1); x := x - h; _plot;
        a(i - 1); y := y - h; _plot;
        a(i - 1); x := x + h; _plot;
        b(i - 1)
      end
  end {a};

  proc b(i: integer);
  begin
    if i > 0 then
      begin
        c(i - 1); y := y + h; _plot;
        b(i - 1); x := x + h; _plot;
        b(i - 1); y := y - h; _plot;
        a(i - 1)
      end
  end {b};

  proc c(i: integer);
  begin
    if i > 0 then
      begin
        b(i - 1); x := x + h; _plot;
        c(i - 1); y := y + h; _plot;
        c(i - 1); x := x - h; _plot;
        d(i - 1)
      end
  end {c};

  proc d(i: integer);
  begin
    if i > 0 then
      begin
        a(i - 1); y := y - h; _plot;
        d(i - 1); x := x - h; _plot;
        d(i - 1); y := y + h; _plot;
        c(i - 1)
      end
  end {d};

begin {Hilbert}
  write('Number of levels (2-7)? ');
  read(n);
  if (n<2) or (n>7) then _abort;
  erase := true;
  _starttek;
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
    {_plot Hilbert curve of order i + 1}
    i := i + 1;
    h := h div 2;
    x0 := x0 + (h div 2);
    y0 := y0 + (h div 2);
    x := x0;   y := y0;
    _startdraw(x+xoffset,y+yoffset);
    a(i);
    _enddraw;
  until i = n;
  _moveto(0,0);
  _endtek;
end {Hilbert}.
