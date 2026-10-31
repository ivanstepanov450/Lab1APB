module apb_slave
(
    input  logic        pclk,
    input  logic        presetn,
    input  logic [31:0] paddr,
    input  logic [31:0] pwdata,
    input  logic        psel,
    input  logic        penable,
    input  logic        pwrite,
    output logic        pready,
    output logic        pslverr,
    output logic [31:0] prdata
);

    logic [31:0] reg_student_number;
    logic [31:0] reg_date;
    logic [31:0] reg_surname;
    logic [31:0] reg_name;
    logic [31:0] register_with_some_name;

    typedef enum logic [1:0] { APB_SETUP, APB_W_ENABLE, APB_R_ENABLE } apb_state_t;
    apb_state_t apb_st;

    always @(posedge pclk) begin
        if (!presetn) begin
            prdata  <= '0;
            pslverr <= 1'b0;
            pready  <= 1'b0;
            reg_student_number <= '0;
            reg_date           <= '0;
            reg_surname        <= '0;
            reg_name           <= '0;
            register_with_some_name <= '0;
            apb_st <= APB_SETUP;
        end else begin
            case (apb_st)
                APB_SETUP: begin
                    prdata  <= '0;
                    pready  <= 1'b0;
                    pslverr <= 1'b0;
                    if (psel && !penable)
                        apb_st <= pwrite ? APB_W_ENABLE : APB_R_ENABLE;
                end

                APB_W_ENABLE: begin
                    if (psel && penable && pwrite) begin
                        pready <= 1'b1;
                        case (paddr[7:0])
                            8'h00: begin reg_student_number <= pwdata; $display("[SLAVE] WRITE 0x00: 0x%h", pwdata); end
                            8'h04: begin reg_date           <= pwdata; $display("[SLAVE] WRITE 0x04: 0x%h", pwdata); end
                            8'h08: begin reg_surname        <= pwdata; $display("[SLAVE] WRITE 0x08: 0x%h", pwdata); end
                            8'h0C: begin reg_name           <= pwdata; $display("[SLAVE] WRITE 0x0C: 0x%h", pwdata); end
                            
                            8'h10: begin 
                                if (pwdata[0] == 1'b0)
                                    register_with_some_name <= 32'hAAAA_AAAA;
                                else
                                    register_with_some_name <= 32'h5555_5555;
                                $display("[SLAVE] WRITE 0x10: 0x%h (pwdata[0]=%b)", pwdata, pwdata[0]);
                            end
                            
                            default: begin
                                pslverr <= 1'b1;
                                $display("[SLAVE] ERROR: Invalid address 0x%h", paddr);
                            end
                        endcase
                        apb_st <= APB_SETUP;
                    end else apb_st <= APB_SETUP;
                end

                APB_R_ENABLE: begin
                    if (psel && penable && !pwrite) begin
                        pready <= 1'b1;
                        case (paddr[7:0])
                            8'h00: prdata <= reg_student_number;
                            8'h04: prdata <= reg_date;
                            8'h08: prdata <= reg_surname;
                            8'h0C: prdata <= reg_name;
                            8'h10: prdata <= register_with_some_name;
                            default: pslverr <= 1'b1;
                        endcase
                        apb_st <= APB_SETUP;
                    end else apb_st <= APB_SETUP;
                end

                default: apb_st <= APB_SETUP;
            endcase
        end
    end
endmodule