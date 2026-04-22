import rv32i_types::*;
import cache_mux_types::*;

module p_d_cache_control 
(
  input i_clk,
  input rst_n,

  /* CPU memory signals */
  input   logic           mem_read,
  input   logic           mem_write,
  output  logic           mem_resp,

  /* Physical memory signals */
  input   logic           pmem_resp,
  output  logic           pmem_read,
  output  logic           pmem_write,

  /* Datapath to Control */
  input logic v_array_0_dataout,
  input logic v_array_1_dataout,
  input logic v_array_2_dataout,
  input logic v_array_3_dataout,

  //input cache_pipeline_control cache_pipeline_out,
  //input cache_pipeline_control cache_pipeline_in,
  
  input d_cache_pipeline_reg cache_pipeline_out,
  input d_cache_pipeline_reg cache_pipeline_in,
  
  input logic if_id_reg_load,

  /* Control to Datapath */
  output logic v_array_0_load,
  output logic v_array_0_datain,
  output logic v_array_1_load,
  output logic v_array_1_datain,
  output logic v_array_2_load,
  output logic v_array_2_datain,
  output logic v_array_3_load,
  output logic v_array_3_datain,
  output logic d_array_0_load,
  output logic d_array_0_datain,
  output logic d_array_1_load,
  output logic d_array_1_datain,
  output logic d_array_2_load,
  output logic d_array_2_datain,
  output logic d_array_3_load,
  output logic d_array_3_datain,

  output logic tag_array_0_load,
  output logic tag_array_1_load,
  output logic tag_array_2_load,
  output logic tag_array_3_load,

  output logic LRU_array_load,
  output logic [2:0] LRU_array_datain,

  output dataarraymux_sel_t write_en_0_MUX_sel,
  output dataarraymux_sel_t write_en_1_MUX_sel,
  output dataarraymux_sel_t write_en_2_MUX_sel,
  output dataarraymux_sel_t write_en_3_MUX_sel,
  output dataarraymux_sel_t data_array_0_datain_MUX_sel,
  output dataarraymux_sel_t data_array_1_datain_MUX_sel,
  output dataarraymux_sel_t data_array_2_datain_MUX_sel,
  output dataarraymux_sel_t data_array_3_datain_MUX_sel,

  output logic load_d_cache_reg,
  output logic read_array_flag,

  output paddressmux_sel_t address_mux_sel,
  output logic [1:0] dataout_MUX_sel,
  output pmemaddressmux_sel_t pmem_address_MUX_sel
);

/*logic v_array_0_load;
logic v_array_0_datain;
logic v_array_1_load;
logic v_array_1_datain;
logic v_array_2_load;
logic v_array_2_datain;
logic v_array_3_load;
logic v_array_3_datain;
logic d_array_0_load;
logic d_array_0_datain;
logic d_array_1_load;
logic d_array_1_datain;
logic d_array_2_load;
logic d_array_2_datain;
logic d_array_3_load;
logic d_array_3_datain;

logic tag_array_0_load;
logic tag_array_1_load;
logic tag_array_2_load;
logic tag_array_3_load;

logic LRU_array_load;
logic [2:0] LRU_array_datain;

dataarraymux_sel_t write_en_0_MUX_sel;
dataarraymux_sel_t write_en_1_MUX_sel;
dataarraymux_sel_t write_en_2_MUX_sel;
dataarraymux_sel_t write_en_3_MUX_sel;
dataarraymux_sel_t data_array_0_datain_MUX_sel;
dataarraymux_sel_t data_array_1_datain_MUX_sel;
dataarraymux_sel_t data_array_2_datain_MUX_sel;
dataarraymux_sel_t data_array_3_datain_MUX_sel;

logic load_d_cache_reg;
logic read_array_flag;

paddressmux_sel_t address_mux_sel;
logic [1:0] dataout_MUX_sel;
pmemaddressmux_sel_t pmem_address_MUX_sel;*/

