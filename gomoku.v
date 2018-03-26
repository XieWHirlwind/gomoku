module gomoku(CLOCK_50, PS2_CLK, PS2_DAT, KEY);
	input CLOCK_50;
	inout PS2_CLK, PS2_DAT;
	input [3:0] KEY;
	wire w, a, s, d, left, right, up, down, space, enter;
	wire in_x, in_y, in_color;
	wire [1:0] game_state;
	
	board7 game_board(.clk(CLOCK_50), .resetn(KEY[0]), .go(enter), .x(in_x), .y(in_y), .color(in_color), .state(game_state));
	
	keyboard_tracker #(.PULSE_OR_HOLD(0)) keyboard(.clock(CLOCK_50), .reset(KEY[0]),
																  .PS2_CLK(PS2_CLK), .PS2_DAT(PS2_DAT),
																  .w(w), .a(a), .s(s), .d(d),
																  .left(left), .right(right), .up(up), .down(down),
																  .space(space), .enter(enter));
	
endmodule

module board7(clk, resetn, go, x, y, color, state);
	input clk;
	input resetn;
	input go;                       // load a stone onto the board
	input [2:0] x, y;               // coordinates of new move played. x = row, y = col.
	input color;                    // current player turn. 0 = black, 1 = white. game starts with black.
	reg [1:0] board [7*7-1:0];      // 7x7 array for board. for each coordinate, 0 = no move, 1 = black move, 2 = white move
	wire [7*7*2-1:0] board_flat;     // flattened board array for passing to modules
	output reg [1:0] state;         // 0 = indeterminate, 1 = black win, 2 = white win.
	
	integer i;
	always@(posedge clk)
	begin
		if (!resetn)
		begin
			for (i = 0; i < 7*7; i = i + 1) begin
				board[i] <= 2'b0;
			end
		end
		else if (go)
			board[7*x + y] <= color + 2'd1;
	end
	
	genvar j;
	generate for (j = 0; j < 7*7; j = j + 1) begin:flatten
		assign board_flat[2*j + 1:2*j] = board[j];
	end endgenerate
	
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

	
	/*function get_state;
		input [4:0] cx, cy;
		input ccolor;
		reg [2:0] counter [7:0]; // counter for each direction
		reg [2:0] dir;
		
		reg [9:0] neighbours [7:0];
		assign neighbours = get_neighbours(cx, cy);
		
		reg [2:0] i;
		reg [1:0] j;
		
		always @(*)
		begin
			for (i = 0; i < 8; i += 1)
			begin
				if (board[neighbours[i][9:5]][neighbours[i][4:0]] == ccolor)
				begin
					j = get_state_helper(cx, cy, ccolor, i);
					counter[i] = j;
					// helper func to check in this direction 4 times
					// helper func returns the amount of times it goes in that direction
					// += to the counter
				end
				//end
			end
			get_state = (counter[0] + counter[4] >= 4 || counter[1] + counter[5] >= 4 || counter[2] + counter[6] >= 4 || counter[3] + counter[7] >= 4) ? ccolor : 0;
		end
		
	endfunction
	
	
	
	function get_state_helper;
		input [4:0] hx, hy;
		input hcolor;
		input [2:0] dir;
		
		reg [2:0] j0, j1, j2, j3;
		reg [9:0] j0_neighbours [7:0];
		reg [9:0] j1_neighbours [7:0];
		reg [9:0] j2_neighbours [7:0];
		reg [9:0] j3_neighbours [7:0];
		assign j0_neighbours = get_neighbours(hx, hy);
		assign j0 = j0_neighbours[dir];
		assign j0_value = board[j0[9:5]][j0[4:0]] == hcolor;
		
		assign j1_neighbours = get_neighbours(j0[9:5], j0[4:0])
		assign j1 = j1_neighbours[dir];
		assign j1_value = board[j1[9:5]][j1[4:0]] == hcolor;
		
		assign j2_neighbours = get_neighbours(j1[9:5], j1[4:0])
		assign j2 = j2_neighbours[dir];
		assign j2_value = board[j2[9:5]][j2[4:0]] == hcolor;
		
		assign j3_neighbours = get_neighbours(j2[9:5], j2[4:0])
		assign j3 = j3_neighbours[dir];
		assign j3_value = board[j3[9:5]][j3[4:0]] == hcolor;
		
		assign get_state_helper = j0_value + j1_value + j2_value + j3_value;
		
	endfunction
	
	function get_neighbours;
		input [4:0] ix, iy;
		reg [9:0] neighbours [7:0];  // first 5 bits are x, 5 bits after are y. 0 is top, goes cw.
		
		reg [4:0] ix_p1, ix_m1, iy_p1, iy_m1; // calculate for edge cases so we dont have values that are out of bounds
		
		assign ix_p1 = ix == 5'd18 ? ix - 1 : ix + 1;
		assign ix_m1 = ix == 5'd0 ? ix + 1 : ix - 1;
		assign iy_p1 = iy == 5'd18 ? iy - 1 : iy + 1;
		assign iy_m1 = iy == 5'd0 ? iy + 1 : iy - 1;
		
		always@(*)
		begin
			neighbours[0] = {ix, iy_m1};
			neighbours[1] = {ix_p1, iy_m1};
			neighbours[2] = {ix_p1, iy};
			neighbours[3] = {ix_p1, iy_p1};
			neighbours[4] = {ix, iy_p1};
			neighbours[5] = {ix_p1, iy_p1};
			neighbours[6] = {ix_p1, iy};
			neighbours[7] = {ix_p1, iy_p1};
			get_neighbours = neighbours;
		end
		
	endfunction*/

