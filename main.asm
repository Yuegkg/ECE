;***********************************************************
;*
;*	Transmitter
;*
;*	Enter the description of the program here
;*
;*	This is the TRANSMIT skeleton file for Lab 8 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Xinyu Ma & Yue Fan
;*	   Date: 11.24
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multi-Purpose Register

.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit
; Use these action codes between the remote and robot
; MSB = 1 thus:
; control signals are shifted right by one and ORed with 0b10000000 = $80
.equ	ID = $2B
.equ	MovFwd =  ($80|1<<(EngDirR-1)|1<<(EngDirL-1))	;0b10110000 Move Forward Action Code
.equ	MovBck =  ($80|$00)								;0b10000000 Move Backward Action Code
.equ	TurnR =   ($80|1<<(EngDirL-1))					;0b10100000 Turn Right Action Code
.equ	TurnL =   ($80|1<<(EngDirR-1))					;0b10010000 Turn Left Action Code
.equ	Halt =    ($80|1<<(EngEnR-1)|1<<(EngEnL-1))		;0b11001000 Halt Action Code
.equ	Freeze =  ($80|1<<(EngEnR-1)|1<<(EngEnL-1)|1<<(EngDirR-1)|1<<(EngDirL-1))		;0b11111000 Freeze Action Code
;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt
.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
	;Stack Pointer (VERY IMPORTANT!!!!)
	; Initialize the Stack Pointer    
	ldi mpr, high(RAMEND)   
	out SPH, mpr   
	ldi mpr, low(RAMEND)   
	out SPL, mpr   
	;I/O Ports
	ldi mpr, $FF   
	out DDRB, mpr    ; set B output    
	ldi mpr, $00   
	out PORTB, mpr    ; All outputs low initially 
 
  ; Initialize Port D for input   

    ldi mpr, 0b00000100 ;make bit 3 for output transmitter
    out DDRD, mpr ; Set the DDR register for Port D   
    ldi mpr, 0b11110011 ;unable bit 2 and 3 for transmitter and receiver, all other are pull-up resistor enabled
    out PORTD, mpr ; 
	;USART1
	;Set baudrate at 2400bps
	ldi  mpr, high(832)  ; Set baud rate to 2,400 with f = 16 MHz  
	sts  UBRR1H, mpr  ; 
	ldi  mpr, low(832)   ; Set baud rate to 2,400 with f = 16 MHz  
	sts  UBRR1L, mpr  ; 
	
	ldi mpr, 1<<U2X1	;set double data rate
	sts UCSR1A, mpr

	;Enable transmitter
	ldi  mpr, (1<<TXEN1|0<<UCSZ12);| 1<<RXEN1); | 1<<RXCIE1) ; Enable Transmitter, receiver and recive interrupt  
	sts  UCSR1B, mpr  ;   

	
	;Set frame format: 8 data bits, 2 stop bits, disable parity bit, asynchronous
	ldi	 mpr, (0<<UMSEL1|0<<UCPOL1|1<<USBS1|0<<UPM11|0<<UPM10|1<<UCSZ11|1<<UCSZ10) 
	sts	 UCSR1C, mpr
	
;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		in	mpr,PIND
		sbrc mpr,0 ;check if bit 0 is down(button 0 is pushed)
		rjmp	Push1
		rcall	Turnleft
Push1:	sbrc mpr,1 ;check if bit 1 is down(button 1 is pushed)
		rjmp	Push4
		rcall	Turnright
Push4:	sbrc mpr,4 ;check if bit 4 is down(button 4 is pushed)
		rjmp	Push5
		rcall	movefoward
Push5:	sbrc mpr,5 ;check if bit 5 is down(button 5 is pushed)
		rjmp	Push6
		rcall	moveback
Push6:	sbrc mpr,6 ;check if bit 6 is down(button 0 is pushed)
		rjmp	Push7
		rcall	send_halt
Push7:	sbrc mpr,7 ;check if bit 7 is down(button 0 is pushed)
		rjmp	MAIN
		rcall	send_Freeze

		rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
Turnleft:
		push	mpr			; Save mpr register
		
		in		mpr, SREG	; Save program state
		push	mpr			;
		
USART_TransmitH1:
		lds	 mpr,UCSR1A
		sbrs mpr, UDRE1 ;check if the empty buffer flag is set, if set, can write to transmit buffer
		rjmp USART_TransmitH1

		ldi	 mpr, ID ;put the robotID(MSB) into transmit buffer
		sts	 UDR1, mpr

USART_TransmitL1:
		lds	 mpr,UCSR1A
		sbrs mpr, UDRE1 ;check if the empty buffer flag is set, if set, can write to transmit buffer
		rjmp USART_TransmitL1 

		ldi  mpr, TurnL
		sts  UDR1, mpr 

		pop		mpr		; Restore program state
		out		SREG, mpr	;

		pop		mpr		; Restore mpr

		ret				; Return from subroutine



