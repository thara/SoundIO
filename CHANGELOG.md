# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- Add documentation
- Add examples
- Support error callbacks in `OutStream`
- Test other platforms except macOS

## [0.3.3] - 2020-03-13
### Added
  - Add `OutStream.beginWrite(theNumberOf)`
  - Add `InStream.beginRead(theNumberOf)`
### Removed
  - Remove `OutStream.write(frameCount, _)`
  - Remove `InStream.write(frameCount, _)`

## [0.3.2] - 2020-03-12
### Added
  - Support `bytes_per_sample` in `OutStream` and `InStream`

## [0.3.1] - 2020-02-28

### Added
  - Support underflow callbacks in `OutStream`
  - Support `soundio_instream_destroy`
  - Support `soundio_instream_create`
  - Support `soundio_instream_open`
  - Support `soundio_instream_start`
  - Support `soundio_instream_begin_write`
  - Support `soundio_instream_end_write`
  - Support `soundio_ring_buffer_create`
  - Support `soundio_ring_buffer_destroy`
  - Support `soundio_ring_buffer_capacity`
  - Support `soundio_ring_buffer_free_count`
  - Support `soundio_ring_buffer_fill_count`
  - Support `soundio_ring_buffer_write_ptr`
  - Support `soundio_ring_buffer_read_ptr`
  - Support `soundio_ring_buffer_advance_write_ptr`
  - Support `soundio_ring_buffer_advance_read_ptr`

## [0.3.0] - 2020-02-28 [YANKED]

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
[0.3.1]: https://github.com/thara/SoundIO/releases/compare/v0.1.0...v0.3.0
[0.2.0]: https://github.com/thara/SoundIO/releases/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/thara/SoundIO/releases/tag/v0.1.0
