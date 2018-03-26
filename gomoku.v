module gomoku;

endmodule

module board(clk, resetn, go, x, y, color, state);
	input clk;
	input resetn;
	input go;                       // load a stone onto the board
	input [2:0] x, y;               // coordinates of new move played. x = row, y = col.
	input color;                    // current player turn. 0 = black, 1 = white. game starts with black.
	reg [1:0] board [6:0][6:0];     // 2d array for board. for each coordinate, 0 = no move, 1 = black move, 2 = white move
	output reg [1:0] state;         // 0 = indeterminate, 1 = black win, 2 = white win.
	
	integer i, j;
	always@(posedge clk)
	begin
		if (!resetn)
		begin
			for (i = 0; i < 7; i = i + 1) begin
				for (j = 0; j < 7; j = j + 1) begin
					board[i][j] <= 2'b0;
				end
			end
		end
		else if (go)
			board[x][y] <= color + 2'd1;
	end
	
	// only need node modules for middle 9 points on 7x7 board
	reg qc, qu, qur, qr, qdr, qd, qdl, ql, qul;
	node nc(.x(3'd3), .y(3'd3), .q(qc)),
		  nu(.x(3'd3), .y(3'd2), .q(qu)),
		  nur(.x(3'd4), .y(3'd2), .q(qur)),
		  nr(.x(3'd4), .y(3'd3), .q(qr)),
		  ndr(.x(3'd4), .y(3'd4), .q(qdr)),
		  nd(.x(3'd3), .y(3'd4), .q(qd)),
		  ndl(.x(3'd2), .y(3'd4), .q(qdl)),
		  nl(.x(3'd2), .y(3'd3), .q(ql)),
		  nul(.x(3'd2), .y(3'd2), .q(qul));
	
	always@(*)
	begin
		if (qc > 0) state = qc;
		else if (qu > 0) state = qu;
		else if (qur > 0) state = qur;
		else if (qr > 0) state = qr;
		else if (qdr > 0) state = qdr;
		else if (qd > 0) state = qd;
		else if (qdl > 0) state = qdl;
		else if (ql > 0) state = ql;
		else if (qul > 0) state = qul;
		else state = 0;
	end
	
	
endmodule

module node(x, y, q);
	input [2:0] x, y;
	output reg [1:0] q;
	reg [1:0] c, l, l2, r, r2, u, u2, d, d2, ul, ul2, ur, ur2, dl, dl2, dr, dr2;
	reg h, v, dil, dir;
	always@(*)
	begin
		c = board[x][y];
		l = board[x - 1][y];
		l2 = board[x - 2][y];
		r = board[x + 1][y];
		r2 = board[x + 2][y];
		u = board[x][y - 1];
		u2 = board[x][y - 2];
		d = board[x][y + 1];
		d2 = board[x][y + 2];
		ul = board[x - 1][y - 1];
		ul2 = board[x - 2][y - 2];
		ur = board[x + 1][y - 1];
		ur2 = board[x + 2][y - 2];
		dl = board[x - 1][y + 1];
		dl2 = board[x - 2][y + 2];
		dr = board[x + 1][y + 1];
		dr2 = board[x + 2][y + 2];
		
		h = l == c && l2 == c && r == c && r2 == c;
		v = u == c && u2 == c && d == c && d2 == c;
		dil = ul == c && ul2 == c && dr == c && dr2 == c;
		dir = ur == c && ur2 == c && dl == c && dl2 == c;
		
		q = (x >= 2 && x <= 4 && y >= 2 && y <= 4) && (h || v || dil || dir);
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

