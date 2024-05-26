sym="ó"
edSym="*"
mark=5

main()
{
	# terminal sizes
	xSize=$(tput cols)
	ySize=$(tput lines)

	xCenter=$((xSize / 2))
	yCenter=$((ySize / 2))

	x=$xCenter
	y=$yCenter

	declare -A arr

	for arg in "$@"; do
		case $arg in
			--help|-h) msg 4 ;;
			--about|-a) msg 3 ;;
		esac
	done

	wInit
	quitHandler

	mkEds $mark

	for ((;;))
	{
		(( mark == score )) && msg 1

		drawHud
		drawEds
		collision
		drawPointer
		inputHandler
	}
	return 0
}

# GAME MECHANICS

mkEds()
{
	# $1: generate edibles with random x, y
	local count=$1

	for ((i=0;i<count;i++)); do
		local x=$(genRandom "$xSize")
		local y=$(genRandom "$ySize" - 1)
		arr["$y;$x"]=1
	done
}

collision()
{
	eval "
	case \"\$y;\$x\" in
		$(for i in "${!arr[@]}"; do
			echo "\"$i\") unset arr\[\"$i\"\] && (( score++ )) ;;"
		done)
	esac
	"
}

drawHud(){ printf "\e[999Hscore=%d" "$score"; }

drawPointer() { printf "\e[%d;%dH%s" "$y" "$x" "$sym"; }

drawEds()
{
	for i in "${!arr[@]}"; do
		(( ${arr[$i]} )) && printf "\e[%sH%s" "$i" "$edSym"
	done
}

# TERMINAL ONLY

wInit() { stty -icanon -echo && printf "\e[33m\e[2J\e[?25l"; }

restoreTerm() { stty icanon echo && clear && printf "\e[?25h\e[0m" && exit; }

quitHandler() { trap 'restoreTerm' EXIT && trap 'msg 2 && restoreTerm' SIGWINCH; }

inputHandler()
{
	read -rsn1 key

	case $key in
		w|k) (( $y - 1 > 0 )) && (( y-- )) && printf "\e[2J" ;;
		a|h) (( $x - 1 > 0 )) && (( x-- )) && printf "\e[2J" ;;
		s|j) (( $y < $ySize )) && (( y++ )) && printf "\e[2J" ;;
		d|l) (( $x < $xSize )) && (( x++ )) && printf "\e[2J" ;;
		q) exit ;;
	esac
}

# ADDITIONAL THINGS

genRandom()
{
	# $1: maximum random value
	local min=1 max=$1
	echo $(( min + RANDOM % (max - min + 1) ))
}

message="Usage: orange.sh [options]

Options:
  --help    display this message and exit
  --about   little story about this game

Author: Arseniy \"everydayikillmylinux\" Kudashkin
"

msg()
{
	# $1: message type to output
	(( $1 == 1 )) &&
	{
		for (( i=0; i<20;i++ )); do
			printf "\e[%sm" "$(( 32 + i % 2 * 58 ))"
			printf "\e[%d;%dH%s" "$yCenter" "$xCenter" "WIN!"
			sleep 0.1
		done
		exit
	}
	(( $1 == 2 )) && printf "\e[2J\e[0H\e[31m%s" \
		"The window size has changed. Exit!" && sleep 2
	(( $1 == 3 )) && drawAsciiArt && exit
	(( $1 == 4 )) && printf "$message" && exit
}

drawAsciiArt()
{
	printf "\e[33m"
	cat << "EOF"

    ___          ,
    `  `--.    ,'
     `.    \  /    |
       `-.._\/    .|/
            /   ---X--
            |     /|`
      _,--''''-..  |
    ,'           `.
   /               `.
  /                  \
 |                    |
 |                    | TEXT HERE
 |                    | TEXT HERE
 |                    |
  \                  /
  '.                /
    `.            ,'
      `.._ __ _,-'

EOF
	printf "\e[0m"
}

main "$@"
