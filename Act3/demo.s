;Humberto Sanchez Rivera
.segment "HEADER"
  ; .byte "NES", $1A      ; iNES header identifier
  .byte $4E, $45, $53, $1A
  .byte 2               ; 2x 16KB PRG code
  .byte 1               ; 1x  8KB CHR data
  .byte $01, $00        ; mapper 0, vertical mirroring

.segment "VECTORS"
  ;; When an NMI happens (once per frame if enabled) the label nmi:
  .addr nmi
  ;; When the processor first turns on or is reset, it will jump to the label reset:
  .addr reset
  ;; External interrupt IRQ (unused)
  .addr 0

; "nes" linker config requires a STARTUP section, even if it's empty
.segment "STARTUP"

; Main code segment for the program
.segment "CODE"

reset:
  sei		; disable IRQs
  cld		; disable decimal mode
  ldx #$40
  stx $4017	; disable APU frame IRQ
  ldx #$ff 	; Set up stack
  txs		;  .
  inx		; now X = 0
  stx $2000	; disable NMI
  stx $2001 	; disable rendering
  stx $4010 	; disable DMC IRQs

;; first wait for vblank to make sure PPU is ready
vblankwait1:
  bit $2002
  bpl vblankwait1

clear_memory:
  lda #$00
  sta $0000, x
  sta $0100, x
  sta $0200, x
  sta $0300, x
  sta $0400, x
  sta $0500, x
  sta $0600, x
  sta $0700, x
  inx
  bne clear_memory

;; second wait for vblank, PPU is ready after this
vblankwait2:
  bit $2002
  bpl vblankwait2

main:
load_palettes:
  lda $2002 ;reads from the CPU-RAM PPU address register to reset it
  lda #$3f  ;loads the higher byte of the PPU address register of the palettes in a (we want to write in $3f00 of the PPU since it is the address where the palettes of the PPU are stored)
  sta $2006 ;store what's in a (higher byte of PPU palettes address register $3f00) in the CPU-RAM memory location that transfers it into the PPU ($2006)
  lda #$00  ;loads the lower byte of the PPU address register in a
  sta $2006 ;store what's in a (lower byte of PPU palettes address register $3f00) in the CPU-RAM memory location that transfers it into the PPU ($2006)
  ldx #$00  ;AFTER THIS, THE PPU-RAM GRAPHICS POINTER WILL BE POINTING TO THE MEMORY LOCATION THAT CONTAINS THE SPRITES, NOW WE NEED TO TRANSFER SPRITES FROM THE CPU-ROM TO THE PPU-RAM
            ;THE PPU-RAM POINTER GETS INCREASED AUTOMATICALLY WHENEVER WE WRITE ON IT

; NO NEED TO MODIFY THIS LOOP SUBROUTINE, IT ALWAYS LOADS THE SAME AMOUNT OF PALETTE REGISTER. TO MODIFY PALETTES, REFER TO THE PALETTE SECTION
@loop: 
  lda palettes, x   ; as x starts at zero, it starts loading in a the first element in the palettes code section ($0f). This address mode allows us to copy elements from a tag with .data directives and the index in x
  sta $2007         ;THE PPU-RAM POINTER GETS INCREASED AUTOMATICALLY WHENEVER WE WRITE ON IT
  inx
  cpx #$20
  bne @loop


BackgroundLoad:
	LDA $2002
	LDA $20
	STA $2006
	LDA #$00
	STA $2006
	LDX #$00
BackgroundLoop:
	LDA background, x 
	STA $2007
	INX
	BNE BackgroundLoop
	LDX #$00
BackgroundLoop2:
	LDA background + 256, x
	STA $2007
	INX
	BNE BackgroundLoop2
	LDX #$00
BackgroundLoop3:
	LDA background + 512, x
	STA $2007
	INX
	BNE BackgroundLoop3
	LDX #$00
BackgroundLoop4:
	LDA background + 768, x
	STA $2007
	INX
	BNE BackgroundLoop4


AttributesLoad:
	LDA $2002
	LDA $23
	STA $2006
	LDA #$C0
	STA $2006
	LDX #$00
AttributesLoadLoop:
  lda attributes, x   
  sta $2007         
  inx
  cpx #$08
  bne AttributesLoadLoop

enable_rendering: ; DO NOT MODIFY THIS
  lda #%10000000	; Enable NMI
  sta $2000
  lda #%00010000	; Enable Sprites
  sta $2001

forever: ;FOREVER LOOP WAITING FOR THEN NMI INTERRUPT, WHICH OCCURS WHENEVER THE LAST PIXEL IN THE BOTTOM RIGHT CORNER IS PROJECTED
  jmp forever

