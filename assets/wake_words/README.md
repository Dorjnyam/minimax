Place Android Porcupine wake-word `.ppn` files here.

The app loads any `.ppn` file in this folder, so the names do not matter.

Important:

- They must be Android `.ppn` files.
- The spoken wake phrase is whatever the `.ppn` was trained for.
- If the files were not trained for "Hey Baigalaa", saying "Hey Baigalaa" will
  not wake the assistant.
- The app builds without these files, but wake-word listening stays disabled
  until at least one `.ppn` asset is added.
