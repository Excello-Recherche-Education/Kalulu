extends "res://addons/gut/test.gd"

var output_dir = "res://tests/test_data/tmp/zip_unzip/unzipped/"

func test_unzip_folder():
	var unzipper = load("res://folder_unzipper.gd").new()
	var input_zip = "res://tests/test_data/test_data.zip"

	# Simule un fichier ZIP (tu dois en avoir un valide dans test_data)
	var result = unzipper.extract(input_zip, output_dir)
	assert_true(result == "test_data.txt", "extract test_data.txt obtains " + result)
	assert_files_identical("res://tests/test_data/zip_unzip/test_data.txt", output_dir + "test_data/test_data.txt")

func assert_files_identical(path1: String, path2: String):
	var file1 = FileAccess.open(path1, FileAccess.READ)
	var file2 = FileAccess.open(path2, FileAccess.READ)

	assert_true(file1 != null and file2 != null, "Les deux fichiers doivent pouvoir être ouverts")

	var content1 = file1.get_as_text()
	var content2 = file2.get_as_text()

	assert_eq(content1, content2, "Les contenus des fichiers sont différents")

func after_all():
	# Nettoyage
	if FileAccess.file_exists(output_dir):
		DirAccess.remove_absolute(output_dir)
