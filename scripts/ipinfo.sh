#!/usr/bin/env bash

INFO=$(ip addr show $(ip route show default | awk '{ for(i = 1; i <= NF; i++) { if($i == "dev") { print $(i+1) } } }') | grep inet -w | awk '{ print $2 }')

IP=$(cut -d'/' -f1 <<< "$INFO")
echo $IP

MASK_LENGTH=$(cut -d'/' -f2 <<< "$INFO")
echo $MASK_LENGTH

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
        echo great
    else
        echo "add zero"
    fi

    echo $DECIMAL
}

getmask