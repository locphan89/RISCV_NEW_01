import rv32i_types::*;
import cache_mux_types::*;
module p_i_cache_control 

(
  input i_clk,
  input rst_n,

  /* CPU memory signals */
  input   logic           mem_read,
  output  logic           mem_resp,

  /* Physical memory signals */
  input   logic           pmem_resp,
  output  logic           pmem_read,

  /* Datapath to Control */
  input logic v_array_0_dataout,
  input logic v_array_1_dataout,
  input logic v_array_2_dataout,
  input logic v_array_3_dataout,
  
  input i_cache_pipeline_data cache_pipeline_data,
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

  output logic load_i_cache_reg,
  output logic read_array_flag,

  output paddressmux_sel_t address_mux_sel
);

logic num_l1_miss_count;
logic num_l1_miss_overflow;
logic [perf_counter_width-1:0] num_l1_miss;

logic num_l1_hit_count;
logic num_l1_hit_overflow;
logic [perf_counter_width-1:0] num_l1_hit;

perf_counter #(.width(perf_counter_width)) l1miss (
    .i_clk(i_clk),
    .rst_n(rst_n),
    .count(num_l1_miss_count),
    .overflow(num_l1_miss_overflow),
    .out(num_l1_miss)
);

perf_counter #(.width(perf_counter_width)) l1hit (
    .i_clk(i_clk),
    .rst_n(rst_n),
    .count(num_l1_hit_count),
    .overflow(num_l1_hit_overflow),
    .out(num_l1_hit)
);



function void set_defaults();
  /* CPU memory signals */
  mem_resp = 1'b0;

  /* Physical memory signals */
  pmem_read = 1'b0;

  /* Control to Datapath */
  v_array_0_load = 1'b0;
  v_array_0_datain = 1'b0;
  v_array_1_load = 1'b0;
  v_array_1_datain = 1'b0;
  v_array_2_load = 1'b0;
  v_array_2_datain = 1'b0;
  v_array_3_load = 1'b0;
  v_array_3_datain = 1'b0;

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

  load_i_cache_reg = 1'b1;

  read_array_flag = 1'b1;

  num_l1_miss_count = 1'b0;
  num_l1_hit_count = 1'b0;


endfunction

/* State Enumeration */
enum int unsigned
{
  START,
	MISS,
  HIT
} state, next_state;