Turnright:
		push	mpr			; Save mpr register
	
		in		mpr, SREG	; Save program state
		push	mpr			;
		
USART_TransmitH2:
		lds	 mpr,UCSR1A
		sbrs mpr, UDRE1 ;check if the empty buffer flag is set, if set, can write to transmit buffer
		rjmp USART_TransmitH2

		ldi	 mpr, ID ;put the robotID(MSB) into transmit buffer
		sts	 UDR1, mpr

USART_TransmitL2:
		lds	 mpr,UCSR1A
		sbrs mpr, UDRE1 ;check if the empty buffer flag is set, if set, can write to transmit buffer
		rjmp USART_TransmitL2 

		ldi  mpr, TurnR
		sts  UDR1, mpr 

		pop		mpr		; Restore program state
		out		SREG, mpr	;

		pop		mpr		; Restore mpr

		ret				; Return from subroutine
movefoward:
		push	mpr			; Save mpr register
		
		in		mpr, SREG	; Save program state
		push	mpr			;
		
USART_TransmitH3:
		lds	 mpr,UCSR1A
		sbrs mpr, UDRE1 ;check if the empty buffer flag is set, if set, can write to transmit buffer
		;sbis UCSR1A, UDRE1
		rjmp USART_TransmitH3

		ldi	 mpr, ID ;put the robotID(MSB) into transmit buffer
		sts	 UDR1, mpr

USART_TransmitL3:
		lds	 mpr,UCSR1A
		sbrs mpr,UDRE1  ;check if the empty buffer flag is set, if set, can write to transmit buffer
		rjmp USART_TransmitL3 

		ldi  mpr, MovFwd
		sts  UDR1, mpr 

		pop		mpr		; Restore program state
		out		SREG, mpr	;

		pop		mpr		; Restore mpr

		ret				; Return from subroutine	
moveback:
		push	mpr			; Save mpr register
		
		in		mpr, SREG	; Save program state
		push	mpr			;
		
USART_TransmitH4:
		lds	 mpr,UCSR1A
		sbrs mpr, UDRE1 ;check if the empty buffer flag is set, if set, can write to transmit buffer
		rjmp USART_TransmitH4

		ldi	 mpr, ID ;put the robotID(MSB) into transmit buffer
		sts	 UDR1, mpr

USART_TransmitL4:
		lds	 mpr,UCSR1A
		sbrs mpr, UDRE1 ;check if the empty buffer flag is set, if set, can write to transmit buffer
		rjmp USART_TransmitL4 

		ldi  mpr, MovBck
		sts  UDR1, mpr 

		pop		mpr		; Restore program state
		out		SREG, mpr	;

		pop		mpr		; Restore mpr

		ret				; Return from subroutine	
send_halt:
		push	mpr			; Save mpr register
		
		in		mpr, SREG	; Save program state
		push	mpr			;
		
USART_TransmitH6:
		lds	 mpr,UCSR1A
		sbrs mpr, UDRE1 ;check if the empty buffer flag is set, if set, can write to transmit buffer
		rjmp USART_TransmitH6

		ldi	 mpr, ID ;put the robotID(MSB) into transmit buffer
		sts	 UDR1, mpr

USART_TransmitL6:
		lds	 mpr,UCSR1A
		sbrs mpr, UDRE1 ;check if the empty buffer flag is set, if set, can write to transmit buffer
		rjmp USART_TransmitL6 

		ldi  mpr, Halt
		sts  UDR1, mpr 

		pop		mpr		; Restore program state
		out		SREG, mpr	;
		
		pop		mpr		; Restore mpr

		ret				; Return from subroutine
send_Freeze:
		push	mpr			; Save mpr register
		
		in		mpr, SREG	; Save program state
		push	mpr			;
		
USART_TransmitH5:
		lds	 mpr,UCSR1A
		sbrs mpr, UDRE1 ;check if the empty buffer flag is set, if set, can write to transmit buffer
		rjmp USART_TransmitH5

		ldi	 mpr, ID ;put the robotID(MSB) into transmit buffer
		sts	 UDR1, mpr

USART_TransmitL5:
		lds	 mpr,UCSR1A
		sbrs mpr, UDRE1 ;check if the empty buffer flag is set, if set, can write to transmit buffer
		rjmp USART_TransmitL5 

		ldi  mpr, Freeze
		sts  UDR1, mpr 

		pop		mpr		; Restore program state
		out		SREG, mpr	;
		
		pop		mpr		; Restore mpr

		ret				; Return from subroutine	
;***********************************************************
;*	Stored Program Data
;***********************************************************

;***********************************************************
;*	Additional Program Includes
;***********************************************************