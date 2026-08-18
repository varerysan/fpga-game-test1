module VGA_timing
(
    input                   PixelClk,
    input                   nRST,
    input                   BUTTON1,

//    input                   ENC_CLK,
//    input                   ENC_DAT,
    input  wire cw_pulse,
    input  wire ccw_pulse,

    output  wire [3:0] image_x,
    output  wire [3:0] image_y,
 
    output  wire [3:0] image2_x,
    output  wire [3:0] image2_y,

    input  wire pixel,
    input  wire pixel2,


//    input           MyButton1,



    output                  LCD_DE,
    output                  LCD_HSYNC,
    output                  LCD_VSYNC,

	output          [4:0]   LCD_B,
	output          [5:0]   LCD_G,
	output          [4:0]   LCD_R
);
	
    // Horizen count to Hsync, then next Horizen line.

    parameter       H_Pixel_Valid    = 16'd480; 
    parameter       H_FrontPorch     = 16'd50;
    parameter       H_BackPorch      = 16'd30;  

    parameter       PixelForHS       = H_Pixel_Valid + H_FrontPorch + H_BackPorch;

    parameter       V_Pixel_Valid    = 16'd272; 
    parameter       V_FrontPorch     = 16'd20;  
    parameter       V_BackPorch      = 16'd5;    

    parameter       step_scale      = 2'd2;    
    parameter       bullet_init_step      = 16'd10000;    


    parameter       PixelForVS       = V_Pixel_Valid + V_FrontPorch + V_BackPorch;

    // Horizen pixel count

    reg         [15:0]  H_PixelCount;
    reg         [15:0]  V_PixelCount;

    reg         [15:0]  N_counter;

    reg         [15:0]  N_shift;


    reg         [15:0]  real_x;
    reg         [15:0]  real_y;

    reg         [15:0]  space_x;
    reg         [15:0]  space_y;

    reg         [15:0]  space_lives;


    reg         [15:0]  bullet_step;
    reg         [15:0]  bullet_x;
    reg         [15:0]  bullet_y;

    
    reg         [15:0]  enemy_x;
    reg         [15:0]  enemy_y;



    wire  [4:0]  TMP_R;
    wire  [4:0]  TMP_R2;

    wire  [5:0]  TMP_G;
    wire  [5:0]  TMP_G2;

    function integer abs_int;
        input integer val;
        begin
            if (val < 0)
                abs_int = -val;
            else
                abs_int = val;
        end
    endfunction



