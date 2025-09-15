import os
from qutebrowser.config.configfiles import ConfigAPI  # noqa: F401
from qutebrowser.config.config import ConfigContainer  # noqa: F401
config: ConfigAPI = config  # noqa: F821 pylint: disable=E0602,C0103
c: ConfigContainer = c  # noqa: F821 pylint: disable=E0602,C0103

user = os.getlogin()

config.load_autoconfig()

c.auto_save.session = True

c.editor.command = ["alacritty", "-e", "helix", "{file}"]

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

config.set("content.notifications.enabled", False)

config.set("colors.webpage.preferred_color_scheme", "dark")

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

config.bind("H", "tab-prev")
config.bind("J", "back")
config.bind("K", "forward")
config.bind("L", "tab-next")

config.bind("<z><l>", "spawn --userscript qute-pass")
config.bind("<z><u><l>", "spawn --userscript qute-pass --username-only")
config.bind("<z><p><l>", "spawn --userscript qute-pass --password-only")
config.bind("<z><o><l>", "spawn --userscript qute-pass --otp-only")

config.bind('<c><s>', 'config-source')

config.bind('<esc>', 'clear-keychain ;; search ;; fullscreen --leave ;; fake-key <esc>', mode='normal')

config.bind('<space><space>', 'cmd-set-text :open -t', mode='normal')
config.bind('<space><f>', 'cmd-set-text :open -t {url:pretty}', mode='normal')
