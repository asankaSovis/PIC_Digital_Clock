;-------- DIGITAL CLOCK -------------------------------------------
;
; Developed to communicate with a DS1302 RTC module and get
; the time and display it on 5✕7 dot-matrix LED displays using
; the MAX6952 display driver
;
; Program Name: digital_clock.S
; Author: Asanka Sovis 
; Date: 12/05/2024
; Platform: PIC16F877a
; HW: MAX6952, DS1302, 5✕7 dot-matrix LED * 12
;
; ------------------------------------------------------------------ 

;-------- PIC16F877A Configuration Bit Settings --------------------
; Assembly source line config statements 
; CONFIG 
 CONFIG FOSC = EXTRC ; Oscillator Selection bits (RC oscillator) 
 CONFIG WDTE = OFF ; Watchdog Timer Enable bit (WDT disabled) 
 CONFIG PWRTE = OFF ; Power-up Timer Enable bit (PWRT disabled) 
 CONFIG BOREN = OFF ; Brown-out Reset Enable bit (BOR disabled) 
 CONFIG LVP = OFF ; Low-Voltage (Single-Supply) In-Circuit Serial Programming Enable bit (RB3 is digital I/O, HV on MCLR must be used for programming) 
 CONFIG CPD = OFF ; Data EEPROM Memory Code Protection bit (Data EEPROM code protection off) 
 CONFIG WRT = OFF ; Flash Program Memory Write Enable bits (Write protection off; all program memory may be written to by EECON control) 
 CONFIG CP = OFF ; Flash Program Memory Code Protection bit (Code protection off) 
// config statements should precede project file includes. 
#include <xc.inc> 

;-------- Initialising --------------------------------------------
PSECT start, CLASS = CODE, DELTA=2
start:
    PAGESEL MAIN
    GOTO MAIN

;-------- Const. Definitions -------------------------------------
D0_ADDR             EQU 0x20    ; D0 address of MAX6952
D1_ADDR             EQU 0x21    ; D1 address of MAX6952
D2_ADDR             EQU 0x22    ; D2 address of MAX6952
D3_ADDR             EQU 0x23    ; D3 address of MAX6952
MAX_CONFIG          EQU 0x81    ; Default config of MAX6952
MAX_CONFIG_ADDR     EQU 0x04    ; Config addr. of MAX6952
I10_ADDR            EQU 0x01    ; Intensity value 0 - 10 bits
I32_ADDR            EQU 0x02    ; Intensity value 10 - 32 bits
CLK_DELAY           EQU 0x0F    ; Bit transmission delay

;-------- Pin Definitions ----------------------------------------
MAX_CS_PIN          EQU 1    ; CS of MAX6952
DS_CS_PIN           EQU 2    ; CS of DS1302
CLK_PIN             EQU 3    ; Common CLK pin
DATA_PIN            EQU 0    ; Common DATA pin

;-------- Addr. Definitions --------------------------------------
STATE_REG           EQU 0x20    ; State machine pointer register
TX_DEC_REG          EQU 0x23    ; TX/RX Bit shift decrement reg.
CLK_DELAY_REG       EQU 0x24    ; Clk. delay decrement reg.
DATA_REG            EQU 0x25    ; Data reg. for TX/RX data
ADDR_REG            EQU 0x26    ; Address for data to be sent to MAX6952
D0_REG              EQU 0x27    ; Data for D0 of MAX6952 daisy chain
D1_REG              EQU 0x28    ; Data for D1 of MAX6952 daisy chain
D2_REG              EQU 0x29    ; Data for D2 of MAX6952 daisy chain
TEMP_D21_REG        EQU 0x30    ; Temp. reg for D2 data splitting 1
TEMP_D22_REG        EQU 0x31    ; Temp. reg for D2 data splitting 2
;----------------------------------------------------------------

