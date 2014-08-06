//////////////////////////////////////////////////////////////////////////////
//
// FILE NAME: DDR_CONTROLLER.SV
//
// AUTHOR: Jeff Nguyen
//
// DATE CREATED: 08/03/2014
//
// DESCRIPTION:  The module implements fsm to control between initialization,
//               read/write, refresh, and update.
// 
///////////////////////////////////////////////////////////////////////////////                       

`include "ddr_package.pkg"

module DDR_CONTROLLER (DDR_INTF intf,
                       CTRL_INTF ctrl_intf,
                       input logic mrs_update,[1:0] mrs_bl, 
                       output logic dev_busy);
                       //input logic config_done,
                       //input logic rw_idle,
                       //input logic mrs_update,[1:0] mrs_bl,  //from sim model
                       //input mode_register_type mr0,
                       //output logic rw_proc,    //start read/write 
                       //output logic dev_busy,   //connect to sim to stop data.
                       //output logic refresh_rdy, 
                       //output logic mrs_update_rdy, 
                       //output mode_register_type mrs_update_cmd);       
                       
ctrl_fsm_type ctrl_state, ctrl_next_state;
  
int   refresh_counter;
logic clear_counter, refresh_almost,refresh_done;
 
int   update_counter;
logic clear_update_counter, update_done;

assign  dev_busy = (ctrl_state == CTRL_RW)? 1'b0: 1'b1;
  
//fsm ddr controller
always_ff @(posedge intf.clock_t, negedge intf.reset_n)
begin
  if (!intf.reset_n) 
     ctrl_state <= CTRL_IDLE;
  else 
     ctrl_state <= ctrl_next_state;
end
   
   
//next state generate logic
//
always_comb
begin
   case (ctrl_state)
   CTRL_IDLE: begin
      clear_counter            <= 1'b1;
      ctrl_intf.mrs_update_rdy <= 1'b0;
      clear_update_counter     <= 1'b1;
      ctrl_intf.rw_proc        <= 1'b0;
      if (intf.reset_n)
         ctrl_next_state    <= CTRL_INIT;
      end   
            
   CTRL_INIT: begin  
      clear_counter <= 1'b1;
      if(ctrl_intf.config_done)
         ctrl_next_state  <= CTRL_RW;
         ctrl_intf.rw_proc<= 1'b1;
      end
           
   CTRL_RW: begin
      clear_counter <= 1'b0;    // assume refresh occurs only rw, and update
      if ((mrs_update) || (refresh_almost))
         ctrl_next_state    <= CTRL_WAIT;    
         ctrl_intf.rw_proc  <= 1'b0;                    
      end
           
   CTRL_WAIT: begin
      if (ctrl_intf.rw_idle) begin
         if (refresh_almost)
            ctrl_next_state <= CTRL_REFRESH;
         else begin
            ctrl_intf.mrs_update_rdy  <= 1'b1;
            //copy MR0 from burst_conf and update burst length
            ctrl_intf.mrs_update_cmd <= {ctrl_intf.mr0[MRS_WIDTH -1:2],mrs_bl};
            ctrl_next_state <= CTRL_UPDATE;  
         end
      end
   end
               
   CTRL_UPDATE: begin
      ctrl_intf.mrs_update_rdy       <= 1'b0;
      clear_update_counter           <= 1'b0;
      if (update_done) begin
         ctrl_next_state    <= CTRL_RW;
         clear_update_counter <= 1'b1;
      end
   end
           
   CTRL_REFRESH: begin
      if (refresh_done)
         ctrl_next_state   <= CTRL_RW;
         ctrl_intf.rw_proc <= 1'b1;
      end
             
   default: ctrl_next_state <= CTRL_IDLE;
          
   endcase
end             
              
      // simple counter 
    always_ff @(posedge intf.clock_t, posedge intf.reset_n)
    begin
       if(clear_counter == 1'b1) begin
          refresh_counter      <= 0;
          refresh_almost       <= 1'b0;
          ctrl_intf.refresh_rdy<= 1'b0;
          refresh_done         <= 1'b0;
          end
       else begin
          refresh_counter <= refresh_counter + 1;
          if (refresh_counter == tREF - 100) 
             refresh_almost <= 1'b1;
          else if (refresh_counter == tREF)
             ctrl_intf.refresh_rdy <= 1'b1;
          else if (refresh_counter == tREF + 1)
             ctrl_intf.refresh_rdy <= 1'b0;   
          else if (refresh_counter == tREF + tRC)
             refresh_done    <= 1'b1;
          end        
     end 
      
       // simple act_counter 
    always_ff @(posedge intf.clock_t, posedge intf.reset_n)
    begin
       if(clear_update_counter == 1'b1) begin
          update_done    <= 1'b0;
          update_counter <= 0;
          end
       else begin
          update_counter <= update_counter + 1;
          if (update_counter == tMOD) 
             update_done  <= 1'b1;
          end                            
    end

endmodule