nmi:  ;WHENEVER AN NMI INTERRUPT OCCURS, THE PROGRAM JUMPS HERE (60fps)
  lda #$00  	
  sta $2003 
  lda #$02  	
  sta $4014 
  lda #$00  	
  sta $2005 
  sta $2005

  LDA #%10010000 
  STA $2000 
  LDA #%00011110
  STA $2001

  RTI 

palettes:
    .byte $0f, 03, 10, 16
    .byte $0f, 20, 23, 17
    .byte $0f, 30, 12, 18
    .byte $0f, 34, 67, 19

    .byte $0f, 02, 12, 13
    .byte $0f, 21, 22, 23
    .byte $0f, 31, 32, 38
    .byte $0f, 44, 47, 49



background:
	.byte $00,$00,$00,$00,$16,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$1a,$1a,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$16,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$1a
	.byte $1a,$1a,$1a,$1a,$1a,$1a,$1a,$1a,$1a,$1a,$1a,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$16,$00,$00,$00,$12,$13,$14,$00,$00,$00,$00,$19,$1a
	.byte $00,$00,$1d,$0a,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$16,$16,$00,$00,$22,$23,$24,$25,$00,$00,$00,$29,$2a
	.byte $00,$00,$2d,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$16,$00,$31,$32,$33,$34,$35,$00,$00,$38,$39,$3a
	.byte $3b,$3c,$3d,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$16,$00,$41,$42,$43,$44,$45,$46,$46,$46,$46,$4a
	.byte $4b,$4c,$4d,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$16,$00,$51,$52,$53,$54,$55,$56,$57,$46,$46,$5a
	.byte $00,$5c,$5d,$5e,$00,$36,$36,$36,$36,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$16,$00,$00,$62,$63,$64,$65,$66,$67,$68,$69,$6a
	.byte $6b,$6c,$6d,$6e,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f,$6f
	.byte $00,$00,$00,$00,$00,$00,$00,$72,$73,$74,$75,$76,$77,$ab,$ab,$ab
	.byte $ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab
	.byte $00,$00,$00,$00,$00,$70,$81,$82,$83,$84,$85,$86,$ab,$ab,$ab,$ab
	.byte $ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab
	.byte $00,$00,$00,$00,$00,$90,$91,$92,$93,$94,$95,$96,$ab,$ab,$ab,$ab
	.byte $ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab
	.byte $00,$00,$00,$16,$00,$a0,$a1,$a2,$a3,$a4,$a5,$a6,$a7,$ab,$d9,$d9
	.byte $d9,$d9,$d9,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab,$ab
	.byte $d9,$d9,$d9,$d9,$d9,$b0,$b1,$b2,$b3,$b4,$b5,$b6,$b7,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$ab,$ab,$d9,$d9,$ab,$ab,$ab,$ab,$ab,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$c0,$d1,$c2,$c3,$c4,$d9,$d9,$d9,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$ab,$ab,$d9,$d9,$d9,$d9,$d9,$ab,$ab,$d9,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$d0,$d1,$d2,$d3,$d4,$d9,$d9,$d9,$d9,$d9,$d9
	.byte $d9,$d9,$ab,$ab,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$e2,$e3,$e4,$d9,$d9,$d9,$d9,$d9,$d9
	.byte $ab,$ab,$ab,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$f2,$f3,$f4,$d9,$d9,$d9,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$cd,$cd,$d9,$d9,$d9,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$cd,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$cd,$cd,$cd,$cd,$cd,$cd,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$cd,$cd,$cd,$cd,$cd,$cd,$cd,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$d9,$cd,$cd,$cd,$cd,$cd,$cd,$cd,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$d9,$cd,$cd,$cd,$cd,$cd,$cd,$cd,$cd,$cd,$cd
	.byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$cd,$cd,$cd,$cd,$cd,$cd,$cd,$cd,$cd,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$cd,$cd,$cd,$cd,$cd,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$cd,$cd,$cd,$cd,$d9,$d9,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$cd,$cd,$cd,$d9,$d9,$d9,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9
	.byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00





attributes:
    .byte $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .byte $55, $55, $55, $55, $55, $55, $55, $55 
    .byte $55, $55, $55, $55, $55, $55, $55, $55 
    .byte $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .byte $55, $55, $55, $55, $55, $55, $55, $55 
    .byte $55, $55, $55, $55, $55, $55, $55, $55 
    .byte $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .byte $55, $55, $55, $55, $55, $55, $55, $55 
.segment "CHARS"
  .incbin "background.chr"