function void set_defaults();
  /* CPU memory signals */
  mem_resp = 1'b0;

  /* Physical memory signals */
  pmem_read = 1'b0;
  pmem_write = 1'b0;

  /* Control to Datapath */
  v_array_0_load = 1'b0;
  v_array_0_datain = 1'b0;
  v_array_1_load = 1'b0;
  v_array_1_datain = 1'b0;
  v_array_2_load = 1'b0;
  v_array_2_datain = 1'b0;
  v_array_3_load = 1'b0;
  v_array_3_datain = 1'b0;

  d_array_0_load = 1'b0;
  d_array_0_datain = 1'b0;
  d_array_1_load = 1'b0;
  d_array_1_datain = 1'b0;
  d_array_2_load = 1'b0;
  d_array_2_datain = 1'b0;
  d_array_3_load = 1'b0;
  d_array_3_datain = 1'b0;

  tag_array_0_load = 1'b0;
  tag_array_1_load = 1'b0;
  tag_array_2_load = 1'b0;
  tag_array_3_load = 1'b0;

  LRU_array_load = 1'b0;
  LRU_array_datain = 3'b000;

  write_en_0_MUX_sel = no_write; 
  write_en_1_MUX_sel = no_write;
  write_en_2_MUX_sel = no_write; 
  write_en_3_MUX_sel = no_write;
  data_array_0_datain_MUX_sel = no_write;
  data_array_1_datain_MUX_sel = no_write;
  data_array_2_datain_MUX_sel = no_write;
  data_array_3_datain_MUX_sel = no_write;

  address_mux_sel = curr_cpu_address;
  dataout_MUX_sel = 2'b00;
  load_d_cache_reg = 1'b1;

  read_array_flag = 1'b1;
  pmem_address_MUX_sel = cache_read_mem;
endfunction

/* State Enumeration */
enum int unsigned
{
    START,  
    MISS,
    HIT,
    WRITE_BACK
} state, next_state;


