////////////////////////////////////////////////////////////////////////////////
// Copyright (C) 1999-2008 Easics NV.
// This source file may be used and distributed without restriction
// provided that this copyright statement is not removed from the file
// and that any derivative work contains the original copyright notice
// and the associated disclaimer.
//
// THIS SOURCE FILE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
// OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
// WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
//
// Purpose : synthesizable CRC function
//   * polynomial: x^7 + x^3 + 1
//   * data width: 1
//
// Info : tools@easics.be
//        http://www.easics.com
////////////////////////////////////////////////////////////////////////////////
module CRC7_D1
(
	input new_data,
	input [6:0] curr_crc,
	output [6:0] new_crc
);

  // polynomial: x^7 + x^3 + 1
  // data width: 1
  // convention: the first serial bit is D[0]
  

  function [6:0] nextCRC7_D1;

    input Data;
    input [6:0] crc;
    reg [0:0] d;
    reg [6:0] c;
    reg [6:0] newcrc;
  begin
    d[0] = Data;
    c = crc;

    newcrc[0] = d[0] ^ c[6];
    newcrc[1] = c[0];
    newcrc[2] = c[1];
    newcrc[3] = d[0] ^ c[2] ^ c[6];
    newcrc[4] = c[3];
    newcrc[5] = c[4];
    newcrc[6] = c[5];
    nextCRC7_D1 = newcrc;
  end
  endfunction
  assign new_crc = nextCRC7_D1(new_data, curr_crc);
endmodule

