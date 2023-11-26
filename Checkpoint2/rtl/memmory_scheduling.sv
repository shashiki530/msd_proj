
module parsing_tb#(parameter ENABLE_TEST=0, ENABLE_FULL=0);
int file_read;   // file handler for read
int file_write;  // to write into output trace file
int read_value; 
int  time_unit;
logic [11:0] core;
logic [1:0] operation;
logic [35:0] address;
string line;
string input_file, output_file;
longint unsigned time_t=1;
// full & empty conditions
int full_qu, empty_qu;
int simulation_t;
// Bounded queue
logic [37:0] q_memctrl[$:15];
longint unsigned q_time[$];
int q_oper[$];
logic [35:0] q_addr[$];
logic [37:0] output_data,temp;
//counter
int count;
always #1 time_t = time_t + 1;

// Parsing input trace file
task parsing();
   int i; read_value=0;
    $display("Reading and printing values from input trace file");
     
    if($value$plusargs("input_file=%s",input_file))begin
      //Read a input trace file through command line
      file_read =$fopen(input_file,"r");
      if(file_read == 0) begin
	 if(ENABLE_TEST) 
           $display("trace file not found read");
      end        
        while (1) begin
          // Read values from the file		
          read_value = $fscanf(file_read, "%d %d %d %h", time_unit, core, operation, address);
	  if(core>=12 || operation >=3) begin 
            $display(" Trace file has out of bound values");
	    $finish;
	  end
          if (read_value == 4) begin
            if(ENABLE_TEST) $display("the value of time=%d, core=%12d, operation=%h, address=%h ", time_unit, core, operation, address); 
            q_oper.push_back(operation);
	   q_addr.push_back(address);
	   q_time.push_back(time_unit);
          i++;
          end
          
        else begin
          break; // exit after the last line
        end
       //end
                        
      end
      $fclose(file_read);      
    end
    else begin
      $display("error :please provide the input file using +input_file=<filename>");
    end
    $display("End of Parsing task");
  
endtask
//Push each element to master queue
task mem_ctrl_store(); 
     temp = {q_oper.pop_front(), q_addr.pop_front()};
   q_memctrl.push_back(temp);
   if(ENABLE_TEST) $display(" %t \t  Push new item to master queue(memctrl) queue=%h, time_t=%d, memctrl_q_size=%d", $time, temp,time_t,q_memctrl.size);
endtask

// pop out each element from master queue
task toggle_out_from_memctrl_q();
   output_data= q_memctrl[0];
   foreach(q_memctrl[i]) $display("\t MASTER QUEUE [%0h] = %h",i,q_memctrl[i]);    
   if(output_data) begin
     if(ENABLE_TEST) 
       $display(" output_data=%0h", output_data);
   end
   output_cmd_format(output_data);
   q_memctrl.pop_front();
    if(output_data || (output_data==0)) begin 
      if(ENABLE_TEST) 
       $display(" %t Pop out item from queue output_data =%h, time_t=%d, q_mem_ctrl_size=%d \n", $time,output_data,time_t,q_memctrl.size());
    end
   count++;
 endtask

