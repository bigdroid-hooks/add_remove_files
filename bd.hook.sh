#           Variables - BigDroid Internals
#           - Only for advanced scripting -
#           ###############################

#   SRC_DIR             % The 'src' dir is the mountpoint of the project operating-system IMAGE.
#
#   HOOK_DIR            % This variable points to the root-dir
#                       % of a bigdroid hook which is being run.
#
#   MOUNT_DIR           % The parent dir which holds other child mountpoint dirs.
#                       % Followed by: system, secondary_ramdisk, initial_ramdisk and install_ramdisk.
#                       % Use `SYSTEM_MOUNT_DIR`, `SECONDARY_RAMDISK_MOUNT_DIR`
#                       % `INITIAL_RAMDISK_MOUNT_DIR`, `INSTALL_RAMDISK_MOUNT_DIR` variables for path.
#
#   TMP_DIR             % You can use this dir for storing temporary files.
#                       % It's equivalent '/tmp' dir but for bigdroid hooks.
#
#   SECONDARY_RAMDISK   % This is either true or false aka a bolean.
#                       % Depends on whether the project operating-system has a ramdisk.img
#
#   SYSTEM_IMAGE        % This points to the project system image (system.sfs or system.img) file.
#
#   @@ Tip: Also all the varaibles defined in the project `Bigdroid.meta` can be used.



#           General Functions - BigDroid Utils
#              - For easy hooks scripting -
#           ##################################
#
#   gclone              % Copy(rsync) files preserving all their attrs with progress indicator.
#                       % Example: `gclone "$HOOK_DIR/myfile.so" "$SYSTEM_DIR/lib64"`
#
#   wipedir             % Easily wipe/empty a dir(childs) without removing it's parent.
#                       % Example: `wipedir "$INSTALL_RAMDISK_MOUNT_DIR/grub"`
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
#   %% Simply take a look at 'https://github.com/bigdroid/bigdroid/blob/main/src/libgearlock.sh' to know
#   %% which gearlock variables and functions are available for use.


_src_dir="$HOOK_DIR/src"
_patches_dir="$HOOK_DIR/patches"
DIRS=(
	"${SYSTEM_MOUNT_DIR}"
	"${INITIAL_RAMDISK_MOUNT_DIR}"
	"${SECONDARY_RAMDISK_MOUNT_DIR}"
	"${INSTALL_RAMDISK_MOUNT_DIR}"
)
_removal_list="$HOOK_DIR/removal_list"

# for _dir in "${DIRS[@]}"; do
# 	eval "$_dir=\"$_src_dir/$_dir\""
# done

### Process removal list if required
if test -e "$_removal_list"; then
	log::info "Removing bloaty files";
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
	log::info "Applying patches for ${_real_path##*/}"
	patch -s "$_real_path" < "$_patch"
	unset _real_path
done

cd "$_src_dir"
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
		log::info "Adding files for $_select"
		find "$_select" -type d -exec chmod 755 {} \;
		find "$_select" -type f -exec chmod 644 {} \;
		find "$_select" -mindepth 1 -type d -name '*bin*' -exec chmod -R 755 {} \;
		find "$_select" -mindepth 1 -type f -name '*.sh' -exec chmod 755 {} \;
		gclone "$_select/" "$_dir"
	fi

done


