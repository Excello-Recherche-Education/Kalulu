extends SceneTree

func _initialize() -> void:
    # Load stubs so typed classes like TeacherSettings are registered
    preload("res://teacher_settings_stub.gd")
    preload("res://user_remediation_stub.gd")
    # ServerManager is copied into the test project so we can load it directly
    var server_scene = load("res://server_manager.tscn")
    var server_manager = server_scene.instantiate()
    get_root().add_child(server_manager)
    await process_frame
    var result = await server_manager.check_email("github-test@this-email-does-not-exists.com")
    if result.code != 200:
        push_error("Expected code 200 for first email, got %s" % result.code)
        quit(1)
        return
    result = await server_manager.check_email("developer@excellolab.org")
    if result.code != 400:
        push_error("Expected code 400 for second email, got %s" % result.code)
        quit(1)
        return
    if result.body != {"error": "Email address already used"}:
        push_error("Unexpected body for second email: %s" % str(result.body))
        quit(1)
        return
    print("Email checks passed")
    quit(0)

