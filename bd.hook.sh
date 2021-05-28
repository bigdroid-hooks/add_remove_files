#!/usr/bin/env bash

#           Variables - BigDroid Internals
#           - Only for advanced scripting -
#           ###############################
#
#   BASE_DIR            % The root dir where you find files like: bigdroid, bin, src.
#                       % Hope it explains the rest.
#
#   SRC_DIR             % The 'src' dir under BASE_DIR.
#
#   HOOKS_DIR           % The 'hooks' dir under BASE_DIR.
#
#   HOOK_BASE           % This variable points to the root-dir
#                       % of every bigdroid hook which is being run during their runtime.
#
#   MOUNT_DIR           % The parent dir which holds other child mountpoint dirs.
#                       % Followed by: system, secondary_ramdisk, initial_ramdisk and install_ramdisk.
#                       % We also have SYSTEM_MOUNT_DIR, SECONDARY_RAMDISK_MOUNT_DIR
#                       % INITIAL_RAMDISK_MOUNT_DIR and INSTALL_RAMDISK_MOUNT_DIR variables.
#
#   ISO_DIR             % Your configured ISO by the '--setup-iso' argument is cached in this dir.
#
#   BUILD_DIR           % This dir is used as the temporary boilerplate while building an ISO/IMAGE.
#
#   TMP_DIR             % You can use this dir for storing temporary files.
#                       % It's more like '/tmp' as in your linux distro.
#
#   OVERLAY_DIR         % The overlay dir under BASE_DIR
#
#   DISTRO_NAME         % Your android distro name as per 'hooks/distro.sh' or the defaults.
#
#   DISTRO_VERSION      % Your android distro version as per 'hooks/distro.sh' or the defaults.
#
#   @@ Protip: Take a look at 'src/main.sh'.



#           General Functions - BigDroid Utils
#              - For easy hooks scripting -
#           ##################################
#
#   gclone              % Copy files preserving all their attrs with progress indicator.
#                       % Example: `gclone "$HOOK_BASE/myfile.txt" "$SYSTEM_DIR/lib64"`
#
#   wipedir             % Easily wipe/empty a dir(childs) without removing it's parent.
#                       % Example: `wipedir "$MOUNT_DIR_INSTALL_RAMDISK/grub"`
#
#   @@ Protip: Take a look at 'src/utils.sh'
#
#
#
#
#             libgearlock - GearLock utils
#     - Some native gearlock vars and functions -
#           ###############################
#
#   %% Simply take a look at 'src/libgearlock.sh' to know
#   %% which gearlock variables and functions are available for use.



#               An example hook script
#           - To give you some quick idea -
#           ###############################

## Okay so here we go...
## Basically if you wanna start with this example script,
## then copy this `example_hook` dir into `hooks/` dir.
## Then start up editing it's `bd.hook.sh`.

_src_dir="$HOOK_BASE/src"
_patches_dir="$HOOK_BASE/patches"
DIRS=(
	"${SYSTEM_MOUNT_DIR}"
	"${INITIAL_RAMDISK_MOUNT_DIR}"
	"${SECONDARY_RAMDISK_MOUNT_DIR}"
	"${INSTALL_RAMDISK_MOUNT_DIR}"
)
_removal_list="$HOOK_BASE/removal_list"

# for _dir in "${DIRS[@]}"; do
# 	eval "$_dir=\"$_src_dir/$_dir\""
# done

### Process removal list if required
if test -e "$_removal_list"; then
	PFUNCNAME="$CODENAME" println "Removing files"
	mapfile -t _removal_list < "$_removal_list"
	for _file in "${_removal_list[@]}"; do
		_target="$(eval "echo \"$_file\"")"
		if test -e "$_target"; then
			rm -r "$_target"
		fi
		unset _target
	done
fi

### Apply patches
mapfile -t _patches < <(find "$_patches_dir" -mindepth 1 -type f -name '*.ppatch')
for _patch in "${_patches[@]}"; do
	_real_path="$SYSTEM_DIR/$(sed 's|##|/|g; s|.ppatch||g' <<<"${_patch##*/}")"
	PFUNCNAME="$CODENAME" println "Applying patches for ${_real_path##*/}"
	patch -s "$_real_path" < "$_patch"
	unset _real_path
done

cd "$_src_dir" || exit
for _dir in "${DIRS[@]}"; do

# 	case "$_dir" in
# 		system)
# 			: "$SYSTEM_MOUNT_DIR"
# 			;;
# 		initial_ramdisk)
# 			: "$INITIAL_RAMDISK_MOUNT_DIR"
# 			;;
# 		secondary_ramdisk)
# 			: "$SECONDARY_RAMDISK_MOUNT_DIR"
# 			;;
# 		install_ramdisk)
# 			: "$INSTALL_RAMDISK_MOUNT_DIR"
# 			;;
# 		*)
# 			exit 1
# 			;;
# 	esac
# 	_target_dir="$_"

# 	mapfile -t _apps_list < <(find "$_dir" -type f -name '*.apk')
#
# 	### First install as necessary
# 	for _app in "${_apps_list[@]}"; do
# 		_target="$SYSTEM_DIR/$_dir/${_app%.apk}"
# 		wipedir "$_target" || exit
# 		mkdir -p "$_target" && chmod 755 "$_target" || exit
# 		PFUNCNAME="${PWD##*/}" println "Installing ${_app##*/} in system/$_dir"
# 		rsync "$_app" "$_target" && chmod -R 644 "$_target/"* || exit
# 	done

	### Add files
	_select="${_dir##*/}"
	if test -e "$_select"; then
		PFUNCNAME="$CODENAME" println "Adding files for $_select"
		find "$_select" -type d -exec chmod 755 {} \;
		find "$_select" -type f -exec chmod 644 {} \;
		find "$_select" -mindepth 1 -type d -name '*bin*' -exec chmod -R 755 {} \;
		find "$_select" -mindepth 1 -type f -name '*.sh' -exec chmod 755 {} \;
		gclone "$_select/" "$_dir"
	fi

done


