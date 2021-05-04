use "lib:zip"
use "format"
use "debug"
use "files"
use "collections"

use @zip_open[Pointer[_ZipArchive] tag](path: Pointer[U8] tag, flags: U32, errorp: Pointer[I32] tag)
use @zip_close[I32](archive: Pointer[_ZipArchive] tag)
use @zip_discard[None](archive: Pointer[_ZipArchive] tag)
use @zip_get_error[Pointer[_ZipError] tag](archive: Pointer[_ZipArchive] tag)
use @zip_error_code_zip[I32](err: Pointer[_ZipError] tag)
use @zip_error_code_system[I32](err: Pointer[_ZipError] tag)
use @zip_error_system_type[I32](err: Pointer[_ZipError] tag)
use @zip_error_strerror[Pointer[U8] ref](err: Pointer[_ZipError] tag)

primitive _ZipArchive
class ref ZipArchive
  """represents an opened zip archive"""
  var _inner: Pointer[_ZipArchive] tag
  let _path: FilePath

  new ref _create(inner: Pointer[_ZipArchive] tag, path': FilePath) =>
    _inner = inner
    _path = path'

  fun path(): String val => _path.path

  fun get_error(): ZipError =>
    ZipError._create(@zip_get_error(_inner))

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

primitive _ZipError
class ZipError
  let _inner: Pointer[_ZipError] tag

  new _create(inner: Pointer[_ZipError] tag) =>
    _inner = inner

  fun zip_errno(): I32 =>
    @zip_error_code_zip(_inner)

  fun system_errno(): I32 =>
    @zip_error_code_system(_inner)

  fun system_type(): I32 =>
    @zip_error_system_type(_inner)

  fun string(): String iso^ =>
    recover
      let raw = @zip_error_strerror(_inner)
      String.copy_cstring(raw)
    end



primitive _ZipFile
class ZipFile
  let _inner: Pointer[_ZipFile] tag

  new _create(inner: Pointer[_ZipFile] tag) =>
    _inner = inner

primitive ZipSource

primitive CREATE
  """Create the archive if it does not exist."""
  fun value(): U32 => 1

primitive EXCL
  """Error is archive already exists"""
  fun value(): U32 => 2

primitive CHECKCONS
  """Perform additional stricter consistency checks on the archive, and error if they fail"""
  fun value(): U32 => 4

primitive TRUNCATE
  """If archive exists, ignore its current contents. In other words, handle it the same way as an empty archive."""
  fun value(): U32 => 8

primitive RDONLY
  """Open archive in read-only mode."""
  fun value(): U32 => 16

type OpenFlags is Flags[(CREATE | EXCL | CHECKCONS | TRUNCATE | RDONLY), U32]

primitive ArchiveExists
  fun apply(): I32 => 10
  fun string(): String =>
    "File already exists"

primitive ArchiveInconsistencies
  fun apply(): I32 => 21
  fun string(): String =>
    "Zip archive inconsistent"

primitive InvalidArgument
  fun apply(): I32 => 18
  fun string(): String =>
    "Invalid Argument"

primitive MallocFailure
  fun apply(): I32 => 14
  fun string(): String =>
    "Malloc failure"

primitive NoSuchFile
  fun apply(): I32 => 9
  fun string(): String =>
    "No such file"

primitive NoZipArchive
  fun apply(): I32 => 19
  fun string(): String =>
    "Not a zip archive"

primitive OpenFailed
  fun apply(): I32 => 11
  fun string(): String =>
    "Can't open file"

primitive ReadError
  fun apply(): I32 => 5
  fun string(): String =>
    "Read Error"

primitive SeekError
  fun apply(): I32 => 4
  fun string(): String =>
    "Seek Error"

class UnknownError
  let _err: I32

  new create(err: I32) =>
    _err = err

  fun apply(): I32 => _err

  fun string(): String =>
    "Unknown Error " + _err.string()

type ZipOpenError is (
  ArchiveExists
  | ArchiveInconsistencies
  | InvalidArgument
  | MallocFailure
  | NoSuchFile
  | NoZipArchive
  | OpenFailed
  | ReadError
  | SeekError
  | UnknownError)

primitive ZipCheckReturn
  fun apply(err: I32): (ZipOpenError | None) =>
    match err
    | 0 => None // all is good
    | ArchiveExists() => ArchiveExists
    | ArchiveInconsistencies() => ArchiveInconsistencies
    | InvalidArgument() => InvalidArgument
    | MallocFailure() => MallocFailure
    | NoSuchFile() => NoSuchFile
    | NoZipArchive() => NoZipArchive
    | OpenFailed() => OpenFailed
    | ReadError() => ReadError
    | SeekError() => SeekError
    else
      UnknownError(err)
    end


primitive Zip
  fun open(path: FilePath, flags: OpenFlags): (ZipArchive | ZipOpenError) =>
    var err: I32 = 0
    let rawzip = @zip_open(path.path.cstring(), flags.value(), addressof err)
    match ZipCheckReturn(err)
    | None => ZipArchive._create(rawzip, path)
    | let zoe: ZipOpenError => zoe
    end



