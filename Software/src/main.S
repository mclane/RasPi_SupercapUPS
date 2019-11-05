; Watchdog Ferienhaus
; Überwachung Betriebsspannung
; Überwacht die RasPi 5V Eingangsspannung (interne 2.56V Referenz) an PB4
; Reset (PB3) wird auf GND gesetzt wenn die Spannung unter 4.6V fällt
; Reset wird auf GND gehalten bis die Spannung 4.8V erreicht
; Erwartet einen Impuls auf PB2 alle 60s. Falls dieser nicht erfolgt wird PB3 für 1s auf GND gesetzt (Reset)

#define __SFR_OFFSET 0
#include <avr/io.h>

#define temp 		r16
#define tick	 	r17
#define wdtime		r18
#define adcval		r19

#define ledpin		3
#define ubatt		4
#define wdin 		2
#define THR			209
#define WDTHR		31			
; 30 x 4 s ist der watchdog timeout

; reset vector
.global main
; vector for Timer1 overflow ISR
.type TIMER1_OVF_vect, @function
.global TIMER1_OVF_vect
; vector for ADC ISR
.type ADC_vect, @function
.global ADC_vect
; vector for pin change ISR
.type PCINT0_vect, @function
.global PCINT0_vect

main:
;init_timer1:
	ldi temp,  0b00001111
	out TCCR1, temp      		; set the Clock Selector Bits CS10-13 to 1111
                         		; this puts Timer Counter1, TCNT1 in to FCPU/16384 mode
                         		; so it ticks at the CPU freq/16384
   	ldi temp, 0b00000110
   	out TIMSK, temp      		; set the Timer Overflow Interrupt Enable (TOIE1) bit 
                         		; of the Timer Interrupt Mask Register (TIMSK)
   	clr temp
   	out TCNT1, temp       		; initialize the Timer/Counter to 0

;init_led_output
	ldi temp, 0b00001000
	out DDRB, temp				; set PB3 as output, all others are input
	cbi PORTB, ledpin

;init_wd_input
	ldi temp, 0b00000100	
	out PORTB, temp				; set pullup for wdtrig input
	ldi temp, 0b00100000		; set pin change interrupt enable bit
	out GIMSK, temp				; write to General Interrupt Mask Register
	ldi temp, 0b00000100		; set wdin (PB2) as pin change source
	out PCMSK, temp				; write to Pin Change Mask Register

	
;init_adc:
	ldi temp, 0b10110010		; 2.56V internal reference, left shift eabled, PB4 is ADC input
	out ADMUX, temp
	ldi temp, 0b00000000
	out ADCSRB, temp			; free running mode
	ldi temp, 0b11101011
	out ADCSRA, temp			; ADC enable, start conversion, auto trigger, interrupt enable, prescaler /8 -> 125 kHz
	ldi adcval, 0b00000000

	sei                   		; enable global interrupts -- equivalent to "sbi SREG, I"
	ldi wdtime, 0x00			; set watchdog timer to 0

looop:
	cpi adcval, THR				; check adc
	brlt setlow					; if low then set reset to low (active)
	sbi PORTB, ledpin			; else set reset inactive
	inc wdtime					; inc watchdog counter
	cpi wdtime, WDTHR			; check if watchdog expired
	breq setlow					; if expired then set reset to low
	rjmp cnt 					; jump to continue
	setlow:
	cbi PORTB, ledpin			; set reset pin to low(active)
	ldi wdtime, 0x00			; reset wadchdog
	cnt:
	ldi tick, 0x00				; reset tick
	delay:
	cpi tick, 0x00				; wait for next tick to happen
	breq delay					; 
	rjmp looop					; if next tick, start from beginning

TIMER1_OVF_vect:
	ldi tick, 0x01         		; set timetick
	reti                  		; return from interrupt

ADC_vect:
	in temp, ADCL
	in adcval, ADCH				; ADC value is in high register due to left shift enable
	reti

PCINT0_vect:
	ldi wdtime, 0x00			; reset watchdog time if input is triggered
	reti

