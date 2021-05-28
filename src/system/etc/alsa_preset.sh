	for c in $(grep '\[.*\]' /proc/asound/cards | awk '{print $1}'); do
		f=/system/etc/alsa/$(cat /proc/asound/card$c/id).state
		if [ -e $f ]; then
			alsa_ctl -f $f restore $c
			alsa_amixer -c $c set Speaker 65%
		else
			alsa_ctl init $c
			alsa_amixer -c $c set Master on
			alsa_amixer -c $c set Master 100%
			alsa_amixer -c $c set Headphone on
			alsa_amixer -c $c set Headphone 100%
			alsa_amixer -c $c set Speaker 100%
			alsa_amixer -c $c set Capture 100%
			alsa_amixer -c $c set Capture cap
			alsa_amixer -c $c set PCM 100 unmute
			alsa_amixer -c $c set SPO unmute
			alsa_amixer -c $c set 'Mic Boost' 1
			alsa_amixer -c $c set 'Internal Mic Boost' 1
		fi
	done

	case "$(cat $DMIPATH/uevent)" in
		*S10T*)
			alsa_amixer -c 0 set Speaker 95%
			;;
		*)
			;;
	esac
