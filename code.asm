#make_bin#

#load_segment=FFFFH#
#load_offset=0000H#

#cs=0000H#
#ip=0000H#
#ds=0000H#
#es=0000H#
#ss=0000H#
#sp=FFFEH#
#ax=0000H#
#bx=0000H#
#cx=0000H#
#dx=0000H#
#si=0000H#
#di=0000H#
#bp=0000H#

; starting of the program

jmp st:
db 2042 dup(0)
st:  cli

one_k db 0
vfac db 0
sine_w db 0
triangular_w db 0
stepsize db 0
square_w db 0
one_hundred db 0
ten db 0
count dw 0
list db 13 dup(0)

; Giving names for the internal addresses of 8255

portA equ 00H
portB equ 02H
portC equ 04H
cregPPI equ 06H

; Giving names for the internal addresses of 8253

timer0 equ 08H
timer1 equ 0AH
timer2 equ 0CH
cregPIT equ 0EH

; Giving names to the different button hexcodes on keypad

SINbutton equ 66H
TRIbutton equ 56H
SQUbutton equ 36H
vbutton equ 65H
OKbutton equ 55H
HUNbutton equ 35H
TENbutton equ 33H
GENbutton equ 63H

; Initializing the segments to start of ram

mov     ax, 0200H
mov     ds, ax
mov     es, ax
mov     ss, ax
mov     sp, 0FFFEH
mov     ax, 00H
mov     vfac, al
mov     one_k, al
mov     vfac, al
mov     one_hundred, al
mov     ten, al
mov     sine_w, al
mov     triangular_w, al
mov     square_w, al

; Table to generate sine wave

lea     di,  list
mov     [di],128
mov     [di+1],144
mov     [di+2],160
mov     [di+3],176
mov     [di+4],191
mov     [di+5],205
mov     [di+6],218
mov     [di+7],228
mov     [di+8],238
mov     [di+9],245
mov     [di+10],251
mov     [di+11],254
mov     [di+12],255
mov        [di+13],254
mov        [di+14],251
mov        [di+15],245
mov        [di+16],238
mov        [di+17],228
mov        [di+18],218
mov        [di+19],205
mov        [di+20],191
mov        [di+21],176
mov        [di+22],160
mov        [di+23],144
mov        [di+24],128
mov        [di+25],127
mov        [di+26],111
mov        [di+27],95
mov        [di+28],79
mov        [di+29],64
mov        [di+30],50
mov        [di+31],37
mov        [di+32],27
mov        [di+33],17
mov        [di+34],10
mov        [di+35],4
mov        [di+36],1
mov        [di+37],0
mov        [di+38],1
mov        [di+39],4
mov        [di+40],10
mov        [di+41],17
mov        [di+42],27
mov        [di+43],37
mov        [di+44],50
mov        [di+45],64
mov        [di+46],79
mov        [di+47],95
mov        [di+48],111
mov        [di+49],127

; Initializing 8255 (setting it to i/o mode)

mov     al, 10001010b
out     cregPPI, al

; Keypad interfacing

key1:
mov        al, 00H
out     portC, al

; Checking for key release

key2:
in      al, portC
and     al, 70H
cmp     al, 70H
jne     key2

mov      al, 00H
out         portC, al

; Checking for key press

key3:
in        al, portC
and     al, 70H
cmp     al, 70H
je      key3

; Once key press is detected, then find which row is the pressed key in

mov     al, 06H
mov     bl, al
out     portC, al
in      al, portC
and     al, 70H
cmp     al, 70H
jne     key4

mov     al, 05H
mov     bl, al
out     portC, al
in      al, portC
and     al, 70H
cmp     al, 70H
jne     key4

mov     al, 03H
mov     bl, al
out     portC, al
in      al, portC
and     al, 70H
cmp     al, 70H
je      key3

; Code reaches here once a key has been pressed and its hex code is stored in the al and bl registers
; Now we check which button that hexcode corresponds to:

key4:or     al, bl
cmp     al, SINbutton
; If SIN button is pressed, then:
jnz     trib
inc     sine_w                        ;inc makes sine_w 1 which means it is selected
jmp     key1

trib:cmp     al, TRIbutton
; Else if TRI button is pressed, then:
jnz      squb
inc  triangular_w
jmp     key1

squb:cmp     al, SQUbutton
; Else if SQU button is pressed, then:
jnz     vfb
inc     square_w
jmp     key1

vfb:    cmp al, vbutton
;else if vbutton is pressed
jnz okb
inc vfac
jmp key1


okb:cmp     al, OKbutton
; Else, if 1K button is pressed, then:
jnz      hunb
inc     one_k
jmp     key1

hunb:cmp     al, HUNbutton
; Else, if 100 button is pressed, then:
jnz      tenb
inc     one_hundred
jmp     key1

tenb:cmp     al, TENbutton
; Else, if 10 button is pressed, then:
jnz      genb
inc     ten
jmp     key1

genb:cmp     al, GENbutton
; Else, if GEN button was pressed:
jz      end_k
jmp key1

