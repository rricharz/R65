{ ********************************************
  * LADDERS3 - 3rd level of the ladders game *
  ********************************************

  uses a horizontally scrolling world           }

program ladders3;
uses plotlib;

begin
  _grinit;
  _cleargr;
  _move(2,YSIZE-10);
  write(@PLOTDEV,'LADDERS LEVEL 3');
end.
