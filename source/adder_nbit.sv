// $Id: $
// File name:   adder_nbit.sv
// Created:     1/21/2018
// Author:      Peiyuan Li
// Lab Section: 337-02
// Version:     1.0  Initial Design Entry
// Description: addernbit
`timescale 1ns / 100ps
module adder_nbit
 #(
   //parameter decleration
  parameter BIT_WIDTH = 4  
   )
   (
    //port decleration
    input wire 	[(BIT_WIDTH - 1) : 0] a,
    input wire 	[(BIT_WIDTH - 1) : 0] b,
    input wire 	carry_in,
   
    output wire [(BIT_WIDTH - 1) : 0] sum,
    output wire overflow
    );
   
   wire [(BIT_WIDTH) : 0] carrys;
   genvar 		  i;
   assign carrys[0] = carry_in;
   generate
      for(i = 0; i <= (BIT_WIDTH - 1); i = i + 1)
	begin
	   adder_1bit IX (.a(a[i]), .b(b[i]), .carry_in(carrys[i]), .sum(sum[i]), .carry_out(carrys[i + 1]));
	end
      endgenerate
   assign overflow = carrys[BIT_WIDTH];

   int z;
   
   always @ (a,b,carry_in)
     begin
	for (z = 0; z < BIT_WIDTH; z = z + 1) begin
	assert(a[z] == 1'b1 || (a[z] == 1'b0))
	  else $error("Input 'a' of component is not a digital logic value");
	   assert(b[z] == 1'b1 || (b[z] == 1'b0))
	       else $error("Input 'b' of component is not a digital logic value");
	end
	assert(carry_in == 1'b1 || (carry_in == 1'b0))
	       else $error("Input 'carry_in' of component is not a digital logic value");
	
     end

  

   always @ (a, b, carry_in)
     begin
       #(2) assert((a + b + carry_in) == {overflow, sum})
         else $error("Output 's' is not correct");
         end

   endmodule
   
   