;-------- Main code pointer -------------------------------------
MAIN:
    MOVLW       CLK_DELAY
    MOVWF       CLK_DELAY_REG       ; Loading clk delay to decrement reg.
    BANKSEL     TRISB               ; Selecting TrisB
    CLRF        TRISB               ; Setting PORTB as output
    BANKSEL     PORTB               ; Selecting PortB
    CLRF        PORTB               ; Turning off all GPIO in PortB
    
    ; MAX6952 defauls high as CS and DS1302 as low
    BSF         PORTB, MAX_CS_PIN   ; Setting the CS of MAX6952 high
    BCF         PORTB, DS_CS_PIN    ; Setting the CS of DS1302 low

    MOVLW       0x08                
    MOVWF       TX_DEC_REG          ; Loading 8 to reg for bit TX/RX
;----------------------------------------------------------------

;-------- Initialization of MAX6952 chip ------------------------
; MAX6952 requires configuration to be set and intensities set
; to operate correctly. Configuration defaults to 0x81, intensity
; as 0xFFFF.
max_chip_init:
    ; MAX Chip Configuration
    MOVLW       MAX_CONFIG_ADDR
    MOVWF       ADDR_REG        ; Load address of config.
    MOVLW       MAX_CONFIG
    MOVWF       D0_REG          ; Load max config to D0, D1,
    MOVWF       D1_REG          ; D2 data reg.
    MOVWF       D2_REG
    call propagate_data

    ; MAX Chip Intensity10
    MOVLW       I10_ADDR
    MOVWF       ADDR_REG        ; Load address of I10.
    MOVLW       0xFF
    MOVWF       D0_REG          ; Load max config to D0, D1,
    MOVWF       D1_REG          ; D2 data reg.
    MOVWF       D2_REG
    call propagate_data

    ; MAX Chip Intensity32
    MOVLW       I32_ADDR
    MOVWF       ADDR_REG        ; Load address of I10.
    MOVLW       0xFF
    MOVWF       D0_REG          ; Load max config to D0, D1,
    MOVWF       D1_REG          ; D2 data reg.
    MOVWF       D2_REG
    call propagate_data

    ; Shifting blank char to clear displays
    ; Digit 0 data for 3 chips
    MOVLW       D0_ADDR
    MOVWF       ADDR_REG
    MOVLW       0xFF
    MOVWF       D0_REG
    MOVWF       D1_REG
    MOVWF       D2_REG
    call propagate_data

    ; Digit 1 data for 3 chips
    MOVLW       D1_ADDR
    MOVWF       ADDR_REG
    MOVLW       0xFF
    MOVWF       D0_REG
    MOVWF       D1_REG
    MOVWF       D2_REG
    call propagate_data

    ; Digit 2 data for 3 chips
    MOVLW       D2_ADDR
    MOVWF       ADDR_REG
    MOVLW       0xFF
    MOVWF       D0_REG
    MOVWF       D1_REG
    MOVWF       D2_REG
    call propagate_data

    ; Digit 3 data for 3 chips
    MOVLW       D3_ADDR
    MOVWF       ADDR_REG
    MOVLW       0xFF
    MOVWF       D0_REG
    MOVWF       D1_REG
    MOVWF       D2_REG
    call propagate_data
;----------------------------------------------------------------

;-------- Main program loop -------------------------------------
Loop:
    ; 0000 1000 - Date
    MOVLW       0x08
    MOVWF       STATE_REG
    call read_ds_byte

    MOVF        D0_REG, 0
    MOVWF       TEMP_D21_REG
    MOVF        D1_REG, 0
    MOVWF       TEMP_D22_REG    ; Load date to temp reg.

    ; 0000 0001 - Seconds
    MOVLW       0x01
    MOVWF       STATE_REG
    call        read_ds_byte

    MOVLW       D0_ADDR
    MOVWF       ADDR_REG
    MOVLW       0xFF
    MOVF        TEMP_D21_REG, 0
    MOVWF       D2_REG
    call propagate_data         ; Immediately load sec +
                                ; 1st digit of date

    ; 0000 0010 - Mins
    MOVLW       0x02
    MOVWF       STATE_REG
    call read_ds_byte

    MOVLW       D1_ADDR
    MOVWF       ADDR_REG
    MOVLW       0xFF
    MOVF        TEMP_D22_REG, 0
    MOVWF       D2_REG
    call propagate_data         ; Immediately load min +
                                ; 2nd digit of date

    ; 0001 0000 - Month
    MOVLW       0x10
    MOVWF       STATE_REG
    call read_ds_byte

    MOVF        D0_REG, 0
    MOVWF       TEMP_D21_REG
    MOVF        D1_REG, 0
    MOVWF       TEMP_D22_REG    ; Load month to temp reg.

    ; 0000 0100 - Hour
    MOVLW       0x04
    MOVWF       STATE_REG
    call read_ds_byte

    MOVLW       D2_ADDR
    MOVWF       ADDR_REG
    MOVLW       0xFF
    MOVF        TEMP_D21_REG, 0
    MOVWF       D2_REG
    call propagate_data         ; Immediately load hour +
                                ; 1st digit of month

    ; 0010 0000 - Year (24)
    MOVLW       0x20
    MOVWF       STATE_REG
    call read_ds_byte

    MOVLW       D3_ADDR
    MOVWF       ADDR_REG
    MOVLW       0xFF
    MOVF        TEMP_D22_REG, 0
    MOVWF       D2_REG
    call propagate_data         ; Immediately load year +
                                ; 2nd digit of month

    call bit_delay
    goto Loop