// Address decoding 
task output_cmd_format(input [37:0] output_data);
 if(ENABLE_TEST) begin
      file_write=$fopen("dram.txt","a");// opening file in append mode
     if(file_write!=0) begin
       if(output_data[37:36] ==0 || output_data[37:36]==2) begin 
   
        
      $display("\t\t\t -----------Read operation-------------------Operation=%d---------", output_data[37:36]);
	 

      $display(" %t \t channel=%d, ACT0 bank_group=%d, bank=%d, row=%d", $time, output_data[6],output_data[9:7],output_data[11:10],output_data[33:18]);
      $fwrite(file_write," %t \t %d ACT0 %d %d %d\n", $time, output_data[6],output_data[9:7],output_data[11:10],output_data[33:18]);

      $display(" %t \t channel=%d, ACT1 bank_group=%d, bank=%d, row=%d", $time, output_data[6],output_data[9:7],output_data[11:10],output_data[33:18]);
       $fwrite(file_write," %t \t %d ACT1 %d %d %d\n", $time, output_data[6],output_data[9:7],output_data[11:10],output_data[33:18]);

      $display(" %t \t channel=%d, RD0 bank_group=%d, bank=%d, column=%d", $time, output_data[6],output_data[9:7],output_data[11:10],output_data[17:12]);
      $fwrite(file_write," %t \t %d RD0 %d %d %d\n", $time, output_data[6],output_data[9:7],output_data[11:10],output_data[17:12]);

      $display(" %t \t channel=%d, RD1 bank_group=%d, bank=%d, column=%d", $time, output_data[6],output_data[9:7],output_data[11:10],output_data[17:12]);
      $fwrite(file_write," %t \t %d RD1 %d %d %d\n", $time, output_data[6],output_data[9:7],output_data[11:10],output_data[17:12]);

      $display(" %t \t channel=%d, PRE bank_group=%d, bank=%d", $time, output_data[6],output_data[9:7],output_data[11:10]);
       $fwrite(file_write," %t \t %d PRE %d %d\n", $time, output_data[6],output_data[9:7],output_data[11:10]);

    end

    if(output_data[37:36]==1) begin

 

      $display("\t\t\t -----------Write operation----------Operation=%d-------", output_data[37:36]);
      

      $display(" %t \t channel=%d, ACT0 bank_group=%d, bank=%d, row=%d", $time, output_data[6],output_data[9:7],output_data[11:10],output_data[33:18]);
      $fwrite(file_write," %t \t %d ACT0 %d  %d =%d\n", $time, output_data[6],output_data[9:7],output_data[11:10],output_data[33:18]);

      $display(" %t \t channel=%d, ACT1 bank_group=%d, bank=%d, row=%d", $time, output_data[6],output_data[9:7],output_data[11:10],output_data[33:18]);
 	$fwrite(file_write," %t \t %d ACT1 %d %d %d\n", $time, output_data[6],output_data[9:7],output_data[11:10],output_data[33:18]);

      	$display(" %t \t channel=%d, WR0 bank_group=%d, bank=%d, column=%d", $time, output_data[6],output_data[9:7],output_data[11:10],output_data[17:12]);
     	 $fwrite(file_write," %t \t %d WR0 %d %d %d\n", $time, output_data[6],output_data[9:7],output_data[11:10],output_data[17:12]);

     	 $display(" %t \t channel=%d, WR1 bank_group=%d, bank=%d, column=%d", $time, output_data[6],output_data[9:7],output_data[11:10],output_data[17:12]);
	 $fwrite(file_write," %t \t %d WR1 %d %d %d\n", $time, output_data[6],output_data[9:7],output_data[11:10],output_data[17:12]);

     	 $display(" %t \t channel=%d, REF bank_group=%d, bank=%d", $time, output_data[6],output_data[9:7],output_data[11:10]);
	$fwrite(file_write," %t \t %d REF %d %d\n", $time, output_data[6],output_data[9:7],output_data[11:10]);

    end
$fclose(file_write);
  end else begin
   $display("error opening the file to write");
end 
end 

endtask

always@(time_t) begin
  if((full_qu == 0) && (q_time.size()!=0)) begin
    simulation_t=q_time.pop_front();
  wait(simulation_t<= time_t);
    $display("simulation_t=%d, time_t=%d", simulation_t, time_t);
    mem_ctrl_store();
 end
end

always@(time_t) begin
  if((ENABLE_FULL == 0) && (q_memctrl.size()!=0)) begin
   if(time_t % 2 == 0) toggle_out_from_memctrl_q(); 
end
  end

always@(time_t) begin
  if(q_memctrl.size() == 0) begin 
    empty_qu =1; 
  end
  else empty_qu =0;
  if(q_memctrl.size == 15) begin
    full_qu=1;
     $display(" memory controller queue is full");
   //q_memctrl.delete();
  end
  else full_qu =0;
end
 

initial begin
  parsing();
end

initial begin
time_t=0;
#1200 $finish;
end
endmodule

