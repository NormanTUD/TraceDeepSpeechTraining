function slurmlogpath { scontrol show job $1 | grep StdOut | sed -e 's/^\s*StdOut=//' }

function countdown() {
    secs=$1
    shift
    msg=$@
    while [ $secs -gt 0 ]
    do
        printf "\r\033[KWaiting %.d seconds $msg" $((secs--))
        sleep 1
    done
    echo
}

function echoheader1 {
        echo -e "\e[100m\e[4m$1\e[0m"
}

function echoheader2 {
        echo -e "\e[4m$1\e[0m"
}

function echoheader2current {
    echo -e "\e[5m\e[4m$1\e[0m (currently running)"
}

function myavg () {
    OUTPUT="count,ave,median,first,last\n"
    OUTPUT2=$(awk '
      BEGIN {
        c = 0;
        sum = 0;
      }
      $1 ~ /^(\-)?[0-9]*(\.[0-9]*)?$/ {
        a[c++] = $1;
        sum += $1;
      }
      END {
        ave = sum / c;
        if( (c % 2) == 1 ) {
          median = a[ int(c/2) ];
        } else {
          median = ( a[c/2] + a[c/2-1] ) / 2;
        }
        OFS=",";
        print c, ave, median, a[0], a[c-1];
      }
      ')
      echo "$OUTPUT$OUTPUT2" | sed -e 's/^/| /' -e 's/,/,| /g' -e 's/$/,|/' | column -t -s,
}

function dumbgnuplot {
    IMGUUID=$(uuidgen)
    terminal=/dev/pts/1
    finalrows=$(($LINES/2.7))
    gnuplot -p -e "set terminal dumb $COLUMNS $finalrows; set autoscale; set style line 1; plot '$1' using 1:2 pt '*'"
}

function validationavg {
    UUID=$(uuidgen)
    cat $1 | grep Validation | grep Loss: | sed -e 's/.*Loss: //' | sed -e "s/ . Dataset:.*//" | grep -v "0.000000" | perl -e 'my $i = 1; print "x\ty\n"; while (<>) { chomp $_; print "$i\t$_\n"; $i++; } ' > ${UUID}
    cat ${UUID} | cut -f2- | myavg
    dumbgnuplot ${UUID}
    rm ${UUID}
}

function traininglossavg {
    UUID=$(uuidgen)
    cat $1 | grep Training | grep Loss: | sed -e 's/.*Loss: //' | sed -e "s/ . Dataset:.*//" | grep -v "0.000000" | perl -e 'my $i = 1; print "x\ty\n"; while (<>) { chomp $_; print "$i\t$_\n"; $i++; } ' > ${UUID}
    cat ${UUID} | cut -f2- | myavg
    dumbgnuplot ${UUID}
    rm ${UUID}
}

function showlosses {
    JOBID=$1
    OUTFILE=$JOBID

    if [[ ! -f $OUTFILE ]]; then
        OUTFILE=$(ls *$JOBID*)
    fi

    if [[ ! -f $OUTFILE ]]; then
        OUTFILE=$(slurmlogpath $JOBID)
    fi

    echoheader1 "VALIDATION AND TRAINING LOSSES FOR JOB $1 ($OUTFILE)"

    cat $OUTFILE | grep "Epoch 1" > /dev/null && cat $OUTFILE | grep "Epoch 0" | grep "Validation" | wc -l | sed -e 's/^/Number of validation steps: /' && cat $OUTFILE | grep "Epoch 0" | grep "Training" | wc -l | sed -e 's/^/Number of training steps: /'
    cat $OUTFILE | grep "^Epoch " | tail -n1 | perl -e 'while (<>) { s/Epoch\s*(\d+)\s.*/Current Epoch: \1/; print $_ }'
    cat $OUTFILE | egrep "Training|Validation" | tail -n1 | perl -e 'while (<>) { s/Epoch\s+\d+\s*\|\s*(\w*)\s+.*/Current phase: $1/; print $_ }'

    echoheader2 "Validation:"
    validationavg $OUTFILE

    echoheader2 "Trainingloss:"
    traininglossavg $OUTFILE
}

function tracedeepspeech {
    JOBID=$1
    OUTFILE=$JOBID

    if [[ ! -f $OUTFILE ]]; then
        OUTFILE=$(ls *$JOBID*)
    fi

    if [[ ! -f $OUTFILE ]]; then
        OUTFILE=$(slurmlogpath $JOBID)
    fi
    while [ 1 ]; do showlosses $OUTFILE; countdown 10; clear; done
}
