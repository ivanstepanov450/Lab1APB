module top (
    input logic pclk,
    input logic presetn,
    input logic start,
    output logic done
);
    logic        psel, penable, pwrite, pready, pslverr;
    logic [31:0] paddr, pwdata, prdata;

    apb_master master_inst (
        .pclk(pclk), .presetn(presetn), .start(start),
        .psel(psel), .penable(penable), .pwrite(pwrite),
        .paddr(paddr), .pwdata(pwdata), .pready(pready),
        .prdata(prdata), .pslverr(pslverr),
        .done(done)
    );

    apb_slave slave_inst (
        .pclk(pclk), .presetn(presetn),
        .psel(psel), .penable(penable), .pwrite(pwrite),
        .paddr(paddr), .pwdata(pwdata), .pready(pready),
        .prdata(prdata), .pslverr(pslverr)
    );
endmodule