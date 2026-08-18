module TOP
(
	input			Reset_Button,
    input           User_Button,
    input           XTAL_IN,

    input           EncoderBtn,
    input           EncoderClk,
    input           EncoderDt,


//    input MyButton1,


	output			LCD_CLK,
	output			LCD_HYNC,
	output			LCD_SYNC,
	output			LCD_DEN,
	output	[4:0]	LCD_R,
	output	[5:0]	LCD_G,
	output	[4:0]	LCD_B
);

    Gowin_rPLL Gowin_rPLL_9Mhz(
        .clkout(LCD_CLK), // 9MHz
        .clkin(XTAL_IN)   //27MHz
    );

wire cw_pulse, ccw_pulse;

wire [3:0] image_x;
wire [3:0] image_y;
wire pixel;

wire [3:0] image2_x;
wire [3:0] image2_y;
wire pixel2;

	VGA_timing	VGA_timing_inst(
		.PixelClk	(	LCD_CLK		),
		.nRST		(	Reset_Button),

		.LCD_DE		(	LCD_DEN	 	),
		.LCD_HSYNC	(	LCD_HYNC 	),
    	.LCD_VSYNC	(	LCD_SYNC 	),

		.LCD_B		(	LCD_B		),
		.LCD_G		(	LCD_G		),
		.LCD_R		(	LCD_R		),

		.BUTTON1	(	EncoderBtn),
//		.ENC_CLK	(	EncoderClk),
//		.ENC_DAT	(	EncoderDt)

        .cw_pulse(cw_pulse),
        .ccw_pulse(ccw_pulse),

        .image_x(image_x),
        .image_y(image_y),

        .image2_x(image2_x),
        .image2_y(image2_y),

        .pixel(pixel),
        .pixel2(pixel2)

	);

    Encoder Encoder_inst(
		.rst_n		(	Reset_Button),
		.clk	(	LCD_CLK		),


		.EncoderClk	(	EncoderClk),
		.EncoderDt	(	EncoderDt),

        .cw_pulse(cw_pulse),
        .ccw_pulse(ccw_pulse)
    );


    image_rom image_rom_inst(
        .x(image_x),
        .y(image_y),

        .x2(image2_x),
        .y2(image2_y),

        .pixel(pixel),
        .pixel2(pixel2)

    );



endmodule