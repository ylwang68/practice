`include "defines1.v"

module pc_reg(

     input wire       clk,
	 input wire       rst,
	 
	 //来自控制模块的信息
	 input wire[5:0] stall,
	 
	 //来自译码阶段 是否转移
	 input wire      branch_flag_i, //转移标志
	 input wire[`RegBus] branch_target_address_i, //转移地址
	 
	 output reg[`InstAddrBus]  pc,
	 output reg       ce

);

    always @ (posedge clk) begin
	    if (ce == `ChipDisable) begin
		    pc <= 32'h00000000;
		end else if(stall[0] == `NoStop) begin
		    if(branch_flag_i == `Branch) begin
			   pc <= branch_target_address_i;
			end else begin
		    pc <= pc + 4'b4;
		    end
	end
	
	always @ (posedge clk) begin
	    if (rst == `RstEnable) begin
		    ce <= `ChipDisable;
		end else begin
		    ce <= `ChipEnable;
		end
	end
	
endmodule