;----------------------------------------------------------------

;-------- Data propagation through MAX6972 daisy chain ----------
; Daisy chained MAX6972 requires all data to be shifted for each
; chip one after the other D0 -> D1 -> D2. Each require an 8bit
; address and 8bit reg. A7 - A0 D7 - D0
propagate_data:
    BCF         PORTB, MAX_CS_PIN   ; CS of MAX6972 set low to
                                    ; prepare for transmission.

    ; Shift add. reg for D2
    MOVF        ADDR_REG, 0
    MOVWF       DATA_REG
    call send_byte

    ; Shift data for D2
    MOVF        D0_REG, 0
    MOVWF       DATA_REG
    call send_byte

    ; Shift add. reg for D1
    MOVF        ADDR_REG, 0
    MOVWF       DATA_REG
    call send_byte

    ; Shift data for D1
    MOVF        D1_REG, 0
    MOVWF       DATA_REG
    call send_byte

    ; Shift add. reg for D0
    MOVF        ADDR_REG, 0
    MOVWF       DATA_REG
    call send_byte

    ; Shift data reg for D0
    MOVF        D2_REG, 0
    MOVWF       DATA_REG
    call send_byte

    ; Pull CLK low and CS high to end TX
    BCF         PORTB, CLK_PIN
    BSF         PORTB, MAX_CS_PIN
    call bit_delay

    return
;----------------------------------------------------------------

;-------- TX a byte ---------------------------------------------
; TX work by rotating bits and setting/resetting GPIO. PIC16F877a
; doesn't have native SPI/I2C support so bit banging is required.
send_byte:
    BCF         PORTB, CLK_PIN      ; Start with pulling CLK low

    BTFSS       DATA_REG, 7
    BCF         PORTB, DATA_PIN     ; Clear GPIO if bit is LOW
    BTFSC       DATA_REG, 7
    BSF         PORTB, DATA_PIN     ; Set GPIO if bit is HIGH
    call bit_delay

    RLF         DATA_REG, 1         ; Rotate bit left and pull
    BSF         PORTB, CLK_PIN      ; CLK high
    call bit_delay

    DECFSZ      TX_DEC_REG, 1       ; Dec the TX/RX reg. and skip
                                    ; the next op if zero
    goto send_byte

    MOVLW       0x08
    MOVWF       TX_DEC_REG
    BCF         PORTB, DATA_PIN     ; Reset TX/RX reg. and clear
                                    ; GPIO
    return
;----------------------------------------------------------------

