class_name InGameSounds
extends GPImageAndSoundDescriptions

const SOUNDS_DIR: String = "user://language_resources/"

var popup: AcceptDialog = AcceptDialog.new()


func _ready() -> void:
	add_child(popup)
	popup.dialog_text = ""
	popup.title = "FFmpeg Required"

	DirAccess.make_dir_recursive_absolute(Database.get_language_sound_path())
	
	Database.db.query("SELECT * FROM GPs WHERE GPs.Exception=0")
	for res: Dictionary in Database.db.query_result:
		var description_line: ImageAndSoundGPDescription = DESCRIPTION_LINE_SCENE.instantiate()
		description_line.get_sound_path = Database.get_gp_sound_path
		description_line.get_image_path = get_empty_string
		description_line.hide_image_part()
		description_container.add_child(description_line)
		description_line.set_gp(res)
		description_line.image_preview.hide()
		description_line.image_upload_button.hide()
	
	Database.db.query("SELECT * FROM Syllables WHERE Syllables.Exception=0")
	for res: Dictionary in Database.db.query_result:
		var description_line: ImageAndSoundGPDescription = DESCRIPTION_LINE_SCENE.instantiate()
		description_line.get_sound_path = Database.get_syllable_sound_path
		description_line.get_image_path = get_empty_string
		description_line.hide_image_part()
		description_container.add_child(description_line)
		res.Grapheme = res.Syllable
		description_line.set_gp(res)
		description_line.image_preview.hide()
		description_line.image_upload_button.hide()
	
	Database.db.query("SELECT * FROM Words WHERE Words.Exception=0")
	for res: Dictionary in Database.db.query_result:
		var description_line: ImageAndSoundGPDescription = DESCRIPTION_LINE_SCENE.instantiate()
		description_line.get_sound_path = Database.get_word_sound_path
		description_line.get_image_path = get_empty_string
		description_line.hide_image_part()
		description_container.add_child(description_line)
		res.Grapheme = res.Word
		description_line.set_gp(res)
		description_line.image_preview.hide()
		description_line.image_upload_button.hide()


func get_empty_string(_a: Variant) -> String:
	return ""


func _on_normalize_sounds_button_pressed() -> void:
	if not _is_ffmpeg_installed():
		_show_ffmpeg_instructions()
	else:
		normalize_all_mp3s(Database.get_language_sound_path())


func _is_ffmpeg_installed() -> bool:
	var ffmpeg_path: String = OS.get_environment("FFMPEG_PATH")

	# 1) Check if FFMPEG_PATH is set
	if ffmpeg_path.is_empty():
		_show_ffmpeg_instructions()
		return false

	# 2) Check if the binary exists
	if not FileAccess.file_exists(ffmpeg_path):
		_show_path_instructions()
		return false

	# 3) Try to execute
	var output: Array = []
	var exit_code: int = OS.execute(ffmpeg_path, ["-version"], output, true, true)
	if exit_code == 0:
		Logger.info("InGameSounds: ffmpeg is installed and working")
		return true
	else:
		_show_contact_developer_message()
		return false


func _show_ffmpeg_instructions() -> void:
	var os_name: String = OS.get_name()
	var message: String = "FFmpeg is required to normalize sounds.\n\n"
	message += "The FFMPEG_PATH environment variable is not defined.\n\n"
	message += "Please follow these steps carefully:\n"

	match os_name:
		"Windows":
			message += "1) Check if FFmpeg is installed by running in Command Prompt:\n" \
					   + "   ffmpeg -version\n" \
					   + "   If 'not recognized', download from:\n" \
					   + "   https://ffmpeg.org/download.html\n\n" \
					   + "2) Find the absolute path with:\n" \
					   + "   where ffmpeg\n" \
					   + "   Example result: C:\\ffmpeg\\bin\\ffmpeg.exe\n\n" \
					   + "3) Define FFMPEG_PATH as a system environment variable:\n" \
					   + "   - Open Control Panel → System → Advanced system settings\n" \
					   + "   - Click 'Environment Variables'\n" \
					   + "   - Add a new variable: Name = FFMPEG_PATH, Value = C:\\ffmpeg\\bin\\ffmpeg.exe\n\n" \
					   + "4) Restart your computer (so all apps, including GUI apps, can see the variable).\n"

		"macOS":
			message += "1) Check if FFmpeg is installed by running in Terminal:\n" \
					   + "   ffmpeg -version\n" \
					   + "   If 'command not found', install it with Homebrew:\n" \
					   + "   brew install ffmpeg\n\n" \
					   + "2) Find the absolute path with:\n" \
					   + "   which ffmpeg\n" \
					   + "   Example result: /usr/local/bin/ffmpeg or /opt/homebrew/bin/ffmpeg\n\n" \
					   + "3) Define FFMPEG_PATH so that ALL applications (including GUI apps) can use it:\n" \
					   + "   launchctl setenv FFMPEG_PATH /usr/local/bin/ffmpeg\n\n" \
					   + "   (Replace with your actual path.)\n" \
					   + "   To make this permanent, add the command to your login script (e.g. ~/.zprofile).\n\n" \
					   + "4) Log out and log back in (or reboot) so GUI apps like Godot can see the variable.\n"

		"Linux":
			message += "1) Check if FFmpeg is installed by running in Terminal:\n" \
					   + "   ffmpeg -version\n" \
					   + "   If 'command not found', install it with your package manager, e.g.:\n" \
					   + "   sudo apt install ffmpeg     (Debian/Ubuntu)\n" \
					   + "   sudo dnf install ffmpeg     (Fedora)\n" \
					   + "   sudo pacman -S ffmpeg       (Arch Linux)\n\n" \
					   + "2) Find the absolute path with:\n" \
					   + "   which ffmpeg\n" \
					   + "   Example result: /usr/bin/ffmpeg\n\n" \
					   + "3) Define FFMPEG_PATH globally so GUI apps can use it:\n" \
					   + "   - Edit ~/.profile or ~/.pam_environment\n" \
					   + "   - Add this line:\n" \
					   + "     export FFMPEG_PATH=/usr/bin/ffmpeg\n\n" \
					   + "4) Log out and log back in (or reboot) so GUI apps like Godot can see the variable.\n"

		_:
			message += "Unknown operating system.\n" \
					   + "Install FFmpeg from https://ffmpeg.org/download.html\n" \
					   + "Then define the FFMPEG_PATH environment variable pointing to the ffmpeg binary.\n"

	popup.dialog_text = message
	popup.popup_centered()


