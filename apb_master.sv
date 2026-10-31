module apb_master (
    input  logic        pclk,
    input  logic        presetn,
    input  logic        start,
    
    output logic        psel,
    output logic        penable,
    output logic        pwrite,
    output logic [31:0] paddr,
    output logic [31:0] pwdata,
    input  logic        pready,
    input  logic [31:0] prdata,
    input  logic        pslverr,
    
    output logic        done
);

    localparam logic [31:0] MY_NUMBER  = 32'd8;            // Номер группы: 8
    localparam logic [31:0] MY_DATE    = 32'h3110_2026;    // Дата: 31.10.2026
    localparam logic [31:0] MY_SURNAME = 32'h5374_6570;    // Фамилия: "Step"
    localparam logic [31:0] MY_NAME    = 32'h4976_616E;    // Имя: "Ivan"

    typedef enum logic [2:0] {IDLE, SETUP, ACCESS, CHECK, FINISHED} state_t;
    state_t state;

    logic [31:0] test_addr;
    logic [31:0] test_wdata;
    logic [31:0] test_expected;
    logic        test_is_write;
    logic        test_expect_err;
    
    logic [31:0] captured_rdata;
    logic        captured_pslverr;
    
    int          step;
    int          errors;

    task automatic set_test(input logic [31:0] a, input logic [31:0] wd, input logic [31:0] exp, input logic is_wr, input logic exp_err);
        test_addr = a;
        test_wdata = wd;
        test_expected = exp;
        test_is_write = is_wr;
        test_expect_err = exp_err;
    endtask

    always @(posedge pclk) begin
        if (!presetn) begin
            state <= IDLE;
            psel <= 0; penable <= 0; pwrite <= 0; paddr <= 0; pwdata <= 0;
            done <= 0;
            step <= 0;
            errors <= 0;
            captured_rdata <= 0;
            captured_pslverr <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= SETUP;
                        errors <= 0;
                        step <= 1;
                        set_test(32'h7000_0000, MY_NUMBER, MY_NUMBER, 1'b1, 1'b0);
                    end
                end
                
                SETUP: begin
                    psel   <= 1'b1;
                    paddr  <= test_addr;
                    pwrite <= test_is_write;
                    pwdata <= test_wdata;
                    state  <= ACCESS;
                end
                
                ACCESS: begin
                    penable <= 1'b1;
                    if (pready) begin
                        // ЗАЩЕЛКА: Сохраняем данные ровно в тот момент, когда слейв сказал "Готово"
                        captured_rdata   <= prdata;
                        captured_pslverr <= pslverr;
                        
                        psel    <= 1'b0;
                        penable <= 1'b0;
                        state   <= CHECK;
                    end
                end
                
                CHECK: begin
                    if (!test_is_write) begin
                        if (captured_pslverr !== test_expect_err || (!test_expect_err && captured_rdata !== test_expected)) begin
                            $display("[MASTER] FAIL at step %0d! Addr: 0x%h. Exp: 0x%h, Got: 0x%h", step, test_addr, test_expected, captured_rdata);
                            errors++;
                        end else begin
                            $display("[MASTER] PASS step %0d (Addr: 0x%h) - Read: 0x%h", step, test_addr, captured_rdata);
                        end
                    end else begin
                        if (captured_pslverr !== test_expect_err) begin
                            $display("[MASTER] FAIL ERR at step %0d! Addr: 0x%h. Exp Err: %b", step, test_addr, test_expect_err);
                            errors++;
                        end
                    end

                    step++;
                    case (step)
                        2: begin set_test(32'h7000_0000, 0, MY_NUMBER, 1'b0, 1'b0); state <= SETUP; end
                        3: begin set_test(32'h7000_0004, MY_DATE, MY_DATE, 1'b1, 1'b0); state <= SETUP; end
                        4: begin set_test(32'h7000_0004, 0, MY_DATE, 1'b0, 1'b0); state <= SETUP; end
                        5: begin set_test(32'h7000_0008, MY_SURNAME, MY_SURNAME, 1'b1, 1'b0); state <= SETUP; end
                        6: begin set_test(32'h7000_0008, 0, MY_SURNAME, 1'b0, 1'b0); state <= SETUP; end
                        7: begin set_test(32'h7000_000C, MY_NAME, MY_NAME, 1'b1, 1'b0); state <= SETUP; end
                        8: begin set_test(32'h7000_000C, 0, MY_NAME, 1'b0, 1'b0); state <= SETUP; end
                        
                        9: begin set_test(32'h7000_0010, 32'h1234_5678, 0, 1'b1, 1'b0); state <= SETUP; end 
                        10: begin set_test(32'h7000_0010, 0, 32'hAAAA_AAAA, 1'b0, 1'b0); state <= SETUP; end 
                        11: begin set_test(32'h7000_0010, 32'h0000_0001, 0, 1'b1, 1'b0); state <= SETUP; end 
                        12: begin set_test(32'h7000_0010, 0, 32'h5555_5555, 1'b0, 1'b0); state <= SETUP; end 
                        
                        13: begin set_test(32'h7000_0020, 32'hDEAD_BEEF, 0, 1'b1, 1'b1); state <= SETUP; end
                        default: begin
                            $display("--- ALL TESTS DONE, ERRORS: %0d ---", errors);
                            state <= FINISHED;
                        end
                    endcase
                end
                
                FINISHED: begin
                    done <= 1'b1;
                end
            endcase
        end
    end
endmodule