end_k:

; Code reaches this point if GEN button is pressed.
; In that case, compute the count required to load in 8253 (PIT)

call computeCount

; BX register now stores the frequency in decaHertz

mov     dx, 00H
mov     ax, 10000
div     bx ; dividing 10000 by bx. Quotient stored in ax

i:  mov count, ax

; Calculated count present in count
; Storing count

mov     al, 00H
out     portC, al

; Wait for GEN key release

call waitForGEN

; BX now stores the value of (actual count * sampling rate)
; Here we have used the sampling rate of ((13*2)-1)*2 = 50

; Selecting the wave form whose button has been pressed the maximum number of times:
; If all have been pressed the same number of times, then sine wave will be selected

mov     al, sine_w
cmp     al, triangular_w
jl      slt
cmp        al, square_w
jg        sine_gen
jmp     sq_gen
slt:mov     al, triangular_w
cmp     al, square_w
jg         tri_gen
jmp     sq_gen

; Code to generate sine wave

sine_gen:
mov dx, portA
;mov dx, 00H
mov ax,count
mov bl,50
div bl
mov ah,00
mov bl, al

; Initialize timer
call initTimer
lea     si, list
mov     cl, 50
x99:
mov al, [si]
mul vfac
mov bl,10
div bl
mov [si],al
inc si
loop x99			;loop to change values of sine table according to given input


l5:
lea     si, list
mov     cl, 50
l1:
mov     al, [si]
out     portA, al
call wait
J1: add     si, 01H
loop    l1
jmp     l5

; Code to generate triangular wave

tri_gen:
mov     dx, 00H
mov     ax, count
mov     bx, 30
div     bx
qr1:
mov     ah, 00
mov     bx, ax
; Initialize timer
call initTimer
mov al,25
mul vfac
mov vfac,al
mov ah,00h
mov bl,15
div bl
mov stepsize,al			;stepsize such that it takes 15 steps to reach max amplitude
mov bl,15
mul bl
mov vfac,al			;vfac now has max amplitude

mov     al, 00H
g1:
out     portA, al
mov     bl, al
call    wait
mov     al, bl
add     al, stepsize
cmp     al, vfac
jnz     g1
g2:
out     portA, al
mov     bl, al
call    wait
mov     al, bl
sub     al, stepsize
cmp     al, 00H
jnz     g2
jmp     g1

; Code to generate square wave:

sq_gen:
mov dx, portA
mov ax, count
mov bx, 02H
div bx
mov bx, ax
mov al,25
mul vfac
mov vfac,al
mov ax,bx

; Initialize timer
call initTimer
mov     al, 80H
out     portA, al
s:  mov     al, 00H
out     portA, al
in      al, portC
and     al, 70H
cmp     al, 70H
jne     key
call    wait
in      al, portC
and     al, 70H
cmp     al, 70H
jne     key


mov     al, vfac
out     portA, al
mov     al, vfac
out     portA, al
in      al, portC
and     al, 70H
cmp     al, 70H
jne     key
call    wait
in      al, portC
and     al, 70H
cmp     al, 70H
jne     key
mov     al, vfac
out     portA, al
jmp     s

; Checking if a key is pressed

key:
mov     al, 06H
mov     bl, al
out     portC, al
in      al, portC
and     al, 70H
cmp     al, 70H
jnz     k3

mov     al, 05H
mov     bl, al
out     portC, al
in      al, portC
and     al, 70H
cmp     al, 70H
jnz     k3

mov     al, 03H
mov     bl, al
out     portC, al
in      al, portC
and     al, 70H
cmp     al, 70H
je      key

; If a key is pressed, find out which one:

k3: or      al, bl
cmp     al, SINbutton
; If SIN button is pressed, then:
jz      sine_gen
cmp     al, TRIbutton
; Else, if TRI button is pressed, then:
jz      tri_gen
cmp     al, SQUbutton
; Else, if SQU button is pressed, then:
jz      sq_gen
; Else (i.e. if none of the waveform buttons were pressed), then:
jmp key

; Procedure to compute the value of count

computeCount proc
mov     bx, 00H
mov     al, 100
mul     one_k
add     bx, ax
mov     al, 0AH
mul     one_hundred
add     bx, ax
mov     al, ten
mov     ah, 00H
add     bx, ax
ret
endp

; Wait procedure

wait proc
v1: in      al, portB
cmp     al, 00H
jne     v1
v2: in      al, portB
cmp     al, 80H
jne     v2
ret
endp

; Procedure to initialize the 8253 (PIT)

initTimer proc
; Initializing the timer with control word
mov dx, 0019H

mov     al, 00110110b
out     cregPIT, al

; Loading LSB of count value
mov     al, bl
out     timer0, al
; Loading MSB of count value
mov     al, bh
out     timer0, al

ret
endp

; Procedure to wait for GEN key release

waitForGEN proc
k1: in      al, portC
and     al, 70H
cmp     al, 70H
jnz     k1
ret
endp