func _show_path_instructions() -> void:
	var message: String = "The FFMPEG_PATH environment variable is set, but the file cannot be found.\n\n" \
				   + "Please ensure the variable points to a valid ffmpeg binary.\n\n" \
				   + "Tips:\n" \
				   + "- Verify the binary exists and is executable by running:\n" \
				   + "  \"/absolute/path/to/ffmpeg\" -version\n" \
				   + "  (Quote the path if it contains spaces.)\n" \
				   + "- Use 'where ffmpeg' on Windows or 'which ffmpeg' on Linux/macOS to discover the correct path."
	popup.dialog_text = message
	popup.popup_centered()


func _show_contact_developer_message() -> void:
	var message: String = "FFmpeg was found but could not be executed.\n\n" \
				   + "Please contact the developer for assistance.\n\n" \
				   + "Include the output of the following command in your report:\n" \
				   + "  \"${FFMPEG_PATH}\" -version"
	popup.dialog_text = message
	popup.popup_centered()


func normalize_all_mp3s(path: String) -> void:
	Logger.info("InGameSounds: Normalizing MP3 at path %s" % path)
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		push_error("Cannot open directory: %s" % path)
		return
	
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if dir.current_is_dir() and file_name != "." and file_name != "..":
			normalize_all_mp3s(path + file_name + "/") # recursion
		elif file_name.ends_with(".mp3"):
			_normalize_file(path + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()


# --- Normalization settings (for longer files) ---
const TARGET_I: String = "-12"       # Target integrated loudness (LUFS)
const TARGET_TP: String = "0"        # True peak limit in dBTP
const TARGET_LRA: String = "11"      # Allowed loudness range
const EXTRA_GAIN: String = "3dB"     # Extra gain after normalization

# --- Compressor settings ---
const COMP_THRESHOLD: String = "-25dB"
const COMP_RATIO: String = "4"
const COMP_ATTACK: String = "5"
const COMP_RELEASE: String = "50"

# --- Dynamic normalization settings (for short sounds) ---
const DYNA_F: String = "75"   # window size in ms
const DYNA_G: String = "25"   # max gain in dB

# --- Duration threshold ---
const SHORT_SOUND_LIMIT: float = 5.0  # seconds


func _get_duration(file_path: String) -> float:
	# Use ffprobe to get duration in seconds
	var ffmpeg_bin: String = OS.get_environment("FFMPEG_PATH")
	if ffmpeg_bin.is_empty():
		ffmpeg_bin = "ffmpeg"
	var ffprobe_bin: String = ffmpeg_bin.replace("ffmpeg", "ffprobe")

	var args: PackedStringArray = [
		"-v", "error",
		"-show_entries", "format=duration",
		"-of", "default=noprint_wrappers=1:nokey=1",
		file_path
	]

	var output: Array = []
	var exit_code: int = OS.execute(ffprobe_bin, args, output, true, true)
	if exit_code != 0 or output.size() == 0:
		Logger.error("InGameSounds: ❌ Could not get duration for " + file_path)
		return -1.0

	return float(output[0])


func _normalize_file(file_path: String) -> void:
	Logger.info("InGameSounds: Normalizing file %s" % file_path)

	var input_path: String = ProjectSettings.globalize_path(file_path)
	var temp_path: String = input_path + ".tmp.mp3"

	# Get ffmpeg binary (user configured or fallback)
	var ffmpeg_bin: String = OS.get_environment("FFMPEG_PATH")
	if ffmpeg_bin.is_empty():
		ffmpeg_bin = "ffmpeg"

	# ---------- Check duration ----------
	var duration: float = _get_duration(input_path)
	if duration <= 0:
		Logger.error("InGameSounds: ❌ Invalid duration for " + file_path)
		return

	# ---------- Branch: short sound (< SHORT_SOUND_LIMIT) ----------
	var exit_code: int 
	if duration < SHORT_SOUND_LIMIT:
		Logger.info("InGameSounds: Short sound detected (%.2fs), using dynaudnorm" % duration)

		var args: PackedStringArray = [
			"-y",
			"-i", input_path,
			"-af", "dynaudnorm=f=%s:g=%s" % [DYNA_F, DYNA_G],
			temp_path
		]

		exit_code = OS.execute(ffmpeg_bin, args, [], false, true)
		if exit_code == 0:
			var dir: DirAccess = DirAccess.open(file_path.get_base_dir())
			if dir != null:
				dir.remove(file_path)
				dir.rename(temp_path, file_path)
			Logger.trace("InGameSounds: ✅ Normalized short sound: " + file_path)
		else:
			Logger.error("InGameSounds: ❌ Error %d normalizing short sound: %s" % [exit_code, file_path])
			var dir_cleanup: DirAccess = DirAccess.open(file_path.get_base_dir())
			if dir_cleanup != null and dir_cleanup.file_exists(temp_path):
				dir_cleanup.remove(temp_path)
		return

	# ---------- Branch: longer sound (>= SHORT_SOUND_LIMIT) ----------
	Logger.info("InGameSounds: Long sound detected (%.2fs), using compressor + loudnorm" % duration)

	# First pass: analysis
	var filter_analyse: String = "acompressor=threshold=%s:ratio=%s:attack=%s:release=%s,loudnorm=I=%s:TP=%s:LRA=%s:print_format=json,volume=%s" % [
		COMP_THRESHOLD, COMP_RATIO, COMP_ATTACK, COMP_RELEASE,
		TARGET_I, TARGET_TP, TARGET_LRA, EXTRA_GAIN
	]

	var args_analyse: PackedStringArray = [
		"-i", input_path,
		"-af", filter_analyse,
		"-f", "null",
		"-"
	]

	var analyse_output: Array = []
	exit_code = OS.execute(ffmpeg_bin, args_analyse, analyse_output, true, true)
	if exit_code != 0:
		Logger.error("InGameSounds: ❌ Analysis failed for " + file_path)
		return

	var joined_output: String = "\n".join(analyse_output)
	var json_start: int = joined_output.find("{")
	var json_end: int = joined_output.rfind("}")

	if json_start == -1 or json_end == -1 or json_end <= json_start:
		Logger.error("InGameSounds: ❌ Could not extract JSON from ffmpeg output for " + file_path)
		return

	var json_text: String = joined_output.substr(json_start, json_end - json_start + 1)
	var json: JSON = JSON.new()
	var error: Error = json.parse(json_text)

	if error != OK:
		Logger.error("InGameSounds: ❌ JSON parse failed for " + file_path + " - " + json.get_error_message())
		return

	var j: Dictionary = json.get_data()

	# Second pass: apply normalization
	var filter_apply: String = "acompressor=threshold=%s:ratio=%s:attack=%s:release=%s,loudnorm=I=%s:TP=%s:LRA=%s:measured_I=%s:measured_LRA=%s:measured_tp=%s:measured_thresh=%s:offset=%s:linear=true:print_format=summary,volume=%s" % [
		COMP_THRESHOLD, COMP_RATIO, COMP_ATTACK, COMP_RELEASE,
		TARGET_I, TARGET_TP, TARGET_LRA,
		str(j.get("input_i", "0")),
		str(j.get("input_lra", "0")),
		str(j.get("input_tp", "0")),
		str(j.get("input_thresh", "0")),
		str(j.get("target_offset", "0")),
		EXTRA_GAIN
	]

	var args_apply: PackedStringArray = [
		"-y",
		"-i", input_path,
		"-af", filter_apply,
		temp_path
	]

	exit_code = OS.execute(ffmpeg_bin, args_apply, [], false, true)
	if exit_code == 0:
		var dir: DirAccess = DirAccess.open(file_path.get_base_dir())
		if dir != null:
			dir.remove(file_path)
			dir.rename(temp_path, file_path)
		Logger.trace("InGameSounds: ✅ Normalized long sound: " + file_path)
	else:
		Logger.error("InGameSounds: ❌ Error %d normalizing long sound: %s" % [exit_code, file_path])
		var dir_cleanup: DirAccess = DirAccess.open(file_path.get_base_dir())
		if dir_cleanup != null and dir_cleanup.file_exists(temp_path):
			dir_cleanup.remove(temp_path)
