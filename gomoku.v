module gomoku(CLOCK_50, PS2_CLK, PS2_DAT, /*SW, */KEY, LEDR, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_R, VGA_G, VGA_B);
	input CLOCK_50;
	inout PS2_CLK, PS2_DAT;
	//input [9:0] SW;
	input [3:0] KEY;
	output [9:0] LEDR;
	output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	output VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N;
	output [9:0] VGA_R, VGA_G, VGA_B;
	
	wire resetn;
	assign resetn = KEY[0];
	
	wire w, a, s, d, left, right, up, down, space, enter;
	wire game_state;
	
	//wire in_x = SW[5:3], in_y = SW[2:0];
	reg [2:0] in_x = 3'd3, in_y = 3'd3;
	reg in_color = 1'b0;
	
	hex_decoder hex0(.hex_digit(in_y), .segments(HEX0)), // y coord
					hex1(.hex_digit(in_x), .segments(HEX1)), // x coord
					hex2(.hex_digit(in_color), .segments(HEX2)), // input color
					hex3(.hex_digit(game_state), .segments(HEX3)), // game state
					hex4(.hex_digit(board[7*in_x + in_y]), .segments(HEX4)), // stone at game logic board coordinate
					hex5(.hex_digit(display_board[7*in_x + in_y]), .segments(HEX5)); // stone at display board coordinate
	
	// keyboard stuff
	reg left_lock, right_lock, up_lock, down_lock; // lock so it doesnt activate every clock tick
	wire left_key, right_key, up_key, down_key;
	assign left_key = left && ~left_lock;
	assign right_key = right && ~right_lock;
	assign up_key = up && ~up_lock;
	assign down_key = down && ~down_lock;
	
	always@(posedge CLOCK_50)
	begin
		if (~resetn)
		begin
			left_lock <= 1'b0;
			right_lock <= 1'b0;
			up_lock <= 1'b0;
			down_lock <= 1'b0;
			in_x <= 3'd3;
			in_y <= 3'd3;
		end
		else begin
			left_lock <= left;
			right_lock <= right;
			up_lock <= up;
			down_lock <= down;
			
			if (left_key)
				in_x <= in_x == 3'd0 ? 3'd0 : in_x - 3'd1;
			if (right_key)
				in_x <= in_x == 3'd6 ? 3'd6 : in_x + 3'd1;
			if (up_key)
				in_y <= in_y == 3'd0 ? 3'd0 : in_y - 3'd1;
			if (down_key)
				in_y <= in_y == 3'd6 ? 3'd6 : in_y + 3'd1;
		end
	end
	
	board7 game_board(.clk(CLOCK_50), .resetn(resetn), .go(go), .x(in_x), .y(in_y), .color(in_color), .board_flat(board_flat), .state(game_state));
	
	reg display_board [7*7-1:0];
	integer j;
	initial begin
		for (j = 0; j < 7*7; j = j + 1)
			display_board[j] <= 1'b0;
	end
	
	wire [7*7*2-1:0] board_flat;
	wire [1:0] board [7*7-1:0];
	genvar i;
	generate for (i = 0; i < 7*7; i = i + 1) begin:unflatten
		assign board[i] = board_flat[2*i+1:2*i];
	end endgenerate
	
	wire [2:0] vga_colour;
	wire [7:0] vga_x;
	wire [6:0] vga_y;
	wire writeEn;
	
	assign vga_colour = in_color ? 3'b111 : 3'b000;
	
	reg [3:0] cx = 4'd0, cy = 4'd0;
	
	always@(posedge CLOCK_50)
	begin
		if (go) begin
			cx <= cx + 1;
			if (cx == 4'd14) begin
				cx <= 0;
				cy <= cy == 4'd14 ? 0 : cy + 1;
			end
		end
		else begin
			cx <= 4'd0;
			cy <= 4'd0;
		end
	end
	
	localparam board_start_x = 8'd31 - 8'd7,
				  board_start_y = 7'd11 - 7'd7;
	
	assign vga_x = board_start_x + in_x * (8'd15 + 8'd1) + cx; // coord to start drawing from
	assign vga_y = board_start_y + in_y * (7'd15 + 7'd1) + cy;
	
	reg [14:0] circle [14:0];
	always@(*)
	begin
		circle[0] = 15'b000001111100000;
		circle[1] = 15'b000111111111000;
		circle[2] = 15'b001111111111100;
		circle[3] = 15'b011111111111110;
		circle[4] = 15'b011111111111110;
		circle[5] = 15'b111111111111111;
		circle[6] = 15'b111111111111111;
		circle[7] = 15'b111111111111111;
		circle[8] = 15'b111111111111111;
		circle[9] = 15'b111111111111111;
		circle[10] = 15'b011111111111110;
		circle[11] = 15'b011111111111110;
		circle[12] = 15'b001111111111100;
		circle[13] = 15'b000111111111000;
		circle[14] = 15'b000001111100000;
	end
	
	assign writeEn = go && circle[cx][cy];
	
	keyboard_tracker #(.PULSE_OR_HOLD(0)) keyboard(.clock(CLOCK_50), .reset(resetn),
																  .PS2_CLK(PS2_CLK), .PS2_DAT(PS2_DAT),
																  .w(w), .a(a), .s(s), .d(d),
																  .left(left), .right(right), .up(up), .down(down),
																  .space(space), .enter(enter));
																  
	vga_adapter VGA(.resetn(resetn), .clock(CLOCK_50),
						 .colour(vga_colour), .x(vga_x), .y(vga_y), .plot(writeEn), 
						 .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B), .VGA_HS(VGA_HS), .VGA_VS(VGA_VS), .VGA_BLANK(VGA_BLANK_N), .VGA_SYNC(VGA_SYNC_N), .VGA_CLK(VGA_CLK));
	defparam VGA.RESOLUTION = "160x120";
	defparam VGA.MONOCHROME = "FALSE";
	defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
	defparam VGA.BACKGROUND_IMAGE = "img/board.colour.mif";
	
	/* // reset vga frame buffer
	always@(posedge CLOCK_50)
	begin
		if (~resetn) begin															  
			vga_adapter VGA2(.resetn(resetn), .clock(CLOCK_50),
								 .colour(vga_colour), .x(vga_x), .y(vga_y), .plot(writeEn), 
								 .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B), .VGA_HS(VGA_HS), .VGA_VS(VGA_VS), .VGA_BLANK(VGA_BLANK_N), .VGA_SYNC(VGA_SYNC_N), .VGA_CLK(VGA_CLK));
			defparam VGA2.RESOLUTION = "160x120";
			defparam VGA2.MONOCHROME = "FALSE";
			defparam VGA2.BITS_PER_COLOUR_CHANNEL = 1;
			defparam VGA2.BACKGROUND_IMAGE = "img/board.colour.mif";
		end
	end*/
	
	wire load_x, load_y, load_colour;
	wire go;
	assign go = /*~KEY[1];*/ enter && ~display_board[7*in_x + in_y];
	
	always@(negedge go) // might not work cuz of delays and stuff
	begin
		display_board[7*in_x + in_y] <= 1'b1;
		in_color <= !in_color;
	end
	
