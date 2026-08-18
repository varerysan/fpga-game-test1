module Encoder (
    input  wire clk,        // системный клок платы (27 MHz на Tang Nano 9K)
    input  wire rst_n,
    input  wire EncoderClk, // физический пин CLK энкодера
    input  wire EncoderDt, // физический пин DAT энкодера
    output reg  cw_pulse,    // импульс при вращении по часовой
    output reg  ccw_pulse    // импульс при вращении против часовой
);


    // ---- 1. Синхронизация (2 FF) ----
    reg [1:0] clk_sync, dat_sync;
    always @(posedge clk) begin
        clk_sync <= {clk_sync[0], EncoderClk};
        dat_sync <= {dat_sync[0], EncoderDt};
    end
    wire clk_s = clk_sync[1];
    wire dat_s = dat_sync[1];

    // ---- 2. Дебаунс (фильтр по счётчику) ----
    // при 27 MHz, ~1 мс = 27000 тактов. Используем счётчик поменьше для примера.
    localparam DEBOUNCE_LIMIT = 20'd5000; // подберите под свою частоту

    reg [19:0] clk_cnt, dat_cnt;
    reg clk_stable, dat_stable;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_cnt <= 0; dat_cnt <= 0;
            clk_stable <= 1'b1; dat_stable <= 1'b1;
        end else begin
            // CLK
            if (clk_s == clk_stable) begin
                clk_cnt <= 0;
            end else begin
                clk_cnt <= clk_cnt + 1;
                if (clk_cnt >= DEBOUNCE_LIMIT) begin
                    clk_stable <= clk_s;
                    clk_cnt <= 0;
                end
            end
            // DAT
            if (dat_s == dat_stable) begin
                dat_cnt <= 0;
            end else begin
                dat_cnt <= dat_cnt + 1;
                if (dat_cnt >= DEBOUNCE_LIMIT) begin
                    dat_stable <= dat_s;
                    dat_cnt <= 0;
                end
            end
        end
    end

    // ---- 3. Детектор фронта + определение направления ----
    reg clk_stable_d;
    always @(posedge clk) clk_stable_d <= clk_stable;

    wire clk_falling = clk_stable_d & ~clk_stable;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cw_pulse  <= 1'b0;
            ccw_pulse <= 1'b0;
        end else begin
            cw_pulse  <= 1'b0;
            ccw_pulse <= 1'b0;
            if (clk_falling) begin
                if (dat_stable)
                    ccw_pulse <= 1'b1;
                else
                    cw_pulse <= 1'b1;
            end
        end
    end

endmodule