/* State Control Signals */
always_comb begin : state_actions

	/* Defaults */
  set_defaults();

	case(state)
    START: begin
      // Just wait for first_n request, MISS state will handle pipeline loading
    end

    MISS: begin
      if (mem_read == 1'b1)
      begin
      if (cache_pipeline_data.hit == 1'b0)
      begin
      load_i_cache_reg = 1'b0;
      address_mux_sel = prev_cpu_address;
      pmem_read = 1'b1;
      if (pmem_resp == 1'b1)
      begin
        num_l1_miss_count = 1'b1;
        
        if(v_array_0_dataout == 1'b0)
        begin
          tag_array_0_load = 1'b1;
          v_array_0_load = 1'b1;
          v_array_0_datain = 1'b1;
          write_en_0_MUX_sel = mem_write_cache;
          data_array_0_datain_MUX_sel = mem_write_cache;
          // Way 0 allocated - update LRU
          LRU_array_load = 1'b1;
          LRU_array_datain = {1'b0, 1'b0, cache_pipeline_data.LRU_array_dataout[0]};
        end
        else if(v_array_1_dataout == 1'b0)
        begin
          tag_array_1_load = 1'b1;
          v_array_1_load = 1'b1;
          v_array_1_datain = 1'b1;
          write_en_1_MUX_sel = mem_write_cache;
          data_array_1_datain_MUX_sel = mem_write_cache;
          // Way 1 allocated - update LRU
          LRU_array_load = 1'b1;
          LRU_array_datain = {1'b0, 1'b1, cache_pipeline_data.LRU_array_dataout[0]};
        end
        else if(v_array_2_dataout == 1'b0)
        begin
          tag_array_2_load = 1'b1;
          v_array_2_load = 1'b1;
          v_array_2_datain = 1'b1;
          write_en_2_MUX_sel = mem_write_cache;
          data_array_2_datain_MUX_sel = mem_write_cache;
          // Way 2 allocated - update LRU
          LRU_array_load = 1'b1;
          LRU_array_datain = {1'b1, cache_pipeline_data.LRU_array_dataout[1], 1'b0};
        end
        else if(v_array_3_dataout == 1'b0)
        begin
          tag_array_3_load = 1'b1;
          v_array_3_load = 1'b1;
          v_array_3_datain = 1'b1;
          write_en_3_MUX_sel = mem_write_cache;
          data_array_3_datain_MUX_sel = mem_write_cache;
          // Way 3 allocated - update LRU
          LRU_array_load = 1'b1;
          LRU_array_datain = {1'b1, cache_pipeline_data.LRU_array_dataout[1], 1'b1};
        end
        else
        begin
          // All ways valid - evict LRU using Tree-PLRU
          // Tree-PLRU encoding for 4-way: [2:1:0]
          //   Bit 2: 0=left subtree (ways 2,3), 1=right subtree (ways 0,1)
          //   Bit 1: in left subtree, 0=way 3, 1=way 2
          //   Bit 0: in right subtree, 0=way 1, 1=way 0
          
          if(cache_pipeline_data.LRU_array_dataout[2] == 1'b0)
          begin
            // LRU is in left subtree (ways 2,3)
            if(cache_pipeline_data.LRU_array_dataout[1] == 1'b0)
            begin
              // Evict way 3, set as MRU
              tag_array_3_load = 1'b1;
              v_array_3_load = 1'b1;
              v_array_3_datain = 1'b1;
              write_en_3_MUX_sel = mem_write_cache;
              data_array_3_datain_MUX_sel = mem_write_cache;
              LRU_array_load = 1'b1;
              LRU_array_datain = {1'b1, cache_pipeline_data.LRU_array_dataout[1], 1'b1};
            end
            else
            begin
              // Evict way 2, set as MRU
              tag_array_2_load = 1'b1;
              v_array_2_load = 1'b1;
              v_array_2_datain = 1'b1;
              write_en_2_MUX_sel = mem_write_cache;
              data_array_2_datain_MUX_sel = mem_write_cache;
              LRU_array_load = 1'b1;
              LRU_array_datain = {1'b1, cache_pipeline_data.LRU_array_dataout[1], 1'b0};
            end
          end
          else
          begin
            // LRU is in right subtree (ways 0,1)
            if(cache_pipeline_data.LRU_array_dataout[0] == 1'b0)
            begin
              // Evict way 1, set as MRU
              tag_array_1_load = 1'b1;
              v_array_1_load = 1'b1;
              v_array_1_datain = 1'b1;
              write_en_1_MUX_sel = mem_write_cache;
              data_array_1_datain_MUX_sel = mem_write_cache;
              LRU_array_load = 1'b1;
              LRU_array_datain = {1'b0, 1'b1, cache_pipeline_data.LRU_array_dataout[0]};
            end
            else
            begin
              // Evict way 0, set as MRU
              tag_array_0_load = 1'b1;
              v_array_0_load = 1'b1;
              v_array_0_datain = 1'b1;
              write_en_0_MUX_sel = mem_write_cache;
              data_array_0_datain_MUX_sel = mem_write_cache;
              LRU_array_load = 1'b1;
              LRU_array_datain = {1'b0, 1'b0, cache_pipeline_data.LRU_array_dataout[0]};
            end  
          end
        end
      end
      end
      else if (cache_pipeline_data.hit == 1'b1 && cache_pipeline_data.address_stable == 1'b1) begin
        // Hit detected and address is stable - data is in cache
        // Keep pipeline frozen, will transition to HIT next cycle
        load_i_cache_reg = 1'b0;
        address_mux_sel = prev_cpu_address;
      end
      else if (cache_pipeline_data.address_stable == 1'b0) begin
        // Address not stable - load new address into pipeline
        load_i_cache_reg = 1'b1;
        address_mux_sel = curr_cpu_address;
      end
      else begin
        load_i_cache_reg = 1'b0;
        address_mux_sel = prev_cpu_address;
      end
      end
    end

  HIT: begin
    if (cache_pipeline_data.hit == 1'b1 && if_id_reg_load == 1'b1 && cache_pipeline_data.address_stable == 1'b1)
      begin
      address_mux_sel = curr_cpu_address;
      num_l1_hit_count = 1'b1;
      mem_resp = 1'b1;
      // Update LRU on hit - mark accessed way as MRU
      // Tree-PLRU update: accessed way becomes MRU
      LRU_array_load = 1'b1;
      if(cache_pipeline_data.way_0_hit)
          // Way 0 accessed: set bit[2]=0 (right), bit[0]=1 (way 0 in right)
          LRU_array_datain = {1'b0, cache_pipeline_data.LRU_array_dataout[1], 1'b1};
      else if (cache_pipeline_data.way_1_hit)
          // Way 1 accessed: set bit[2]=0 (right), bit[0]=0 (way 1 in right)
          LRU_array_datain = {1'b0, cache_pipeline_data.LRU_array_dataout[1], 1'b0};
      else if (cache_pipeline_data.way_2_hit)
          // Way 2 accessed: set bit[2]=1 (left), bit[1]=1 (way 2 in left)
          LRU_array_datain = {1'b1, 1'b1, cache_pipeline_data.LRU_array_dataout[0]};
      else if (cache_pipeline_data.way_3_hit)
          // Way 3 accessed: set bit[2]=1 (left), bit[1]=0 (way 3 in left)
          LRU_array_datain = {1'b1, 1'b0, cache_pipeline_data.LRU_array_dataout[0]};
      end 
    else begin
       // Not a valid hit - don't update LRU
       load_i_cache_reg = 1'b0;
       read_array_flag = 1'b0;
    end
    end

	endcase
end

/* Next State Logic */
always_comb begin : next_state_logic
	/* Default state transition */
	next_state = state;

	case(state)
    START: begin
      if (mem_read) begin
        // Always transition to MISS on first_n request to load pipeline
        next_state = MISS;
      end
    end

    MISS: begin
      if (pmem_resp == 1'b1)
        next_state = HIT;
      else if (cache_pipeline_data.hit == 1'b1 && cache_pipeline_data.address_stable == 1'b1)
        next_state = HIT;
      end

    HIT: begin
      if (mem_read == 1'b1) begin
        if (cache_pipeline_data.address_stable == 1'b0)
          next_state = MISS;
        else if (cache_pipeline_data.hit == 1'b0)
          next_state = MISS;
      end
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

endmodule : p_i_cache_control