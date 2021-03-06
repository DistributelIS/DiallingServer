#!/bin/bash

# This version uses local tmp softlink

# ------------------------------------------------------------
# processDIDfile function
# takes two arguments, filename, sipphonescount, sipinfilebase
# returns count of DIDs processed
# ------------------------------------------------------------
function processDIDfile {
  didFile=$1
  xlites=$2
  sipinfilebase=$3

  # grab settings
  # use C for tcp INVITES, c for udp INVITES
  if [ "x$(grep -cE "^TCP=true" ${didFile}.settings)" == "x1" ]; then
    DIALCMD="C"
  else
    DIALCMD="c"
  fi

  # How many DIDs do we have?
  index=1
  for DIDnumberValue in `cat $didFile`; do
    theDIDs[$index]=$DIDnumberValue
    let index=($index + 1)
  done
  let DIDcount=($index - 1)

  # How many times do we need to loop through all of the sip phones?
  let loops=($index / $xlites)
  let junk=($loops * $xlites)
  [ $junk -lt $index ] && let loops=($loops + 1)

  currentDIDindex=1

  for ((pass=0; pass<$loops; pass++)); do

    for ((xliteindex=1; xliteindex<= $xlites; xliteindex++)); do
      thisDID=${theDIDs[$currentDIDindex]}
      let currentDIDindex=($currentDIDindex + 1) 
      if [ "x$thisDID" != "x" ]; then
        #As thisDID can include addtional trace DIDs separated by pipes, just dial the first one
        justTheFirstDID=`echo "$thisDID" | awk -F\| '{print $1}'`
        startDialling $justTheFirstDID $xliteindex $sipinfilebase $DIALCMD
        #But log the full set so the addtional can be used in trace greps
        log_event $thisDID
      fi
    done

    sleep 6

    #for ((xliteindex=1; xliteindex <= $xlites; xliteindex++)); do
    #  let junk=($pass * $xlites)
    #  let junk=($junk + $xliteindex)
    #  [ $junk -le $DIDcount ] && toggleRecording $xliteindex $sipinfilebase
    #done

    sleep 4

    for ((xliteindex=1; xliteindex <= $xlites; xliteindex++)); do
      let junk=($pass * $xlites)
      let junk=($junk + $xliteindex)
      [ $junk -le $DIDcount ] && stopCalling $xliteindex $sipinfilebase
    done

    sleep 1

  done

  echo $DIDcount
}

function startDialling() {
  DID=$1
  index=$2
  sipinfilebase=$3
  dialcmd=$4
  echo "$dialcmd 777661$DID" >> ${sipinfilebase}$index
}

function toggleRecording () {
  index=$1
  sipinfilebase=$2
  echo "tape" >>  ${sipinfilebase}$index
}

function stopCalling() {
  index=$1
  sipinfilebase=$2
  echo "h" >> ${sipinfilebase}$index
}

function log_event() {
  themessage="$1"
  theLine="`date  +'%Y-%m-%d %H:%M:%S'` $themessage "
  echo "$theLine" >> ./tmp/did.events.log
}

echo "xfileread Script: This script is an DID autodialler.  Found `processDIDfile $1 $2 $3` DIDs in $1."
