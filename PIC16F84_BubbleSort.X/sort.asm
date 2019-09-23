#include "p16f84.inc" 
    
array_start SET	    0x30        ; the starting address of the array, a constant
array_size  SET	    0x14        ; the number of elements in array, a constant 
cur_limit   EQU	    0x2E        ; current array limit to search until
cur_element EQU     0x2F        ; current element
swap_1      EQU     0x20        ; address of swapped value
swap_2      EQU     0x21        ; address of swapped value
temp        EQU     0x22

RES_VECT    CODE    0x0000      ; processor reset vector
GOTO START

SWAP
    MOVF swap_1, 0              ; WREG = first swapped address
    MOVWF FSR
    MOVF INDF, 0                ; WREG = first swapped value
    MOVWF temp                  ; temp = first swapped value
    
    MOVF swap_2, 0              ; WREG = second swapped address
    MOVWF FSR
    MOVF INDF, 0                ; WREG = second swapped value
    
    XORWF temp, 0
    XORWF temp, 1
    XORWF temp, 0
    
    MOVWF INDF                  ; swap_2 = first swapped value
    
    MOVF swap_1, 0              ; WREG = first swapped address
    MOVWF FSR
    MOVF temp, 0                ; WREG = second swapped value
    MOVWF INDF                  ; swap_1 = second swapped value
    
    CLRF temp
    RETURN
    
SORT_ASCENDING
    MOVLW 1                     ; WREG = 1
    SUBLW array_size            ; WREG = array_size - 1
                                ; we don't need to compare last element with next (not array element)
    MOVWF cur_limit             ; cur_limit = WREG
    
    OUTER_ASCENDING_LOOP:
        CLRF cur_element        ; cur_element = 0
        INNER_ASCENDING_LOOP:
            INCF cur_element, 0 ; WREG = cur_element + 1
            ADDLW array_start   ; WREG += array_start
            MOVWF FSR           ; FSR = WREG, INDF = array[cur_element + 1]
            MOVF INDF, 0        ; WREG = INDF
            MOVWF temp          ; temp = WREG
            
            MOVF cur_element, 0 ; WREG = cur_element
            ADDLW array_start   ; WREG += array_start
            MOVWF FSR           ; FSR = WREG
            MOVF INDF, 0        ; WREG = INDF = array[cur_element]
            
            SUBWF temp, 0;      ; WREG = array[cur_element + 1] - array[cur_element] 
            BTFSC STATUS, 0     ; if (cur_element - WREG < 0) then swap
            GOTO INC_CUR_ELEMENT
            
            MOVF FSR, 0         ; WREG = array[cur_element]
            MOVWF swap_1

            INCF cur_element, 0 ; WREG = cur_element + 1
            ADDLW array_start   ; WREG += array_start
            MOVWF swap_2
            
            CALL SWAP
            
            INC_CUR_ELEMENT
                INCF cur_element, 1         ; ++cur_element
                MOVF cur_limit, 0           ; WREG = cur_limit
                SUBWF cur_element, 0        ; WREG = cur_element - cur_limit
                BTFSS STATUS, 0             ; if (cur_element - cur_limit >= 0) skip next command
                GOTO INNER_ASCENDING_LOOP
            
        DECF cur_limit, 1                   ; --cur_limit
        MOVF cur_limit, 0                   ; WREG = cur_limit
        SUBLW 0                             ; WREG = 0 - cur_limit
        BTFSS STATUS, 0                     ; if (cur_limit > 0) continue
        GOTO OUTER_ASCENDING_LOOP
    
    CLRF swap_1
    CLRF swap_2
    CLRF temp
    CLRF cur_element
    CLRF cur_limit
    RETURN
    
SORT_DESCENDING
    CLRF cur_limit              ; cur_limit = 0
    
    OUTER_DESCENDING_LOOP:
        MOVLW 1                 ; WREG = 1
        SUBLW array_size        ; WREG = array_size - 1
        MOVWF cur_element       ; cur_element = WREG
        INNER_DESCENDING_LOOP:
            DECF cur_element, 0 ; WREG = cur_element - 1
            ADDLW array_start   ; WREG += array_start
            MOVWF FSR           ; FSR = WREG, INDF = array[cur_element - 1]
            MOVF INDF, 0        ; WREG = INDF
            MOVWF temp          ; temp = WREG
            
            MOVF cur_element, 0 ; WREG = cur_element
            ADDLW array_start   ; WREG += array_start
            MOVWF FSR           ; FSR = WREG
            MOVF INDF, 0        ; WREG = INDF = array[cur_element]
            
            SUBWF temp, 0;      ; WREG = array[cur_element - 1] - array[cur_element] 
            BTFSC STATUS, 0     ; if (array[cur_element - 1] - array[cur_element] < 0) then swap
            GOTO DEC_CUR_ELEMENT
            
            MOVF FSR, 0         ; WREG = array[cur_element]
            MOVWF swap_1

            DECF cur_element, 0 ; WREG = cur_element - 1
            ADDLW array_start   ; WREG += array_start
            MOVWF swap_2
            
            CALL SWAP
            
            DEC_CUR_ELEMENT
                DECF cur_element, 1     ; --cur_element
                MOVF cur_element, 0     ; WREG = cur_element
                SUBWF cur_limit, 0      ; WREG = cur_limit - cur_element
                BTFSS STATUS, 0         ; if (cur_limit >= cur_element) skip next command
                GOTO INNER_DESCENDING_LOOP
            
        INCF cur_limit, 1               ; ++cur_limit
        MOVF cur_limit, 0               ; WREG = cur_limit
        ADDLW 2                         ; WREG = cur_limit + 2
        SUBLW array_size                ; WREG = array_size - cur_limit - 2
        BTFSC STATUS, 0                 ; if (array_size >= cur_limit + 2) continue
        GOTO OUTER_DESCENDING_LOOP
    
    CLRF swap_1
    CLRF swap_2
    CLRF temp
    CLRF cur_element
    CLRF cur_limit
    RETURN
    
START:
CONFIGURE_PORTS:
    CLRF PORTA
    CLRF PORTB
    BSF STATUS, RP0
    BSF TRISA, 0
    BCF TRISB, 0
    BCF STATUS, RP0
BEGIN:
    BTFSS PORTA, 0
    GOTO ASC
    GOTO DESC
ASC:
    CALL SORT_ASCENDING
    GOTO FINISH
DESC:
    CALL SORT_DESCENDING
    GOTO FINISH
FINISH:
    BSF PORTB, 0
END
