`include "VG_ROM_8x18.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: Rana & Co.
// Engineer: K. Saldanha
// 
// Create Date:    07:54:36 02/26/2016 
// Design Name:    Sigmoid
// Module Name:    sigmoid 
// Project Name: Sigmoid
// Target Devices: Numato Mimas, Spartan 6
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments:in case of failure ,gently apply capacitor
//                      and DARE you contact me
//////////////////////////////////////////////////////////////////////////////////
module sigmoid_combinational(
    input [17:0] x1,
    output reg signed [47:0] fixed_op
//	 output reg [2:0] test
    );

wire [17:0]  dout1,dout2;
reg [17:0] n1,n2;
reg [1:0] addr;
reg pos,sign;
reg signed [47:0] temp1;
reg [17:0] x_abs;
reg signed [47:0] temp2;
//Instantiate the ROM 
VG_ROM_8x18 my_rom(
	.addr(addr),
	.dout1(dout1),
	.dout2(dout2)
	);

always@(*) begin
//sign_magnitude_precision format
	
	x_abs={1'b0,x1[16:0]}; 
	n1=18'b0_0001_1001100110011;   //binary shit represents +1.6
	n2=18'b0_1000_0000000000000;   //binary shit represents +8.0
	//check sign of input x1
	if(x1[17]==0)
		pos=1;//x1 is positive
	else
		pos=0;
		
		/*Region 2:|x|<1.6    */
		if(x_abs[16:0]< n1[16:0])
			begin 
		
			addr=2'b10;
//			test=3'b010;
			temp1=(x_abs*dout1)>>13;//convert back to original fixed point format
			temp2=(temp1+dout2);
			if(pos==1)
				fixed_op=temp2;
			else
				fixed_op=18'b0_0001_0000000000000-temp2;
			end 
	
		/*Region 3:1.6 < x < 8   and Region1:-1.6 > x > -8*/
		else if(x_abs[16:0]>=n1[16:0] && x_abs[16:0]<n2[16:0])
			begin
			
			addr=2'b11;
//			test=3'b011;
			temp1=(x_abs*dout1)>>13;
			temp2=(temp1+dout2);
			if(pos==1)
				fixed_op=temp2;
			else
				fixed_op=18'b0_0001_0000000000000-temp2;
			end 
		/* Region4:x > 8  and Region 0:x < -8  */
		else if( x_abs[16:0]>=n2[16:0] )
			begin
		
			addr=2'b00;
//			test=3'b000;
			if(pos==1)
				fixed_op=8192;
			else
				fixed_op={48'b00};
			end
		else begin
			addr = 2'b01;
//			test=3'b101;
			fixed_op=48'bx;
		end
	
	//calculate c1*|x| + c2 i.e. sigmoid value 
end 

endmodule
