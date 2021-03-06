//////////////////////////////////////////////////////////////////////////////
//
// FILE NAME: BURST_CONF.SV
//
// AUTHOR: Jeff Nguyen
//
// DATE CREATED: 08/03/2014
//
// DESCRIPTION:  The module implements fsm to control sequence for DDR4 
//  Initialization
//  Refer data sheet for details
//
// Note: use clock_t as main clock
// 
///////////////////////////////////////////////////////////////////////////////                       

`include "ddr_package.pkg"

module BURST_CONF (DDR_INTERFACE intf,
                   CTRL_INTERFACE ctrl_intf);
                   
parameter tCCD        = 4;
parameter tCAS_W      = 10;
parameter tCAS_R      = 13;
parameter W_PRE       = 1'b1;
parameter R_PRE       = 1'b1;
parameter BURST_LENGTH= 2'b00;
parameter AL_DLY      = 2'b00;

bit [2:0] cas, wr;
bit [3:0] rd;


//use always block to init the sequence any time reset asserted.
always@ (intf.reset_n)
begin
   if(!intf.reset_n)
      init_task();
end

//sequence of initialization 

task init_task ();
   intf.cke  <= 1'b0;
   ctrl_intf.mrs_rdy   		<= 1'b0;
   ctrl_intf.des_rdy   		<= 1'b0;
   ctrl_intf.zqcl_rdy  		<= 1'b0;
   ctrl_intf.config_done 	<= 1'b0;
   
   wait (intf.reset_n); repeat (tCKE_L - tIS) @(posedge intf.clock_t);
   intf.cke 				<= 1'b1;
   $cast(cas,(tCCD   -4));
   $cast(wr, (tCAS_W -9));
   $cast(rd, (tCAS_R -9));
   
   //DES
   repeat (tIS) @(posedge intf.clock_t);
   ctrl_intf.des_rdy 		<= 1'b1;
   ctrl_intf.mode_reg 		<= 'x;
   
   //MR3
   repeat (tXPR) @(posedge intf.clock_t);
   ctrl_intf.des_rdy 		<= 1'b0;
   ctrl_intf.mrs_rdy 		<= 1'b1;
   ctrl_intf.mode_reg 		<= {1'b0,3'b011,2'b00,2'b0,2'b00,3'b000,1'b0,1'b0,1'b0,1'b0,2'b00};
   @(posedge intf.clock_t);
   ctrl_intf.mrs_rdy 		<= 1'b0; 
   ctrl_intf.des_rdy 		<= 1'b1;
   ctrl_intf.mode_reg  		<= 'x;
   
   //MR6
   repeat (tMRD) @(posedge intf.clock_t); ctrl_intf.mrs_rdy <= 1'b1; 
   ctrl_intf.des_rdy 		<= 1'b0;
   ctrl_intf.mode_reg 		<= {1'b0,3'b110,1'b0,1'b0,cas,1'b0,1'b0,1'b0,1'b0,6'b000000};
   @(posedge intf.clock_t);
   ctrl_intf.mrs_rdy 		<= 1'b0; 
   ctrl_intf.des_rdy 		<= 1'b1;
   ctrl_intf.mode_reg 		<= 'x;
   
   // MR5
   repeat (tMRD) @(posedge intf.clock_t); ctrl_intf.mrs_rdy <= 1'b1; 
   ctrl_intf.des_rdy 		<= 1'b0;
   ctrl_intf.mode_reg 		<= {1'b0,3'b101,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,3'b000,1'b0,1'b0,1'b0,3'b000};
   @(posedge intf.clock_t); 
   ctrl_intf.mrs_rdy 		<= 1'b0; 
   ctrl_intf.des_rdy 		<= 1'b1;
   ctrl_intf.mode_reg 		<= 'x;
   
   //MR4
   repeat (tMRD) @(posedge intf.clock_t); ctrl_intf.mrs_rdy <= 1'b1; 
   ctrl_intf.des_rdy 		<= 1'b0;
   ctrl_intf.mode_reg 		<= {1'b0,3'b100,1'b0,1'b0,W_PRE,R_PRE,1'b0,1'b0,3'b000, 1'b0,1'b0,1'b0,1'b0,1'b0,1'b0};
   @(posedge intf.clock_t);
   ctrl_intf.mrs_rdy 		<= 1'b0; 
   ctrl_intf.des_rdy 		<= 1'b1;
   ctrl_intf.mode_reg 		<= 'x;
   
   //MR2
   repeat (tMRD) @(posedge intf.clock_t); ctrl_intf.mrs_rdy <= 1'b1; 
   ctrl_intf.des_rdy 		<= 1'b0;
   ctrl_intf.mode_reg 		<= {1'b0,3'b010,1'b0,1'b0,1'b0,1'b0,2'b00,1'b0,2'b00,wr,3'b000};
   @(posedge intf.clock_t);
   ctrl_intf.mrs_rdy 		<= 1'b0; 
   ctrl_intf.des_rdy 		<= 1'b1;
   ctrl_intf.mode_reg 		<= 'x;
   
   //MR1
   repeat (tMRD) @(posedge intf.clock_t); ctrl_intf.mrs_rdy <= 1'b1; 
   ctrl_intf.des_rdy 		<= 1'b0;
   ctrl_intf.mode_reg 		<= {1'b0,3'b001,1'b0,1'b0,1'b0,1'b0,3'b000,1'b0, 2'b00,AL_DLY,2'b00,1'b1};
   @(posedge intf.clock_t); 
   ctrl_intf.mrs_rdy 		<= 1'b0; 
   ctrl_intf.des_rdy 		<= 1'b1;
   ctrl_intf.mode_reg 		<= 'x;
   
   //MR0
   repeat (tMRD) @(posedge intf.clock_t); 
   ctrl_intf.mrs_rdy 		<= 1'b1; 
   ctrl_intf.des_rdy 		<= 1'b0;
   ctrl_intf.mode_reg 		<= {1'b0,3'b000,1'b0,1'b0,1'b0, 3'b000, 1'b0,1'b0,rd[3:1],1'b0,rd[0],BURST_LENGTH};
   ctrl_intf.mr0 			<= {1'b0,3'b000,1'b0,1'b0,1'b0, 3'b000, 1'b0,1'b0,rd[3:1],1'b0,rd[0],BURST_LENGTH};          
   @(posedge intf.clock_t);
   ctrl_intf.mrs_rdy 		<= 1'b0; 
   ctrl_intf.des_rdy 		<= 1'b1;
   ctrl_intf.mode_reg 		<= 'x;
   
   //ZQCL
   repeat (tMOD) @(posedge intf.clock_t); ctrl_intf.des_rdy <= 1'b0; 
   ctrl_intf.zqcl_rdy 		<= 1'b1;
   ctrl_intf.mode_reg 		<= '1;
   
   
   @(posedge intf.clock_t); ctrl_intf.zqcl_rdy <= 1'b0; 
   ctrl_intf.des_rdy 		<= 1'b1;
   ctrl_intf.mode_reg 		<= 'x;
   repeat (tZQ) @(posedge intf.clock_t); 
   ctrl_intf.config_done 	<= 1'b1; 
   ctrl_intf.des_rdy 		<= 1'b0;
endtask
                 
endmodule
