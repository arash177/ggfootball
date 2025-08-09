import time
from telethon import TelegramClient, sync
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.textinput import TextInput
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.clock import Clock
from kivy.uix.filechooser import FileChooserIconView
from kivy.uix.popup import Popup

class GFootballApp(App):
    def build(self):
        self.api_id_input = TextInput(hint_text='API ID', multiline=False, input_filter='int')
        self.api_hash_input = TextInput(hint_text='API Hash', multiline=False)
        self.phone_input = TextInput(hint_text='Phone (+98...)', multiline=False)
        self.group_ids_input = TextInput(hint_text='Group IDs (comma separated)', multiline=False)
        self.caption_input = TextInput(hint_text='Caption', multiline=True)
        self.interval_input = TextInput(hint_text='Interval seconds', multiline=False, input_filter='int')
        self.photo_path = ''

        self.file_chooser = FileChooserIconView()
        self.file_chooser.bind(on_selection=self.select_photo)
        self.file_chooser_popup = Popup(title='Select Photo', content=self.file_chooser, size_hint=(0.9, 0.9))

        layout = BoxLayout(orientation='vertical', padding=10, spacing=10)
        layout.add_widget(Label(text='API ID:'))
        layout.add_widget(self.api_id_input)
        layout.add_widget(Label(text='API Hash:'))
        layout.add_widget(self.api_hash_input)
        layout.add_widget(Label(text='Phone Number:'))
        layout.add_widget(self.phone_input)
        layout.add_widget(Label(text='Group IDs (comma separated):'))
        layout.add_widget(self.group_ids_input)
        layout.add_widget(Label(text='Caption:'))
        layout.add_widget(self.caption_input)
        layout.add_widget(Label(text='Interval (seconds):'))
        layout.add_widget(self.interval_input)

        btn_select_photo = Button(text='Select Photo')
        btn_select_photo.bind(on_release=self.show_file_chooser)
        layout.add_widget(btn_select_photo)

        self.label_photo = Label(text='No photo selected')
        layout.add_widget(self.label_photo)

        self.status_label = Label(text='Status: Ready')
        layout.add_widget(self.status_label)

        btn_start = Button(text='Start Sending')
        btn_start.bind(on_release=self.start_sending)
        layout.add_widget(btn_start)

        return layout

    def show_file_chooser(self, instance):
        self.file_chooser_popup.open()

    def select_photo(self, filechooser, selection):
        if selection:
            self.photo_path = selection[0]
            self.label_photo.text = f'Selected: {self.photo_path}'
            self.file_chooser_popup.dismiss()

    def start_sending(self, instance):
        try:
            api_id = int(self.api_id_input.text.strip())
            api_hash = self.api_hash_input.text.strip()
            phone = self.phone_input.text.strip()
            groups = [g.strip() for g in self.group_ids_input.text.strip().split(',') if g.strip()]
            caption = self.caption_input.text.strip()
            interval = int(self.interval_input.text.strip())

            self.client = TelegramClient('session', api_id, api_hash)
            self.client.start(phone)

            self.groups = [self.client.get_entity(g) for g in groups]

            self.status_label.text = 'Status: Sending started'
            self.send_index = 0
            self.interval = interval

            Clock.schedule_interval(self.send_message, interval)
        except Exception as e:
            self.status_label.text = f'Error: {str(e)}'

    def send_message(self, dt):
        try:
            group = self.groups[self.send_index]
            self.client.send_file(group, self.photo_path, caption=self.caption_input.text.strip())
            self.status_label.text = f'Sent to {group.title if hasattr(group, "title") else str(group)} at {time.strftime("%H:%M:%S")}'
            self.send_index = (self.send_index + 1) % len(self.groups)
        except Exception as e:
            self.status_label.text = f'Error sending: {str(e)}'

if __name__ == '__main__':
    GFootballApp().run()
[app]
title = GFootball
package.name = gfootball
package.domain = org.example
source.include_exts = py,png,jpg,kv,atlas
version = 0.1
requirements = python3,kivy,telethon
android.permissions = INTERNET
orientation = portrait

[buildozer]
log_level = 2
name: Build APK

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:

    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2

    - name: Set up Python
      uses: actions/setup-python@v2
      with:
        python-version: 3.8

    - name: Install dependencies
      run: |
        sudo apt update
        sudo apt install -y openjdk-11-jdk python3-pip python3-setuptools python3-wheel
        pip3 install --upgrade buildozer

    - name: Build APK
      run: |
        buildozer android debug

    - name: Upload APK
      uses: actions/upload-artifact@v2
      with:
        name: gfootball-apk
        path: bin/*.apk
