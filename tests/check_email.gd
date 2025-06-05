extends SceneTree

func _initialize() -> void:
    # When running the test project from tests/godot, res:// points to that
    # directory. ServerManager lives in the repository sources folder one level
    # above, so load it relatively.
    var server_scene = load("res://../sources/utils/autoloads/server_manager.tscn")
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

