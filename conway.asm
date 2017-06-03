; Conway's Game of Life - Taylor Adamson

.orig x3000

and R0, R0, #0
and R1, R1, #0
and R2, R2, #0
and R3, R3, #0
and R4, R4, #0
and R5, R5, #0
and R6, R6, #0
and R7, R7, #0

WELCOME 	  .stringz "[ Conway's Game of Life ]\n\nPattern? (x - exit)\ng - Glider\nl - LWSS\ns - Small exploder\ne - Exploder\nn - Glider gun\no - P22 Oscillator\n> "
DONE    	  .stringz "\nSimulation complete.\n\n"
INPUT_F 	  .stringz "\nERROR: Invalid input\n> "
BREAK   	  .stringz "\n"
SPACER  	  .stringz "\n\n\n\n\n\n\n\n\n\n\n"

jsr GRIDPOINTER  ; store grid address in grid pointer
jsr CLEAR 		 ; populate the grid with dead cells

MENU
	lea R0, WELCOME
	puts

INIT
	getc
	out
	add R1, R0, #0 	 	 ; input buffer

	ld R2, KX
	add R2, R1, R2  	 ; test for exit key first
	BRz EXIT

	jsr PATTERNPOINTERS  ; store pattern addresses in their respective pointers
	lea R4, KGLIDER      ; pointer to first key constant
	lea R5, G_P 	     ; pointer to first pattern
	ld R6, ITEMS

	INIT_ITER
		ldr R2, R4, #0 	 ; store current key in R2
		ldr R3, R5, #0   ; store current pattern in R3
		jsr KEYCHECK

		add R4, R4, #1   ; advance key pointer
		add R5, R5, #1   ; advance pattern pointer
		add R6, R6, #-1  ; advance loop step
		BRp INIT_ITER

	lea R0, INPUT_F
	puts
	BRnzp INIT

RUN
	jsr LOAD  ; pattern address was loaded into R3

	DRAW
		jsr RENDER

	STEP
		jsr PROCESS

	UPDATE
		jsr RESOLVE

	WAIT
		getc
		ld R2, KSUSPEND
		add R0, R0, R2  ; test for suspend key
		BRnp DRAW

RESTART
	lea R0, DONE
	puts
	jsr CLEAR

EXIT
	halt

KEYCHECK
	add R2, R1, R2  ; test key constant
	BRz RUN
	ret

RENDER
	lea R0, SPACER
	puts
	ld R1, GRID_P
	and R2, R2, #0	; clear R2 for grid step
	and R3, R3, #0  ; clear R3 for row check

	RENDER_ITER
		ldr R0, R1, #0  ; store cell at current index in R0
		out
		add R3, R3, #1  ; advance row checker
		ld R5, CELLS_R
		add R6, R3, R5  ; test for new row
		BRn NO_BREAK

		and R3, R3, #0	; reset row checker
		lea R0, BREAK	; add a line break
		puts

		NO_BREAK
			jsr ITER
			add R4, R2, R5	; bounds check
			BRn RENDER_ITER	; continue if grid step is < cell total
			BRnzp STEP 		; then wait for user to advance simulation

LOAD
	ldr R2, R3, #0  ; store pattern index in R2
	add R5, R2, #0  ; test for terminating value
	BRn DRAW

	ld R1, GRID_P
	ld R4, ALIVE
	add R1, R1, R2  ; move to pattern index in grid
	str R4, R1, #0	; mark cell as living
	add R3, R3, #1  ; advance pattern pointer
	BRnzp LOAD

PROCESS
	ld R1, GRID_P
	and R2, R2, #0	; clear R2 for grid step

	PROCESS_ITER
		and R3, R3, #0  ; clear R3 for neighbor count
		ld R4, DIRS
		lea R5, N

		DIRS_ITER
			ldr R6, R5, #0  ; store dir constant in R6
			add R6, R2, R6  ; store index of neighbor in R6

			; cells outside of grid are considered dead
			add R6, R6, #0
			BRn SKIP
			ld R0, CELLS
			add R0, R6, R0
			BRp SKIP

			ld R7, GRID_P
			add R7, R7, R6  ; advance to that index in grid
			ldr R0, R7, #0  ; store that cell in R0
			ld R6, CHECK
			add R0, R0, R6  ; test neighbor for cell life
			BRn SKIP

			add R3, R3, #1

			SKIP
				add R5, R5, #1   ; advance dirs pointer
				add R4, R4, #-1  ; advance loop step
				BRp DIRS_ITER

		jsr CELLCHECK

		CELL_RESOLVED
			jsr ITER
			add R4, R2, R5  ; bounds check
			BRn PROCESS_ITER
			BRnzp UPDATE

CELLCHECK
	ldr R4, R1, #0  ; store current cell in R4
	ld R5, CHECK
	add R5, R4, R5  ; determine living status of cell
	BRn REVIVECHECK
	ld R4, CROWDED
	add R5, R3, R4  ; kill if cell has 4 or more neighbors
	BRzp DIE
	ld R4, ALONE
	add R5, R3, R4  ; kill if cell has 1 or no neighbors
	BRnz DIE
	BRnzp CELL_RESOLVED

	REVIVECHECK
		ld R4, REVIVE
		add R5, R3, R4  ; revive if dead cell has 3 neighbors
		BRnp CELL_RESOLVED
		ld R4, SAVE
		str R4, R1, #0
		BRnzp CELL_RESOLVED

	DIE
		ld R4, KILL
		str R4, R1, #0
		BRnzp CELL_RESOLVED