;-------- Read a byte from DS1302 -------------------------------
; Reads a byte from DS1302. For this first an address is sent of
; the form [RW A0 A1 A2 A3 A4 RC 1] in our case
; [1 A0 A1 A2 A3 A4 1 1]
; Reply follws with the form [ D7 ---- D0]
; First 4 bits for digit 1 and rest for 0
; NOTE: DS1302 require addr. to be sent D0 to D7
; This program is defaulted to D7 to D0 as per the
; MAX6972. For DS1302, bits are flipped for actual
; TX. [1000 0011 -> 1100 0001]
read_ds_byte:
    BSF         PORTB, DS_CS_PIN    ; Pull CS high

    ; 0x81 - Seconds
    BTFSC       STATE_REG, 0
    MOVLW       0x81

    ; 0x83 - Minutes
    BTFSC       STATE_REG, 1
    MOVLW       0xC1

    ; 0x85 - Hours
    BTFSC       STATE_REG, 2
    MOVLW       0xA1

    ; 0x87 - Date
    BTFSC       STATE_REG, 3
    MOVLW       0xE1

    ; 0x89 - Month
    BTFSC       STATE_REG, 4
    MOVLW       0x91

    ; 0x8D - Year (last 2 digits)
    BTFSC       STATE_REG, 5
    MOVLW       0xB1

    ; Set addr. to data reg. and set GPIO
    ; as output
    MOVWF       DATA_REG
    BSF         TRISB, DATA_PIN
    call send_byte

    ; Clear data pin and set GPIO as input
    BCF         PORTB, DATA_PIN
    BCF         TRISB, DATA_PIN
    call receive_byte

    ; Set GPIO as output and CS low
    BSF         TRISB, DATA_PIN
    BCF         PORTB, DS_CS_PIN
    call bit_delay

    ; Finalize received data
    call byte_receive_done

    return
;----------------------------------------------------------------

;-------- Finalize received data --------------------------------
; Extract and convert digits to be compatible with MAX6972
;           10*X2          X1
; Sec. - [ X  B2 B1 B0] [ B3 B2 B1 B0]
; Min. - [ 0  B2 B1 B0] [ B3 B2 B1 B0]
; Hr. -  [ X  0  B1 B0] [ B3 B2 B1 B0]
; Dat. - [ 0  0  B1 B0] [ B3 B2 B1 B0]
; Mon. - [ 0  B2 0  B0] [ B3 B2 B1 B0]
; Yr. -  [ B3 B2 B1 B0] [ B3 B2 B1 B0]
; MAX6972 charset offsets digits by 0x30
byte_receive_done:
    ; Legacy
    ;BCF         PORTB, 6       ; Set data pin high (1) for bit 1
    ;BCF         PORTB, 4       ; Set data pin high (1) for bit 1

    ; Extract 1st 4 bits from reply and add 0x30 to convert to
    ; MAX6972 character
    MOVF        DATA_REG, 0
    ANDLW       0x0F
    ADDLW       0x30
    MOVWF       D0_REG

    ; Extract 2nd 3 bits skipping the last bits from reply and
    ; add 0x30 to convert to MAX6972 character
    SWAPF       DATA_REG, 0
    ANDLW       0x07
    ADDLW       0x30
    MOVWF       D1_REG
    
    return
;----------------------------------------------------------------

;-------- RX a byte ---------------------------------------------
; RX work by rotating bits and reading state of GPIO. PIC16F877a
; doesn't have native SPI/I2C support so bit banging is required.
receive_byte:
    BTFSS       PORTB, DATA_PIN
    BCF         DATA_REG, 7         ; Set bit if GPIO set
    BTFSC       PORTB, DATA_PIN
    BSF         DATA_REG, 7         ; Clear bit if GPIO clear

    BCF         PORTB, CLK_PIN
    RRF         DATA_REG, 1         ; Set CLK low and rotate right
    call bit_delay

    BSF         PORTB, CLK_PIN      ; Set CLK high after delay
    call bit_delay

    DECFSZ      TX_DEC_REG, 1       ; Dec the TX/RX reg. and skip
                                    ; the next op if zero
    goto   receive_byte

    MOVLW       0x08
    MOVWF       TX_DEC_REG          ; Reset TX/RX reg. and clear
                                    ; GPIO

    return
;----------------------------------------------------------------

;-------- Delay -------------------------------------------------
; Used to emulate a delay for TX/RX CLK signals
bit_delay:
    decfsz      CLK_DELAY
    goto        bit_delay           ; Loop until 0x0F ops pass

    MOVLW       CLK_DELAY
    MOVWF       CLK_DELAY_REG       ; Reset

    return

;----------------------------------------------------------------
END start