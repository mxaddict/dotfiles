import os

user = os.getlogin()

config.load_autoconfig()

c.auto_save.session = True

config.set(
    "content.headers.user_agent",
    "Mozilla/5.0 ({os_info}; rv:136.0) Gecko/20100101 Firefox/139.0",
    "https://accounts.google.com/*",
)

config.set("content.cookies.accept", "all", "chrome-devtools://*")

config.set("content.cookies.accept", "all", "devtools://*")

config.set("content.headers.accept_language", "", "https://matchmaker.krunker.io/*")

config.set("content.images", True, "chrome-devtools://*")

config.set("content.images", True, "devtools://*")

config.set("content.javascript.clipboard", "access-paste", "https://gemini.google.com")

config.set("content.javascript.enabled", True, "chrome-devtools://*")

config.set("content.javascript.enabled", True, "devtools://*")

config.set("content.javascript.enabled", True, "chrome://*/*")

config.set("content.javascript.enabled", True, "qute://*/*")

config.set(
    "content.local_content_can_access_remote_urls",
    True,
    "file:///home/" + user + "/.local/share/qutebrowser/userscripts/*",
)

config.set(
    "content.local_content_can_access_file_urls",
    False,
    "file:///home/" + user + "/.local/share/qutebrowser/userscripts/*",
)