/* State Control Signals */
always_comb begin : state_actions

  /* Defaults */
  set_defaults();

  case(state)
    START: begin
      // All defaults already set
    end

    MISS: begin
      load_d_cache_reg = 1'b0;
      address_mux_sel = prev_cpu_address;

      if (~cache_pipeline_in.dirty && ~cache_pipeline_in.hit) begin
        pmem_read = 1'b1;
        if (pmem_resp) begin
          if(~v_array_0_dataout) begin
            tag_array_0_load = 1'b1;
            v_array_0_load = 1'b1;
            v_array_0_datain = 1'b1;
            write_en_0_MUX_sel = mem_write_cache;
            data_array_0_datain_MUX_sel = mem_write_cache;
          end
          else if(~v_array_1_dataout) begin
            tag_array_1_load = 1'b1;
            v_array_1_load = 1'b1;
            v_array_1_datain = 1'b1;
            write_en_1_MUX_sel = mem_write_cache;
            data_array_1_datain_MUX_sel = mem_write_cache;
          end
          else if(~v_array_2_dataout) begin
            tag_array_2_load = 1'b1;
            v_array_2_load = 1'b1;
            v_array_2_datain = 1'b1;
            write_en_2_MUX_sel = mem_write_cache;
            data_array_2_datain_MUX_sel = mem_write_cache;
          end
          else if(~v_array_3_dataout) begin
            tag_array_3_load = 1'b1;
            v_array_3_load = 1'b1;
            v_array_3_datain = 1'b1;
            write_en_3_MUX_sel = mem_write_cache;
            data_array_3_datain_MUX_sel = mem_write_cache;
          end
          else begin
            if(~cache_pipeline_in.LRU_array_dataout[2]) begin
              if(~cache_pipeline_in.LRU_array_dataout[0]) begin
                // Alloc way 3
                tag_array_3_load = 1'b1;
                v_array_3_load = 1'b1;
                v_array_3_datain = 1'b1;
                write_en_3_MUX_sel = mem_write_cache;
                data_array_3_datain_MUX_sel = mem_write_cache;
              end
              else begin
                // Alloc way 2
                tag_array_2_load = 1'b1;
                v_array_2_load = 1'b1;
                v_array_2_datain = 1'b1;
                write_en_2_MUX_sel = mem_write_cache;
                data_array_2_datain_MUX_sel = mem_write_cache;
              end
            end
            else begin
              if(~cache_pipeline_in.LRU_array_dataout[1]) begin
                // Alloc way 1
                tag_array_1_load = 1'b1;
                v_array_1_load = 1'b1;
                v_array_1_datain = 1'b1;
                write_en_1_MUX_sel = mem_write_cache;
                data_array_1_datain_MUX_sel = mem_write_cache;
              end
              else begin
                // Alloc way 0
                tag_array_0_load = 1'b1;
                v_array_0_load = 1'b1;
                v_array_0_datain = 1'b1;
                write_en_0_MUX_sel = mem_write_cache;
                data_array_0_datain_MUX_sel = mem_write_cache;
              end  
            end
          end
        end
      end
    end

    HIT: begin
      if (cache_pipeline_in.hit) begin
        address_mux_sel = curr_cpu_address;
        mem_resp = 1'b1;
        LRU_array_load = 1'b1;
        
        if(cache_pipeline_in.way_0_hit)
          LRU_array_datain = {1'b0, 1'b0, cache_pipeline_in.LRU_array_dataout[0]};
        else if (cache_pipeline_in.way_1_hit)
          LRU_array_datain = {1'b0, 1'b1, cache_pipeline_in.LRU_array_dataout[0]};
        else if (cache_pipeline_in.way_2_hit)
          LRU_array_datain = {1'b1, cache_pipeline_in.LRU_array_dataout[1], 1'b0};
        else if (cache_pipeline_in.way_3_hit)
          LRU_array_datain = {1'b1, cache_pipeline_in.LRU_array_dataout[1], 1'b1};
        
        if(cache_pipeline_in.mem_write) begin
          if(cache_pipeline_in.way_0_hit) begin
            write_en_0_MUX_sel = cpu_write_cache;
            data_array_0_datain_MUX_sel = cpu_write_cache;
            d_array_0_load = 1'b1;
            d_array_0_datain = 1'b1;
          end
          else if(cache_pipeline_in.way_1_hit) begin
            write_en_1_MUX_sel = cpu_write_cache;
            data_array_1_datain_MUX_sel = cpu_write_cache;
            d_array_1_load = 1'b1;
            d_array_1_datain = 1'b1;
          end
          else if(cache_pipeline_in.way_2_hit) begin
            write_en_2_MUX_sel = cpu_write_cache;
            data_array_2_datain_MUX_sel = cpu_write_cache;
            d_array_2_load = 1'b1;
            d_array_2_datain = 1'b1;
          end
          else if(cache_pipeline_in.way_3_hit) begin
            write_en_3_MUX_sel = cpu_write_cache;
            data_array_3_datain_MUX_sel = cpu_write_cache;
            d_array_3_load = 1'b1;
            d_array_3_datain = 1'b1;
          end
        end
      end
    end
    
    WRITE_BACK: begin
      address_mux_sel = prev_cpu_address;

      if(~cache_pipeline_out.LRU_array_dataout[2]) begin
        if(~cache_pipeline_out.LRU_array_dataout[0]) begin
          pmem_write = 1'b1;
          dataout_MUX_sel = 2'b11;
          pmem_address_MUX_sel = cache_write_mem;
          v_array_3_load = 1'b1;
          v_array_3_datain = 1'b0;
        end
        else begin
          pmem_write = 1'b1;
          dataout_MUX_sel = 2'b10;
          pmem_address_MUX_sel = cache_write_mem;
          v_array_2_load = 1'b1;
          v_array_2_datain = 1'b0;
        end
      end
      else begin
        if(~cache_pipeline_out.LRU_array_dataout[1]) begin
          pmem_write = 1'b1;
          dataout_MUX_sel = 2'b01;
          pmem_address_MUX_sel = cache_write_mem;
          v_array_1_load = 1'b1;
          v_array_1_datain = 1'b0;
        end
        else begin
          pmem_write = 1'b1;
          dataout_MUX_sel = 2'b00;
          pmem_address_MUX_sel = cache_write_mem;
          v_array_0_load = 1'b1;
          v_array_0_datain = 1'b0;
        end  
      end
    end

    default: begin
      // All defaults already set by set_defaults()
    end
  endcase
end

/* Next State Logic */
always_comb begin : next_state_logic
  /* Default state transition */
  next_state = state;

  case(state)
    START: begin
      if ((mem_read || mem_write) && ~cache_pipeline_in.hit) begin
        next_state = MISS;
      end
    end

    MISS: begin
      if (cache_pipeline_in.dirty)
        next_state = WRITE_BACK;
      else if (pmem_resp)
        next_state = HIT;
    end

    HIT: begin
      if ((cache_pipeline_out.mem_read || cache_pipeline_out.mem_write) && ~cache_pipeline_in.hit)
        next_state = MISS;
    end

    WRITE_BACK: begin
      if (pmem_resp)
        next_state = MISS;
    end

    default: begin
      next_state = START;
    end
  endcase
end

/* Next State Assignment */
always_ff @(posedge i_clk or negedge rst_n) begin: next_state_assignment
  if (~rst_n)
    state <= START;
  else
    state <= next_state;
end

endmodule : p_d_cache_control