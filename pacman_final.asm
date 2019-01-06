;Copyright (c) 2019 kelvinjguan
;MIT License
;Licensed under MIT license.


INCLUDE Irvine32.inc

.data
	filename1 BYTE "pacman1.txt",0
	filename2 BYTE "pacman2.txt",0
	filename3 BYTE "pacman3.txt",0
	BUFFER_SIZE = 5000
	buffer BYTE BUFFER_SIZE DUP(?)
	bytesRead DWORD ?
	
	menu BYTE "1. Start new game (S)", 0,
		"2. Print Map (P)     ", 0, 
		"3. End Game (E)      ", 0,
		"4. Move Up (U)       ", 0,
		"5. Move Down (D)     ", 0, 
		"6. Move Left (L)     ", 0,
		"7. Move Right (R)    ", 0

	Pacman BYTE "    ", 0

	posPacman BYTE "Position of the Pacman (@) is: (", 0
	posGhost BYTE "Position of the Ghost ($) is: ", 0
	getInput BYTE "INPUT: ", 0
	error BYTE "Wrong move. Please try again.", 0
	finish BYTE "No ghosts left.", 0
	choosemap BYTE "Input 1 for map 1 and 2 for map 2. (enter 3 for demo map)", 0

	userInput BYTE ?
	row DWORD 1
	col DWORD 0
	ghost DWORD 0
	pos SDWORD 0
	found DWORD 0
	fileinfo DWORD 0
	cont DWORD 0

.code
main PROC
	mov al, '1'
	call LOADMAP
	GAME:
		call PRINTMAP ;prints map
		call POSITION ;prints position

		push OFFSET menu
		call GAMEMENU ;prints gamemenu
		
		GO::
		call INPUT ;retrives user input

		.IF al == 's' ;starts new game, (map 1 * map 2 * map 3)
			mov edx, OFFSET choosemap
			call WriteString
			call Crlf
			call INPUT
			call LOADMAP
			jmp GAME

		.ELSEIF al == 'p' ;prints the pacman map
			jmp GAME ;jumps to the game condition
		
		.ELSEIF al == 'e' ;ends game
			exit
			jmp GAME
		
		.ELSEIF al == 'u' ;moves pacman "up"
			mov pos, -14d
			call MOVEPACMAN ;moves pacman
			call Clrscr ;clears the screen after the move is completed
			jmp GAME
		
		.ELSEIF al == 'd' ;moved pacman "down"
			mov pos, 14d
			call MOVEPACMAN
			call Clrscr
			jmp GAME
		
		.ELSEIF al == 'l' ; move left
			mov pos, -1d
			call MOVEPACMAN
			call Clrscr
			jmp GAME
		
		.ELSEIF al == 'r' ; move right
			mov pos, 1d
			call MOVEPACMAN
			call Clrscr
			jmp GAME
		
		.ELSE
			mov edx, OFFSET error ;prints error if the correct key is not logged
			call WriteString
			mov eax, 1000
			call Delay
			jmp GAME
		.ENDIF
	exit
main ENDP
;----------------------------

LOADMAP proc ;load the game map text file into memory
	.IF al == '1'
		mov edx, OFFSET filename1 ;map 1
	.ELSEIF al == '2'
		mov edx, OFFSET filename2 ;map 2
	.ELSE
		mov edx, OFFSET filename3 ;map 3
	.ENDIF

	;loading the map text into memory
	call OpenInputFile
	mov fileinfo, eax
	mov edx,OFFSET buffer 
	mov ecx,BUFFER_SIZE 
	call ReadFromFile
	mov bytesRead, eax
	mov eax, fileinfo
	call CloseFile
	
	ret

LOADMAP ENDP
;----------------------------

PRINTMAP proc ;print the game map onto the console
	mov edx, OFFSET buffer
	call WriteString
	call crlf
	call crlf
	ret

PRINTMAP ENDP
;----------------------------

