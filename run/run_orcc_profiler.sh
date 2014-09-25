#!/bin/bash

usage() { 
    echo
    echo "Usage: $0 "
    echo "   -w   <working_directory>         path to folder used to perform build & tests"
    echo "   -d   <projects_directory>        folder containing CAL projects"
    echo "   -p   <project_name>              CAL project name containing application to build"
    echo "   -x   <network_file>              network file name (e.g. src/Hello.xdf)"
    echo "   -o   <output_folder>             output folder"
    echo "   -t   <trace_project_name>        trace project name"
    echo "   -i   <input_stimulus_file>       [optional] input file to pass to application"
    echo "   -b   <buffer_size>               [optional] buffer size value in number of tokens (value = {1,2, ..., n})"
    echo "   -r   <b>,<b>,<b>                 [optional] type resize options (b = {true,false})"
    echo "   -c   <b>,<b>,<b>,<b>,<b>,<b>,<b> [optional] ir code transformation options (b = {true,false})"
	
    exit 1
}

# Import constants
source $(dirname $0)/../utils/defines.sh

# pre-set optional values
i=""
b=512
r=("false" "false" "false")
k=("false" "false" "false" "false" "false" "false" "false")

# parse all the values
while getopts ":w:d:p:x:o:t:i:r:c:b:" tmp; do
    case "${tmp}" in
        w)
            w=${OPTARG}
            ;;
        d)
            d=${OPTARG}
            ;;
        p)
            p=${OPTARG}
            ;;
        x)	
            x=${OPTARG}
            ;;
        o)
            o=${OPTARG}
            ;;
        t)	
            t=${OPTARG}
            ;;
        i)
            i=${OPTARG}
            ;;
        r)
            string=${OPTARG}
            oldIFS="$IFS"
	    IFS=','
	    r=( $string )
	    IFS="$oldIFS"
            if [[ ${#r[@]} != 3 ]]; then
		echo "resize parameters not consistent"
	    else
	       for tmp2 in "${r[@]}"
		do
	          if ! isBoolean $tmp2 ; then
            	   echo "Error resize parametrs not boolean"
		     usage
	    	  fi
		done
	    fi
            ;;
        k)
            string=${OPTARG}
            oldIFS="$IFS"
	    IFS=','
	    c=( $string )
	    IFS="$oldIFS"
 	    if [[ ${#k[@]} != 7 ]]; then
		echo "tranformation parameters not consistent"
	    else
	       for tmp2 in k
		do
	          if ! isBoolean $tmp2 ; then
            	   echo "Error transformation parametrs not boolean"
		     usage
	    	  fi
		done
	    fi	
            ;;
        b)
	    
            b=${OPTARG}
	    if ! isNumber $b ; then
            	echo "Error parsing buffer size"
		usage
	    fi
            ;;
    esac
done
shift $((OPTIND-1))

# check required values
isValid=true
[ -z "$w" ]  && echo "Missing Working directory" && isValid=false
[ -z "$d" ]  && echo "Missing CAL projects directory" && isValid=false
[ -z "$p" ]  && echo "Missing CAL project name" && isValid=false
[ -z "$x" ]  && echo "Missing network file name" && isValid=false
[ -z "$o" ]  && echo "Missing output folder" && isValid=false
[ -z "$t" ]  && echo "Missing trace project name" && isValid=false
if ! $isValid; then
  usage
fi

# setup the eclipse environment
setupEclipse $w

# ok now it is possible to launch the profiler
APPDIR=$d
CAL_PROJECT=$p
NETWORK=$x
OUTPUT_PATH=$o
TRACE_PROJECT=$t
INPUT=$i
RESIZER=$r
TRANSFO=$k
INPUT_STIMULUS=$i

# get the Orcc Qualified name of the network
QUALIFIED_NAME="$( echo "$NETWORK" | sed -e 's#^src/##; s#.xdf$##' )"
QUALIFIED_NAME=${QUALIFIED_NAME////.} 

# Split 2 test to perform a "short circuit evaluation"
[ "$FIFOSIZE" -ge 2 ] 2>/dev/null && SETFIFO="-s $FIFOSIZE" && echo "Fifo size set to $FIFOSIZE"

echo "***START*** $0 $(date -R)"

RUNWORKSPACE=$APPDIR
rm -fr $RUNWORKSPACE/.metadata $RUNWORKSPACE/.JETEmitters
rm -fr $RUNWORKSPACE/**/bin

echo "Register Orcc projects in eclipse workspace"
$ECLIPSE_BUILD/eclipse  -nosplash -consoleLog \
                        -application net.sf.orcc.cal.workspaceSetup \
                        -data $RUNWORKSPACE \
                        $APPDIR

echo "Generate Orcc IR for $CAL_PROJECT and projects it depends on"
$ECLIPSE_BUILD/eclipse  -nosplash -consoleLog \
                        -application net.sf.orcc.cal.cli \
                        -data $RUNWORKSPACE \
                        $CAL_PROJECT \
                        $QUALIFIED_NAME \
                        -vmargs -Xms40m -Xmx768m

echo "Run simulation"
$ECLIPSE_BUILD/eclipse  -nosplash -consoleLog \
                        -application co.turnus.profiler.orcc.sim.cli \
                        -data $RUNWORKSPACE \
			-x $NETWORK \
                        -p $CAL_PROJECT \
			-o $OUTPUT_PATH \
			-t $TRACE_PROJECT \
                        -z \
		        -i $INPUT_STIMULUS \
			-resizer ${RESIZER[0]},${RESIZER[1]},${RESIZER[2]} \
                        -transfo ${TRANSFO[0]},${TRANSFO[1]},${TRANSFO[2]},${TRANSFO[3]},${TRANSFO[4]},${TRANSFO[5]},${TRANSFO[6]} \
                        -vmargs -Xms40m -Xmx1024m

echo "***END*** $0 $(date -R)"
