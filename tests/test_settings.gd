extends GutTest
## Cài đặt khởi chạy: mặc định tiếng Việt trên mọi nền tảng để web và điện thoại giống nhau (người duyệt 1/11).


func test_default_language_is_vietnamese() -> void:
	assert_eq(Settings.DEFAULT_LOCALE, "vi")


func test_language_can_be_chosen_from_the_url() -> void:
	assert_eq(Settings.query_value("?lang=en&debug", "lang"), "en")
	assert_eq(Settings.query_value("?debug", "lang"), "")
