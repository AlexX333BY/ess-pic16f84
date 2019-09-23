#include "p16f84a.inc" 
    
array_start SET	    0x30        ; the starting address of the array, a constant
array_size  SET	    0x14        ; the number of elements in array, a constant 
min_element EQU	    0x2E        ; address to file register that stores max value
cur_element EQU	    0x2F        ; address to number of current array element

RES_VECT    CODE    0x0000      ; processor reset vector

START:
    MOVF array_start, 0         ; WREG = array[0]
    MOVWF min_element           ; min_element = WREG
    CLRF cur_element            ; cur_element = 0
    INCF cur_element, 1         ; ++cur_element
    
ANALYZE:
    MOVF cur_element, 0         ; WREG = cur_element
    ADDLW array_start           ; WREG += array_start
    MOVWF FSR                   ; FSR = WREG, INDF = [WREG] = array[cur_element]
    MOVF INDF, 0                ; WREG = array[cur_element]
    SUBWF min_element, 0        ; WREG = min_element - WREG
    BTFSS STATUS, 0             ; skip next command if STATUS[0] is SET
                                ; (WREG - min_element > 0 => min_element < WREG)
    GOTO NEXT

SET_MIN_ELEMENT:
    MOVF cur_element, 0         ; WREG = cur_element
    ADDLW array_start           ; WREG += array_start
    MOVWF FSR                   ; FSR = WREG, INDF = [WREG] = array[cur_element]
    MOVF INDF, 0                ; WREG = array[cur_element]
    MOVWF min_element           ; min_element = WREG
	
NEXT:
    INCF cur_element, 0x1       ; ++cur_element
    MOVLW array_size            ; WREG = array_size
    SUBWF cur_element, 0        ; WREG -= cur_element
    BTFSS STATUS, 0             ; skip next command if STATUS[0] is unset
                                ; (cur_element - array_size < 0)
    GOTO ANALYZE                

    CLRF cur_element            ; cur_element = 0

end
