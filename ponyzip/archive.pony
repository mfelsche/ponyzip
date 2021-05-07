use "files"

use @zip_get_error[Pointer[_ZipErrorT] tag](archive: Pointer[_ZipArchive] tag)
use @zip_close[I32](archive: Pointer[_ZipArchive] tag)
use @zip_discard[None](archive: Pointer[_ZipArchive] tag)
use @zip_get_num_entries[I64](archive: Pointer[_ZipArchive] tag, flags: U32)
use @zip_stat[I32](archive: Pointer[_ZipArchive] tag, name: Pointer[U8] tag, flags: U32, stat: NullablePointer[_ZipStat])
use @zip_stat_index[I32](archive: Pointer[_ZipArchive] tag, index: U64, flags: U32, stat: NullablePointer[_ZipStat])
use @zip_fopen[Pointer[_ZipFile] tag](archive: Pointer[_ZipArchive] tag, name: Pointer[U8] tag, flags: U32)
use @zip_fopen_index[Pointer[_ZipFile] tag](archive: Pointer[_ZipArchive] tag, index: U64, flags: U32)
use @zip_fopen_encrypted[Pointer[_ZipFile] tag](archive: Pointer[_ZipArchive] tag, name: Pointer[U8] tag, flags: U32, password: Pointer[U8] tag)
use @zip_fopen_index_encrypted[Pointer[_ZipFile] tag](archive: Pointer[_ZipArchive] tag, index: U64, flags: U32, password: Pointer[U8] tag)
use @zip_set_default_password[I32](archive: Pointer[_ZipArchive] tag, password: Pointer[U8] tag)


primitive _ZipArchive


class ref ZipArchive is Stringable
  """represents an opened zip archive"""
  var _inner: Pointer[_ZipArchive] tag
  let _path: FilePath

  new ref _create(inner: Pointer[_ZipArchive] tag, path': FilePath) =>
    _inner = inner
    _path = path'

  fun string(): String iso^ =>
    _path.path.clone()

  fun num_entries(ignore_changes: Bool = false): USize =>
    let flags = if ignore_changes then
      UNCHANGED.value()
    else
      0
    end
    @zip_get_num_entries(_inner, flags).usize()

  fun stat_by_name(name: String): ZipStat ? =>
    """
    if this method fails, get the error with get_error()
    """
    let zipstat: _ZipStat ref = _ZipStat.create()
    // TODO: good support for flags
    match @zip_stat(_inner, name.cstring(), 0, NullablePointer[_ZipStat](zipstat))
    | 0 => ZipStat._create(this, consume zipstat)
    else
      error
    end

  fun stat_by_index(index: U64): ZipStat ? =>
    """
    if this method fails, get the error with `get_error()`
    """
    // TODO: good support for flags
    let zipstat: _ZipStat ref = _ZipStat.create()
    match @zip_stat_index(_inner, index, 0, NullablePointer[_ZipStat](zipstat))
    | 0 => ZipStat._create(this, consume zipstat)
    else
      error
    end

  fun open_by_name(name: String, password: (String | None) = None): ZipFile ? =>
    // TODO: flag support
    let raw =
      match password
      | let pw: String =>
        @zip_fopen_encrypted(_inner, name.cstring(), 0, pw.cstring())
      else
        @zip_fopen(_inner, name.cstring(), 0)
      end
    if raw.is_null() then
      error
    else
      ZipFile._create(raw)
    end

  fun open_by_index(index: U64, password: (String | None) = None): ZipFile ? =>
    // TODO: flag support
    let raw =
      match password
      | let pw: String =>
        @zip_fopen_index_encrypted(_inner, index, 0, pw.cstring())
      else
        @zip_fopen_index(_inner, index, 0)
      end
    if raw.is_null() then
      error
    else
      ZipFile._create(raw)
    end

  fun path(): String val => _path.path

  fun get_error(): ZipErrorT =>
    ZipErrorT._create(@zip_get_error(_inner))

  fun ref set_default_password(password: (String | None)) ? =>
    let pw =
      match password
      | None => Pointer[U8].create()
      | let s: String => s.cstring()
      end
    if @zip_set_default_password(_inner, pw) != 0 then
      error
    end

  fun is_closed(): Bool =>
    _inner.is_null()

  fun ref close() ? =>
    """
    Write to disk and free and invalidate this instance.

    If close succeeds, this instance is invalid, and should not be used anymore.
    If it errors, call `get_error()` to get the cause and finally call `discard()`
    in order to free this instance, otherwise it might leak memory.
    """
    match @zip_close(_inner)
    | 0 =>
      // set a NULL pointer - all operation on _inner are now exploding
      _inner = Pointer[_ZipArchive].create()
    | -1 => error
    end

  fun ref discard() =>
    """Closes this archive and discards all changes, not writing them to disk."""
    @zip_discard(_inner)
    // set a NULL pointer
    _inner = Pointer[_ZipArchive].create()

  fun _final() =>
    """ensure we free all memory that has been allocated."""
    if not _inner.is_null() then
      @zip_discard(_inner)
    end

  fun stats(): ZipArchiveStatsIter =>
    ZipArchiveStatsIter.create(this)


class ref ZipArchiveStatsIter is Iterator[ZipStat]

  let _archive: ZipArchive box
  let _num_entries: USize

  var _idx: U64 = 0

  new ref create(archive: ZipArchive box) =>
    _archive = archive
    _num_entries = _archive.num_entries()

  fun ref has_next(): Bool =>
    _idx < _num_entries.u64()

  fun ref next(): ZipStat ? =>
    _archive.stat_by_index(_idx = _idx + 1)?

