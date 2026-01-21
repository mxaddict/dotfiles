import os
from qutebrowser.config.configfiles import ConfigAPI  # noqa: F401
from qutebrowser.config.config import ConfigContainer  # noqa: F401

config: ConfigAPI = config  # noqa: F821 pylint: disable=E0602,C0103
c: ConfigContainer = c  # noqa: F821 pylint: disable=E0602,C0103
config.source("./tokyonight.py")

user = os.getlogin()

config.load_autoconfig()

c.auto_save.session = True

c.editor.command = ["alacritty", "--class", "floating", "-e", "nvim", "{file}"]

# Set the font family and size
c.fonts.tabs.selected = "16px Hack Nerd Font Mono"
c.fonts.tabs.unselected = "16px Hack Nerd Font Mono"
c.fonts.statusbar = "16px Hack Nerd Font Mono"
c.fonts.completion.entry = "16px Hack Nerd Font Mono"
c.fonts.completion.category = "16px Hack Nerd Font Mono"

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

config.bind(
    "<esc>",
    "clear-keychain ;; search ;; fullscreen --leave ;; fake-key <esc>",
    mode="normal",
)

config.bind("<space><space>", "edit-url", mode="normal")
config.bind("<space><r>", "config-source")

config.bind("<space><l>", "spawn --userscript qute-pass")
config.bind("<space><u><l>", "spawn --userscript qute-pass --username-only")
config.bind("<space><p><l>", "spawn --userscript qute-pass --password-only")
config.bind("<space><o><l>", "spawn --userscript qute-pass --otp-only")
