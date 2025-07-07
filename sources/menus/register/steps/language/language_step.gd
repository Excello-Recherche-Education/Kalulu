@tool
extends Step
class_name LanguageStep

@onready var language_field: OptionButton = %LanguageField
var items: Array[String] = []

func on_enter() -> void:
    super.on_enter()
    items.clear()
    language_field.clear()
    var idx: int = 0
    for locale: String in DeviceSettings.SUPPORTED_LOCALES:
        if not locale:
            continue
        var name := TranslationServer.get_locale_name(locale)
        if not name:
            continue
        language_field.add_item(name, idx)
        items.append(locale)
        if locale == UserDataManager.get_device_settings().language:
            language_field.select(idx)
        idx += 1

func get_selected_language() -> String:
    var id: int = language_field.get_selected_id()
    if id >= 0 and id < items.size():
        return items[id]
    return ""

func _on_language_selected(index: int) -> void:
    if index >= 0 and index < items.size():
        UserDataManager.set_language(items[index])

func _on_next() -> bool:
    var lang := get_selected_language()
    if lang:
        UserDataManager.set_language(lang)
    return true