//  always @(posedge PixelClk) begin
//    sr <= {sr[3:0], sr[4] ^ sr[1]};
//    randomBit <= sr[4];
//  end


    always @(  posedge PixelClk or negedge nRST )begin
        if( !nRST ) begin
            V_PixelCount      <=  16'b0;    
            H_PixelCount      <=  16'b0;
            N_counter         <=  16'b0;
            N_shift           <=  16'd45;
            bullet_x          <= 500; // 100;
            bullet_y          <= 100;
            bullet_step       <= bullet_init_step;
            enemy_x           <= 500;
            enemy_y           <= 100;
            space_lives       <= 5;
            end
        else 
            begin
                if(  H_PixelCount == PixelForHS ) begin
                    V_PixelCount      <=  V_PixelCount + 1'b1;
                    H_PixelCount      <=  16'b0;
                    end
                else if(  V_PixelCount == PixelForVS ) begin
                    V_PixelCount      <=  16'b0;
                    H_PixelCount      <=  16'b0;
                    N_counter         <=   N_counter + 5'd5;

                    bullet_x = bullet_x + 5;

                    // check
                    if (abs_int(bullet_x - enemy_x) < 20 && abs_int(bullet_y - 16 - enemy_y) < 16) begin
                        enemy_x = 450;
                        bullet_x = 510;
                        enemy_y = (enemy_y + 25) % 200 + 20;
                    end else begin

                        if (enemy_x > 5) begin
                            enemy_x = enemy_x - 5;
                        end else begin
    //                        enemy_y = enemy_y;
                            enemy_x = 500;
                        end

                    end




                    end
                else begin
                    V_PixelCount      <=  V_PixelCount ;
                    H_PixelCount      <=  H_PixelCount + 1'b1;
                end

                if (cw_pulse && !ccw_pulse) begin
                    if (N_shift != 7'd90)
                        N_shift <= N_shift + 1'b1;
                end else if (ccw_pulse && !cw_pulse) begin
                    if (N_shift != 7'd1)
                        N_shift <= N_shift - 1'b1;
                end


                if (bullet_x >= 500) begin
                    if (BUTTON1 == 0) begin
                        bullet_x = 50;
                        bullet_y = space_y + 14 + N_shift * step_scale;
                    end
                end



            end
    end


    // SYNC-DE MODE
    
    assign  LCD_HSYNC = H_PixelCount <= (PixelForHS-H_FrontPorch) ? 1'b0 : 1'b1;
    
	assign  LCD_VSYNC = V_PixelCount  <= (PixelForVS-0)  ? 1'b0 : 1'b1;

    assign real_x = H_PixelCount - H_BackPorch;
    assign real_y = V_PixelCount - V_BackPorch;

    assign space_x = 20;
    assign space_y = 30 + N_shift * step_scale;

    assign  LCD_DE =    ( H_PixelCount >= H_BackPorch ) && ( H_PixelCount <= H_Pixel_Valid + H_BackPorch ) &&
                        ( V_PixelCount >= V_BackPorch ) && ( V_PixelCount <= V_Pixel_Valid + V_BackPorch ) && PixelClk;

    // color bar
    localparam          Colorbar_width   =   H_Pixel_Valid / 16;

//    assign  LCD_R     = ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 0  )) ? 5'b00000 :
//                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 1  )) ? 5'b00001 : 
//                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 2  )) ? 5'b00010 :    
//                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 3  )) ? 5'b00100 :    
//                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 4  )) ? 5'b01000 :    
//                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 5  )) ? 5'b10000 :  5'b00000;

//    assign  LCD_R = ( H_PixelCount > 100 && H_PixelCount < 150 && V_PixelCount > 100 && V_PixelCount < 150) ? 5'b11111 : 0;

//    assign LCD_R = (H_PixelCount > 100 && H_PixelCount < 120) ? 5'b11111 : 0;
//    assign LCD_R = (real_x == 29) ? 5'b11111 : 0;  // 5->0
//    assign LCD_R = 0;

//    assign LCD_R = (
//        real_x > bullet_x &&
//        real_x < bullet_x + 20 &&
//        real_y > bullet_y &&
//        real_y < bullet_y + 4) ? 5'b11111 : 0;  // 5->0



//    assign LCD_R = (
//        real_x > bullet_x &&
//        real_x < bullet_x + 20 &&
//        real_y > bullet_y - N_shift * step_scale &&
//        real_y < bullet_y + 4 - N_shift * step_scale) ? 5'b11111 : 0;  // 5->0

    assign TMP_R =  (
        real_x > bullet_x &&
        real_x < bullet_x + 20 &&
        real_y > bullet_y - N_shift * step_scale &&
        real_y < bullet_y + 4 - N_shift * step_scale) ? 5'b11111 : 0;  // 5->0


    assign image2_x = (real_x - enemy_x) / 2;
    assign image2_y = (real_y - enemy_y + N_shift * step_scale) / 2;
    assign TMP_R2 = ((real_x - enemy_x) < 32 && (real_y - enemy_y + N_shift * step_scale) < 32 && enemy_x > 0) ? pixel2 * 6'b111111 : 0;


    assign LCD_R = TMP_R | TMP_R2;



//   ((real_x - space_x) < 32 && (real_y - space_y) < 32) ? pixel * 6'b111111 : 0;

//    assign  LCD_G    =  ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 6  )) ? 6'b000001: 
//                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 7  )) ? 6'b000010:    
//                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 8  )) ? 6'b000100:    
//                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 9  )) ? 6'b001000:    
//                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 10 )) ? 6'b010000:    
//                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 11 )) ? 6'b100000:  6'b000000;


//    assign image_x = real_x / 2;
//    assign image_y = real_y / 2;
//    assign LCD_G = (real_x < 32 && real_y < 32) ? pixel * 6'b111111 : 0;

    assign image_x = (real_x - space_x) / 2;
    assign image_y = (real_y - space_y) / 2;


    assign TMP_G = 0;//(real_x < space_lives * 10 && real_y < 10)  ? pixel * 6'b011111 : 0;


    assign TMP2_G = ((real_x - space_x) < 32 && (real_y - space_y) < 32) ? pixel * 6'b111111 : 0;


//    assign LCD_G = TMP_G ;//| TMP2_G;

//    assign LCD_G = TMP2_G ;//| TMP2_G;
    assign LCD_G = ((real_x - space_x) < 32 && (real_y - space_y) < 32) ? pixel * 6'b111111 : 0;



//    assign LCD_G = (real_x < 16 && real_y < 16) ? 6'b111111 : 0;
//    assign LCD_G = (H_PixelCount - H_BackPorch < 50 && V_PixelCount < 50) ? 6'b111111 : 0;


//    assign  LCD_B    =  ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 12 )) ? 5'b00001 : 
//                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 13 )) ? 5'b00010 :    
//                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 14 )) ? 5'b00100 :    
//                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 15 )) ? 5'b01000 :    
//                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 16 )) ? 5'b10000 :  5'b00000;

//    if(  H_PixelCount > 100 && H_PixelCount < 150 && V_PixelCount > 100 && V_PixelCount < 200 ) begin
//    assign LCD_B = (  H_PixelCount > 100 && H_PixelCount < 150 && V_PixelCount > 100 && V_PixelCount < 200 ) ? 5'b11111 :  5'b00000;

//    assign LCD_B = (((H_PixelCount + N_counter) / N_shift) + ((V_PixelCount + N_shift) / 16 + BUTTON1) & 1 == 1)? 5'b11011 :  5'b00100;



    assign LCD_B = (((H_PixelCount + N_counter) / 32) + ((V_PixelCount + N_shift * step_scale) / 16 ) & 1 == 1)? 5'b01011 :  5'b00000;

//    assign LCD_B = (((H_PixelCount ) / 32) + ((V_PixelCount + N_shift*3) / 16 + BUTTON1) & 1 == 1)? 5'b11011 :  5'b00100;
//assign LCD_B = 0;
//    if(  H_PixelCount > 100) begin
//        assign LCD_B = 255;
//    end
    

endmodule