POSITION proc ;prints location of both the pacman and ghosts (@ & $), in a (x,y) coordinate
	mov col, 0
	mov row, 1

	mov esi, OFFSET buffer
	mov ecx, bytesRead

	findPacman:
		inc col
		mov al, [esi]
		cmp al, '@'
		je FOUND_PACMAN

		cmp col, 14d
		jne CONTINUE
		inc row
		mov col, 0

		CONTINUE:
		add esi, 1

		loop findPacman

	FOUND_PACMAN:
		mov edx, OFFSET posPacman
		call WriteString

		mov eax, row
		call WriteDec
		mov al, ','
		call WriteChar
		mov eax, col
		call WriteDec
		mov al, ')'
		call WriteChar
		call crlf
		
	mov col, 0
	mov row, 1
	mov found, 0

	mov esi, OFFSET buffer
	mov ecx, bytesRead

	mov edx, OFFSET posGhost
	call WriteString

	findGhost:
		inc col
		mov al, [esi]
		cmp al, '$'
		jne NOTFOUND
		
		inc found
		mov al, '('
		call WriteChar
		mov eax, row
		call WriteDec
		mov al, ','
		call WriteChar
		mov eax, col
		call WriteDec
		mov al, ')'
		call WriteChar

		NOTFOUND:
			cmp col, 14d
			jne CONTINUE2
			inc row
			mov col, 0

		CONTINUE2:
			add esi, 1
		
		loop findGhost
	
	mov ebx, found
	.IF ebx == 0
		mov edx, OFFSET finish
		call WriteString
		call crlf
		call OVER
	.ENDIF
		call crlf
		call crlf
	ret

POSITION ENDP
;----------------------------
INPUT proc ; game menu for Pacman which should contain certain options
	mov edx, OFFSET getInput
	call WriteString
	
	LookForKey:
		mov  eax,50          ; sleep, to allow OS to time slice
		call Delay           ; (otherwise, some key presses are lost)

		call ReadKey         ; look for keyboard input
		jz   LookForKey      ; no key pressed yet
		
		call WriteChar	
		call crlf
		
		ret

INPUT ENDP
;----------------------------

MOVEPACMAN proc ;move pacman in the direction of up, down, left, right
	mov esi, OFFSET buffer
	mov ecx, bytesRead
	findPacman:
		mov al, [esi]
		cmp al, '@'
		je FOUNDPACMAN
		add esi, 1
		loop findPacman

	FOUNDPACMAN:
		mov edi, esi
		add  edi, pos
		mov al, [edi]
		.IF al == '*'
			mov edx, OFFSET error
			call WriteString
			call crlf
			mov  eax,1000 
			call Delay 
		.ELSE 
			mov bl, '@'
			mov [edi], bl
			call CHECKGHOST
		.ENDIF
			
	ret

MOVEPACMAN ENDP
;----------------------------

CHECKGHOST proc ;ghost converts into '#' once touched by pacman
	.IF ghost == 1
		mov bl, '#'
		mov [esi], bl
		mov ghost, 0
	.ELSE
		mov bl, ' '
		mov [esi], bl
	.ENDIF
	
	.IF al == '$' || al == '#'
		mov ghost, 1
	.ELSE
		mov ghost, 0
	.ENDIF

	ret
CHECKGHOST ENDP
;----------------------------

GAMEMENU proc ;game menu for Pacman which should contain certain options	
	menuoffset EQU [ebp+8]
	enter 0,0
	pushad
	
	mov edx, menuoffset
	mov ecx, 8
	L1:
		call WriteString
		call crlf
		cmp ecx, 1
		je L2
		add edx, 22
		loop L1

		L2:
		call crlf
	popad
	leave
	ret 4

GAMEMENU ENDP
;----------------------------

OVER proc ;gameover proc, with options of:: S,P,E
	mov edx, OFFSET menu
	mov ecx, 3
	L1: ;loops the input
		call WriteString
		call crlf
		cmp ecx, 1
		je L2
		add edx, 22
		loop L1

		L2: ;continues after getting input
		call crlf
		call GO
	ret
	
OVER ENDP
;----------------------------

end main  
