#!/usr/bin/env bash

INFO=$(ip addr show $(ip route show default | awk '{ for(i = 1; i <= NF; i++) { if($i == "dev") { print $(i+1) } } }') | grep inet -w | awk '{ print $2 }')

IP=$(cut -d'/' -f1 <<< "$INFO")
echo $IP

MASK_LENGTH=$(cut -d'/' -f2 <<< "$INFO")

#this is terrible, but it's mine :)))
function getmask() {
    CLEARED_BLOCKS=$(($MASK_LENGTH/8))
    REMAINDER=$(($MASK_LENGTH - 8 * $CLEARED_BLOCKS))

    declare DECIMAL
    for ((i = 0; i <= $CLEARED_BLOCKS; i++)); do
        BLOCK=$(cut -d'.' -f$(($i+1)) <<< "$IP")
        
        DECIMAL+=$BLOCK
        DECIMAL+="."
    done

    if (( $REMAINDER > 0 )); then
        #ok so i have the remaining bits ike 4 that means the highest 4 bits of that last number are reserved so ill convert decimal to binary and & it with 11110000
        LAST_BLOCK=$(cut -d'.' -f$(($CLEARED_BLOCKS+1)) <<< "$IP")
        LAST_BLOCK_BIN=$(echo "obase=2; $LAST_BLOCK" | bc)
        LAST_BLOCK_BIN=$(printf "%08d\n" $LAST_BLOCK_BIN)
        $((2#))
    else
        DECIMAL+="0"
    fi

}

getmask