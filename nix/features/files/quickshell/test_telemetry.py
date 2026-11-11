import unittest
from telemetry import fields, privacy


class StatusTest(unittest.TestCase):
    def test_nmcli_ssid_delimiters(self):
        self.assertEqual(fields(r"*:Office\: guest\\wifi:80:5180 MHz"),
                         ["*", "Office: guest\\wifi", "80", "5180 MHz"])

    def test_privacy_excludes_idle_and_monitors(self):
        def node(media, name, state="running", monitor=False):
            return {"info": {"state": state, "props": {
                "media.class": media, "application.name": name,
                "stream.monitor": monitor}}}
        nodes = [node("Stream/Input/Audio", "Recorder"),
                 node("Stream/Input/Video", "Browser"),
                 node("Stream/Input/Audio", "Volume meter", monitor="true"),
                 node("Stream/Input/Audio", "Paused call", state="idle"),
                 node("Stream/Output/Audio", "Music"),
                 node("Audio/Source", "Unused microphone"), {}]
        self.assertEqual(privacy(nodes), {"microphone": ["Recorder"], "screenshare": ["Browser"]})


if __name__ == "__main__":
    unittest.main()