RESOLVE
	ld R1, GRID_P
	and R2, R2, #0

	RESOLVE_ITER
		ldr R3, R1, #0
		ld R4, SAVE
		not R4, R4
		add R4, R4, #1
		add R4, R3, R4  ; determine if cell needs to be revived
		BRz TO_LIVE
		ld R4, KILL
		not R4, R4
		add R4, R4, #1
		add R4, R3, R4  ; determine if cell needs to be killed
		BRz TO_DEAD
		BRnzp COMPLETE

		TO_LIVE
			ld R4, ALIVE
			str R4, R1, #0
			BRnzp COMPLETE

		TO_DEAD
			ld R4, DEAD
			str R4, R1, #0

	COMPLETE
		jsr ITER
		add R4, R2, R5	; bounds check
		BRn RESOLVE_ITER
		BRnzp WAIT

CLEAR
	ld R1, GRID_P
	and R2, R2, #0

	CLEAR_ITER
		ld R3, DEAD
		str R3, R1, #0	; mark cell as dead
		jsr ITER
		ld R3, CELLS
		add R4, R2, R3  ; bounds check
		BRn CLEAR_ITER
		BRnzp MENU

ITER
	add R1, R1, #1	; advance grid pointer
	add R2, R2, #1  ; advance grid step
	ld R5, CELLS
	ret

GRIDPOINTER
	lea R0, GRID
	st R0, GRID_P
	ret

PATTERNPOINTERS
	lea R0, GLIDER
	st R0, G_P
	lea R0, LWSS
	st R0, L_P
	lea R0, EXPLODER_S
	st R0, S_P
	lea R0, EXPLODER
	st R0, E_P
	lea R0, GLIDER_GUN
	st R0, N_P
	lea R0, OSCILLATOR
	st R0, O_P
	ret

GRID_P 		  .blkw 1
G_P 		  .blkw 1
L_P 		  .blkw 1
S_P  		  .blkw 1
E_P  		  .blkw 1
N_P  		  .blkw 1
O_P 		  .blkw 1

ASCII    	  .fill 48
ITEMS 		  .fill 6
KSUSPEND  	  .fill -27
KX        	  .fill -120
KGLIDER   	  .fill -103
KLWSS 		  .fill -108
KEXPLODER_S   .fill -115
KEXPLODER 	  .fill -101
KGLIDER_GUN   .fill -110
KOSCILLATOR   .fill -111
CELLS 	 	  .fill -760
CELLS_R  	  .fill -40
ALIVE 	 	  .fill 35
DEAD	 	  .fill 32
CHECK 	 	  .fill -35
REVIVE 	 	  .fill -3
CROWDED  	  .fill -4
ALONE 	 	  .fill -1
SAVE 	 	  .fill 33
KILL 	 	  .fill 36
DIRS 	 	  .fill 8
N 		 	  .fill -40
NE 		 	  .fill -39
E 		 	  .fill 1
SE 		 	  .fill 41
S 		 	  .fill 40
SW 		 	  .fill 39
W 		 	  .fill -1
NW 		 	  .fill -41

GLIDER        .fill 1
		      .fill 42
		      .fill 80
		      .fill 81
		      .fill 82
		      .fill -1
LWSS    	  .fill 0
			  .fill 3
			  .fill 44
			  .fill 80
			  .fill 84
			  .fill 121
			  .fill 122
			  .fill 123
			  .fill 124
			  .fill 596
			  .fill 599
			  .fill 635
			  .fill 675
			  .fill 679
			  .fill 718
			  .fill 717
			  .fill 716
			  .fill 715
			  .fill -1
EXPLODER_S    .fill 340
			  .fill 379
			  .fill 380
			  .fill 381
			  .fill 419
			  .fill 421
			  .fill 460
			  .fill -1
EXPLODER 	  .fill 338
			  .fill 340
			  .fill 342
			  .fill 378
			  .fill 382
			  .fill 418
			  .fill 422
			  .fill 458
			  .fill 462
			  .fill 498
			  .fill 500
			  .fill 502
			  .fill -1
GLIDER_GUN    .fill 25
			  .fill 63
			  .fill 65
			  .fill 93
			  .fill 94
			  .fill 101
			  .fill 102
			  .fill 115
			  .fill 116
			  .fill 132
			  .fill 136
			  .fill 141
			  .fill 142
			  .fill 155
			  .fill 156
			  .fill 161
			  .fill 162
			  .fill 171
			  .fill 177
			  .fill 181
			  .fill 182
			  .fill 201
			  .fill 202
			  .fill 211
			  .fill 215
			  .fill 217
			  .fill 218
			  .fill 223
			  .fill 225
			  .fill 251
			  .fill 257
			  .fill 265
			  .fill 292
			  .fill 296
			  .fill 334
			  .fill 333
			  .fill -1
OSCILLATOR    .fill 55
			  .fill 56
			  .fill 95
			  .fill 97
			  .fill 134
			  .fill 139
			  .fill 145
			  .fill 175
			  .fill 177
			  .fill 179
			  .fill 180
			  .fill 183
			  .fill 184
			  .fill 186
			  .fill 187
			  .fill 215
			  .fill 219
			  .fill 227
			  .fill 264
			  .fill 266
			  .fill 335
			  .fill 343
			  .fill 344
			  .fill 345
			  .fill 374
			  .fill 375
			  .fill 376
			  .fill 384
			  .fill 453
			  .fill 455
			  .fill 492
			  .fill 500
			  .fill 504
			  .fill 532
			  .fill 533
			  .fill 535
			  .fill 536
			  .fill 539
			  .fill 540
			  .fill 542
			  .fill 544
			  .fill 574
			  .fill 580
			  .fill 585
			  .fill 622
			  .fill 624
			  .fill 663
			  .fill 664
			  .fill -1

GRID 	 	  .blkw 760

.end