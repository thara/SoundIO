# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- Add documentation
- Add examples
- Support error callbacks in `OutStream`
- Test other platforms except macOS

## [0.2.0] - 2020-02-28
### Added
  - Support underflow callbacks in `OutStream`
  - Support `soundio_instream_destroy`
  - Support `soundio_instream_create`
  - Support `soundio_instream_open`
  - Support `soundio_instream_start`
  - Support `soundio_instream_begin_write`
  - Support `soundio_instream_end_write`

## [0.2.0] - 2020-01-25
### Added
  - Support `soundio_connect_backend`
  - Support `soundio_input_device_count`
  - Support `soundio_output_device_count`
  - Support `soundio_default_input_device_index`
  - Support `soundio_get_input_device`
  - Support `soundio_get_channel_name`
  - Support `soundio_format_string`

## [0.1.0] - 2020-01-12
### Added
  - Support `soundio_create`
  - Support `soundio_destroy`
  - Support `soundio_connect`
  - Support `soundio_flush_events`
  - Support `soundio_wait_events`
  - Support `soundio_default_output_device_index`
  - Support `soundio_get_output_device`
  - Support `soundio_device_unref`
  - Support `soundio_outstream_destroy`
  - Support `soundio_outstream_create`
  - Support `soundio_outstream_open`
  - Support `soundio_outstream_start`
  - Support `soundio_outstream_begin_write`
  - Support `soundio_outstream_end_write`
  - Sine demo

[Unreleased]: https://github.com/thara/SoundIO/compare/v0.1.0...HEAD
[0.3.0]: https://github.com/thara/SoundIO/releases/compare/v0.1.0...v0.3.0
[0.2.0]: https://github.com/thara/SoundIO/releases/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/thara/SoundIO/releases/tag/v0.1.0