endmodule

module board7(clk, resetn, go, x, y, color, board_flat, state);
	input clk;
	input resetn;
	input go;                            // load a stone onto the board
	input [2:0] x, y;                    // coordinates of new move played. x = row, y = col.
	input color;                         // current player turn. 0 = black, 1 = white. game starts with black.
	reg [1:0] board [7*7-1:0];           // 7x7 array for board. for each coordinate, 0 = no move, 1 = black move, 2 = white move
	output wire [7*7*2-1:0] board_flat;  // flattened board array for passing to modules
	output wire state;                   // 0 = no win yet, 1 = (color) has won
	
	initial begin
		for (i = 0; i < 7*7; i = i + 1)
			board[i] <= 2'b0;
	end
	
	integer i;
	always@(posedge clk)
	begin
		if (~resetn)
		begin
			for (i = 0; i < 7*7; i = i + 1) begin
				board[i] <= 2'b0;
			end
		end
		else if (go && board[7*x + y] == 2'd0)
			board[7*x + y] <= color + 2'd1;
	end
	
	genvar j;
	generate for (j = 0; j < 7*7; j = j + 1) begin:flatten
		assign board_flat[2*j + 1:2*j] = board[j];
	end endgenerate
	
	wire [(9+6*4)-1:0] q;
	
	genvar k, m;
	generate for (k = 3'd2; k <= 3'd4; k = k + 3'd1) begin: nodes_outer
		for (m = 3'd2; m <= 3'd4; m = m + 3'd1) begin: nodes_inner
			centernode cn(.x(k), .y(m), .board_flat(board_flat), .q(q[3*(k - 2) + (m - 2)]));
		end
		edgenode en_x0(.x(3'd0), .y(k), .board_flat(board_flat), .q(q[9 + (k - 2)]);
		edgenode en_x1(.x(3'd1), .y(k), .board_flat(board_flat), .q(q[12 + (k - 2)]);
		edgenode en_x2(.x(3'd5), .y(k), .board_flat(board_flat), .q(q[15 + (k - 2)]);
		edgenode en_x3(.x(3'd6), .y(k), .board_flat(board_flat), .q(q[18 + (k - 2)]);
		edgenode en_y0(.x(k), .y(3'd0), .board_flat(board_flat), .q(q[21 + (k - 2)]);
		edgenode en_y1(.x(k), .y(3'd1), .board_flat(board_flat), .q(q[24 + (k - 2)]);
		edgenode en_y2(.x(k), .y(3'd5), .board_flat(board_flat), .q(q[27 + (k - 2)]);
		edgenode en_y3(.x(k), .y(3'd6), .board_flat(board_flat), .q(q[30 + (k - 2)]);
	end endgenerate
	
	assign state = |q;
	
	/*
	// middle 9 points on 7x7 board
	wire qc, qu, qur, qr, qdr, qd, qdl, ql, qul;
	centernode nc(.x(3'd3), .y(3'd3), .board_flat(board_flat), .q(qc)),
		  nu(.x(3'd3), .y(3'd2), .board_flat(board_flat), .q(qu)),
		  nur(.x(3'd4), .y(3'd2), .board_flat(board_flat), .q(qur)),
		  nr(.x(3'd4), .y(3'd3), .board_flat(board_flat), .q(qr)),
		  ndr(.x(3'd4), .y(3'd4), .board_flat(board_flat), .q(qdr)),
		  nd(.x(3'd3), .y(3'd4), .board_flat(board_flat), .q(qd)),
		  ndl(.x(3'd2), .y(3'd4), .board_flat(board_flat), .q(qdl)),
		  nl(.x(3'd2), .y(3'd3), .board_flat(board_flat), .q(ql)),
		  nul(.x(3'd2), .y(3'd2), .board_flat(board_flat), .q(qul));
		  
	// left edge
	wire qlc, qlu, qld, ql2c, ql2u, ql2d;
	edgenode nlc(.x(3'd0), .y(3'd3), .board_flat(board_flat), .q(qlc)),
			 nlu(.x(3'd0), .y(3'd2), .board_flat(board_flat), .q(qlu)),
			 nld(.x(3'd0), .y(3'd4), .board_flat(board_flat), .q(qld)),
			 nl2c(.x(3'd1), .y(3'd3), .board_flat(board_flat), .q(ql2c)),
			 nl2u(.x(3'd1), .y(3'd2), .board_flat(board_flat), .q(ql2u)),
			 nl2d(.x(3'd1), .y(3'd4), .board_flat(board_flat), .q(ql2d));
	
	// right edge
	wire qrc, qru, qrd, qr2c, qr2u, qr2d;
	edgenode nrc(.x(3'd6), .y(3'd3), .board_flat(board_flat), .q(qrc)),
			 nru(.x(3'd6), .y(3'd2), .board_flat(board_flat), .q(qru)),
			 nrd(.x(3'd6), .y(3'd4), .board_flat(board_flat), .q(qrd)),
			 nr2c(.x(3'd5), .y(3'd3), .board_flat(board_flat), .q(qr2c)),
			 nr2u(.x(3'd5), .y(3'd2), .board_flat(board_flat), .q(qr2u)),
			 nr2d(.x(3'd5), .y(3'd4), .board_flat(board_flat), .q(qr2d));
	// top edge
	wire qtc, qtl, qtr, qt2c, qt2l, qt2r;
	edgenode ntc(.x(3'd3), .y(3'd0), .board_flat(board_flat), .q(qtc)),
			 ntl(.x(3'd2), .y(3'd0), .board_flat(board_flat), .q(qtl)),
			 ntr(.x(3'd4), .y(3'd0), .board_flat(board_flat), .q(qtr)),
			 nt2c(.x(3'd3), .y(3'd1), .board_flat(board_flat), .q(qt2c)),
			 nt2l(.x(3'd2), .y(3'd1), .board_flat(board_flat), .q(qt2l)),
			 nt2r(.x(3'd4), .y(3'd1), .board_flat(board_flat), .q(qt2r));
	// bottom edge
	wire qbc, qbl, qbr, qb2c, qb2l, qb2r;
	edgenode nbc(.x(3'd3), .y(3'd6), .board_flat(board_flat), .q(qbc)),
			 nbl(.x(3'd2), .y(3'd6), .board_flat(board_flat), .q(qbl)),
			 nbr(.x(3'd4), .y(3'd6), .board_flat(board_flat), .q(qbr)),
			 nb2c(.x(3'd3), .y(3'd5), .board_flat(board_flat), .q(qb2c)),
			 nb2l(.x(3'd2), .y(3'd5), .board_flat(board_flat), .q(qb2l)),
			 nb2r(.x(3'd4), .y(3'd5), .board_flat(board_flat), .q(qb2r));
	
	always@(*)
	begin
		// center
		if (qc > 0) state = qc;
		else if (qu > 0) state = qu;
		else if (qur > 0) state = qur;
		else if (qr > 0) state = qr;
		else if (qdr > 0) state = qdr;
		else if (qd > 0) state = qd;
		else if (qdl > 0) state = qdl;
		else if (ql > 0) state = ql;
		else if (qul > 0) state = qul;
		// left
		else if (qlc > 0) state = qlc;
		else if (qlu > 0) state = qlu;
		else if (qld > 0) state = qld;
		else if (ql2c > 0) state = ql2c;
		else if (ql2u > 0) state = ql2u;
		else if (ql2d > 0) state = ql2d;
		// right
		else if (qrc > 0) state = qrc;
		else if (qru > 0) state = qru;
		else if (qrd > 0) state = qrd;
		else if (qr2c > 0) state = qr2c;
		else if (qr2u > 0) state = qr2u;
		else if (qr2d > 0) state = qr2d;
		// top
		else if (qtc > 0) state = qtc;
		else if (qtl > 0) state = qtl;
		else if (qtr > 0) state = qtr;
		else if (qt2c > 0) state = qt2c;
		else if (qt2l > 0) state = qt2l;
		else if (qt2r > 0) state = qt2r;
		// bottom
		else if (qbc > 0) state = qbc;
		else if (qbl > 0) state = qbl;
		else if (qbr > 0) state = qbr;
		else if (qb2c > 0) state = qb2c;
		else if (qb2l > 0) state = qb2l;
		else if (qb2r > 0) state = qb2r;

		else state = 0;
	end
	*/
	
endmodule

module centernode(x, y, board_flat, q);
	input [2:0] x, y;
	input [7*7*2-1:0] board_flat;
	output wire [1:0] q;
	wire h, v, dil, dir;
	node cn(.x(x), .y(y), .board_flat(board_flat), .h(h), .v(v), .dil(dil), .dir(dir));
	assign q = (x >= 2 && x <= 4 && y >= 2 && y <= 4) && (h || v || dil || dir);
endmodule

module edgenode(x, y, board_flat, q);
	input [2:0] x, y;
	input [7*7*2-1:0] board_flat;
	output wire [1:0] q;
	wire h, v, dil, dir;
	node cn(.x(x), .y(y), .board_flat(board_flat), .h(h), .v(v), .dil(dil), .dir(dir));
	assign q = ((x < 2 || x > 4) && v) || ((y < 2 || y > 4) && h);
endmodule

module node(x, y, board_flat, h, v, dil, dir);
	input [2:0] x, y;
	input [7*7*2-1:0] board_flat;
	wire [1:0] board [7*7-1:0];
	genvar i;
	generate for (i = 0; i < 7*7; i = i + 1) begin:unflatten
		assign board[i] = board_flat[2*i+1:2*i];
	end endgenerate
	reg [1:0] c, l, l2, r, r2, u, u2, d, d2, ul, ul2, ur, ur2, dl, dl2, dr, dr2;
	output reg h, v, dil, dir;
	always@(*)
	begin
		c = board[7*x + y];
		l = board[7*(x - 1) + y ];	
		l2 = board[7*(x - 2) + y];
		r = board[7*(x + 1) + y];
		r2 = board[7*(x + 2) + y];
		u = board[7*x + y - 1];
		u2 = board[7*x + y - 2];
		d = board[7*x + y + 1];
		d2 = board[7*x + y + 2];
		ul = board[7*(x - 1) + y - 1];
		ul2 = board[7*(x - 2) + y - 2];
		ur = board[7*(x + 1) + y - 1];
		ur2 = board[7*(x + 2) + y - 2];
		dl = board[7*(x - 1) + y + 1];
		dl2 = board[7*(x - 2) + y + 2];
		dr = board[7*(x + 1) + y + 1];
		dr2 = board[7*(x + 2) + y + 2];
		
		h = l == c && l2 == c && r == c && r2 == c;
		v = u == c && u2 == c && d == c && d2 == c;
		dil = ul == c && ul2 == c && dr == c && dr2 == c;
		dir = ur == c && ur2 == c && dl == c && dl2 == c;
	end
endmodule

module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule
